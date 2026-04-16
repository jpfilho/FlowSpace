import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

/// Skeleton loader for content placeholders
class FlowSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const FlowSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 6,
  });

  const FlowSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = 4,
  });

  const FlowSkeleton.circle({
    super.key,
    double size = 40,
  })  : width = size,
        height = size,
        radius = 9999;

  @override
  State<FlowSkeleton> createState() => _FlowSkeletonState();
}

class _FlowSkeletonState extends State<FlowSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.borderDark : AppColors.border)
              .withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Card skeleton
class FlowCardSkeleton extends StatelessWidget {
  const FlowCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlowSkeleton.circle(size: 32),
              const SizedBox(width: AppSpacing.sp12),
              const Expanded(
                child: FlowSkeleton(height: 14, width: 120),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp12),
          const FlowSkeleton(height: 12),
          const SizedBox(height: AppSpacing.sp8),
          const FlowSkeleton(height: 12, width: 200),
        ],
      ),
    );
  }
}

/// Empty state widget
class FlowEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FlowEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                icon,
                size: 32,
                color: context.cTextMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sp16),
            Text(
              title,
              style: AppTypography.heading(context.cTextPrimary)
                  .copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sp8),
              Text(
                subtitle!,
                style: AppTypography.body(context.cTextMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.sp24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget
class FlowErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const FlowErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.sp16),
            Text(
              'Algo deu errado',
              style: AppTypography.heading(context.cTextPrimary)
                  .copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.sp8),
            Text(
              message,
              style: AppTypography.body(context.cTextMuted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sp20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
