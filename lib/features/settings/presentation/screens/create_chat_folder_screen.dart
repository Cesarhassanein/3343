import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/chat_settings_service.dart';

class CreateChatFolderScreen extends StatefulWidget {
  final ChatFolderModel? existingFolder;

  const CreateChatFolderScreen({super.key, this.existingFolder});

  @override
  State<CreateChatFolderScreen> createState() => _CreateChatFolderScreenState();
}

class _CreateChatFolderScreenState extends State<CreateChatFolderScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<ConversationSummary> _allChats = [];
  final Set<String> _selectedChatIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingFolder != null) {
      _nameController.text = widget.existingFolder!.name;
      _selectedChatIds.addAll(widget.existingFolder!.includedChatIds);
    }
    _loadChats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final chats = await ChatService.instance.fetchUserConversations();
    if (!mounted) return;
    setState(() {
      _allChats = chats;
      _isLoading = false;
    });
  }

  void _saveFolder() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إدخال اسم للمجلد أولاً (مثل: أصدقاء، دراسة، مشاريع)"),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    if (widget.existingFolder != null) {
      await ChatSettingsService.instance.updateFolder(
        id: widget.existingFolder!.id,
        name: name,
        includedChatIds: _selectedChatIds.toList(),
      );
    } else {
      await ChatSettingsService.instance.addFolder(
        name: name,
        includedChatIds: _selectedChatIds.toList(),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم حفظ مجلد '$name' بنجاح! يظهر الآن في تبويبات المراسلات 📁"),
        backgroundColor: WadiqColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text(
          widget.existingFolder != null ? "تعديل المجلد" : "إنشاء مجلد جديد",
          style: WadiqTypography.titleLarge,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WadiqColors.primaryAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saveFolder,
              child: const Text("حفظ المجلد", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Folder Name Input
          Text("1. اسم المجلد:", style: WadiqTypography.titleMedium.copyWith(color: WadiqColors.primaryAmber)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                icon: const Icon(Icons.folder_outlined, color: WadiqColors.primaryAmber),
                hintText: "مثال: مراجع دراسية، زملاء القسم، مشاريع التخرج...",
                hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Select Chats Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("2. إضافة محادثات إلى المجلد:", style: WadiqTypography.titleMedium.copyWith(color: WadiqColors.primaryAmber)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_selectedChatIds.length} محادثة محددة",
                  style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "حدد المحادثات والقنوات والمجموعات التي ترغب بظهورها عند اختيار هذا المجلد:",
            style: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: WadiqColors.primaryAmber),
            ))
          else if (_allChats.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: Center(
                child: Text(
                  "لا توجد محادثات نشطة بعد. يمكنك حفظ المجلد وإضافة محادثات لاحقاً.",
                  style: WadiqTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allChats.length,
                separatorBuilder: (_, __) => const Divider(color: WadiqColors.surfaceBorder, height: 1),
                itemBuilder: (context, index) {
                  final chat = _allChats[index];
                  final isSelected = _selectedChatIds.contains(chat.id) || _selectedChatIds.contains(chat.username);

                  return CheckboxListTile(
                    activeColor: WadiqColors.primaryAmber,
                    checkColor: Colors.black,
                    value: isSelected,
                    onChanged: (bool? val) {
                      setState(() {
                        if (val == true) {
                          _selectedChatIds.add(chat.id);
                        } else {
                          _selectedChatIds.remove(chat.id);
                          _selectedChatIds.remove(chat.username);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      radius: 20,
                      backgroundColor: WadiqColors.elevatedSurface,
                      child: Text(
                        chat.name.isNotEmpty ? chat.name.substring(0, 1) : 'و',
                        style: const TextStyle(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      chat.name,
                      style: WadiqTypography.bodyLarge.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      chat.isChannel
                          ? "قناة تعليمية"
                          : chat.isGroup
                              ? "مجموعة"
                              : "@${chat.username}",
                      style: WadiqTypography.caption,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
