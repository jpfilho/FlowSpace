import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';
export 'app_theme.dart';

/// Convenience extension on BuildContext for easy theme access
extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cPrimary => AppColors.primary;
  Color get cSurface =>
      isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get cBackground =>
      isDark ? AppColors.backgroundDark : AppColors.background;
  Color get cBorder =>
      isDark ? AppColors.borderDark : AppColors.border;
  Color get cTextPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get cTextMuted =>
      isDark ? AppColors.textMutedDark : AppColors.textMuted;
  Color get cSurfaceVariant =>
      isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

  TextStyle get bodyMd => AppTypography.body(cTextPrimary);
  TextStyle get bodySm => AppTypography.body(cTextMuted).copyWith(fontSize: 13);
  TextStyle get labelMd => AppTypography.label(cTextMuted);
  TextStyle get headingMd =>
      AppTypography.heading(cTextPrimary).copyWith(fontSize: 16);
}

/// Responsive layout helper
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= AppSpacing.mobileBreakpoint &&
        w < AppSpacing.tabletBreakpoint;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppSpacing.tabletBreakpoint;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
