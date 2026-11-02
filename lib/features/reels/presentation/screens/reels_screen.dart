import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/reel_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../../../../core/utils/file_downloader.dart';
import '../widgets/reel_video_player_widget.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../creation/presentation/screens/create_reel_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  List<ReelModel> _reels = [];
  bool _isLoading = true;
  bool _isPlaying = true;
  int _selectedFilterIndex = 0; // 0: العام, 1: أتابعهم

  List<ReelModel> get _displayedReels {
    if (_selectedFilterIndex == 0) return _reels;
    return _reels.where((r) => PostService.instance.isUserFollowed(r.creatorUsername)).toList();
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _loadReels();
  }

  Future<void> _loadReels() async {
    final list = await ReelService.instance.fetchReels();
    for (var r in list) {
      r.isFollowing = PostService.instance.isUserFollowed(r.creatorUsername);
    }
    if (!mounted) return;
    setState(() {
      _reels = list;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _progressController.repeat();
      } else {
        _progressController.stop();
      }
    });
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
                          Text(reel.soundTitle, style: WadiqTypography.titleMedium.copyWith(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            "بواسطة @${reel.creatorUsername} • استخدام في 12 ريلز",
                            style: WadiqTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: WadiqColors.divider),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    currentlySaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: WadiqColors.primaryAmber,
                  ),
                  title: Text(
                    currentlySaved ? "محفوظ في قائمة الأصوات ✓" : "حفظ الصوت في المفضلة",
                    style: WadiqTypography.bodyLarge,
                  ),
                  onTap: () {
                    ReelService.instance.toggleSaveSound(reel.soundTitle);
                    setSheetState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          currentlySaved ? "تمت إزالة الصوت من المفضلة" : "تم حفظ الصوت في المفضلة لاستخدامه لاحقاً!",
                        ),
                        backgroundColor: WadiqColors.primaryAmber,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.video_call_rounded, color: WadiqColors.primaryAmber),
                  title: Text("استخدام هذا الصوت في ريلز جديد", style: WadiqTypography.bodyLarge),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateReelScreen(initialSoundTitle: reel.soundTitle),
                      ),
                    ).then((_) => _loadReels());
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shareReel(ReelModel reel) {
    final url = "https://wadiq.app/reel/${reel.id}";
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم نسخ رابط الريلز بنجاح: $url"),
        backgroundColor: WadiqColors.success,
      ),
    );
  }

  void _openCreatorProfile(ReelModel reel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          name: reel.creatorName,
          role: "صانع محتوى أكاديمي",
          handle: "@${reel.creatorUsername}",
          avatarChar: reel.creatorName.isNotEmpty ? reel.creatorName[0] : 'و',
          avatarUrl: reel.creatorAvatarUrl,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          reel.isFollowing = PostService.instance.isUserFollowed(reel.creatorUsername);
        });
      }
    });
  }

  void _saveAndDownloadVideo(ReelModel reel) {
    final effectiveUrl = WadiqApiService.instance.getMediaUrl(reel.videoUrl);
    ReelService.instance.toggleSaveReel(reel.id);
    downloadVideoFile(effectiveUrl, 'reel_${reel.id}.mp4');
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم حفظ وتنزيل مقطع الفيديو بنجاح على جهازك! 📥"),
        backgroundColor: WadiqColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: WadiqColors.primaryAmber)),
      );
    }

    if (_reels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_collection_outlined, size: 70, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text("لا توجد مقاطع ريلز منشورة حالياً", style: WadiqTypography.titleLarge.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  "كن أول من ينشر مقطع ريلز تعليمي بالضغط على زر (+) في الأسفل واختيار فيديو من المعرض!",
                  textAlign: TextAlign.center,
                  style: WadiqTypography.caption.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_displayedReels.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFilterIndex == 1
                          ? "لا توجد مقاطع من الحسابات التي تتابعها حالياً"
                          : "لا توجد مقاطع ريلز منشورة حالياً",
                      style: WadiqTypography.titleMedium.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFilterIndex == 1
                          ? "تابع منشئي المحتوى بالضغط على (+) في أي مقطع لتظهر مقاطعهم هنا!"
                          : "كن أول من ينشر مقطع ريلز تعليمي بالضغط على زر (+) في الأسفل!",
                      textAlign: TextAlign.center,
                      style: WadiqTypography.caption.copyWith(color: Colors.white54),
                    ),
                    const SizedBox(height: 18),
                    if (_selectedFilterIndex == 1)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WadiqColors.primaryAmber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => setState(() => _selectedFilterIndex = 0),
                        child: const Text("استكشاف مقاطع الريلز العامة"),
                      ),
                  ],
                ),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _displayedReels.length,
              onPageChanged: (idx) {
                ReelService.instance.incrementViews(_displayedReels[idx]);
                _progressController.reset();
                if (_isPlaying) _progressController.repeat();
              },
              itemBuilder: (context, index) {
                final reel = _displayedReels[index];
                return _buildReelItem(reel, index);
              },
            ),

          // Top Header Tabs: العام vs أتابعهم
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
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
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReelItem(ReelModel reel, int index) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Real Video Player
          ReelVideoPlayerWidget(
            videoUrl: reel.videoUrl,
            isPlaying: _isPlaying,
          ),

          // Center Pause Icon Overlay
          if (!_isPlaying)
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
              ),
            ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: WadiqColors.videoOverlayGradient),
            ),
          ),

          // Progress bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressController.value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(WadiqColors.primaryAmber),
                  minHeight: 2.5,
                );
              },
            ),
          ),

          // Side Action Column
          Positioned(
            left: 16,
            bottom: 28,
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
                _buildActionItem(
                  icon: ReelService.instance.isReelSaved(reel.id) ? Icons.bookmark_added_rounded : Icons.download_rounded,
                  color: ReelService.instance.isReelSaved(reel.id) ? WadiqColors.primaryAmber : Colors.white,
                  label: "حفظ",
                  onTap: () => _saveAndDownloadVideo(reel),
                ),
                const SizedBox(height: 16),
                _buildActionItem(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  label: "مشاركة",
                  onTap: () => _shareReel(reel),
                ),
              ],
            ),
          ),

          // Bottom Creator Info, Caption & Sound (Positioned cleanly at bottom right to not crowd the video)
          Positioned(
            right: 16,
            left: 88,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Creator Account Row
                GestureDetector(
                  onTap: () => _openCreatorProfile(reel),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar with + follow badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: WadiqColors.amberGradient,
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
                          if (!reel.isFollowing)
                            Positioned(
                              bottom: -3,
                              right: -3,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    PostService.instance.toggleFollowUser(reel.creatorUsername);
                                    reel.isFollowing = PostService.instance.isUserFollowed(reel.creatorUsername);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("تمت متابعة @${reel.creatorUsername} +"),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: WadiqColors.primaryAmber,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: WadiqColors.primaryAmber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add, size: 13, color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                                const SizedBox(width: 6),
                                if (!reel.isFollowing)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        PostService.instance.toggleFollowUser(reel.creatorUsername);
                                        reel.isFollowing = PostService.instance.isUserFollowed(reel.creatorUsername);
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("تمت متابعة @${reel.creatorUsername} +"),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: WadiqColors.primaryAmber,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: WadiqColors.primaryAmber,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "+ متابعة",
                                        style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 10),

                // Caption (Video title / description)
                if (reel.caption != null && reel.caption!.isNotEmpty)
                  Text(
                    reel.caption!,
                    style: WadiqTypography.bodyLarge.copyWith(color: Colors.white, fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

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
                        const SizedBox(width: 6),
                        const Icon(Icons.tune_rounded, size: 12, color: Colors.white70),
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
              color: Colors.black.withValues(alpha: 0.4),
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

  void _showCommentsSheet(BuildContext context, ReelModel reel) {
    final commentController = TextEditingController();

    // Fetch persisted comments from backend
    WadiqApiService.instance.getPostComments(reel.id).then((saved) {
      if (saved.isNotEmpty) {
        reel.comments.clear();
        for (var c in saved) {
          reel.comments.add({
            'user': c['authorName'] ?? 'مستخدم',
            'username': c['authorUsername'] ?? '',
            'comment': c['content'] ?? '',
            'time': 'مؤخراً',
          });
        }
        reel.commentsCount = saved.length;
        if (context.mounted) {
          setState(() {});
        }
      }
    });

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
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "التعليقات (${reel.commentsCount})",
                      style: WadiqTypography.titleMedium.copyWith(color: Colors.white),
                    ),
                    const Divider(color: WadiqColors.divider, height: 20),
                    Expanded(
                      child: reel.comments.isEmpty
                          ? Center(
                              child: Text(
                                "لا توجد تعليقات بعد. كن أول من يترك تعليقاً!",
                                style: WadiqTypography.caption.copyWith(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: reel.comments.length,
                              itemBuilder: (context, idx) {
                                final c = reel.comments[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: WadiqColors.elevatedSurface,
                                        child: Text(
                                          (c['user'] ?? 'م')[0],
                                          style: const TextStyle(fontSize: 12, color: WadiqColors.primaryAmber),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(c['user'] ?? '', style: WadiqTypography.titleMedium.copyWith(fontSize: 13)),
                                                Text(c['time'] ?? 'الآن', style: WadiqTypography.caption.copyWith(fontSize: 10)),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(c['comment'] ?? '', style: WadiqTypography.bodyMedium.copyWith(fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(color: WadiqColors.divider, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "أضف تعليقاً على هذا المقطع...",
                                hintStyle: WadiqTypography.caption,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: WadiqColors.primaryAmber),
                            onPressed: () {
                              final text = commentController.text.trim();
                              if (text.isEmpty) return;
                              ReelService.instance.addComment(reel, text);
                              commentController.clear();
                              setSheetState(() {});
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
  }
}
