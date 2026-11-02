import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/moderation_service.dart';

class ModerationReportDialog extends StatefulWidget {
  final String targetType;
  final String targetTitle;
  final String targetId;

  const ModerationReportDialog({
    super.key,
    required this.targetType,
    required this.targetTitle,
    required this.targetId,
  });

  static void show(
    BuildContext context, {
    required String targetType,
    required String targetTitle,
    required String targetId,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ModerationReportDialog(
        targetType: targetType,
        targetTitle: targetTitle,
        targetId: targetId,
      ),
    );
  }

  @override
  State<ModerationReportDialog> createState() => _ModerationReportDialogState();
}

class _ModerationReportDialogState extends State<ModerationReportDialog> {
  String _selectedReason = "محتوى مسيء أو مضلل";
  String _assignedTeam = "Team Ashura";
  bool _isSubmitting = false;

  final List<String> _reasons = [
    "محتوى مسيء أو مضلل",
    "رسائل غير مرغوب فيها أو احتيال (Spam)",
    "انتهاك خصوصية أو مضايقة",
    "انتحال صفة أو حساب زائف",
    "محتوى خارج النطاق التعليمي",
  ];

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ModerationService.instance.submitReport(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selectedReason,
        assignedTeam: _assignedTeam,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ البلاغ بنجاح وإرساله إلى قائمة المراجعة ($_assignedTeam).',
          ),
          backgroundColor: WadiqColors.primaryAmber,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال البلاغ: $error'),
          backgroundColor: WadiqColors.alert,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WadiqColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: WadiqColors.surfaceBorder),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: WadiqColors.alert.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined, color: WadiqColors.alert, size: 20),
          ),
          const SizedBox(width: 10),
          Text("إبلاغ عن محتوى", style: WadiqTypography.titleLarge),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "أنت تبلغ عن: ${widget.targetTitle}",
              style: WadiqTypography.caption.copyWith(color: WadiqColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text("سبب الإبلاغ:", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                    // Auto assign teams based on severity
                    if (reason.contains("احتيال") || reason.contains("مضايقة")) {
                      _assignedTeam = "Meezan Ali";
                    } else if (reason.contains("انتحال")) {
                      _assignedTeam = "Team Abu Fadhel";
                    } else {
                      _assignedTeam = "Team Ashura";
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: WadiqTypography.bodyMedium.copyWith(
                            color: isSelected ? Colors.white : WadiqColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WadiqColors.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 16, color: WadiqColors.primaryAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "سيتم فحص البلاغ ومراجعته بواسطة: $_assignedTeam",
                      style: WadiqTypography.caption.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("إلغاء", style: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted)),
        ),
        WadiqButton(
          text: "إرسال البلاغ",
          height: 38,
          isLoading: _isSubmitting,
          onPressed: _submitReport,
        ),
      ],
    );
  }
}
