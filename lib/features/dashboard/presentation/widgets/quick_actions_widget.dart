import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/index.dart';
import '../../../../core/routing/app_routes.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_task_rounded,
        label: 'Nova tarefa',
        color: AppColors.primary,
        onTap: () => context.go(AppRoutes.tasks),
      ),
      _QuickAction(
        icon: Icons.create_new_folder_outlined,
        label: 'Novo projeto',
        color: AppColors.accent,
        onTap: () => context.go(AppRoutes.projects),
      ),
      _QuickAction(
        icon: Icons.note_add_outlined,
        label: 'Nova página',
        color: AppColors.warning,
        onTap: () => context.go(AppRoutes.pages),
      ),
      _QuickAction(
        icon: Icons.inbox_outlined,
        label: 'Capturar ideia',
        color: AppColors.success,
        onTap: () => context.go(AppRoutes.gtd),
      ),
    ];

    return Row(
      children: actions
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: e.key < actions.length - 1 ? AppSpacing.sp10 : 0,
                ),
                child: _QuickActionCard(action: e.value),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatefulWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final color = widget.action.color;
    final isDesktop = Responsive.isDesktop(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.action.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12,
            vertical: isDesktop ? 14.0 : AppSpacing.sp10,
          ),
          decoration: BoxDecoration(
            color: _hovering
                ? color.withValues(alpha: 0.08)
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hovering
                  ? color.withValues(alpha: 0.3)
                  : (isDark ? AppColors.borderDark : AppColors.border),
            ),
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Icon(widget.action.icon, size: 18, color: color),
                    const SizedBox(width: AppSpacing.sp8),
                    Expanded(
                      child: Text(
                        widget.action.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.cTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.action.icon, size: 20, color: color),
                    const SizedBox(height: AppSpacing.sp6),
                    Text(
                      widget.action.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.cTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}


