import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_service.dart';

class UserSelectionModal extends StatefulWidget {
  final String title;
  final String actionLabel;
  final List<String> initialSelected;

  const UserSelectionModal({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.initialSelected,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required List<String> initialSelected,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => UserSelectionModal(
        title: title,
        actionLabel: actionLabel,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<UserSelectionModal> createState() => _UserSelectionModalState();
}

class _UserSelectionModalState extends State<UserSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = {};
  List<ConversationSummary> _allFriends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final convs = await ChatService.instance.fetchUserConversations();
    if (!mounted) return;
    setState(() {
      _allFriends = convs.where((c) => !c.isChannel).toList();
      _isLoading = false;
    });
  }

  List<ConversationSummary> get _filteredFriends {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _allFriends;
    return _allFriends.where((c) => c.name.toLowerCase().contains(q) || c.username.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: WadiqTypography.titleLarge.copyWith(fontSize: 17)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: WadiqColors.elevatedSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: WadiqColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "ابحث بالاسم أو المعرف...",
                      hintStyle: TextStyle(color: WadiqColors.textMuted, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Friends list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: WadiqColors.primaryAmber))
                : _filteredFriends.isEmpty
                    ? Center(
                        child: Text(
                          "لا يوجد أصدقاء متطابقون في قائمة المحادثات",
                          style: WadiqTypography.caption,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredFriends.length,
                        separatorBuilder: (_, __) => const Divider(color: WadiqColors.surfaceBorder, height: 1),
                        itemBuilder: (context, i) {
                          final friend = _filteredFriends[i];
                          final isChecked = _selected.contains(friend.username) || _selected.contains(friend.name);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: WadiqColors.primaryAmber,
                            checkColor: Colors.black,
                            value: isChecked,
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selected.add(friend.username);
                                } else {
                                  _selected.remove(friend.username);
                                  _selected.remove(friend.name);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              radius: 18,
                              backgroundColor: WadiqColors.elevatedSurface,
                              child: Text(
                                friend.name.isNotEmpty ? friend.name.substring(0, 1) : 'و',
                                style: const TextStyle(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(friend.name, style: WadiqTypography.bodyMedium),
                            subtitle: Text("@${friend.username}", style: WadiqTypography.caption),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WadiqColors.primaryAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, _selected.toList()),
              child: Text(
                "${widget.actionLabel} (${_selected.length})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
