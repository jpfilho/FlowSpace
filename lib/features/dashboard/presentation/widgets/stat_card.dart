import 'package:flutter/material.dart';
import '../../../../core/theme/index.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final color = widget.color;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppSpacing.sp20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hovering && widget.onTap != null
                  ? color.withValues(alpha: 0.5)
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: _hovering && widget.onTap != null ? 1.5 : 1,
            ),
            boxShadow: _hovering && widget.onTap != null
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: _hovering && widget.onTap != null ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(widget.icon, size: 18, color: color),
                  ),
                  const Spacer(),
                  if (widget.trend != null)
                    _TrendBadge(
                      label: widget.trend!,
                      up: widget.trendUp,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp16),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                widget.label,
                style: AppTypography.body(context.cTextMuted)
                    .copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String label;
  final bool? up;

  const _TrendBadge({required this.label, this.up});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (up) {
      true => (AppColors.success, Icons.trending_up_rounded),
      false => (AppColors.error, Icons.trending_down_rounded),
      _ => (AppColors.textMuted, Icons.trending_flat_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp6,
        vertical: AppSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
