const fs = require('fs');
const path = require('path');

// Safe, zero-dependency .env loader
function loadEnv() {
  const envPath = path.join(__dirname, '..', '.env');
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    for (const line of content.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx !== -1) {
        const key = trimmed.substring(0, eqIdx).trim();
        const value = trimmed.substring(eqIdx + 1).trim();
        if (process.env[key] === undefined) {
          process.env[key] = value.replace(/^["']|["']$/g, '');
        }
      }
    }
  }
}

loadEnv();

const config = {
  port: parseInt(process.env.PORT || '8080', 10),
  host: process.env.HOST || '0.0.0.0',
  nodeEnv: process.env.NODE_ENV || 'development',
  storageProvider: (process.env.STORAGE_PROVIDER || 'local').toLowerCase(),

  telegram: {
    botToken: process.env.TELEGRAM_BOT_TOKEN || '',
    apiId: process.env.TELEGRAM_API_ID || '',
    apiHash: process.env.TELEGRAM_API_HASH || '',
    channels: {
      images: process.env.TELEGRAM_STORAGE_CHANNEL_IMAGES || '',
      reels: process.env.TELEGRAM_STORAGE_CHANNEL_REELS || '',
      voice: process.env.TELEGRAM_STORAGE_CHANNEL_VOICE || '',
      registrations: process.env.TELEGRAM_STORAGE_CHANNEL_REGISTRATIONS || process.env.TELEGRAM_STORAGE_CHANNEL_IMAGES || '',
      avatars: process.env.TELEGRAM_STORAGE_CHANNEL_AVATARS || process.env.TELEGRAM_STORAGE_CHANNEL_IMAGES || '',
      audio: process.env.TELEGRAM_STORAGE_CHANNEL_AUDIO || process.env.TELEGRAM_STORAGE_CHANNEL_VOICE || '',
      supergroup: process.env.TELEGRAM_COMMUNITY_SUPERGROUP_ID || '',
    },
    rateLimitOpsPerSec: parseInt(process.env.TELEGRAM_RATE_LIMIT_OPS_PER_SEC || '25', 10),
    webhookSecret: process.env.TELEGRAM_WEBHOOK_SECRET || '',
    isConfigured() {
      return Boolean(this.botToken && this.botToken.includes(':'));
    }
  },

  supabase: {
    url: process.env.SUPABASE_URL || '',
    anonKey: process.env.SUPABASE_ANON_KEY || '',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  },

  agora: {
    appId: process.env.AGORA_APP_ID || '',
    appCertificate: process.env.AGORA_APP_CERTIFICATE || '',
    expirationSeconds: parseInt(process.env.AGORA_TOKEN_EXPIRATION_SECONDS || '3600', 10),
    isConfigured() {
      return Boolean(this.appId);
    }
  },

  cache: {
    dir: path.resolve(__dirname, '..', process.env.MEDIA_CACHE_DIR || './storage/cache'),
    maxSizeMb: parseInt(process.env.MEDIA_MAX_CACHE_SIZE_MB || '500', 10),
  }
};

module.exports = config;
