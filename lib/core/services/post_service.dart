import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'wadiq_api_service.dart';

class PostModel {
  final String id;
  final String authorName;
  final String authorUsername;
  final String authorRole;
  final String content;
  final List<String> mediaUrls;
  final String? pollQuestion;
  final List<String> pollOptions;
  final Map<int, int> pollVotes;
  int? userVotedOption;
  int likesCount;
  int commentsCount;
  int repostsCount;
  bool isLiked;
  bool isBookmarked;
  bool isReposted;
  bool isFollowedPost;
  final List<Map<String, dynamic>> commentsList;
  final DateTime createdAt;
  final DateTime expiresAt;

  PostModel({
    required this.id,
    required this.authorName,
    required this.authorUsername,
    this.authorRole = 'طالب',
    required this.content,
    this.mediaUrls = const [],
    this.pollQuestion,
    this.pollOptions = const [],
    Map<int, int>? pollVotes,
    this.userVotedOption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isReposted = false,
    this.isFollowedPost = false,
    List<Map<String, dynamic>>? commentsList,
    required this.createdAt,
    required this.expiresAt,
  })  : pollVotes = pollVotes ?? {},
        commentsList = commentsList ?? [];

  int get totalPollVotes => pollVotes.values.fold(0, (sum, count) => sum + count);

  int getVotesForOption(int index) => pollVotes[index] ?? 0;

  double getPercentageForOption(int index) {
    final total = totalPollVotes;
    if (total == 0) return 0.0;
    return (getVotesForOption(index) / total);
  }

  Duration get remainingTime => expiresAt.difference(DateTime.now());
  int get daysLeft => remainingTime.inDays > 0 ? remainingTime.inDays : (isExpired ? 0 : 1);
  int get daysRemaining => daysLeft;
  bool get canRenew => remainingTime.inHours <= 24 && !isExpired;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
    'id': id,
    'author_name': authorName,
    'author_username': authorUsername,
    'content': content,
    'media_urls': mediaUrls,
    'poll_question': pollQuestion,
    'poll_options': pollOptions,
    'likes_count': likesCount,
    'comments_count': commentsCount,
    'reposts_count': repostsCount,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
  };

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final mediaList = (map['media_urls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final pollList = (map['poll_options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final created = DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now();
    final expires = DateTime.tryParse(map['expires_at']?.toString() ?? '') ?? created.add(const Duration(days: 10));

    Map<int, int> votes = {};
    if (map['poll_votes'] is Map) {
      (map['poll_votes'] as Map).forEach((k, v) {
        final keyInt = int.tryParse(k.toString());
        final valInt = int.tryParse(v.toString());
        if (keyInt != null && valInt != null) votes[keyInt] = valInt;
      });
    }

    return PostModel(
      id: map['id']?.toString() ?? '',
      authorName: map['author_name']?.toString() ?? 'مستخدم ودق',
      authorUsername: map['author_username']?.toString() ?? 'user',
      authorRole: map['author_role']?.toString() ?? 'طالب',
      content: map['content']?.toString() ?? '',
      mediaUrls: mediaList,
      pollQuestion: map['poll_question']?.toString(),
      pollOptions: pollList,
      pollVotes: votes,
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
      repostsCount: (map['reposts_count'] as num?)?.toInt() ?? 0,
      createdAt: created,
      expiresAt: expires,
    );
  }
}

class PostService {
  PostService._();
  static final PostService instance = PostService._();

  final List<PostModel> _localPosts = [];
  final Set<String> _likedPostIds = {};
  final Set<String> _bookmarkedPostIds = {};
  final Set<String> _repostedPostIds = {};
  final Set<String> _followedPostIds = {};
  final Set<String> _followedUsernames = {};
  final Set<String> _seenPostIds = {};
  bool _preferencesLoaded = false;

  Set<String> get followedUsernames => Set.unmodifiable(_followedUsernames);
  Set<String> get seenPostIds => Set.unmodifiable(_seenPostIds);

  Future<void> _loadPreferences() async {
    if (_preferencesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final liked = prefs.getStringList('wadiq_liked_posts');
      if (liked != null) _likedPostIds.addAll(liked);

      final bookmarked = prefs.getStringList('wadiq_bookmarked_posts');
      if (bookmarked != null) _bookmarkedPostIds.addAll(bookmarked);

      final reposted = prefs.getStringList('wadiq_reposted_posts');
      if (reposted != null) _repostedPostIds.addAll(reposted);

      final followed = prefs.getStringList('wadiq_followed_posts');
      if (followed != null) _followedPostIds.addAll(followed);

      final users = prefs.getStringList('wadiq_followed_users');
      if (users != null) _followedUsernames.addAll(users);

      _preferencesLoaded = true;
    } catch (_) {}
  }

  Future<void> _saveLikedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_liked_posts', _likedPostIds.toList());
    } catch (_) {}
  }

  Future<void> _saveBookmarkedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_bookmarked_posts', _bookmarkedPostIds.toList());
    } catch (_) {}
  }

  Future<void> _saveRepostedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_reposted_posts', _repostedPostIds.toList());
    } catch (_) {}
  }

  Future<void> _saveFollowedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wadiq_followed_users', _followedUsernames.toList());
    } catch (_) {}
  }

  void markPostAsSeen(String postId) {
    _seenPostIds.add(postId);
  }

  List<PostModel> applySeenFilter(List<PostModel> posts) {
    if (posts.length <= 5) return posts;
    final unseen = posts.where((p) => !_seenPostIds.contains(p.id)).toList();
    if (unseen.length < 3) return posts;
    return unseen;
  }

  bool isUserFollowed(String username) => _followedUsernames.contains(username.toLowerCase());

  void toggleFollowUser(String username) {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    if (_followedUsernames.contains(clean)) {
      _followedUsernames.remove(clean);
    } else {
      _followedUsernames.add(clean);
      NotificationService.instance.addNotification(
        type: 'follow',
        title: 'متابعة جديدة',
        body: 'بدأت بمتابعة الحساب @$clean لتصلك كافة منشوراته أولاً بأول.',
        targetType: 'user',
        targetId: clean,
      );
    }
    _saveFollowedUsers();
  }

  Future<List<PostModel>> fetchPosts() async {
    await _loadPreferences();

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final res = await client
            .from('posts')
            .select('*')
            .order('created_at', ascending: false);

        final list = (res as List<dynamic>)
            .map((item) => PostModel.fromMap(item as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) {
          final Map<String, PostModel> merged = {};
          for (var p in _localPosts) {
            merged[p.id] = p;
          }
          for (var p in list) {
            merged[p.id] = p;
          }
          final combined = merged.values.toList();
          combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          for (var p in combined) {
            p.isLiked = _likedPostIds.contains(p.id);
            p.isBookmarked = _bookmarkedPostIds.contains(p.id);
            p.isFollowedPost = _followedPostIds.contains(p.id);
            p.isReposted = _repostedPostIds.contains(p.id);

            // Asynchronously load persisted comments from backend
            WadiqApiService.instance.getPostComments(p.id).then((loadedComments) {
              if (loadedComments.isNotEmpty) {
                p.commentsList.clear();
                p.commentsList.addAll(loadedComments);
                p.commentsCount = loadedComments.length;
              }
            });
          }
          return combined;
        }
      } catch (e) {
        debugPrint('Error fetching posts from Supabase: $e');
      }
    }

    final local = List<PostModel>.from(_localPosts);
    for (var p in local) {
      p.isLiked = _likedPostIds.contains(p.id);
      p.isBookmarked = _bookmarkedPostIds.contains(p.id);
      p.isFollowedPost = _followedPostIds.contains(p.id);
      p.isReposted = _repostedPostIds.contains(p.id);
    }
    return local;
  }

  List<PostModel> filterFollowedPosts(List<PostModel> allPosts) {
    return allPosts.where((p) => _followedUsernames.contains(p.authorUsername.toLowerCase())).toList();
  }

  Future<List<PostModel>> fetchPostsByUser(String username) async {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    final all = await fetchPosts();
    return all.where((p) => p.authorUsername.toLowerCase() == clean).toList();
  }

  List<PostModel> fetchSavedPosts(List<PostModel> allPosts) {
    return allPosts.where((p) => _bookmarkedPostIds.contains(p.id) || p.isBookmarked).toList();
  }

  Future<bool> createPost({
    required String content,
    List<String> mediaUrls = const [],
    String? pollQuestion,
    List<String> pollOptions = const [],
  }) async {
    final user = AuthService.instance.currentUser;
    final now = DateTime.now();
    final expires = now.add(const Duration(days: 10));

    Map<int, int> initialVotes = {};
    if (pollOptions.isNotEmpty) {
      for (int i = 0; i < pollOptions.length; i++) {
        initialVotes[i] = 0;
      }
    }

    final newPost = PostModel(
      id: 'post_${now.millisecondsSinceEpoch}',
      authorName: user.fullName,
      authorUsername: user.username,
      authorRole: user.role,
      content: content,
      mediaUrls: mediaUrls,
      pollQuestion: pollQuestion,
      pollOptions: pollOptions,
      pollVotes: initialVotes,
      createdAt: now,
      expiresAt: expires,
    );

    _localPosts.insert(0, newPost);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('posts').insert({
          'author_name': user.fullName,
          'author_username': user.username,
          'content': content,
          'media_urls': mediaUrls,
          'poll_question': pollQuestion,
          'poll_options': pollOptions,
          'created_at': now.toIso8601String(),
          'expires_at': expires.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error inserting post to Supabase: $e');
      }
    }

    return true;
  }

  void votePoll(PostModel post, int optionIndex) {
    if (post.userVotedOption != null) return; // Already voted
    post.userVotedOption = optionIndex;
    post.pollVotes[optionIndex] = (post.pollVotes[optionIndex] ?? 0) + 1;

    NotificationService.instance.addNotification(
      type: 'post_update',
      title: 'تصويت في استطلاع رأي',
      body: 'تم تسجيل تصويتك في الاستطلاع: "${post.pollQuestion}"',
      targetType: 'post',
      targetId: post.id,
    );
  }

  void toggleLike(PostModel post) {
    final user = AuthService.instance.currentUser;
    post.isLiked = !post.isLiked;
    post.likesCount += post.isLiked ? 1 : -1;
    if (post.likesCount < 0) post.likesCount = 0;

    if (post.isLiked) {
      _likedPostIds.add(post.id);
      NotificationService.instance.sendNotificationToUser(
        targetUsername: post.authorUsername,
        type: 'like',
        title: 'إعجاب جديد بمنشورك',
        body: 'سجّل @${user.username} إعجابه بمنشورك الأكاديمي.',
        targetType: 'post',
        targetId: post.id,
      );
    } else {
      _likedPostIds.remove(post.id);
    }

    _saveLikedPosts();

    final client = SupabaseConfig.client;
    if (client != null) {
      client
          .from('posts')
          .update({'likes_count': post.likesCount})
          .eq('id', post.id)
          .then((_) {}, onError: (_) {});
    }
  }

  void toggleBookmark(PostModel post) {
    post.isBookmarked = !post.isBookmarked;
    if (post.isBookmarked) {
      _bookmarkedPostIds.add(post.id);
    } else {
      _bookmarkedPostIds.remove(post.id);
    }
    _saveBookmarkedPosts();
  }

  void toggleRepost(PostModel post) {
    final user = AuthService.instance.currentUser;
    post.isReposted = !post.isReposted;
    post.repostsCount += post.isReposted ? 1 : -1;
    if (post.repostsCount < 0) post.repostsCount = 0;

    if (post.isReposted) {
      _repostedPostIds.add(post.id);
      NotificationService.instance.sendNotificationToUser(
        targetUsername: post.authorUsername,
        type: 'repost',
        title: 'إعادة نشر لمنشورك',
        body: 'أعاد @${user.username} نشر منشورك الأكاديمي في مساره.',
        targetType: 'post',
        targetId: post.id,
      );
    } else {
      _repostedPostIds.remove(post.id);
    }
    _saveRepostedPosts();

    final client = SupabaseConfig.client;
    if (client != null) {
      client
          .from('posts')
          .update({'reposts_count': post.repostsCount})
          .eq('id', post.id)
          .then((_) {}, onError: (_) {});
    }
  }

  void toggleFollowPost(PostModel post) {
    post.isFollowedPost = !post.isFollowedPost;
    if (post.isFollowedPost) {
      _followedPostIds.add(post.id);
      NotificationService.instance.addNotification(
        type: 'post_update',
        title: 'متابعة المنشور',
        body: 'ستصلك إشعارات وتنبيهات بأي تعليقات أو تفاعلات جديدة على هذا المنشور.',
        targetType: 'post',
        targetId: post.id,
      );
    } else {
      _followedPostIds.remove(post.id);
    }
  }

  void addComment(PostModel post, {required String text, String? replyToAuthor}) {
    final user = AuthService.instance.currentUser;
    post.commentsCount += 1;
    final commentData = {
      'author': user.fullName,
      'username': user.username,
      'role': user.role,
      'time': 'الآن',
      'text': text.trim(),
      'replyTo': replyToAuthor,
      'likes': 0,
      'isLiked': false,
    };
    post.commentsList.add(commentData);

    // Save permanently in Backend comments store
    WadiqApiService.instance.addPostComment(post.id, commentData);

    // Update Supabase comments count
    final client = SupabaseConfig.client;
    if (client != null) {
      client
          .from('posts')
          .update({'comments_count': post.commentsCount})
          .eq('id', post.id)
          .then((_) {}, onError: (_) {});
    }

    // Send real notification to author
    NotificationService.instance.sendNotificationToUser(
      targetUsername: post.authorUsername,
      type: 'comment',
      title: 'تعليق جديد على منشورك',
      body: 'علّق @${user.username} على منشورك: "$text"',
      targetType: 'post',
      targetId: post.id,
    );
  }

  Future<bool> renewPost(String postId) async {
    final client = SupabaseConfig.client;
    final newExpiresAt = DateTime.now().add(const Duration(days: 10));
    if (client != null) {
      try {
        await client
            .from('posts')
            .update({'expires_at': newExpiresAt.toIso8601String()})
            .eq('id', postId);
        return true;
      } catch (e) {
        debugPrint('Renew post error: $e');
      }
    }
    return true;
  }
}
