import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/retention_badge.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onCommentTap;

  const PostCard({
    super.key,
    required this.post,
    this.onCommentTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final myUsername = AuthService.instance.currentUser.username.toLowerCase();
    final isAuthor = post.authorUsername.toLowerCase() == myUsername;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WadiqColors.surfaceBorder, width: 0.9),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onCommentTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Author info & Retention Badge / Follow Button
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
                              avatarChar: post.authorName.isNotEmpty ? post.authorName[0] : 'أ',
                              handle: "@${post.authorUsername}",
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: WadiqColors.amberGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                post.authorName.isNotEmpty ? post.authorName[0] : 'أ',
                                style: WadiqTypography.titleMedium.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    post.authorName,
                                    style: WadiqTypography.titleMedium.copyWith(fontSize: 15),
                                  ),
                                  if (!isAuthor) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          PostService.instance.toggleFollowUser(post.authorUsername);
                                        });
                                        final isNowFollowed = PostService.instance.isUserFollowed(post.authorUsername);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isNowFollowed ? "بدأت بمتابعة ${post.authorName}!" : "تم إلغاء متابعة ${post.authorName}."),
                                            backgroundColor: WadiqColors.primaryAmber,
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: PostService.instance.isUserFollowed(post.authorUsername) ? WadiqColors.elevatedSurface : WadiqColors.primaryAmber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: PostService.instance.isUserFollowed(post.authorUsername) ? WadiqColors.surfaceBorder : WadiqColors.primaryAmber,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              PostService.instance.isUserFollowed(post.authorUsername) ? Icons.check_rounded : Icons.add_rounded,
                                              size: 12,
                                              color: PostService.instance.isUserFollowed(post.authorUsername) ? Colors.white70 : WadiqColors.primaryAmber,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              PostService.instance.isUserFollowed(post.authorUsername) ? "متابع" : "متابعة",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: PostService.instance.isUserFollowed(post.authorUsername) ? Colors.white70 : WadiqColors.primaryAmber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      post.authorRole,
                                      style: WadiqTypography.caption.copyWith(
                                        color: WadiqColors.primaryAmber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "@${post.authorUsername}",
                                style: WadiqTypography.caption.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isAuthor)
                      RetentionBadge(
                        daysLeft: post.daysRemaining,
                        onRenewTap: () async {
                          await PostService.instance.renewPost(post.id);
                          if (mounted) setState(() {});
                        },
                      )
                    else
                      InkWell(
                        onTap: () {
                          PostService.instance.toggleFollowPost(post);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                post.isFollowedPost
                                    ? 'تم تفعيل متابعة المنشور لتصلك إشعارات التعليقات والتفاعلات.'
                                    : 'تم إلغاء متابعة تحديثات المنشور.',
                              ),
                              backgroundColor: WadiqColors.cardSurface,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: post.isFollowedPost
                                ? WadiqColors.primaryAmber.withValues(alpha: 0.15)
                                : WadiqColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: post.isFollowedPost ? WadiqColors.primaryAmber : WadiqColors.surfaceBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                post.isFollowedPost ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                size: 14,
                                color: post.isFollowedPost ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.isFollowedPost ? "متابع" : "متابعة المنشور",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: post.isFollowedPost ? WadiqColors.primaryAmber : WadiqColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content
                Text(
                  post.content,
                  style: WadiqTypography.bodyLarge.copyWith(height: 1.5),
                ),

                // Media Gallery (Adaptive height according to user image)
                if (post.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: WadiqColors.elevatedSurface,
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 520),
                      child: _buildPostImage(post.mediaUrls.first),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Actions: Like, Comment, Repost, Bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        PostService.instance.toggleLike(post);
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: post.isLiked ? const Color(0xFFEF4444) : WadiqColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text("${post.likesCount}", style: WadiqTypography.caption),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: widget.onCommentTap,
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: WadiqColors.textSecondary),
                          const SizedBox(width: 6),
                          Text("${post.commentsCount}", style: WadiqTypography.caption),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        PostService.instance.toggleRepost(post);
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 20,
                            color: post.isReposted ? WadiqColors.success : WadiqColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text("${post.repostsCount}", style: WadiqTypography.caption),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 20,
                        color: post.isBookmarked ? WadiqColors.primaryAmber : WadiqColors.textSecondary,
                      ),
                      onPressed: () {
                        PostService.instance.toggleBookmark(post);
                        setState(() {});
                      },
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

  /// Build image widget supporting both Base64 data URLs and API URLs
  Widget _buildPostImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        final base64Data = comma != -1 ? url.substring(comma + 1) : url;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_rounded, color: WadiqColors.textMuted, size: 36),
          ),
        );
      } catch (_) {}
    }
    // For API URLs (/api/media/xxx), file IDs, or full URLs
    final displayUrl = WadiqApiService.instance.getMediaUrl(url);
    return Image.network(
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
      errorBuilder: (context, error, stackTrace) => Container(
        height: 100,
        color: WadiqColors.elevatedSurface,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded, color: WadiqColors.textMuted, size: 32),
              SizedBox(height: 6),
              Text("تعذر عرض الصورة", style: TextStyle(color: WadiqColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
