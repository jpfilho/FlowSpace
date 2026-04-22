import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../../shared/widgets/common/flow_tags.dart';
import '../../auth/domain/data_providers.dart';
import '../../auth/domain/auth_provider.dart';
import 'edit_task_sheet.dart';
import 'task_attachments_widget.dart';
import 'widgets/task_5w2h_section.dart';

// ── Providers locais ─────────────────────────────────────────

/// Carrega detalhes completos de uma tarefa incluindo projeto e autor
final taskDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, taskId) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('tasks')
      .select(
          'id, title, description, status, priority, due_date, created_at, updated_at, project_id, assignee_id, created_by, projects(name, status)')
      .eq('id', taskId)
      .maybeSingle();
  return data;
});

/// Subtarefas (tasks com parent_id = taskId)
final subtasksProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, taskId) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('tasks')
      .select('id, title, status, priority')
      .eq('parent_id', taskId)
      .order('created_at', ascending: true);
  return (data as List).cast<Map<String, dynamic>>();
});

/// Comentários da tarefa
final taskCommentsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, taskId) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('task_comments')
      .select('id, content, created_at, author_id, profiles(name, avatar_url)')
      .eq('task_id', taskId)
      .order('created_at', ascending: true);
  return (data as List).cast<Map<String, dynamic>>();
});

// ── Página Principal ─────────────────────────────────────────
class TaskDetailPage extends ConsumerWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor:
            context.isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/tasks'),
          color: context.cTextPrimary,
        ),
        title: taskAsync.when(
          data: (task) => Text(
            task?['title'] as String? ?? 'Tarefa',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const Text('Carregando...'),
          error: (_, __) => const Text('Erro'),
        ),
        actions: [
          taskAsync.when(
            data: (task) => task != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar tarefa',
                    color: AppColors.primary,
                    onPressed: () {
                      final td = TaskData(
                        id: task['id'] as String,
                        title: task['title'] as String,
                        status: task['status'] as String? ?? 'todo',
                        priority: task['priority'] as String? ?? 'medium',
                        projectId: task['project_id'] as String?,
                        projectName: task['projects'] != null
                            ? (task['projects']
                                as Map<String, dynamic>)['name'] as String?
                            : null,
                        assigneeId: task['assignee_id'] as String?,
                        dueDate: task['due_date'] != null
                            ? DateTime.parse(task['due_date'] as String)
                            : null,
                      );
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => EditTaskSheet(task: td),
                      ).then((_) =>
                          // ignore: unused_result
                          ref.refresh(taskDetailProvider(taskId)));
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: context.isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      body: taskAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Erro ao carregar tarefa', style: context.bodyMd),
            const SizedBox(height: 8),
            Text('$e',
                style: context.bodySm
                    .copyWith(color: context.cTextMuted),
                textAlign: TextAlign.center),
          ]),
        ),
        data: (task) => task == null
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.find_in_page_outlined,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('Tarefa não encontrada', style: context.bodyMd),
                  const SizedBox(height: 16),
                  FlowButton(
                    label: 'Voltar',
                    onPressed: () => context.go('/tasks'),
                    variant: FlowButtonVariant.outline,
                  ),
                ]),
              )
            : _TaskDetailBody(taskId: taskId, task: task),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────
class _TaskDetailBody extends ConsumerWidget {
  final String taskId;
  final Map<String, dynamic> task;

  const _TaskDetailBody({required this.taskId, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final status = task['status'] as String? ?? 'todo';
    final priority = task['priority'] as String? ?? 'medium';
    final dueDate = task['due_date'] != null
        ? DateTime.parse(task['due_date'] as String)
        : null;
    final projectName = task['projects'] != null
        ? (task['projects'] as Map<String, dynamic>)['name'] as String?
        : null;
    final description = task['description'] as String?;
    final isOverdue =
        dueDate != null && dueDate.isBefore(DateTime.now()) && status != 'done';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main column
        Expanded(
          flex: isDesktop ? 3 : 1,
          child: ListView(
            padding: EdgeInsets.all(
                isDesktop ? AppSpacing.sp32 : AppSpacing.sp20),
            children: [
              // ── Status + Priority bar
              Wrap(
                spacing: AppSpacing.sp8,
                runSpacing: AppSpacing.sp8,
                children: [
                  StatusTag(status: status),
                  PriorityTag(priority: priority),
                  if (projectName != null)
                    _InfoChip(
                      icon: Icons.folder_rounded,
                      label: projectName,
                      color: AppColors.primary,
                    ),
                  if (dueDate != null)
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}',
                      color: isOverdue ? AppColors.error : AppColors.success,
                    ),
                ],
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppSpacing.sp24),

              // ── Título
              Text(
                task['title'] as String,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                  height: 1.3,
                ),
              ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
              const SizedBox(height: AppSpacing.sp20),

              // ── Descrição
              _DescriptionSection(taskId: taskId, description: description),
              const SizedBox(height: AppSpacing.sp24),

              // ── Labels / Etiquetas
              _LabelsSection(taskId: taskId),
              const SizedBox(height: AppSpacing.sp32),

              // ── 5W2H
              Task5w2hSection(taskId: taskId),
              const SizedBox(height: AppSpacing.sp32),

              // ── Subtarefas
              _SubtasksSection(taskId: taskId),
              const SizedBox(height: AppSpacing.sp32),

              // ── Anexos
              AttachmentsSection(taskId: taskId),
              const SizedBox(height: AppSpacing.sp32),

              // ── Comentários
              _CommentsSection(taskId: taskId),
            ],
          ),
        ),

        // ── Sidebar (desktop only)
        if (isDesktop)
          Container(
            width: 260,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                ),
              ),
            ),
            child: _TaskSidebar(taskId: taskId, task: task),
          ),
      ],
    );
  }
}

// ── Seção Descrição ──────────────────────────────────────────
class _DescriptionSection extends ConsumerStatefulWidget {
  final String taskId;
  final String? description;
  const _DescriptionSection(
      {required this.taskId, required this.description});

  @override
  ConsumerState<_DescriptionSection> createState() =>
      _DescriptionSectionState();
}

class _DescriptionSectionState
    extends ConsumerState<_DescriptionSection> {
  bool _editing = false;
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.description ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final client = ref.read(supabaseProvider);
    await client.from('tasks').update({
      'description': _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', widget.taskId);
    setState(() {
      _saving = false;
      _editing = false;
    });
    // ignore: unused_result
    ref.refresh(taskDetailProvider(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Descrição',
              style: context.bodyMd
                  .copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          if (!_editing)
            InkWell(
              onTap: () => setState(() => _editing = true),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Row(children: [
                  Icon(Icons.edit_outlined,
                      size: 14, color: context.cTextMuted),
                  const SizedBox(width: 4),
                  Text('Editar',
                      style: TextStyle(
                          fontSize: 12, color: context.cTextMuted)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: AppSpacing.sp8),
        if (_editing) ...[
          TextField(
            controller: _ctrl,
            maxLines: 6,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Adicione uma descrição...',
              alignLabelWithHint: true,
            ),
            style: TextStyle(
                fontSize: 14, color: context.cTextPrimary, height: 1.6),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Row(children: [
            FlowButton(
              label: 'Cancelar',
              onPressed: () {
                setState(() {
                  _editing = false;
                  _ctrl.text = widget.description ?? '';
                });
              },
              variant: FlowButtonVariant.ghost,
            ),
            const SizedBox(width: 8),
            FlowButton(
              label: _saving ? 'Salvando...' : 'Salvar',
              onPressed: _saving ? null : _save,
            ),
          ]),
        ] else
          widget.description == null || widget.description!.trim().isEmpty
              ? InkWell(
                  onTap: () => setState(() => _editing = true),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sp16),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: context.isDark
                            ? AppColors.borderDark
                            : AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Text(
                      'Clique para adicionar uma descrição...',
                      style: context.bodySm
                          .copyWith(color: context.cTextMuted),
                    ),
                  ),
                )
              : Text(
                  widget.description!,
                  style: TextStyle(
                      fontSize: 14,
                      color: context.cTextPrimary,
                      height: 1.7),
                ),
      ],
    );
  }
}

// ── Seção Subtarefas ─────────────────────────────────────────
class _SubtasksSection extends ConsumerStatefulWidget {
  final String taskId;
  const _SubtasksSection({required this.taskId});

  @override
  ConsumerState<_SubtasksSection> createState() =>
      _SubtasksSectionState();
}

class _SubtasksSectionState extends ConsumerState<_SubtasksSection> {
  bool _adding = false;
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _addSubtask() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final workspace =
        await ref.read(currentWorkspaceProvider.future);
    final user = ref.read(currentUserProvider);
    if (workspace == null || user == null) {
      setState(() => _saving = false);
      return;
    }

    final client = ref.read(supabaseProvider);
    await client.from('tasks').insert({
      'workspace_id': workspace.id,
      'parent_id': widget.taskId,
      'title': _ctrl.text.trim(),
      'status': 'todo',
      'priority': 'medium',
      'created_by': user.id,
      'assignee_id': user.id,
    });

    _ctrl.clear();
    setState(() {
      _saving = false;
      _adding = false;
    });
    // ignore: unused_result
    ref.refresh(subtasksProvider(widget.taskId));
  }

  Future<void> _toggleSubtask(String subId, String currentStatus) async {
    final newStatus = currentStatus == 'done' ? 'todo' : 'done';
    final client = ref.read(supabaseProvider);
    await client.from('tasks').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', subId);
    // ignore: unused_result
    ref.refresh(subtasksProvider(widget.taskId));
  }

  Future<void> _deleteSubtask(String subId) async {
    final client = ref.read(supabaseProvider);
    await client.from('tasks').delete().eq('id', subId);
    // ignore: unused_result
    ref.refresh(subtasksProvider(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(subtasksProvider(widget.taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.checklist_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Subtarefas',
              style: context.bodyMd
                  .copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          subtasksAsync.when(
            data: (subs) {
              final done = subs.where((s) => s['status'] == 'done').length;
              return subs.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      '$done/${subs.length}',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.cTextMuted,
                          fontWeight: FontWeight.w600),
                    );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _adding = !_adding),
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(children: [
                const Icon(Icons.add_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Adicionar',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.sp12),

        // Progress bar for subtasks
        subtasksAsync.maybeWhen(
          data: (subs) {
            if (subs.isEmpty) return const SizedBox.shrink();
            final done =
                subs.where((s) => s['status'] == 'done').length;
            final progress = done / subs.length;
            return Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: AppSpacing.sp12),
            ]);
          },
          orElse: () => const SizedBox.shrink(),
        ),

        // Add subtask input
        if (_adding) ...[
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addSubtask(),
                decoration: const InputDecoration(
                  hintText: 'Nome da subtarefa...',
                  isDense: true,
                  prefixIcon:
                      Icon(Icons.radio_button_unchecked_rounded, size: 16),
                ),
                style: TextStyle(
                    fontSize: 14, color: context.cTextPrimary),
              ),
            ),
            const SizedBox(width: 8),
            FlowButton(
              label: _saving ? '...' : 'Adicionar',
              onPressed: _saving ? null : _addSubtask,
            ),
          ]),
          const SizedBox(height: AppSpacing.sp12),
        ],

        // Subtask list
        subtasksAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)),
          error: (_, __) => Text('Erro ao carregar subtarefas',
              style: context.bodySm
                  .copyWith(color: AppColors.error)),
          data: (subs) => subs.isEmpty && !_adding
              ? Text(
                  'Nenhuma subtarefa. Clique em "Adicionar" para criar.',
                  style:
                      context.bodySm.copyWith(color: context.cTextMuted),
                )
              : Column(
                  children: subs
                      .map((s) => _SubtaskTile(
                            sub: s,
                            onToggle: () =>
                                _toggleSubtask(s['id'] as String,
                                    s['status'] as String),
                            onDelete: () =>
                                _deleteSubtask(s['id'] as String),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  final Map<String, dynamic> sub;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubtaskTile(
      {required this.sub,
      required this.onToggle,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDone = sub['status'] == 'done';
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(
            isDone
                ? Icons.task_alt_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isDone ? AppColors.success : context.cTextMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sub['title'] as String,
              style: TextStyle(
                fontSize: 14,
                color: isDone ? context.cTextMuted : context.cTextPrimary,
                decoration:
                    isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          PriorityTag(priority: sub['priority'] as String? ?? 'medium'),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 14),
            onPressed: onDelete,
            color: context.cTextMuted,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ]),
      ),
    );
  }
}

// ── Seção Comentários ────────────────────────────────────────
class _CommentsSection extends ConsumerStatefulWidget {
  final String taskId;
  const _CommentsSection({required this.taskId});

  @override
  ConsumerState<_CommentsSection> createState() =>
      _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _saving = false);
      return;
    }
    final client = ref.read(supabaseProvider);
    await client.from('task_comments').insert({
      'task_id': widget.taskId,
      'author_id': user.id,
      'content': _ctrl.text.trim(),
    });
    _ctrl.clear();
    setState(() => _saving = false);
    // ignore: unused_result
    ref.refresh(taskCommentsProvider(widget.taskId));
  }

  Future<void> _deleteComment(String commentId) async {
    final client = ref.read(supabaseProvider);
    await client.from('task_comments').delete().eq('id', commentId);
    // ignore: unused_result
    ref.refresh(taskCommentsProvider(widget.taskId));
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync =
        ref.watch(taskCommentsProvider(widget.taskId));
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Comentários',
              style: context.bodyMd
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          commentsAsync.maybeWhen(
            data: (c) => c.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('${c.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ]),
        const SizedBox(height: AppSpacing.sp16),

        // Comment list
        commentsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)),
          error: (_, __) => Text('Erro ao carregar comentários',
              style: context.bodySm
                  .copyWith(color: AppColors.error)),
          data: (comments) => Column(
            children: comments
                .map((c) => _CommentTile(
                      comment: c,
                      isOwn: c['author_id'] == currentUser?.id,
                      onDelete: () =>
                          _deleteComment(c['id'] as String),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sp16),

        // New comment input
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Escreva um comentário...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: context.isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariant,
                ),
                style: TextStyle(
                    fontSize: 14, color: context.cTextPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.sp8),
            SizedBox(
              height: 44,
              child: FlowButton(
                label: '',
                leadingIcon: _saving
                    ? null
                    : Icons.send_rounded,
                onPressed: _saving ? null : _postComment,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final bool isOwn;
  final VoidCallback onDelete;

  const _CommentTile(
      {required this.comment,
      required this.isOwn,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final profile = comment['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'Usuário';
    final createdAt = DateTime.parse(comment['created_at'] as String);
    final timeStr =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp12),
      padding: const EdgeInsets.all(AppSpacing.sp14),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isOwn
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOwn ? 'Você' : name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.cTextPrimary)),
                  Text(timeStr,
                      style: TextStyle(
                          fontSize: 11, color: context.cTextMuted)),
                ]),
          ),
          if (isOwn)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 14),
              onPressed: onDelete,
              color: AppColors.error,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ]),
        const SizedBox(height: AppSpacing.sp8),
        Text(
          comment['content'] as String,
          style: TextStyle(
              fontSize: 14, color: context.cTextPrimary, height: 1.6),
        ),
      ]),
    );
  }
}

// ── Sidebar de detalhes (Desktop) ────────────────────────────
class _TaskSidebar extends ConsumerWidget {
  final String taskId;
  final Map<String, dynamic> task;
  const _TaskSidebar({required this.taskId, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = task['created_at'] != null
        ? DateTime.parse(task['created_at'] as String)
        : null;
    final updatedAt = task['updated_at'] != null
        ? DateTime.parse(task['updated_at'] as String)
        : null;
    final dueDate = task['due_date'] != null
        ? DateTime.parse(task['due_date'] as String)
        : null;
    final status = task['status'] as String? ?? 'todo';
    final priority = task['priority'] as String? ?? 'medium';

    String fmt(DateTime? d) {
      if (d == null) return '—';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      children: [
        Text('Detalhes',
            style: context.bodyMd.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sp16),

        // Status — popup para edição rápida
        _SidebarRow(
          label: 'Status',
          child: PopupMenuButton<String>(
            tooltip: 'Alterar status',
            padding: EdgeInsets.zero,
            onSelected: (val) async {
              await ref.read(tasksProvider.notifier).updateStatus(taskId, val);
              // ignore: unused_result
              ref.refresh(taskDetailProvider(taskId));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'todo',        child: Text('A fazer')),
              PopupMenuItem(value: 'in_progress', child: Text('Em progresso')),
              PopupMenuItem(value: 'review',      child: Text('Revisão')),
              PopupMenuItem(value: 'done',        child: Text('Concluído')),
              PopupMenuItem(value: 'cancelled',   child: Text('Cancelado')),
            ],
            child: StatusTag(status: status),
          ),
        ),

        // Prioridade — popup para edição rápida
        _SidebarRow(
          label: 'Prioridade',
          child: PopupMenuButton<String>(
            tooltip: 'Alterar prioridade',
            padding: EdgeInsets.zero,
            onSelected: (val) async {
              await ref.read(tasksProvider.notifier).updateTask(
                    taskId: taskId, priority: val);
              // ignore: unused_result
              ref.refresh(taskDetailProvider(taskId));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'urgent', child: Text('🔴 Urgente')),
              PopupMenuItem(value: 'high',   child: Text('🟠 Alta')),
              PopupMenuItem(value: 'medium', child: Text('🔵 Média')),
              PopupMenuItem(value: 'low',    child: Text('⚪ Baixa')),
            ],
            child: PriorityTag(priority: priority),
          ),
        ),

        // Data de vencimento — date picker inline
        _SidebarRow(
          label: 'Vencimento',
          child: _DueDateSidebarCell(
            taskId: taskId,
            dueDate: dueDate,
            onChanged: () => ref.refresh(taskDetailProvider(taskId)),
          ),
        ),

        // Projeto
        _SidebarRow(
          label: 'Projeto',
          child: task['projects'] != null
              ? Text(
                  (task['projects'] as Map<String, dynamic>)['name']
                          as String? ?? '—',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500),
                )
              : Text('Sem projeto',
                  style: TextStyle(fontSize: 13, color: context.cTextMuted)),
        ),

        _SidebarRow(
          label: 'Criado em',
          child: Text(fmt(createdAt),
              style: TextStyle(fontSize: 13, color: context.cTextMuted)),
        ),
        _SidebarRow(
          label: 'Atualizado',
          child: Text(fmt(updatedAt),
              style: TextStyle(fontSize: 13, color: context.cTextMuted)),
        ),
        const SizedBox(height: AppSpacing.sp24),

        // Quick actions
        Text('Ações rápidas',
            style: context.bodyMd.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sp12),
        if (task['status'] != 'done')
          FlowButton(
            label: 'Marcar como concluído',
            leadingIcon: Icons.task_alt_rounded,
            onPressed: () async {
              await ref.read(tasksProvider.notifier).updateStatus(taskId, 'done');
              // ignore: unused_result
              ref.refresh(taskDetailProvider(taskId));
            },
          ),
        if (task['status'] == 'done') ...[          
          FlowButton(
            label: 'Reabrir tarefa',
            leadingIcon: Icons.replay_rounded,
            variant: FlowButtonVariant.outline,
            onPressed: () async {
              await ref.read(tasksProvider.notifier).updateStatus(taskId, 'todo');
              // ignore: unused_result
              ref.refresh(taskDetailProvider(taskId));
            },
          ),
        ],
      ],
    );
  }
}

// ── Célula de data de vencimento (sidebar) ────────────────────
class _DueDateSidebarCell extends ConsumerWidget {
  final String taskId;
  final DateTime? dueDate;
  final VoidCallback onChanged;
  const _DueDateSidebarCell(
      {required this.taskId, required this.dueDate, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = dueDate != null &&
        DateTime(dueDate!.year, dueDate!.month, dueDate!.day).isBefore(today);
    final color = dueDate == null
        ? context.cTextMuted
        : (isOverdue ? AppColors.error : AppColors.success);

    return Row(children: [
      Expanded(
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate ?? now,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(days: 365 * 3)),
              helpText: 'Data de vencimento',
              confirmText: 'Confirmar',
              cancelText: 'Cancelar',
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme:
                      const ColorScheme.light(primary: AppColors.primary),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              await ref
                  .read(tasksProvider.notifier)
                  .updateTask(taskId: taskId, dueDate: picked);
              onChanged();
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                dueDate != null
                    ? '${dueDate!.day.toString().padLeft(2, '0')}/${dueDate!.month.toString().padLeft(2, '0')}/${dueDate!.year}'
                    : 'Definir data',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight:
                      dueDate != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ]),
          ),
        ),
      ),
      if (dueDate != null)
        GestureDetector(
          onTap: () async {
            await ref
                .read(tasksProvider.notifier)
                .updateTask(taskId: taskId, clearDueDate: true);
            onChanged();
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.close_rounded,
                size: 13, color: context.cTextMuted),
          ),
        ),
    ]);
  }
}

class _SidebarRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SidebarRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: context.bodySm.copyWith(color: context.cTextMuted)),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Chip de informação inline ────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Labels / Etiquetas ───────────────────────────────────────
class _LabelsSection extends ConsumerWidget {
  final String taskId;
  const _LabelsSection({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLabelsAsync = ref.watch(taskLabelsProvider(taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label_outline_rounded,
                size: 16, color: context.cTextMuted),
            const SizedBox(width: 6),
            Text('Etiquetas', style: context.labelMd),
            const Spacer(),
            InkWell(
              onTap: () => _showLabelPicker(context, ref),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add_rounded,
                    size: 18, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        taskLabelsAsync.when(
          loading: () => const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)),
          error: (e, _) => Text('Erro: $e',
              style: TextStyle(color: AppColors.error, fontSize: 12)),
          data: (labels) => labels.isEmpty
              ? Text('Sem etiquetas',
                  style: context.bodySm
                      .copyWith(color: context.cTextMuted))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: labels.map((l) => _LabelChip(
                        label: l,
                        onRemove: () async {
                          final client = ref.read(supabaseProvider);
                          await removeLabelFromTask(
                              client, taskId, l.id);
                          // ignore: unused_result
                          ref.refresh(taskLabelsProvider(taskId));
                        },
                      )).toList(),
                ),
        ),
      ],
    );
  }

  void _showLabelPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _LabelPickerDialog(taskId: taskId),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final LabelData label;
  final VoidCallback onRemove;

  const _LabelChip({required this.label, required this.onRemove});

  Color get _color {
    try {
      return Color(
          int.parse(label.color.replaceFirst('#', ''), radix: 16) |
              0xFF000000);
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: _color),
          ),
        ],
      ),
    );
  }
}

// ── Label Picker Dialog ──────────────────────────────────────
class _LabelPickerDialog extends ConsumerStatefulWidget {
  final String taskId;
  const _LabelPickerDialog({required this.taskId});

  @override
  ConsumerState<_LabelPickerDialog> createState() =>
      _LabelPickerDialogState();
}

class _LabelPickerDialogState
    extends ConsumerState<_LabelPickerDialog> {
  final _nameCtrl = TextEditingController();
  bool _creating = false;
  int _selectedColorIdx = 0;

  static const _colors = [
    '#5B6AF3', '#EF4444', '#F59E0B', '#10B981',
    '#8B5CF6', '#EC4899', '#06B6D4', '#F97316',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createLabel() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      final label = await ref
          .read(labelsProvider.notifier)
          .create(name, _colors[_selectedColorIdx]);
      // Auto-assign to task
      final client = ref.read(supabaseProvider);
      await addLabelToTask(client, widget.taskId, label.id);
      // ignore: unused_result
      ref.refresh(taskLabelsProvider(widget.taskId));
      _nameCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLabels = ref.watch(labelsProvider);
    final taskLabelsAsync = ref.watch(taskLabelsProvider(widget.taskId));
    final assignedIds = taskLabelsAsync.valueOrNull
            ?.map((l) => l.id)
            .toSet() ??
        {};

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.label_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Etiquetas'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create new
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nova etiqueta...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _createLabel(),
                  ),
                ),
                const SizedBox(width: 8),
                _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _createLabel,
                        icon: const Icon(Icons.add_circle_rounded,
                            color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            // Color picker
            Row(
              children: _colors.asMap().entries.map((e) {
                final i = e.key;
                final hex = e.value;
                final c = Color(
                    int.parse(hex.replaceFirst('#', ''), radix: 16) |
                        0xFF000000);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIdx = i),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _selectedColorIdx == i
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: _selectedColorIdx == i
                          ? [
                              BoxShadow(
                                  color: c.withValues(alpha: 0.5),
                                  blurRadius: 6)
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 20),
            // Existing labels
            Text('Etiquetas do workspace',
                style: context.labelMd
                    .copyWith(color: context.cTextMuted)),
            const SizedBox(height: 8),
            allLabels.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
              error: (e, _) => Text('Erro: $e'),
              data: (labels) => labels.isEmpty
                  ? Text('Nenhuma etiqueta ainda.',
                      style: context.bodySm)
                  : ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: labels.length,
                        itemBuilder: (ctx, i) {
                          final l = labels[i];
                          final assigned =
                              assignedIds.contains(l.id);
                          final c = Color(int.parse(
                                  l.color
                                      .replaceFirst('#', ''),
                                  radix: 16) |
                              0xFF000000);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(l.name,
                                style: const TextStyle(
                                    fontSize: 13)),
                            trailing: assigned
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 20)
                                : const Icon(
                                    Icons
                                        .radio_button_unchecked_rounded,
                                    size: 20),
                            onTap: () async {
                              final client =
                                  ref.read(supabaseProvider);
                              if (assigned) {
                                await removeLabelFromTask(
                                    client,
                                    widget.taskId,
                                    l.id);
                              } else {
                                await addLabelToTask(
                                    client,
                                    widget.taskId,
                                    l.id);
                              }
                              // ignore: unused_result
                              ref.refresh(
                                  taskLabelsProvider(
                                      widget.taskId));
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
