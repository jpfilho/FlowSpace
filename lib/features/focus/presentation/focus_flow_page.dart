import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/auth/domain/data_providers.dart';
import '../../../features/auth/domain/auth_provider.dart';
import '../../../features/members/presentation/members_page.dart'
    show workspaceMembersProvider, WorkspaceMember;
import '../../../shared/widgets/common/flow_tags.dart';
import '../domain/focus_providers.dart';

// ─────────────────────────────────────────────────────────────
// FOCUS FLOW PAGE
// ─────────────────────────────────────────────────────────────

class FocusFlowPage extends ConsumerStatefulWidget {
  const FocusFlowPage({super.key});

  @override
  ConsumerState<FocusFlowPage> createState() => _FocusFlowPageState();
}

class _FocusFlowPageState extends ConsumerState<FocusFlowPage> {
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusSessionProvider);
    final notifier = ref.read(focusSessionProvider.notifier);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    // ── Detecta conclusão da sessão ───────────────────────────
    ref.listen<FocusSessionState>(focusSessionProvider, (_, next) {
      if (!_navigating && next.isComplete && mounted) {
        setState(() => _navigating = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(AppRoutes.focusComplete);
        });
      }
    });

    if (session.tasks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.focusComplete);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Column(
        children: [
          // ── Barra de progresso + header ───────────────────
          _FocusProgressHeader(
            current: session.currentIndex,
            total: session.tasks.length,
          ),

          // ── Conteúdo principal ──────────────────────────
          Expanded(
            child: session.isComplete
                ? const SizedBox.shrink()
                : isDesktop
                    ? _DesktopLayout(
                        session: session,
                        notifier: notifier,
                      )
                    : _MobileLayout(
                        session: session,
                        notifier: notifier,
                        compact: !isTablet,
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Header ──────────────────────────────────────────

class _FocusProgressHeader extends StatelessWidget {
  final int current;
  final int total;

  const _FocusProgressHeader({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 1.0 : current / total;
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp20,
        vertical: AppSpacing.sp12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: AppSpacing.sp6),
              Text(
                'Focus Start',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                '$current / $total',
                style: AppTypography.body(context.cTextMuted)
                    .copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: context.isDark
                  ? AppColors.borderDark
                  : AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Layouts ──────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  final FocusSessionState session;
  final FocusSessionNotifier notifier;

  const _DesktopLayout({required this.session, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // ── Sidebar com lista restante ──────────────────
        SizedBox(
          width: 240,
          child: _TaskSidebar(session: session),
        ),
        Container(
          width: 1,
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
        // ── Card principal ──────────────────────────────
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.sp32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _FocusTaskCard(
                  focusTask: session.currentTask!,
                  notifier: notifier,
                  compact: false,
                ).animate().fadeIn(duration: 250.ms).slideY(
                      begin: 0.04, end: 0, duration: 250.ms),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final FocusSessionState session;
  final FocusSessionNotifier notifier;
  final bool compact;

  const _MobileLayout({
    required this.session,
    required this.notifier,
    required this.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? AppSpacing.sp16 : AppSpacing.sp24),
      child: _FocusTaskCard(
        focusTask: session.currentTask!,
        notifier: notifier,
        compact: compact,
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03, end: 0),
    );
  }
}

// ── Task Sidebar (desktop) ────────────────────────────────────

class _TaskSidebar extends StatelessWidget {
  final FocusSessionState session;

  const _TaskSidebar({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp16, AppSpacing.sp16, AppSpacing.sp16, AppSpacing.sp8),
          child: Text(
            'Tarefas restantes',
            style: AppTypography.label(context.cTextMuted),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: session.tasks.length,
            itemBuilder: (ctx, i) {
              final ft = session.tasks[i];
              final isCurrent = i == session.currentIndex;
              final isDone = i < session.currentIndex;
              return Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp10, vertical: AppSpacing.sp8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : isCurrent
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: isDone
                          ? AppColors.success
                          : isCurrent
                              ? AppColors.primary
                              : context.cTextMuted,
                    ),
                    const SizedBox(width: AppSpacing.sp8),
                    Expanded(
                      child: Text(
                        ft.task.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isDone
                              ? context.cTextMuted
                              : context.cTextPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ft.isOverdue)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FOCUS TASK CARD
// ─────────────────────────────────────────────────────────────

class _FocusTaskCard extends ConsumerWidget {
  final FocusTask focusTask;
  final FocusSessionNotifier notifier;
  final bool compact;

  const _FocusTaskCard({
    required this.focusTask,
    required this.notifier,
    required this.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = focusTask.task;
    final isDark = context.isDark;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: focusTask.isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: focusTask.isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (focusTask.isOverdue ? AppColors.error : AppColors.primary)
                .withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge urgência ─────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp20, vertical: AppSpacing.sp10),
            decoration: BoxDecoration(
              color: focusTask.isOverdue
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.warning.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  focusTask.isOverdue
                      ? Icons.alarm_rounded
                      : Icons.today_rounded,
                  size: 14,
                  color: focusTask.isOverdue
                      ? AppColors.error
                      : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sp6),
                Text(
                  focusTask.isOverdue ? 'ATRASADA' : 'VENCE HOJE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: focusTask.isOverdue
                        ? AppColors.error
                        : AppColors.warning,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                PriorityTag(priority: task.priority),
              ],
            ),
          ),

          // ── Conteúdo ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: AppSpacing.sp12),

                // ── Meta-infos ────────────────────────────
                Wrap(
                  spacing: AppSpacing.sp8,
                  runSpacing: AppSpacing.sp6,
                  children: [
                    StatusTag(status: task.status),
                    if (task.dueDate != null)
                      FlowTag(
                        label: dateFormat.format(task.dueDate!),
                        color: focusTask.isOverdue
                            ? AppColors.error
                            : AppColors.textMuted,
                        icon: Icons.calendar_today_rounded,
                        small: true,
                      ),
                    if (task.projectName != null)
                      FlowTag(
                        label: task.projectName!,
                        color: AppColors.primary,
                        icon: Icons.folder_outlined,
                        small: true,
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sp20),
                _Divider(),
                const SizedBox(height: AppSpacing.sp20),

                // ── Ações ─────────────────────────────────
                _FocusActionBar(
                  focusTask: focusTask,
                  notifier: notifier,
                  compact: compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: context.isDark ? AppColors.borderDark : AppColors.border,
      );
}

// ─────────────────────────────────────────────────────────────
// FOCUS ACTION BAR
// ─────────────────────────────────────────────────────────────

class _FocusActionBar extends ConsumerWidget {
  final FocusTask focusTask;
  final FocusSessionNotifier notifier;
  final bool compact;

  const _FocusActionBar({
    required this.focusTask,
    required this.notifier,
    required this.compact,
  });

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final tasksNotifier = ref.read(tasksProvider.notifier);
    await tasksNotifier.updateStatus(focusTask.task.id, 'done');
    notifier.recordCompleted();
  }

  Future<void> _openDetail(BuildContext context) async {
    context.push('/tasks/${focusTask.task.id}');
  }

  Future<void> _postpone(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({DateTime date, String reason})>(
      context: context,
      builder: (_) => _RescheduleModal(task: focusTask.task),
    );
    if (result == null) return;

    final tasksNotifier = ref.read(tasksProvider.notifier);
    await tasksNotifier.updateTaskDates(
        focusTask.task.id, focusTask.task.startDate, result.date);
    notifier.recordPostponed();
  }

  Future<void> _delegate(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _DelegateModal(),
    );
    if (result == null) return;

    // updateTask não tem assigneeId — usamos supabase diretamente
    final client = ref.read(supabaseProvider);
    await client.from('tasks').update({
      'assignee_id': result,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', focusTask.task.id);
    await ref.read(tasksProvider.notifier).refresh();
    notifier.recordDelegated();
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _BlockModal(),
    );
    if (reason == null) return;

    // Mapeamos "bloquear" para status 'review' no sistema atual
    final tasksNotifier = ref.read(tasksProvider.notifier);
    await tasksNotifier.updateStatus(focusTask.task.id, 'review');
    notifier.recordBlocked();
  }

  void _skip() {
    notifier.recordSkipped(focusTask.task.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _ActionBtn(
        label: 'Concluir',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        filled: true,
        onTap: () => _complete(context, ref),
      ),
      _ActionBtn(
        label: 'Detalhe',
        icon: Icons.open_in_new_rounded,
        color: AppColors.primary,
        onTap: () => _openDetail(context),
      ),
      _ActionBtn(
        label: 'Adiar',
        icon: Icons.calendar_month_rounded,
        color: AppColors.warning,
        onTap: () => _postpone(context, ref),
      ),
      _ActionBtn(
        label: 'Delegar',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.primary,
        onTap: () => _delegate(context, ref),
      ),
      _ActionBtn(
        label: 'Bloquear',
        icon: Icons.block_rounded,
        color: AppColors.error,
        onTap: () => _block(context, ref),
      ),
      _ActionBtn(
        label: 'Pular',
        icon: Icons.skip_next_rounded,
        color: AppColors.textMuted,
        onTap: _skip,
      ),
    ];

    if (!compact) {
      // Desktop/tablet: botões em linha responsiva
      return Wrap(
        spacing: AppSpacing.sp8,
        runSpacing: AppSpacing.sp8,
        children: actions,
      );
    }

    // Mobile: grid 2 colunas
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sp8,
      mainAxisSpacing: AppSpacing.sp8,
      childAspectRatio: 3.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions,
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovering = false;
  bool _loading = false;

  void _handle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await Future.microtask(widget.onTap);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (widget.filled) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: _handle,
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp16, vertical: AppSpacing.sp10),
            decoration: BoxDecoration(
              color: _hovering
                  ? widget.color.withValues(alpha: 0.85)
                  : widget.color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(widget.icon, size: 15, color: Colors.white),
                const SizedBox(width: AppSpacing.sp6),
                Text(
                  widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _handle,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp12, vertical: AppSpacing.sp8),
          decoration: BoxDecoration(
            color: _hovering
                ? widget.color.withValues(alpha: 0.08)
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _hovering
                  ? widget.color.withValues(alpha: 0.4)
                  : (isDark ? AppColors.borderDark : AppColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _loading
                  ? SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: widget.color))
                  : Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: AppSpacing.sp6),
              Text(
                widget.label,
                style: TextStyle(
                    color: context.cTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODALS
// ─────────────────────────────────────────────────────────────

// ── Adiar modal ───────────────────────────────────────────────

class _RescheduleModal extends ConsumerStatefulWidget {
  final TaskData task;
  const _RescheduleModal({required this.task});

  @override
  ConsumerState<_RescheduleModal> createState() => _RescheduleModalState();
}

class _RescheduleModalState extends ConsumerState<_RescheduleModal> {
  DateTime? _selectedDate;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecione a nova data',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final canSubmit =
        _selectedDate != null && _reasonCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor:
          context.isDark ? AppColors.surfaceDark : AppColors.surface,
      title: Row(children: [
        const Icon(Icons.calendar_month_rounded,
            color: AppColors.warning, size: 20),
        const SizedBox(width: 8),
        const Text('Adiar tarefa'),
      ]),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: context.bodyMd.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sp16),
            // Seletor de data
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sp12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedDate != null
                        ? AppColors.primary
                        : (context.isDark
                            ? AppColors.borderDark
                            : AppColors.border),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: _selectedDate != null
                          ? AppColors.primary
                          : context.cTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate != null
                          ? dateFormat.format(_selectedDate!)
                          : 'Selecionar nova data',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? context.cTextPrimary
                            : context.cTextMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp12),
            // Justificativa
            TextField(
              controller: _reasonCtrl,
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivo do adiamento *',
                hintText: 'Ex: aguardando informação do cliente...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canSubmit && !_submitting
              ? () => Navigator.pop(context,
                  (date: _selectedDate!, reason: _reasonCtrl.text.trim()))
              : null,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Adiar'),
        ),
      ],
    );
  }
}

// ── Bloquear modal ────────────────────────────────────────────

class _BlockModal extends StatefulWidget {
  const _BlockModal();

  @override
  State<_BlockModal> createState() => _BlockModalState();
}

class _BlockModalState extends State<_BlockModal> {
  final _reasonCtrl = TextEditingController();
  String? _quickOption;

  static const _options = [
    'Aguardando aprovação',
    'Aguardando resposta',
    'Dependência externa',
    'Recursos indisponíveis',
    'Precisa de mais informações',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _reasonCtrl.text.trim().isNotEmpty || _quickOption != null;

    return AlertDialog(
      backgroundColor:
          context.isDark ? AppColors.surfaceDark : AppColors.surface,
      title: Row(children: [
        const Icon(Icons.block_rounded, color: AppColors.error, size: 20),
        const SizedBox(width: 8),
        const Text('Marcar como bloqueada'),
      ]),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione o motivo do bloqueio:',
              style: context.bodySm.copyWith(color: context.cTextMuted),
            ),
            const SizedBox(height: AppSpacing.sp10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _options.map((opt) {
                final selected = _quickOption == opt;
                return GestureDetector(
                  onTap: () => setState(() {
                    _quickOption = selected ? null : opt;
                    if (!selected) _reasonCtrl.text = opt;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.error.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: selected
                            ? AppColors.error.withValues(alpha: 0.4)
                            : (context.isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? AppColors.error
                            : context.cTextPrimary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sp12),
            TextField(
              controller: _reasonCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Ou descreva o bloqueio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canSubmit
              ? () => Navigator.pop(
                  context,
                  _reasonCtrl.text.trim().isNotEmpty
                      ? _reasonCtrl.text.trim()
                      : _quickOption)
              : null,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.error),
          child: const Text('Confirmar bloqueio'),
        ),
      ],
    );
  }
}

// ── Delegar modal ─────────────────────────────────────────────

class _DelegateModal extends ConsumerWidget {
  const _DelegateModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(workspaceMembersProvider);
    final currentUserId = ref.read(currentUserProvider)?.id;

    return AlertDialog(
      backgroundColor:
          context.isDark ? AppColors.surfaceDark : AppColors.surface,
      title: const Row(children: [
        Icon(Icons.person_add_alt_1_rounded,
            color: AppColors.primary, size: 20),
        SizedBox(width: 8),
        Text('Delegar tarefa'),
      ]),
      content: SizedBox(
        width: 360,
        child: membersAsync.when(
          data: (members) {
            final others = members
                .where((m) => m.userId != currentUserId)
                .toList();

            if (others.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.sp16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_off_rounded,
                        size: 40, color: context.cTextMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum outro membro no workspace.',
                      textAlign: TextAlign.center,
                      style: context.bodySm
                          .copyWith(color: context.cTextMuted),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: others.map((m) => _MemberTile(
                member: m,
                onTap: () => Navigator.pop(context, m.userId),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(
            'Erro ao carregar membros.',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final WorkspaceMember member;
  final VoidCallback onTap;

  const _MemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sp8, horizontal: AppSpacing.sp4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: member.avatar != null
                    ? NetworkImage(member.avatar!)
                    : null,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.12),
                child: member.avatar == null
                    ? Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sp10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name.isNotEmpty ? member.name : member.email,
                      style: context.bodyMd
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(member.email,
                        style: context.bodySm
                            .copyWith(color: context.cTextMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: context.cTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}
