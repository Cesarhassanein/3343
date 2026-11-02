import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/retention_badge.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToAuthor;

  @override
  void initState() {
    super.initState();
    WadiqApiService.instance.getPostComments(widget.post.id).then((comments) {
      if (comments.isNotEmpty && mounted) {
        setState(() {
          widget.post.commentsList.clear();
          widget.post.commentsList.addAll(comments);
          widget.post.commentsCount = comments.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      PostService.instance.addComment(
        widget.post,
        text: text,
        replyToAuthor: _replyingToAuthor,
      );
      _commentController.clear();
      _replyingToAuthor = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = AuthService.instance.currentUser.username.toLowerCase();
    final isAuthor = widget.post.authorUsername.toLowerCase() == myUsername;

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text("تفاصيل المنشور", style: WadiqTypography.titleLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Post Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WadiqColors.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: WadiqColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    name: widget.post.authorName,
                                    role: widget.post.authorRole,
                                    handle: "@${widget.post.authorUsername}",
                                    avatarChar: widget.post.authorName.isNotEmpty ? widget.post.authorName[0] : "و",
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: WadiqColors.elevatedSurface,
                              child: Text(
                                widget.post.authorName.isNotEmpty ? widget.post.authorName[0] : "و",
                                style: const TextStyle(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.post.authorName, style: WadiqTypography.titleMedium),
                                Text("@${widget.post.authorUsername} • ${widget.post.authorRole}", style: WadiqTypography.caption),
                              ],
                            ),
                          ),
                          if (isAuthor)
                            RetentionBadge(
                              daysLeft: widget.post.daysLeft,
                              onRenewTap: () => PostService.instance.renewPost(widget.post.id),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                widget.post.isFollowedPost ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                size: 20,
                                color: widget.post.isFollowedPost ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  PostService.instance.toggleFollowPost(widget.post);
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(widget.post.content, style: WadiqTypography.bodyLarge),

                      if (widget.post.mediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildPostImage(widget.post.mediaUrls.first),
                      ],

                      const SizedBox(height: 16),
                      const Divider(color: WadiqColors.divider),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  widget.post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: widget.post.isLiked ? Colors.redAccent : WadiqColors.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    PostService.instance.toggleLike(widget.post);
                                  });
                                },
                              ),
                              Text("${widget.post.likesCount}", style: WadiqTypography.caption),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: WadiqColors.textMuted),
                              const SizedBox(width: 6),
                              Text("${widget.post.commentsCount}", style: WadiqTypography.caption),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.repeat_rounded,
                                  color: widget.post.isReposted ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    PostService.instance.toggleRepost(widget.post);
                                  });
                                },
                              ),
                              Text("${widget.post.repostsCount}", style: WadiqTypography.caption),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comments Header
                Text(
                  "التعليقات والمناقشات (${widget.post.commentsCount})",
                  style: WadiqTypography.titleLarge.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Real Comments List
                if (widget.post.commentsList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "لا توجد تعليقات حتى الآن. شارك رأيك أولاً!",
                        style: WadiqTypography.caption.copyWith(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ...widget.post.commentsList.map((c) {
                    final author = c['author'] ?? 'مستخدم';
                    final username = c['username'] ?? '';
                    final text = c['text'] ?? '';
                    final time = c['time'] ?? 'الآن';
                    final replyTo = c['replyTo'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WadiqColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: WadiqColors.elevatedSurface,
                                    child: Text(
                                      author.isNotEmpty ? author[0] : 'أ',
                                      style: const TextStyle(fontSize: 12, color: WadiqColors.primaryAmber),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(author, style: WadiqTypography.titleMedium.copyWith(fontSize: 13)),
                                  if (username.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Text("@$username", style: WadiqTypography.caption.copyWith(fontSize: 11)),
                                  ],
                                ],
                              ),
                              Text(time, style: WadiqTypography.caption.copyWith(fontSize: 11)),
                            ],
                          ),
                          if (replyTo != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: WadiqColors.elevatedSurface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text("رداً على @$replyTo", style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 10)),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(text, style: WadiqTypography.bodyMedium.copyWith(fontSize: 13)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _replyingToAuthor = username.isNotEmpty ? username : author;
                                _commentController.text = "@$_replyingToAuthor ";
                              });
                            },
                            child: Text("رد على التعليق", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Add comment bar
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: WadiqColors.cardSurface,
              border: Border(top: BorderSide(color: WadiqColors.surfaceBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToAuthor != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text("الرد على: @$_replyingToAuthor", style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 12)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                          onPressed: () => setState(() => _replyingToAuthor = null),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: WadiqColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "أضف تعليقاً أكاديمياً...",
                            hintStyle: TextStyle(color: WadiqColors.textMuted, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: WadiqColors.primaryAmber,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                        onPressed: _addComment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
