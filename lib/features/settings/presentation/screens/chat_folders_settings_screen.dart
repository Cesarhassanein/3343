import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_settings_service.dart';
import 'create_chat_folder_screen.dart';

class ChatFoldersSettingsScreen extends StatefulWidget {
  const ChatFoldersSettingsScreen({super.key});

  @override
  State<ChatFoldersSettingsScreen> createState() => _ChatFoldersSettingsScreenState();
}

class _ChatFoldersSettingsScreenState extends State<ChatFoldersSettingsScreen> {
  final _service = ChatSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _openCreateFolderScreen({ChatFolderModel? folder}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateChatFolderScreen(existingFolder: folder),
      ),
    );
  }

  void _confirmDelete(ChatFolderModel folder) {
    if (folder.id == 'all') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("لا يمكن حذف مجلد 'الكل' الافتراضي."),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("حذف المجلد", style: WadiqTypography.titleLarge),
        content: Text("هل أنت متأكد من حذف مجلد '${folder.name}'؟ لن يتم حذف أي محادثات داخلية.", style: WadiqTypography.bodyMedium),
        actions: [
          TextButton(
            child: const Text("إلغاء", style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WadiqColors.alert,
              foregroundColor: Colors.white,
            ),
            child: const Text("حذف"),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteFolder(folder.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folders = _service.folders;

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("مجلدات المحادثات", style: WadiqTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informational Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.folder_special_rounded, color: WadiqColors.primaryAmber, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("تنظيم المحادثات في تبويبات", style: WadiqTypography.titleMedium.copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        "تتيح لك المجلدات تجميع القنوات أو المجموعات أو الأشخاص في تبويبات مستقلة بأعلى شاشة المراسلات.",
                        style: WadiqTypography.caption.copyWith(height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action: Create New Folder Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: WadiqColors.primaryAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.create_new_folder_outlined, size: 22),
              label: const Text(
                "إنشاء مجلد جديد +",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () => _openCreateFolderScreen(),
            ),
          ),
          const SizedBox(height: 24),

          // Folders List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "المجلدات النشطة (اسحب الأيقونة لتغيير الترتيب):",
                style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
              ),
              Text("${folders.length} مجلدات", style: WadiqTypography.caption),
            ],
          ),
          const SizedBox(height: 10),

          // Reorderable Folders List
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: folders.length,
              onReorder: (oldIndex, newIndex) => _service.reorderFolders(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final folder = folders[index];
                final isDefault = folder.id == 'all';

                return Container(
                  key: ValueKey(folder.id),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: WadiqColors.surfaceBorder, width: 0.8)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_indicator_rounded, color: Colors.white38),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: WadiqColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isDefault ? Icons.all_inbox_rounded : Icons.folder_rounded,
                            color: WadiqColors.primaryAmber,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    title: Text(folder.name, style: WadiqTypography.bodyLarge),
                    subtitle: Text(
                      isDefault
                          ? "يحتوي جميع المحادثات تلقائياً"
                          : "${folder.includedChatIds.length} محادثة مخصصة",
                      style: WadiqTypography.caption,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDefault) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                            tooltip: "تعديل",
                            onPressed: () => _openCreateFolderScreen(folder: folder),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: WadiqColors.alert, size: 20),
                            tooltip: "حذف",
                            onPressed: () => _confirmDelete(folder),
                          ),
                        ],
                      ],
                    ),
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
