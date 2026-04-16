import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

/// Colored tag/chip for labels, statuses, priorities
class FlowTag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool small;
  final VoidCallback? onRemove;
  final IconData? icon;

  const FlowTag({
    super.key,
    required this.label,
    this.color,
    this.small = false,
    this.onRemove,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = color ?? AppColors.primary;
    final bg = tagColor.withValues(alpha: 0.12);
    final fg = tagColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSpacing.sp6 : AppSpacing.sp8,
        vertical: small ? AppSpacing.sp2 : AppSpacing.sp4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 10 : 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 12, color: fg),
            ),
          ],
        ],
      ),
    );
  }
}

/// Priority tag with predefined colors
class PriorityTag extends StatelessWidget {
  final String priority; // urgent, high, medium, low

  const PriorityTag({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (priority.toLowerCase()) {
      'urgent' => ('Urgente', AppColors.priorityUrgent, Icons.arrow_upward_rounded),
      'high' => ('Alta', AppColors.priorityHigh, Icons.keyboard_arrow_up_rounded),
      'medium' => ('Média', AppColors.priorityMedium, Icons.remove_rounded),
      _ => ('Baixa', AppColors.priorityLow, Icons.keyboard_arrow_down_rounded),
    };

    return FlowTag(label: label, color: color, icon: icon, small: true);
  }
}

/// Status tag with predefined colors
class StatusTag extends StatelessWidget {
  final String status; // todo, in_progress, review, done, cancelled

  const StatusTag({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.toLowerCase()) {
      'todo' => ('A fazer', AppColors.statusTodo),
      'in_progress' => ('Em progresso', AppColors.statusInProgress),
      'review' => ('Em revisão', AppColors.statusReview),
      'done' => ('Concluído', AppColors.statusDone),
      'cancelled' => ('Cancelado', AppColors.statusCancelled),
      _ => ('Desconhecido', AppColors.textDisabled),
    };

    return FlowTag(label: label, color: color);
  }
}

/// Numeric badge (e.g., notification count)
class FlowBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const FlowBadge({super.key, required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Avatar widget
class FlowAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? color;

  const FlowAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final avatarColor = color ?? _colorFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imageUrl == null ? avatarColor.withValues(alpha: 0.15) : null,
        shape: BoxShape.circle,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: avatarColor,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }

  Color _colorFromName(String name) {
    final colors = AppColors.labelColors;
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
}
