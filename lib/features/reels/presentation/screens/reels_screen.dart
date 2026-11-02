import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/reel_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../widgets/reel_video_player_widget.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../creation/presentation/screens/create_reel_screen.dart';

class ReelsScreen extends StatefulWidget {
  final bool isActive;

  const ReelsScreen({
    super.key,
    this.isActive = true,
  });

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  List<ReelModel> _reels = [];
  bool _isLoading = true;
  bool _isPlaying = true;
  int _selectedFilterIndex = 0; // 0: العام, 1: أتابعهم
  int _currentIndex = 0;

  // Real controller tracking for the active reel
  VideoPlayerController? _activeController;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  bool _isScrubbing = false;

  // Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Rotating disc animation controller
  late AnimationController _discAnimationController;

  // Caption expanded state per reel ID
  final Set<String> _expandedCaptions = {};

  // Landscape fullscreen mode
  bool _isLandscapeFullscreen = false;

  List<ReelModel> get _displayedReels {
    List<ReelModel> list;
    if (_selectedFilterIndex == 0) {
      list = _reels;
    } else {
      list = _reels.where((r) => PostService.instance.isUserFollowed(r.creatorUsername)).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        final cap = (r.caption ?? '').toLowerCase();
        final name = r.creatorName.toLowerCase();
        final user = r.creatorUsername.toLowerCase();
        final sound = r.soundTitle.toLowerCase();
        return cap.contains(q) || name.contains(q) || user.contains(q) || sound.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isActive && _isPlaying) {
      _discAnimationController.repeat();
    }
    _loadReels();
  }

  @override
  void didUpdateWidget(covariant ReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (!widget.isActive) {
        _activeController?.pause();
        _activeController?.setVolume(0.0);
        _discAnimationController.stop();
      } else {
        _activeController?.setVolume(1.0);
        if (_isPlaying) {
          _activeController?.play();
          _discAnimationController.repeat();
        }
      }
    }
  }

  Future<void> _loadReels() async {
    final list = await ReelService.instance.fetchReels();
    for (var r in list) {
      r.isFollowing = PostService.instance.isUserFollowed(r.creatorUsername);
      r.isSaved = ReelService.instance.isReelSaved(r.id);
      r.isReposted = ReelService.instance.isReelReposted(r.id);
    }
    if (!mounted) return;
    setState(() {
      _reels = list;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _activeController?.removeListener(_onControllerUpdate);
    _discAnimationController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    if (_isLandscapeFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  void _onControllerReady(VideoPlayerController controller) {
    _activeController?.removeListener(_onControllerUpdate);
    _activeController = controller;
    _activeController!.addListener(_onControllerUpdate);

    if (mounted) {
      setState(() {
        _videoPosition = controller.value.position;
        _videoDuration = controller.value.duration;
      });
      if (widget.isActive && _isPlaying) {
        _discAnimationController.repeat();
      }
    }
  }

  void _onControllerUpdate() {
    if (_activeController == null || !mounted || _isScrubbing) return;
    final val = _activeController!.value;
    if (val.isInitialized) {
      setState(() {
        _videoPosition = val.position;
        _videoDuration = val.duration;
      });
      if (val.isPlaying && !_discAnimationController.isAnimating && widget.isActive) {
        _discAnimationController.repeat();
      } else if (!val.isPlaying && _discAnimationController.isAnimating) {
        _discAnimationController.stop();
      }
    }
  }

  void _togglePlayPause() {
    if (_activeController == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying && widget.isActive) {
        _activeController!.play();
        _discAnimationController.repeat();
      } else {
        _activeController!.pause();
        _discAnimationController.stop();
      }
    });
  }

  // --- 1. SEARCH FUNCTIONALITY ---
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  // --- 3. SAVE TO PLATFORM & COLLECTIONS ---
  void _saveReel(ReelModel reel) async {
    final isAlreadySaved = ReelService.instance.isReelSaved(reel.id);

    if (isAlreadySaved) {
      await ReelService.instance.removeReelFromPlatform(reel.id);
      setState(() => reel.isSaved = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تمت إزالة المقطع من المحفوظات."),
            backgroundColor: WadiqColors.alert,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await ReelService.instance.saveReelToPlatform(reel);
      setState(() => reel.isSaved = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: WadiqColors.cardSurface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.bookmark_added_rounded, color: WadiqColors.primaryAmber),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "تم الحفظ في المنصة (تم إشعار صاحب الحساب)",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _showAddToCollectionSheet(reel);
                  },
                  child: const Text(
                    "أضفه إلى مجموعة",
                    style: TextStyle(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _showAddToCollectionSheet(ReelModel reel) {
    final collectionNameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final collections = ReelService.instance.getCollections();
            final savedIn = ReelService.instance.getCollectionsForReel(reel.id);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 16,
              ),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("حفظ في مجموعة", style: WadiqTypography.titleMedium.copyWith(color: Colors.white)),
                      const Icon(Icons.folder_special_rounded, color: WadiqColors.primaryAmber),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Create new collection row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: collectionNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "اسم مجموعة جديدة...",
                            hintStyle: WadiqTypography.caption,
                            filled: true,
                            fillColor: WadiqColors.elevatedSurface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WadiqColors.primaryAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final name = collectionNameController.text.trim();
                          if (name.isEmpty) return;
                          await ReelService.instance.createCollection(name);
                          await ReelService.instance.addReelToCollection(reel.id, name);
                          collectionNameController.clear();
                          setModalState(() {});
                          if (mounted) setState(() {});
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text("تمت إضافة المقطع إلى مجموعة '$name' بنجاح!"),
                              backgroundColor: WadiqColors.primaryAmber,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text("إنشاء +", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("المجموعات السابقة:", style: WadiqTypography.caption.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: collections.length,
                      separatorBuilder: (_, __) => const Divider(color: WadiqColors.divider, height: 1),
                      itemBuilder: (context, idx) {
                        final cName = collections[idx];
                        final isIn = savedIn.contains(cName);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isIn ? Icons.check_circle_rounded : Icons.folder_outlined,
                            color: isIn ? WadiqColors.primaryAmber : Colors.white70,
                          ),
                          title: Text(cName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          trailing: isIn
                              ? const Text("مضاف ✓", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 12))
                              : const Text("+ إضافة", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          onTap: () async {
                            await ReelService.instance.addReelToCollection(reel.id, cName);
                            setModalState(() {});
                            if (mounted) setState(() {});
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("تم الحفظ في مجموعة '$cName'"),
                                backgroundColor: WadiqColors.primaryAmber,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 4. ADVANCED 3-SECTION SHARE SHEET ---
  void _shareReel(ReelModel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final shareUrl = "https://3343-rosy.vercel.app/reel/${reel.id}";
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
                  child: Text("مشاركة مقطع الريلز", style: WadiqTypography.titleMedium.copyWith(color: Colors.white)),
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
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
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
                                  content: "شاهد هذا الريلز الرائع على ودق:\n$shareUrl\n${reel.caption ?? ''}",
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("تم إرسال المقطع إلى @$friend بنجاح!"),
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

                // SECTION 2: إعادة النشر والمشاركة الخارجية
                Text("إعادة نشر ومشاركة عبر التطبيقات 🔄", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Repost Button
                InkWell(
                  onTap: () async {
                    await ReelService.instance.toggleRepost(reel);
                    setState(() {});
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(reel.isReposted ? "تمت إعادة نشر الريلز على صفحتك الشخصية! 🔄" : "تم إلغاء إعادة النشر."),
                        backgroundColor: WadiqColors.primaryAmber,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: reel.isReposted ? WadiqColors.primaryAmber.withValues(alpha: 0.2) : WadiqColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: reel.isReposted ? WadiqColors.primaryAmber : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: reel.isReposted ? WadiqColors.primaryAmber : Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reel.isReposted ? "تمت إعادة النشر على صفحتك (اضغط للإلغاء)" : "إعادة نشر (يظهر لمتابعيك في صفحتك)",
                            style: TextStyle(color: reel.isReposted ? WadiqColors.primaryAmber : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // External apps grid
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

                // SECTION 3: إبلاغ + غير مهتم + إضافة لقصة
                Text("إجراءات سريعة ⚙️", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_stories_rounded, color: WadiqColors.primaryAmber),
                  title: const Text("إضافة إلى قصة (Story)", style: TextStyle(color: Colors.white, fontSize: 13)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تمت إضافة مقطع الريلز إلى قصتك بنجاح 🌟!"),
                        backgroundColor: WadiqColors.primaryAmber,
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_off_rounded, color: Colors.white70),
                  title: const Text("غير مهتم بهذا المحتوى", style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text("سنقلل من اقتراح مقاطع مشابهة", style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () async {
                    await ReelService.instance.markNotInterested(reel.id);
                    Navigator.pop(ctx);
                    setState(() {
                      _reels.removeWhere((r) => r.id == reel.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تم إخفاء المقطع ولن نقترح مقاطع مشابهة."),
                        backgroundColor: WadiqColors.cardSurface,
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_rounded, color: Colors.redAccent),
                  title: const Text("إبلاغ عن المقطع", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportDialog(reel);
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: WadiqColors.elevatedSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _copyAndToast(String text, String target) {
    Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم نسخ رابط الريلز لمشاركته في $target!"),
        backgroundColor: WadiqColors.primaryAmber,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReportDialog(ReelModel reel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        title: const Text("إبلاغ عن المقطع", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportOption(ctx, reel, "محتوى غير لائق أو مسيء"),
            _buildReportOption(ctx, reel, "انتهاك حقوق الملكية الفكرية"),
            _buildReportOption(ctx, reel, "عنف أو تشجيع على الكراهية"),
            _buildReportOption(ctx, reel, "معلومات مضللة أو احتيال"),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(BuildContext ctx, ReelModel reel, String reason) {
    return ListTile(
      title: Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      onTap: () async {
        await ReelService.instance.reportReel(reel.id, reason);
        Navigator.pop(ctx);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("شكراً لك. تم استلام البلاغ وسيتم تدقيقه من الإدارة."),
              backgroundColor: WadiqColors.primaryAmber,
            ),
          );
        }
      },
    );
  }

  // --- 6. LANDSCAPE FULLSCREEN TOGGLE ---
  void _toggleLandscapeFullscreen() {
    setState(() {
      _isLandscapeFullscreen = !_isLandscapeFullscreen;
      if (_isLandscapeFullscreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  // --- 7. LONG PRESS MENU (PLAYBACK SPEED) ---
  void _showLongPressMenu(ReelModel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSpeedState) {
            final speeds = [0.5, 1.0, 1.5, 2.0];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("خيارات تشغيل المقطع", style: WadiqTypography.titleMedium.copyWith(color: Colors.white)),
                      const Icon(Icons.speed_rounded, color: WadiqColors.primaryAmber),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("سرعة التشغيل:", style: WadiqTypography.caption.copyWith(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: speeds.map((s) {
                      final isSelected = (reel.playbackSpeed == s);
                      return GestureDetector(
                        onTap: () {
                          setSpeedState(() => reel.playbackSpeed = s);
                          _activeController?.setPlaybackSpeed(s);
                          setState(() {});
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("تم ضبط سرعة الفيديو على ${s}x"),
                              backgroundColor: WadiqColors.primaryAmber,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? WadiqColors.primaryAmber : WadiqColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? WadiqColors.primaryAmber : Colors.white24),
                          ),
                          child: Text(
                            "${s}x",
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: WadiqColors.divider),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: WadiqColors.primaryAmber, size: 18),
                      const SizedBox(width: 8),
                      Text("مزايا أخرى قريباً (تنزيل صوت المقطع، الترجمة الذكية)", style: WadiqTypography.caption.copyWith(color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 9. ADVANCED COMMENTS SYSTEM ---
  void _showCommentsSheet(BuildContext context, ReelModel reel) {
    final commentController = TextEditingController();
    String? replyingToCommentId;
    String? replyingToAuthor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: ReelService.instance.fetchComments(reel.id),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? reel.comments;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "التعليقات (${comments.length})",
                              style: WadiqTypography.titleMedium.copyWith(color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const Divider(color: WadiqColors.divider, height: 16),

                        // Comments List
                        Expanded(
                          child: comments.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.white24),
                                      const SizedBox(height: 8),
                                      Text(
                                        "لا توجد تعليقات بعد. كن أول من يترك بصمته!",
                                        style: WadiqTypography.caption.copyWith(color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: comments.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, idx) {
                                    final c = comments[idx];
                                    return _buildCommentTile(
                                      comment: c,
                                      reel: reel,
                                      onReplyTap: () {
                                        setSheetState(() {
                                          replyingToCommentId = c['id']?.toString();
                                          replyingToAuthor = c['user'] ?? c['username'] ?? 'مستخدم';
                                        });
                                      },
                                      onLongPress: () {
                                        _showCommentOptions(c);
                                      },
                                      onReactionChanged: () {
                                        setSheetState(() {});
                                      },
                                    );
                                  },
                                ),
                        ),

                        // Active Reply Banner if replying
                        if (replyingToAuthor != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.reply_rounded, size: 16, color: WadiqColors.primaryAmber),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "الرد على $replyingToAuthor...",
                                    style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      replyingToCommentId = null;
                                      replyingToAuthor = null;
                                    });
                                  },
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),

                        const Divider(color: WadiqColors.divider, height: 1),

                        // Input field
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: WadiqColors.primaryAmber,
                                child: Text(
                                  AuthService.instance.currentUser.fullName.isNotEmpty
                                      ? AuthService.instance.currentUser.fullName[0].toUpperCase()
                                      : 'و',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: commentController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: replyingToAuthor != null ? "اكتب ردك على $replyingToAuthor..." : "أضف تعليقاً باسمك...",
                                    hintStyle: WadiqTypography.caption,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send_rounded, color: WadiqColors.primaryAmber),
                                onPressed: () async {
                                  final text = commentController.text.trim();
                                  if (text.isEmpty) return;

                                  await ReelService.instance.addComment(
                                    reel,
                                    text,
                                    replyToId: replyingToCommentId,
                                    replyToUser: replyingToAuthor,
                                  );

                                  commentController.clear();
                                  setSheetState(() {
                                    replyingToCommentId = null;
                                    replyingToAuthor = null;
                                  });
                                  setState(() {});
                                },
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
      },
    );
  }

  Widget _buildCommentTile({
    required Map<String, dynamic> comment,
    required ReelModel reel,
    required VoidCallback onReplyTap,
    required VoidCallback onLongPress,
    required VoidCallback onReactionChanged,
  }) {
    final authorFullName = comment['user'] ?? 'طالب ودق';
    final authorUsername = comment['username'] ?? '';
    final commentText = comment['comment'] ?? '';
    final timeStr = comment['time'] ?? 'الآن';
    final likesCount = (comment['likesCount'] as int?) ?? 0;
    final dislikesCount = (comment['dislikesCount'] as int?) ?? 0;
    final isLiked = comment['isLiked'] == true;
    final isDisliked = comment['isDisliked'] == true;
    final replies = (comment['replies'] as List<dynamic>?) ?? [];

    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: WadiqColors.elevatedSurface,
                child: Text(
                  authorFullName.isNotEmpty ? authorFullName[0].toUpperCase() : 'و',
                  style: const TextStyle(fontSize: 12, color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FULL NAME displayed prominently!
                    Row(
                      children: [
                        Text(
                          authorFullName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (authorUsername.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            "@$authorUsername",
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                        const Spacer(),
                        Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      commentText,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 6),

                    // Actions: Like, Dislike, Reply
                    Row(
                      children: [
                        // Like
                        GestureDetector(
                          onTap: () {
                            ReelService.instance.toggleCommentReaction(comment, isDislike: false);
                            onReactionChanged();
                          },
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 14,
                                color: isLiked ? Colors.redAccent : Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text("$likesCount", style: TextStyle(color: isLiked ? Colors.redAccent : Colors.white60, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Dislike
                        GestureDetector(
                          onTap: () {
                            ReelService.instance.toggleCommentReaction(comment, isDislike: true);
                            onReactionChanged();
                          },
                          child: Row(
                            children: [
                              Icon(
                                isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                                size: 14,
                                color: isDisliked ? Colors.orangeAccent : Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text("$dislikesCount", style: TextStyle(color: isDisliked ? Colors.orangeAccent : Colors.white60, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Reply
                        GestureDetector(
                          onTap: onReplyTap,
                          child: const Text("رد", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    // Nested Replies
                    if (replies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: replies.map((r) {
                            final rMap = r as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: WadiqColors.elevatedSurface,
                                    child: Text(
                                      (rMap['user'] ?? 'م')[0],
                                      style: const TextStyle(fontSize: 10, color: WadiqColors.primaryAmber),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rMap['user'] ?? 'مستخدم',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          rMap['comment'] ?? '',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
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
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentOptions(Map<String, dynamic> comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white),
              title: const Text("نسخ نص التعليق", style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: comment['comment'] ?? ''));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم نسخ التعليق للحافظة"), backgroundColor: WadiqColors.primaryAmber),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: WadiqColors.primaryAmber),
              title: const Text("مشاركة التعليق", style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: "${comment['user']}: ${comment['comment']}"));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم نسخ التعليق للمشاركة"), backgroundColor: WadiqColors.primaryAmber),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: Colors.redAccent),
              title: const Text("إبلاغ عن هذا التعليق", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم استلام البلاغ عن التعليق، شكراً لك."), backgroundColor: WadiqColors.primaryAmber),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSoundDetails(ReelModel reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final currentlySaved = ReelService.instance.isSoundSaved(reel.soundTitle);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: WadiqColors.amberGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reel.soundTitle, style: WadiqTypography.titleMedium.copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(reel.creatorName, style: WadiqTypography.caption.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: currentlySaved ? WadiqColors.primaryAmber : Colors.white,
                          side: BorderSide(color: currentlySaved ? WadiqColors.primaryAmber : Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(currentlySaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined),
                        label: Text(currentlySaved ? "الصوت محفوظ ✓" : "حفظ الصوت"),
                        onPressed: () {
                          ReelService.instance.toggleSaveSound(reel.soundTitle);
                          setSheetState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(currentlySaved ? "تمت إزالة الصوت من المحفوظات." : "تم حفظ الصوت في مكتبتك الموسيقية! 🎵"),
                              backgroundColor: WadiqColors.primaryAmber,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WadiqColors.primaryAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.video_call_rounded),
                        label: const Text("استخدام هذا الصوت", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateReelScreen(initialSoundTitle: reel.soundTitle),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openCreatorProfile(ReelModel reel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          name: reel.creatorName,
          role: 'طالب',
          avatarChar: reel.creatorName.isNotEmpty ? reel.creatorName[0] : 'و',
          handle: '@${reel.creatorUsername}',
          avatarUrl: reel.creatorAvatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: WadiqColors.primaryAmber),
        ),
      );
    }

    final displayed = _displayedReels;

    if (displayed.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "ابحث عن ريلز...",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : const Text("ريلز", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
              onPressed: _toggleSearch,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library_outlined, size: 56, color: Colors.white38),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty ? "لا توجد نتائج بحث مطابقة لـ '$_searchQuery'" : "لا توجد مقاطع ريلز معروضة حالياً.",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WadiqColors.primaryAmber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: const Text("أنشئ أول ريلز", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReelScreen())).then((_) => _loadReels());
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. REELS PAGE VIEW
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: displayed.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
                _isPlaying = true;
                _videoPosition = Duration.zero;
              });
              ReelService.instance.incrementViews(displayed[idx]);
            },
            itemBuilder: (context, index) {
              final reel = displayed[index];
              return _buildReelItem(reel, index);
            },
          ),

          // 2. TOP FLOATING APP BAR (Search + Filters + Camera)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                // Search Button (Requirement 1)
                GestureDetector(
                  onTap: _toggleSearch,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSearching ? WadiqColors.primaryAmber : Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                      color: _isSearching ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // If searching, show search input; else show Filters
                if (_isSearching)
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WadiqColors.primaryAmber, width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: "ابحث عن مقاطع، حسابات، أصوات...",
                          hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFilterPill("العام", 0),
                            const SizedBox(width: 4),
                            _buildFilterPill("أتابعهم", 1),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Create Reel button
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReelScreen())).then((_) => _loadReels());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, int index) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? WadiqColors.primaryAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReelItem(ReelModel reel, int index) {
    final isCurrent = index == _currentIndex;
    final isCaptionExpanded = _expandedCaptions.contains(reel.id);

    // Calculate real video progress (0.0 to 1.0)
    final totalMs = _videoDuration.inMilliseconds;
    final currentMs = _videoPosition.inMilliseconds;
    final progressVal = (totalMs > 0 && isCurrent) ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

    // Check if video is wide (landscape)
    final isWide = _activeController != null && isCurrent && _activeController!.value.aspectRatio > 1.2;

    return GestureDetector(
      onTap: _togglePlayPause,
      onLongPress: () => _showLongPressMenu(reel),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Real Video Player (Requirement 6 & 10)
          ReelVideoPlayerWidget(
            videoUrl: reel.videoUrl,
            isPlaying: _isPlaying && isCurrent && widget.isActive,
            isActive: widget.isActive && isCurrent,
            playbackSpeed: reel.playbackSpeed,
            isLandscape: _isLandscapeFullscreen,
            onControllerReady: isCurrent ? _onControllerReady : null,
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: WadiqColors.videoOverlayGradient),
            ),
          ),

          // 10. REAL PROGRESS BAR (Requirement 10 & 3: Real Video Duration Progress)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => setState(() => _isScrubbing = true),
              onHorizontalDragUpdate: (details) {
                if (_activeController == null || totalMs == 0) return;
                final width = MediaQuery.of(context).size.width;
                final pos = (details.globalPosition.dx / width).clamp(0.0, 1.0);
                final newMs = (pos * totalMs).toInt();
                _activeController!.seekTo(Duration(milliseconds: newMs));
                setState(() => _videoPosition = Duration(milliseconds: newMs));
              },
              onHorizontalDragEnd: (_) => setState(() => _isScrubbing = false),
              child: Container(
                height: 12,
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  value: progressVal,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(WadiqColors.primaryAmber),
                  minHeight: _isScrubbing ? 4.5 : 2.5,
                ),
              ),
            ),
          ),

          // Side Action Column (Likes, Comments, Save, Share)
          Positioned(
            left: 16,
            bottom: 32,
            child: Column(
              children: [
                _buildActionItem(
                  icon: reel.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: reel.isLiked ? Colors.redAccent : Colors.white,
                  label: "${reel.likesCount}",
                  onTap: () => setState(() => ReelService.instance.toggleLike(reel)),
                ),
                const SizedBox(height: 16),
                _buildActionItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  label: "${reel.commentsCount}",
                  onTap: () => _showCommentsSheet(context, reel),
                ),
                const SizedBox(height: 16),
                // Platform Save Button (Requirement 3)
                _buildActionItem(
                  icon: reel.isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                  color: reel.isSaved ? WadiqColors.primaryAmber : Colors.white,
                  label: reel.isSaved ? "تم الحفظ" : "حفظ",
                  onTap: () => _saveReel(reel),
                ),
                const SizedBox(height: 16),
                // Advanced Share Button (Requirement 4)
                _buildActionItem(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  label: "مشاركة",
                  onTap: () => _shareReel(reel),
                ),
                const SizedBox(height: 20),

                // 5. ROTATING MUSIC DISC WITH CREATOR AVATAR (Requirement 5)
                GestureDetector(
                  onTap: () => _openSoundDetails(reel),
                  child: RotationTransition(
                    turns: _discAnimationController,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(color: Colors.white30, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 8, spreadRadius: 2),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Vinyl grooves simulation
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white12, width: 1.5),
                            ),
                          ),
                          // Creator mini avatar inside vinyl
                          ClipOval(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: (reel.creatorAvatarUrl != null && reel.creatorAvatarUrl!.isNotEmpty)
                                  ? Image.network(
                                      WadiqApiService.instance.getMediaUrl(reel.creatorAvatarUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, size: 14, color: WadiqColors.primaryAmber),
                                    )
                                  : const Icon(Icons.music_note_rounded, size: 14, color: WadiqColors.primaryAmber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Creator Info, Caption & Landscape Toggle
          Positioned(
            right: 16,
            left: 92,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 6. Landscape Fullscreen Button (Requirement 6)
                if (isWide) ...[
                  GestureDetector(
                    onTap: _toggleLandscapeFullscreen,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WadiqColors.primaryAmber, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fullscreen_rounded, size: 18, color: WadiqColors.primaryAmber),
                          const SizedBox(width: 6),
                          Text(
                            _isLandscapeFullscreen ? "الوضع العمودي ⛶" : "عرض كامل ⛶",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Creator Account Row
                GestureDetector(
                  onTap: () => _openCreatorProfile(reel),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: WadiqColors.primaryAmber, width: 1.5),
                        ),
                        child: ClipOval(
                          child: (reel.creatorAvatarUrl != null && reel.creatorAvatarUrl!.isNotEmpty)
                              ? Image.network(
                                  WadiqApiService.instance.getMediaUrl(reel.creatorAvatarUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      reel.creatorName.isNotEmpty ? reel.creatorName[0] : 'و',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    reel.creatorName.isNotEmpty ? reel.creatorName[0] : 'و',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    reel.creatorName,
                                    style: WadiqTypography.titleMedium.copyWith(color: Colors.white, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (reel.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 14, color: WadiqColors.primaryAmber),
                                ],
                                const SizedBox(width: 8),
                                if (!reel.isFollowing)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        PostService.instance.toggleFollowUser(reel.creatorUsername);
                                        reel.isFollowing = PostService.instance.isUserFollowed(reel.creatorUsername);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: WadiqColors.primaryAmber,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "+ متابعة",
                                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "متابع ✓",
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              "@${reel.creatorUsername} • ${reel.timeAgo}",
                              style: WadiqTypography.caption.copyWith(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 8. EXPANDABLE CAPTION (Requirement 8)
                if (reel.caption != null && reel.caption!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isCaptionExpanded) {
                          _expandedCaptions.remove(reel.id);
                        } else {
                          _expandedCaptions.add(reel.id);
                        }
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reel.caption!,
                          style: WadiqTypography.bodyLarge.copyWith(color: Colors.white, fontSize: 13, height: 1.4),
                          maxLines: isCaptionExpanded ? 10 : 2,
                          overflow: isCaptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                        if (reel.caption!.length > 60)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              isCaptionExpanded ? "عرض أقل ▲" : "... عرض المزيد ▼",
                              style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Sound Pill
                GestureDetector(
                  onTap: () => _openSoundDetails(reel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note_rounded, size: 14, color: WadiqColors.primaryAmber),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            reel.soundTitle,
                            style: WadiqTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
