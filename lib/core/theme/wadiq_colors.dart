import 'package:flutter/material.dart';

class WadiqColors {
  WadiqColors._();

  // Background & Surfaces (Obsidian Dark)
  static const Color obsidianBlack = Color(0xFF0D0D0D);
  static const Color darkCharcoal = Color(0xFF161616);
  static const Color cardSurface = Color(0xFF1A1A1C);
  static const Color elevatedSurface = Color(0xFF242426);
  static const Color surfaceBorder = Color(0xFF2A2A2D);

  // Primary Accent (Amber Glow)
  static const Color primaryAmber = Color(0xFFFF6B35);
  static const Color amberLight = Color(0xFFFF8555);
  static const Color amberDark = Color(0xFFE55722);
  static const Color amberGlow = Color(0x66FF6B35);

  // Gradients
  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF7A00),
      Color(0xFFFF521B),
    ],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0x1AFF6B35),
      Color(0x000D0D0D),
    ],
  );

  static const LinearGradient videoOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x99000000),
      Color(0xDE000000),
    ],
  );

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A5);
  static const Color textMuted = Color(0xFF6E6E75);

  // Interactive & Status
  static const Color success = Color(0xFF10B981);
  static const Color alert = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color divider = Color(0xFF242427);
}
