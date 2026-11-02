const crypto = require('crypto');
const config = require('../config');
const supabaseAdmin = require('../database/supabase_admin');

class TokenManager {
  constructor() {
    this.jwtSecret = process.env.JWT_SECRET || config.telegram.botToken || 'wadiq_jwt_fallback_secret_key_2026';
    this.accessTokenTtlSec = 30 * 60; // 30 minutes
    this.refreshTokenTtlDays = 30; // 30 days
    this.revokedSessions = new Set();
  }

  _base64UrlEncode(str) {
    return Buffer.from(str)
      .toString('base64')
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');
  }

  _base64UrlDecode(str) {
    str = str.replace(/-/g, '+').replace(/_/g, '/');
    while (str.length % 4) str += '=';
    return Buffer.from(str, 'base64').toString('utf8');
  }

  createAccessToken(userId, username, sessionId) {
    const header = { alg: 'HS256', typ: 'JWT' };
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      sub: userId,
      username: username.toLowerCase(),
      sid: sessionId,
      iat: now,
      exp: now + this.accessTokenTtlSec,
    };

    const headerEnc = this._base64UrlEncode(JSON.stringify(header));
    const payloadEnc = this._base64UrlEncode(JSON.stringify(payload));
    const signature = crypto
      .createHmac('sha256', this.jwtSecret)
      .update(`${headerEnc}.${payloadEnc}`)
      .digest('base64')
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

    return `${headerEnc}.${payloadEnc}.${signature}`;
  }

  verifyAccessToken(token) {
    if (!token || typeof token !== 'string') return null;
    const parts = token.split('.');
    if (parts.length !== 3) return null;

    const [headerEnc, payloadEnc, signature] = parts;
    const expectedSig = crypto
      .createHmac('sha256', this.jwtSecret)
      .update(`${headerEnc}.${payloadEnc}`)
      .digest('base64')
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

    if (signature !== expectedSig) return null;

    try {
      const payload = JSON.parse(this._base64UrlDecode(payloadEnc));
      const now = Math.floor(Date.now() / 1000);
      if (payload.exp && payload.exp < now) {
        return null; // Expired
      }

      // Check instant revocation
      if (payload.sid && this.revokedSessions.has(payload.sid)) {
        return null; // Revoked
      }

      return payload;
    } catch (_) {
      return null;
    }
  }

  generateRefreshToken() {
    return crypto.randomBytes(32).toString('hex');
  }

  hashRefreshToken(refreshToken) {
    return crypto.createHash('sha256').update(refreshToken).digest('hex');
  }

  async createSession(userId, username, userAgent = '', ipAddress = '') {
    const sessionId = crypto.randomUUID();
    const rawRefreshToken = this.generateRefreshToken();
    const refreshTokenHash = this.hashRefreshToken(rawRefreshToken);
    const expiresAt = new Date(Date.now() + this.refreshTokenTtlDays * 24 * 60 * 60 * 1000).toISOString();

    if (supabaseAdmin.isConfigured) {
      await supabaseAdmin.insert('user_sessions', {
        id: sessionId,
        user_id: userId,
        refresh_token_hash: refreshTokenHash,
        user_agent: userAgent,
        ip_address: ipAddress,
        expires_at: expiresAt,
      });
    }

    const accessToken = this.createAccessToken(userId, username, sessionId);
    return {
      sessionId,
      accessToken,
      refreshToken: rawRefreshToken,
      expiresAt,
    };
  }

  async revokeSession(sessionId) {
    if (!sessionId) return;
    this.revokedSessions.add(sessionId);

    if (supabaseAdmin.isConfigured) {
      try {
        await supabaseAdmin.update(
          'user_sessions',
          { revoked_at: new Date().toISOString() },
          `id=eq.${sessionId}`
        );
      } catch (err) {
        console.error('[TokenManager] Error revoking session:', err.message);
      }
    }
  }

  async revokeAllUserSessions(userId) {
    if (!userId) return;
    if (supabaseAdmin.isConfigured) {
      try {
        const sessions = await supabaseAdmin.select('user_sessions', `user_id=eq.${userId}&revoked_at=is.null`);
        for (const s of sessions) {
          this.revokedSessions.add(s.id);
        }
        await supabaseAdmin.update(
          'user_sessions',
          { revoked_at: new Date().toISOString() },
          `user_id=eq.${userId}&revoked_at=is.null`
        );
      } catch (err) {
        console.error('[TokenManager] Error revoking user sessions:', err.message);
      }
    }
  }

  async refreshSession(rawRefreshToken, userAgent = '', ipAddress = '') {
    if (!rawRefreshToken || !supabaseAdmin.isConfigured) return null;
    const tokenHash = this.hashRefreshToken(rawRefreshToken);

    const sessions = await supabaseAdmin.select(
      'user_sessions',
      `refresh_token_hash=eq.${tokenHash}&revoked_at=is.null&select=*`
    );

    if (!sessions || sessions.length === 0) return null;
    const currentSession = sessions[0];

    // Check expiration
    if (new Date(currentSession.expires_at) < new Date()) {
      await this.revokeSession(currentSession.id);
      return null;
    }

    // Fetch user profile
    const profiles = await supabaseAdmin.select('profiles', `id=eq.${currentSession.user_id}`);
    if (!profiles || profiles.length === 0) return null;
    const user = profiles[0];

    // Revoke old session and issue a new one (Token Rotation)
    await this.revokeSession(currentSession.id);
    return await this.createSession(user.id, user.username, userAgent, ipAddress);
  }
}

module.exports = new TokenManager();
