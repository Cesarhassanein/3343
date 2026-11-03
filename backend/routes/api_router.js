const url = require('url');
const path = require('path');
const mediaManager = require('../media/media_manager');
const agoraService = require('../agora/agora_service');
const telegramService = require('../telegram/telegram_service');
const webhookHandler = require('../telegram/webhook_handler');
const authManager = require('../auth/auth_manager');
const tokenManager = require('../auth/token_manager');
const socialManager = require('../social/social_manager');
const supabaseAdmin = require('../database/supabase_admin');
const config = require('../config');

// Helper to read JSON body (compatible with both raw HTTP streams and Vercel/Express parsed bodies)
function readJsonBody(req) {
  if (req.body !== undefined && req.body !== null) {
    if (typeof req.body === 'object') return Promise.resolve(req.body);
    try {
      return Promise.resolve(JSON.parse(req.body));
    } catch (_) {
      return Promise.resolve({});
    }
  }
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
      if (body.length > 50 * 1024 * 1024) { // 50MB limit
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      if (!body) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch (err) {
        reject(new Error('Invalid JSON'));
      }
    });
    req.on('error', reject);
  });
}

// Helper to read raw binary stream directly into Buffer (bypasses Base64 and JSON parsing)
function readBinaryBody(req, maxSizeBytes = 50 * 1024 * 1024) {
  if (Buffer.isBuffer(req.body)) return Promise.resolve(req.body);

  return new Promise((resolve, reject) => {
    const chunks = [];
    let receivedBytes = 0;

    req.on('data', chunk => {
      receivedBytes += chunk.length;
      if (receivedBytes > maxSizeBytes) {
        req.destroy();
        reject(new Error(`حجم الملف يتجاوز الحد المسموح به (${Math.round(maxSizeBytes / (1024 * 1024))}MB)`));
        return;
      }
      chunks.push(chunk);
    });

    req.on('end', () => {
      resolve(Buffer.concat(chunks));
    });

    req.on('error', reject);
  });
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=UTF-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, Range',
  });
  res.end(JSON.stringify(data));
}

function getAuthUser(req) {
  const authHeader = req.headers['authorization'] || '';
  if (!authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.substring(7).trim();
  return tokenManager.verifyAccessToken(token);
}

class ApiRouter {
  async handle(req, res) {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;
    const method = req.method.toUpperCase();

    // CORS preflight
    if (method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Range',
        'Access-Control-Max-Age': '86400',
      });
      res.end();
      return true;
    }

    // Only process /api routes
    if (!pathname.startsWith('/api/')) {
      return false;
    }

    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '';
    const userAgent = req.headers['user-agent'] || '';

    try {
      // 1. Health check
      if (pathname === '/api/health' && (method === 'GET' || method === 'HEAD')) {
        sendJson(res, 200, {
          status: 'ok',
          service: 'Wadiq Backend Proxy',
          version: '2.0.0',
          storageProvider: config.storageProvider,
          telegramConfigured: config.telegram.isConfigured(),
          agoraConfigured: config.agora.isConfigured(),
          supabaseAdminConfigured: supabaseAdmin.isConfigured,
          queueStats: telegramService.queue.getStats(),
          timestamp: new Date().toISOString(),
        });
        return true;
      }

      // 1b. In-App Auto Update: GET /api/app/version
      if (pathname === '/api/app/version' && method === 'GET') {
        sendJson(res, 200, {
          ok: true,
          latestVersion: '1.0.3',
          versionCode: 3,
          downloadUrl: 'https://github.com/Cesarhassanein/3343/releases/latest/download/app-release.apk',
          directApkUrl: 'https://3343-rosy.vercel.app/api/app/download',
          releaseNotes: 'تحديث ودق رقم 3: تحسين قسم المنشورات، التفاعلات، التعليقات والسرعة العالية للرفع والتحميل 🚀',
          isForced: false,
          minVersionCode: 1,
        });
        return true;
      }

      // 1c. Direct APK Download Redirect: GET /api/app/download
      if (pathname === '/api/app/download' && method === 'GET') {
        res.writeHead(302, {
          'Location': 'https://github.com/Cesarhassanein/3343/releases/latest/download/app-release.apk',
          'Access-Control-Allow-Origin': '*',
        });
        res.end();
        return true;
      }

      // 2. Media Upload: POST /api/media/upload (Base64 JSON legacy compatibility)
      if (pathname === '/api/media/upload' && method === 'POST') {
        const body = await readJsonBody(req);
        if (!body.data) {
          sendJson(res, 400, { error: 'Missing media data (Base64 string required)' });
          return true;
        }

        const auth = getAuthUser(req);
        const owner = auth ? auth.username : (body.ownerUsername || 'anon');

        const result = await mediaManager.uploadMedia(
          body.data,
          body.fileName || 'upload.jpg',
          body.category || 'image',
          {
            ownerUsername: owner,
          }
        );

        sendJson(res, 200, {
          ok: true,
          ...result,
        });
        return true;
      }

      // 2b. High-Performance Direct Binary Upload: POST /api/media/upload-binary
      if (pathname === '/api/media/upload-binary' && method === 'POST') {
        const rawFileName = req.headers['x-file-name'] || 'file.bin';
        const sanitizedFileName = path.basename(decodeURIComponent(rawFileName)).replace(/[^a-zA-Z0-9._-]/g, '_');
        const ext = path.extname(sanitizedFileName).toLowerCase();

        // Security check: Block dangerous executable extensions
        const blockedExtensions = ['.exe', '.sh', '.bat', '.cmd', '.msi', '.php', '.pl', '.py', '.js', '.vbs', '.apk', '.jar', '.dll'];
        if (blockedExtensions.includes(ext)) {
          sendJson(res, 400, { ok: false, error: 'نوع الملف غير مسموح به لأسباب أمنية.' });
          return true;
        }

        const category = (req.headers['x-category'] || 'image').toLowerCase();
        let mimeType = req.headers['x-mime-type'] || req.headers['content-type'] || 'application/octet-stream';
        if (mimeType.includes(';')) mimeType = mimeType.split(';')[0].trim();

        const allowedCategories = ['image', 'avatar', 'reel', 'video', 'voice', 'audio', 'document'];
        if (!allowedCategories.includes(category)) {
          sendJson(res, 400, { ok: false, error: 'فئة الوسائط غير صالحة.' });
          return true;
        }

        const auth = getAuthUser(req);
        const owner = auth ? auth.username : (req.headers['x-owner-username'] || 'anon');

        try {
          const buffer = await readBinaryBody(req, 50 * 1024 * 1024);
          if (!buffer || buffer.length === 0) {
            sendJson(res, 400, { ok: false, error: 'الملف المرسل فارغ.' });
            return true;
          }

          const result = await mediaManager.uploadMedia(
            buffer,
            sanitizedFileName,
            category,
            { ownerUsername: owner, mimeType }
          );

          sendJson(res, 200, {
            ok: true,
            ...result,
          });
        } catch (err) {
          sendJson(res, 400, { ok: false, error: err.message });
        }
        return true;
      }

      // 3. Media Stream: GET /api/media/:fileId
      const mediaMatch = pathname.match(/^\/api\/media\/(.+?)\/?$/);
      if (mediaMatch && (method === 'GET' || method === 'HEAD')) {
        const fileId = decodeURIComponent(mediaMatch[1].trim());
        await mediaManager.streamMedia(fileId, req, res);
        return true;
      }

      // 4. Media Metadata: GET /api/media/meta/:fileId
      const metaMatch = pathname.match(/^\/api\/media\/meta\/([^/]+)$/);
      if (metaMatch && method === 'GET') {
        const fileId = metaMatch[1];
        const meta = mediaManager.getMetadata(fileId);
        if (!meta) {
          sendJson(res, 404, { error: 'Media metadata not found' });
        } else {
          sendJson(res, 200, meta);
        }
        return true;
      }

      // 5. Agora Call Session: POST /api/calls/initiate
      if (pathname === '/api/calls/initiate' && method === 'POST') {
        const body = await readJsonBody(req);
        if (!body.caller || !body.receiver) {
          sendJson(res, 400, { error: 'Missing caller or receiver username' });
          return true;
        }

        const session = agoraService.createCallSession(
          body.caller,
          body.receiver,
          Boolean(body.isVideo)
        );

        sendJson(res, 200, session);
        return true;
      }

      // 6. Community Forum Topics: POST /api/groups/create-topic
      if (pathname === '/api/groups/create-topic' && method === 'POST') {
        const body = await readJsonBody(req);
        const supergroupId = body.supergroupId || config.telegram.channels.supergroup;
        const topicName = body.name || 'New Topic';

        const result = await telegramService.createForumTopic(supergroupId, topicName);
        sendJson(res, 200, {
          ok: true,
          ...result,
        });
        return true;
      }

      // 7. Telegram Webhook: POST /api/telegram/webhook
      if (pathname === '/api/telegram/webhook' && method === 'POST') {
        const update = await readJsonBody(req);
        webhookHandler.handleUpdate(req, res, update);
        return true;
      }

      // 8. Auth: POST /api/auth/register
      if (pathname === '/api/auth/register' && method === 'POST') {
        const body = await readJsonBody(req);
        try {
          const result = await authManager.register({
            ...body,
            userAgent,
            ipAddress: clientIp,
          });
          sendJson(res, 200, { ok: true, ...result });
        } catch (err) {
          sendJson(res, 400, { ok: false, error: err.message });
        }
        return true;
      }

      // 9. Auth: POST /api/auth/login
      if (pathname === '/api/auth/login' && method === 'POST') {
        const body = await readJsonBody(req);
        try {
          const result = await authManager.login(
            body.usernameOrEmail,
            body.password,
            userAgent,
            clientIp
          );
          sendJson(res, 200, { ok: true, ...result });
        } catch (err) {
          sendJson(res, 401, { ok: false, error: err.message });
        }
        return true;
      }

      // 10. Auth: POST /api/auth/refresh
      if (pathname === '/api/auth/refresh' && method === 'POST') {
        const body = await readJsonBody(req);
        if (!body.refreshToken) {
          sendJson(res, 400, { ok: false, error: 'رمز التجديد مطلوب.' });
          return true;
        }

        const session = await tokenManager.refreshSession(body.refreshToken, userAgent, clientIp);
        if (!session) {
          sendJson(res, 401, { ok: false, error: 'انتهت صلاحية الجلسة أو تم إلغاؤها. يرجى تسجيل الدخول مجدداً.' });
          return true;
        }

        sendJson(res, 200, { ok: true, tokens: session });
        return true;
      }

      // 11. Auth: POST /api/auth/logout (Instant Revocation)
      if (pathname === '/api/auth/logout' && method === 'POST') {
        const auth = getAuthUser(req);
        if (auth && auth.sid) {
          await tokenManager.revokeSession(auth.sid);
        }
        sendJson(res, 200, { ok: true, message: 'تم تسجيل الخروج بنجاح.' });
        return true;
      }

      // 12. Auth: GET /api/auth/me (Protected Profile)
      if (pathname === '/api/auth/me' && method === 'GET') {
        const auth = getAuthUser(req);
        if (!auth) {
          sendJson(res, 401, { ok: false, error: 'غير مصرح.' });
          return true;
        }

        const profiles = await supabaseAdmin.select('profiles', `id=eq.${auth.sub}`);
        const creds = await supabaseAdmin.select('auth_credentials', `id=eq.${auth.sub}&select=email`);
        const p = profiles && profiles.length > 0 ? profiles[0] : null;

        if (!p) {
          sendJson(res, 404, { ok: false, error: 'الملف الشخصي غير موجود.' });
          return true;
        }

        sendJson(res, 200, {
          ok: true,
          user: {
            id: p.id,
            username: p.username,
            fullName: p.full_name,
            email: creds && creds.length > 0 ? creds[0].email : '',
            role: p.role,
            bio: p.bio,
            avatarUrl: p.avatar_url,
            department: p.department,
            academicStage: p.academic_stage,
            followersCount: p.followers_count,
            followingCount: p.following_count,
          }
        });
        return true;
      }

      // 13. Auth: POST /api/auth/change-password
      if (pathname === '/api/auth/change-password' && method === 'POST') {
        const auth = getAuthUser(req);
        if (!auth) {
          sendJson(res, 401, { ok: false, error: 'غير مصرح.' });
          return true;
        }

        const body = await readJsonBody(req);
        try {
          await authManager.changePassword(auth.sub, body.currentPassword, body.newPassword);
          sendJson(res, 200, { ok: true, message: 'تم تحديث كلمة المرور وإلغاء الجلسات الأخرى بنجاح.' });
        } catch (err) {
          sendJson(res, 400, { ok: false, error: err.message });
        }
        return true;
      }

      // 13b. Auth: POST /api/auth/avatar (Update User Profile Picture Asynchronously)
      if (pathname === '/api/auth/avatar' && method === 'POST') {
        const auth = getAuthUser(req);
        if (!auth) {
          sendJson(res, 401, { ok: false, error: 'غير مصرح.' });
          return true;
        }

        const body = await readJsonBody(req);
        if (!body.avatarUrl) {
          sendJson(res, 400, { ok: false, error: 'رابط الصورة مطلوب.' });
          return true;
        }

        try {
          const result = await authManager.updateAvatar(auth.sub, body.avatarUrl);
          sendJson(res, 200, { ok: true, ...result });
        } catch (err) {
          sendJson(res, 400, { ok: false, error: err.message });
        }
        return true;
      }

      // 14. Auth Check User Exists: GET /api/auth/check-user?u=...
      if (pathname === '/api/auth/check-user' && method === 'GET') {
        const queryUser = (parsedUrl.query.u || '').toString();
        const user = await authManager.findUser(queryUser);
        sendJson(res, 200, { exists: Boolean(user), user: user ? { username: user.username } : null });
        return true;
      }

      // 15. Post Comments: GET /api/posts/:postId/comments
      const commentsGetMatch = pathname.match(/^\/api\/posts\/([^/]+)\/comments$/);
      if (commentsGetMatch && method === 'GET') {
        const postId = commentsGetMatch[1];
        const comments = await socialManager.getComments(postId);
        sendJson(res, 200, { ok: true, comments });
        return true;
      }

      // 16. Post Comments: POST /api/posts/:postId/comments
      const commentsPostMatch = pathname.match(/^\/api\/posts\/([^/]+)\/comments$/);
      if (commentsPostMatch && method === 'POST') {
        const postId = commentsPostMatch[1];
        const body = await readJsonBody(req);
        const auth = getAuthUser(req);

        const commentData = {
          ...body,
          userId: auth ? auth.sub : null,
          username: auth ? auth.username : (body.username || 'user'),
          author_name: auth ? (body.author || auth.username) : body.author,
        };

        const comment = await socialManager.addComment(postId, commentData);
        sendJson(res, 200, { ok: true, comment });
        return true;
      }

      // 16b. Post Like / React: POST /api/posts/:postId/react
      const reactPostMatch = pathname.match(/^\/api\/posts\/([^/]+)\/react$/);
      if (reactPostMatch && method === 'POST') {
        const postId = reactPostMatch[1];
        const body = await readJsonBody(req);
        const auth = getAuthUser(req);
        const username = auth ? auth.username : (body.username || 'user');
        const reactionType = body.reaction || 'like';

        const result = await socialManager.toggleLikePost(postId, username, reactionType);
        sendJson(res, 200, result);
        return true;
      }

      // 16c. Post Repost: POST /api/posts/:postId/repost
      const repostPostMatch = pathname.match(/^\/api\/posts\/([^/]+)\/repost$/);
      if (repostPostMatch && method === 'POST') {
        const postId = repostPostMatch[1];
        const body = await readJsonBody(req);
        const auth = getAuthUser(req);
        const username = auth ? auth.username : (body.username || 'user');

        const result = await socialManager.toggleRepostPost(postId, username);
        sendJson(res, 200, result);
        return true;
      }

      // 16d. Comment Vote: POST /api/comments/:commentId/vote
      const commentVoteMatch = pathname.match(/^\/api\/comments\/([^/]+)\/vote$/);
      if (commentVoteMatch && method === 'POST') {
        const commentId = commentVoteMatch[1];
        const body = await readJsonBody(req);
        const voteType = body.voteType || 'like';

        const result = await socialManager.voteComment(commentId, voteType);
        sendJson(res, 200, result);
        return true;
      }

      // 17. Notifications: GET /api/notifications
      if (pathname === '/api/notifications' && method === 'GET') {
        const auth = getAuthUser(req);
        if (!auth) {
          sendJson(res, 401, { ok: false, error: 'غير مصرح.' });
          return true;
        }

        const notifications = await socialManager.getNotifications(auth.username);
        sendJson(res, 200, { ok: true, notifications });
        return true;
      }

      // Backward compatible: GET /api/notifications/:username (requires auth matching)
      const notifsGetMatch = pathname.match(/^\/api\/notifications\/([^/]+)$/);
      if (notifsGetMatch && method === 'GET') {
        const username = notifsGetMatch[1];
        const auth = getAuthUser(req);
        // Ensure user can only read their own notifications
        if (auth && auth.username.toLowerCase() !== username.toLowerCase()) {
          sendJson(res, 403, { ok: false, error: 'ممنوع الوصول لإشعارات مستخدم آخر.' });
          return true;
        }

        const notifications = await socialManager.getNotifications(username);
        sendJson(res, 200, { ok: true, notifications });
        return true;
      }

      // 18. Notifications: POST /api/notifications/read-all
      if (pathname === '/api/notifications/read-all' && method === 'POST') {
        const auth = getAuthUser(req);
        if (!auth) {
          sendJson(res, 401, { ok: false, error: 'غير مصرح.' });
          return true;
        }

        await socialManager.markAllAsRead(auth.username);
        sendJson(res, 200, { ok: true, message: 'تم تعليم جميع الإشعارات كمقروءة.' });
        return true;
      }

      // 19. Notifications: POST /api/notifications (Create notification)
      if (pathname === '/api/notifications' && method === 'POST') {
        const body = await readJsonBody(req);
        const auth = getAuthUser(req);
        const sender = auth ? auth.username : 'system';

        const notif = await socialManager.addNotification(body.targetUsername, {
          ...body,
          senderUsername: sender,
        });
        sendJson(res, 200, { ok: true, notification: notif });
        return true;
      }

      // Route not handled
      sendJson(res, 404, { error: `Endpoint not found: ${pathname}` });
      return true;
    } catch (err) {
      console.error(`[ApiRouter] Error handling ${method} ${pathname}:`, err);
      sendJson(res, 500, { error: 'Internal server error', details: err.message });
      return true;
    }
  }
}

module.exports = new ApiRouter();
