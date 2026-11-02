import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/retention_badge.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import 'post_detail_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../search/presentation/screens/global_search_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../moderation/presentation/widgets/moderation_report_dialog.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<PostModel>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = PostService.instance.fetchPosts();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _loadPosts();
    });
  }

  void _renewPost(PostModel post) async {
    final success = await PostService.instance.renewPost(post.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم تجديد المنشور بنجاح لمدة 10 أيام إضافية! ⏱️"),
          backgroundColor: WadiqColors.primaryAmber,
        ),
      );
      _refreshPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تجديد المنشور متاح فقط بعد مرور 24 ساعة من نشره."),
          backgroundColor: WadiqColors.alert,
        ),
      );
    }
  }

  void _showPostOptions(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: WadiqColors.primaryAmber,
                ),
                title: Text(
                  post.isBookmarked ? "إلغاء الحفظ من المفضلة" : "حفظ المنشور في المفضلة",
                  style: WadiqTypography.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    PostService.instance.toggleBookmark(post);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(post.isBookmarked ? "تم الحفظ في المفضلة." : "تمت إزالة المنشور من المفضلة."),
                      backgroundColor: WadiqColors.primaryAmber,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: WadiqColors.alert),
                title: Text("إبلاغ عن محتوى غير لائق", style: WadiqTypography.bodyLarge.copyWith(color: WadiqColors.alert)),
                onTap: () {
                  Navigator.pop(ctx);
                  ModerationReportDialog.show(
                    context,
                    targetType: "post",
                    targetId: post.id,
                    targetTitle: post.content.length > 30 ? "${post.content.substring(0, 30)}..." : post.content,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = NotificationService.instance.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: WadiqColors.amberGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "و",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "ودق",
              style: WadiqTypography.displayMedium.copyWith(fontSize: 22),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
              );
            },
            icon: const Icon(Icons.search_rounded, size: 24),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ).then((_) => setState(() {}));
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 24),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: WadiqColors.primaryAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WadiqColors.primaryAmber,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: WadiqColors.surfaceBorder,
          labelColor: WadiqColors.primaryAmber,
          unselectedLabelColor: WadiqColors.textSecondary,
          labelStyle: WadiqTypography.titleMedium.copyWith(fontSize: 14),
          tabs: const [
            Tab(text: "المنشورات"),
            Tab(text: "أتابعهم"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsList(isFollowingOnly: false),
          _buildPostsList(isFollowingOnly: true),
        ],
      ),
    );
  }

  Widget _buildPostsList({required bool isFollowingOnly}) {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: WadiqColors.primaryAmber,
      backgroundColor: WadiqColors.cardSurface,
      child: FutureBuilder<List<PostModel>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: WadiqColors.primaryAmber),
            );
          }

          final allPosts = snapshot.data ?? [];
          final basePosts = isFollowingOnly
              ? PostService.instance.filterFollowedPosts(allPosts)
              : allPosts;

          final posts = isFollowingOnly
              ? basePosts
              : PostService.instance.applySeenFilter(basePosts);

          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFollowingOnly ? Icons.people_outline_rounded : Icons.feed_outlined,
                      size: 54,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isFollowingOnly
                          ? "لا توجد منشورات من الحسابات التي تتابعها بعد"
                          : "لا توجد منشورات نشطة حالياً",
                      style: WadiqTypography.titleMedium.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFollowingOnly
                          ? "تابع زملاءك وأساتذتك لتظهر منشوراتهم هنا في مسارك المخصص."
                          : "كن أول من ينشر فكرة أو استطلاع رأي عبر زر (+) أدناه!",
                      style: WadiqTypography.caption.copyWith(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              PostService.instance.markPostAsSeen(post.id);
              return _buildPostCard(post);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final myUsername = AuthService.instance.currentUser.username.toLowerCase();
    final isAuthor = post.authorUsername.toLowerCase() == myUsername;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WadiqColors.surfaceBorder, width: 0.9),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            ).then((_) => setState(() {}));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar, Name, Role, Retention/Follow Action
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              name: post.authorName,
                              role: post.authorRole,
                              handle: "@${post.authorUsername}",
                              avatarChar: post.authorName.isNotEmpty ? post.authorName.substring(0, 1) : "و",
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: WadiqColors.elevatedSurface,
                        child: Text(
                          post.authorName.isNotEmpty ? post.authorName.substring(0, 1) : "و",
                          style: const TextStyle(
                            color: WadiqColors.primaryAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                name: post.authorName,
                                role: post.authorRole,
                                handle: "@${post.authorUsername}",
                                avatarChar: post.authorName.isNotEmpty ? post.authorName.substring(0, 1) : "و",
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: WadiqTypography.titleMedium.copyWith(fontSize: 15),
                            ),
                            Text(
                              "@${post.authorUsername} • ${post.authorRole}",
                              style: WadiqTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Retention Badge ONLY for author; Follow Post button for others!
                    if (isAuthor)
                      RetentionBadge(
                        daysLeft: post.daysLeft,
                        onRenewTap: () => _renewPost(post),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          post.isFollowedPost ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 20,
                          color: post.isFollowedPost ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                        ),
                        tooltip: post.isFollowedPost ? "إلغاء متابعة المنشور" : "متابعة المنشور وتلقي التنبيهات",
                        onPressed: () {
                          setState(() {
                            PostService.instance.toggleFollowPost(post);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                post.isFollowedPost
                                    ? "تمت متابعة المنشور! ستصلك إشعارات بأي تفاعل جديد عليه."
                                    : "تم إلغاء متابعة المنشور.",
                              ),
                              backgroundColor: WadiqColors.primaryAmber,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),

                    IconButton(
                      icon: const Icon(Icons.more_horiz, size: 18, color: WadiqColors.textMuted),
                      onPressed: () => _showPostOptions(post),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                Text(
                  post.content,
                  style: WadiqTypography.bodyLarge,
                ),

                // Attached Media Image (Adaptive height according to user image)
                if (post.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPostImage(post.mediaUrls.first),
                ],

                // Interactive Poll
                if (post.pollQuestion != null && post.pollQuestion!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WadiqColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.poll_rounded, color: WadiqColors.primaryAmber, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                post.pollQuestion!,
                                style: WadiqTypography.titleMedium.copyWith(fontSize: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...post.pollOptions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final optionText = entry.value;
                          final isVoted = post.userVotedOption == idx;
                          final percentage = post.getPercentageForOption(idx);
                          final votes = post.getVotesForOption(idx);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  PostService.instance.votePoll(post, idx);
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isVoted ? WadiqColors.primaryAmber.withValues(alpha: 0.15) : WadiqColors.cardSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isVoted ? WadiqColors.primaryAmber : WadiqColors.surfaceBorder,
                                    width: isVoted ? 1.2 : 0.6,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (post.totalPollVotes > 0)
                                      FractionallySizedBox(
                                        widthFactor: percentage,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: WadiqColors.primaryAmber.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              if (isVoted) ...[
                                                const Icon(Icons.check_circle_rounded, size: 16, color: WadiqColors.primaryAmber),
                                                const SizedBox(width: 6),
                                              ],
                                              Text(
                                                optionText,
                                                style: TextStyle(
                                                  color: isVoted ? WadiqColors.primaryAmber : Colors.white,
                                                  fontWeight: isVoted ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (post.totalPollVotes > 0)
                                            Text(
                                              "${(percentage * 100).toInt()}% ($votes)",
                                              style: TextStyle(
                                                color: isVoted ? WadiqColors.primaryAmber : Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Text(
                          "إجمالي الأصوات: ${post.totalPollVotes} صوت",
                          style: WadiqTypography.caption.copyWith(fontSize: 11, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Actions: Like, Comment, Repost, Bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Like
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              PostService.instance.toggleLike(post);
                            });
                          },
                          icon: Icon(
                            post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: post.isLiked ? Colors.redAccent : WadiqColors.textMuted,
                          ),
                        ),
                        Text("${post.likesCount}", style: WadiqTypography.caption),
                      ],
                    ),

                    // Comments
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                            ).then((_) => setState(() {}));
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: WadiqColors.textMuted),
                        ),
                        Text("${post.commentsCount}", style: WadiqTypography.caption),
                      ],
                    ),

                    // Repost
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              PostService.instance.toggleRepost(post);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(post.isReposted ? "تمت إعادة نشر المنشور في مسارك!" : "تم إلغاء إعادة النشر."),
                                backgroundColor: WadiqColors.primaryAmber,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.repeat_rounded,
                            size: 20,
                            color: post.isReposted ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                          ),
                        ),
                        Text("${post.repostsCount}", style: WadiqTypography.caption),
                      ],
                    ),

                    // Bookmark
                    IconButton(
                      onPressed: () {
                        setState(() {
                          PostService.instance.toggleBookmark(post);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(post.isBookmarked ? "تم حفظ المنشور في المفضلة" : "تمت إزالة المنشور من المفضلة"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: Icon(
                        post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 20,
                        color: post.isBookmarked ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Adaptive image builder according to user's uploaded image dimensions
  Widget _buildPostImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        final base64Data = comma != -1 ? url.substring(comma + 1) : url;
        final bytes = base64Decode(base64Data);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 520),
            color: WadiqColors.elevatedSurface,
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      } catch (_) {}
    }

    final displayUrl = url.startsWith('/api/')
        ? WadiqApiService.instance.getMediaUrl(url)
        : (url.startsWith('http') ? url : WadiqApiService.instance.getMediaUrl(url));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 520),
        color: WadiqColors.elevatedSurface,
        child: Image.network(
          displayUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 180,
              color: WadiqColors.elevatedSurface,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: WadiqColors.primaryAmber,
                ),
              ),
            );
          },
          errorBuilder: (_, error, __) {
            return Container(
              height: 100,
              color: WadiqColors.elevatedSurface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_rounded, color: WadiqColors.textMuted, size: 32),
                    const SizedBox(height: 6),
                    Text("تعذر عرض الصورة", style: WadiqTypography.caption),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
