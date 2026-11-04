import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/retention_badge.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../../../../core/services/chat_service.dart';
import 'post_detail_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../search/presentation/screens/global_search_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../moderation/presentation/widgets/moderation_report_dialog.dart';
import '../../../creation/presentation/screens/create_post_screen.dart';
import '../../../../core/widgets/wadiq_avatar.dart';

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

  // --- REQUIREMENT 3: THREE-DOTS MENU (1_ مهتم 2 غير مهتم 3 ابلاغ 4 تفضيلات المحتوى 5 حظر) ---
  void _showPostThreeDotsMenu(PostModel post) {
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
                child: Text("خيارات المنشور", style: WadiqTypography.titleMedium.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: 16),

              // 1. مهتم
              ListTile(
                leading: const Icon(Icons.thumb_up_alt_rounded, color: WadiqColors.primaryAmber),
                title: const Text("1. مهتم بهذا المحتوى", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("سنقترح عليك المزيد من هذا النوع من المنشورات الأكاديمية", style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  PostService.instance.markInterested(post.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تم تسجيل اهتمامك بهذا المنشور! 👍"),
                      backgroundColor: WadiqColors.primaryAmber,
                    ),
                  );
                },
              ),

              // 2. غير مهتم
              ListTile(
                leading: const Icon(Icons.visibility_off_rounded, color: Colors.white70),
                title: const Text("2. غير مهتم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("إخفاء هذا المنشور والتقليل من اقتراح منشورات مشابهة", style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    PostService.instance.markNotInterested(post.id);
                    _refreshPosts();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تم إخفاء هذا المنشور ولن نقترح منشورات مماثلة."),
                      backgroundColor: WadiqColors.cardSurface,
                    ),
                  );
                },
              ),

              // 3. إبلاغ
              ListTile(
                leading: const Icon(Icons.flag_rounded, color: Colors.redAccent),
                title: const Text("3. إبلاغ عن المنشور", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text("إرسال تقرير لمشرفي ودق للمراجعة والتدقيق الأكاديمي", style: TextStyle(color: Colors.white54, fontSize: 12)),
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

              // 4. تفضيلات المحتوى
              ListTile(
                leading: const Icon(Icons.tune_rounded, color: Colors.blueAccent),
                title: const Text("4. تفضيلات المحتوى", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("تعديل المواد والمجالات الأكاديمية التي تهمك", style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showContentPreferencesDialog();
                },
              ),

              // 5. حظر
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.deepOrangeAccent),
                title: Text("5. حظر @${post.authorUsername}", style: const TextStyle(color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text("لن تشاهد أي منشورات أو رسائل من هذا الحساب", style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmBlockUser(post.authorUsername, post.authorName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContentPreferencesDialog() {
    final categories = ["تقنية المعلومات", "الذكاء الاصطناعي", "الطب والصيدلة", "الهندسة", "القانون", "إدارة الأعمال", "العلوم الإنسانية"];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        title: const Text("تفضيلات المحتوى 🎓", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("اختر التخصصات والموضوعات المفضلة لديك لتخصيص مسارك:", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                return Chip(
                  backgroundColor: WadiqColors.elevatedSurface,
                  side: const BorderSide(color: WadiqColors.primaryAmber, width: 0.8),
                  label: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("حفظ التفضيلات", style: TextStyle(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmBlockUser(String username, String fullName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        title: Text("حظر $fullName (@$username)؟", style: const TextStyle(color: Colors.white)),
        content: const Text("عند حظر هذا المستخدم، سيتم إخفاء جميع منشوراته من مسارك ولن يتمكن من مراسلتك.", style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                PostService.instance.blockUser(username);
                _refreshPosts();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("تم حظر @$username بنجاح."),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text("تأكيد الحظر", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- REQUIREMENT 4: 3-SECTION SHARE SHEET ---
  void _showShareSheet(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final shareUrl = "https://3343-rosy.vercel.app/post/${post.id}";
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

                // SECTION 1: إرسال إلى أصدقاء داخل التطبيق
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
                                  content: "اقرأ هذا المنشور على ودق:\n$shareUrl\n${post.content}",
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

                // SECTION 2: إعادة نشر وتطبيقات أخرى للمشاركة
                Text("إعادة نشر ومشاركة عبر التطبيقات 🔄", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Repost Button (فعلي وليس وهمي)
                InkWell(
                  onTap: () {
                    setState(() {
                      PostService.instance.toggleRepost(post);
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(post.isReposted ? "تمت إعادة نشر المنشور في مسارك! 🔄" : "تم إلغاء إعادة النشر."),
                        backgroundColor: WadiqColors.primaryAmber,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: post.isReposted ? WadiqColors.primaryAmber.withValues(alpha: 0.2) : WadiqColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: post.isReposted ? WadiqColors.primaryAmber : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: post.isReposted ? WadiqColors.primaryAmber : Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            post.isReposted ? "تمت إعادة النشر في مسارك (${post.repostsCount}) - اضغط للإلغاء" : "إعادة نشر (فعلية - تظهر لجميع متابعيك)",
                            style: TextStyle(color: post.isReposted ? WadiqColors.primaryAmber : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // External apps
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
                          initialContent: "💬 اقتباس من منشور @${post.authorUsername}:\n\"${post.content}\"\n\n",
                        ),
                      ),
                    ).then((_) => _refreshPosts());
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

  // --- REQUIREMENT 5: REACTIONS BAR ON LONG PRESS ---
  void _showReactionsMenu(PostModel post) {
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
              final isCurrent = post.isLiked && post.userReaction == r['key'];
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    PostService.instance.toggleLike(post, reaction: r['key']!);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isCurrent ? WadiqColors.primaryAmber.withValues(alpha: 0.3) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
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

  // --- REQUIREMENT 6 & 8: RICH COMMENTS BOTTOM SHEET (FULL NAME + LIKE/DISLIKE + REPLIES + ZERO KEYBOARD GAP) ---
  void _showCommentsBottomSheet(PostModel post) {
    final TextEditingController commentCtrl = TextEditingController();
    String? replyingToAuthor;
    String? replyingToCommentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              // FIX: Keyboard padding directly on the sheet with zero awkward gap
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalContext).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle & Header
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "التعليقات والمناقشات (${post.commentsCount})",
                            style: WadiqTypography.titleMedium.copyWith(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: WadiqColors.divider, height: 1),

                    // Comments List
                    Expanded(
                      child: post.commentsList.isEmpty
                          ? Center(
                              child: Text(
                                "لا توجد تعليقات حتى الآن. شارك رأيك أولاً!",
                                style: WadiqTypography.caption.copyWith(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: post.commentsList.length,
                              itemBuilder: (cContext, cIdx) {
                                final c = post.commentsList[cIdx];
                                return _buildCommentItem(
                                  post: post,
                                  comment: c,
                                  onReplyTap: (author, cId) {
                                    setModalState(() {
                                      replyingToAuthor = author;
                                      replyingToCommentId = cId;
                                      commentCtrl.text = "@$author ";
                                    });
                                  },
                                  onUpdate: () {
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                    ),

                    // Input bar (Snug against keyboard with zero empty gap)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: WadiqColors.obsidianBlack,
                        border: Border(top: BorderSide(color: WadiqColors.surfaceBorder, width: 0.8)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (replyingToAuthor != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text("الرد على: @$replyingToAuthor", style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 12)),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => setModalState(() {
                                      replyingToAuthor = null;
                                      replyingToCommentId = null;
                                      commentCtrl.clear();
                                    }),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white54),
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
                                    border: Border.all(color: WadiqColors.surfaceBorder, width: 0.6),
                                  ),
                                  child: TextField(
                                    controller: commentCtrl,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText: "أضف تعليقاً أكاديمياً...",
                                      hintStyle: TextStyle(color: WadiqColors.textMuted, fontSize: 12),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: WadiqColors.primaryAmber,
                                radius: 18,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.send_rounded, color: Colors.black, size: 16),
                                  onPressed: () {
                                    final text = commentCtrl.text.trim();
                                    if (text.isEmpty) return;
                                    PostService.instance.addComment(
                                      post,
                                      text: text,
                                      replyToAuthor: replyingToAuthor,
                                      parentCommentId: replyingToCommentId,
                                    );
                                    commentCtrl.clear();
                                    setModalState(() {
                                      replyingToAuthor = null;
                                      replyingToCommentId = null;
                                    });
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
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
      },
    );
  }

  Widget _buildCommentItem({
    required PostModel post,
    required Map<String, dynamic> comment,
    required Function(String author, String? commentId) onReplyTap,
    required VoidCallback onUpdate,
  }) {
    final authorName = comment['author'] ?? 'مستخدم ودق'; // REQUIREMENT: Full Name prominently displayed
    final username = comment['username'] ?? 'user';
    final text = comment['text'] ?? '';
    final time = comment['time'] ?? 'الآن';
    final replyTo = comment['replyTo'];
    final likesCount = (comment['likesCount'] ?? comment['likes'] ?? 0) as int;
    final dislikesCount = (comment['dislikesCount'] ?? comment['dislikes'] ?? 0) as int;
    final isLiked = comment['isLiked'] == true;
    final isDisliked = comment['isDisliked'] == true;
    final userReaction = comment['userReaction'];
    final replies = (comment['replies'] as List<dynamic>? ?? []);

    return InkWell(
      onLongPress: () => _showCommentLongPressMenu(post, comment, onUpdate),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WadiqColors.elevatedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WadiqColors.surfaceBorder, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                WadiqAvatar(
                  avatarUrl: comment['avatarUrl']?.toString() ?? comment['author_avatar']?.toString(),
                  fallbackInitial: authorName,
                  radius: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // REQUIREMENT 6: Show Full Name clearly
                      Text(
                        authorName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        "@$username",
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
            if (replyTo != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: WadiqColors.cardSurface, borderRadius: BorderRadius.circular(4)),
                child: Text("رداً على @$replyTo", style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 10)),
              ),
            ],
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 8),

            // Live comment actions: Like, Dislike, Reply
            Row(
              children: [
                // Comment Like
                InkWell(
                  onTap: () {
                    PostService.instance.toggleCommentVote(post, comment, 'like');
                    onUpdate();
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

                // Comment Dislike
                InkWell(
                  onTap: () {
                    PostService.instance.toggleCommentVote(post, comment, 'dislike');
                    onUpdate();
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

                // Reply Button
                InkWell(
                  onTap: () => onReplyTap(username, comment['id']?.toString()),
                  child: const Text("رد", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),

                if (userReaction != null) ...[
                  const Spacer(),
                  Text(userReaction, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),

            // Nested Replies
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
                        color: WadiqColors.cardSurface,
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
  }

  void _showCommentLongPressMenu(PostModel post, Map<String, dynamic> comment, VoidCallback onUpdate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final commentText = comment['text'] ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Comment Reactions Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👍', '❤️', '💡', '👏', '😂', '😢'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      PostService.instance.setCommentReaction(comment, emoji);
                      onUpdate();
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
                  _showShareSheet(post);
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
            // REQUIREMENT 1: Rename to منشورات
            Tab(text: "منشورات"),
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
    final isFollowed = PostService.instance.isUserFollowed(post.authorUsername);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WadiqColors.surfaceBorder, width: 0.9),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Handle, + متابعة Button, Three-dots
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
                            avatarUrl: post.authorAvatar,
                          ),
                        ),
                      );
                    },
                    child: WadiqAvatar(
                      avatarUrl: post.authorAvatar,
                      fallbackInitial: post.authorName,
                      radius: 20,
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
                              avatarUrl: post.authorAvatar,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  style: WadiqTypography.titleMedium.copyWith(fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // REQUIREMENT 2: + متابعة Button beside author
                              if (!isAuthor) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      PostService.instance.toggleFollowUser(post.authorUsername);
                                    });
                                    final nowFollowed = PostService.instance.isUserFollowed(post.authorUsername);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(nowFollowed ? "بدأت بمتابعة ${post.authorName}!" : "تم إلغاء متابعة ${post.authorName}."),
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
                          Text(
                            "@${post.authorUsername} • ${post.authorRole}",
                            style: WadiqTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Retention Badge for author
                  if (isAuthor)
                    RetentionBadge(
                      daysLeft: post.daysLeft,
                      onRenewTap: () => _renewPost(post),
                    ),

                  // REQUIREMENT 3: Three dots button (1_ مهتم 2 غير مهتم 3 ابلاغ 4 تفضيلات المحتوى 5 حظر)
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, size: 20, color: WadiqColors.textMuted),
                    onPressed: () => _showPostThreeDotsMenu(post),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content (Clickable to open details)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                  ).then((_) => setState(() {}));
                },
                child: Text(
                  post.content,
                  style: WadiqTypography.bodyLarge,
                ),
              ),

              // Attached Media Image
              if (post.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                    ).then((_) => setState(() {}));
                  },
                  child: _buildPostImage(post.mediaUrls.first),
                ),
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

              // Actions Row: Like (Long press for reactions), Comments, Repost, Share, Bookmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // REQUIREMENT 5: Like + Long-press for all reactions
                  InkWell(
                    onTap: () {
                      setState(() {
                        PostService.instance.toggleLike(post);
                      });
                    },
                    onLongPress: () => _showReactionsMenu(post),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          if (post.isLiked && post.userReaction != null)
                            Text(post.reactionEmoji, style: const TextStyle(fontSize: 18))
                          else
                            Icon(
                              post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 20,
                              color: post.isLiked ? Colors.redAccent : WadiqColors.textMuted,
                            ),
                          const SizedBox(width: 5),
                          Text("${post.likesCount}", style: WadiqTypography.caption),
                        ],
                      ),
                    ),
                  ),

                  // Comments
                  InkWell(
                    onTap: () => _showCommentsBottomSheet(post),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: WadiqColors.textMuted),
                          const SizedBox(width: 5),
                          Text("${post.commentsCount}", style: WadiqTypography.caption),
                        ],
                      ),
                    ),
                  ),

                  // Repost
                  InkWell(
                    onTap: () {
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
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 20,
                            color: post.isReposted ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text("${post.repostsCount}", style: WadiqTypography.caption),
                        ],
                      ),
                    ),
                  ),

                  // REQUIREMENT 4: 3-Section Share Button
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20, color: WadiqColors.textMuted),
                    onPressed: () => _showShareSheet(post),
                  ),

                  // Bookmark
                  IconButton(
                    icon: Icon(
                      post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 20,
                      color: post.isBookmarked ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                    ),
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
                  ),
                ],
              ),
            ],
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
