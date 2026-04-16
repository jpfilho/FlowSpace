import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_tags.dart';
import '../../auth/domain/data_providers.dart';
import 'edit_project_sheet.dart';

// ── Provider local para projeto único por id ─────────────────
final _projectByIdProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, id) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('projects')
      .select('id, name, description, status, priority, progress, created_at, updated_at, project_members(count)')
      .eq('id', id)
      .maybeSingle();
  return data;
});

// ── Página ───────────────────────────────────────────────────
class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(_projectByIdProvider(widget.projectId));
    final tasksAsync = ref.watch(projectTasksProvider(widget.projectId));

    return Scaffold(
      backgroundColor: context.cBackground,
      body: projectAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Erro ao carregar projeto: $e',
              style: TextStyle(color: AppColors.error)),
        ),
        data: (raw) {
          if (raw == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.folder_off_rounded,
                    size: 56, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('Projeto não encontrado', style: context.bodyMd),
                const SizedBox(height: 16),
                FlowButton(
                    label: 'Voltar',
                    onPressed: () => context.go('/projects'),
                    variant: FlowButtonVariant.outline),
              ]),
            );
          }

          // Build ProjectData from raw map
          final project = ProjectData(
            id: raw['id'] as String,
            name: raw['name'] as String,
            description: raw['description'] as String?,
            status: raw['status'] as String? ?? 'active',
            priority: raw['priority'] as String? ?? 'medium',
            progress: (raw['progress'] as num?)?.toInt() ?? 0,
            memberCount: 0,
          );
          final updatedAt = raw['updated_at'] != null
              ? DateTime.tryParse(raw['updated_at'] as String)
              : null;

          final progressColor = project.progress > 70
              ? AppColors.success
              : project.progress > 40
                  ? AppColors.primary
                  : AppColors.warning;

          return Column(
            children: [
              // ── AppBar + Header ──────────────────────────
              Container(
                color: context.isDark
                    ? AppColors.surfaceDark
                    : AppColors.surface,
                child: Column(
                  children: [
                    // Top row
                    SizedBox(
                      height: AppSpacing.topbarHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp16),
                        child: Row(children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => context.go('/projects'),
                            color: context.cTextPrimary,
                            tooltip: 'Voltar a Projetos',
                          ),
                          const SizedBox(width: AppSpacing.sp8),
                          // Project icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(Icons.folder_rounded,
                                color: AppColors.primary, size: 16),
                          ),
                          const SizedBox(width: AppSpacing.sp10),
                          Expanded(
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusTag(status: project.status),
                          const SizedBox(width: AppSpacing.sp8),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Editar projeto',
                            color: AppColors.primary,
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  EditProjectSheet(project: project),
                            ).then((_) {
                              // ignore: unused_result
                              ref.refresh(
                                  _projectByIdProvider(widget.projectId));
                              // ignore: unused_result
                              ref.refresh(projectsProvider);
                            }),
                          ),
                        ]),
                      ),
                    ),

                    // Progress section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sp24, 0, AppSpacing.sp24, AppSpacing.sp16),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (project.description != null &&
                                    project.description!.isNotEmpty)
                                  Text(project.description!,
                                      style: context.bodySm
                                          .copyWith(color: context.cTextMuted)),
                                Row(children: [
                                  PriorityTag(priority: project.priority),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Atualizado ${updatedAt != null ? _fmtDate(updatedAt) : '—'}',
                                    style: context.bodySm
                                        .copyWith(color: context.cTextMuted),
                                  ),
                                ]),
                              ],
                            ),
                            Text(
                              '${project.progress}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: progressColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sp10),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            value: project.progress / 100,
                            backgroundColor:
                                progressColor.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation(progressColor),
                            minHeight: 8,
                          ),
                        ),
                      ]),
                    ),

                    // Stats row
                    tasksAsync.maybeWhen(
                      data: (tasks) {
                        final done = tasks
                            .where((t) => t['status'] == 'done')
                            .length;
                        final total = tasks.length;
                        final inProgress = tasks
                            .where((t) => t['status'] == 'in_progress')
                            .length;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: context.isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp24,
                              vertical: AppSpacing.sp12),
                          child: Row(children: [
                            _StatChip(
                                label: 'Total',
                                value: total,
                                color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sp16),
                            _StatChip(
                                label: 'Em progresso',
                                value: inProgress,
                                color: AppColors.statusInProgress),
                            const SizedBox(width: AppSpacing.sp16),
                            _StatChip(
                                label: 'Concluídas',
                                value: done,
                                color: AppColors.success),
                          ]),
                        ).animate().fadeIn(duration: 300.ms);
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),

                    // Tabs
                    TabBar(
                      controller: _tabs,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: context.cTextMuted,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2,
                      tabs: const [
                        Tab(text: 'Lista'),
                        Tab(text: 'Kanban'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tab views ───────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    // ── Lista ────────────────────────────
                    tasksAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                      error: (e, _) => Center(
                          child: Text('Erro: $e',
                              style: TextStyle(color: AppColors.error))),
                      data: (tasks) => tasks.isEmpty
                          ? _EmptyTasksState(projectId: widget.projectId)
                          : _TaskListTab(tasks: tasks),
                    ),

                    // ── Kanban ───────────────────────────
                    tasksAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                      error: (e, _) => Center(
                          child: Text('Erro: $e',
                              style: TextStyle(color: AppColors.error))),
                      data: (tasks) => _KanbanTab(tasks: tasks),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}

// ── Stat chip ────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: context.bodySm.copyWith(fontSize: 12, color: context.cTextMuted)),
    ]);
  }
}

// ── Lista de tarefas ─────────────────────────────────────────
class _TaskListTab extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  const _TaskListTab({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final t = tasks[i];
        final isDone = t['status'] == 'done';
        final priority = t['priority'] as String? ?? 'medium';
        final dueDate = t['due_date'] != null
            ? DateTime.tryParse(t['due_date'] as String)
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: context.isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Row(children: [
            Icon(
              isDone
                  ? Icons.task_alt_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? AppColors.success : context.cTextMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['title'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDone ? context.cTextMuted : context.cTextPrimary,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      decorationColor: context.cTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    PriorityTag(priority: priority),
                    const SizedBox(width: 6),
                    StatusTag(status: t['status'] as String? ?? 'todo'),
                    if (dueDate != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_today_rounded,
                          size: 11, color: context.cTextMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${dueDate.day}/${dueDate.month}',
                        style: TextStyle(
                            fontSize: 11, color: context.cTextMuted),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/tasks/${t['id']}'),
              child: Icon(Icons.open_in_new_rounded,
                  size: 15, color: context.cTextMuted),
            ),
          ]),
        ).animate().fadeIn(delay: (i * 30).ms, duration: 250.ms);
      },
    );
  }
}

// ── Kanban ────────────────────────────────────────────────────
class _KanbanTab extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  const _KanbanTab({required this.tasks});

  @override
  Widget build(BuildContext context) {
    const columns = ['todo', 'in_progress', 'review', 'done'];
    const labels = {
      'todo': ('A fazer', AppColors.statusTodo),
      'in_progress': ('Em progresso', AppColors.statusInProgress),
      'review': ('Em revisão', AppColors.statusReview),
      'done': ('Concluído', AppColors.statusDone),
    };

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      children: columns.map((col) {
        final colTasks = tasks.where((t) => t['status'] == col).toList();
        final (label, color) = labels[col]!;
        return Container(
          width: 260,
          margin: const EdgeInsets.only(right: AppSpacing.sp12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sp10),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.cTextPrimary)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('${colTasks.length}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ]),
              ),
              // Cards
              Expanded(
                child: colTasks.isEmpty
                    ? Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: color.withValues(alpha: 0.2),
                              style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Text('Nenhuma tarefa',
                              style: TextStyle(
                                  fontSize: 12, color: context.cTextMuted)),
                        ),
                      )
                    : ListView(
                        children: colTasks.asMap().entries.map((e) {
                          final i = e.key;
                          final t = e.value;
                          return _KanbanCard(task: t)
                              .animate()
                              .fadeIn(delay: (i * 40).ms, duration: 250.ms);
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _KanbanCard extends StatefulWidget {
  final Map<String, dynamic> task;
  const _KanbanCard({required this.task});

  @override
  State<_KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<_KanbanCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final priority = t['priority'] as String? ?? 'medium';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/tasks/${t['id']}'),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
          padding: const EdgeInsets.all(AppSpacing.sp12),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _hovering
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : (context.isDark ? AppColors.borderDark : AppColors.border),
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t['title'] as String? ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.cTextPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sp8),
              Row(children: [
                PriorityTag(priority: priority),
                const Spacer(),
                if (_hovering)
                  Icon(Icons.open_in_new_rounded,
                      size: 13, color: context.cTextMuted),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Estado vazio de tarefas ───────────────────────────────────
class _EmptyTasksState extends StatelessWidget {
  final String projectId;
  const _EmptyTasksState({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.assignment_outlined,
            size: 56, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('Nenhuma tarefa neste projeto',
            style: context.bodyMd.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Vá em Tarefas → crie ou edite uma tarefa\ne atribua-a a este projeto',
          style: context.bodySm.copyWith(color: context.cTextMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FlowButton(
          label: 'Ir para Tarefas',
          leadingIcon: Icons.check_box_outline_blank_rounded,
          variant: FlowButtonVariant.outline,
          onPressed: () => context.go('/tasks'),
        ),
      ]),
    );
  }
}
