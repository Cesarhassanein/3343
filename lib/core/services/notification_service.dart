import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'wadiq_api_service.dart';

class WadiqNotification {
  final String id;
  final String type; // 'like', 'comment', 'follow', 'repost', 'post_update', 'system'
  final String title;
  final String body;
  final String time;
  bool isUnread;
  final String? targetType; // 'post', 'user'
  final String? targetId;
  final DateTime createdAt;

  WadiqNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isUnread = true,
    this.targetType,
    this.targetId,
    required this.createdAt,
  });

  IconData get icon {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'repost':
        return Icons.repeat_rounded;
      case 'post_update':
        return Icons.notifications_active_rounded;
      default:
        return Icons.auto_awesome;
    }
  }

  Color get color {
    switch (type) {
      case 'like':
        return Colors.redAccent;
      case 'comment':
        return Colors.blueAccent;
      case 'follow':
        return Colors.greenAccent;
      case 'repost':
        return const Color(0xFFFF6B35);
      case 'post_update':
        return const Color(0xFFFF9E00);
      default:
        return const Color(0xFFFF6B35);
    }
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final List<WadiqNotification> _notifications = [];

  List<WadiqNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> fetchUserNotifications() async {
    final currentUsername = AuthService.instance.currentUser.username.replaceAll('@', '').toLowerCase().trim();
    if (currentUsername.isEmpty || currentUsername == 'wadiq_user') return;

    try {
      final list = await WadiqApiService.instance.getNotifications(currentUsername);
      if (list.isNotEmpty) {
        _notifications.clear();
        for (final item in list) {
          _notifications.add(WadiqNotification(
            id: item['id']?.toString() ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
            type: item['type']?.toString() ?? 'system',
            title: item['title']?.toString() ?? 'إشعار جديد',
            body: item['body']?.toString() ?? '',
            time: item['time']?.toString() ?? 'الآن',
            isUnread: item['isUnread'] == true,
            targetType: item['targetType']?.toString(),
            targetId: item['targetId']?.toString(),
            createdAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
          ));
        }
      }
    } catch (_) {}
  }

  /// Send notification to a specific target user (e.g. author of a post or reel)
  void sendNotificationToUser({
    required String targetUsername,
    required String type,
    required String title,
    required String body,
    String? targetType,
    String? targetId,
  }) {
    final cleanTarget = targetUsername.replaceAll('@', '').toLowerCase().trim();
    final myUsername = AuthService.instance.currentUser.username.replaceAll('@', '').toLowerCase().trim();

    // Do not notify self
    if (cleanTarget.isEmpty || cleanTarget == myUsername) return;

    // Send to backend store
    WadiqApiService.instance.sendNotification(
      targetUsername: cleanTarget,
      type: type,
      title: title,
      body: body,
      targetType: targetType,
      targetId: targetId,
    );
  }

  void addNotification({
    required String type,
    required String title,
    required String body,
    String? targetType,
    String? targetId,
  }) {
    final notif = WadiqNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      body: body,
      time: 'الآن',
      isUnread: true,
      targetType: targetType,
      targetId: targetId,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isUnread = false;
    }
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isUnread = false;
    }
  }

  List<WadiqNotification> getByCategory(String category) {
    if (category == 'all') return _notifications;
    if (category == 'likes') return _notifications.where((n) => n.type == 'like').toList();
    if (category == 'comments') return _notifications.where((n) => n.type == 'comment').toList();
    if (category == 'follows') return _notifications.where((n) => n.type == 'follow').toList();
    if (category == 'followed_posts') return _notifications.where((n) => n.type == 'post_update').toList();
    return _notifications;
  }
}
