import 'package:flutter/material.dart';
import 'wadiq_colors.dart';
import 'wadiq_typography.dart';

class WadiqTheme {
  WadiqTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WadiqColors.obsidianBlack,
      primaryColor: WadiqColors.primaryAmber,
      colorScheme: const ColorScheme.dark(
        primary: WadiqColors.primaryAmber,
        secondary: WadiqColors.amberLight,
        surface: WadiqColors.cardSurface,
        error: WadiqColors.alert,
        onPrimary: Colors.white,
        onSurface: WadiqColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: WadiqColors.obsidianBlack.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: WadiqTypography.titleLarge,
        iconTheme: const IconThemeData(color: WadiqColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: WadiqColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: WadiqColors.surfaceBorder, width: 1),
        ),
      ),
      dividerColor: WadiqColors.divider,
      dividerTheme: const DividerThemeData(
        color: WadiqColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
