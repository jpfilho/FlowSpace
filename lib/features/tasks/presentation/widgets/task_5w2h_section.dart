import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/index.dart';
import '../../../../shared/widgets/common/flow_button.dart';
import '../../data/models/task_5w2h_model.dart';
import '../../domain/providers/task_5w2h_providers.dart';

// ────────────────────────────────────────────────────────────────────────────
// Enum de modo de visualização
// ────────────────────────────────────────────────────────────────────────────

enum _ViewMode { cards, compact, table }

// ────────────────────────────────────────────────────────────────────────────
// Metadados dos campos 5W2H
// ────────────────────────────────────────────────────────────────────────────

class _FieldMeta {
  final String key;
  final String label;
  final String hint;
  final String identifier; // Ex: W1, W2, H1 — exibido na visualização tabela
  final IconData icon;
  final Color color;
  final bool multiline;
  final bool fullWidth; // ocupa linha inteira no grid

  const _FieldMeta({
    required this.key,
    required this.label,
    required this.hint,
    required this.identifier,
    required this.icon,
    required this.color,
    this.multiline = false,
    this.fullWidth = false,
  });
}

const _fields = <_FieldMeta>[
  _FieldMeta(
    key: 'what',
    label: 'O que será feito?',
    hint: 'Descreva a ação ou entrega esperada...',
    identifier: 'W1',
    icon: Icons.assignment_rounded,
    color: AppColors.primary,
    multiline: true,
  ),
  _FieldMeta(
    key: 'why',
    label: 'Por que será feito?',
    hint: 'Qual é o objetivo ou justificativa?',
    identifier: 'W2',
    icon: Icons.help_outline_rounded,
    color: Color(0xFF8B5CF6),
    multiline: true,
  ),
  _FieldMeta(
    key: 'where',
    label: 'Onde será feito?',
    hint: 'Local, ambiente ou sistema...',
    identifier: 'W3',
    icon: Icons.place_rounded,
    color: Color(0xFF10B981),
    multiline: false,
  ),
  _FieldMeta(
    key: 'when',
    label: 'Quando será feito?',
    hint: 'Prazo, sprint, data estimada...',
    identifier: 'W4',
    icon: Icons.schedule_rounded,
    color: Color(0xFFF59E0B),
    multiline: false,
  ),
  _FieldMeta(
    key: 'who',
    label: 'Quem será responsável?',
    hint: 'Nome, equipe ou perfil responsável...',
    identifier: 'W5',
    icon: Icons.person_outline_rounded,
    color: Color(0xFF06B6D4),
    multiline: false,
  ),
  _FieldMeta(
    key: 'how',
    label: 'Como será feito?',
    hint: 'Metodologia, passos, ferramentas...',
    identifier: 'H1',
    icon: Icons.settings_outlined,
    color: Color(0xFFEC4899),
    multiline: true,
    fullWidth: true,
  ),
  _FieldMeta(
    key: 'how_much',
    label: 'Quanto custa / esforço?',
    hint: 'Orçamento, horas, story points...',
    identifier: 'H2',
    icon: Icons.attach_money_rounded,
    color: Color(0xFFF97316),
    multiline: false,
  ),
];

// Helper para ler o valor de um campo do model
String? _getValue(Task5w2hModel? m, String key) {
  if (m == null) return null;
  return switch (key) {
    'what' => m.what,
    'why' => m.why,
    'where' => m.whereTask,
    'when' => m.whenDetails,
    'who' => m.whoDetails,
    'how' => m.how,
    'how_much' => m.howMuch,
    _ => null,
  };
}

// Helper para construir model a partir dos controllers
Task5w2hModel _buildModel(
  Task5w2hModel base,
  Map<String, TextEditingController> ctrls,
) =>
    base.copyWith(
      what: ctrls['what']!.text.trim().isEmpty
          ? null
          : ctrls['what']!.text.trim(),
      why: ctrls['why']!.text.trim().isEmpty
          ? null
          : ctrls['why']!.text.trim(),
      whereTask: ctrls['where']!.text.trim().isEmpty
          ? null
          : ctrls['where']!.text.trim(),
      whenDetails: ctrls['when']!.text.trim().isEmpty
          ? null
          : ctrls['when']!.text.trim(),
      whoDetails: ctrls['who']!.text.trim().isEmpty
          ? null
          : ctrls['who']!.text.trim(),
      how: ctrls['how']!.text.trim().isEmpty
          ? null
          : ctrls['how']!.text.trim(),
      howMuch: ctrls['how_much']!.text.trim().isEmpty
          ? null
          : ctrls['how_much']!.text.trim(),
    );

// ────────────────────────────────────────────────────────────────────────────
// Widget Principal
// ────────────────────────────────────────────────────────────────────────────

/// Seção 5W2H para a página de detalhe de tarefa.
///
/// Suporta múltiplos registros por tarefa — igual ao padrão de subtarefas.
class Task5w2hSection extends ConsumerStatefulWidget {
  final String taskId;
  const Task5w2hSection({super.key, required this.taskId});

  @override
  ConsumerState<Task5w2hSection> createState() => _Task5w2hSectionState();
}

class _Task5w2hSectionState extends ConsumerState<Task5w2hSection> {
  bool _expanded = true;
  bool _isAdding = false;

  Future<void> _addItem() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      await ref
          .read(task5w2hListProvider(widget.taskId).notifier)
          .add();
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(task5w2hListProvider(widget.taskId));
    final list = asyncList.valueOrNull ?? [];
    final isLoading = asyncList.isLoading;

    // Auto-expande se há dados
    if (!_expanded && list.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _expanded = true);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────
        _SectionHeader(
          expanded: _expanded,
          itemCount: list.length,
          isLoading: isLoading,
          onToggleExpand: () => setState(() => _expanded = !_expanded),
        ),

        // ── Body (colapsável) ─────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sp12),
            child: isLoading && list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)),
                  )
                : Column(
                    children: [
                      // Lista de itens
                      ...list.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sp10),
                          child: _Plan5w2hCard(
                            key: ValueKey(item.id),
                            item: item,
                            index: index,
                            taskId: widget.taskId,
                          ),
                        );
                      }),

                      // Botao adicionar
                      _AddButton(
                        isLoading: _isAdding,
                        onTap: _addItem,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Card individual de cada 5W2H
// ────────────────────────────────────────────────────────────────────────────

class _Plan5w2hCard extends ConsumerStatefulWidget {
  final Task5w2hModel item;
  final int index;
  final String taskId;

  const _Plan5w2hCard({
    super.key,
    required this.item,
    required this.index,
    required this.taskId,
  });

  @override
  ConsumerState<_Plan5w2hCard> createState() => _Plan5w2hCardState();
}

class _Plan5w2hCardState extends ConsumerState<_Plan5w2hCard> {
  bool _expanded = false;
  bool _editingTitle = false;
  bool _editing = false;
  bool _deleting = false;
  bool _saveSuccess = false;
  String? _saveError;
  _ViewMode _viewMode = _ViewMode.cards;

  late final TextEditingController _titleCtrl;
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _ctrls = {for (final f in _fields) f.key: TextEditingController()};
    _populateFields(widget.item);
    // Auto-expande se tem dados
    _expanded = !widget.item.isEmpty;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _ctrls.values) { c.dispose(); }
    super.dispose();
  }

  void _populateFields(Task5w2hModel m) {
    for (final f in _fields) {
      final val = _getValue(m, f.key) ?? '';
      if (_ctrls[f.key]!.text != val) _ctrls[f.key]!.text = val;
    }
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleCtrl.text.trim();
    if (newTitle.isEmpty || newTitle == widget.item.title) {
      setState(() => _editingTitle = false);
      return;
    }
    await ref
        .read(task5w2hListProvider(widget.taskId).notifier)
        .rename(widget.item.id, newTitle);
    if (mounted) setState(() => _editingTitle = false);
  }

  Future<void> _saveFields() async {
    setState(() {
      _saveSuccess = false;
      _saveError = null;
    });
    try {
      final updated = _buildModel(widget.item, _ctrls);
      await ref
          .read(task5w2hListProvider(widget.taskId).notifier)
          .save(updated);
      if (mounted) {
        setState(() {
          _saveSuccess = true;
          _editing = false;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _saveSuccess = false);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover planejamento'),
        content: Text(
            'Remover "${widget.item.title}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    await ref
        .read(task5w2hListProvider(widget.taskId).notifier)
        .delete(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        context.isDark ? AppColors.borderDark : AppColors.border;
    final surfaceBg =
        context.isDark ? AppColors.surfaceVariantDark : AppColors.surface;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _deleting ? 0.4 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _saveSuccess
                ? AppColors.success.withValues(alpha: 0.4)
                : borderColor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header do card ───────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp14,
                    vertical: AppSpacing.sp10),
                child: Row(
                  children: [
                    // Chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 18, color: context.cTextMuted),
                    ),
                    const SizedBox(width: 8),

                    // Badge index
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '#${widget.index + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Título (editável inline)
                    Expanded(
                      child: _editingTitle
                          ? TextField(
                              controller: _titleCtrl,
                              autofocus: true,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.cTextPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _saveTitle(),
                              onTapOutside: (_) => _saveTitle(),
                            )
                          : GestureDetector(
                              onDoubleTap: () =>
                                  setState(() => _editingTitle = true),
                              child: Tooltip(
                                message: 'Duplo clique para renomear',
                                child: Text(
                                  widget.item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.cTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(width: 8),

                    // Badge campos preenchidos
                    if (!_editing && widget.item.filledCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.success.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '${widget.item.filledCount}/7',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),

                    // Salvo ok
                    if (_saveSuccess)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: const Icon(Icons.check_circle_rounded,
                            size: 14, color: AppColors.success),
                      ),

                    // View toggle (quando expandido)
                    if (_expanded && !_editing)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _ViewToggle(
                          current: _viewMode,
                          onChanged: (m) =>
                              setState(() => _viewMode = m),
                        ),
                      ),

                    // Botão editar
                    if (_expanded && !_editing)
                      Tooltip(
                        message: 'Editar',
                        child: InkWell(
                          onTap: () {
                            _populateFields(widget.item);
                            setState(() => _editing = true);
                          },
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_outlined,
                                size: 14, color: context.cTextMuted),
                          ),
                        ),
                      ),

                    // Botão deletar
                    if (!_deleting)
                      Tooltip(
                        message: 'Remover este planejamento',
                        child: InkWell(
                          onTap: () => _delete(context),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 14, color: AppColors.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Body expansível ──────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: borderColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sp14),
                    child: _editing
                        ? _EditForm(
                            taskId: widget.taskId,
                            ctrls: _ctrls,
                            saveError: _saveError,
                            onSave: _saveFields,
                            onCancel: () {
                              _populateFields(widget.item);
                              setState(() {
                                _editing = false;
                                _saveError = null;
                              });
                            },
                            isSaving: false,
                          )
                        : _ReadView(
                            model: widget.item,
                            viewMode: _viewMode,
                            onEdit: () {
                              _populateFields(widget.item);
                              setState(() => _editing = true);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.02),
    );
  }
}

// ── Botão Adicionar ──────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _AddButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp14, vertical: AppSpacing.sp10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Adicionar planejamento 5W2H',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


// ────────────────────────────────────────────────────────────────────────────
// Header da Seção (novo — baseado em contagem de itens)
// ────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool expanded;
  final int itemCount;
  final bool isLoading;
  final VoidCallback onToggleExpand;

  const _SectionHeader({
    required this.expanded,
    required this.itemCount,
    required this.isLoading,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: context.cTextMuted),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.grid_view_rounded,
                  size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5W2H',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                  ),
                ),
                Text(
                  'Planejamento detalhado da execução',
                  style:
                      TextStyle(fontSize: 11, color: context.cTextMuted),
                ),
              ],
            ),
            const Spacer(),
            if (isLoading)
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppColors.primary))
            else if (itemCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$itemCount planejamento${itemCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Toggle de Visualização (Cards ↔ Compacto)
// ────────────────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;

  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            tooltip: 'Cards',
            active: current == _ViewMode.cards,
            onTap: () => onChanged(_ViewMode.cards),
          ),
          _ToggleBtn(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'Compacto',
            active: current == _ViewMode.compact,
            onTap: () => onChanged(_ViewMode.compact),
          ),
          _ToggleBtn(
            icon: Icons.table_chart_outlined,
            tooltip: 'Tabela',
            active: current == _ViewMode.table,
            onTap: () => onChanged(_ViewMode.table),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(
            icon,
            size: 14,
            color: active ? AppColors.primary : context.cTextMuted,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Visualização de Leitura
// ────────────────────────────────────────────────────────────────────────────

class _ReadView extends StatelessWidget {
  final Task5w2hModel? model;
  final _ViewMode viewMode;
  final VoidCallback onEdit;

  const _ReadView({
    required this.model,
    required this.viewMode,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = model == null || model!.isEmpty;

    if (isEmpty) {
      return _EmptyState(onFill: onEdit);
    }

    return switch (viewMode) {
      _ViewMode.cards   => _CardsView(model: model!),
      _ViewMode.compact => _CompactView(model: model!),
      _ViewMode.table   => _TableView(model: model!),
    };
  }
}

// ── Estado vazio ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onFill;
  const _EmptyState({required this.onFill});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onFill,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sp24),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: context.isDark ? AppColors.borderDark : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum planejamento 5W2H ainda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.cTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Clique para preencher o planejamento detalhado desta tarefa',
              style: TextStyle(fontSize: 13, color: context.cTextMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Visualização Cards ───────────────────────────────────────

class _CardsView extends StatelessWidget {
  final Task5w2hModel model;
  const _CardsView({required this.model});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final crossAxisCount = (isDesktop || isTablet) ? 2 : 1;

    // Separa campos full-width dos que entram no grid
    final gridFields = _fields.where((f) => !f.fullWidth).toList();
    final fullWidthFields = _fields.where((f) => f.fullWidth).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid de 2 ou 1 coluna
        _ResponsiveGrid(
          crossAxisCount: crossAxisCount,
          children: gridFields.map((f) {
            final value = _getValue(model, f.key);
            return _FieldCard(meta: f, value: value);
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sp12),
        // Campos full-width (Como)
        for (final f in fullWidthFields) ...[
          _FieldCard(meta: f, value: _getValue(model, f.key), fullWidth: true),
          const SizedBox(height: AppSpacing.sp8),
        ],
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int crossAxisCount;
  final List<Widget> children;
  const _ResponsiveGrid(
      {required this.crossAxisCount, required this.children});

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount == 1) {
      return Column(
        children: children
            .map((c) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sp10),
                  child: c,
                ))
            .toList(),
      );
    }

    // 2 colunas
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final left = children[i];
      final right = i + 1 < children.length ? children[i + 1] : const SizedBox.shrink();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sp10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpacing.sp10),
              Expanded(child: right),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _FieldCard extends StatelessWidget {
  final _FieldMeta meta;
  final String? value;
  final bool fullWidth;

  const _FieldCard({
    required this.meta,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.sp14),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasValue
              ? meta.color.withValues(alpha: 0.2)
              : context.isDark
                  ? AppColors.borderDark
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(meta.icon, size: 13, color: meta.color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                meta.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: meta.color,
                ),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.sp10),
          // Value
          hasValue
              ? Text(
                  value!,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cTextPrimary,
                    height: 1.6,
                  ),
                )
              : Text(
                  meta.hint,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cTextMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Visualização Compacta ────────────────────────────────────

class _CompactView extends StatelessWidget {
  final Task5w2hModel model;
  const _CompactView({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: _fields.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          final value = _getValue(model, f.key);
          final hasValue = value != null && value.trim().isNotEmpty;
          final isLast = i == _fields.length - 1;

          return _CompactRow(
            meta: f,
            value: value,
            hasValue: hasValue,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  final _FieldMeta meta;
  final String? value;
  final bool hasValue;
  final bool showDivider;

  const _CompactRow({
    required this.meta,
    required this.value,
    required this.hasValue,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp14, vertical: AppSpacing.sp10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone + label (coluna fixa)
              SizedBox(
                width: 160,
                child: Row(children: [
                  Icon(meta.icon, size: 14, color: meta.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: meta.color,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: AppSpacing.sp12),
              // Valor
              Expanded(
                child: hasValue
                    ? Text(
                        value!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cTextPrimary,
                          height: 1.5,
                        ),
                      )
                    : Text(
                        '—',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cTextMuted,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: context.isDark ? AppColors.borderDark : AppColors.border,
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Visualização Tabela
// ────────────────────────────────────────────────────────────────────────────

class _TableView extends StatelessWidget {
  final Task5w2hModel model;
  const _TableView({required this.model});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        context.isDark ? AppColors.borderDark : AppColors.border;
    final headerBg = context.isDark
        ? AppColors.surfaceVariantDark.withValues(alpha: 0.6)
        : AppColors.surfaceVariant;
    final filledCount =
        _fields.where((f) {
      final v = _getValue(model, f.key);
      return v != null && v.trim().isNotEmpty;
    }).length;

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceVariantDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Cabeçalho da tabela ───────────────────────────
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp14, vertical: AppSpacing.sp10),
            child: Row(children: [
              // Coluna ID
              SizedBox(
                width: 44,
                child: Text(
                  'ID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.cTextMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp10),
              // Coluna Pergunta
              Expanded(
                flex: 2,
                child: Text(
                  'PERGUNTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.cTextMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp10),
              // Coluna Resposta
              Expanded(
                flex: 3,
                child: Text(
                  'RESPOSTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.cTextMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ]),
          ),

          // ── Linha divisória do cabeçalho ──────────────────
          Divider(height: 1, thickness: 1, color: borderColor),

          // ── Linhas de dados ───────────────────────────────
          ..._fields.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            final value = _getValue(model, f.key);
            final isLast = i == _fields.length - 1;
            return _TableRow(
              meta: f,
              value: value,
              showDivider: !isLast,
            );
          }),

          // ── Rodapé: contagem de campos preenchidos ────────
          Divider(height: 1, thickness: 1, color: borderColor),
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp14, vertical: AppSpacing.sp8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 14,
                    color: filledCount == _fields.length
                        ? AppColors.success
                        : context.cTextMuted),
                const SizedBox(width: 6),
                Text(
                  '$filledCount de ${_fields.length} campos preenchidos',
                  style: TextStyle(
                    fontSize: 12,
                    color: filledCount == _fields.length
                        ? AppColors.success
                        : context.cTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final _FieldMeta meta;
  final String? value;
  final bool showDivider;

  const _TableRow({
    required this.meta,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    final borderColor =
        context.isDark ? AppColors.borderDark : AppColors.border;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp14, vertical: AppSpacing.sp12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Coluna ID (badge colorido) ─────────────────
              SizedBox(
                width: 44,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border:
                        Border.all(color: meta.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    meta.identifier,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: meta.color,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp10),

              // ── Coluna Pergunta (ícone + label) ───────────
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(meta.icon, size: 14, color: meta.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.cTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp10),

              // ── Coluna Resposta ───────────────────────────
              Expanded(
                flex: 3,
                child: hasValue
                    ? Text(
                        value!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cTextPrimary,
                          height: 1.55,
                        ),
                      )
                    : Row(children: [
                        Icon(Icons.remove_rounded,
                            size: 14, color: context.cTextMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Não informado',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.cTextMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ]),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: borderColor),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Formulário de Edição
// ────────────────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  final String taskId;
  final Map<String, TextEditingController> ctrls;
  final String? saveError;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  const _EditForm({
    required this.taskId,
    required this.ctrls,
    required this.saveError,
    required this.onSave,
    required this.onCancel,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final crossAxisCount = (isDesktop || isTablet) ? 2 : 1;

    final gridFields = _fields.where((f) => !f.fullWidth).toList();
    final fullWidthFields = _fields.where((f) => f.fullWidth).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid de inputs
        _buildGrid(context, gridFields, crossAxisCount),
        const SizedBox(height: AppSpacing.sp10),

        // Full-width fields
        for (final f in fullWidthFields) ...[
          _buildField(context, f),
          const SizedBox(height: AppSpacing.sp10),
        ],

        // Erro
        if (saveError != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sp12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erro ao salvar: $saveError',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.error),
                ),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.sp12),
        ],

        // Botões
        Row(children: [
          FlowButton(
            label: 'Cancelar',
            onPressed: isSaving ? null : onCancel,
            variant: FlowButtonVariant.ghost,
          ),
          const SizedBox(width: AppSpacing.sp8),
          FlowButton(
            label: isSaving ? 'Salvando...' : 'Salvar 5W2H',
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
            leadingIcon: isSaving ? null : Icons.save_rounded,
          ),
        ]),
      ],
    );
  }

  Widget _buildGrid(
      BuildContext context, List<_FieldMeta> fields, int crossCount) {
    if (crossCount == 1) {
      return Column(
        children: fields.map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sp10),
            child: _buildField(context, f),
          );
        }).toList(),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      final left = fields[i];
      final right = i + 1 < fields.length ? fields[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sp10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildField(context, left)),
              const SizedBox(width: AppSpacing.sp10),
              Expanded(
                child: right != null
                    ? _buildField(context, right)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildField(BuildContext context, _FieldMeta f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com ícone colorido
        Row(children: [
          Icon(f.icon, size: 14, color: f.color),
          const SizedBox(width: 6),
          Text(
            f.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: f.color,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        // Input
        TextField(
          controller: ctrls[f.key],
          maxLines: f.multiline ? 4 : 1,
          minLines: f.multiline ? 3 : 1,
          style: TextStyle(fontSize: 13, color: context.cTextPrimary),
          decoration: InputDecoration(
            hintText: f.hint,
            alignLabelWithHint: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: f.color, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp12,
              vertical: AppSpacing.sp10,
            ),
          ),
        ),
      ],
    );
  }
}
