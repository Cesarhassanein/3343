const https = require('https');
const crypto = require('crypto');
const TaskQueue = require('./queue');
const config = require('../config');

class TelegramService {
  constructor() {
    this.botToken = config.telegram.botToken;
    this.queue = new TaskQueue(config.telegram.rateLimitOpsPerSec);
  }

  isConfigured() {
    return config.telegram.isConfigured();
  }

  /**
   * Execute raw Telegram API call through rate limiter queue
   */
  async callApi(method, payload = {}) {
    if (!this.isConfigured()) {
      return {
        ok: false,
        mock: true,
        description: 'Telegram bot token is not configured in .env',
      };
    }

    return this.queue.enqueue(async () => {
      return new Promise((resolve, reject) => {
        const bodyStr = JSON.stringify(payload);
        const options = {
          hostname: 'api.telegram.org',
          path: `/bot${this.botToken}/${method}`,
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(bodyStr),
          },
        };

        const req = https.request(options, (res) => {
          let data = '';
          res.on('data', chunk => data += chunk);
          res.on('end', () => {
            try {
              const parsed = JSON.parse(data);
              if (parsed.ok) {
                resolve(parsed.result);
              } else {
                const err = new Error(parsed.description || 'Telegram API Error');
                err.response = parsed;
                reject(err);
              }
            } catch (e) {
              reject(new Error(`Failed to parse Telegram API response: ${data}`));
            }
          });
        });

        req.on('error', reject);
        req.write(bodyStr);
        req.end();
      });
    });
  }

  /**
   * Upload binary buffer as multipart/form-data to a Telegram channel
   */
  async uploadBinary(endpoint, chatId, fieldName, fileBuffer, fileName, mimeType, caption = '', threadId = null) {
    if (!this.isConfigured()) {
      const mockId = `mock_tg_${crypto.randomUUID()}`;
      return {
        file_id: mockId,
        message_id: Math.floor(Math.random() * 100000),
        file_size: fileBuffer.length,
        mock: true,
      };
    }

    return this.queue.enqueue(async () => {
      return new Promise((resolve, reject) => {
        const boundary = '----WebKitFormBoundary' + crypto.randomBytes(16).toString('hex');
        const crlf = '\r\n';

        let postDataHeader = '';
        postDataHeader += `--${boundary}${crlf}`;
        postDataHeader += `Content-Disposition: form-data; name="chat_id"${crlf}${crlf}${chatId}${crlf}`;

        if (threadId) {
          postDataHeader += `--${boundary}${crlf}`;
          postDataHeader += `Content-Disposition: form-data; name="message_thread_id"${crlf}${crlf}${threadId}${crlf}`;
        }

        if (caption) {
          postDataHeader += `--${boundary}${crlf}`;
          postDataHeader += `Content-Disposition: form-data; name="caption"${crlf}${crlf}${caption}${crlf}`;
        }

        postDataHeader += `--${boundary}${crlf}`;
        postDataHeader += `Content-Disposition: form-data; name="${fieldName}"; filename="${fileName}"${crlf}`;
        postDataHeader += `Content-Type: ${mimeType}${crlf}${crlf}`;

        const postDataFooter = `${crlf}--${boundary}--${crlf}`;

        const headerBuf = Buffer.from(postDataHeader, 'utf8');
        const footerBuf = Buffer.from(postDataFooter, 'utf8');
        const totalLength = headerBuf.length + fileBuffer.length + footerBuf.length;

        const options = {
          hostname: 'api.telegram.org',
          path: `/bot${this.botToken}/${endpoint}`,
          method: 'POST',
          headers: {
            'Content-Type': `multipart/form-data; boundary=${boundary}`,
            'Content-Length': totalLength,
          },
        };

        const req = https.request(options, (res) => {
          let data = '';
          res.on('data', chunk => data += chunk);
          res.on('end', () => {
            try {
              const parsed = JSON.parse(data);
              if (parsed.ok) {
                const result = parsed.result;
                let fileId = null;
                if (result.photo) {
                  fileId = result.photo[result.photo.length - 1].file_id;
                } else if (result.video) {
                  fileId = result.video.file_id;
                } else if (result.voice) {
                  fileId = result.voice.file_id;
                } else if (result.document) {
                  fileId = result.document.file_id;
                }
                resolve({
                  file_id: fileId,
                  message_id: result.message_id,
                  chat_id: result.chat.id,
                  file_size: fileBuffer.length,
                });
              } else {
                const err = new Error(parsed.description || 'Upload failed');
                err.response = parsed;
                reject(err);
              }
            } catch (e) {
              reject(new Error(`Failed to parse response: ${data}`));
            }
          });
        });

        req.on('error', reject);
        req.write(headerBuf);
        req.write(fileBuffer);
        req.write(footerBuf);
        req.end();
      });
    }, 8); // High priority for uploads
  }

  /**
   * Get direct downloadable file path for a file_id
   */
  async getFilePath(fileId) {
    if (!this.isConfigured() || fileId.startsWith('mock_')) {
      return null;
    }
    const info = await this.callApi('getFile', { file_id: fileId });
    if (info && info.file_path) {
      return `https://api.telegram.org/file/bot${this.botToken}/${info.file_path}`;
    }
    return null;
  }

  /**
   * Create a Forum Topic in a Telegram Supergroup
   */
  async createForumTopic(supergroupId, name, iconColor = 0x6FB9F0) {
    if (!this.isConfigured()) {
      return {
        message_thread_id: Math.floor(Math.random() * 10000),
        name,
        mock: true,
      };
    }
    return this.callApi('createForumTopic', {
      chat_id: supergroupId,
      name,
      icon_color: iconColor,
    });
  }

  /**
   * Send a message to a specific Forum Topic
   */
  async sendTopicMessage(supergroupId, threadId, text) {
    if (!this.isConfigured()) {
      return { message_id: Math.floor(Math.random() * 100000), mock: true };
    }
    return this.callApi('sendMessage', {
      chat_id: supergroupId,
      message_thread_id: threadId,
      text,
    });
  }
}

module.exports = new TelegramService();
