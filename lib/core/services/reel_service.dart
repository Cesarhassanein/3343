import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'wadiq_api_service.dart';

class ReelModel {
  final String id;
  final String creatorName;
  final String creatorUsername;
  String? creatorAvatarUrl;
  final String videoUrl;
  final String? caption;
  final String soundTitle;
  final bool isVerified;
  int viewsCount;
  int likesCount;
  int commentsCount;
  bool isLiked;
  bool isFollowing;
  final List<Map<String, String>> comments;
  final DateTime createdAt;

  ReelModel({
    required this.id,
    required this.creatorName,
    required this.creatorUsername,
    this.creatorAvatarUrl,
    required this.videoUrl,
    this.caption,
    this.soundTitle = 'الصوت الأصلي',
    this.isVerified = false,
    this.viewsCount = 1,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isFollowing = false,
    List<Map<String, String>>? comments,
    required this.createdAt,
  }) : comments = comments ?? [];

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'منذ لحظات';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }

  factory ReelModel.fromMap(Map<String, dynamic> map) {
    return ReelModel(
      id: map['id']?.toString() ?? '',
      creatorName: map['creator_name']?.toString() ?? 'صانع محتوى',
      creatorUsername: map['creator_username']?.toString() ?? 'creator',
      creatorAvatarUrl: map['creator_avatar_url']?.toString() ?? map['avatar_url']?.toString(),
      videoUrl: map['video_url']?.toString() ?? '',
      caption: map['caption']?.toString(),
      soundTitle: map['sound_title']?.toString() ?? 'الصوت الأصلي',
      isVerified: map['is_verified'] == true,
      viewsCount: (map['views_count'] as num?)?.toInt() ?? 1,
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ReelService {
  ReelService._();
  static final ReelService instance = ReelService._();

  final List<ReelModel> _localReels = [];
  final Set<String> _likedReelIds = {};
  final Set<String> _savedSounds = {};
  final Set<String> _savedReelIds = {};
  bool _preferencesLoaded = false;

  Future<void> _loadPreferences() async {
    if (_preferencesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final liked = prefs.getStringList('wadiq_liked_reels');
      if (liked != null) _likedReelIds.addAll(liked);

      final sounds = prefs.getStringList('wadiq_saved_sounds');
      if (sounds != null) _savedSounds.addAll(sounds);

      final saved = prefs.getStringList('wadiq_saved_reels');
      if (saved != null) _savedReelIds.addAll(saved);

      _preferencesLoaded = true;
    } catch (_) {}
  }

  Future<void> _saveLikedReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_liked_reels', _likedReelIds.toList());
    } catch (_) {}
  }

  Future<void> _saveSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_saved_sounds', _savedSounds.toList());
    } catch (_) {}
  }

  Future<void> _saveSavedReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_saved_reels', _savedReelIds.toList());
    } catch (_) {}
  }

  bool isReelSaved(String reelId) => _savedReelIds.contains(reelId);

  void toggleSaveReel(String reelId) {
    if (_savedReelIds.contains(reelId)) {
      _savedReelIds.remove(reelId);
    } else {
      _savedReelIds.add(reelId);
    }
    _saveSavedReels();
  }

  bool isSoundSaved(String soundTitle) => _savedSounds.contains(soundTitle);

  void toggleSaveSound(String soundTitle) {
    if (_savedSounds.contains(soundTitle)) {
      _savedSounds.remove(soundTitle);
    } else {
      _savedSounds.add(soundTitle);
      NotificationService.instance.addNotification(
        type: 'system',
        title: 'تم حفظ الصوت',
        body: 'تمت إضافة "$soundTitle" إلى قائمة الأصوات المحفوظة.',
      );
    }
    _saveSounds();
  }

  Future<List<ReelModel>> fetchReels() async {
    await _loadPreferences();

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('reels')
            .select('*')
            .order('created_at', ascending: false);

        final list = (res as List<dynamic>)
            .map((item) => ReelModel.fromMap(item as Map<String, dynamic>))
            .toList();

        final Map<String, ReelModel> merged = {};
        for (var r in _localReels) {
          merged[r.id] = r;
        }
        for (var r in list) {
          merged[r.id] = r;
        }
        final combined = merged.values.toList();
        combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        for (var r in combined) {
          r.isLiked = _likedReelIds.contains(r.id);
        }

        // Attach creator profile avatar if missing
        try {
          final profilesRes = await client.from('profiles').select('username, avatar_url');
          final avatarMap = <String, String>{};
          for (var p in (profilesRes as List<dynamic>)) {
            final u = p['username']?.toString().toLowerCase();
            final av = p['avatar_url']?.toString();
            if (u != null && av != null && av.isNotEmpty) {
              avatarMap[u] = av;
            }
          }
          for (var r in combined) {
            if (r.creatorAvatarUrl == null || r.creatorAvatarUrl!.isEmpty) {
              final matchedAvatar = avatarMap[r.creatorUsername.toLowerCase()];
              if (matchedAvatar != null) {
                r.creatorAvatarUrl = matchedAvatar;
              }
            }
          }
        } catch (_) {}

        return combined;
      } catch (e) {
        debugPrint('Error fetching reels: $e');
      }
    }

    final local = List<ReelModel>.from(_localReels);
    for (var r in local) {
      r.isLiked = _likedReelIds.contains(r.id);
    }
    return local;
  }

  List<ReelModel> filterFollowedReels(List<ReelModel> allReels, Set<String> followedUsernames) {
    return allReels.where((r) => followedUsernames.contains(r.creatorUsername.toLowerCase())).toList();
  }

  Future<List<ReelModel>> fetchReelsByUser(String username) async {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    final all = await fetchReels();
    return all.where((r) => r.creatorUsername.toLowerCase() == clean).toList();
  }

  Future<bool> createReel({
    required String videoUrl,
    String? caption,
    String soundTitle = 'الصوت الأصلي',
  }) async {
    final user = AuthService.instance.currentUser;
    final now = DateTime.now();

    final newReel = ReelModel(
      id: 'reel_${now.millisecondsSinceEpoch}',
      creatorName: user.fullName,
      creatorUsername: user.username,
      videoUrl: videoUrl.trim(),
      caption: caption?.trim(),
      soundTitle: soundTitle,
      isVerified: false,
      viewsCount: 1,
      createdAt: now,
    );

    _localReels.insert(0, newReel);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('reels').insert({
          'creator_name': user.fullName,
          'creator_username': user.username,
          'video_url': videoUrl.trim(),
          'caption': caption?.trim(),
          'sound_title': soundTitle,
          'created_at': now.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error inserting reel to Supabase: $e');
      }
    }

    return true;
  }

  void incrementViews(ReelModel reel) {
    reel.viewsCount += 1;
    final client = SupabaseConfig.client;
    if (client != null) {
      client.from('reels').update({'views_count': reel.viewsCount}).eq('id', reel.id).then((_) {}, onError: (_) {});
    }
  }

  void toggleLike(ReelModel reel) {
    reel.isLiked = !reel.isLiked;
    reel.likesCount += reel.isLiked ? 1 : -1;
    if (reel.likesCount < 0) reel.likesCount = 0;

    if (reel.isLiked) {
      _likedReelIds.add(reel.id);
      NotificationService.instance.sendNotificationToUser(
        targetUsername: reel.creatorUsername,
        type: 'like',
        title: 'إعجاب جديد بمقطع ريلزك',
        body: 'سجّل @${AuthService.instance.currentUser.username} إعجابه بمقطع الريلز.',
        targetType: 'user',
        targetId: reel.creatorUsername,
      );
    } else {
      _likedReelIds.remove(reel.id);
    }

    _saveLikedReels();

    final client = SupabaseConfig.client;
    if (client != null) {
      client
          .from('reels')
          .update({'likes_count': reel.likesCount})
          .eq('id', reel.id)
          .then((_) {}, onError: (_) {});
    }
  }

  Future<void> addComment(ReelModel reel, String commentText) async {
    final user = AuthService.instance.currentUser;
    final cleanComment = commentText.trim();
    if (cleanComment.isEmpty) return;

    reel.commentsCount += 1;
    reel.comments.insert(0, {
      'user': user.fullName,
      'username': user.username,
      'comment': cleanComment,
      'time': 'الآن',
    });

    // Save to persistent backend storage
    try {
      await WadiqApiService.instance.addPostComment(
        reel.id,
        {
          'authorName': user.fullName,
          'authorUsername': user.username,
          'content': cleanComment,
        },
      );
    } catch (_) {}

    // Update Supabase
    final client = SupabaseConfig.client;
    if (client != null) {
      client.from('reels').update({'comments_count': reel.commentsCount}).eq('id', reel.id).then((_) {}, onError: (_) {});
    }

    NotificationService.instance.sendNotificationToUser(
      targetUsername: reel.creatorUsername,
      type: 'comment',
      title: 'تعليق جديد على ريلزك',
      body: 'علّق @${user.username} على ريلز الخاص بك: "$cleanComment"',
      targetType: 'user',
      targetId: reel.creatorUsername,
    );
  }
}
