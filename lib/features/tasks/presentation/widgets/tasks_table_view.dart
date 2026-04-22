import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/domain/data_providers.dart';
import '../../data/models/task_5w2h_model.dart';
import '../../domain/providers/task_5w2h_providers.dart';

// ── Batch provider: busca todos os 5W2H do workspace de uma vez ──────────────

final _all5w2hProvider =
    FutureProvider.autoDispose<Map<String, List<Task5w2hModel>>>((ref) async {
  final repo = ref.watch(task5w2hRepositoryProvider);
  return repo.fetchAllForWorkspace();
});

// ────────────────────────────────────────────────────────────────────────────
// Widget principal
// ────────────────────────────────────────────────────────────────────────────

class TasksTableView extends ConsumerWidget {
  final List<TaskData> tasks;

  const TasksTableView({super.key, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async5w2h = ref.watch(_all5w2hProvider);

    return async5w2h.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Erro ao carregar dados 5W2H: $e',
          style: TextStyle(color: context.cTextMuted),
        ),
      ),
      data: (map5w2h) => _TableContent(tasks: tasks, map5w2h: map5w2h),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Conteúdo da tabela
// ────────────────────────────────────────────────────────────────────────────

class _TableContent extends StatefulWidget {
  final List<TaskData> tasks;
  final Map<String, List<Task5w2hModel>> map5w2h;

  const _TableContent({required this.tasks, required this.map5w2h});

  @override
  State<_TableContent> createState() => _TableContentState();
}

class _TableContentState extends State<_TableContent> {
  // Coluna de ordenação
  String _sortColumn = 'title';
  bool _sortAsc = true;

  // Quais colunas 5W2H estão visíveis (toggle por coluna)
  final Set<String> _visible5w2h = {
    'what', 'why', 'where', 'when', 'who', 'how', 'how_much'
  };

  final _scrollH = ScrollController();
  final _scrollV = ScrollController();

  @override
  void dispose() {
    _scrollH.dispose();
    _scrollV.dispose();
    super.dispose();
  }

  List<TaskData> get _sorted {
    final list = [...widget.tasks];
    list.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'status':
          cmp = a.status.compareTo(b.status);
          break;
        case 'priority':
          const ord = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
          cmp = (ord[a.priority] ?? 9).compareTo(ord[b.priority] ?? 9);
          break;
        case 'due':
          final ad = a.dueDate?.millisecondsSinceEpoch ?? 9999999999999;
          final bd = b.dueDate?.millisecondsSinceEpoch ?? 9999999999999;
          cmp = ad.compareTo(bd);
          break;
        default: // title
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  void _setSort(String col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortColumn = col;
        _sortAsc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        context.isDark ? AppColors.borderDark : AppColors.border;
    final headerBg = context.isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;

    // Colunas fixas de tarefa
    const taskCols = <_ColDef>[
      _ColDef('count',     '# Planos',     64),
      _ColDef('status',    '📌 Status',    80),
      _ColDef('title',     'Tarefa',       260, flex: true),
      _ColDef('priority',  'Prioridade',   100),
      _ColDef('project',   'Projeto',      140),
      _ColDef('due',       'Vencimento',   110),
    ];

    // Colunas 5W2H
    const w2hCols = <_ColDef>[
      _ColDef('what',     'W1 · O quê?',      200),
      _ColDef('why',      'W2 · Por quê?',    200),
      _ColDef('where',    'W3 · Onde?',       160),
      _ColDef('when',     'W4 · Quando?',     160),
      _ColDef('who',      'W5 · Quem?',       160),
      _ColDef('how',      'H1 · Como?',       220),
      _ColDef('how_much', 'H2 · Quanto?',     160),
    ];

    final visibleW2h =
        w2hCols.where((c) => _visible5w2h.contains(c.id)).toList();

    final sorted = _sorted;

    return Column(
      children: [
        // ── Toolbar de colunas ──────────────────────────────
        _ColumnToggleBar(
          w2hCols: w2hCols,
          visible: _visible5w2h,
          onToggle: (id) => setState(() {
            if (_visible5w2h.contains(id)) {
              _visible5w2h.remove(id);
            } else {
              _visible5w2h.add(id);
            }
          }),
          taskCount: sorted.length,
        ),

        // ── Tabela (LayoutBuilder garante altura finita para o Expanded interno) ──
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _scrollH,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollH,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _totalWidth(taskCols, visibleW2h),
                    height: constraints.maxHeight, // altura finita → Expanded funciona
                    child: Column(
                      children: [
                        _TableHeader(
                          taskCols: taskCols,
                          w2hCols: visibleW2h,
                          sortCol: _sortColumn,
                          sortAsc: _sortAsc,
                          onSort: _setSort,
                          borderColor: borderColor,
                          headerBg: headerBg,
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollV,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollV,
                              itemCount: sorted.length,
                              itemBuilder: (ctx, i) {
                                final task = sorted[i];
                                final list5w2h = widget.map5w2h[task.id] ?? [];
                                return _TableDataRow(
                                  task: task,
                                  list5w2h: list5w2h,
                                  taskCols: taskCols,
                                  w2hCols: visibleW2h,
                                  even: i.isEven,
                                  borderColor: borderColor,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _totalWidth(List<_ColDef> fixed, List<_ColDef> w2h) {
    double w = fixed.fold(0, (s, c) => s + c.width);
    w += w2h.fold(0, (s, c) => s + c.width);
    return w;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Definição de coluna
// ────────────────────────────────────────────────────────────────────────────

class _ColDef {
  final String id;
  final String label;
  final double width;
  final bool flex;
  const _ColDef(this.id, this.label, this.width, {this.flex = false});
}

// ────────────────────────────────────────────────────────────────────────────
// Toolbar de toggle de colunas 5W2H
// ────────────────────────────────────────────────────────────────────────────

class _ColumnToggleBar extends StatelessWidget {
  final List<_ColDef> w2hCols;
  final Set<String> visible;
  final ValueChanged<String> onToggle;
  final int taskCount;

  const _ColumnToggleBar({
    required this.w2hCols,
    required this.visible,
    required this.onToggle,
    required this.taskCount,
  });

  // cor por campo
  static Color _fieldColor(String id) => switch (id) {
        'what'     => AppColors.primary,
        'why'      => const Color(0xFF8B5CF6),
        'where'    => const Color(0xFF10B981),
        'when'     => const Color(0xFFF59E0B),
        'who'      => const Color(0xFF06B6D4),
        'how'      => const Color(0xFFEC4899),
        'how_much' => const Color(0xFFF97316),
        _          => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
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
          const SizedBox(width: AppSpacing.sp16),
          Icon(Icons.table_chart_outlined,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '$taskCount tarefa${taskCount != 1 ? 's' : ''} · colunas 5W2H:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.cTextMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: w2hCols.map((c) {
                  final on = visible.contains(c.id);
                  final color = _fieldColor(c.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onToggle(c.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: on
                              ? color.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: on
                                ? color
                                : (context.isDark
                                    ? AppColors.borderDark
                                    : AppColors.border),
                            width: on ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: on
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: on ? color : context.cTextMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Cabeçalho da tabela
// ────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final List<_ColDef> taskCols;
  final List<_ColDef> w2hCols;
  final String sortCol;
  final bool sortAsc;
  final ValueChanged<String> onSort;
  final Color borderColor;
  final Color headerBg;

  const _TableHeader({
    required this.taskCols,
    required this.w2hCols,
    required this.sortCol,
    required this.sortAsc,
    required this.onSort,
    required this.borderColor,
    required this.headerBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(children: [
        // Colunas de tarefa
        ...taskCols.map((c) => _HeaderCell(
              col: c,
              sortCol: sortCol,
              sortAsc: sortAsc,
              onSort: onSort,
              borderColor: borderColor,
              isTask: true,
            )),
        // Separador visual entre tarefa e 5W2H
        if (w2hCols.isNotEmpty)
          Container(
            width: 2,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        // Colunas 5W2H
        ...w2hCols.map((c) => _HeaderCell(
              col: c,
              sortCol: sortCol,
              sortAsc: sortAsc,
              onSort: null,
              borderColor: borderColor,
              isTask: false,
            )),
      ]),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final _ColDef col;
  final String sortCol;
  final bool sortAsc;
  final ValueChanged<String>? onSort;
  final Color borderColor;
  final bool isTask;

  const _HeaderCell({
    required this.col,
    required this.sortCol,
    required this.sortAsc,
    required this.onSort,
    required this.borderColor,
    required this.isTask,
  });

  @override
  Widget build(BuildContext context) {
    final active = sortCol == col.id;
    return GestureDetector(
      onTap: onSort != null ? () => onSort!(col.id) : null,
      child: Container(
        width: col.width,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              col.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active
                    ? AppColors.primary
                    : (isTask
                        ? context.cTextPrimary
                        : AppColors.primary.withValues(alpha: 0.7)),
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (onSort != null && active)
            Icon(
              sortAsc
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 12,
              color: AppColors.primary,
            ),
        ]),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Linha de dados
// ────────────────────────────────────────────────────────────────────────────

class _TableDataRow extends ConsumerWidget {
  final TaskData task;
  final List<Task5w2hModel> list5w2h;
  final List<_ColDef> taskCols;
  final List<_ColDef> w2hCols;
  final bool even;
  final Color borderColor;

  const _TableDataRow({
    required this.task,
    required this.list5w2h,
    required this.taskCols,
    required this.w2hCols,
    required this.even,
    required this.borderColor,
  });

  Task5w2hModel? get _first => list5w2h.isEmpty ? null : list5w2h.first;

  // ── Helpers de display ──────────────────────────────────
  static Color _statusColor(String s) => switch (s) {
        'todo'        => AppColors.statusTodo,
        'in_progress' => AppColors.statusInProgress,
        'review'      => AppColors.statusReview,
        'done'        => AppColors.statusDone,
        'cancelled'   => AppColors.statusCancelled,
        _             => AppColors.textDisabled,
      };

  static String _statusLabel(String s) => switch (s) {
        'todo'        => 'A fazer',
        'in_progress' => 'Em progresso',
        'review'      => 'Revisão',
        'done'        => 'Concluída',
        'cancelled'   => 'Cancelada',
        _             => s,
      };

  static Color _priorityColor(String p) => switch (p) {
        'urgent' => AppColors.error,
        'high'   => AppColors.warning,
        'medium' => AppColors.primary,
        'low'    => AppColors.textMuted,
        _        => AppColors.textMuted,
      };

  static String _priorityLabel(String p) => switch (p) {
        'urgent' => '🔴 Urgente',
        'high'   => '🟠 Alta',
        'medium' => '🔵 Média',
        'low'    => '⚪ Baixa',
        _        => p,
      };

  String? _w2hValue(String key) {
    final m = _first;
    if (m == null) return null;
    return switch (key) {
      'what'     => m.what,
      'why'      => m.why,
      'where'    => m.whereTask,
      'when'     => m.whenDetails,
      'who'      => m.whoDetails,
      'how'      => m.how,
      'how_much' => m.howMuch,
      _          => null,
    };
  }

  static Color _w2hColor(String id) => switch (id) {
        'what'     => AppColors.primary,
        'why'      => const Color(0xFF8B5CF6),
        'where'    => const Color(0xFF10B981),
        'when'     => const Color(0xFFF59E0B),
        'who'      => const Color(0xFF06B6D4),
        'how'      => const Color(0xFFEC4899),
        'how_much' => const Color(0xFFF97316),
        _          => AppColors.primary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowBg = even
        ? (context.isDark ? AppColors.surfaceDark : AppColors.surface)
        : (context.isDark
            ? AppColors.surfaceVariantDark.withValues(alpha: 0.4)
            : AppColors.surfaceVariant.withValues(alpha: 0.5));

    final today = DateTime.now();
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime(today.year, today.month, today.day)) &&
        task.status != 'done';

    return GestureDetector(
      onTap: () => context.push('/tasks/${task.id}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: rowBg,
            border:
                Border(bottom: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: Row(children: [
            // ── Colunas de tarefa ────────────────────────
            // Count badge
            _DataCell(
              width: 64,
              borderColor: borderColor,
              child: list5w2h.isEmpty
                  ? Text('—',
                      style: TextStyle(
                          fontSize: 12, color: context.cTextMuted))
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${list5w2h.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
            // Status
            _DataCell(
              width: 80,
              borderColor: borderColor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(task.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: _statusColor(task.status).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _statusLabel(task.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(task.status),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Título
            _DataCell(
              width: 260,
              borderColor: borderColor,
              child: Text(
                task.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.cTextPrimary,
                  decoration: task.status == 'done'
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            // Prioridade
            _DataCell(
              width: 100,
              borderColor: borderColor,
              child: Text(
                _priorityLabel(task.priority),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _priorityColor(task.priority),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Projeto
            _DataCell(
              width: 140,
              borderColor: borderColor,
              child: task.projectName != null
                  ? Text(
                      task.projectName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text('—',
                      style: TextStyle(
                          fontSize: 12, color: context.cTextMuted)),
            ),
            // Vencimento
            _DataCell(
              width: 110,
              borderColor: borderColor,
              child: task.dueDate != null
                  ? Row(children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: isOverdue ? AppColors.error : context.cTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(task.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? AppColors.error : context.cTextMuted,
                          fontWeight: isOverdue
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ])
                  : Text('—',
                      style: TextStyle(
                          fontSize: 12, color: context.cTextMuted)),
            ),

            // ── Separador visual ──────────────────────────
            if (w2hCols.isNotEmpty)
              Container(width: 2, color: AppColors.primary.withValues(alpha: 0.15)),

            // ── Colunas 5W2H ──────────────────────────────
            ...w2hCols.map((c) {
              final val = _w2hValue(c.id);
              final hasVal = val != null && val.trim().isNotEmpty;
              return _DataCell(
                width: c.width,
                borderColor: borderColor,
                child: hasVal
                    ? Text(
                        val,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.cTextPrimary,
                        ),
                      )
                    : Row(children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _w2hColor(c.id).withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Não informado',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.cTextMuted.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ]),
              );
            }),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Célula genérica ──────────────────────────────────────────

class _DataCell extends StatelessWidget {
  final double width;
  final Widget child;
  final Color borderColor;

  const _DataCell({
    required this.width,
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}
