import 'package:flutter/material.dart';
import '../theme/wadiq_colors.dart';
import '../theme/wadiq_typography.dart';

enum WadiqButtonType { primary, secondary, outline }

class WadiqButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final WadiqButtonType type;
  final IconData? icon;
  final double? width;
  final double height;
  final bool isLoading;

  const WadiqButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = WadiqButtonType.primary,
    this.icon,
    this.width,
    this.height = 46,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Decoration decoration;
    Color textColor = Colors.white;

    switch (type) {
      case WadiqButtonType.primary:
        decoration = BoxDecoration(
          gradient: WadiqColors.amberGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: WadiqColors.amberGlow,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        );
        break;
      case WadiqButtonType.secondary:
        decoration = BoxDecoration(
          color: WadiqColors.elevatedSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WadiqColors.surfaceBorder),
        );
        textColor = WadiqColors.textPrimary;
        break;
      case WadiqButtonType.outline:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WadiqColors.primaryAmber, width: 1.5),
        );
        textColor = WadiqColors.primaryAmber;
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: textColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: WadiqTypography.button.copyWith(color: textColor),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
