import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../feed/presentation/screens/post_detail_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    NotificationService.instance.fetchUserNotifications().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAllAsRead() {
    setState(() {
      NotificationService.instance.markAllAsRead();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم تحديد جميع الإشعارات كمقروءة ✓"),
        backgroundColor: WadiqColors.success,
      ),
    );
  }

  void _onNotificationTap(WadiqNotification n) async {
    setState(() {
      n.isUnread = false;
    });

    if (n.targetType == 'post' && n.targetId != null) {
      final posts = await PostService.instance.fetchPosts();
      final post = posts.firstWhere(
        (p) => p.id == n.targetId,
        orElse: () => PostModel(
          id: n.targetId!,
          authorName: "مستخدم",
          authorUsername: "user",
          content: n.body,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 10)),
        ),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      );
    } else if (n.targetType == 'user' && n.targetId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            name: n.targetId!,
            role: "عضو في ودق",
            handle: "@${n.targetId}",
            avatarChar: n.targetId!.isNotEmpty ? n.targetId![0] : "و",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text("الإشعارات والتنبيهات", style: WadiqTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: WadiqColors.primaryAmber),
            tooltip: "تحديد الكل كمقروء",
            onPressed: _markAllAsRead,
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: WadiqColors.primaryAmber,
          labelColor: WadiqColors.primaryAmber,
          unselectedLabelColor: WadiqColors.textSecondary,
          labelStyle: WadiqTypography.titleMedium.copyWith(fontSize: 13),
          tabs: const [
            Tab(text: "الكل"),
            Tab(text: "الإعجابات"),
            Tab(text: "التعليقات"),
            Tab(text: "المتابعات"),
            Tab(text: "المنشورات المتابعة"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(NotificationService.instance.getByCategory('all')),
          _buildNotificationList(NotificationService.instance.getByCategory('likes')),
          _buildNotificationList(NotificationService.instance.getByCategory('comments')),
          _buildNotificationList(NotificationService.instance.getByCategory('follows')),
          _buildNotificationList(NotificationService.instance.getByCategory('followed_posts')),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<WadiqNotification> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 54, color: Colors.white24),
              const SizedBox(height: 14),
              Text("لا توجد إشعارات في هذا القسم", style: WadiqTypography.titleMedium.copyWith(color: Colors.white70)),
              const SizedBox(height: 6),
              Text("ستظهر هنا أي تفاعلات جديدة فور حدوثها.", style: WadiqTypography.caption.copyWith(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final n = list[index];

        return InkWell(
          onTap: () => _onNotificationTap(n),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.isUnread ? WadiqColors.elevatedSurface : WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: n.isUnread ? WadiqColors.primaryAmber.withValues(alpha: 0.5) : WadiqColors.surfaceBorder,
                width: n.isUnread ? 1.2 : 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.icon, color: n.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    n.title,
                                    style: WadiqTypography.titleMedium.copyWith(
                                      fontSize: 14,
                                      fontWeight: n.isUnread ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (n.isUnread) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: WadiqColors.primaryAmber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(n.time, style: WadiqTypography.caption.copyWith(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: WadiqTypography.bodyMedium.copyWith(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
