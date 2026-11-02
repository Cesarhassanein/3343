import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wadiq_colors.dart';

class WadiqTypography {
  WadiqTypography._();

  static TextStyle displayLarge = GoogleFonts.readexPro(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: WadiqColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.readexPro(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: WadiqColors.textPrimary,
  );

  static TextStyle titleLarge = GoogleFonts.readexPro(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: WadiqColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.readexPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: WadiqColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.readexPro(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: WadiqColors.textPrimary,
    height: 1.6,
  );

  static TextStyle bodyMedium = GoogleFonts.readexPro(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: WadiqColors.textSecondary,
    height: 1.5,
  );

  static TextStyle caption = GoogleFonts.readexPro(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: WadiqColors.textMuted,
  );

  static TextStyle badge = GoogleFonts.readexPro(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: WadiqColors.primaryAmber,
  );

  static TextStyle button = GoogleFonts.readexPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
