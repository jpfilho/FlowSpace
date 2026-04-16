import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';
import '../../auth/domain/data_providers.dart';

// ── Report Data Providers ─────────────────────────────────────

/// Tasks grouped by status
final tasksByStatusProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final tasks = await ref.watch(tasksProvider.future);
  final map = <String, int>{};
  for (final t in tasks) {
    map[t.status] = (map[t.status] ?? 0) + 1;
  }
  return map;
});

/// Tasks grouped by priority
final tasksByPriorityProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final tasks = await ref.watch(tasksProvider.future);
  final map = <String, int>{};
  for (final t in tasks) {
    map[t.priority] = (map[t.priority] ?? 0) + 1;
  }
  return map;
});

/// Tasks completed per day (last 7 days)
final tasksCompletedPerDayProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final client = ref.read(supabaseProvider);
  final ws = await ref.read(currentWorkspaceProvider.future);
  if (ws == null) return {};

  final since = DateTime.now().subtract(const Duration(days: 6));
  final data = await client
      .from('tasks')
      .select('updated_at')
      .eq('workspace_id', ws.id)
      .eq('status', 'done')
      .gte('updated_at', since.toIso8601String());

  final map = <String, int>{};
  // Initialize last 7 days
  for (int i = 6; i >= 0; i--) {
    final day = DateTime.now().subtract(Duration(days: i));
    final key = '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';
    map[key] = 0;
  }

  for (final row in data as List) {
    final dt = DateTime.parse(row['updated_at'] as String).toLocal();
    final key = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    if (map.containsKey(key)) {
      map[key] = (map[key] ?? 0) + 1;
    }
  }
  return map;
});

/// Tasks overdue count
final overdueTasksCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final tasks = await ref.watch(tasksProvider.future);
  final now = DateTime.now();
  return tasks.where((t) {
    if (t.dueDate == null) return false;
    if (t.status == 'done' || t.status == 'cancelled') return false;
    return t.dueDate!.isBefore(now);
  }).length;
});

// ═══════════════════════════════════════════════════════════════
// REPORTS PAGE
// ═══════════════════════════════════════════════════════════════

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
            isDesktop ? AppSpacing.sp32 : AppSpacing.sp20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ──────────────────────────────────
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sp12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reports & Analytics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                Text('Visão geral da produtividade do workspace',
                    style: context.bodySm),
              ]),
            ]),
            const SizedBox(height: AppSpacing.sp32),

            // ── KPI Cards ─────────────────────────────────────
            _KpiRow(),
            const SizedBox(height: AppSpacing.sp32),

            // ── Charts grid ──────────────────────────────────
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TasksByStatusChart()),
                      const SizedBox(width: AppSpacing.sp20),
                      Expanded(child: _TasksByPriorityChart()),
                    ],
                  )
                : Column(children: [
                    _TasksByStatusChart(),
                    const SizedBox(height: AppSpacing.sp20),
                    _TasksByPriorityChart(),
                  ]),
            const SizedBox(height: AppSpacing.sp24),

            // ── Line chart: completions per day ────────────
            _CompletionsPerDayChart(),
          ],
        ),
      ),
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────
class _KpiRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final overdueAsync = ref.watch(overdueTasksCountProvider);
    final byStatusAsync = ref.watch(tasksByStatusProvider);

    final totalTasks = tasksAsync.valueOrNull?.length ?? 0;
    final doneTasks = byStatusAsync.valueOrNull?['done'] ?? 0;
    final inProgressTasks = byStatusAsync.valueOrNull?['in_progress'] ?? 0;
    final overdueCount = overdueAsync.valueOrNull ?? 0;
    final doneRate =
        totalTasks > 0 ? (doneTasks / totalTasks * 100).toStringAsFixed(0) : '0';

    final kpis = [
      (
        'Total de Tarefas',
        '$totalTasks',
        Icons.task_alt_rounded,
        AppColors.primary,
        null,
      ),
      (
        'Concluídas',
        '$doneTasks',
        Icons.check_circle_rounded,
        AppColors.success,
        '$doneRate% do total',
      ),
      (
        'Em Progresso',
        '$inProgressTasks',
        Icons.timelapse_rounded,
        AppColors.accent,
        null,
      ),
      (
        'Em Atraso',
        '$overdueCount',
        Icons.warning_amber_rounded,
        AppColors.error,
        overdueCount > 0 ? 'Requer atenção' : 'Tudo ok ✓',
      ),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final crossCount = constraints.maxWidth > 700 ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sp12,
        crossAxisSpacing: AppSpacing.sp12,
        childAspectRatio: 1.6,
        children: kpis.map((kpi) {
          final (label, value, icon, color, subtitle) = kpi;
          return _KpiCard(
            label: label,
            value: value,
            icon: icon,
            color: color,
            subtitle: subtitle,
          );
        }).toList(),
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: context.cTextMuted,
                      fontWeight: FontWeight.w500)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1)),
              if (subtitle != null)
                Text(subtitle!,
                    style: TextStyle(
                        fontSize: 10,
                        color: context.cTextMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tasks by Status Donut Chart ────────────────────────────────
class _TasksByStatusChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byStatusAsync = ref.watch(tasksByStatusProvider);

    return _ChartCard(
      title: 'Por Status',
      icon: Icons.donut_small_rounded,
      child: byStatusAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data.isEmpty) return _EmptyChart();

          final statusColors = {
            'todo': AppColors.statusTodo,
            'in_progress': AppColors.statusInProgress,
            'review': AppColors.statusReview,
            'done': AppColors.statusDone,
            'cancelled': AppColors.textMuted,
          };

          final statusLabels = {
            'todo': 'A fazer',
            'in_progress': 'Em progresso',
            'review': 'Revisão',
            'done': 'Concluída',
            'cancelled': 'Cancelada',
          };

          final sections = data.entries
              .where((e) => e.value > 0)
              .map((e) {
            final color =
                statusColors[e.key] ?? AppColors.primary;
            return PieChartSectionData(
              value: e.value.toDouble(),
              color: color,
              title: '${e.value}',
              radius: 55,
              titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            );
          }).toList();

          return Row(children: [
            Expanded(
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                  duration: const Duration(milliseconds: 600),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sp16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: data.entries
                  .where((e) => e.value > 0)
                  .map((e) {
                final color =
                    statusColors[e.key] ?? AppColors.primary;
                final label =
                    statusLabels[e.key] ?? e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            color: context.cTextMuted)),
                    const SizedBox(width: 4),
                    Text('${e.value}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.cTextPrimary)),
                  ]),
                );
              }).toList(),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Tasks by Priority Bar Chart ───────────────────────────────
class _TasksByPriorityChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byPriorityAsync = ref.watch(tasksByPriorityProvider);

    return _ChartCard(
      title: 'Por Prioridade',
      icon: Icons.flag_rounded,
      child: byPriorityAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data.isEmpty) return _EmptyChart();

          final priorities = ['urgent', 'high', 'medium', 'low'];
          final colors = {
            'urgent': AppColors.error,
            'high': AppColors.warning,
            'medium': AppColors.primary,
            'low': AppColors.textMuted,
          };
          final labels = {
            'urgent': 'Urgente',
            'high': 'Alta',
            'medium': 'Média',
            'low': 'Baixa',
          };

          final maxVal = priorities
              .map((p) => (data[p] ?? 0).toDouble())
              .fold(0.0, (a, b) => a > b ? a : b);

          return SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + 1,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(
                            fontSize: 10,
                            color: context.cTextMuted),
                      ),
                      reservedSize: 24,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= priorities.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            labels[priorities[idx]] ?? '',
                            style: TextStyle(
                                fontSize: 10,
                                color: context.cTextMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: context.isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: priorities.asMap().entries.map((e) {
                  final idx = e.key;
                  final p = e.value;
                  final val = (data[p] ?? 0).toDouble();
                  return BarChartGroupData(x: idx, barRods: [
                    BarChartRodData(
                      toY: val,
                      color: colors[p] ?? AppColors.primary,
                      width: 28,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ]);
                }).toList(),
              ),
              duration: const Duration(milliseconds: 600),
            ),
          );
        },
      ),
    );
  }
}

// ── Completions per Day Line Chart ────────────────────────────
class _CompletionsPerDayChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionsAsync = ref.watch(tasksCompletedPerDayProvider);

    return _ChartCard(
      title: 'Tarefas concluídas (últimos 7 dias)',
      icon: Icons.trending_up_rounded,
      child: completionsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          final days = data.keys.toList();
          final values = data.values.toList();
          final maxVal =
              values.fold(0, (a, b) => a > b ? a : b).toDouble();

          if (values.every((v) => v == 0)) return _EmptyChart();

          final spots = List.generate(
            days.length,
            (i) => FlSpot(i.toDouble(), values[i].toDouble()),
          );

          return SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (days.length - 1).toDouble(),
                minY: 0,
                maxY: maxVal + 1,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: context.isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(
                            fontSize: 10,
                            color: context.cTextMuted),
                      ),
                      reservedSize: 24,
                      interval: 1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(days[idx],
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.cTextMuted)),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: context.isDark
                                ? AppColors.surfaceDark
                                : AppColors.surface,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 600),
            ),
          );
        },
      ),
    );
  }
}

// ── Shared chart card wrapper ─────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style: context.bodyMd
                    .copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: AppSpacing.sp20),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart_rounded,
              size: 32, color: context.cTextMuted),
          const SizedBox(height: 8),
          Text('Sem dados suficientes ainda.',
              style: context.bodySm
                  .copyWith(color: context.cTextMuted)),
        ]),
      ),
    );
  }
}
