const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const crypto = require('crypto');
const telegramService = require('../telegram/telegram_service');
const config = require('../config');

class BaseStorageAdapter {
  async uploadFile(buffer, filename, mimeType, category, metadata = {}) {
    throw new Error('Not implemented');
  }

  async getFileStream(fileId, rangeHeader = null) {
    throw new Error('Not implemented');
  }

  async deleteFile(fileId) {
    throw new Error('Not implemented');
  }

  getFileUrl(fileId) {
    return `/api/media/${fileId}`;
  }
}

/**
 * Telegram Storage Adapter:
 * Stores media in private segmented channels and streams via proxy
 */
class TelegramStorageAdapter extends BaseStorageAdapter {
  constructor() {
    super();
    this.channels = config.telegram.channels;
  }

  _getTargetChannel(category) {
    switch (category) {
      case 'reel':
      case 'video':
        return this.channels.reels || this.channels.images;
      case 'voice':
      case 'audio':
        return this.channels.audio || this.channels.voice || this.channels.images;
      case 'avatar':
        return this.channels.avatars || this.channels.images;
      case 'image':
      default:
        return this.channels.images;
    }
  }

  _getEndpoint(mimeType = '', category = '', filename = '') {
    const fn = (filename || '').toLowerCase();
    const mime = (mimeType || '').toLowerCase();
    const cat = (category || '').toLowerCase();

    // Priority 1: Video (Reel, Video, .mp4, .mov, .webm, .mkv)
    if (cat === 'reel' || cat === 'video' || mime.startsWith('video/') || fn.endsWith('.mp4') || fn.endsWith('.mov') || fn.endsWith('.webm') || fn.endsWith('.mkv')) {
      return { endpoint: 'sendVideo', field: 'video' };
    }

    // Priority 2: Audio (Voice, Audio, .mp3, .ogg, .m4a, .wav)
    if (cat === 'voice' || cat === 'audio' || mime.startsWith('audio/') || fn.endsWith('.mp3') || fn.endsWith('.ogg') || fn.endsWith('.m4a') || fn.endsWith('.wav')) {
      return { endpoint: 'sendVoice', field: 'voice' };
    }

    // Priority 3: Photo (Avatar, Image, .jpg, .png, etc.)
    if (cat === 'avatar' || cat === 'image' || mime.startsWith('image/') || fn.endsWith('.jpg') || fn.endsWith('.jpeg') || fn.endsWith('.png') || fn.endsWith('.webp') || fn.endsWith('.gif')) {
      return { endpoint: 'sendPhoto', field: 'photo' };
    }

    // Default: document
    return { endpoint: 'sendDocument', field: 'document' };
  }

  async uploadFile(buffer, filename, mimeType, category = 'image', metadata = {}) {
    const targetChannel = this._getTargetChannel(category);
    let { endpoint, field } = this._getEndpoint(mimeType, category, filename);

    // Guarantee proper video MIME type when sending video
    if (endpoint === 'sendVideo' && (!mimeType || !mimeType.startsWith('video/'))) {
      mimeType = 'video/mp4';
    }

    const caption = `Wadiq Storage | ${category} | User: ${metadata.ownerUsername || 'anon'}`;

    let result;
    try {
      result = await telegramService.uploadBinary(
        endpoint,
        targetChannel,
        field,
        buffer,
        filename,
        mimeType,
        caption
      );
    } catch (err) {
      // Fallback: if sendPhoto or sendVideo fails, try sendDocument
      if ((endpoint === 'sendPhoto' || endpoint === 'sendVideo') && err.message) {
        console.warn(`[TelegramStorage] ${endpoint} failed (${err.message}), falling back to sendDocument`);
        result = await telegramService.uploadBinary(
          'sendDocument',
          targetChannel,
          'document',
          buffer,
          filename,
          mimeType,
          caption
        );
      } else {
        throw err;
      }
    }

    return {
      fileId: result.file_id,
      storageProvider: 'telegram',
      mimeType,
      sizeBytes: buffer.length,
      telegramMessageId: result.message_id,
      telegramChatId: targetChannel,
      category,
      url: this.getFileUrl(result.file_id),
      createdAt: new Date().toISOString(),
    };
  }

  async getFileStream(fileId, rangeHeader = null) {
    const directUrl = await telegramService.getFilePath(fileId);
    if (!directUrl) {
      throw new Error(`File not found or Telegram not configured for fileId: ${fileId}`);
    }

    return this._fetchWithRedirect(directUrl, rangeHeader, 3);
  }

  _fetchWithRedirect(fileUrl, rangeHeader, maxRedirects) {
    return new Promise((resolve, reject) => {
      const headers = {};
      if (rangeHeader) {
        headers['Range'] = rangeHeader;
      }

      const req = https.get(fileUrl, { headers, timeout: 15000 }, (res) => {
        // Follow redirects (301, 302, 307, 308)
        if ([301, 302, 307, 308].includes(res.statusCode) && res.headers.location && maxRedirects > 0) {
          res.resume(); // consume response to free socket
          this._fetchWithRedirect(res.headers.location, rangeHeader, maxRedirects - 1)
            .then(resolve).catch(reject);
          return;
        }

        if (res.statusCode >= 400) {
          res.resume();
          reject(new Error(`Telegram CDN returned status ${res.statusCode}`));
          return;
        }

        resolve({
          stream: res,
          statusCode: res.statusCode === 206 ? 206 : 200,
          headers: {
            'Content-Type': res.headers['content-type'] || 'application/octet-stream',
            'Content-Length': res.headers['content-length'],
            'Content-Range': res.headers['content-range'],
            'Accept-Ranges': 'bytes',
            'Cache-Control': 'public, max-age=604800, immutable',
          },
        });
      });
      req.on('error', reject);
      req.on('timeout', () => { req.destroy(); reject(new Error('Telegram CDN timeout')); });
    });
  }

  async deleteFile(fileId) {
    // In Telegram channels, messages can be deleted by message_id
    return true;
  }
}

/**
 * Local Disk Storage Adapter:
 * Fallback when Telegram keys are absent or for offline testing
 */
class LocalStorageAdapter extends BaseStorageAdapter {
  constructor() {
    super();
    this.uploadDir = process.env.VERCEL
      ? path.join(require('os').tmpdir(), 'wadiq-uploads')
      : path.resolve(__dirname, '..', '..', 'storage', 'uploads');
    try {
      if (!fs.existsSync(this.uploadDir)) {
        fs.mkdirSync(this.uploadDir, { recursive: true });
      }
    } catch (_) {}
  }

  async uploadFile(buffer, filename, mimeType, category = 'image', metadata = {}) {
    const ext = path.extname(filename) || (mimeType.includes('png') ? '.png' : mimeType.includes('mp4') ? '.mp4' : '.jpg');
    const fileId = `wadiq_${Date.now()}_${crypto.randomBytes(6).toString('hex')}${ext}`;
    const filePath = path.join(this.uploadDir, fileId);

    await fs.promises.writeFile(filePath, buffer);

    return {
      fileId,
      storageProvider: 'local',
      mimeType,
      sizeBytes: buffer.length,
      category,
      url: this.getFileUrl(fileId),
      createdAt: new Date().toISOString(),
    };
  }

  async getFileStream(fileId, rangeHeader = null) {
    const filePath = path.join(this.uploadDir, path.basename(fileId));
    if (!fs.existsSync(filePath)) {
      throw new Error(`Local file not found: ${fileId}`);
    }

    const stat = await fs.promises.stat(filePath);
    const fileSize = stat.size;

    if (rangeHeader) {
      const parts = rangeHeader.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
      const chunksize = (end - start) + 1;
      const fileStream = fs.createReadStream(filePath, { start, end });

      return {
        stream: fileStream,
        statusCode: 206,
        headers: {
          'Content-Range': `bytes ${start}-${end}/${fileSize}`,
          'Accept-Ranges': 'bytes',
          'Content-Length': chunksize,
          'Content-Type': this._guessMimeType(filePath),
        },
      };
    } else {
      const fileStream = fs.createReadStream(filePath);
      return {
        stream: fileStream,
        statusCode: 200,
        headers: {
          'Content-Length': fileSize,
          'Accept-Ranges': 'bytes',
          'Content-Type': this._guessMimeType(filePath),
          'Cache-Control': 'public, max-age=86400',
        },
      };
    }
  }

  _guessMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    const map = {
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.mp4': 'video/mp4',
      '.webm': 'video/webm',
      '.ogg': 'audio/ogg',
      '.mp3': 'audio/mpeg',
    };
    return map[ext] || 'application/octet-stream';
  }

  async deleteFile(fileId) {
    const filePath = path.join(this.uploadDir, path.basename(fileId));
    if (fs.existsSync(filePath)) {
      await fs.promises.unlink(filePath);
    }
    return true;
  }
}

/**
 * Storage Adapter Factory
 */
class StorageAdapterFactory {
  static getAdapter() {
    const provider = config.storageProvider;
    if (provider === 'telegram' && config.telegram.isConfigured()) {
      return new TelegramStorageAdapter();
    }
    // Default safe fallback to LocalStorageAdapter
    return new LocalStorageAdapter();
  }
}

module.exports = {
  BaseStorageAdapter,
  TelegramStorageAdapter,
  LocalStorageAdapter,
  StorageAdapterFactory,
};
