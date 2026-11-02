const supabaseAdmin = require('../database/supabase_admin');

class SocialManager {
  // --- COMMENTS ---
  async getComments(targetId) {
    if (!targetId) return [];
    if (supabaseAdmin.isConfigured) {
      try {
        const rows = await supabaseAdmin.select(
          'comments',
          `or=(post_id.eq.${targetId},reel_id.eq.${targetId})&order=created_at.asc&select=*`
        );
        return rows.map(r => ({
          id: r.id,
          postId: r.post_id,
          reelId: r.reel_id,
          author: r.author_name,
          username: r.author_username || 'user',
          avatarUrl: r.author_avatar,
          text: r.content,
          replyTo: r.reply_to || null,
          likesCount: r.likes_count || 0,
          dislikesCount: r.dislikes_count || 0,
          time: 'مؤخراً',
          createdAt: r.created_at,
        }));
      } catch (err) {
        console.error('[SocialManager] getComments error:', err.message);
      }
    }
    return [];
  }

  async addComment(targetId, commentData) {
    const content = (commentData.text || commentData.content || '').trim();
    if (!content) throw new Error('محتوى التعليق لا يمكن أن يكون فارغاً.');

    const authorName = commentData.author || commentData.author_name || 'طالب ودق';
    const authorUsername = (commentData.username || 'user').replaceAll('@', '').toLowerCase();
    const authorAvatar = commentData.avatarUrl || commentData.author_avatar || '';
    const userId = commentData.userId || null;
    const isReel = commentData.isReel === true || commentData.targetType === 'reel';

    let isReelTarget = isReel;
    if (!isReel && supabaseAdmin.isConfigured) {
      try {
        const reelCheck = await supabaseAdmin.select('reels', `id=eq.${targetId}&select=id`);
        if (reelCheck && reelCheck.length > 0) {
          isReelTarget = true;
        }
      } catch (_) {}
    }

    if (supabaseAdmin.isConfigured) {
      const inserted = await supabaseAdmin.insert('comments', {
        post_id: isReelTarget ? null : targetId,
        reel_id: isReelTarget ? targetId : null,
        user_id: userId,
        author_name: authorName,
        author_username: authorUsername,
        author_avatar: authorAvatar,
        content: content,
        reply_to: commentData.replyTo || commentData.reply_to || null,
      });

      const row = inserted && inserted.length > 0 ? inserted[0] : null;
      return {
        id: row ? row.id : `comment_${Date.now()}`,
        postId: isReelTarget ? null : targetId,
        reelId: isReelTarget ? targetId : null,
        author: authorName,
        username: authorUsername,
        avatarUrl: authorAvatar,
        text: content,
        replyTo: commentData.replyTo || commentData.reply_to || null,
        likesCount: 0,
        dislikesCount: 0,
        time: 'الآن',
        createdAt: row ? row.created_at : new Date().toISOString(),
      };
    }

    return {
      id: `comment_${Date.now()}`,
      author: authorName,
      username: authorUsername,
      text: content,
      replyTo: commentData.replyTo || commentData.reply_to || null,
      likesCount: 0,
      dislikesCount: 0,
      time: 'الآن',
      createdAt: new Date().toISOString(),
    };
  }

  // --- POST INTERACTIONS (LIKES & REPOSTS) ---
  async toggleLikePost(postId, username, reactionType = 'like') {
    if (!postId) return { ok: false, error: 'Missing postId' };
    const cleanUser = (username || 'user').replaceAll('@', '').toLowerCase();
    if (supabaseAdmin.isConfigured) {
      try {
        const rows = await supabaseAdmin.select('posts', `id=eq.${postId}&select=likes_count`);
        if (rows && rows.length > 0) {
          const currentLikes = rows[0].likes_count || 0;
          const likeCheck = await supabaseAdmin.select('post_likes', `post_id=eq.${postId}&user_id=eq.${cleanUser}`);
          let newCount = currentLikes;
          let isLiked = false;
          if (likeCheck && likeCheck.length > 0) {
            await supabaseAdmin.delete('post_likes', `post_id=eq.${postId}&user_id=eq.${cleanUser}`);
            newCount = Math.max(0, currentLikes - 1);
            isLiked = false;
          } else {
            await supabaseAdmin.insert('post_likes', { post_id: postId, user_id: cleanUser });
            newCount = currentLikes + 1;
            isLiked = true;
          }
          await supabaseAdmin.update('posts', { likes_count: newCount }, `id=eq.${postId}`);
          return { ok: true, isLiked, likesCount: newCount, reaction: isLiked ? reactionType : null };
        }
      } catch (err) {
        console.error('[SocialManager] toggleLikePost error:', err.message);
      }
    }
    return { ok: true, isLiked: true, likesCount: 1, reaction: reactionType };
  }

  async toggleRepostPost(postId, username) {
    if (!postId) return { ok: false, error: 'Missing postId' };
    if (supabaseAdmin.isConfigured) {
      try {
        const rows = await supabaseAdmin.select('posts', `id=eq.${postId}&select=reposts_count`);
        if (rows && rows.length > 0) {
          const current = rows[0].reposts_count || 0;
          const newCount = current + 1;
          await supabaseAdmin.update('posts', { reposts_count: newCount }, `id=eq.${postId}`);
          return { ok: true, isReposted: true, repostsCount: newCount };
        }
      } catch (err) {
        console.error('[SocialManager] toggleRepostPost error:', err.message);
      }
    }
    return { ok: true, isReposted: true, repostsCount: 1 };
  }

  async voteComment(commentId, voteType = 'like') {
    if (!commentId) return { ok: false, error: 'Missing commentId' };
    if (supabaseAdmin.isConfigured) {
      try {
        const rows = await supabaseAdmin.select('comments', `id=eq.${commentId}&select=likes_count,dislikes_count`);
        if (rows && rows.length > 0) {
          let likes = rows[0].likes_count || 0;
          let dislikes = rows[0].dislikes_count || 0;
          if (voteType === 'dislike') {
            dislikes += 1;
          } else {
            likes += 1;
          }
          await supabaseAdmin.update('comments', { likes_count: likes, dislikes_count: dislikes }, `id=eq.${commentId}`);
          return { ok: true, likesCount: likes, dislikesCount: dislikes };
        }
      } catch (err) {
        console.error('[SocialManager] voteComment error:', err.message);
      }
    }
    return { ok: true, likesCount: voteType === 'like' ? 1 : 0, dislikesCount: voteType === 'dislike' ? 1 : 0 };
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
