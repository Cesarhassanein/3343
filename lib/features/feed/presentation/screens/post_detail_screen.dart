import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/retention_badge.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../moderation/presentation/widgets/moderation_report_dialog.dart';
import '../../../creation/presentation/screens/create_post_screen.dart';

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
  String? _replyingToCommentId;

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
        parentCommentId: _replyingToCommentId,
      );
      _commentController.clear();
      _replyingToAuthor = null;
      _replyingToCommentId = null;
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

  void _showReactionsMenu() {
    final reactions = [
      {'key': 'like', 'emoji': '👍', 'label': 'إعجاب'},
      {'key': 'love', 'emoji': '❤️', 'label': 'حب'},
      {'key': 'insightful', 'emoji': '💡', 'label': 'مفيد'},
      {'key': 'clap', 'emoji': '👏', 'label': 'تصفيق'},
      {'key': 'laugh', 'emoji': '😂', 'label': 'مضحك'},
      {'key': 'sad', 'emoji': '😢', 'label': 'حزين'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: WadiqColors.cardSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: reactions.map((r) {
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    PostService.instance.toggleLike(widget.post, reaction: r['key']!);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    r['emoji']!,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final shareUrl = "https://3343-rosy.vercel.app/post/${widget.post.id}";
        final friends = PostService.instance.followedUsernames.toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text("مشاركة المنشور", style: WadiqTypography.titleMedium.copyWith(color: Colors.white)),
                ),
                const SizedBox(height: 16),

                // SECTION 1: أصدقاء داخل التطبيق
                Text("إرسال إلى أصدقاء داخل التطبيق 💬", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (friends.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: WadiqColors.elevatedSurface, borderRadius: BorderRadius.circular(10)),
                    child: const Center(
                      child: Text("تابِع أصدقاء داخل ودق ليظهروا هنا للإرسال السريع!", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  )
                else
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: friends.length,
                      separatorBuilder: (context, i) => const SizedBox(width: 14),
                      itemBuilder: (context, idx) {
                        final friend = friends[idx];
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: WadiqColors.elevatedSurface,
                              child: Text(friend.isNotEmpty ? friend[0].toUpperCase() : '؟', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text("@$friend", style: const TextStyle(color: Colors.white70, fontSize: 10), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () {
                                ChatService.instance.sendMessage(
                                  conversationId: "conv_${friend}_${AuthService.instance.currentUser.username}",
                                  content: "اقرأ هذا المنشور على ودق:\n$shareUrl\n${widget.post.content}",
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("تم إرسال المنشور إلى @$friend بنجاح!"),
                                    backgroundColor: WadiqColors.primaryAmber,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: WadiqColors.primaryAmber, borderRadius: BorderRadius.circular(8)),
                                child: const Text("إرسال", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                const Divider(color: WadiqColors.divider, height: 24),

                // SECTION 2: إعادة النشر وتطبيقات أخرى
                Text("إعادة نشر ومشاركة عبر التطبيقات 🔄", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    setState(() {
                      PostService.instance.toggleRepost(widget.post);
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.post.isReposted ? "تمت إعادة نشر المنشور في مسارك! 🔄" : "تم إلغاء إعادة النشر."),
                        backgroundColor: WadiqColors.primaryAmber,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.post.isReposted ? WadiqColors.primaryAmber.withValues(alpha: 0.2) : WadiqColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.post.isReposted ? WadiqColors.primaryAmber : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: widget.post.isReposted ? WadiqColors.primaryAmber : Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.post.isReposted ? "تمت إعادة النشر (${widget.post.repostsCount}) - اضغط للإلغاء" : "إعادة نشر (فعلية - تظهر لمتابعيك)",
                            style: TextStyle(color: widget.post.isReposted ? WadiqColors.primaryAmber : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildShareAppTile(Icons.telegram, "تيليجرام", const Color(0xFF229ED9), () => _copyAndToast(shareUrl, "تيليجرام")),
                    _buildShareAppTile(Icons.facebook, "فيسبوك", const Color(0xFF1877F2), () => _copyAndToast(shareUrl, "فيسبوك")),
                    _buildShareAppTile(Icons.chat_bubble_rounded, "ماسنجر", const Color(0xFF00B2FF), () => _copyAndToast(shareUrl, "ماسنجر")),
                    _buildShareAppTile(Icons.camera_alt_rounded, "انستغرام", const Color(0xFFE4405F), () => _copyAndToast(shareUrl, "انستغرام")),
                    _buildShareAppTile(Icons.phone_android_rounded, "واتساب", const Color(0xFF25D366), () => _copyAndToast(shareUrl, "واتساب")),
                    _buildShareAppTile(Icons.mail_rounded, "إيميل", Colors.orangeAccent, () => _copyAndToast(shareUrl, "الإيميل")),
                    _buildShareAppTile(Icons.sms_rounded, "SMS", Colors.tealAccent, () => _copyAndToast(shareUrl, "الرسائل القصيرة")),
                    _buildShareAppTile(Icons.link_rounded, "نسخ الرابط", WadiqColors.primaryAmber, () => _copyAndToast(shareUrl, "الحافظة")),
                  ],
                ),

                const Divider(color: WadiqColors.divider, height: 24),

                // SECTION 3: نشر كمنشور
                Text("نشر في ودق ✍️", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: WadiqColors.elevatedSurface,
                    child: Icon(Icons.edit_note_rounded, color: WadiqColors.primaryAmber),
                  ),
                  title: const Text("نشر كمنشور (Quote Post)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text("اقتباس هذا المنشور ومشاركته مع تعليقك الخاص", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreatePostScreen(
                          initialContent: "💬 اقتباس من منشور @${widget.post.authorUsername}:\n\"${widget.post.content}\"\n\n",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareAppTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: WadiqColors.elevatedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WadiqColors.surfaceBorder, width: 0.6),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _copyAndToast(String url, String platform) {
    Clipboard.setData(ClipboardData(text: url));
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم نسخ رابط المنشور لمشاركته عبر $platform! 📋"),
        backgroundColor: WadiqColors.primaryAmber,
      ),
    );
  }

  void _showCommentLongPressMenu(Map<String, dynamic> comment) {
    final commentText = comment['text'] ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👍', '❤️', '💡', '👏', '😂', '😢'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        PostService.instance.setCommentReaction(comment, emoji);
                      });
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  );
                }).toList(),
              ),
              const Divider(color: WadiqColors.divider, height: 24),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                title: const Text("نسخ نص التعليق", style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: commentText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم نسخ التعليق! 📋"), backgroundColor: WadiqColors.primaryAmber),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: WadiqColors.primaryAmber),
                title: const Text("مشاركة التعليق", style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showShareSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_rounded, color: Colors.redAccent),
                title: const Text("إبلاغ عن التعليق", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  ModerationReportDialog.show(
                    context,
                    targetType: "comment",
                    targetId: comment['id']?.toString() ?? '',
                    targetTitle: commentText.length > 30 ? "${commentText.substring(0, 30)}..." : commentText,
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
  Widget build(BuildContext context) {
    final myUsername = AuthService.instance.currentUser.username.toLowerCase();
    final isAuthor = widget.post.authorUsername.toLowerCase() == myUsername;
    final isFollowed = PostService.instance.isUserFollowed(widget.post.authorUsername);

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text("تفاصيل المنشور", style: WadiqTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _showShareSheet,
          ),
        ],
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
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.post.authorName,
                                        style: WadiqTypography.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!isAuthor) ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            PostService.instance.toggleFollowUser(widget.post.authorUsername);
                                          });
                                          final nowFollowed = PostService.instance.isUserFollowed(widget.post.authorUsername);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(nowFollowed ? "بدأت بمتابعة ${widget.post.authorName}!" : "تم إلغاء متابعة ${widget.post.authorName}."),
                                              backgroundColor: WadiqColors.primaryAmber,
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isFollowed ? WadiqColors.elevatedSurface : WadiqColors.primaryAmber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isFollowed ? WadiqColors.surfaceBorder : WadiqColors.primaryAmber,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isFollowed ? Icons.check_rounded : Icons.add_rounded,
                                                size: 12,
                                                color: isFollowed ? Colors.white70 : WadiqColors.primaryAmber,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isFollowed ? "متابع" : "متابعة",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isFollowed ? Colors.white70 : WadiqColors.primaryAmber,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text("@${widget.post.authorUsername} • ${widget.post.authorRole}", style: WadiqTypography.caption),
                              ],
                            ),
                          ),
                          if (isAuthor)
                            RetentionBadge(
                              daysLeft: widget.post.daysLeft,
                              onRenewTap: () => PostService.instance.renewPost(widget.post.id),
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
                          // Like with long press
                          InkWell(
                            onTap: () {
                              setState(() {
                                PostService.instance.toggleLike(widget.post);
                              });
                            },
                            onLongPress: _showReactionsMenu,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  if (widget.post.isLiked && widget.post.userReaction != null)
                                    Text(widget.post.reactionEmoji, style: const TextStyle(fontSize: 18))
                                  else
                                    Icon(
                                      widget.post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: widget.post.isLiked ? Colors.redAccent : WadiqColors.textMuted,
                                      size: 20,
                                    ),
                                  const SizedBox(width: 6),
                                  Text("${widget.post.likesCount}", style: WadiqTypography.caption),
                                ],
                              ),
                            ),
                          ),

                          Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: WadiqColors.textMuted),
                              const SizedBox(width: 6),
                              Text("${widget.post.commentsCount}", style: WadiqTypography.caption),
                            ],
                          ),

                          InkWell(
                            onTap: () {
                              setState(() {
                                PostService.instance.toggleRepost(widget.post);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(widget.post.isReposted ? "تمت إعادة النشر في مسارك!" : "تم إلغاء إعادة النشر."),
                                  backgroundColor: WadiqColors.primaryAmber,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.repeat_rounded,
                                    color: widget.post.isReposted ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text("${widget.post.repostsCount}", style: WadiqTypography.caption),
                                ],
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 20, color: WadiqColors.textMuted),
                            onPressed: _showShareSheet,
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
                    final author = c['author'] ?? 'مستخدم ودق'; // REQUIREMENT: Full Name
                    final username = c['username'] ?? '';
                    final text = c['text'] ?? '';
                    final time = c['time'] ?? 'الآن';
                    final replyTo = c['replyTo'];
                    final likesCount = (c['likesCount'] ?? c['likes'] ?? 0) as int;
                    final dislikesCount = (c['dislikesCount'] ?? c['dislikes'] ?? 0) as int;
                    final isLiked = c['isLiked'] == true;
                    final isDisliked = c['isDisliked'] == true;
                    final userReaction = c['userReaction'];
                    final replies = (c['replies'] as List<dynamic>? ?? []);

                    return InkWell(
                      onLongPress: () => _showCommentLongPressMenu(c),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
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
                                        style: const TextStyle(fontSize: 12, color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Full Name
                                    Text(author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    if (username.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Text("@$username", style: WadiqTypography.caption.copyWith(fontSize: 10)),
                                    ],
                                  ],
                                ),
                                Text(time, style: WadiqTypography.caption.copyWith(fontSize: 10)),
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
                            const SizedBox(height: 8),

                            // Like, Dislike, Reply
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      PostService.instance.toggleCommentVote(widget.post, c, 'like');
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                        size: 14,
                                        color: isLiked ? WadiqColors.primaryAmber : Colors.white60,
                                      ),
                                      const SizedBox(width: 4),
                                      Text("$likesCount", style: TextStyle(color: isLiked ? WadiqColors.primaryAmber : Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      PostService.instance.toggleCommentVote(widget.post, c, 'dislike');
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        isDisliked ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined,
                                        size: 14,
                                        color: isDisliked ? Colors.redAccent : Colors.white60,
                                      ),
                                      const SizedBox(width: 4),
                                      Text("$dislikesCount", style: TextStyle(color: isDisliked ? Colors.redAccent : Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _replyingToAuthor = username.isNotEmpty ? username : author;
                                      _replyingToCommentId = c['id']?.toString();
                                      _commentController.text = "@$_replyingToAuthor ";
                                    });
                                  },
                                  child: const Text("رد", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),

                                if (userReaction != null) ...[
                                  const Spacer(),
                                  Text(userReaction, style: const TextStyle(fontSize: 12)),
                                ],
                              ],
                            ),

                            // Nested replies
                            if (replies.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: replies.map((rep) {
                                    final rAuthor = rep['author'] ?? 'مستخدم';
                                    final rUser = rep['username'] ?? '';
                                    final rText = rep['text'] ?? '';
                                    return Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: WadiqColors.elevatedSurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: const Border(right: BorderSide(color: WadiqColors.primaryAmber, width: 2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(rAuthor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                              const SizedBox(width: 4),
                                              Text("@$rUser", style: const TextStyle(color: Colors.white38, fontSize: 9)),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(rText, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Add comment bar (FIXED: Zero awkward gap with keyboard)
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 8,
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
                          onPressed: () => setState(() {
                            _replyingToAuthor = null;
                            _replyingToCommentId = null;
                            _commentController.clear();
                          }),
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
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
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
          errorBuilder: (context, error, stackTrace) {
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
