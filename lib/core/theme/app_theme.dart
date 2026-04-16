import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// FlowSpace Theme — Light and Dark ThemeData
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primary,
            primaryContainer: AppColors.primaryContainerDark,
            secondary: AppColors.accent,
            surface: AppColors.surfaceDark,
            onSurface: AppColors.textPrimaryDark,
            onPrimary: Colors.white,
            error: AppColors.error,
            outline: AppColors.borderDark,
            outlineVariant: AppColors.borderStrongDark,
            surfaceContainerHighest: AppColors.surfaceVariantDark,
            surfaceContainerHigh: AppColors.surfaceVariantDark,
            surfaceContainer: AppColors.surfaceDark,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            primaryContainer: AppColors.primaryContainer,
            secondary: AppColors.accent,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            onPrimary: Colors.white,
            error: AppColors.error,
            outline: AppColors.border,
            outlineVariant: AppColors.borderStrong,
            surfaceContainerHighest: AppColors.surfaceVariant,
            surfaceContainerHigh: AppColors.surfaceVariant,
            surfaceContainer: AppColors.background,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: isDark ? AppTypography.darkTextTheme : AppTypography.textTheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: isDark
            ? AppTypography.darkTextTheme.titleLarge
            : AppTypography.textTheme.titleLarge,
        toolbarHeight: AppSpacing.topbarHeight,
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp12,
          vertical: AppSpacing.sp10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTypography.body(
          isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
        labelStyle: AppTypography.label(
          isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.label(Colors.white)
              .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12,
            vertical: AppSpacing.sp8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        labelStyle: AppTypography.label(
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp8,
          vertical: AppSpacing.sp2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide.none,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.border,
        thickness: 1,
        space: 0,
      ),

      // Popup Menu
      popupMenuTheme: PopupMenuThemeData(
        elevation: AppElevation.dropdown,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        textStyle: AppTypography.body(
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: AppElevation.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTypography.caption(
          isDark ? AppColors.textPrimaryDark : Colors.white,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceVariantDark : AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentTextStyle: AppTypography.body(Colors.white),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? AppColors.textMutedDark : AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return isDark ? AppColors.borderDark : AppColors.border;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(
          color: isDark ? AppColors.borderStrongDark : AppColors.borderStrong,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryContainer,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: AppTypography.textTheme.bodyMedium,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textMutedDark : AppColors.textMuted,
        indicatorColor: AppColors.primary,
        dividerColor: isDark ? AppColors.borderDark : AppColors.border,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
      ),
    );
  }
}
