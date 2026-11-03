import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/reels_settings_service.dart';
import '../widgets/user_selection_modal.dart';

class ReelsInteractionsSettingsScreen extends StatefulWidget {
  const ReelsInteractionsSettingsScreen({super.key});

  @override
  State<ReelsInteractionsSettingsScreen> createState() => _ReelsInteractionsSettingsScreenState();
}

class _ReelsInteractionsSettingsScreenState extends State<ReelsInteractionsSettingsScreen> {
  final _service = ReelsSettingsService.instance;
  final TextEditingController _commentKeywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    _commentKeywordController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showPermissionModal({
    required String title,
    required AudiencePermission current,
    required bool includeNobody,
    required Function(AudiencePermission perm, List<String>? specific, List<String>? except) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: WadiqTypography.titleLarge.copyWith(fontSize: 16)),
              const SizedBox(height: 14),
              _buildPermTile(ctx, 'للجميع', AudiencePermission.everyone, current, onSave),
              _buildPermTile(ctx, 'الأصدقاء فقط', AudiencePermission.friends, current, onSave),
              _buildPermTile(ctx, 'أشخاص محددون...', AudiencePermission.specific, current, onSave),
              _buildPermTile(ctx, 'باستثناء أشخاص...', AudiencePermission.exceptUsers, current, onSave),
              if (includeNobody)
                _buildPermTile(ctx, 'لا أحد', AudiencePermission.nobody, current, onSave),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermTile(
    BuildContext ctx,
    String label,
    AudiencePermission perm,
    AudiencePermission current,
    Function(AudiencePermission perm, List<String>? specific, List<String>? except) onSave,
  ) {
    final isSelected = current == perm;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: isSelected ? WadiqColors.primaryAmber : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: WadiqColors.primaryAmber) : null,
      onTap: () async {
        Navigator.pop(ctx);
        if (perm == AudiencePermission.specific) {
          final res = await UserSelectionModal.show(
            context,
            title: "تحديد الأشخاص المسموح لهم",
            actionLabel: "حفظ الأشخاص المحددين",
            initialSelected: _service.commentsSpecificUsers,
          );
          if (res != null) {
            onSave(perm, res, null);
          }
        } else if (perm == AudiencePermission.exceptUsers) {
          final res = await UserSelectionModal.show(
            context,
            title: "استثناء أشخاص محددين",
            actionLabel: "حفظ المستثنين",
            initialSelected: _service.commentsExceptUsers,
          );
          if (res != null) {
            onSave(perm, null, res);
          }
        } else {
          onSave(perm, null, null);
        }
      },
    );
  }

  void _addCommentKeyword() {
    final w = _commentKeywordController.text.trim();
    if (w.isNotEmpty) {
      _service.addCommentKeyword(w);
      _commentKeywordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("إعدادات التفاعلات للريلز", style: WadiqTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Comments
          _buildSectionHeader("1_ التعليقات"),
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded, color: WadiqColors.primaryAmber),
                  title: Text("السماح بالتعليقات من:", style: WadiqTypography.bodyLarge),
                  subtitle: Text(_service.commentsAllowedFrom.title, style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                  onTap: () {
                    _showPermissionModal(
                      title: "من يمكنه التعليق على مقاطع الريلز الخاصة بك؟",
                      current: _service.commentsAllowedFrom,
                      includeNobody: false,
                      onSave: (p, s, e) => _service.setCommentsPermission(p, specific: s, except: e),
                    );
                  },
                ),
                const Divider(color: WadiqColors.surfaceBorder, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("تصفية كلمات رئيسية محددة في التعليقات:", style: WadiqTypography.bodyMedium),
                      const SizedBox(height: 6),
                      Text("التعليقات التي تحتوي هذه الكلمات سيتم حجبها تلقائياً.", style: WadiqTypography.caption),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: WadiqColors.elevatedSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _commentKeywordController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: "أضف كلمة محظورة (مثال: سبام)...",
                                  hintStyle: TextStyle(color: WadiqColors.textMuted, fontSize: 12),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addCommentKeyword(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WadiqColors.primaryAmber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _addCommentKeyword,
                            child: const Text("إضافة", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _service.commentFilterKeywords.map((word) {
                          return Chip(
                            backgroundColor: WadiqColors.elevatedSurface,
                            label: Text(word, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14, color: WadiqColors.alert),
                            onDeleted: () => _service.removeCommentKeyword(word),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: WadiqColors.surfaceBorder)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Mentions & Tags
          _buildSectionHeader("2_ الذكر (التاك @)"),
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.alternate_email_rounded, color: WadiqColors.primaryAmber),
              title: Text("السماح بالذكر والإشارة (@) من:", style: WadiqTypography.bodyLarge),
              subtitle: Text(_service.mentionsAllowedFrom.title, style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                _showPermissionModal(
                  title: "من يمكنه الإشارة إليك (@) في مقاطع الريلز؟",
                  current: _service.mentionsAllowedFrom,
                  includeNobody: true,
                  onSave: (p, s, e) => _service.setMentionsPermission(p, specific: s, except: e),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. Followers List Visibility
          _buildSectionHeader("3_ قائمة المتابعين"),
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined, color: WadiqColors.primaryAmber),
              title: Text("من يمكنه رؤية قائمة متابعيك:", style: WadiqTypography.bodyLarge),
              subtitle: Text(_service.followersVisibility.title, style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                _showPermissionModal(
                  title: "تحديد خصوصية قائمة المتابعين",
                  current: _service.followersVisibility,
                  includeNobody: false,
                  onSave: (p, s, e) => _service.setFollowersVisibility(p, specific: s, except: e),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 4. Liked Videos Visibility
          _buildSectionHeader("4_ فيديوهات أعجبتك"),
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.favorite_border_rounded, color: WadiqColors.primaryAmber),
              title: Text("من يمكنه رؤية الفيديوهات التي أعجبتك:", style: WadiqTypography.bodyLarge),
              subtitle: Text(_service.likedVideosVisibility.title, style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                _showPermissionModal(
                  title: "خصوصية قائمة الفيديوهات المعجب بها",
                  current: _service.likedVideosVisibility,
                  includeNobody: false,
                  onSave: (p, s, e) => _service.setLikedVideosVisibility(p, specific: s, except: e),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: WadiqTypography.caption.copyWith(
          color: WadiqColors.primaryAmber,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
