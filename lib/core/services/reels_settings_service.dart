import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudiencePermission {
  everyone,   // للجميع
  friends,    // الأصدقاء
  specific,   // أشخاص محددون
  exceptUsers,// باستثناء
  nobody,     // لا أحد (للذكر فقط)
  onlyMe,     // لك فقط (للريلز الخاص فقط)
}

extension AudiencePermissionExt on AudiencePermission {
  String get title {
    switch (this) {
      case AudiencePermission.everyone:
        return 'للجميع';
      case AudiencePermission.friends:
        return 'الأصدقاء فقط';
      case AudiencePermission.specific:
        return 'أشخاص محددون';
      case AudiencePermission.exceptUsers:
        return 'باستثناء أشخاص محددين';
      case AudiencePermission.nobody:
        return 'لا أحد';
      case AudiencePermission.onlyMe:
        return 'لك فقط (خاص)';
    }
  }
}

class RecentlyDeletedReelItem {
  final String id;
  final String caption;
  final String videoUrl;
  final String soundTitle;
  final DateTime deletedAt;

  RecentlyDeletedReelItem({
    required this.id,
    required this.caption,
    required this.videoUrl,
    required this.soundTitle,
    required this.deletedAt,
  });

  int get remainingDays {
    final diff = DateTime.now().difference(deletedAt).inDays;
    return (7 - diff).clamp(0, 7);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'caption': caption,
    'videoUrl': videoUrl,
    'soundTitle': soundTitle,
    'deletedAt': deletedAt.toIso8601String(),
  };

  factory RecentlyDeletedReelItem.fromMap(Map<String, dynamic> map) => RecentlyDeletedReelItem(
    id: map['id']?.toString() ?? '',
    caption: map['caption']?.toString() ?? '',
    videoUrl: map['videoUrl']?.toString() ?? '',
    soundTitle: map['soundTitle']?.toString() ?? '',
    deletedAt: DateTime.tryParse(map['deletedAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

class ReelsSettingsService extends ChangeNotifier {
  ReelsSettingsService._();
  static final ReelsSettingsService instance = ReelsSettingsService._();

  // Storage Keys
  static const _kCommentsAllowedFrom = 'wadiq_reels_comments_perm';
  static const _kCommentsSpecific = 'wadiq_reels_comments_specific';
  static const _kCommentsExcept = 'wadiq_reels_comments_except';
  static const _kCommentKeywords = 'wadiq_reels_comment_keywords';

  static const _kMentionsAllowedFrom = 'wadiq_reels_mentions_perm';
  static const _kMentionsSpecific = 'wadiq_reels_mentions_specific';
  static const _kMentionsExcept = 'wadiq_reels_mentions_except';

  static const _kFollowersVisibility = 'wadiq_reels_followers_vis';
  static const _kFollowersSpecific = 'wadiq_reels_followers_specific';
  static const _kFollowersExcept = 'wadiq_reels_followers_except';

  static const _kLikedVideosVisibility = 'wadiq_reels_liked_vis';
  static const _kLikedSpecific = 'wadiq_reels_liked_specific';
  static const _kLikedExcept = 'wadiq_reels_liked_except';

  static const _kFeedFilteredKeywords = 'wadiq_reels_feed_keywords';
  static const _kStudyModeEnabled = 'wadiq_reels_study_mode';
  static const _kMutedAccounts = 'wadiq_reels_muted_accounts';

  static const _kWatchHistory = 'wadiq_reels_watch_history';
  static const _kSearchHistory = 'wadiq_reels_search_history';
  static const _kCommentsHistory = 'wadiq_reels_comments_history';
  static const _kMentionsHistory = 'wadiq_reels_mentions_history';
  static const _kRecentlyDeleted = 'wadiq_reels_recently_deleted';
  static const _kReelOverrides = 'wadiq_reels_per_reel_overrides';

  // State
  AudiencePermission _commentsAllowedFrom = AudiencePermission.everyone;
  List<String> _commentsSpecificUsers = [];
  List<String> _commentsExceptUsers = [];
  List<String> _commentFilterKeywords = ['إعلان', 'سبام', 'تداول'];

  AudiencePermission _mentionsAllowedFrom = AudiencePermission.everyone;
  List<String> _mentionsSpecificUsers = [];
  List<String> _mentionsExceptUsers = [];

  AudiencePermission _followersVisibility = AudiencePermission.everyone;
  List<String> _followersSpecificUsers = [];
  List<String> _followersExceptUsers = [];

  AudiencePermission _likedVideosVisibility = AudiencePermission.everyone;
  List<String> _likedSpecificUsers = [];
  List<String> _likedExceptUsers = [];

  List<String> _feedFilteredKeywords = [];
  bool _isStudyModeEnabled = false;
  List<String> _mutedAccounts = [];

  List<Map<String, dynamic>> _watchHistory = [];
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _commentsHistory = [];
  List<Map<String, dynamic>> _mentionsHistory = [];
  List<RecentlyDeletedReelItem> _recentlyDeleted = [];
  Map<String, Map<String, dynamic>> _perReelOverrides = {};

  // Getters
  AudiencePermission get commentsAllowedFrom => _commentsAllowedFrom;
  List<String> get commentsSpecificUsers => _commentsSpecificUsers;
  List<String> get commentsExceptUsers => _commentsExceptUsers;
  List<String> get commentFilterKeywords => _commentFilterKeywords;

  AudiencePermission get mentionsAllowedFrom => _mentionsAllowedFrom;
  List<String> get mentionsSpecificUsers => _mentionsSpecificUsers;
  List<String> get mentionsExceptUsers => _mentionsExceptUsers;

  AudiencePermission get followersVisibility => _followersVisibility;
  List<String> get followersSpecificUsers => _followersSpecificUsers;
  List<String> get followersExceptUsers => _followersExceptUsers;

  AudiencePermission get likedVideosVisibility => _likedVideosVisibility;
  List<String> get likedSpecificUsers => _likedSpecificUsers;
  List<String> get likedExceptUsers => _likedExceptUsers;

  List<String> get feedFilteredKeywords => _feedFilteredKeywords;
  bool get isStudyModeEnabled => _isStudyModeEnabled;
  List<String> get mutedAccounts => _mutedAccounts;

  List<Map<String, dynamic>> get watchHistory => _watchHistory;
  List<String> get searchHistory => _searchHistory;
  List<Map<String, dynamic>> get commentsHistory => _commentsHistory;
  List<Map<String, dynamic>> get mentionsHistory => _mentionsHistory;
  List<RecentlyDeletedReelItem> get recentlyDeleted => _recentlyDeleted;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _commentsAllowedFrom = _parsePerm(prefs.getString(_kCommentsAllowedFrom), AudiencePermission.everyone);
      _commentsSpecificUsers = prefs.getStringList(_kCommentsSpecific) ?? [];
      _commentsExceptUsers = prefs.getStringList(_kCommentsExcept) ?? [];
      _commentFilterKeywords = prefs.getStringList(_kCommentKeywords) ?? ['إعلان', 'سبام', 'تداول'];

      _mentionsAllowedFrom = _parsePerm(prefs.getString(_kMentionsAllowedFrom), AudiencePermission.everyone);
      _mentionsSpecificUsers = prefs.getStringList(_kMentionsSpecific) ?? [];
      _mentionsExceptUsers = prefs.getStringList(_kMentionsExcept) ?? [];

      _followersVisibility = _parsePerm(prefs.getString(_kFollowersVisibility), AudiencePermission.everyone);
      _followersSpecificUsers = prefs.getStringList(_kFollowersSpecific) ?? [];
      _followersExceptUsers = prefs.getStringList(_kFollowersExcept) ?? [];

      _likedVideosVisibility = _parsePerm(prefs.getString(_kLikedVideosVisibility), AudiencePermission.everyone);
      _likedSpecificUsers = prefs.getStringList(_kLikedSpecific) ?? [];
      _likedExceptUsers = prefs.getStringList(_kLikedExcept) ?? [];

      _feedFilteredKeywords = prefs.getStringList(_kFeedFilteredKeywords) ?? [];
      _isStudyModeEnabled = prefs.getBool(_kStudyModeEnabled) ?? false;
      _mutedAccounts = prefs.getStringList(_kMutedAccounts) ?? [];
      _searchHistory = prefs.getStringList(_kSearchHistory) ?? ['فيزياء', 'رياضيات', 'كيمياء'];

      // Load histories
      final watchRaw = prefs.getString(_kWatchHistory);
      if (watchRaw != null) {
        _watchHistory = List<Map<String, dynamic>>.from(jsonDecode(watchRaw));
      }
      final commentsRaw = prefs.getString(_kCommentsHistory);
      if (commentsRaw != null) {
        _commentsHistory = List<Map<String, dynamic>>.from(jsonDecode(commentsRaw));
      }
      final mentionsRaw = prefs.getString(_kMentionsHistory);
      if (mentionsRaw != null) {
        _mentionsHistory = List<Map<String, dynamic>>.from(jsonDecode(mentionsRaw));
      }
      final deletedRaw = prefs.getString(_kRecentlyDeleted);
      if (deletedRaw != null) {
        final list = jsonDecode(deletedRaw) as List;
        _recentlyDeleted = list.map((e) => RecentlyDeletedReelItem.fromMap(e)).toList();
        // Auto purge expired > 7 days
        _recentlyDeleted.removeWhere((item) => item.remainingDays <= 0);
      }
      final overridesRaw = prefs.getString(_kReelOverrides);
      if (overridesRaw != null) {
        _perReelOverrides = Map<String, Map<String, dynamic>>.from(jsonDecode(overridesRaw));
      }

      notifyListeners();
    } catch (_) {}
  }

  AudiencePermission _parsePerm(String? str, AudiencePermission fallback) {
    if (str == null) return fallback;
    for (var val in AudiencePermission.values) {
      if (val.name == str) return val;
    }
    return fallback;
  }

  // Setters for Interactions
  Future<void> setCommentsPermission(AudiencePermission perm, {List<String>? specific, List<String>? except}) async {
    _commentsAllowedFrom = perm;
    if (specific != null) _commentsSpecificUsers = specific;
    if (except != null) _commentsExceptUsers = except;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCommentsAllowedFrom, perm.name);
    await prefs.setStringList(_kCommentsSpecific, _commentsSpecificUsers);
    await prefs.setStringList(_kCommentsExcept, _commentsExceptUsers);
  }

  Future<void> addCommentKeyword(String word) async {
    final clean = word.trim();
    if (clean.isNotEmpty && !_commentFilterKeywords.contains(clean)) {
      _commentFilterKeywords.add(clean);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kCommentKeywords, _commentFilterKeywords);
    }
  }

  Future<void> removeCommentKeyword(String word) async {
    _commentFilterKeywords.remove(word);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCommentKeywords, _commentFilterKeywords);
  }

  Future<void> setMentionsPermission(AudiencePermission perm, {List<String>? specific, List<String>? except}) async {
    _mentionsAllowedFrom = perm;
    if (specific != null) _mentionsSpecificUsers = specific;
    if (except != null) _mentionsExceptUsers = except;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMentionsAllowedFrom, perm.name);
    await prefs.setStringList(_kMentionsSpecific, _mentionsSpecificUsers);
    await prefs.setStringList(_kMentionsExcept, _mentionsExceptUsers);
  }

  Future<void> setFollowersVisibility(AudiencePermission perm, {List<String>? specific, List<String>? except}) async {
    _followersVisibility = perm;
    if (specific != null) _followersSpecificUsers = specific;
    if (except != null) _followersExceptUsers = except;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFollowersVisibility, perm.name);
    await prefs.setStringList(_kFollowersSpecific, _followersSpecificUsers);
    await prefs.setStringList(_kFollowersExcept, _followersExceptUsers);
  }

  Future<void> setLikedVideosVisibility(AudiencePermission perm, {List<String>? specific, List<String>? except}) async {
    _likedVideosVisibility = perm;
    if (specific != null) _likedSpecificUsers = specific;
    if (except != null) _likedExceptUsers = except;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLikedVideosVisibility, perm.name);
    await prefs.setStringList(_kLikedSpecific, _likedSpecificUsers);
    await prefs.setStringList(_kLikedExcept, _likedExceptUsers);
  }

  // Content Preferences
  Future<void> addFeedKeyword(String word) async {
    final clean = word.trim();
    if (clean.isNotEmpty && !_feedFilteredKeywords.contains(clean)) {
      _feedFilteredKeywords.add(clean);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFeedFilteredKeywords, _feedFilteredKeywords);
    }
  }

  Future<void> removeFeedKeyword(String word) async {
    _feedFilteredKeywords.remove(word);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFeedFilteredKeywords, _feedFilteredKeywords);
  }

  Future<void> setStudyMode(bool enabled) async {
    _isStudyModeEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStudyModeEnabled, enabled);
  }

  Future<void> muteAccount(String username) async {
    final clean = username.replaceAll('@', '').trim();
    if (clean.isNotEmpty && !_mutedAccounts.contains(clean)) {
      _mutedAccounts.add(clean);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kMutedAccounts, _mutedAccounts);
    }
  }

  Future<void> unmuteAccount(String username) async {
    final clean = username.replaceAll('@', '').trim();
    _mutedAccounts.remove(clean);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kMutedAccounts, _mutedAccounts);
  }

  // Per-Reel Overrides
  Map<String, dynamic> getReelPermissions(String reelId) {
    return _perReelOverrides[reelId] ?? {
      'visibility': AudiencePermission.everyone.name,
      'comments': AudiencePermission.everyone.name,
      'repost': AudiencePermission.everyone.name,
    };
  }

  Future<void> setReelPermission(String reelId, String type, AudiencePermission perm) async {
    final current = getReelPermissions(reelId);
    current[type] = perm.name;
    _perReelOverrides[reelId] = current;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReelOverrides, jsonEncode(_perReelOverrides));
  }

  // Recently Deleted
  Future<void> markReelDeleted({
    required String id,
    required String caption,
    required String videoUrl,
    required String soundTitle,
  }) async {
    _recentlyDeleted.insert(0, RecentlyDeletedReelItem(
      id: id,
      caption: caption,
      videoUrl: videoUrl,
      soundTitle: soundTitle,
      deletedAt: DateTime.now(),
    ));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRecentlyDeleted, jsonEncode(_recentlyDeleted.map((e) => e.toMap()).toList()));
  }

  Future<RecentlyDeletedReelItem?> restoreReel(String id) async {
    final idx = _recentlyDeleted.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final item = _recentlyDeleted.removeAt(idx);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRecentlyDeleted, jsonEncode(_recentlyDeleted.map((e) => e.toMap()).toList()));
      return item;
    }
    return null;
  }

  Future<void> permanentlyDeleteReel(String id) async {
    _recentlyDeleted.removeWhere((e) => e.id == id);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRecentlyDeleted, jsonEncode(_recentlyDeleted.map((e) => e.toMap()).toList()));
  }

  // Activity Center
  Future<void> recordWatchHistory({required String reelId, required String title, required String creator}) async {
    _watchHistory.removeWhere((e) => e['reelId'] == reelId);
    _watchHistory.insert(0, {
      'reelId': reelId,
      'title': title,
      'creator': creator,
      'time': DateTime.now().toIso8601String(),
    });
    if (_watchHistory.length > 50) _watchHistory.removeLast();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWatchHistory, jsonEncode(_watchHistory));
  }

  Future<void> recordSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    _searchHistory.remove(clean);
    _searchHistory.insert(0, clean);
    if (_searchHistory.length > 30) _searchHistory.removeLast();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSearchHistory, _searchHistory);
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSearchHistory);
  }

  Future<void> clearWatchHistory() async {
    _watchHistory.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWatchHistory);
  }

  Future<void> recordCommentActivity({required String reelId, required String commentText, required String reelTitle}) async {
    _commentsHistory.insert(0, {
      'reelId': reelId,
      'comment': commentText,
      'reelTitle': reelTitle,
      'time': DateTime.now().toIso8601String(),
    });
    if (_commentsHistory.length > 50) _commentsHistory.removeLast();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCommentsHistory, jsonEncode(_commentsHistory));
  }
}
