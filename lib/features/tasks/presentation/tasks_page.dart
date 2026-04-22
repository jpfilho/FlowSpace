import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_tags.dart';
import '../../../shared/widgets/common/flow_states.dart';
import '../../../shared/widgets/common/skeleton.dart';
import '../../auth/domain/data_providers.dart';
import '../../members/presentation/members_page.dart' show workspaceMembersProvider;
import 'edit_task_sheet.dart';
import 'widgets/gantt_view.dart';
import 'widgets/tasks_table_view.dart';

final _viewProvider = StateProvider<String>((ref) => 'gantt'); // list | kanban | gantt

// ── Filtros ───────────────────────────────────────────────────
final _statusFilterProvider = StateProvider<String>((ref) => 'all');
final _priorityFilterProvider = StateProvider<String>((ref) => 'all');
final _dueTodayFilterProvider = StateProvider<bool>((ref) => false);
final _noDateFilterProvider = StateProvider<bool>((ref) => false);
final _projectFilterProvider = StateProvider<String?>((ref) => null);
final _assigneeFilterProvider = StateProvider<String?>((ref) => null);

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(_viewProvider);
    final isDesktop = Responsive.isDesktop(context);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Column(
        children: [
          // Header
          tasksAsync.when(
            data: (tasks) => _TasksHeader(
              taskCount: tasks.length,
              currentView: view,
              onViewChanged: (v) =>
                  ref.read(_viewProvider.notifier).state = v,
            ),
            loading: () => _TasksHeader(
              taskCount: 0,
              currentView: view,
              onViewChanged: (v) =>
                  ref.read(_viewProvider.notifier).state = v,
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Filter bar
          _FilterBar(),

          // Content
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final statusFilter = ref.watch(_statusFilterProvider);
                final priorityFilter = ref.watch(_priorityFilterProvider);
                final dueTodayOnly = ref.watch(_dueTodayFilterProvider);
                final noDateOnly = ref.watch(_noDateFilterProvider);
                final projectFilter = ref.watch(_projectFilterProvider);
                final assigneeFilter = ref.watch(_assigneeFilterProvider);
                final today = DateTime.now();
                final todayDate = DateTime(today.year, today.month, today.day);

                var filtered = tasks.where((t) {
                  // Status filter
                  if (statusFilter != 'all' && t.status != statusFilter) {
                    return false;
                  }
                  // Priority filter
                  if (priorityFilter != 'all' && t.priority != priorityFilter) {
                    return false;
                  }
                  // Due today filter
                  if (dueTodayOnly) {
                    if (t.dueDate == null) return false;
                    final due = DateTime(
                        t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                    if (due != todayDate) return false;
                  }
                  // No date filter
                  if (noDateOnly && t.dueDate != null) return false;
                  // Project filter
                  if (projectFilter != null && t.projectId != projectFilter) {
                    return false;
                  }
                  // Assignee filter
                  if (assigneeFilter != null && t.assigneeId != assigneeFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                if (view == 'gantt') {
                  return GanttView(tasks: filtered);
                }
                if (view == 'table') {
                  return TasksTableView(tasks: filtered);
                }
                return view == 'kanban'
                    ? _KanbanView(tasks: filtered)
                    : _TaskListView(tasks: filtered, isDesktop: isDesktop);
              },
              loading: () => const _TasksLoadingSkeleton(),
              error: (e, _) => FlowErrorState(
                message: 'Erro ao carregar tarefas: $e',
                onRetry: () => ref.refresh(tasksProvider),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTask(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova tarefa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateTask(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTaskSheet(),
    );
  }
}

// ── Filter Bar ─────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(_statusFilterProvider);
    final currentPriority = ref.watch(_priorityFilterProvider);
    final dueToday = ref.watch(_dueTodayFilterProvider);
    final noDate = ref.watch(_noDateFilterProvider);
    final currentProject = ref.watch(_projectFilterProvider);
    final currentAssignee = ref.watch(_assigneeFilterProvider);
    final projects = ref.watch(projectsProvider).valueOrNull ?? [];
    final members = ref.watch(workspaceMembersProvider).valueOrNull ?? [];

    final hasActiveFilter = currentStatus != 'all' ||
        currentPriority != 'all' ||
        dueToday ||
        noDate ||
        currentProject != null ||
        currentAssignee != null;

    const statusFilters = [
      ('all', 'Todas', null),
      ('todo', 'A fazer', AppColors.statusTodo),
      ('in_progress', 'Em progresso', AppColors.statusInProgress),
      ('review', 'Revisão', AppColors.statusReview),
      ('done', 'Concluídas', AppColors.statusDone),
      ('cancelled', 'Canceladas', AppColors.textMuted),
    ];

    const priorityFilters = [
      ('all', 'Qualquer', null),
      ('urgent', '🔴 Urgente', AppColors.error),
      ('high', '🟠 Alta', AppColors.warning),
      ('medium', '🔵 Média', AppColors.primary),
      ('low', '⚪ Baixa', AppColors.textMuted),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha 1: Status ───────────────────────────
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
              child: Row(children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: statusFilters.map((f) {
                      final (value, label, color) = f;
                      final active = currentStatus == value;
                      final chipColor = color ?? AppColors.primary;
                      return Padding(
                        padding: const EdgeInsets.only(
                            right: AppSpacing.sp6, top: 9, bottom: 9),
                        child: GestureDetector(
                          onTap: () => ref
                              .read(_statusFilterProvider.notifier)
                              .state = value,
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sp10, vertical: 3),
                            decoration: BoxDecoration(
                              color: active
                                  ? chipColor.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: active
                                    ? chipColor
                                    : (context.isDark
                                        ? AppColors.borderDark
                                        : AppColors.border),
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: active ? chipColor : context.cTextMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Clear all button
                if (hasActiveFilter)
                  Tooltip(
                    message: 'Limpar filtros',
                    child: GestureDetector(
                      onTap: () {
                        ref.read(_statusFilterProvider.notifier).state = 'all';
                        ref.read(_priorityFilterProvider.notifier).state = 'all';
                        ref.read(_dueTodayFilterProvider.notifier).state = false;
                        ref.read(_noDateFilterProvider.notifier).state = false;
                        ref.read(_projectFilterProvider.notifier).state = null;
                        ref.read(_assigneeFilterProvider.notifier).state = null;
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.close_rounded,
                                size: 11, color: AppColors.error),
                            SizedBox(width: 3),
                            Text('Limpar',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded,
                      size: 18, color: context.cTextMuted),
                  // ignore: unused_result
                  onPressed: () => ref.refresh(tasksProvider),
                  tooltip: 'Atualizar',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ]),
            ),
          ),

          // ── Linha 2: Prioridade + Vence hoje ─────────
          SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp16),
              child: Row(children: [
                Icon(Icons.tune_rounded,
                    size: 13, color: context.cTextMuted),
                const SizedBox(width: 6),
                Text('Prioridade:',
                    style: TextStyle(
                        fontSize: 11,
                        color: context.cTextMuted,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: priorityFilters.map((f) {
                      final (value, label, color) = f;
                      final active = currentPriority == value;
                      final chipColor = color ?? AppColors.primary;
                      return Padding(
                        padding: const EdgeInsets.only(
                            right: AppSpacing.sp6, top: 6, bottom: 6),
                        child: GestureDetector(
                          onTap: () => ref
                              .read(_priorityFilterProvider.notifier)
                              .state = value,
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sp8, vertical: 2),
                            decoration: BoxDecoration(
                              color: active
                                  ? chipColor.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: active
                                    ? chipColor
                                    : (context.isDark
                                        ? AppColors.borderDark
                                        : AppColors.border),
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color:
                                    active ? chipColor : context.cTextMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Due today toggle
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => ref
                      .read(_dueTodayFilterProvider.notifier)
                      .state = !dueToday,
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dueToday
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: dueToday
                            ? AppColors.warning
                            : (context.isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                        width: dueToday ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.today_rounded,
                          size: 11,
                          color: dueToday
                              ? AppColors.warning
                              : context.cTextMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Vence hoje',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: dueToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: dueToday
                              ? AppColors.warning
                              : context.cTextMuted,
                        ),
                      ),
                    ]),
                  ),
                ),
                // No date toggle
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => ref
                      .read(_noDateFilterProvider.notifier)
                      .state = !noDate,
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: noDate
                          ? AppColors.textMuted.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: noDate
                            ? AppColors.textMuted
                            : (context.isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                        width: noDate ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.event_busy_rounded,
                          size: 11,
                          color: noDate
                              ? AppColors.textMuted
                              : context.cTextMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Sem data',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: noDate
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: noDate
                              ? AppColors.textMuted
                              : context.cTextMuted,
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // ── Linha 3: Projeto + Membro ────────────────────────
          SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Icon(Icons.folder_outlined, size: 13, color: context.cTextMuted),
                  const SizedBox(width: 6),
                  Text('Projeto:', style: TextStyle(fontSize: 11, color: context.cTextMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Todos', active: currentProject == null, color: AppColors.primary, onTap: () => ref.read(_projectFilterProvider.notifier).state = null),
                  ...projects.map((p) {
                    final active = currentProject == p.id;
                    final chipColor = (p.color != null && p.color!.isNotEmpty)
                        ? _hexColor(p.color!) : AppColors.primary;
                    return _FilterChip(label: p.name, active: active, color: chipColor,
                      onTap: () => ref.read(_projectFilterProvider.notifier).state = active ? null : p.id);
                  }),
                  const SizedBox(width: 12),
                  Icon(Icons.person_outline_rounded, size: 13, color: context.cTextMuted),
                  const SizedBox(width: 4),
                  Text('Membro:', style: TextStyle(fontSize: 11, color: context.cTextMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Todos', active: currentAssignee == null, color: AppColors.accent, onTap: () => ref.read(_assigneeFilterProvider.notifier).state = null),
                  ...members.map((m) {
                    final active = currentAssignee == m.userId;
                    final name = m.name.isNotEmpty ? m.name : m.email;
                    return _FilterChip(label: name, active: active, color: AppColors.accent,
                      onTap: () => ref.read(_assigneeFilterProvider.notifier).state = active ? null : m.userId);
                  }),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
  } catch (_) {
    return AppColors.primary;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sp6, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp8, vertical: 2),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: active ? color : (context.isDark ? AppColors.borderDark : AppColors.border),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? color : context.cTextMuted)),
        ),
      ),
    );
  }
}


// ── Header ──────────────────────────────────────────────────
class _TasksHeader extends StatelessWidget {
  final int taskCount;
  final String currentView;
  final ValueChanged<String> onViewChanged;

  const _TasksHeader({
    required this.taskCount,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp24,
        vertical: AppSpacing.sp16,
      ),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarefas', style: Theme.of(context).textTheme.headlineSmall),
              Text('$taskCount tarefa${taskCount != 1 ? 's' : ''} no total',
                  style: context.bodySm),
            ],
          ),
          const Spacer(),
          // View switcher
          Container(
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                _ViewBtn(
                  icon: Icons.list_rounded,
                  label: 'Lista',
                  active: currentView == 'list',
                  onTap: () => onViewChanged('list'),
                ),
                _ViewBtn(
                  icon: Icons.view_kanban_outlined,
                  label: 'Kanban',
                  active: currentView == 'kanban',
                  onTap: () => onViewChanged('kanban'),
                ),
                _ViewBtn(
                  icon: Icons.view_timeline_outlined,
                  label: 'Gantt',
                  active: currentView == 'gantt',
                  onTap: () => onViewChanged('gantt'),
                ),
                _ViewBtn(
                  icon: Icons.table_chart_outlined,
                  label: 'Tabela',
                  active: currentView == 'table',
                  onTap: () => onViewChanged('table'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ViewBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp10,
          vertical: AppSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: active
              ? (context.isDark ? AppColors.surfaceDark : AppColors.surface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 15,
                color: active ? AppColors.primary : context.cTextMuted),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.primary : context.cTextMuted,
                )),
          ],
        ),
      ),
    );
  }
}

// ── List View ───────────────────────────────────────────────
class _TaskListView extends ConsumerStatefulWidget {
  final List<TaskData> tasks;
  final bool isDesktop;

  const _TaskListView({required this.tasks, required this.isDesktop});

  @override
  ConsumerState<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<_TaskListView> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(pagedTasksProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagedState = ref.watch(pagedTasksProvider).valueOrNull;
    final isLoadingMore = pagedState?.isLoadingMore ?? false;
    final hasMore = pagedState?.hasMore ?? true;

    if (widget.tasks.isEmpty) {
      return const FlowEmptyState(
        icon: Icons.check_box_outline_blank_rounded,
        title: 'Nenhuma tarefa aqui',
        subtitle: 'Crie uma nova tarefa para começar',
        actionLabel: 'Nova tarefa',
      );
    }
    return ListView.separated(
      controller: _scrollCtrl,
      padding: EdgeInsets.only(
        left: widget.isDesktop ? AppSpacing.sp24 : AppSpacing.sp16,
        right: widget.isDesktop ? AppSpacing.sp24 : AppSpacing.sp16,
        top: widget.isDesktop ? AppSpacing.sp24 : AppSpacing.sp16,
        bottom: 80,
      ),
      itemCount: widget.tasks.length + 1, // +1 for footer
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp8),
      itemBuilder: (_, i) {
        // Footer
        if (i == widget.tasks.length) {
          if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }
          if (!hasMore && widget.tasks.length >= 30) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '${widget.tasks.length} tarefas carregadas',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return _TaskListTile(task: widget.tasks[i])
            .animate()
            .fadeIn(delay: (i * 20).ms, duration: 250.ms)
            .slideX(begin: -0.02, duration: 250.ms);
      },
    );
  }
}

class _TaskListTile extends ConsumerStatefulWidget {
  final TaskData task;
  const _TaskListTile({required this.task});

  @override
  ConsumerState<_TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends ConsumerState<_TaskListTile> {
  bool _hovering = false;

  Color get _statusColor => switch (widget.task.status) {
        'todo' => AppColors.statusTodo,
        'in_progress' => AppColors.statusInProgress,
        'review' => AppColors.statusReview,
        'done' => AppColors.statusDone,
        'cancelled' => AppColors.statusCancelled,
        _ => AppColors.textDisabled,
      };

  Future<void> _toggleComplete() async {
    final newStatus =
        widget.task.status == 'done' ? 'todo' : 'done';
    final error = await ref
        .read(tasksProvider.notifier)
        .updateStatus(widget.task.id, newStatus);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/tasks/${task.id}'),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppSpacing.sp16),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hovering
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (context.isDark ? AppColors.borderDark : AppColors.border),
            ),
          ),
          child: Row(
            children: [
              // Status bar
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),

              // Checkbox
              GestureDetector(
                onTap: _toggleComplete,
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: task.isDone ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: task.isDone
                          ? AppColors.primary
                          : (context.isDark
                              ? AppColors.borderStrongDark
                              : AppColors.borderStrong),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sp12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: task.isDone
                            ? context.cTextMuted
                            : context.cTextPrimary,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: context.cTextMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp6),
                    Row(
                      children: [
                        PriorityTag(priority: task.priority),
                        const SizedBox(width: AppSpacing.sp6),
                        StatusTag(status: task.status),
                        if (task.projectName != null) ...[
                          const SizedBox(width: AppSpacing.sp6),
                          _ProjectBadge(name: task.projectName!),
                        ],
                        if (task.dueDate != null) ...[
                          const SizedBox(width: AppSpacing.sp6),
                          _DueDateBadge(date: task.dueDate!),
                        ],
                        if (task.isRecurring) ...[
                          const SizedBox(width: AppSpacing.sp6),
                          Tooltip(
                            message: _recurrenceLabel(task.recurrenceType, task.recurrenceInterval),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat_rounded,
                                      size: 10, color: AppColors.accent),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions — always in tree, visible on hover
              Visibility(
                visible: _hovering,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded,
                      size: 18, color: context.cTextMuted),
                  tooltip: 'Opções',
                  onSelected: (action) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (action == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir tarefa'),
                          content: Text(
                            'Tem certeza que deseja excluir "${task.title}"? Esta ação não pode ser desfeita.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final err = await ref
                            .read(tasksProvider.notifier)
                            .deleteTask(task.id);
                        if (mounted) {
                          if (err != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Row(children: [
                                  Icon(Icons.delete_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Tarefa excluída'),
                                ]),
                                backgroundColor: AppColors.error,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
                    } else if (action == 'done') {
                      await ref
                          .read(tasksProvider.notifier)
                          .updateStatus(task.id, 'done');
                    } else if (action == 'in_progress') {
                      await ref
                          .read(tasksProvider.notifier)
                          .updateStatus(task.id, 'in_progress');
                    } else if (action == 'assign_project') {
                      _showAssignProject(context, ref, task);
                    } else if (action == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => EditTaskSheet(task: task),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Editar tarefa'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'in_progress',
                      child: Row(children: [
                        Icon(Icons.pending_actions_rounded,
                            size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('Em progresso'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'done',
                      child: Row(children: [
                        Icon(Icons.task_alt_rounded,
                            size: 16, color: AppColors.success),
                        SizedBox(width: 8),
                        Text('Concluir'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'assign_project',
                      child: Row(children: [
                        Icon(Icons.folder_outlined,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Atribuir projeto'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Excluir',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignProject(BuildContext context, WidgetRef ref, TaskData task) {
    showDialog(
      context: context,
      builder: (_) => _AssignProjectDialog(task: task),
    );
  }
}

// ── Dialog de Atribuição de Projeto ───────────────────────────
class _AssignProjectDialog extends ConsumerStatefulWidget {
  final TaskData task;
  const _AssignProjectDialog({required this.task});

  @override
  ConsumerState<_AssignProjectDialog> createState() =>
      _AssignProjectDialogState();
}

class _AssignProjectDialogState extends ConsumerState<_AssignProjectDialog> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.task.projectId;
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch aqui funciona corretamente — este é um ConsumerWidget
    final projectsAsync = ref.watch(projectsProvider);

    return AlertDialog(
      title: const Text('Atribuir projeto'),
      content: SizedBox(
        width: 360,
        child: projectsAsync.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text('Erro: $e',
              style: const TextStyle(color: AppColors.error)),
          data: (projects) => projects.isEmpty
              ? const Text('Nenhum projeto encontrado')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RadioTile(
                        title: 'Sem projeto',
                        isSelected: _selected == null,
                        onTap: () => setState(() => _selected = null),
                      ),
                      ...projects.map((p) => _RadioTile(
                            title: p.name,
                            subtitle: p.statusDisplay,
                            isSelected: _selected == p.id,
                            onTap: () => setState(() => _selected = p.id),
                          )),
                    ],
                  ),
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final client = ref.read(supabaseProvider);
            final messenger = ScaffoldMessenger.of(context);
            final nav = Navigator.of(context);
            try {
              await client.from('tasks').update({
                'project_id': _selected,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', widget.task.id);
              // ignore: unused_result
              ref.refresh(tasksProvider);
              if (mounted) {
                nav.pop();
                messenger.showSnackBar(SnackBar(
                  content: Text(_selected != null
                      ? 'Tarefa atribuída ao projeto!'
                      : 'Projeto removido da tarefa'),
                  backgroundColor: AppColors.success,
                ));
              }
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Erro: $e'),
                  backgroundColor: AppColors.error,
                ));
              }
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// ── Helper: recurrence tooltip text ──────────────────────────
String _recurrenceLabel(String type, int interval) {
  final labels = {
    'daily': interval == 1 ? 'Diária' : 'A cada $interval dias',
    'weekly': interval == 1 ? 'Semanal' : 'A cada $interval semanas',
    'monthly': interval == 1 ? 'Mensal' : 'A cada $interval meses',
    'yearly': interval == 1 ? 'Anual' : 'A cada $interval anos',
  };
  return labels[type] ?? 'Recorrente';
}

class _ProjectBadge extends StatelessWidget {
  final String name;
  const _ProjectBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp6, vertical: 2),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_outlined, size: 10, color: context.cTextMuted),
        const SizedBox(width: 3),
        Text(name, style: AppTypography.caption(context.cTextMuted)),
      ]),
    );
  }
}

class _DueDateBadge extends StatelessWidget {
  final DateTime date;
  const _DueDateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final isOverdue = due.isBefore(today);
    final isToday = due.isAtSameMomentAs(today);

    final color = isOverdue
        ? AppColors.error
        : isToday
            ? AppColors.warning
            : context.cTextMuted;
    final label = isToday
        ? 'Hoje'
        : isOverdue
            ? 'Atrasada'
            : '${date.day}/${date.month}';

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.schedule_rounded, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

// ── Kanban View ─────────────────────────────────────────────
class _KanbanView extends StatelessWidget {
  final List<TaskData> tasks;
  const _KanbanView({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final columns = ['todo', 'in_progress', 'review', 'done'];
    final labels = {
      'todo': ('A fazer', AppColors.statusTodo),
      'in_progress': ('Em progresso', AppColors.statusInProgress),
      'review': ('Em revisão', AppColors.statusReview),
      'done': ('Concluído', AppColors.statusDone),
    };

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.sp24),
      children: columns.map((col) {
        final colTasks = tasks.where((t) => t.status == col).toList();
        final (label, color) = labels[col]!;
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: AppSpacing.sp12),
          child: _KanbanColumn(colId: col, label: label, color: color, tasks: colTasks),
        );
      }).toList(),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String colId;
  final String label;
  final Color color;
  final List<TaskData> tasks;

  const _KanbanColumn({
    required this.colId,
    required this.label,
    required this.color,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<TaskData>(
      onWillAcceptWithDetails: (details) => details.data.status != colId,
      onAcceptWithDetails: (details) {
        ref.read(tasksProvider.notifier).updateStatus(details.data.id, colId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovered
                ? color.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sp12),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: AppSpacing.sp8),
            Text(label,
                style: AppTypography.label(context.cTextPrimary)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: AppSpacing.sp8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(tasks.length.toString(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    color: context.isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  child: Center(
                    child: Text('Sem tarefas',
                        style: context.bodySm.copyWith(fontSize: 13)),
                  ),
                )
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp8),
                  itemBuilder: (_, i) => _KanbanCard(task: tasks[i])
                      .animate()
                      .fadeIn(delay: (i * 40).ms, duration: 300.ms),
                ),
            ),
          ],
        ),
      );
    },
    );
  }
}

class _KanbanCard extends ConsumerStatefulWidget {
  final TaskData task;
  const _KanbanCard({required this.task});

  @override
  ConsumerState<_KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends ConsumerState<_KanbanCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final content = AnimatedContainer(
      duration: AppAnimations.fast,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _hovering
              ? AppColors.primary.withValues(alpha: 0.3)
              : (context.isDark ? AppColors.borderDark : AppColors.border),
        ),
        boxShadow: _hovering
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
          const SizedBox(height: AppSpacing.sp10),
          Row(children: [
            PriorityTag(priority: task.priority),
            const Spacer(),
            if (task.dueDate != null) _DueDateBadge(date: task.dueDate!),
            if (task.isRecurring) ...[
              const SizedBox(width: AppSpacing.sp4),
              Icon(Icons.repeat_rounded, size: 12, color: AppColors.accent),
            ],
          ]),
          if (task.projectName != null) ...[
            const SizedBox(height: AppSpacing.sp8),
            Text(task.projectName!, style: context.labelMd),
          ],
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        onTap: () => context.go('/tasks/${task.id}'),
        child: LongPressDraggable<TaskData>(
          data: task,
          delay: const Duration(milliseconds: 150),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.8,
              child: SizedBox(width: 250, child: content),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: content,
          ),
          child: content,
        ),
      ),
    );
  }
}


// ── Create Task Sheet ────────────────────────────────────────
class _CreateTaskSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final _ctrl = TextEditingController();
  String _priority = 'medium';
  final String _status = 'todo';
  String? _projectId;
  DateTime? _dueDate;
  bool _loading = false;
  String? _error;

  final _priorities = [
    ('urgent', 'Urgente'),
    ('high', 'Alta'),
    ('medium', 'Média'),
    ('low', 'Baixa'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _error = 'Digite o título da tarefa');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = await ref.read(tasksProvider.notifier).createTask(
      title: _ctrl.text,
      status: _status,
      priority: _priority,
      projectId: _projectId,
      dueDate: _dueDate,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (result.error != null) {
        setState(() => _error = result.error);
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Tarefa criada com sucesso!'),
            ]),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.sp24,
        right: AppSpacing.sp24,
        top: AppSpacing.sp24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sp24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp20),

          Text('Nova tarefa', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sp16),

          // Title input
          TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'O que precisa ser feito?',
              errorText: _error,
            ),
            style: TextStyle(fontSize: 15, color: context.cTextPrimary),
          ),
          const SizedBox(height: AppSpacing.sp16),

          // Priority selector
          Text('Prioridade', style: context.labelMd),
          const SizedBox(height: AppSpacing.sp8),
          Wrap(
            spacing: AppSpacing.sp8,
            children: _priorities.map((p) {
              final (value, label) = p;
              final selected = _priority == value;
              return GestureDetector(
                onTap: () => setState(() => _priority = value),
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12, vertical: AppSpacing.sp6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: selected ? AppColors.primary : (context.isDark ? AppColors.borderDark : AppColors.border),
                    ),
                  ),
                  child: Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.primary : context.cTextMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sp16),

          // ── Projeto ─────────────────────────────────────
          Text('Projeto (opcional)', style: context.labelMd),
          const SizedBox(height: AppSpacing.sp8),
          _ProjectPicker(
            selectedId: _projectId,
            onSelected: (id) => setState(() => _projectId = id),
          ),
          const SizedBox(height: AppSpacing.sp20),

          // ── Data de Vencimento ─────────────────────────
          Text('Data de vencimento', style: context.labelMd),
          const SizedBox(height: AppSpacing.sp8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                helpText: 'Data de vencimento',
                confirmText: 'Confirmar',
                cancelText: 'Cancelar',
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: AppColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp12, vertical: AppSpacing.sp10),
              decoration: BoxDecoration(
                color: _dueDate != null
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : (context.isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _dueDate != null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : (context.isDark
                          ? AppColors.borderDark
                          : AppColors.border),
                ),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16,
                    color: _dueDate != null
                        ? AppColors.primary
                        : context.cTextMuted),
                const SizedBox(width: AppSpacing.sp8),
                Expanded(
                  child: Text(
                    _dueDate != null
                        ? '${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}'
                        : 'Sem data — toque para definir',
                    style: TextStyle(
                      fontSize: 13,
                      color: _dueDate != null
                          ? AppColors.primary
                          : context.cTextMuted,
                      fontWeight: _dueDate != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (_dueDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _dueDate = null),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.primary),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.sp20),

          // Buttons
          Row(children: [
            Expanded(
              child: FlowButton(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                variant: FlowButtonVariant.outline,
              ),
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: FlowButton(
                label: _loading ? 'Salvando...' : 'Criar tarefa',
                onPressed: _loading ? null : _submit,
                leadingIcon: _loading ? null : Icons.add_rounded,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Project Picker (inline chips para criação de tarefa) ──────
class _ProjectPicker extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _ProjectPicker({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      loading: () => const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      error: (_, __) => Text('Erro ao carregar projetos',
          style: TextStyle(color: AppColors.error, fontSize: 12)),
      data: (projects) {
        if (projects.isEmpty) {
          return Text('Nenhum projeto disponível', style: context.bodySm);
        }
        return Wrap(
          spacing: AppSpacing.sp8,
          runSpacing: AppSpacing.sp6,
          children: [
            // Chip "Nenhum"
            _ProjectChip(
              label: 'Nenhum',
              icon: Icons.block_rounded,
              isSelected: selectedId == null,
              onTap: () => onSelected(null),
            ),
            ...projects.map(
              (p) => _ProjectChip(
                label: p.name,
                icon: Icons.folder_rounded,
                isSelected: selectedId == p.id,
                onTap: () => onSelected(p.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp10, vertical: AppSpacing.sp6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (context.isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (context.isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isSelected ? AppColors.primary : context.cTextMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : context.cTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading ─────────────────────────────────────────
class _TasksLoadingSkeleton extends StatelessWidget {
  const _TasksLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.cBackground,
      child: Column(children: [
        // Filter bar skeleton
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: context.isDark
                    ? AppColors.borderDark
                    : AppColors.border,
              ),
            ),
          ),
          child: Row(children: [
            SkeletonBox(width: 48, height: 28, radius: 14),
            const SizedBox(width: 8),
            SkeletonBox(width: 72, height: 28, radius: 14),
            const SizedBox(width: 8),
            SkeletonBox(width: 64, height: 28, radius: 14),
            const SizedBox(width: 8),
            SkeletonBox(width: 56, height: 28, radius: 14),
          ]),
        ),
        // Task tiles
        Expanded(
          child: ListView.separated(
            itemCount: 8,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp8),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: AppSpacing.sp16,
              endIndent: AppSpacing.sp16,
              color: context.isDark
                  ? AppColors.borderDark
                  : AppColors.border,
            ),
            itemBuilder: (_, __) => const SkeletonTaskTile(),
          ),
        ),
      ]),
    );
  }
}

// ── Radio Tile simples (substitui RadioListTile deprecated) ───
class _RadioTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 4, vertical: AppSpacing.sp8),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isSelected ? AppColors.primary : context.cTextMuted,
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : context.cTextPrimary,
                      )),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(fontSize: 11, color: context.cTextMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
