import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/index.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/domain/data_providers.dart';

class TodayTasksWidget extends ConsumerWidget {
  const TodayTasksWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp20),
            child: Row(
              children: [
                Text(
                  'Tarefas recentes',
                  style: AppTypography.heading(context.cTextPrimary)
                      .copyWith(fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.tasks),
                  child: const Text(
                    'Ver todas',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Task list — real data
          tasksAsync.when(
            data: (allTasks) {
              // Show at most 5 most recent non-done tasks, then done at end
              final active = allTasks
                  .where((t) => t.status != 'done')
                  .take(4)
                  .toList();
              final done = allTasks
                  .where((t) => t.status == 'done')
                  .take(1)
                  .toList();
              final tasks = [...active, ...done].take(5).toList();

              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.sp20),
                  child: Center(
                    child: Text(
                      'Nenhuma tarefa ainda',
                      style: context.bodySm,
                    ),
                  ),
                );
              }
              return Column(
                children: tasks.map((t) => _TaskRow(task: t)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.sp20),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.sp16),
              child: Text('Erro: $e', style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          ),

          // Add task shortcut
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp16),
            child: InkWell(
              onTap: () => context.go(AppRoutes.tasks),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp8,
                  vertical: AppSpacing.sp8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: context.cTextMuted),
                    const SizedBox(width: AppSpacing.sp8),
                    Text(
                      'Nova tarefa',
                      style: AppTypography.body(context.cTextMuted)
                          .copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerStatefulWidget {
  final TaskData task;
  const _TaskRow({required this.task});

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<_TaskRow> {
  Color get _priorityColor => switch (widget.task.priority) {
        'urgent' => AppColors.priorityUrgent,
        'high' => AppColors.priorityHigh,
        'medium' => AppColors.priorityMedium,
        _ => AppColors.priorityLow,
      };

  Future<void> _toggle() async {
    final newStatus = widget.task.isDone ? 'todo' : 'done';
    await ref.read(tasksProvider.notifier).updateStatus(widget.task.id, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return InkWell(
      onTap: () => context.go('/tasks/${task.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp20,
          vertical: AppSpacing.sp12,
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: task.isDone ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: task.isDone
                        ? AppColors.primary
                        : context.isDark
                            ? AppColors.borderStrongDark
                            : AppColors.borderStrong,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: task.isDone
                    ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sp12),

            // Priority dot
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _priorityColor, shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sp10),

            // Title
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: task.isDone ? context.cTextMuted : context.cTextPrimary,
                  decoration: task.isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: context.cTextMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sp12),

            // Project + due date
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (task.projectName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(task.projectName!,
                      style: AppTypography.caption(context.cTextMuted)),
                ),
              if (task.dueDate != null) ...[
                const SizedBox(width: AppSpacing.sp8),
                Icon(Icons.schedule_rounded, size: 12, color: context.cTextMuted),
                const SizedBox(width: 3),
                Text(
                  '${task.dueDate!.day}/${task.dueDate!.month}',
                  style: AppTypography.caption(context.cTextMuted),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}
