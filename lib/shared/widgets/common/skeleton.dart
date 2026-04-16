import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

/// Animated shimmer skeleton for loading states.
/// Usage:
///   SkeletonBox(width: 120, height: 14)
///   SkeletonList(itemCount: 5, itemHeight: 64)
///   SkeletonCard()
///   SkeletonTaskTile()

// ── Base shimmer animation ─────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
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
    final base = isDark ? AppColors.surfaceVariantDark : const Color(0xFFE8E8EE);
    final highlight = isDark ? AppColors.surfaceDark : Colors.white;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, highlight, base],
          stops: const [0.0, 0.5, 1.0],
          transform: _SlideTransform(_anim.value),
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: widget.child,
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  final double slide;
  const _SlideTransform(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slide, 0, 0);
  }
}

// ── Public skeleton widgets ────────────────────────────────────

/// A simple rectangular skeleton block
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.isDark
        ? AppColors.surfaceVariantDark
        : const Color(0xFFE8E8EE);

    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A skeleton avatar/circle
class SkeletonAvatar extends StatelessWidget {
  final double size;
  const SkeletonAvatar({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, radius: size / 2);
  }
}

/// A full skeleton replicating a task list tile
class SkeletonTaskTile extends StatelessWidget {
  const SkeletonTaskTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16, vertical: AppSpacing.sp10),
      child: Row(children: [
        const SkeletonBox(width: 20, height: 20, radius: 4),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(height: 13),
              const SizedBox(height: 6),
              Row(children: const [
                SkeletonBox(width: 60, height: 10),
                SizedBox(width: 8),
                SkeletonBox(width: 48, height: 10),
              ]),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sp12),
        const SkeletonBox(width: 56, height: 20, radius: 10),
      ]),
    );
  }
}

/// A skeleton for a stat card
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              SkeletonBox(width: 32, height: 32, radius: 8),
              Spacer(),
              SkeletonBox(width: 24, height: 10),
            ]),
            const SizedBox(height: AppSpacing.sp12),
            const SkeletonBox(width: 48, height: 28),
            const SizedBox(height: 6),
            const SkeletonBox(width: 80, height: 10),
          ],
        ),
      ),
    );
  }
}

/// A skeleton for a project card
class SkeletonProjectCard extends StatelessWidget {
  const SkeletonProjectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SkeletonBox(width: 36, height: 36, radius: 8),
            const SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 14)),
            SkeletonBox(width: 48, height: 20, radius: 10),
          ]),
          const SizedBox(height: AppSpacing.sp16),
          SkeletonBox(height: 10),
          const SizedBox(height: 6),
          SkeletonBox(width: 160, height: 10),
          const SizedBox(height: AppSpacing.sp16),
          SkeletonBox(height: 6, radius: 3), // progress bar
          const SizedBox(height: AppSpacing.sp12),
          Row(children: [
            SkeletonBox(width: 80, height: 10),
            const Spacer(),
            SkeletonBox(width: 48, height: 10),
          ]),
        ],
      ),
    );
  }
}

/// A skeleton for a page/document card
class SkeletonPageCard extends StatelessWidget {
  const SkeletonPageCard({super.key});

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
      child: Row(children: [
        SkeletonBox(width: 36, height: 36, radius: 8),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 14),
              const SizedBox(height: 6),
              SkeletonBox(width: 100, height: 10),
            ],
          ),
        ),
        SkeletonBox(width: 24, height: 24, radius: 12),
      ]),
    );
  }
}

/// Generic skeleton list — repeated tile skeletons
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(int i)? itemBuilder;

  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: context.isDark ? AppColors.borderDark : AppColors.border,
      ),
      itemBuilder: (_, i) =>
          itemBuilder?.call(i) ?? const SkeletonTaskTile(),
    );
  }
}
