import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

enum FlowButtonVariant { primary, outline, ghost, danger }
enum FlowButtonSize { sm, md, lg }

class FlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FlowButtonVariant variant;
  final FlowButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const FlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FlowButtonVariant.primary,
    this.size = FlowButtonSize.md,
    this.isLoading = false,
    this.fullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // Size config
    final (hPad, vPad, fontSize, iconSize) = switch (size) {
      FlowButtonSize.sm => (12.0, 6.0, 12.0, 14.0),
      FlowButtonSize.md => (16.0, 9.0, 14.0, 16.0),
      FlowButtonSize.lg => (20.0, 12.0, 15.0, 18.0),
    };

    // Style config
    final (bgColor, fgColor, borderColor) = switch (variant) {
      FlowButtonVariant.primary => (
          AppColors.primary,
          Colors.white,
          AppColors.primary,
        ),
      FlowButtonVariant.outline => (
          Colors.transparent,
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          isDark ? AppColors.borderDark : AppColors.border,
        ),
      FlowButtonVariant.ghost => (
          Colors.transparent,
          isDark ? AppColors.textPrimaryDark : AppColors.textSecondary,
          Colors.transparent,
        ),
      FlowButtonVariant.danger => (
          AppColors.error,
          Colors.white,
          AppColors.error,
        ),
    };

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fgColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: iconSize, color: fgColor),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fgColor,
            letterSpacing: 0,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 6),
          Icon(trailingIcon, size: iconSize, color: fgColor),
        ],
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: BorderSide(color: borderColor),
    );

    if (fullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return AnimatedOpacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      duration: AppAnimations.fast,
      child: Material(
        color: bgColor,
        shape: shape,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          customBorder: shape,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Icon-only circular button
class FlowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool active;

  const FlowIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size = 36,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = active ? AppColors.primary : (color ?? context.cTextMuted);
    final bgColor = active
        ? (context.isDark
            ? AppColors.primaryContainerDark
            : AppColors.primaryContainer)
        : Colors.transparent;

    Widget btn = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 18, color: effectiveColor),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
