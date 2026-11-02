import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/supabase_config.dart';
import '../../../../core/services/chat_service.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  void _performSearch(String query) async {
    final cleanQuery = query.replaceAll('@', '').trim();
    if (cleanQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final List<Map<String, dynamic>> results = [];

    // 1. Search Channels and Groups
    final matchedChannels = ChatService.instance.searchChannelsAndGroups(cleanQuery);
    for (var ch in matchedChannels) {
      results.add({
        'type': ch.isChannel ? 'channel' : 'group',
        'name': ch.name,
        'username': ch.username,
        'role': ch.isChannel ? 'قناة أكاديمية' : 'مجموعة دراسية',
        'bio': ch.description ?? (ch.isChannel ? 'قناة للبث الأكاديمي المباشر' : 'مجموعة نقاش أكاديمية'),
        'convId': ch.id,
      });
    }

    // 2. Query registered users from Supabase profiles
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final profilesRes = await client
            .from('profiles')
            .select('*')
            .or('username.ilike.%$cleanQuery%,full_name.ilike.%$cleanQuery%')
            .limit(15);

        for (var p in profilesRes) {
          results.add({
            'type': 'user',
            'name': p['full_name'] ?? p['username'] ?? 'مستخدم',
            'username': p['username'] ?? '',
            'role': p['role'] ?? 'طالب',
            'bio': p['bio'] ?? 'عضو مسجل في منصة ودق الأكاديمية 🎓',
          });
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: WadiqColors.cardSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: WadiqColors.surfaceBorder),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "ابحث عن أي حساب @username أو اسم أو قناة...",
              hintStyle: const TextStyle(color: WadiqColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: WadiqColors.primaryAmber, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _performSearch,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: WadiqColors.primaryAmber))
          : _searchController.text.isEmpty
              ? _buildInitialState()
              : _searchResults.isEmpty && _hasSearched
                  ? _buildEmptyResultsState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, index) => const Divider(color: WadiqColors.divider, height: 16),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final isChannel = item['type'] == 'channel';
                        final isGroup = item['type'] == 'group';
                        final name = item['name'] ?? '';
                        final username = item['username'] ?? '';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isChannel
                                ? Colors.blue.withValues(alpha: 0.2)
                                : isGroup
                                    ? Colors.teal.withValues(alpha: 0.2)
                                    : WadiqColors.elevatedSurface,
                            child: Icon(
                              isChannel
                                  ? Icons.campaign_rounded
                                  : isGroup
                                      ? Icons.groups_rounded
                                      : Icons.person_rounded,
                              color: WadiqColors.primaryAmber,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(name, style: WadiqTypography.titleMedium.copyWith(fontSize: 15)),
                              const SizedBox(width: 6),
                              if (isChannel || isGroup)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: WadiqColors.elevatedSurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isChannel ? "قناة" : "مجموعة",
                                    style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            "@$username • ${item['role']}\n${item['bio']}",
                            style: WadiqTypography.caption.copyWith(height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isChannel && !isGroup)
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: WadiqColors.primaryAmber, size: 20),
                                  tooltip: "مراسلة مباشرة",
                                  onPressed: () {
                                    final myUsername = SupabaseConfig.client?.auth.currentUser?.email ?? 'me';
                                    final convId = ChatService.directConvId(myUsername, username);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatRoomScreen(
                                          title: name,
                                          subtitle: "@$username",
                                          avatarChar: name.isNotEmpty ? name[0] : '@',
                                          conversationId: convId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: WadiqColors.textMuted),
                            ],
                          ),
                          onTap: () {
                            if (isChannel || isGroup) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(
                                    title: name,
                                    subtitle: isChannel ? "قناة أكاديمية" : "مجموعة دراسية",
                                    isChannel: isChannel,
                                    avatarChar: name.isNotEmpty ? name[0] : 'ق',
                                    conversationId: item['convId'] ?? 'channel_$username',
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                    name: name,
                                    role: item['role'] ?? 'طالب أكاديمي',
                                    handle: "@$username",
                                    avatarChar: name.isNotEmpty ? name[0] : '@',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text("ابحث عن الحسابات والقنوات المسجلة", style: WadiqTypography.titleMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            "اكتب معرّف الشخص @ أو اسمه للوصول المباشر إلى ملفه أو بدء محادثة مشفرة معه.",
            textAlign: TextAlign.center,
            style: WadiqTypography.caption.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 60, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              "لم يتم العثور على أي حساب مسجل بهذا المعرّف",
              style: WadiqTypography.titleMedium.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "تأكد من كتابة الاسم أو المعرّف الأكاديمي بشكل صحيح، أو ابحث عن القنوات والمجموعات.",
              textAlign: TextAlign.center,
              style: WadiqTypography.caption.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
