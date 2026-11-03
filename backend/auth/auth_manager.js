const crypto = require('crypto');
const supabaseAdmin = require('../database/supabase_admin');
const tokenManager = require('./token_manager');

class AuthManager {
  // Scrypt password hashing with unique random salt per user
  _hashPassword(password) {
    const salt = crypto.randomBytes(16).toString('hex');
    const derivedKey = crypto.scryptSync(password, salt, 64, { N: 16384, r: 8, p: 1 });
    return `scrypt:${salt}:${derivedKey.toString('hex')}`;
  }

  _verifyPassword(password, storedHash) {
    if (!storedHash || typeof storedHash !== 'string') return false;

    // Support v2 scrypt format
    if (storedHash.startsWith('scrypt:')) {
      const parts = storedHash.split(':');
      if (parts.length !== 3) return false;
      const salt = parts[1];
      const expectedKey = Buffer.from(parts[2], 'hex');
      const actualKey = crypto.scryptSync(password, salt, 64, { N: 16384, r: 8, p: 1 });
      return crypto.timingSafeEqual(expectedKey, actualKey);
    }

    // Support legacy hmac if any exists
    const legacyHash = crypto.createHmac('sha256', 'wadiq_secure_salt_2026').update(password).digest('hex');
    return storedHash === legacyHash;
  }

  async findUser(usernameOrEmail) {
    const clean = usernameOrEmail.replaceAll('@', '').trim().toLowerCase();
    if (!supabaseAdmin.isConfigured) return null;

    try {
      const creds = await supabaseAdmin.select(
        'auth_credentials',
        `or=(username.ilike.${clean},email.ilike.${clean})&select=*`
      );
      if (creds && creds.length > 0) {
        return creds[0];
      }
    } catch (err) {
      console.error('[AuthManager] findUser error:', err.message);
    }
    return null;
  }

  async userExists(username, email) {
    const cleanU = username.replaceAll('@', '').trim().toLowerCase();
    const cleanE = email.trim().toLowerCase();
    if (!supabaseAdmin.isConfigured) return false;

    try {
      const creds = await supabaseAdmin.select(
        'auth_credentials',
        `or=(username.ilike.${cleanU},email.ilike.${cleanE})&select=id`
      );
      return Boolean(creds && creds.length > 0);
    } catch (_) {
      return false;
    }
  }

  async register({ username, fullName, email, password, role = 'طالب', avatarUrl = null, bio = null, userAgent = '', ipAddress = '' }) {
    const cleanU = username.replaceAll('@', '').trim().toLowerCase();
    const cleanE = email.trim().toLowerCase();

    if (!cleanU || !cleanE || !fullName) {
      throw new Error('جميع حقول التسجيل الأساسية مطلوبة.');
    }

    if (cleanU.length < 3 || cleanU.length > 30) {
      throw new Error('اسم المستخدم يجب أن يكون بين 3 و30 حرفاً.');
    }

    if (!/^[a-zA-Z0-9_]+$/.test(cleanU)) {
      throw new Error('اسم المستخدم يجب أن يحتوي فقط على أحرف وأرقام وشرطة سفلية.');
    }

    if (password.length < 8) {
      throw new Error('كلمة المرور يجب ألا تقل عن 8 خانات لأسباب أمنية.');
    }

    const exists = await this.userExists(cleanU, cleanE);
    if (exists) {
      throw new Error('اسم المستخدم أو البريد الإلكتروني مسجل مسبقاً.');
    }

    const userId = crypto.randomUUID();
    const passwordHash = this._hashPassword(password);
    const finalBio = bio || 'طالب مسجل في منصة ودق الأكاديمية 🎓';

    // 1. Insert into public profiles (Public fields only)
    await supabaseAdmin.insert('profiles', {
      id: userId,
      username: cleanU,
      full_name: fullName.trim(),
      role: role || 'طالب',
      avatar_url: avatarUrl || '',
      bio: finalBio,
      department: 'العام',
      academic_stage: 'الأولى',
      followers_count: 0,
      following_count: 0,
    });

    // 2 & 3. Parallelize insertion into auth_credentials and user_sessions to eliminate redundant sequential network latency
    const [_, session] = await Promise.all([
      supabaseAdmin.insert('auth_credentials', {
        id: userId,
        username: cleanU,
        email: cleanE,
        password_hash: passwordHash,
        password_algorithm: 'scrypt',
      }),
      tokenManager.createSession(userId, cleanU, userAgent, ipAddress),
    ]);

    // 4. Safe notification to Telegram (NO PASSWORDS, NO SECRETS!)
    try {
      const telegramService = require('../telegram/telegram_service');
      const config = require('../config');
      const targetChannel = config.telegram.channels.registrations || config.telegram.channels.images;
      if (targetChannel && telegramService.isConfigured()) {
        const regMessage = `📋 تسجيل مستخدم جديد في منصة ودق 🎓\n👤 الاسم: ${fullName.trim()}\n🏷️ المعرف: @${cleanU}\n🎓 الدور: ${role}\n⏰ التاريخ: ${new Date().toLocaleString('ar-EG', { timeZone: 'Asia/Baghdad' })}`;
        telegramService.callApi('sendMessage', {
          chat_id: targetChannel,
          text: regMessage,
        }).catch(() => {});
      }
    } catch (_) {}

    return {
      user: {
        id: userId,
        username: cleanU,
        fullName: fullName.trim(),
        role: role || 'طالب',
        avatarUrl: avatarUrl || '',
        bio: finalBio,
        department: 'العام',
        academicStage: 'الأولى',
      },
      tokens: {
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: session.expiresAt,
      }
    };
  }

  async login(usernameOrEmail, password, userAgent = '', ipAddress = '') {
    const cred = await this.findUser(usernameOrEmail);
    if (!cred) {
      throw new Error('الحساب غير مسجل في المنصة. يرجى التأكد من البيانات أو إنشاء حساب جديد.');
    }

    const isValid = this._verifyPassword(password, cred.password_hash);
    if (!isValid) {
      throw new Error('كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.');
    }

    // Fetch profile
    const profiles = await supabaseAdmin.select('profiles', `id=eq.${cred.id}`);
    const profile = profiles && profiles.length > 0 ? profiles[0] : null;

    // Create session
    const session = await tokenManager.createSession(cred.id, cred.username, userAgent, ipAddress);

    return {
      user: {
        id: cred.id,
        username: cred.username,
        email: cred.email,
        fullName: profile ? profile.full_name : cred.username,
        role: profile ? profile.role : 'طالب',
        avatarUrl: profile ? profile.avatar_url : '',
        bio: profile ? profile.bio : '',
        department: profile ? profile.department : 'العام',
        academicStage: profile ? profile.academic_stage : 'الأولى',
        followersCount: profile ? profile.followers_count : 0,
        followingCount: profile ? profile.following_count : 0,
      },
      tokens: {
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: session.expiresAt,
      }
    };
  }

  async changePassword(userId, currentPassword, newPassword) {
    if (newPassword.length < 8) {
      throw new Error('كلمة المرور الجديدة يجب ألا تقل عن 8 خانات.');
    }

    const creds = await supabaseAdmin.select('auth_credentials', `id=eq.${userId}`);
    if (!creds || creds.length === 0) {
      throw new Error('المستخدم غير موجود.');
    }

    const cred = creds[0];
    const isValid = this._verifyPassword(currentPassword, cred.password_hash);
    if (!isValid) {
      throw new Error('كلمة المرور الحالية غير صحيحة.');
    }

    const newHash = this._hashPassword(newPassword);
    await supabaseAdmin.update('auth_credentials', {
      password_hash: newHash,
      updated_at: new Date().toISOString()
    }, `id=eq.${userId}`);

    // Revoke all active sessions on other devices
    await tokenManager.revokeAllUserSessions(userId);
    return true;
  }

  async updateAvatar(userId, avatarUrl) {
    if (!userId || !avatarUrl) {
      throw new Error('بيانات تحديث الصورة غير مكتملة.');
    }
    await supabaseAdmin.update('profiles', {
      avatar_url: avatarUrl,
      updated_at: new Date().toISOString()
    }, `id=eq.${userId}`);
    return { ok: true, avatarUrl };
  }
}

module.exports = new AuthManager();
