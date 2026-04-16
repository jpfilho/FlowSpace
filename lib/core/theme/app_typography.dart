import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// FlowSpace Typography System — Inter family
abstract class AppTypography {
  static TextTheme get textTheme => TextTheme(
    // Display
    displayLarge: _inter(32, FontWeight.w700, -1.0, AppColors.textPrimary),
    displayMedium: _inter(28, FontWeight.w700, -0.5, AppColors.textPrimary),
    displaySmall: _inter(24, FontWeight.w600, -0.3, AppColors.textPrimary),

    // Headline
    headlineLarge: _inter(22, FontWeight.w600, -0.3, AppColors.textPrimary),
    headlineMedium: _inter(20, FontWeight.w600, -0.2, AppColors.textPrimary),
    headlineSmall: _inter(18, FontWeight.w600, -0.1, AppColors.textPrimary),

    // Title
    titleLarge: _inter(16, FontWeight.w600, 0, AppColors.textPrimary),
    titleMedium: _inter(15, FontWeight.w500, 0, AppColors.textPrimary),
    titleSmall: _inter(14, FontWeight.w500, 0.1, AppColors.textPrimary),

    // Body
    bodyLarge: _inter(15, FontWeight.w400, 0, AppColors.textSecondary),
    bodyMedium: _inter(14, FontWeight.w400, 0, AppColors.textSecondary),
    bodySmall: _inter(13, FontWeight.w400, 0.1, AppColors.textMuted),

    // Label
    labelLarge: _inter(13, FontWeight.w500, 0.1, AppColors.textSecondary),
    labelMedium: _inter(12, FontWeight.w500, 0.2, AppColors.textMuted),
    labelSmall: _inter(11, FontWeight.w500, 0.3, AppColors.textDisabled),
  );

  static TextTheme get darkTextTheme => TextTheme(
    displayLarge: _inter(32, FontWeight.w700, -1.0, AppColors.textPrimaryDark),
    displayMedium: _inter(28, FontWeight.w700, -0.5, AppColors.textPrimaryDark),
    displaySmall: _inter(24, FontWeight.w600, -0.3, AppColors.textPrimaryDark),
    headlineLarge: _inter(22, FontWeight.w600, -0.3, AppColors.textPrimaryDark),
    headlineMedium: _inter(20, FontWeight.w600, -0.2, AppColors.textPrimaryDark),
    headlineSmall: _inter(18, FontWeight.w600, -0.1, AppColors.textPrimaryDark),
    titleLarge: _inter(16, FontWeight.w600, 0, AppColors.textPrimaryDark),
    titleMedium: _inter(15, FontWeight.w500, 0, AppColors.textPrimaryDark),
    titleSmall: _inter(14, FontWeight.w500, 0.1, AppColors.textPrimaryDark),
    bodyLarge: _inter(15, FontWeight.w400, 0, AppColors.textSecondaryDark),
    bodyMedium: _inter(14, FontWeight.w400, 0, AppColors.textSecondaryDark),
    bodySmall: _inter(13, FontWeight.w400, 0.1, AppColors.textMutedDark),
    labelLarge: _inter(13, FontWeight.w500, 0.1, AppColors.textSecondaryDark),
    labelMedium: _inter(12, FontWeight.w500, 0.2, AppColors.textMutedDark),
    labelSmall: _inter(11, FontWeight.w500, 0.3, AppColors.textDisabledDark),
  );

  static TextStyle _inter(
    double size,
    FontWeight weight,
    double letterSpacing,
    Color color,
  ) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color,
    height: 1.5,
  );

  // Convenience shortcuts
  static TextStyle displayLg(Color? color) =>
      _inter(32, FontWeight.w700, -1.0, color ?? AppColors.textPrimary);
  static TextStyle heading(Color? color) =>
      _inter(20, FontWeight.w600, -0.2, color ?? AppColors.textPrimary);
  static TextStyle body(Color? color) =>
      _inter(14, FontWeight.w400, 0, color ?? AppColors.textSecondary);
  static TextStyle label(Color? color) =>
      _inter(12, FontWeight.w500, 0.2, color ?? AppColors.textMuted);
  static TextStyle caption(Color? color) =>
      _inter(11, FontWeight.w400, 0.3, color ?? AppColors.textDisabled);
  static TextStyle mono(double size, Color? color) => TextStyle(
    fontFamily: 'monospace',
    fontSize: size,
    color: color ?? AppColors.textSecondary,
    height: 1.5,
  );
}
