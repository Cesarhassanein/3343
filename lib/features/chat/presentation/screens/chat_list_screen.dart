import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/chat_settings_service.dart';
import 'chat_room_screen.dart';
import '../../../creation/presentation/screens/create_group_channel_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<ConversationSummary> _conversations = [];
  List<ConversationSummary> _filteredConversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ChatSettingsService.instance.addListener(_onSettingsChanged);
    _initTabController();
    _searchController.addListener(_onSearchChanged);
    _loadConversations();
  }

  void _initTabController([int initialIndex = 0]) {
    final count = ChatSettingsService.instance.folders.length;
    _tabController = TabController(
      length: count > 0 ? count : 1,
      vsync: this,
      initialIndex: initialIndex.clamp(0, (count > 0 ? count : 1) - 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onSettingsChanged() {
    final count = ChatSettingsService.instance.folders.length;
    final targetLength = count > 0 ? count : 1;
    if (_tabController.length != targetLength) {
      final oldIndex = _tabController.index.clamp(0, targetLength - 1);
      _tabController.dispose();
      _initTabController(oldIndex);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ChatSettingsService.instance.removeListener(_onSettingsChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final convs = await ChatService.instance.fetchUserConversations();
    if (!mounted) return;
    setState(() {
      _conversations = convs;
      _filterConversations();
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    _filterConversations();
  }

  void _filterConversations() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredConversations = _conversations.where((c) {
        if (query.isEmpty) return true;
        return c.name.toLowerCase().contains(query) ||
            c.username.toLowerCase().contains(query) ||
            c.lastMessage.toLowerCase().contains(query);
      }).toList();
    });
  }

  List<ConversationSummary> _getTabFilteredList() {
    final folders = ChatSettingsService.instance.folders;
    if (folders.isEmpty) return _filteredConversations;

    final currentIndex = _tabController.index.clamp(0, folders.length - 1);
    final folder = folders[currentIndex];

    if (folder.id == 'all') {
      return _filteredConversations;
    } else if (folder.id == 'academic') {
      return _filteredConversations.where((c) => c.isChannel).toList();
    } else if (folder.id == 'groups') {
      return _filteredConversations.where((c) => c.isGroup).toList();
    } else if (folder.id == 'direct') {
      return _filteredConversations.where((c) => !c.isChannel && !c.isGroup).toList();
    }

    // Custom user folder filter
    return _filteredConversations.where((c) {
      return folder.includedChatIds.contains(c.id) ||
          folder.includedChatIds.contains(c.username) ||
          folder.includedChatIds.contains(c.name);
    }).toList();
  }

  void _openDirectChatWithUser(String username, {String? displayName}) {
    final cleanUsername = username.replaceAll('@', '').trim();
    if (cleanUsername.isEmpty) return;
    final myUsername = AuthService.instance.currentUser.username;
    final convId = ChatService.directConvId(myUsername, cleanUsername);

    ChatService.instance.createOrOpenConversation(
      name: displayName ?? cleanUsername,
      username: cleanUsername,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          title: displayName ?? '@$cleanUsername',
          subtitle: 'محادثة خاصة ومباشرة',
          isChannel: false,
          avatarChar: (displayName ?? cleanUsername).substring(0, 1).toUpperCase(),
          conversationId: convId,
          recipientUsername: cleanUsername,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  void _showNewChatDialog() {
    final userController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "محادثة جديدة مع زميل",
                    style: WadiqTypography.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: WadiqColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "أدخل المعرّف الأكاديمي (@username) لبدء محادثة مشفرة فورية:",
                style: WadiqTypography.caption,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.alternate_email, color: WadiqColors.primaryAmber),
                  hintText: "مثال: ali_tech أو zainab_99",
                  hintStyle: const TextStyle(color: WadiqColors.textMuted),
                  filled: true,
                  fillColor: WadiqColors.elevatedSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WadiqColors.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    "بدء المحادثة الآن",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () async {
                    final target = userController.text.trim();
                    if (target.isEmpty) return;

                    final cleanTarget = target.replaceAll('@', '').toLowerCase().trim();
                    final myUsername = AuthService.instance.currentUser.username.replaceAll('@', '').toLowerCase().trim();

                    if (cleanTarget == myUsername) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("لا يمكنك بدء محادثة مع نفسك."),
                          backgroundColor: WadiqColors.alert,
                        ),
                      );
                      return;
                    }

                    // Check if target user actually exists on the platform
                    final exists = await AuthService.instance.isUsernameTaken(cleanTarget);
                    if (!exists) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("المستخدم @$cleanTarget غير مسجل على المنصة! تأكد من المعرّف."),
                          backgroundColor: WadiqColors.alert,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    _openDirectChatWithUser(cleanTarget);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WadiqColors.textPrimary,
                        side: const BorderSide(color: WadiqColors.surfaceBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.campaign, color: WadiqColors.primaryAmber, size: 18),
                      label: const Text("إنشاء قناة"),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateGroupOrChannelScreen(isChannel: true)),
                        ).then((_) => _loadConversations());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WadiqColors.textPrimary,
                        side: const BorderSide(color: WadiqColors.surfaceBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.groups, color: WadiqColors.primaryAmber, size: 18),
                      label: const Text("إنشاء مجموعة"),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateGroupOrChannelScreen(isChannel: false)),
                        ).then((_) => _loadConversations());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _getTabFilteredList();

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text(
          "المراسلات والقنوات",
          style: WadiqTypography.displayMedium.copyWith(fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: "محادثة جديدة عبر @",
            onPressed: _showNewChatDialog,
            icon: const Icon(Icons.edit_square, color: WadiqColors.primaryAmber, size: 22),
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: WadiqTypography.titleMedium.copyWith(fontSize: 14),
          tabs: ChatSettingsService.instance.folders
              .map((f) => Tab(text: f.name))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: WadiqColors.primaryAmber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text("محادثة جديدة @", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showNewChatDialog,
      ),
      body: Column(
        children: [
          // Search & Direct Contact Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search, color: WadiqColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "ابحث بالاسم أو اكتب @ للبحث عن مستخدم...",
                        hintStyle: WadiqTypography.caption.copyWith(fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: WadiqColors.textMuted),
                      onPressed: () => _searchController.clear(),
                    ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: WadiqColors.primaryAmber),
                  )
                : list.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: WadiqColors.primaryAmber,
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: WadiqColors.divider,
                            height: 1,
                            indent: 72,
                          ),
                          itemBuilder: (context, index) {
                            final chat = list[index];
                            return _buildChatTile(chat);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: WadiqColors.primaryAmber,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "لا توجد محادثات نشطة بعد",
              style: WadiqTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "تواصل مباشرة مع زملائك بالجامعة عبر معرّفهم @، أو أنشئ قناة أكاديمية أو مجموعة لمقرراتك.",
              style: WadiqTypography.caption.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: WadiqColors.primaryAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text(
                "بدء محادثة جديدة عبر @",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _showNewChatDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(ConversationSummary chat) {
    final avatarChar = chat.name.isNotEmpty ? chat.name.substring(0, 1) : 'و';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              title: chat.name,
              subtitle: chat.isChannel
                  ? "قناة تعليمية"
                  : chat.isGroup
                      ? "مجموعة دراسية"
                      : "@${chat.username}",
              isChannel: chat.isChannel,
              avatarChar: avatarChar,
              conversationId: chat.id,
              recipientUsername: chat.username,
            ),
          ),
        ).then((_) => _loadConversations());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: WadiqColors.elevatedSurface,
                  child: Text(
                    avatarChar,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WadiqColors.primaryAmber,
                    ),
                  ),
                ),
                if (chat.isChannel)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: WadiqColors.darkCharcoal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign,
                        size: 14,
                        color: WadiqColors.primaryAmber,
                      ),
                    ),
                  )
                else if (chat.isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: WadiqColors.darkCharcoal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups,
                        size: 14,
                        color: WadiqColors.primaryAmber,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: WadiqTypography.titleMedium.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.time,
                        style: WadiqTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  if (ChatSettingsService.instance.listPreviewMode > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: WadiqTypography.caption.copyWith(
                              color: WadiqColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: ChatSettingsService.instance.listPreviewMode,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
