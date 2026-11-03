import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/reels_settings_service.dart';
import '../../../../core/services/reel_service.dart';
import '../widgets/user_selection_modal.dart';

class ReelsAdvancedManagementScreen extends StatefulWidget {
  const ReelsAdvancedManagementScreen({super.key});

  @override
  State<ReelsAdvancedManagementScreen> createState() => _ReelsAdvancedManagementScreenState();
}

class _ReelsAdvancedManagementScreenState extends State<ReelsAdvancedManagementScreen> {
  final _service = ReelsSettingsService.instance;
  List<ReelModel> _myReels = [];

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
    _loadReels();
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadReels() async {
    final reels = await ReelService.instance.fetchReels();
    if (!mounted) return;
    setState(() {
      _myReels = reels;
    });
  }

  void _showPerReelPermissionModal({
    required ReelModel reel,
    required String permType, // 'visibility', 'comments', 'repost'
    required String title,
    required bool allowOnlyMe,
  }) {
    final currentMap = _service.getReelPermissions(reel.id);
    final currentVal = currentMap[permType] ?? AudiencePermission.everyone.name;

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
              Text("المقطع: ${reel.caption}", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber)),
              const SizedBox(height: 14),
              _buildPermRow(ctx, reel.id, permType, 'للجميع', AudiencePermission.everyone, currentVal),
              _buildPermRow(ctx, reel.id, permType, 'الأصدقاء فقط', AudiencePermission.friends, currentVal),
              _buildPermRow(ctx, reel.id, permType, 'أشخاص محددون...', AudiencePermission.specific, currentVal),
              _buildPermRow(ctx, reel.id, permType, 'باستثناء أشخاص...', AudiencePermission.exceptUsers, currentVal),
              if (allowOnlyMe)
                _buildPermRow(ctx, reel.id, permType, 'لك فقط (صاحب الحساب فقط)', AudiencePermission.onlyMe, currentVal),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermRow(
    BuildContext ctx,
    String reelId,
    String permType,
    String label,
    AudiencePermission perm,
    String currentVal,
  ) {
    final isSelected = currentVal == perm.name;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: isSelected ? WadiqColors.primaryAmber : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: WadiqColors.primaryAmber) : null,
      onTap: () async {
        Navigator.pop(ctx);
        if (perm == AudiencePermission.specific || perm == AudiencePermission.exceptUsers) {
          final res = await UserSelectionModal.show(
            context,
            title: perm == AudiencePermission.specific ? "تحديد الأشخاص المسموح لهم" : "استثناء أشخاص محددين",
            actionLabel: "حفظ الاختيار",
            initialSelected: const [],
          );
          if (res != null) {
            await _service.setReelPermission(reelId, permType, perm);
            if (mounted) setState(() {});
          }
        } else {
          await _service.setReelPermission(reelId, permType, perm);
          if (mounted) setState(() {});
        }
      },
    );
  }

  void _showReelsPickerForPermission(String permType, String title, bool allowOnlyMe) {
    if (_myReels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لم تقم بنشر مقاطع ريلز بعد لتحديد أذوناتها")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: WadiqTypography.titleLarge.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text("اختر مقطع الريلز لتعديل إعداداته:", style: WadiqTypography.caption),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _myReels.length,
                  separatorBuilder: (_, __) => const Divider(color: WadiqColors.surfaceBorder, height: 1),
                  itemBuilder: (c, i) {
                    final reel = _myReels[i];
                    final perms = _service.getReelPermissions(reel.id);
                    final currentVal = perms[permType] ?? AudiencePermission.everyone.name;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: WadiqColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: WadiqColors.surfaceBorder),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: WadiqColors.primaryAmber),
                      ),
                      title: Text(reel.caption ?? 'مقطع بدون عنوان', style: WadiqTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text("الحالة الحالية: $currentVal", style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber)),
                      trailing: const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showPerReelPermissionModal(
                          reel: reel,
                          permType: permType,
                          title: title,
                          allowOnlyMe: allowOnlyMe,
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
  }

  void _restoreItem(RecentlyDeletedReelItem item) async {
    await _service.restoreReel(item.id);
    await ReelService.instance.createReel(
      videoUrl: item.videoUrl,
      caption: item.caption,
      soundTitle: item.soundTitle,
    );
    await _loadReels();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تمت استعادة مقطع '${item.caption}' بنجاح إلى قسم الريلز! 🎬"),
          backgroundColor: WadiqColors.success,
        ),
      );
    }
  }

  void _deletePermanently(RecentlyDeletedReelItem item) async {
    await _service.permanentlyDeleteReel(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حذف المقطع نهائياً"), backgroundColor: WadiqColors.alert),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deleted = _service.recentlyDeleted;

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("إدارة الريلز المعمق", style: WadiqTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Recently Deleted
          _buildSectionHeader("1_ تم حذفه مؤخراً (تبقى المقاطع 7 أيام فقط)"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("سلة المحذوفات المؤقتة للريلز", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: WadiqColors.alert.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("${deleted.length} مقاطع", style: const TextStyle(color: WadiqColors.alert, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "أي مقطع ريلز تقوم بحذفه يبقى هنا لمدة 7 أيام مع إمكانية استعادته بالكامل، ويُحذف تلقائياً ونهائياً بعد انقضاء المدة.",
                  style: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted, height: 1.3),
                ),
                const SizedBox(height: 12),
                if (deleted.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: Text("لا توجد مقاطع محذوفة مؤخراً. سلة المحذوفات نظيفة ✓", style: WadiqTypography.caption),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: deleted.length,
                    separatorBuilder: (_, __) => const Divider(color: WadiqColors.surfaceBorder, height: 1),
                    itemBuilder: (context, i) {
                      final item = deleted[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: WadiqColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_sweep_rounded, color: WadiqColors.alert, size: 20),
                        ),
                        title: Text(item.caption, style: WadiqTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("متبقي: ${item.remainingDays} أيام قبل الحذف النهائي", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_rounded, color: WadiqColors.success, size: 22),
                              tooltip: "استعادة المقطع",
                              onPressed: () => _restoreItem(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: WadiqColors.alert, size: 22),
                              tooltip: "حذف نهائي",
                              onPressed: () => _deletePermanently(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Reels Visibility Management
          _buildSectionHeader("2_ إدارة ظهور الريلز (من يشاهد المقطع)"),
          _buildActionCard(
            icon: Icons.visibility_outlined,
            title: "تحديد خصوصية ظهور مقطع محدد",
            subtitle: "خيارات: للجميع، الأصدقاء، أشخاص محددون، باستثناء، لك فقط (خاص)",
            onTap: () => _showReelsPickerForPermission('visibility', 'إدارة ظهور الريلز', true),
          ),
          const SizedBox(height: 20),

          // 3. Comments Permissions
          _buildSectionHeader("3_ إدارة أذونات التعليقات لكل ريلز"),
          _buildActionCard(
            icon: Icons.insert_comment_outlined,
            title: "تحديد أذونات التعليق لمقطع محدد",
            subtitle: "خيارات: للجميع، الأصدقاء، أشخاص محددون، باستثناء",
            onTap: () => _showReelsPickerForPermission('comments', 'إدارة أذونات التعليقات', false),
          ),
          const SizedBox(height: 20),

          // 4. Repost Permissions
          _buildSectionHeader("4_ إدارة أذونات إعادة نشر الريلز"),
          _buildActionCard(
            icon: Icons.repeat_rounded,
            title: "تحديد من يمكنه إعادة نشر الريلز الخاص بك",
            subtitle: "خيارات: للجميع، الأصدقاء، أشخاص محددون، باستثناء",
            onTap: () => _showReelsPickerForPermission('repost', 'إدارة أذونات إعادة النشر', false),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WadiqColors.surfaceBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: WadiqColors.primaryAmber, size: 22),
        ),
        title: Text(title, style: WadiqTypography.bodyLarge),
        subtitle: Text(subtitle, style: WadiqTypography.caption),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
        onTap: onTap,
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
