const config = require('../config');

class TelegramWebhookHandler {
  constructor() {
    this.secret = config.telegram.webhookSecret;
    this.listeners = new Map();
  }

  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event).push(callback);
  }

  emit(event, data) {
    const list = this.listeners.get(event) || [];
    for (const cb of list) {
      try {
        cb(data);
      } catch (err) {
        console.error(`[WebhookHandler] Error in event listener for ${event}:`, err);
      }
    }
  }

  /**
   * Verify and process incoming Telegram webhook update
   */
  handleUpdate(req, res, update) {
    // 1. Verify Secret Token header if configured
    if (this.secret) {
      const headerSecret = req.headers['x-telegram-bot-api-secret-token'];
      if (headerSecret !== this.secret) {
        res.writeHead(403, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Unauthorized webhook secret' }));
        return;
      }
    }

    // Immediate 200 OK acknowledgment to prevent Telegram retries
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true }));

    try {
      this._parseAndDispatch(update);
    } catch (err) {
      console.error('[WebhookHandler] Error processing update payload:', err);
    }
  }

  _parseAndDispatch(update) {
    if (!update) return;

    // 1. Message event (in private channel or supergroup topic)
    if (update.message) {
      const msg = update.message;
      const threadId = msg.message_thread_id;
      const isTopicMessage = Boolean(threadId);

      this.emit('message', {
        messageId: msg.message_id,
        chatId: msg.chat.id,
        threadId,
        isTopicMessage,
        text: msg.text,
        hasMedia: Boolean(msg.photo || msg.video || msg.voice || msg.document),
        date: msg.date,
      });
    }

    // 2. Poll answer event
    if (update.poll_answer) {
      const answer = update.poll_answer;
      this.emit('poll_answer', {
        pollId: answer.poll_id,
        user: answer.user,
        optionIds: answer.option_ids,
      });
    }

    // 3. Channel post event
    if (update.channel_post) {
      this.emit('channel_post', update.channel_post);
    }
  }
}

module.exports = new TelegramWebhookHandler();
