import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/reel_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import '../../../../core/services/supabase_config.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../feed/presentation/screens/post_detail_screen.dart';
import '../../../reels/presentation/screens/reel_detail_screen.dart';
import '../../../../core/widgets/wadiq_avatar.dart';

class UserProfileScreen extends StatefulWidget {
  final String name;
  final String role;
  final String avatarChar;
  final String handle;
  final String? avatarUrl;

  const UserProfileScreen({
    super.key,
    required this.name,
    required this.role,
    required this.avatarChar,
    this.handle = "@user_tech",
    this.avatarUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  int _followersCount = 0;
  List<PostModel> _userPosts = [];
  List<ReelModel> _userReels = [];
  bool _isLoading = true;
  String _userBio = "عضو مسجل في منصة ودق الأكاديمية 🎓";
  String? _avatarUrl;
  String _displayName = "";
  String _userRole = "";

  String get _cleanUsername => widget.handle.replaceAll('@', '').trim();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isFollowing = PostService.instance.isUserFollowed(_cleanUsername);
    _followersCount = _isFollowing ? 1 : 0;
    _avatarUrl = widget.avatarUrl;
    _displayName = widget.name;
    _userRole = widget.role;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 1. Fetch live profile info from Supabase if available
    try {
      final client = SupabaseConfig.client;
      if (client != null) {
        final profile = await client
            .from('profiles')
            .select('*')
            .eq('username', _cleanUsername)
            .maybeSingle();

        if (profile != null) {
          if (profile['avatar_url'] != null && profile['avatar_url'].toString().isNotEmpty) {
            _avatarUrl = profile['avatar_url'].toString();
          }
          if (profile['full_name'] != null && profile['full_name'].toString().isNotEmpty) {
            _displayName = profile['full_name'].toString();
          }
          if (profile['role'] != null && profile['role'].toString().isNotEmpty) {
            _userRole = profile['role'].toString();
          }
          if (profile['bio'] != null && profile['bio'].toString().isNotEmpty) {
            _userBio = profile['bio'].toString();
          }
        }
      }
    } catch (_) {}

    // 2. Fetch posts and reels created by this user
    final posts = await PostService.instance.fetchPostsByUser(_cleanUsername);
    final reels = await ReelService.instance.fetchReelsByUser(_cleanUsername);

    if (!mounted) return;
    setState(() {
      _userPosts = posts;
      _userReels = reels;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _totalLikesCount {
    int sum = 0;
    for (var p in _userPosts) {
      sum += p.likesCount;
    }
    for (var r in _userReels) {
      sum += r.likesCount;
    }
    return sum;
  }

  void _toggleFollow() {
    setState(() {
      PostService.instance.toggleFollowUser(_cleanUsername);
      _isFollowing = PostService.instance.isUserFollowed(_cleanUsername);
      _followersCount = _isFollowing ? 1 : 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? "تمت متابعة @$_cleanUsername بنجاح!" : "تم إلغاء المتابعة."),
        backgroundColor: WadiqColors.primaryAmber,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _copyProfileLink() {
    final url = "https://wadiq.app/u/$_cleanUsername";
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم نسخ رابط الحساب للمشاركة: $url"),
        backgroundColor: WadiqColors.success,
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined, color: WadiqColors.primaryAmber),
              title: Text("مشاركة الحساب", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _copyProfileLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: Colors.white70),
              title: Text("نسخ الرابط", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _copyProfileLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined, color: Colors.white70),
              title: Text("كتم التنبيهات من هذا الحساب", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تم كتم تنبيهات @$_cleanUsername")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_flipped, color: Colors.orangeAccent),
              title: Text("حظر الحساب", style: WadiqTypography.bodyLarge.copyWith(color: Colors.orangeAccent)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تم حظر @$_cleanUsername")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: WadiqColors.alert),
              title: Text("إبلاغ عن الحساب", style: WadiqTypography.bodyLarge.copyWith(color: WadiqColors.alert)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم استلام بلاغك وستتم مراجعته فوراً.")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("قائمة المتابعين", style: WadiqTypography.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: _isFollowing
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: WadiqAvatar(
                    avatarUrl: AuthService.instance.currentUser.avatarUrl,
                    fallbackInitial: AuthService.instance.currentUser.fullName,
                    radius: 20,
                  ),
                  title: Text(AuthService.instance.currentUser.fullName, style: WadiqTypography.titleMedium),
                  subtitle: Text("@${AuthService.instance.currentUser.username} • أنت", style: WadiqTypography.caption),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "لا يوجد متابعون لهذا الحساب حتى الآن. كن أول من يتابعه!",
                    textAlign: TextAlign.center,
                    style: WadiqTypography.caption,
                  ),
                ),
        ),
        actions: [
          TextButton(
            child: const Text("إغلاق", style: TextStyle(color: WadiqColors.primaryAmber)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _startDirectChat() {
    final myUsername = AuthService.instance.currentUser.username;
    final convId = ChatService.directConvId(myUsername, _cleanUsername);

    ChatService.instance.createOrOpenConversation(
      name: widget.name,
      username: _cleanUsername,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          title: widget.name,
          subtitle: "@$_cleanUsername",
          avatarChar: widget.avatarChar,
          avatarUrl: _avatarUrl,
          conversationId: convId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text(widget.name, style: WadiqTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            tooltip: "مشاركة الحساب",
            onPressed: _copyProfileLink,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            tooltip: "المزيد من الخيارات",
            onPressed: _showMoreMenu,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Avatar with live image support
                    _buildAvatar(),
                    const SizedBox(height: 12),
                    Text(
                      _displayName.isNotEmpty ? _displayName : widget.name,
                      style: WadiqTypography.titleLarge.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${widget.handle} • ${_userRole.isNotEmpty ? _userRole : widget.role}",
                      style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userBio,
                      style: WadiqTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // Stats Row (Reels, Posts, Followers, Likes)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: WadiqColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WadiqColors.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () => _tabController.animateTo(0),
                            child: _buildStatCounter("الريلز", "${_userReels.length}"),
                          ),
                          Container(width: 1, height: 26, color: WadiqColors.divider),
                          InkWell(
                            onTap: () => _tabController.animateTo(1),
                            child: _buildStatCounter("المنشورات", "${_userPosts.length}"),
                          ),
                          Container(width: 1, height: 26, color: WadiqColors.divider),
                          InkWell(
                            onTap: _showFollowersDialog,
                            child: _buildStatCounter("المتابعون", "$_followersCount"),
                          ),
                          Container(width: 1, height: 26, color: WadiqColors.divider),
                          _buildStatCounter("الإعجابات", "$_totalLikesCount"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons (Follow / Message)
                    Row(
                      children: [
                        Expanded(
                          child: WadiqButton(
                            text: _isFollowing ? "إلغاء المتابعة" : "متابعة",
                            type: _isFollowing ? WadiqButtonType.secondary : WadiqButtonType.primary,
                            height: 44,
                            icon: _isFollowing ? Icons.check : Icons.person_add_alt_1_outlined,
                            onPressed: _toggleFollow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: WadiqButton(
                            text: "مراسلة",
                            type: WadiqButtonType.secondary,
                            height: 44,
                            icon: Icons.chat_bubble_outline_rounded,
                            onPressed: _startDirectChat,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: WadiqColors.primaryAmber,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: WadiqColors.primaryAmber,
                  unselectedLabelColor: WadiqColors.textSecondary,
                  labelStyle: WadiqTypography.titleMedium.copyWith(fontSize: 14),
                  tabs: [
                    Tab(text: "الريلز (${_userReels.length})"),
                    Tab(text: "المنشورات (${_userPosts.length})"),
                    const Tab(text: "المقررات"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildReelsGrid(),
            _buildPostsList(),
            _buildCoursesList(),
          ],
        ),
      ),
    );
  }

  /// Build user avatar with image support and initial fallback
  Widget _buildAvatar() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      final displayUrl = WadiqApiService.instance.getMediaUrl(_avatarUrl!);

      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: WadiqColors.primaryAmber, width: 2),
          boxShadow: const [
            BoxShadow(
              color: WadiqColors.amberGlow,
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            displayUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
          ),
        ),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    final initial = _displayName.isNotEmpty ? _displayName[0] : (widget.name.isNotEmpty ? widget.name[0] : 'و');
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        gradient: WadiqColors.amberGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: WadiqColors.amberGlow,
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCounter(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: WadiqTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: WadiqTypography.caption),
      ],
    );
  }

  Widget _buildReelsGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: WadiqColors.primaryAmber));
    }

    if (_userReels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_collection_outlined, size: 50, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Text("لا توجد مقاطع ريلز لهذا الحساب بعد", style: WadiqTypography.caption),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _userReels.length,
      itemBuilder: (context, index) {
        final reel = _userReels[index];
        final videoTitle = reel.caption?.isNotEmpty == true ? reel.caption! : "مقطع ريلز";

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReelDetailScreen(reel: reel)),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1C12), Color(0xFF141414)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Video thumbnail icon & name in center
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.5), width: 1),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: WadiqColors.primaryAmber, size: 26),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          videoTitle,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top corner badge: duration/sound
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.videocam_rounded, size: 12, color: Colors.white70),
                  ),
                ),

                // Bottom stats: views & likes
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 11, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            "${reel.viewsCount}",
                            style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, size: 10, color: Colors.redAccent),
                          const SizedBox(width: 2),
                          Text(
                            "${reel.likesCount}",
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
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
  }

  Widget _buildPostsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: WadiqColors.primaryAmber));
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feed_outlined, size: 50, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Text("لا توجد منشورات لهذا المستخدم بعد", style: WadiqTypography.caption),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _userPosts.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.content, style: WadiqTypography.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text("${post.likesCount}", style: WadiqTypography.caption),
                        const SizedBox(width: 14),
                        const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text("${post.commentsCount}", style: WadiqTypography.caption),
                      ],
                    ),
                    Text("باقي ${post.daysLeft} أيام", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 50, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text("لا توجد مقررات دراسية مضافة حالياً لهذا الحساب", style: WadiqTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: WadiqColors.obsidianBlack,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
