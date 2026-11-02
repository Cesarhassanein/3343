import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wadiq Backend API Service
/// Centralized HTTP client for communicating with the Node.js backend proxy.
/// All media uploads go through this service → Backend → Telegram.
class WadiqApiService {
  WadiqApiService._();
  static final WadiqApiService instance = WadiqApiService._();

  static const _secureStorage = FlutterSecureStorage();
  static const String _keyAccessToken = 'wadiq_jwt_access_token';
  static const String _keyRefreshToken = 'wadiq_jwt_refresh_token';

  static const String defaultProductionBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://editors-dramatically-tourism-epa.trycloudflare.com',
  );

  /// Base URL for the backend API.
  String _baseUrl = defaultProductionBackendUrl;

  String get baseUrl => _baseUrl;

  /// Initialize with the backend URL.
  /// Call this in main() before runApp().
  Future<void> init({String? backendUrl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('wadiq_custom_backend_url');

      if (backendUrl != null && backendUrl.isNotEmpty) {
        _baseUrl = backendUrl;
      } else if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
      } else if (kIsWeb) {
        try {
          final origin = Uri.base.origin;
          if (origin.isNotEmpty && !origin.startsWith('file:') && origin != 'null') {
            _baseUrl = origin;
          } else {
            _baseUrl = defaultProductionBackendUrl;
          }
        } catch (_) {
          _baseUrl = defaultProductionBackendUrl;
        }
      } else {
        // Physical mobile device default - HTTPS production
        _baseUrl = defaultProductionBackendUrl;
      }

      if (_baseUrl.endsWith('/')) {
        _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
      }
    } catch (_) {
      _baseUrl = defaultProductionBackendUrl;
    }
    debugPrint('[WadiqAPI] Initialized with baseUrl: $_baseUrl');
  }

  Future<void> setBackendUrl(String newUrl) async {
    final clean = newUrl.trim();
    if (clean.isEmpty) return;
    _baseUrl = clean.endsWith('/') ? clean.substring(0, clean.length - 1) : clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wadiq_custom_backend_url', _baseUrl);
    } catch (_) {}
    debugPrint('[WadiqAPI] Updated baseUrl: $_baseUrl');
  }

  /// Build full URL for an API endpoint
  String _url(String path) {
    if (path.startsWith('http')) return path;
    return '$_baseUrl$path';
  }

  /// Build full URL for a media file (for display in Image/Video widgets)
  String getMediaUrl(String fileIdOrUrl) {
    if (fileIdOrUrl.isEmpty) return '';
    final clean = fileIdOrUrl.trim();
    if (clean.startsWith('data:')) return clean;

    // If it contains /api/media/, extract the path and prepend current _baseUrl
    if (clean.contains('/api/media/')) {
      final idx = clean.indexOf('/api/media/');
      var path = clean.substring(idx);
      if (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      return '$_baseUrl$path';
    }

    // Full 3rd-party URL (e.g. googleapis, dicebear, etc.)
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    // Raw file ID
    return '$_baseUrl/api/media/$clean';
  }

  /// Health check — verify backend is reachable
  Future<Map<String, dynamic>?> healthCheck() async {
    try {
      final response = await http.get(Uri.parse(_url('/api/health')))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[WadiqAPI] Health check failed: $e');
    }
    return null;
  }

  /// Upload media (image/video/audio) to backend → Telegram
  /// [data] can be:
  ///   - Base64 data URL string (data:image/jpeg;base64,...)
  ///   - Raw Base64 string
  ///   - Uint8List bytes (will be converted to Base64)
  /// Returns the upload result with fileId and url, or null on failure.
  Future<MediaUploadResult?> uploadMedia({
    required dynamic data,
    String fileName = 'upload.jpg',
    String category = 'image',
    String ownerUsername = 'anon',
  }) async {
    try {
      String base64Data;

      if (data is Uint8List) {
        // Detect mime type from file extension
        final mime = _mimeFromFileName(fileName);
        base64Data = 'data:$mime;base64,${base64Encode(data)}';
      } else if (data is String) {
        base64Data = data;
      } else {
        debugPrint('[WadiqAPI] Unsupported data type: ${data.runtimeType}');
        return null;
      }

      final response = await http.post(
        Uri.parse(_url('/api/media/upload')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': base64Data,
          'fileName': fileName,
          'category': category,
          'ownerUsername': ownerUsername,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['ok'] == true && json['fileId'] != null) {
          return MediaUploadResult(
            fileId: json['fileId'] as String,
            url: json['url'] as String? ?? '/api/media/${json['fileId']}',
            storageProvider: json['storageProvider'] as String? ?? 'unknown',
            mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
            sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
          );
        }
      }

      debugPrint('[WadiqAPI] Upload failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[WadiqAPI] Upload error: $e');
    }
    return null;
  }

  /// Upload image bytes and return the display URL
  /// Convenience method for common image upload pattern.
  Future<String?> uploadImageBytes(Uint8List bytes, {
    String fileName = 'image.jpg',
    String ownerUsername = 'anon',
  }) async {
    final result = await uploadMedia(
      data: bytes,
      fileName: fileName,
      category: 'image',
      ownerUsername: ownerUsername,
    );
    if (result != null) {
      return result.url;
    }
    return null;
  }

  /// Upload a Base64 data URL and return the relative API path (/api/media/fileId)
  Future<String?> uploadBase64Image(String dataUrl, {
    String fileName = 'image.jpg',
    String ownerUsername = 'anon',
  }) async {
    final result = await uploadMedia(
      data: dataUrl,
      fileName: fileName,
      category: 'image',
      ownerUsername: ownerUsername,
    );
    if (result != null) {
      return result.url;
    }
    return null;
  }

  /// Upload video and return the relative API path (/api/media/fileId)
  Future<String?> uploadVideoBytes(Uint8List bytes, {
    String fileName = 'video.mp4',
    String ownerUsername = 'anon',
  }) async {
    final result = await uploadMedia(
      data: bytes,
      fileName: fileName,
      category: 'reel',
      ownerUsername: ownerUsername,
    );
    if (result != null) {
      return result.url;
    }
    return null;
  }

  /// Initiate a call session via Agora
  Future<Map<String, dynamic>?> initiateCall({
    required String caller,
    required String receiver,
    bool isVideo = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_url('/api/calls/initiate')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'caller': caller,
          'receiver': receiver,
          'isVideo': isVideo,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[WadiqAPI] Call initiation error: $e');
    }
    return null;
  }

  // --- SECURE TOKENS ---
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _keyRefreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _keyAccessToken);
      await _secureStorage.delete(key: _keyRefreshToken);
    } catch (_) {}
  }

  Future<Map<String, String>> _authHeaders([Map<String, String>? extra]) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  // --- AUTHENTICATION ---
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String role = 'طالب',
    String? avatarUrl,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_url('/api/auth/register')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'avatarUrl': avatarUrl,
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['ok'] == true) {
        if (json['tokens'] != null) {
          final access = json['tokens']['accessToken']?.toString() ?? '';
          final refresh = json['tokens']['refreshToken']?.toString() ?? '';
          if (access.isNotEmpty) {
            await saveTokens(access, refresh);
          }
        }
        return {'success': true, 'user': json['user']};
      }
      return {'success': false, 'error': json['error'] ?? 'تعذر إنشاء الحساب.'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_url('/api/auth/login')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['ok'] == true) {
        if (json['tokens'] != null) {
          final access = json['tokens']['accessToken']?.toString() ?? '';
          final refresh = json['tokens']['refreshToken']?.toString() ?? '';
          if (access.isNotEmpty) {
            await saveTokens(access, refresh);
          }
        }
        return {'success': true, 'user': json['user']};
      }
      return {'success': false, 'error': json['error'] ?? 'بيانات الدخول غير صحيحة.'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> logoutUser() async {
    try {
      final headers = await _authHeaders();
      await http.post(Uri.parse(_url('/api/auth/logout')), headers: headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    await clearTokens();
  }

  Future<bool> checkUserExists(String username) async {
    try {
      final clean = username.replaceAll('@', '').trim().toLowerCase();
      final res = await http.get(Uri.parse(_url('/api/auth/check-user?u=$clean')))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return json['exists'] == true;
      }
    } catch (_) {}
    return false;
  }

  // --- COMMENTS ---
  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse(_url('/api/posts/$postId/comments')), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['comments'] is List) {
          return (json['comments'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addPostComment(String postId, Map<String, dynamic> comment) async {
    try {
      final headers = await _authHeaders();
      final res = await http.post(
        Uri.parse(_url('/api/posts/$postId/comments')),
        headers: headers,
        body: jsonEncode(comment),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // --- NOTIFICATIONS ---
  Future<List<Map<String, dynamic>>> getNotifications(String username) async {
    try {
      final headers = await _authHeaders();
      final clean = username.replaceAll('@', '').trim().toLowerCase();
      final res = await http.get(Uri.parse(_url('/api/notifications/$clean')), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['notifications'] is List) {
          return (json['notifications'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<bool> sendNotification({
    required String targetUsername,
    required String type,
    required String title,
    required String body,
    String? targetType,
    String? targetId,
  }) async {
    try {
      final headers = await _authHeaders();
      final res = await http.post(
        Uri.parse(_url('/api/notifications')),
        headers: headers,
        body: jsonEncode({
          'targetUsername': targetUsername,
          'type': type,
          'title': title,
          'body': body,
          'targetType': targetType,
          'targetId': targetId,
        }),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  String _mimeFromFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Result from a successful media upload
class MediaUploadResult {
  final String fileId;
  final String url;
  final String storageProvider;
  final String mimeType;
  final int sizeBytes;

  MediaUploadResult({
    required this.fileId,
    required this.url,
    required this.storageProvider,
    required this.mimeType,
    required this.sizeBytes,
  });

  @override
  String toString() => 'MediaUploadResult(fileId: $fileId, url: $url, provider: $storageProvider)';
}
