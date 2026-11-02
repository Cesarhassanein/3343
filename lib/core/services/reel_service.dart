import 'dart:convert';
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
  bool isSaved;
  bool isReposted;
  final List<Map<String, dynamic>> comments;
  final DateTime createdAt;
  double playbackSpeed;

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
    this.isSaved = false,
    this.isReposted = false,
    List<Map<String, dynamic>>? comments,
    required this.createdAt,
    this.playbackSpeed = 1.0,
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
  final Set<String> _repostedReelIds = {};
  final Set<String> _notInterestedIds = {};
  final Map<String, List<String>> _collections = {
    'المحفوظات العامة': [],
    'تعليمي 🎓': [],
    'مفضلتي ⭐': [],
  };
  final Map<String, List<Map<String, dynamic>>> _cachedComments = {};
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

      final reposted = prefs.getStringList('wadiq_reposted_reels');
      if (reposted != null) _repostedReelIds.addAll(reposted);

      final notInt = prefs.getStringList('wadiq_not_interested_reels');
      if (notInt != null) _notInterestedIds.addAll(notInt);

      final collectionsJson = prefs.getString('wadiq_reel_collections');
      if (collectionsJson != null) {
        final decoded = jsonDecode(collectionsJson) as Map<String, dynamic>;
        for (var entry in decoded.entries) {
          _collections[entry.key] = List<String>.from(entry.value as List);
        }
      }

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
      await prefs.setString('wadiq_reel_collections', jsonEncode(_collections));
    } catch (_) {}
  }

  Future<void> _saveRepostedReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_reposted_reels', _repostedReelIds.toList());
    } catch (_) {}
  }

  Future<void> _saveNotInterested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_not_interested_reels', _notInterestedIds.toList());
    } catch (_) {}
  }

  // --- PLATFORM SAVING & COLLECTIONS ---
  bool isReelSaved(String reelId) => _savedReelIds.contains(reelId);

  List<String> getCollections() {
    return _collections.keys.toList();
  }

  Map<String, int> getCollectionsCounts() {
    return _collections.map((k, v) => MapEntry(k, v.length));
  }

  Future<void> createCollection(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || _collections.containsKey(clean)) return;
    _collections[clean] = [];
    await _saveSavedReels();
  }

  Future<bool> saveReelToPlatform(ReelModel reel, {String? collectionName}) async {
    final user = AuthService.instance.currentUser;
    _savedReelIds.add(reel.id);
    reel.isSaved = true;

    final targetCollection = collectionName ?? 'المحفوظات العامة';
    if (!_collections.containsKey(targetCollection)) {
      _collections[targetCollection] = [];
    }
    if (!_collections[targetCollection]!.contains(reel.id)) {
      _collections[targetCollection]!.add(reel.id);
    }

    await _saveSavedReels();

    // Notify reel creator
    try {
      NotificationService.instance.sendNotificationToUser(
        targetUsername: reel.creatorUsername,
        type: 'save',
        title: 'تم حفظ مقطعك 🔖',
        body: 'قام @${user.username} بحفظ مقطع الريلز الخاص بك في مجموعاته على المنصة.',
        targetType: 'user',
        targetId: reel.creatorUsername,
      );
    } catch (_) {}

    // Save to Supabase saved_posts if valid UUID
    final client = SupabaseConfig.client;
    if (client != null && user.id.isNotEmpty) {
      try {
        await client.from('saved_posts').insert({
          'user_id': user.id,
          'post_id': reel.id,
        });
      } catch (_) {}
    }

    return true;
  }

  Future<void> removeReelFromPlatform(String reelId) async {
    _savedReelIds.remove(reelId);
    for (var list in _collections.values) {
      list.remove(reelId);
    }
    await _saveSavedReels();

    final user = AuthService.instance.currentUser;
    final client = SupabaseConfig.client;
    if (client != null && user.id.isNotEmpty) {
      try {
        await client.from('saved_posts').delete().match({'user_id': user.id, 'post_id': reelId});
      } catch (_) {}
    }
  }

  Future<void> addReelToCollection(String reelId, String collectionName) async {
    if (!_collections.containsKey(collectionName)) {
      _collections[collectionName] = [];
    }
    if (!_collections[collectionName]!.contains(reelId)) {
      _collections[collectionName]!.add(reelId);
    }
    _savedReelIds.add(reelId);
    await _saveSavedReels();
  }

  List<String> getCollectionsForReel(String reelId) {
    final list = <String>[];
    for (var entry in _collections.entries) {
      if (entry.value.contains(reelId)) list.add(entry.key);
    }
    return list;
  }

  // --- REPOSTING ---
  bool isReelReposted(String reelId) => _repostedReelIds.contains(reelId);

  Future<void> toggleRepost(ReelModel reel) async {
    final user = AuthService.instance.currentUser;
    if (_repostedReelIds.contains(reel.id)) {
      _repostedReelIds.remove(reel.id);
      reel.isReposted = false;
    } else {
      _repostedReelIds.add(reel.id);
      reel.isReposted = true;
      try {
        NotificationService.instance.sendNotificationToUser(
          targetUsername: reel.creatorUsername,
          type: 'repost',
          title: 'إعادة نشر لمقطعك 🔄',
          body: 'أعاد @${user.username} نشر مقطع الريلز الخاص بك على صفحته.',
          targetType: 'user',
          targetId: reel.creatorUsername,
        );
      } catch (_) {}
    }
    await _saveRepostedReels();
  }

  // --- NOT INTERESTED & REPORTING ---
  bool isNotInterested(String reelId) => _notInterestedIds.contains(reelId);

  Future<void> markNotInterested(String reelId) async {
    _notInterestedIds.add(reelId);
    await _saveNotInterested();
  }

  Future<void> reportReel(String reelId, String reason) async {
    final user = AuthService.instance.currentUser;
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('reports').insert({
          'target_type': 'reel',
          'target_id': reelId,
          'reporter_username': user.username,
          'reason': reason,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  // --- SOUNDS ---
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

  // --- FETCHING REELS ---
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
        var combined = merged.values.toList();
        combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Filter out not-interested reels
        combined = combined.where((r) => !_notInterestedIds.contains(r.id)).toList();

        for (var r in combined) {
          r.isLiked = _likedReelIds.contains(r.id);
          r.isSaved = _savedReelIds.contains(r.id);
          r.isReposted = _repostedReelIds.contains(r.id);
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

    final local = List<ReelModel>.from(_localReels)
        .where((r) => !_notInterestedIds.contains(r.id))
        .toList();
    for (var r in local) {
      r.isLiked = _likedReelIds.contains(r.id);
      r.isSaved = _savedReelIds.contains(r.id);
      r.isReposted = _repostedReelIds.contains(r.id);
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

  // --- RICH COMMENTS SYSTEM ---
  Future<List<Map<String, dynamic>>> fetchComments(String reelId) async {
    // 1. Check local cache
    if (_cachedComments.containsKey(reelId) && _cachedComments[reelId]!.isNotEmpty) {
      return _cachedComments[reelId]!;
    }

    // 2. Query backend API
    final serverComments = await WadiqApiService.instance.getPostComments(reelId);
    final result = <Map<String, dynamic>>[];

    for (var c in serverComments) {
      result.add({
        'id': c['id']?.toString() ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
        'user': c['author'] ?? c['authorName'] ?? 'مستخدم',
        'username': c['username'] ?? c['authorUsername'] ?? '',
        'avatar': c['avatarUrl'] ?? '',
        'comment': c['text'] ?? c['content'] ?? '',
        'time': c['time'] ?? 'مؤخراً',
        'likesCount': (c['likesCount'] as num?)?.toInt() ?? 0,
        'dislikesCount': (c['dislikesCount'] as num?)?.toInt() ?? 0,
        'isLiked': false,
        'isDisliked': false,
        'replyToId': c['replyTo'],
        'replyToUser': null,
        'replies': <Map<String, dynamic>>[],
      });
    }

    // Also check direct Supabase fallback
    if (result.isEmpty) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          final res = await client
              .from('comments')
              .select('*')
              .or('post_id.eq.$reelId,reel_id.eq.$reelId')
              .order('created_at', ascending: true);
          for (var r in (res as List<dynamic>)) {
            result.add({
              'id': r['id']?.toString() ?? '',
              'user': r['author_name'] ?? 'مستخدم',
              'username': r['author_username'] ?? '',
              'avatar': r['author_avatar'] ?? '',
              'comment': r['content'] ?? '',
              'time': 'مؤخراً',
              'likesCount': 0,
              'dislikesCount': 0,
              'isLiked': false,
              'isDisliked': false,
              'replyToId': null,
              'replyToUser': null,
              'replies': <Map<String, dynamic>>[],
            });
          }
        } catch (_) {}
      }
    }

    _cachedComments[reelId] = result;
    return result;
  }

  Future<void> addComment(
    ReelModel reel,
    String commentText, {
    String? replyToId,
    String? replyToUser,
  }) async {
    final user = AuthService.instance.currentUser;
    final cleanComment = commentText.trim();
    if (cleanComment.isEmpty) return;

    final commentId = 'c_${DateTime.now().millisecondsSinceEpoch}';
    final newComment = <String, dynamic>{
      'id': commentId,
      'user': user.fullName,
      'username': user.username,
      'avatar': user.avatarUrl ?? '',
      'comment': cleanComment,
      'time': 'الآن',
      'likesCount': 0,
      'dislikesCount': 0,
      'isLiked': false,
      'isDisliked': false,
      'replyToId': replyToId,
      'replyToUser': replyToUser,
      'replies': <Map<String, dynamic>>[],
    };

    if (!_cachedComments.containsKey(reel.id)) {
      _cachedComments[reel.id] = [];
    }

    if (replyToId != null) {
      // Find parent comment and append to its replies
      final parent = _cachedComments[reel.id]!.firstWhere(
        (c) => c['id'] == replyToId,
        orElse: () => <String, dynamic>{},
      );
      if (parent.isNotEmpty) {
        (parent['replies'] as List<Map<String, dynamic>>).add(newComment);
      } else {
        _cachedComments[reel.id]!.insert(0, newComment);
      }
    } else {
      _cachedComments[reel.id]!.insert(0, newComment);
      reel.comments.insert(0, newComment);
    }

    reel.commentsCount += 1;

    // Save to persistent backend API
    try {
      await WadiqApiService.instance.addPostComment(
        reel.id,
        {
          'authorName': user.fullName,
          'authorUsername': user.username,
          'avatarUrl': user.avatarUrl ?? '',
          'content': cleanComment,
          'targetType': 'reel',
          'isReel': true,
        },
      );
    } catch (_) {}

    // Direct Supabase insert fallback
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('comments').insert({
          'reel_id': reel.id,
          'user_id': user.id.isNotEmpty ? user.id : null,
          'author_name': user.fullName,
          'author_username': user.username,
          'author_avatar': user.avatarUrl ?? '',
          'content': cleanComment,
        });
        await client.from('reels').update({'comments_count': reel.commentsCount}).eq('id', reel.id);
      } catch (_) {}
    }

    // Send notifications
    final targetUser = (replyToUser != null && replyToUser.isNotEmpty)
        ? replyToUser
        : reel.creatorUsername;

    NotificationService.instance.sendNotificationToUser(
      targetUsername: targetUser,
      type: 'comment',
      title: replyToUser != null ? 'رد جديد على تعليقك 💬' : 'تعليق جديد على ريلزك 💬',
      body: replyToUser != null
          ? 'رد @${user.username} على تعليقك: "$cleanComment"'
          : 'علّق @${user.username} على ريلزك: "$cleanComment"',
      targetType: 'user',
      targetId: targetUser,
    );
  }

  void toggleCommentReaction(Map<String, dynamic> comment, {required bool isDislike}) {
    if (isDislike) {
      if (comment['isDisliked'] == true) {
        comment['isDisliked'] = false;
        comment['dislikesCount'] = (comment['dislikesCount'] as int) - 1;
      } else {
        comment['isDisliked'] = true;
        comment['dislikesCount'] = (comment['dislikesCount'] as int) + 1;
        if (comment['isLiked'] == true) {
          comment['isLiked'] = false;
          comment['likesCount'] = (comment['likesCount'] as int) - 1;
        }
      }
    } else {
      if (comment['isLiked'] == true) {
        comment['isLiked'] = false;
        comment['likesCount'] = (comment['likesCount'] as int) - 1;
      } else {
        comment['isLiked'] = true;
        comment['likesCount'] = (comment['likesCount'] as int) + 1;
        if (comment['isDisliked'] == true) {
          comment['isDisliked'] = false;
          comment['dislikesCount'] = (comment['dislikesCount'] as int) - 1;
        }
      }
    }
  }
}
