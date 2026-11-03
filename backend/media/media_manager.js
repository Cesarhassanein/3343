const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { StorageAdapterFactory } = require('../storage/storage_adapter');
const config = require('../config');

class MediaManager {
  constructor() {
    this.metadataFile = path.resolve(__dirname, '..', '..', 'storage', 'media_mapping.json');
    this.mapping = new Map();
    this.cacheDir = config.cache.dir;
    this._initStorage();
  }

  _initStorage() {
    try {
      const dir = path.dirname(this.metadataFile);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    } catch (_) {}

    try {
      if (!fs.existsSync(this.cacheDir)) fs.mkdirSync(this.cacheDir, { recursive: true });
    } catch (_) {}

    try {
      if (fs.existsSync(this.metadataFile)) {
        const raw = fs.readFileSync(this.metadataFile, 'utf8');
        const list = JSON.parse(raw);
        if (Array.isArray(list)) {
          for (const item of list) {
            this.mapping.set(item.fileId, item);
          }
        }
      }
    } catch (_) {}
  }

  _saveMapping() {
    try {
      const list = Array.from(this.mapping.values());
      fs.writeFileSync(this.metadataFile, JSON.stringify(list, null, 2), 'utf8');
    } catch (_) {}
  }

  getAdapter() {
    return StorageAdapterFactory.getAdapter();
  }

  /**
   * Ingest Base64 or buffer and store using the active Storage Adapter
   */
  async uploadMedia(data, originalName = 'upload.jpg', category = 'image', metadata = {}) {
    let buffer;
    const ext = path.extname(originalName).toLowerCase();

    // 1. Determine mimeType from metadata, filename extension, or category
    let mimeType = metadata.mimeType;
    if (!mimeType) {
      if (ext === '.mp4') mimeType = 'video/mp4';
      else if (ext === '.webm') mimeType = 'video/webm';
      else if (ext === '.mov') mimeType = 'video/quicktime';
      else if (ext === '.mkv') mimeType = 'video/x-matroska';
      else if (ext === '.png') mimeType = 'image/png';
      else if (ext === '.webp') mimeType = 'image/webp';
      else if (ext === '.gif') mimeType = 'image/gif';
      else if (ext === '.jpg' || ext === '.jpeg') mimeType = 'image/jpeg';
      else if (ext === '.mp3') mimeType = 'audio/mpeg';
      else if (ext === '.ogg') mimeType = 'audio/ogg';
      else if (category === 'reel' || category === 'video') mimeType = 'video/mp4';
      else if (category === 'voice' || category === 'audio') mimeType = 'audio/mpeg';
      else mimeType = 'image/jpeg';
    }

    if (Buffer.isBuffer(data)) {
      buffer = data;
    } else if (typeof data === 'string') {
      if (data.startsWith('data:')) {
        const matches = data.match(/^data:([a-zA-Z0-9/+-]+);base64,(.+)$/);
        if (matches) {
          mimeType = matches[1];
          buffer = Buffer.from(matches[2], 'base64');
        } else {
          const comma = data.indexOf(',');
          const base64Str = comma !== -1 ? data.substring(comma + 1) : data;
          buffer = Buffer.from(base64Str, 'base64');
        }
      } else {
        buffer = Buffer.from(data, 'base64');
      }
    } else {
      throw new Error('Unsupported data format');
    }

    // Always enforce video MIME type if category is reel or video
    if ((category === 'reel' || category === 'video' || ext === '.mp4') && !mimeType.startsWith('video/')) {
      mimeType = 'video/mp4';
    }

    const adapter = this.getAdapter();
    const result = await adapter.uploadFile(buffer, originalName, mimeType, category, metadata);

    // Save metadata record
    this.mapping.set(result.fileId, {
      ...result,
      ownerUsername: metadata.ownerUsername || 'anon',
      originalName,
      createdAt: new Date().toISOString(),
    });
    this._saveMapping();

    return result;
  }

  getMetadata(fileId) {
    return this.mapping.get(fileId);
  }

  /**
   * Stream media file back to HTTP response with Range support
   */
  async streamMedia(fileId, req, res) {
    const adapter = this.getAdapter();
    const rangeHeader = req.headers['range'] || null;

    try {
      console.log(`[MediaManager] Streaming fileId: ${fileId.substring(0, 30)}...`);
      const { stream, statusCode, headers } = await adapter.getFileStream(fileId, rangeHeader);
      console.log(`[MediaManager] Got stream, status: ${statusCode}, type: ${headers['Content-Type']}`);

      // Determine true media MIME type
      const meta = this.getMetadata(fileId);
      let effectiveMime = meta?.mimeType;

      if (!effectiveMime || effectiveMime === 'application/octet-stream') {
        if (fileId.startsWith('AgAC')) {
          effectiveMime = 'image/jpeg';
        } else if (fileId.startsWith('BAAC')) {
          effectiveMime = 'video/mp4';
        } else if (meta?.category === 'reel' || meta?.category === 'video') {
          effectiveMime = 'video/mp4';
        } else {
          effectiveMime = 'image/jpeg';
        }
      }

      // Headers for seamless browser rendering and streaming
      const cleanHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Range, Authorization, Content-Type',
        'Access-Control-Expose-Headers': 'Content-Range, Content-Length, Accept-Ranges',
        'Content-Type': effectiveMime,
        'Content-Disposition': 'inline',
        'Cross-Origin-Resource-Policy': 'cross-origin',
      };
      for (const [k, v] of Object.entries(headers)) {
        if (k.toLowerCase() !== 'content-type' && k.toLowerCase() !== 'content-disposition' && v !== undefined && v !== null) {
          cleanHeaders[k] = v;
        }
      }

      res.writeHead(statusCode, cleanHeaders);
      stream.pipe(res);
      stream.on('end', () => console.log('[MediaManager] Stream complete'));
      stream.on('error', (err) => {
        console.error('[MediaManager] Stream error:', err.message);
        if (!res.writableEnded) res.end();
      });
    } catch (err) {
      console.error('[MediaManager] streamMedia error:', err.message);
      if (!res.headersSent) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
      }
      if (!res.writableEnded) {
        res.end(JSON.stringify({ error: 'Media not found', details: err.message }));
      }
    }
  }
}

module.exports = new MediaManager();
