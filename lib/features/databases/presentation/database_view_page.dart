import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../auth/domain/data_providers.dart' show supabaseProvider;
import '../domain/database_providers.dart';
import 'widgets/db_grid_cell.dart';

// ── View mode provider ────────────────────────────────────────
final _dbViewModeProvider =
    StateProvider.family<String, String>((ref, _) => 'grid'); // grid|board|gallery

class DatabaseViewPage extends ConsumerWidget {
  final String databaseId;

  const DatabaseViewPage({super.key, required this.databaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(databaseDetailProvider(databaseId));
    final rowsAsync = ref.watch(databaseRowsProvider(databaseId));
    final viewMode = ref.watch(_dbViewModeProvider(databaseId));

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor:
            context.isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: context.cTextPrimary,
          onPressed: () => context.go('/databases'),
        ),
        title: detailAsync.when(
          data: (detail) => detail == null
              ? const Text('Banco não encontrado')
              : Row(children: [
                  Icon(
                    Icons.table_chart_rounded,
                    color: Color(int.parse(
                            detail.database.color.replaceFirst('#', ''),
                            radix: 16) |
                        0xFF000000),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(detail.database.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ]),
          loading: () => const Text('Carregando...'),
          error: (_, __) => const Text('Erro'),
        ),
        actions: [
          // ── View mode switcher ──────────────────────────────
          _ViewModePill(databaseId: databaseId),
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
      body: detailAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Banco não encontrado.'));
          }
          final columns = detail.columns;

          return rowsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Erro nas linhas: $e')),
            data: (rows) {
              switch (viewMode) {
                case 'board':
                  return _BoardView(
                      databaseId: databaseId, columns: columns, rows: rows);
                case 'gallery':
                  return _GalleryView(
                      databaseId: databaseId, columns: columns, rows: rows);
                default:
                  return _DatabaseGrid(
                      databaseId: databaseId, columns: columns, rows: rows);
              }
            },
          );
        },
      ),
    );
  }
}

// ── View mode selector ────────────────────────────────────────
class _ViewModePill extends ConsumerWidget {
  final String databaseId;
  const _ViewModePill({required this.databaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_dbViewModeProvider(databaseId));

    const modes = [
      ('grid', Icons.table_rows_rounded, 'Tabela'),
      ('board', Icons.view_kanban_rounded, 'Board'),
      ('gallery', Icons.grid_view_rounded, 'Galeria'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final (value, icon, label) = m;
          final active = current == value;
          return GestureDetector(
            onTap: () =>
                ref.read(_dbViewModeProvider(databaseId).notifier).state =
                    value,
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(children: [
                Icon(icon,
                    size: 14,
                    color: active ? Colors.white : context.cTextMuted),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? Colors.white : context.cTextMuted,
                  ),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRID VIEW (tabela)
// ═══════════════════════════════════════════════════════════════

class _DatabaseGrid extends ConsumerWidget {
  final String databaseId;
  final List<DbColumnData> columns;
  final List<DbRowData> rows;

  const _DatabaseGrid({
    required this.databaseId,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double totalWidth = columns.fold(0.0, (w, c) => w + c.width);
    totalWidth += 120 + 32;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                  ),
                ),
                color: context.isDark
                    ? Colors.black12
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  ...columns.map((col) => _GridHeaderCell(col: col)),
                  // New Column Button
                  InkWell(
                    onTap: () =>
                        _showAddColumnDialog(context, ref, databaseId),
                    child: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 16, color: context.cTextMuted),
                          const SizedBox(width: 4),
                          Text('Coluna',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: context.cTextMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // ── Rows ──
            Expanded(
              child: ListView.builder(
                itemCount: rows.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == rows.length) {
                    return _NewRowButton(databaseId: databaseId);
                  }
                  final row = rows[index];
                  return _GridRow(
                    databaseId: databaseId,
                    row: row,
                    columns: columns,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridHeaderCell extends StatelessWidget {
  final DbColumnData col;
  const _GridHeaderCell({required this.col});

  IconData _iconForType(String type) => switch (type) {
        'text' => Icons.short_text_rounded,
        'number' => Icons.numbers_rounded,
        'date' => Icons.calendar_today_rounded,
        'select' => Icons.arrow_drop_down_circle_outlined,
        'checkbox' => Icons.check_box_outlined,
        _ => Icons.short_text_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: col.width.toDouble(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: context.isDark ? AppColors.borderDark : AppColors.border),
        ),
      ),
      child: Row(children: [
        Icon(_iconForType(col.type), size: 14, color: context.cTextMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(col.name,
              style:
                  context.labelMd.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _GridRow extends ConsumerStatefulWidget {
  final String databaseId;
  final DbRowData row;
  final List<DbColumnData> columns;

  const _GridRow({
    required this.databaseId,
    required this.row,
    required this.columns,
  });

  @override
  ConsumerState<_GridRow> createState() => _GridRowState();
}

class _GridRowState extends ConsumerState<_GridRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _hovering
              ? (context.isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: context.isDark
                  ? AppColors.borderDark
                  : AppColors.border,
            ),
          ),
        ),
        child: Row(children: [
          const SizedBox(width: 4),
          // Delete button on hover
          AnimatedOpacity(
            opacity: _hovering ? 1 : 0,
            duration: AppAnimations.fast,
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 14, color: AppColors.error),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Deletar linha',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Deletar linha?'),
                    content: const Text('Esta ação não pode ser desfeita.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Deletar',
                              style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await deleteDbRow(ref, widget.row.id);
                }
              },
            ),
          ),
          if (!_hovering) const SizedBox(width: 28),
          ...widget.columns.map((col) {
            final val = widget.row.data[col.id];
            return Container(
              width: col.width.toDouble(),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: context.isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                  ),
                ),
              ),
              child: DbGridCell(
                rowId: widget.row.id,
                colId: col.id,
                colType: col.type,
                value: val,
              ),
            );
          }),
          const SizedBox(width: 120),
          const SizedBox(width: 16),
        ]),
      ),
    );
  }
}

class _NewRowButton extends ConsumerWidget {
  final String databaseId;
  const _NewRowButton({required this.databaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => addDbRow(ref, databaseId, {}),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        alignment: Alignment.centerLeft,
        child: Row(children: [
          const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Nova linha',
              style: context.bodyMd.copyWith(color: AppColors.primary)),
        ]),
      ),
    );
  }
}

// ── Add Column Dialog ─────────────────────────────────────────
void _showAddColumnDialog(
    BuildContext context, WidgetRef ref, String databaseId) {
  final nameCtrl = TextEditingController();
  String selectedType = 'text';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor:
            ctx.isDark ? AppColors.surfaceDark : AppColors.surface,
        title: const Text('Nova coluna'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Nome da coluna', hintText: 'ex: Status'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Texto')),
              DropdownMenuItem(value: 'number', child: Text('Numero')),
              DropdownMenuItem(value: 'date', child: Text('Data')),
              DropdownMenuItem(value: 'select', child: Text('Select')),
              DropdownMenuItem(value: 'checkbox', child: Text('Checkbox')),
            ],
            onChanged: (v) => setState(() => selectedType = v!),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final client = ref.read(supabaseProvider);
              // Get max position
              final colsRes = await client
                  .from('db_columns')
                  .select('position')
                  .eq('database_id', databaseId)
                  .order('position', ascending: false)
                  .limit(1)
                  .maybeSingle();
              final maxPos =
                  colsRes != null ? (colsRes['position'] as int? ?? 0) : 0;

              await client.from('db_columns').insert({
                'database_id': databaseId,
                'name': nameCtrl.text.trim(),
                'type': selectedType,
                'position': maxPos + 1000,
                'width': 200,
              });
              // ignore: unused_result
              ref.invalidate(databaseDetailProvider(databaseId));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// BOARD VIEW (Kanban)
// ═══════════════════════════════════════════════════════════════

class _BoardView extends ConsumerWidget {
  final String databaseId;
  final List<DbColumnData> columns;
  final List<DbRowData> rows;

  const _BoardView({
    required this.databaseId,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find the first 'select' column to group by, or fall back to no grouping
    final selectCol = columns.where((c) => c.type == 'select').firstOrNull;
    final titleCol = columns.firstOrNull;

    if (selectCol == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.view_kanban_rounded,
                size: 64, color: context.cTextMuted),
            const SizedBox(height: 16),
            Text('Board requer uma coluna do tipo Select',
                style: context.headingMd, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
                'Adicione uma coluna "Select" na tabela para agrupar os cards.',
                style: context.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar coluna Select'),
              onPressed: () => _showAddColumnDialog(context, ref, databaseId),
            ),
          ]),
        ),
      );
    }

    // Get unique group values from the rows + fallback "Sem grupo"
    final allValues = rows
        .map((r) => r.data[selectCol.id]?.toString() ?? '')
        .toSet()
        .toList()
      ..sort();

    if (!allValues.contains('')) allValues.insert(0, '');

    // Group colors
    final groupColors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.accent,
      AppColors.error,
      AppColors.textMuted,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.sp20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allValues.asMap().entries.map((entry) {
          final idx = entry.key;
          final groupValue = entry.value;
          final groupRows =
              rows.where((r) => (r.data[selectCol.id]?.toString() ?? '') == groupValue).toList();
          final color = groupColors[idx % groupColors.length];
          final label = groupValue.isEmpty ? 'Sem grupo' : groupValue;

          return _BoardColumn(
            databaseId: databaseId,
            label: label,
            color: color,
            rows: groupRows,
            columns: columns,
            titleCol: titleCol,
            selectCol: selectCol,
            groupValue: groupValue,
          );
        }).toList(),
      ),
    );
  }
}

class _BoardColumn extends ConsumerWidget {
  final String databaseId;
  final String label;
  final Color color;
  final List<DbRowData> rows;
  final List<DbColumnData> columns;
  final DbColumnData? titleCol;
  final DbColumnData selectCol;
  final String groupValue;

  const _BoardColumn({
    required this.databaseId,
    required this.label,
    required this.color,
    required this.rows,
    required this.columns,
    required this.titleCol,
    required this.selectCol,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: AppSpacing.sp12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Column header ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp12, vertical: AppSpacing.sp10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
              border: Border(
                  top: BorderSide(color: color, width: 3),
                  left: BorderSide(
                      color: color.withValues(alpha: 0.2)),
                  right: BorderSide(
                      color: color.withValues(alpha: 0.2))),
            ),
            child: Row(children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('${rows.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),
          ),

          // ── Cards ──
          Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppColors.surfaceDark
                  : AppColors.surface,
              border: Border(
                  left: BorderSide(
                      color: color.withValues(alpha: 0.2)),
                  right: BorderSide(
                      color: color.withValues(alpha: 0.2)),
                  bottom: BorderSide(
                      color: color.withValues(alpha: 0.2))),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.sp8),
              itemCount: rows.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sp6),
              itemBuilder: (ctx, i) {
                if (i == rows.length) {
                  return _BoardAddCard(
                    databaseId: databaseId,
                    selectCol: selectCol,
                    groupValue: groupValue,
                  );
                }
                final row = rows[i];
                return _BoardCard(
                  row: row,
                  columns: columns,
                  titleCol: titleCol,
                  color: color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends ConsumerWidget {
  final DbRowData row;
  final List<DbColumnData> columns;
  final DbColumnData? titleCol;
  final Color color;

  const _BoardCard({
    required this.row,
    required this.columns,
    required this.titleCol,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = titleCol != null
        ? (row.data[titleCol!.id]?.toString() ?? 'Sem título')
        : 'Sem título';

    // Secondary fields (skip the title col)
    final secondaryCols = columns
        .where((c) => c.id != titleCol?.id && c.type != 'select')
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp12),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title.isEmpty ? 'Sem título' : title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.cTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (secondaryCols.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...secondaryCols.map((col) {
              final val = row.data[col.id];
              if (val == null || val.toString().isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Text('${col.name}:',
                      style: TextStyle(
                          fontSize: 10,
                          color: context.cTextMuted,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      val.toString(),
                      style: TextStyle(
                          fontSize: 11, color: context.cTextPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              );
            }),
          ],
          // Delete button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => deleteDbRow(ref, row.id),
              child: Icon(Icons.delete_outline_rounded,
                  size: 14, color: context.cTextMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardAddCard extends ConsumerWidget {
  final String databaseId;
  final DbColumnData selectCol;
  final String groupValue;

  const _BoardAddCard({
    required this.databaseId,
    required this.selectCol,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => addDbRow(ref, databaseId, {selectCol.id: groupValue}),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: context.isDark ? AppColors.borderDark : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 14, color: context.cTextMuted),
            const SizedBox(width: 4),
            Text('Adicionar card',
                style: TextStyle(fontSize: 12, color: context.cTextMuted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GALLERY VIEW
// ═══════════════════════════════════════════════════════════════

class _GalleryView extends ConsumerWidget {
  final String databaseId;
  final List<DbColumnData> columns;
  final List<DbRowData> rows;

  const _GalleryView({
    required this.databaseId,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleCol = columns.firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      child: Column(
        children: [
          // Header bar
          Row(children: [
            Text('${rows.length} registro${rows.length != 1 ? 's' : ''}',
                style: context.bodySm),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Novo card'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
              ),
              onPressed: () => addDbRow(ref, databaseId, {}),
            ),
          ]),
          const SizedBox(height: AppSpacing.sp16),

          // Gallery grid
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view_rounded,
                            size: 64, color: context.cTextMuted),
                        const SizedBox(height: 12),
                        Text('Nenhum registro ainda',
                            style: context.headingMd),
                        const SizedBox(height: 8),
                        Text('Clique em "Novo card" para começar.',
                            style: context.bodySm),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      crossAxisSpacing: AppSpacing.sp12,
                      mainAxisSpacing: AppSpacing.sp12,
                      childAspectRatio: 3 / 2,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (ctx, i) {
                      final row = rows[i];
                      return _GalleryCard(
                        row: row,
                        columns: columns,
                        titleCol: titleCol,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GalleryCard extends ConsumerWidget {
  final DbRowData row;
  final List<DbColumnData> columns;
  final DbColumnData? titleCol;

  const _GalleryCard({
    required this.row,
    required this.columns,
    required this.titleCol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = titleCol != null
        ? (row.data[titleCol!.id]?.toString() ?? '')
        : '';

    final otherCols = columns
        .where((c) => c.id != titleCol?.id)
        .take(4)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp14),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + delete
          Row(children: [
            Expanded(
              child: Text(
                title.isEmpty ? 'Sem título' : title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => deleteDbRow(ref, row.id),
              child: Icon(Icons.delete_outline_rounded,
                  size: 14, color: context.cTextMuted),
            ),
          ]),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Fields
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: otherCols.map((col) {
                final val = row.data[col.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Text('${col.name}:',
                        style: TextStyle(
                            fontSize: 10,
                            color: context.cTextMuted,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        val?.toString() ?? '—',
                        style: TextStyle(
                            fontSize: 11,
                            color: val != null
                                ? context.cTextPrimary
                                : context.cTextMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
