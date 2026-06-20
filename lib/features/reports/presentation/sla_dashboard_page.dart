import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../../shared/widgets/common/flow_states.dart';
import '../../auth/domain/data_providers.dart';

class SlaDashboard extends ConsumerWidget {
  const SlaDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final isDesktop = Responsive.isDesktop(context);

    return tasksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => FlowErrorState(
        message: 'Erro ao carregar dados: $err',
        onRetry: () => ref.refresh(tasksProvider),
      ),
      data: (tasks) {
        final slaTasks = tasks.where((t) => t.isSlaCritical).toList();

        if (slaTasks.isEmpty) {
          return const FlowEmptyState(
            icon: Icons.alarm_off_rounded,
            title: 'Nenhuma tarefa com SLA Crítico',
            subtitle: 'Marque a opção "SLA Crítico" ao criar ou editar uma tarefa para ver as análises aqui.',
          );
        }

        // Calculations
        final totalSla = slaTasks.length;
        
        int overdueSlaCount = 0;
        int onTimeSlaCount = 0;
        
        final List<Duration> completionDurations = [];

        for (final t in slaTasks) {
          bool isOverdue = false;
          if (t.deadlineAt != null) {
            if (t.isDone) {
              isOverdue = t.completedAt != null && t.completedAt!.isAfter(t.deadlineAt!);
            } else {
              isOverdue = DateTime.now().isAfter(t.deadlineAt!);
            }
          }
          
          if (isOverdue) {
            overdueSlaCount++;
          } else {
            onTimeSlaCount++;
          }

          if (t.isDone && t.completedAt != null && t.createdAt != null) {
            completionDurations.add(t.completedAt!.difference(t.createdAt!));
          }
        }

        final onTimePercentVal = totalSla > 0 
            ? (onTimeSlaCount / totalSla * 100)
            : 100.0;
        final onTimeRate = onTimePercentVal.toStringAsFixed(0);

        String avgResolutionTime = '-';
        if (completionDurations.isNotEmpty) {
          final totalMs = completionDurations.fold(0, (sum, dur) => sum + dur.inMilliseconds);
          final avgMs = totalMs ~/ completionDurations.length;
          final avgDuration = Duration(milliseconds: avgMs);
          
          if (avgDuration.inDays > 0) {
            avgResolutionTime = '${avgDuration.inDays}d ${avgDuration.inHours % 24}h';
          } else if (avgDuration.inHours > 0) {
            avgResolutionTime = '${avgDuration.inHours}h ${avgDuration.inMinutes % 60}m';
          } else {
            avgResolutionTime = '${avgDuration.inMinutes}m';
          }
        }

        // Upcoming deadlines
        final upcomingSlaTasks = slaTasks
            .where((t) => !t.isDone && t.deadlineAt != null)
            .toList();
        // Sort by deadlineAt ascending
        upcomingSlaTasks.sort((a, b) => a.deadlineAt!.compareTo(b.deadlineAt!));

        final kpis = [
          (
            'Total SLA Crítico',
            '$totalSla',
            Icons.assignment_late_rounded,
            AppColors.primary,
            'Tarefas prioritárias',
          ),
          (
            'Resolvidas / Em Dia',
            '$onTimeSlaCount',
            Icons.check_circle_rounded,
            AppColors.success,
            '$onTimeRate% de conformidade',
          ),
          (
            'Em Atraso',
            '$overdueSlaCount',
            Icons.warning_amber_rounded,
            AppColors.error,
            overdueSlaCount > 0 ? 'Exige atenção imediata' : 'Nenhuma atrasada',
          ),
          (
            'Resolução Média',
            avgResolutionTime,
            Icons.speed_rounded,
            AppColors.accent,
            'Tempo médio de conclusão',
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid
            LayoutBuilder(builder: (ctx, constraints) {
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
                  return _SlaKpiCard(
                    label: label,
                    value: value,
                    icon: icon,
                    color: color,
                    subtitle: subtitle,
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: AppSpacing.sp32),

            // Charts & Upcoming
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _SlaDistributionChart(
                          onTime: onTimeSlaCount,
                          overdue: overdueSlaCount,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp20),
                      Expanded(
                        flex: 6,
                        child: _UpcomingDeadlinesCard(tasks: upcomingSlaTasks),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _SlaDistributionChart(
                        onTime: onTimeSlaCount,
                        overdue: overdueSlaCount,
                      ),
                      const SizedBox(height: AppSpacing.sp20),
                      _UpcomingDeadlinesCard(tasks: upcomingSlaTasks),
                    ],
                  ),
          ],
        );
      },
    );
  }
}

class _SlaKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _SlaKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
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
              Text(subtitle,
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

class _SlaDistributionChart extends StatelessWidget {
  final int onTime;
  final int overdue;

  const _SlaDistributionChart({
    required this.onTime,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    final total = onTime + overdue;
    final onTimePercent = total > 0 ? (onTime / total * 100).toStringAsFixed(1) : '0';
    final overduePercent = total > 0 ? (overdue / total * 100).toStringAsFixed(1) : '0';

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
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Distribuição do SLA',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.sp24),
          if (total == 0)
            const SizedBox(
              height: 200,
              child: Center(child: Text('Nenhum dado disponível')),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: onTime.toDouble(),
                            color: AppColors.success,
                            title: '$onTimePercent%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: overdue.toDouble(),
                            color: AppColors.error,
                            title: '$overduePercent%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sp16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChartLegendItem(
                      color: AppColors.success,
                      label: 'No Prazo / Resolvido',
                      value: '$onTime',
                    ),
                    const SizedBox(height: 8),
                    _ChartLegendItem(
                      color: AppColors.error,
                      label: 'Em Atraso',
                      value: '$overdue',
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: context.cTextMuted)),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.cTextPrimary)),
      ],
    );
  }
}

class _UpcomingDeadlinesCard extends StatelessWidget {
  final List<TaskData> tasks;

  const _UpcomingDeadlinesCard({required this.tasks});

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
          Row(
            children: [
              const Icon(Icons.alarm_on_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('Próximos Prazos Críticos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${tasks.length} pendente${tasks.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp16),
          if (tasks.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text('Nenhuma tarefa crítica pendente! 🎉',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500)),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => Divider(
                  color: context.isDark ? AppColors.borderDark : AppColors.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final deadline = task.deadlineAt!;
                  final now = DateTime.now();
                  final isOverdue = deadline.isBefore(now);
                  final diff = deadline.difference(now);
                  final isNear = diff.inMinutes <= 60 && !diff.isNegative;

                  final badgeColor = isOverdue
                      ? AppColors.error
                      : isNear
                          ? AppColors.warning
                          : AppColors.primary;

                  String timeText;
                  if (isOverdue) {
                    final hours = diff.abs().inHours;
                    if (hours > 0) {
                      timeText = 'Atrasada há ${hours}h';
                    } else {
                      timeText = 'Atrasada há ${diff.abs().inMinutes} min';
                    }
                  } else {
                    final hours = diff.inHours;
                    if (hours > 24) {
                      timeText = 'Vence em ${diff.inDays} dias';
                    } else if (hours > 0) {
                      timeText = 'Vence em ${hours}h';
                    } else {
                      timeText = 'Vence em ${diff.inMinutes} min';
                    }
                  }

                  return InkWell(
                    onTap: () => context.go('/tasks/${task.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (task.projectName != null) ...[
                                      Text(
                                        task.projectName!,
                                        style: TextStyle(fontSize: 11, color: context.cTextMuted),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      'Prazo: ${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')} às ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 11, color: context.cTextMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
