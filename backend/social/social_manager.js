const supabaseAdmin = require('../database/supabase_admin');

class SocialManager {
  // --- COMMENTS ---
  async getComments(postId) {
    if (!postId) return [];
    if (supabaseAdmin.isConfigured) {
      try {
        const rows = await supabaseAdmin.select(
          'comments',
          `post_id=eq.${postId}&order=created_at.asc&select=*`
        );
        return rows.map(r => ({
          id: r.id,
          postId: r.post_id,
          reelId: r.reel_id,
          author: r.author_name,
          username: r.author_username || 'user',
          avatarUrl: r.author_avatar,
          text: r.content,
          replyTo: null,
          time: 'مؤخراً',
          createdAt: r.created_at,
        }));
      } catch (err) {
        console.error('[SocialManager] getComments error:', err.message);
      }
    }
    return [];
  }

  async addComment(postId, commentData) {
    const content = (commentData.text || commentData.content || '').trim();
    if (!content) throw new Error('محتوى التعليق لا يمكن أن يكون فارغاً.');

    const authorName = commentData.author || commentData.author_name || 'طالب ودق';
    const authorUsername = (commentData.username || 'user').replaceAll('@', '').toLowerCase();
    const authorAvatar = commentData.avatarUrl || commentData.author_avatar || '';
    const userId = commentData.userId || null;

    if (supabaseAdmin.isConfigured) {
      const inserted = await supabaseAdmin.insert('comments', {
        post_id: postId,
        reel_id: null,
        user_id: userId,
        author_name: authorName,
        author_username: authorUsername,
        author_avatar: authorAvatar,
        content: content,
      });

      const row = inserted && inserted.length > 0 ? inserted[0] : null;
      return {
        id: row ? row.id : `comment_${Date.now()}`,
        postId: postId,
        author: authorName,
        username: authorUsername,
        avatarUrl: authorAvatar,
        text: content,
        time: 'الآن',
        createdAt: row ? row.created_at : new Date().toISOString(),
      };
    }

    return {
      id: `comment_${Date.now()}`,
      author: authorName,
      username: authorUsername,
      text: content,
      time: 'الآن',
      createdAt: new Date().toISOString(),
    };
  }

  // --- NOTIFICATIONS ---
  async getNotifications(usernameOrId) {
    if (!usernameOrId) return [];
    const clean = usernameOrId.replaceAll('@', '').toLowerCase().trim();

    if (supabaseAdmin.isConfigured) {
      try {
        const rows = await supabaseAdmin.select(
          'notifications',
          `recipient_username=eq.${clean}&order=created_at.desc&limit=100&select=*`
        );
        return rows.map(r => ({
          id: r.id,
          type: r.type,
          title: r.title,
          body: r.body,
          data: r.data,
          isUnread: !r.is_read,
          time: 'مؤخراً',
          targetType: r.data?.targetType || 'post',
          targetId: r.data?.targetId || '',
          createdAt: r.created_at,
        }));
      } catch (err) {
        console.error('[SocialManager] getNotifications error:', err.message);
      }
    }
    return [];
  }

  async addNotification(targetUsername, { type, title, body, targetType, targetId, senderUsername = 'system' }) {
    const cleanTarget = targetUsername.replaceAll('@', '').toLowerCase().trim();
    if (!cleanTarget) return null;

    if (supabaseAdmin.isConfigured) {
      try {
        const inserted = await supabaseAdmin.insert('notifications', {
          recipient_username: cleanTarget,
          sender_username: senderUsername.replaceAll('@', '').toLowerCase().trim(),
          type: type || 'system',
          title: title || 'إشعار جديد',
          body: body || '',
          data: { targetType: targetType || 'post', targetId: targetId || '' },
          is_read: false,
        });
        return inserted && inserted.length > 0 ? inserted[0] : null;
      } catch (err) {
        console.error('[SocialManager] addNotification error:', err.message);
      }
    }
    return null;
  }

  async markAllAsRead(username) {
    const clean = username.replaceAll('@', '').toLowerCase().trim();
    if (supabaseAdmin.isConfigured) {
      try {
        await supabaseAdmin.update(
          'notifications',
          { is_read: true },
          `recipient_username=eq.${clean}&is_read=eq.false`
        );
        return true;
      } catch (err) {
        console.error('[SocialManager] markAllAsRead error:', err.message);
      }
    }
    return true;
  }
}

module.exports = new SocialManager();
