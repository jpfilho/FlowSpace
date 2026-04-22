import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_tags.dart';
import '../../auth/domain/data_providers.dart';
import '../../tasks/presentation/edit_task_sheet.dart';
import 'weekly_review_wizard.dart';

class GtdPage extends ConsumerStatefulWidget {
  const GtdPage({super.key});

  @override
  ConsumerState<GtdPage> createState() => _GtdPageState();
}

class _GtdPageState extends ConsumerState<GtdPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final inboxAsync = ref.watch(gtdInboxProvider);
    final somedayAsync = ref.watch(somedayTasksProvider);

    final areas = [
      _GtdArea('Inbox', Icons.inbox_rounded, AppColors.primary,
          inboxAsync.valueOrNull?.length ?? 0, 'Ideias e capturas'),
      _GtdArea('Próximas ações', Icons.play_arrow_rounded, AppColors.success,
          ref.watch(tasksProvider).valueOrNull?.where((t) => t.status == 'todo' && !t.isSomeday).length ?? 0,
          'Ações concretas'),
      _GtdArea('Em progresso', Icons.pending_actions_rounded, AppColors.accent,
          ref.watch(tasksProvider).valueOrNull?.where((t) => t.status == 'in_progress').length ?? 0,
          'Trabalhando agora'),
      _GtdArea('Aguardando', Icons.hourglass_empty_rounded, AppColors.warning,
          ref.watch(tasksProvider).valueOrNull?.where((t) => t.status == 'review').length ?? 0,
          'Deleguei / revisão'),
      _GtdArea('Algum dia', Icons.wb_cloudy_outlined, AppColors.textMuted,
          somedayAsync.valueOrNull?.length ?? 0,
          'Talvez futuramente'),
    ];

    return Scaffold(
      backgroundColor: context.cBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sp24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('GTD — Getting Things Done',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sp4),
              Text('Capture, esclareça, organize, reflita e execute.',
                  style: context.bodySm),
              const SizedBox(height: AppSpacing.sp24),

              // Weekly Review Banner
              _WeeklyReviewBanner()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, duration: 400.ms),

              const SizedBox(height: AppSpacing.sp24),

              // Quick capture
              _InboxCapture()
                  .animate()
                  .fadeIn(duration: 350.ms),

              const SizedBox(height: AppSpacing.sp28),

              // GTD Areas
              Row(children: [
                Text('Horizontes GTD', style: context.headingMd),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 18, color: context.cTextMuted),
                  onPressed: () {
                // ignore: unused_result
                ref.refresh(gtdInboxProvider);
                // ignore: unused_result
                ref.refresh(tasksProvider);
                  },
                  tooltip: 'Atualizar',
                ),
              ]),
              const SizedBox(height: AppSpacing.sp12),
              Wrap(
                spacing: AppSpacing.sp12,
                runSpacing: AppSpacing.sp12,
                children: areas.asMap().entries.map((e) => SizedBox(
                  width: Responsive.isDesktop(context) ? 280 : double.infinity,
                  child: _GtdAreaCard(
                    area: e.value,
                    isSelected: _tabIndex == e.key,
                    onTap: () => setState(() => _tabIndex = e.key),
                  ).animate().fadeIn(delay: (e.key * 50).ms, duration: 300.ms),
                )).toList(),
              ),

              const SizedBox(height: AppSpacing.sp28),

              // ── Dynamic Horizon Content ───────────────────────────
              if (_tabIndex == 0) ...[
                // Inbox items
                Row(children: [
                  Text('Inbox — itens pendentes', style: context.headingMd),
                  const SizedBox(width: AppSpacing.sp8),
                  inboxAsync.when(
                    data: (items) => FlowBadge(count: items.length, color: AppColors.primary),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]),
                const SizedBox(height: AppSpacing.sp12),
                inboxAsync.when(
                  data: (items) => items.isEmpty
                      ? _EmptyInbox()
                      : Column(
                          children: items.asMap().entries
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
                                    child: _InboxItemCard(item: e.value)
                                        .animate()
                                        .fadeIn(delay: (e.key * 40).ms, duration: 280.ms),
                                  ))
                              .toList(),
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Text('Erro: $e', style: TextStyle(color: AppColors.error)),
                ),
              ] else if (_tabIndex == 1) ...[
                _TasksFilteredSection(status: 'todo', title: 'Próximas ações', icon: Icons.play_arrow_rounded, color: AppColors.success),
              ] else if (_tabIndex == 2) ...[
                _TasksFilteredSection(status: 'in_progress', title: 'Em progresso', icon: Icons.pending_actions_rounded, color: AppColors.accent),
              ] else if (_tabIndex == 3) ...[
                _TasksFilteredSection(status: 'review', title: 'Aguardando', icon: Icons.hourglass_empty_rounded, color: AppColors.warning),
              ] else if (_tabIndex == 4) ...[
                // Algum dia
                _SomedaySection(),
              ],

              const SizedBox(height: AppSpacing.sp40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Captura rápida conectada ao banco ────────────────────────
class _InboxCapture extends ConsumerStatefulWidget {
  @override
  ConsumerState<_InboxCapture> createState() => _InboxCaptureState();
}

class _InboxCaptureState extends ConsumerState<_InboxCapture> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _error = 'Digite algo para capturar');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final err = await ref.read(gtdInboxProvider.notifier).capture(_ctrl.text);

    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        setState(() => _error = err);
      } else {
        _ctrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.inbox_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Capturado com sucesso!'),
            ]),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inbox_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sp8),
            Text('Captura rápida', style: context.headingMd),
            const Spacer(),
            Text('Inbox', style: AppTypography.caption(AppColors.primary)
                .copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: AppSpacing.sp12),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _capture(),
                decoration: InputDecoration(
                  hintText: 'O que está na sua cabeça? Capture agora...',
                  hintStyle: AppTypography.body(context.cTextMuted),
                  errorText: _error,
                  filled: true,
                  fillColor: context.isDark ? AppColors.surfaceDark : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp12,
                    vertical: AppSpacing.sp10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sp12),

            ElevatedButton(
              onPressed: _loading ? null : _capture,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp16,
                  vertical: AppSpacing.sp12,
                ),
                minimumSize: const Size(0, 46),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Capturar'),
            ),
          ]),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            '💡 Dica: Capture tudo agora, processe depois.',
            style: AppTypography.caption(context.cTextMuted),
          ),
        ],
      ),
    );
  }
}

// ── Inbox item card ──────────────────────────────────────────
class _InboxItemCard extends ConsumerStatefulWidget {
  final InboxItem item;
  const _InboxItemCard({required this.item});

  @override
  ConsumerState<_InboxItemCard> createState() => _InboxItemCardState();
}

class _InboxItemCardState extends ConsumerState<_InboxItemCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
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
        child: Row(children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.content,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: context.cTextPrimary,
                    )),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(widget.item.createdAt),
                  style: AppTypography.caption(context.cTextMuted),
                ),
              ],
            ),
          ),
          if (_hovering)
            Row(children: [
              // Process button
              Tooltip(
                message: 'Converter em tarefa',
                child: IconButton(
                  icon: const Icon(Icons.add_task_rounded,
                      size: 18, color: AppColors.success),
                  onPressed: () async {
                    // mark as processed + create task
                    await ref.read(gtdInboxProvider.notifier)
                        .markProcessed(widget.item.id);
                    final result = await ref.read(tasksProvider.notifier).createTask(
                      title: widget.item.content,
                    );
                    if (!context.mounted) return;
                    if (result.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.error!),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    // Busca a tarefa recém-criada e abre o editor
                    final tasks = ref.read(tasksProvider).valueOrNull ?? [];
                    final newTask = tasks.where((t) => t.id == result.id).firstOrNull;
                    if (newTask != null) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => EditTaskSheet(task: newTask),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Convertido em tarefa!'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Dismiss button
              Tooltip(
                message: 'Descartar',
                child: IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: context.cTextMuted),
                  onPressed: () async {
                    await ref
                        .read(gtdInboxProvider.notifier)
                        .markProcessed(widget.item.id);
                  },
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    return 'Há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
  }
}

class _EmptyInbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp32),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: context.isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(children: [
        const Icon(Icons.check_circle_outline_rounded,
            size: 40, color: AppColors.success),
        const SizedBox(height: AppSpacing.sp12),
        Text('Inbox vazio! 🎉',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
        const SizedBox(height: AppSpacing.sp4),
        Text('Capture novas ideias acima.',
            style: context.bodySm, textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Seção Dinâmica de Tarefas ────────────────────────────────
class _TasksFilteredSection extends ConsumerWidget {
  final String status;
  final String title;
  final IconData icon;
  final Color color;

  const _TasksFilteredSection({
    required this.status,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.sp10),
          Text(title, style: context.headingMd),
          const Spacer(),
        ]),
        const SizedBox(height: AppSpacing.sp8),
        Text(
          'Tarefas ativas agrupadas neste horizonte.',
          style: context.bodySm.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.sp12),

        tasksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.sp24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text('Erro: $e', style: TextStyle(color: AppColors.error)),
          data: (tasks) {
            final filtered = tasks.where((t) => t.status == status && !t.isSomeday).toList();
            if (filtered.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp24),
                decoration: BoxDecoration(
                  color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: context.isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.done_all_rounded, size: 36, color: context.cTextMuted),
                    const SizedBox(height: AppSpacing.sp12),
                    Text('Tudo limpo!',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: context.cTextPrimary,
                        )),
                  ]
                ),
              );
            }
            return Column(
              children: filtered.asMap().entries.map((e) {
                final task = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
                  child: _FilteredTaskTile(task: task)
                      .animate()
                      .fadeIn(delay: (e.key * 40).ms, duration: 280.ms),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _FilteredTaskTile extends ConsumerWidget {
  final TaskData task;
  const _FilteredTaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(children: [
        Icon(Icons.tag_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.cTextPrimary,
                  )),
              if (task.projectName != null)
                Text(task.projectName!,
                    style: TextStyle(fontSize: 11, color: context.cTextMuted)),
            ],
          ),
        ),
        if (task.priority == 'high' || task.priority == 'urgent')
          PriorityTag(priority: task.priority),
      ]),
    );
  }
}

// ── Seção "Algum dia / Talvez" ────────────────────────────────
class _SomedaySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final somedayAsync = ref.watch(somedayTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.wb_cloudy_outlined,
                color: AppColors.textMuted, size: 16),
          ),
          const SizedBox(width: AppSpacing.sp10),
          Text('Algum dia / Talvez', style: context.headingMd),
          const SizedBox(width: AppSpacing.sp8),
          somedayAsync.when(
            data: (items) => items.isNotEmpty
                ? FlowBadge(count: items.length, color: AppColors.textMuted)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Adicionar tarefa'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            onPressed: () => _showAddToSomedaySheet(context, ref),
          ),
        ]),
        const SizedBox(height: AppSpacing.sp8),
        Text(
          'Tarefas sem prazo definido que talvez queira fazer no futuro.',
          style: context.bodySm.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.sp12),

        somedayAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.sp24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Text('Erro: $e',
              style: TextStyle(color: AppColors.error)),
          data: (tasks) => tasks.isEmpty
              ? _EmptySomeday()
              : Column(
                  children: tasks.asMap().entries.map((e) {
                    final task = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
                      child: _SomedayTaskTile(task: task)
                          .animate()
                          .fadeIn(delay: (e.key * 40).ms, duration: 280.ms),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  void _showAddToSomedaySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToSomedaySheet(),
    );
  }
}

class _EmptySomeday extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp24),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(children: [
        Icon(Icons.wb_cloudy_outlined, size: 36, color: context.cTextMuted),
        const SizedBox(height: AppSpacing.sp12),
        Text('Nenhuma tarefa aqui ainda',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: context.cTextPrimary,
            )),
        const SizedBox(height: AppSpacing.sp4),
        Text(
          'Adicione tarefas que talvez queira fazer algum dia.',
          style: context.bodySm, textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _SomedayTaskTile extends ConsumerWidget {
  final TaskData task;
  const _SomedayTaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Row(children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: AppColors.textMuted.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.cTextPrimary,
                  )),
              if (task.projectName != null)
                Text(task.projectName!,
                    style: TextStyle(fontSize: 11, color: context.cTextMuted)),
            ],
          ),
        ),
        Tooltip(
          message: 'Mover para ações',
          child: IconButton(
            icon: const Icon(Icons.play_arrow_rounded,
                size: 18, color: AppColors.success),
            onPressed: () async {
              final err = await ref
                  .read(tasksProvider.notifier)
                  .setSomeday(task.id, false);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.error),
                );
              }
            },
          ),
        ),
        Tooltip(
          message: 'Remover do "Algum dia"',
          child: IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: context.cTextMuted),
            onPressed: () async {
              final err = await ref
                  .read(tasksProvider.notifier)
                  .setSomeday(task.id, false);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.error),
                );
              }
            },
          ),
        ),
      ]),
    );
  }
}

// ── Sheet: adicionar tarefa ao Algum dia ─────────────────────
class _AddToSomedaySheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddToSomedaySheet> createState() => _AddToSomedaySheetState();
}

class _AddToSomedaySheetState extends ConsumerState<_AddToSomedaySheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final tasks = tasksAsync.valueOrNull ?? [];

    final eligible = tasks
        .where((t) =>
            !t.isSomeday &&
            t.status != 'done' &&
            t.status != 'cancelled' &&
            (t.title.toLowerCase().contains(_search.toLowerCase())))
        .toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp20),
            child: Row(children: [
              Text('Adicionar ao "Algum dia"',
                  style: context.headingMd),
            ]),
          ),
          const SizedBox(height: AppSpacing.sp12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp20),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar tarefa...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                filled: true,
                fillColor: context.isDark
                    ? AppColors.backgroundDark
                    : AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp12, vertical: AppSpacing.sp10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: eligible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.sp24),
                    child: Text(
                      _search.isEmpty
                          ? 'Todas as tarefas ativas ja estao no "Algum dia"'
                          : 'Nenhuma tarefa encontrada',
                      style: TextStyle(color: context.cTextMuted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp20, vertical: AppSpacing.sp4),
                    itemCount: eligible.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sp4),
                    itemBuilder: (_, i) {
                      final t = eligible[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () async {
                          final err = await ref
                              .read(tasksProvider.notifier)
                              .setSomeday(t.id, true);
                          if (context.mounted) {
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(err),
                                backgroundColor: AppColors.error,
                              ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '"${t.title}" movida para Algum dia'),
                                  backgroundColor: AppColors.success,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp12,
                              vertical: AppSpacing.sp10),
                          child: Row(children: [
                            const Icon(Icons.wb_cloudy_outlined,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: AppSpacing.sp10),
                            Expanded(
                              child: Text(t.title,
                                  style: TextStyle(
                                    fontSize: 14, color: context.cTextPrimary)),
                            ),
                            if (t.projectName != null)
                              Text(t.projectName!,
                                  style: TextStyle(
                                      fontSize: 11, color: context.cTextMuted)),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.sp16),
        ],
      ),
    );
  }
}

class _GtdArea {
  final String name;
  final IconData icon;
  final Color color;
  final int count;
  final String description;

  const _GtdArea(this.name, this.icon, this.color, this.count, this.description);
}

class _GtdAreaCard extends StatefulWidget {
  final _GtdArea area;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _GtdAreaCard({
    required this.area,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_GtdAreaCard> createState() => _GtdAreaCardState();
}

class _GtdAreaCardState extends State<_GtdAreaCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.area;
    final isSelected = widget.isSelected;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppSpacing.sp20),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected 
                  ? a.color 
                  : (_hovering
                      ? a.color.withValues(alpha: 0.4)
                      : (context.isDark ? AppColors.borderDark : AppColors.border)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: a.color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(a.icon, color: a.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: context.cTextPrimary)),
                Text(a.description, style: context.bodySm.copyWith(fontSize: 12)),
              ],
            )),
            if (a.count > 0)
              FlowBadge(count: a.count, color: a.color),
          ]),
        ),
      ),
    );
  }
}

// ── Weekly Review Banner ──────────────────────────────────────
class _WeeklyReviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.loop_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revisão Semanal GTD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mantenha seu sistema atualizado. 6 etapas guiadas.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp16),
          FilledButton(
            onPressed: () => showWeeklyReview(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Iniciar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
