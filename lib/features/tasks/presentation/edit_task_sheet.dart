import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_button.dart';
import '../../auth/domain/data_providers.dart';

/// Bottom sheet completo para edição de uma tarefa existente.
/// Exibe todos os campos editáveis: título, status, prioridade, projeto e data.
class EditTaskSheet extends ConsumerStatefulWidget {
  final TaskData task;

  const EditTaskSheet({super.key, required this.task});

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  late final TextEditingController _titleCtrl;
  late String _status;
  late String _priority;
  late String? _projectId;
  late DateTime? _dueDate;
  // Recurrence
  late String _recurrenceType;
  late int _recurrenceInterval;
  DateTime? _recurrenceEndsAt;
  bool _dueDateAutoSet = false; // true quando a data foi preenchida automaticamente pela recorrência
  bool _loading = false;
  String? _error;

  static const _statuses = [
    ('todo', 'A fazer', AppColors.statusTodo),
    ('in_progress', 'Em progresso', AppColors.statusInProgress),
    ('review', 'Revisão', AppColors.statusReview),
    ('done', 'Concluído', AppColors.statusDone),
    ('cancelled', 'Cancelado', AppColors.statusCancelled),
  ];

  static const _priorities = [
    ('urgent', 'Urgente', AppColors.error),
    ('high', 'Alta', AppColors.warning),
    ('medium', 'Média', AppColors.primary),
    ('low', 'Baixa', AppColors.textMuted),
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _status = widget.task.status;
    _priority = widget.task.priority;
    _projectId = widget.task.projectId;
    _dueDate = widget.task.dueDate;
    _recurrenceType = widget.task.recurrenceType;
    _recurrenceInterval = widget.task.recurrenceInterval;
    _recurrenceEndsAt = widget.task.recurrenceEndsAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  /// Calcula a próxima data de vencimento a partir de hoje com base no tipo e intervalo.
  DateTime _computeFirstDueDate(String type, int interval) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return switch (type) {
      'daily'   => base.add(Duration(days: interval)),
      'weekly'  => base.add(Duration(days: 7 * interval)),
      'monthly' => DateTime(base.year, base.month + interval, base.day),
      'yearly'  => DateTime(base.year + interval, base.month, base.day),
      _         => base.add(const Duration(days: 1)),
    };
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'O título não pode ficar vazio');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final clearProjectId = _projectId == null && widget.task.projectId != null;
    final clearDueDate = _dueDate == null && widget.task.dueDate != null;
    final clearEndsAt = _recurrenceEndsAt == null &&
        widget.task.recurrenceEndsAt != null;

    final err = await ref.read(tasksProvider.notifier).updateTask(
      taskId: widget.task.id,
      title: _titleCtrl.text,
      status: _status,
      priority: _priority,
      projectId: _projectId,
      dueDate: _dueDate,
      clearDueDate: clearDueDate,
      clearProjectId: clearProjectId,
      recurrenceType: _recurrenceType,
      recurrenceInterval: _recurrenceInterval,
      recurrenceEndsAt: _recurrenceEndsAt,
      clearRecurrenceEndsAt: clearEndsAt,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        setState(() => _error = err);
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Tarefa atualizada!'),
          ]),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Data de vencimento',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateAutoSet = false; // usuário definiu manualmente
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.sp24,
        right: AppSpacing.sp24,
        top: AppSpacing.sp24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sp24,
      ),
      child: SingleChildScrollView(
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

            // Título
            Row(children: [
              Text('Editar tarefa',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: context.cTextMuted,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
            const SizedBox(height: AppSpacing.sp16),

            // Título da tarefa
            TextField(
              controller: _titleCtrl,
              autofocus: false,
              decoration: InputDecoration(
                labelText: 'Título',
                errorText: _error,
                prefixIcon: const Icon(Icons.title_rounded, size: 18),
              ),
              style: TextStyle(fontSize: 15, color: context.cTextPrimary),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Status ──────────────────────────────────────
            Text('Status', style: context.labelMd),
            const SizedBox(height: AppSpacing.sp8),
            Wrap(
              spacing: AppSpacing.sp8,
              runSpacing: AppSpacing.sp6,
              children: _statuses.map((s) {
                final (value, label, color) = s;
                final sel = _status == value;
                return _SelectChip(
                  label: label,
                  color: color,
                  isSelected: sel,
                  onTap: () => setState(() => _status = value),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Prioridade ───────────────────────────────────
            Text('Prioridade', style: context.labelMd),
            const SizedBox(height: AppSpacing.sp8),
            Wrap(
              spacing: AppSpacing.sp8,
              runSpacing: AppSpacing.sp6,
              children: _priorities.map((p) {
                final (value, label, color) = p;
                final sel = _priority == value;
                return _SelectChip(
                  label: label,
                  color: color,
                  isSelected: sel,
                  onTap: () => setState(() => _priority = value),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Data de Vencimento ───────────────────────────
            Text('Data de vencimento', style: context.labelMd),
            const SizedBox(height: AppSpacing.sp8),
            InkWell(
              onTap: _pickDate,
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
                child: Row(
                  children: [
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
                            : 'Sem data definida',
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
                        onTap: () => setState(() {
                          _dueDate = null;
                          _dueDateAutoSet = false;
                        }),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.primary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Projeto ──────────────────────────────────────
            Text('Projeto', style: context.labelMd),
            const SizedBox(height: AppSpacing.sp8),
            projectsAsync.when(
              loading: () => const SizedBox(
                height: 32,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary)),
              ),
              error: (_, __) => Text('Erro ao carregar projetos',
                  style: TextStyle(color: AppColors.error, fontSize: 12)),
              data: (projects) => Wrap(
                spacing: AppSpacing.sp8,
                runSpacing: AppSpacing.sp6,
                children: [
                  _SelectChip(
                    label: 'Nenhum',
                    color: context.cTextMuted,
                    isSelected: _projectId == null,
                    icon: Icons.block_rounded,
                    onTap: () => setState(() => _projectId = null),
                  ),
                  ...projects.map((p) => _SelectChip(
                    label: p.name,
                    color: AppColors.primary,
                    isSelected: _projectId == p.id,
                    icon: Icons.folder_rounded,
                    onTap: () => setState(() => _projectId = p.id),
                  )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sp20),

            // ── Recorrência ────────────────────────────────
            _RecurrenceSection(
              recurrenceType: _recurrenceType,
              recurrenceInterval: _recurrenceInterval,
              recurrenceEndsAt: _recurrenceEndsAt,
              onTypeChanged: (v) {
                setState(() {
                  _recurrenceType = v;
                  // Auto-preenche a data se não houver data definida e uma recorrência foi escolhida
                  if (v != 'none' && (_dueDate == null || _dueDateAutoSet)) {
                    _dueDate = _computeFirstDueDate(v, _recurrenceInterval);
                    _dueDateAutoSet = true;
                  }
                  // Remove a data auto-preenchida ao desativar recorrência
                  if (v == 'none' && _dueDateAutoSet) {
                    _dueDate = null;
                    _dueDateAutoSet = false;
                  }
                });
              },
              onIntervalChanged: (v) {
                setState(() {
                  _recurrenceInterval = v;
                  // Recalcula a data auto-definida quando o intervalo muda
                  if (_dueDateAutoSet && _recurrenceType != 'none') {
                    _dueDate = _computeFirstDueDate(_recurrenceType, v);
                  }
                });
              },
              onEndsAtChanged: (v) =>
                  setState(() => _recurrenceEndsAt = v),
            ),
            const SizedBox(height: AppSpacing.sp24),

            // ── Botões ───────────────────────────────────────
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
                  label: _loading ? 'Salvando...' : 'Salvar alterações',
                  onPressed: _loading ? null : _save,
                  leadingIcon: _loading ? null : Icons.save_rounded,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Chip de seleção reutilizável ─────────────────────────────
class _SelectChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SelectChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp12, vertical: AppSpacing.sp6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? color
                : (context.isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isSelected ? color : context.cTextMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : context.cTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recurrence section ────────────────────────────────────────
class _RecurrenceSection extends StatelessWidget {
  final String recurrenceType;
  final int recurrenceInterval;
  final DateTime? recurrenceEndsAt;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<DateTime?> onEndsAtChanged;

  const _RecurrenceSection({
    required this.recurrenceType,
    required this.recurrenceInterval,
    required this.recurrenceEndsAt,
    required this.onTypeChanged,
    required this.onIntervalChanged,
    required this.onEndsAtChanged,
  });

  static const _types = [
    ('none', 'Nunca', Icons.block_rounded),
    ('daily', 'Diária', Icons.wb_sunny_rounded),
    ('weekly', 'Semanal', Icons.view_week_rounded),
    ('monthly', 'Mensal', Icons.calendar_month_rounded),
    ('yearly', 'Anual', Icons.event_repeat_rounded),
  ];

  static const _intervalLabels = {
    'daily': 'dias',
    'weekly': 'semanas',
    'monthly': 'meses',
    'yearly': 'anos',
  };

  @override
  Widget build(BuildContext context) {
    final hasRecurrence = recurrenceType != 'none';
    final intervalLabel = _intervalLabels[recurrenceType] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.repeat_rounded,
              size: 16,
              color: hasRecurrence ? AppColors.accent : context.cTextMuted),
          const SizedBox(width: 6),
          Text('Recorrência',
              style: context.labelMd.copyWith(
                  color: hasRecurrence
                      ? AppColors.accent
                      : context.cTextPrimary)),
        ]),
        const SizedBox(height: AppSpacing.sp8),

        // Type chips
        Wrap(
          spacing: AppSpacing.sp6,
          runSpacing: AppSpacing.sp6,
          children: _types.map((t) {
            final (value, label, icon) = t;
            final sel = recurrenceType == value;
            return GestureDetector(
              onTap: () => onTypeChanged(value),
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: sel
                        ? AppColors.accent
                        : (context.isDark
                            ? AppColors.borderDark
                            : AppColors.border),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon,
                      size: 12,
                      color: sel ? AppColors.accent : context.cTextMuted),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? AppColors.accent
                              : context.cTextMuted)),
                ]),
              ),
            );
          }).toList(),
        ),

        // Interval + end date (only when recurrence is set)
        if (hasRecurrence) ...[
          const SizedBox(height: AppSpacing.sp12),
          Row(children: [
            // Interval selector
            Text('A cada', style: context.bodySm),
            const SizedBox(width: 8),
            _CounterButton(
              value: recurrenceInterval,
              min: 1,
              max: 99,
              onChanged: onIntervalChanged,
            ),
            const SizedBox(width: 8),
            Text(intervalLabel, style: context.bodySm),
            const Spacer(),
            // End date
            GestureDetector(
              onTap: () async {
                if (recurrenceEndsAt != null) {
                  onEndsAtChanged(null);
                  return;
                }
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 5)),
                  helpText: 'Termina em',
                  confirmText: 'Confirmar',
                  cancelText: 'Cancelar',
                );
                if (picked != null) onEndsAtChanged(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: recurrenceEndsAt != null
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: recurrenceEndsAt != null
                        ? AppColors.accent
                        : (context.isDark
                            ? AppColors.borderDark
                            : AppColors.border),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_busy_rounded,
                      size: 12,
                      color: recurrenceEndsAt != null
                          ? AppColors.accent
                          : context.cTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    recurrenceEndsAt != null
                        ? 'Até ${recurrenceEndsAt!.day.toString().padLeft(2, '0')}/${recurrenceEndsAt!.month.toString().padLeft(2, '0')}/${recurrenceEndsAt!.year}'
                        : 'Sem fim',
                    style: TextStyle(
                        fontSize: 11,
                        color: recurrenceEndsAt != null
                            ? AppColors.accent
                            : context.cTextMuted),
                  ),
                ]),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _CounterButton({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(Icons.remove_rounded,
                size: 14,
                color: value > min ? context.cTextPrimary : context.cTextMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$value',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
        ),
        InkWell(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(Icons.add_rounded,
                size: 14,
                color:
                    value < max ? context.cTextPrimary : context.cTextMuted),
          ),
        ),
      ]),
    );
  }
}
