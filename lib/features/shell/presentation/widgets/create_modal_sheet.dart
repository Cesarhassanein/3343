import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';

class CreateModalSheet extends StatelessWidget {
  final VoidCallback onPostTap;
  final VoidCallback onReelTap;
  final VoidCallback onChannelTap;
  final VoidCallback onGroupTap;

  const CreateModalSheet({
    super.key,
    required this.onPostTap,
    required this.onReelTap,
    required this.onChannelTap,
    required this.onGroupTap,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onPostTap,
    required VoidCallback onReelTap,
    required VoidCallback onChannelTap,
    required VoidCallback onGroupTap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CreateModalSheet(
        onPostTap: onPostTap,
        onReelTap: onReelTap,
        onChannelTap: onChannelTap,
        onGroupTap: onGroupTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WadiqColors.darkCharcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: WadiqColors.surfaceBorder, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: WadiqColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "نشر وإنشاء محتوى جديد",
                style: WadiqTypography.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: WadiqColors.textSecondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            context: context,
            icon: Icons.video_collection_outlined,
            title: "نشر ريلز فيديو جديد",
            subtitle: "فيديو عمودي سريع مع استوديو القص والمؤثرات",
            onTap: () {
              Navigator.pop(context);
              onReelTap();
            },
          ),
          _buildActionItem(
            context: context,
            icon: Icons.edit_note_rounded,
            title: "كتابة منشور في ودق",
            subtitle: "نص، صور، تصويت، ومتابعة لمدة 10 أيام",
            onTap: () {
              Navigator.pop(context);
              onPostTap();
            },
          ),
          _buildActionItem(
            context: context,
            icon: Icons.campaign_outlined,
            title: "إنشاء قناة جديدة",
            subtitle: "بث المحتوى للطلاب والمتابعين باتجاه واحد",
            onTap: () {
              Navigator.pop(context);
              onChannelTap();
            },
          ),
          _buildActionItem(
            context: context,
            icon: Icons.groups_outlined,
            title: "إنشاء مجموعة دراسية / نقاش",
            subtitle: "محادثات تفاعلية ومجموعات عمل مشتركة",
            onTap: () {
              Navigator.pop(context);
              onGroupTap();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: WadiqColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: WadiqColors.amberGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WadiqTypography.titleMedium.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: WadiqTypography.caption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: WadiqColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
