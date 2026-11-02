import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../moderation/presentation/widgets/moderation_report_dialog.dart';

class ChannelInfoScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isChannel;
  final String avatarChar;
  final String targetId;

  const ChannelInfoScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isChannel,
    required this.avatarChar,
    required this.targetId,
  });

  @override
  State<ChannelInfoScreen> createState() => _ChannelInfoScreenState();
}

class _ChannelInfoScreenState extends State<ChannelInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMuted = false;
  List<MessageModel> _messages = [];

  ConversationSummary? get conv => ChatService.instance.getConversationById(widget.targetId);

  @override
  void initState() {
    super.initState();
    _isMuted = conv?.isMuted ?? false;
    _tabController = TabController(length: widget.isChannel ? 4 : 3, vsync: this);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final msgs = await ChatService.instance.fetchMessages(widget.targetId);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyLink() {
    final clean = widget.title.replaceAll('@', '').trim();
    final link = "https://wadiq.app/${widget.isChannel ? 'c' : 'u'}/$clean";
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم نسخ الرابط بنجاح: $link"),
        backgroundColor: WadiqColors.success,
      ),
    );
  }

  void _showImageDialog(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.image, size: 80, color: WadiqColors.primaryAmber),
                  const SizedBox(height: 12),
                  Text("عرض الصورة المرفقة", style: WadiqTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(path, style: WadiqTypography.caption, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link_rounded, color: WadiqColors.primaryAmber),
              title: Text("نسخ رابط الحساب / القناة", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                _copyLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined, color: Colors.white70),
              title: Text(_isMuted ? "إلغاء كتم التنبيهات" : "كتم التنبيهات", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _isMuted = !_isMuted;
                  ChatService.instance.toggleMute(widget.targetId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isMuted ? "تم كتم التنبيهات" : "تم إلغاء كتم التنبيهات")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: WadiqColors.alert),
              title: Text("إبلاغ عن محتوى", style: WadiqTypography.bodyLarge.copyWith(color: WadiqColors.alert)),
              onTap: () {
                Navigator.pop(ctx);
                ModerationReportDialog.show(
                  context,
                  targetType: widget.isChannel ? 'channel' : 'conversation',
                  targetId: widget.targetId,
                  targetTitle: widget.title,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanTitle = widget.title.replaceAll('@', '').trim();
    final myUsername = AuthService.instance.currentUser.username.toLowerCase();
    final bool isOwner = conv?.ownerUsername.toLowerCase() == myUsername;
    final realBio = conv?.description ?? (widget.isChannel ? "قناة أكاديمية رسمية لنشر المقررات والملازم والتنبيهات الدراسية." : "حساب أكاديمي مسجل في منصة ودق الوطنية.");

    final mediaMessages = _messages.where((m) => m.mediaType == 'image' && m.mediaUrl != null).toList();

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 270,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  tooltip: "مشاركة",
                  onPressed: _copyLink,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: "المزيد",
                  onPressed: _showMoreOptions,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2C1810), WadiqColors.obsidianBlack],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 36),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            gradient: WadiqColors.amberGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: WadiqColors.amberGlow, blurRadius: 20, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.avatarChar,
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.title, style: WadiqTypography.displayMedium.copyWith(fontSize: 20)),
                            if (widget.isChannel) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.campaign_rounded, size: 18, color: WadiqColors.primaryAmber),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.subtitle, style: WadiqTypography.caption.copyWith(color: WadiqColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionPill(
                          icon: _isMuted ? Icons.notifications_off : Icons.notifications_active_outlined,
                          label: _isMuted ? "مكتوم" : "كتم",
                          isActive: _isMuted,
                          onTap: () {
                            setState(() {
                              _isMuted = !_isMuted;
                              ChatService.instance.toggleMute(widget.targetId);
                            });
                          },
                        ),
                        _buildActionPill(
                          icon: Icons.link_rounded,
                          label: "رابط الحساب",
                          isActive: false,
                          onTap: _copyLink,
                        ),
                        _buildActionPill(
                          icon: Icons.search_rounded,
                          label: "بحث",
                          isActive: false,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        _buildActionPill(
                          icon: Icons.more_horiz_rounded,
                          label: "المزيد",
                          isActive: false,
                          onTap: _showMoreOptions,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bio Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WadiqColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WadiqColors.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("الوصف والمعلومات", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(realBio, style: WadiqTypography.bodyMedium.copyWith(color: Colors.white70, height: 1.4)),
                          const Divider(color: WadiqColors.divider, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("المعرّف الأكاديمي", style: WadiqTypography.caption),
                                  const SizedBox(height: 2),
                                  Text("@$cleanTitle", style: WadiqTypography.titleMedium.copyWith(color: WadiqColors.primaryAmber, fontSize: 14)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18, color: WadiqColors.primaryAmber),
                                onPressed: _copyLink,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: WadiqColors.primaryAmber,
                  labelColor: WadiqColors.primaryAmber,
                  unselectedLabelColor: WadiqColors.textSecondary,
                  labelStyle: WadiqTypography.titleMedium.copyWith(fontSize: 13),
                  tabs: [
                    const Tab(text: "الوسائط"),
                    const Tab(text: "الملفات"),
                    const Tab(text: "الروابط"),
                    if (widget.isChannel) const Tab(text: "الأعضاء"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Media Grid (Real images)
            mediaMessages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text("لا توجد صور مرسلة في هذه المحادثة بعد", style: WadiqTypography.caption),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: mediaMessages.length,
                    itemBuilder: (context, idx) {
                      final m = mediaMessages[idx];
                      return InkWell(
                        onTap: () => _showImageDialog(m.mediaUrl!),
                        child: Container(
                          decoration: BoxDecoration(
                            color: WadiqColors.cardSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: WadiqColors.surfaceBorder),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, color: WadiqColors.primaryAmber, size: 30),
                          ),
                        ),
                      );
                    },
                  ),

            // Files List
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text("لا توجد ملفات مرفقة حالياً", style: WadiqTypography.caption),
              ),
            ),

            // Links List
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, color: WadiqColors.primaryAmber),
                  title: const Text("https://wadiq.app"),
                  subtitle: const Text("رابط المنصة الأكاديمية الرسمي"),
                  onTap: _copyLink,
                ),
              ],
            ),

            // Members (for channels)
            if (widget.isChannel)
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: WadiqColors.primaryAmber,
                      child: Text("م", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(conv?.ownerUsername ?? "المالك", style: WadiqTypography.titleMedium),
                    subtitle: const Text("مالك القناة • صلاحيات كاملة", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 12)),
                  ),
                  if (conv != null && conv!.adminUsernames.isNotEmpty)
                    ...conv!.adminUsernames.map(
                      (u) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: WadiqColors.elevatedSurface,
                          child: Text(u.isNotEmpty ? u[0] : 'أ', style: const TextStyle(color: WadiqColors.primaryAmber)),
                        ),
                        title: Text("@$u", style: WadiqTypography.titleMedium),
                        subtitle: const Text("مشرف معتمد", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        trailing: isOwner
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                onPressed: () {
                                  setState(() => conv!.adminUsernames.remove(u));
                                },
                              )
                            : null,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? WadiqColors.primaryAmber : WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Icon(icon, color: isActive ? Colors.black : WadiqColors.primaryAmber, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: WadiqTypography.caption.copyWith(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverHeaderDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: WadiqColors.obsidianBlack, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) => false;
}
