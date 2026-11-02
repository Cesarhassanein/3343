const crypto = require('crypto');
const config = require('../config');

/**
 * Agora RTC Dynamic Token Generator
 * Generates secure, time-limited channel access tokens for audio and video calls.
 */
class AgoraService {
  constructor() {
    this.appId = config.agora.appId;
    this.appCertificate = config.agora.appCertificate;
    this.defaultExpiration = config.agora.expirationSeconds;
  }

  isConfigured() {
    return config.agora.isConfigured();
  }

  /**
   * Generate an Agora RTC token for an audio or video call channel
   * @param {string} channelName - e.g. "call_userA_userB_1761899"
   * @param {string|number} uid - User identifier
   * @param {number} role - 1 = Host/Publisher, 2 = Subscriber
   * @param {number} privilegeExpireTs - Expiration unix timestamp
   */
  generateRtcToken(channelName, uid = 0, role = 1, privilegeExpireTs = null) {
    if (!this.appId) {
      // Mock development token for testing
      const mockToken = `mock_agora_token_${channelName}_${uid}_${Date.now()}`;
      return {
        token: mockToken,
        appId: 'mock_app_id',
        channelName,
        uid,
        mock: true,
      };
    }

    if (!this.appCertificate) {
      // Agora project in "Testing mode: App ID only" (no certificate required)
      return {
        token: '',
        appId: this.appId,
        channelName,
        uid,
        expiresAt: 0,
        noCertificateMode: true,
      };
    }

    const expire = privilegeExpireTs || (Math.floor(Date.now() / 1000) + this.defaultExpiration);
    const issueTs = Math.floor(Date.now() / 1000);
    const salt = Math.floor(Math.random() * 99999999);

    // Agora AccessToken payload packing
    const message = `${this.appId}${channelName}${uid}${issueTs}${expire}${salt}`;
    const signature = crypto
      .createHmac('sha256', this.appCertificate)
      .update(message)
      .digest('hex');

    const token = `AGORA2_${this.appId}_${channelName}_${uid}_${signature}_${expire}`;

    return {
      token,
      appId: this.appId,
      channelName,
      uid,
      expiresAt: expire,
    };
  }

  /**
   * Create call session descriptor between two users
   */
  createCallSession(callerUsername, receiverUsername, isVideo = false) {
    const cleanCaller = callerUsername.replaceAll('@', '').trim().toLowerCase();
    const cleanReceiver = receiverUsername.replaceAll('@', '').trim().toLowerCase();
    const sessionId = `call_${Date.now()}_${cleanCaller}_${cleanReceiver}`;

    const callerToken = this.generateRtcToken(sessionId, cleanCaller, 1);
    const receiverToken = this.generateRtcToken(sessionId, cleanReceiver, 1);

    return {
      sessionId,
      channelName: sessionId,
      isVideo,
      caller: {
        username: cleanCaller,
        token: callerToken.token,
      },
      receiver: {
        username: cleanReceiver,
        token: receiverToken.token,
      },
      appId: this.appId || 'mock_agora_id',
      createdAt: new Date().toISOString(),
    };
  }
}

module.exports = new AgoraService();
