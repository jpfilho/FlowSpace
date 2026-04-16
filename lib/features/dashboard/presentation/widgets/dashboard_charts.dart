import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/domain/data_providers.dart';

/// Dashboard charts: Donut chart (tasks por status) + Bar chart (por prioridade)
class DashboardChartsWidget extends ConsumerWidget {
  const DashboardChartsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final isDesktop = Responsive.isDesktop(context);

    return tasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();

        return isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StatusDonut(tasks: tasks)),
                  const SizedBox(width: AppSpacing.sp20),
                  Expanded(child: _PriorityBars(tasks: tasks)),
                ],
              )
            : Column(
                children: [
                  _StatusDonut(tasks: tasks),
                  const SizedBox(height: AppSpacing.sp20),
                  _PriorityBars(tasks: tasks),
                ],
              );
      },
    );
  }
}

// ── Donut Chart: Tarefas por Status ──────────────────────────
class _StatusDonut extends StatefulWidget {
  final List<TaskData> tasks;
  const _StatusDonut({required this.tasks});

  @override
  State<_StatusDonut> createState() => _StatusDonutState();
}

class _StatusDonutState extends State<_StatusDonut> {
  int _touchedIndex = -1;

  static const _statusMap = {
    'todo': ('A fazer', AppColors.statusTodo),
    'in_progress': ('Em progresso', AppColors.statusInProgress),
    'review': ('Revisão', AppColors.statusReview),
    'done': ('Concluído', AppColors.statusDone),
    'cancelled': ('Cancelado', AppColors.statusCancelled),
  };

  @override
  Widget build(BuildContext context) {
    // Count tasks per status
    final counts = <String, int>{};
    for (final t in widget.tasks) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }

    final entries = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ChartCard(
      title: 'Por Status',
      icon: Icons.donut_large_rounded,
      height: 280,
      child: Row(children: [
        // Donut
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final info = _statusMap[entry.key];
                final isTouched = idx == _touchedIndex;
                return PieChartSectionData(
                  color: info?.$2 ?? AppColors.textMuted,
                  value: entry.value.toDouble(),
                  title: isTouched ? '${entry.value}' : '',
                  radius: isTouched ? 38 : 32,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sp20),
        // Legend
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              final info = _statusMap[e.key];
              final pct =
                  (e.value / widget.tasks.length * 100).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: info?.$2 ?? AppColors.textMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info?.$1 ?? e.key,
                      style: TextStyle(
                          fontSize: 12, color: context.cTextPrimary),
                    ),
                  ),
                  Text(
                    '${e.value} ($pct%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.cTextMuted,
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ── Bar Chart: Tarefas por Prioridade ────────────────────────
class _PriorityBars extends StatefulWidget {
  final List<TaskData> tasks;
  const _PriorityBars({required this.tasks});

  @override
  State<_PriorityBars> createState() => _PriorityBarsState();
}

class _PriorityBarsState extends State<_PriorityBars> {
  int _touchedIndex = -1;

  static const _priorities = [
    ('urgent', 'Urgente', AppColors.error),
    ('high', 'Alta', AppColors.warning),
    ('medium', 'Média', AppColors.primary),
    ('low', 'Baixa', AppColors.textMuted),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final t in widget.tasks) {
      counts[t.priority] = (counts[t.priority] ?? 0) + 1;
    }

    final maxVal = counts.values.fold(0, (a, b) => a > b ? a : b);

    return _ChartCard(
      title: 'Por Prioridade',
      icon: Icons.bar_chart_rounded,
      height: 280,
      child: Column(children: [
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.spot!.touchedBarGroupIndex;
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => context.isDark
                      ? AppColors.surfaceDark
                      : AppColors.surface,
                  tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final info = _priorities[group.x.toInt()];
                    return BarTooltipItem(
                      '${info.$2}: ${rod.toY.toInt()}',
                      TextStyle(
                        color: info.$3,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxVal / 4).ceilToDouble().clamp(1, 100),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: (context.isDark
                          ? AppColors.borderDark
                          : AppColors.border)
                      .withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 10, color: context.cTextMuted),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _priorities.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _priorities[idx].$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _touchedIndex == idx
                                ? _priorities[idx].$3
                                : context.cTextMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _priorities.asMap().entries.map((e) {
                final idx = e.key;
                final info = e.value;
                final count = counts[info.$1] ?? 0;
                final isTouched = _touchedIndex == idx;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      color: info.$3.withValues(alpha: isTouched ? 1.0 : 0.7),
                      width: isTouched ? 24 : 18,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxVal.toDouble() * 1.2,
                        color: info.$3.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                );
              }).toList(),
              maxY: maxVal.toDouble() * 1.3,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Card wrapper reutilizável ────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double height;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.sp20),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.cTextPrimary,
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.sp20),
          Expanded(child: child),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}
