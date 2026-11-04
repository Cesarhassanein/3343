import 'package:flutter/material.dart';
import '../theme/wadiq_colors.dart';
import '../services/wadiq_api_service.dart';

class WadiqAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String fallbackInitial;
  final double radius;
  final double? fontSize;
  final Border? border;

  const WadiqAvatar({
    super.key,
    required this.avatarUrl,
    required this.fallbackInitial,
    this.radius = 20,
    this.fontSize,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = avatarUrl?.trim();
    final hasValidUrl = cleanUrl != null && cleanUrl.isNotEmpty && cleanUrl.toLowerCase() != 'null';
    final initial = fallbackInitial.trim().isNotEmpty ? fallbackInitial.trim().substring(0, 1).toUpperCase() : 'و';
    final effectiveFontSize = fontSize ?? (radius * 0.9);

    if (hasValidUrl) {
      final fullUrl = WadiqApiService.instance.getMediaUrl(cleanUrl);
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
        ),
        child: ClipOval(
          child: Image.network(
            fullUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => _buildFallback(initial, effectiveFontSize),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: WadiqColors.elevatedSurface,
                child: const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(WadiqColors.primaryAmber),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return _buildFallback(initial, effectiveFontSize);
  }

  Widget _buildFallback(String initial, double effectiveFontSize) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: WadiqColors.amberGradient,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
