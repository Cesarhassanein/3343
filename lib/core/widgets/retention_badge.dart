import 'package:flutter/material.dart';
import '../theme/wadiq_colors.dart';
import '../theme/wadiq_typography.dart';

class RetentionBadge extends StatelessWidget {
  final int daysLeft;
  final VoidCallback? onRenewTap;

  const RetentionBadge({
    super.key,
    required this.daysLeft,
    this.onRenewTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isExpiringSoon = daysLeft <= 2;
    final Color badgeColor = isExpiringSoon ? WadiqColors.alert : WadiqColors.primaryAmber;

    return InkWell(
      onTap: onRenewTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 13,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              "متبقي $daysLeft أيام",
              style: WadiqTypography.badge.copyWith(
                color: badgeColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
