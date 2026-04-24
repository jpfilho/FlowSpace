import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/tasks/presentation/tasks_page.dart'
    show taskOverdueFilterProvider;
import '../domain/focus_providers.dart';

class FocusCompletionPage extends ConsumerStatefulWidget {
  const FocusCompletionPage({super.key});

  @override
  ConsumerState<FocusCompletionPage> createState() =>
      _FocusCompletionPageState();
}

class _FocusCompletionPageState extends ConsumerState<FocusCompletionPage> {
  @override
  void initState() {
    super.initState();
    _markDoneToday();
  }

  Future<void> _markDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool(
      'focus_done_${now.year}_${now.month}_${now.day}',
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusSessionProvider);
    final stats = session.stats;
    final isDesktop = Responsive.isDesktop(context);

    final allHandled = stats.completed + stats.postponed +
        stats.blocked + stats.delegated + stats.skipped;
    final stillPending = session.tasks.length - allHandled;

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.sp40 : AppSpacing.sp20,
            vertical: AppSpacing.sp40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Ícone de conclusão ───────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 36),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 500.ms,
                        curve: Curves.elasticOut),

                const SizedBox(height: AppSpacing.sp24),

                Text(
                  'Foco inicial concluído!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms),

                const SizedBox(height: AppSpacing.sp8),

                Text(
                  'Você revisou ${session.tasks.length} tarefa${session.tasks.length != 1 ? "s" : ""} crítica${session.tasks.length != 1 ? "s" : ""}.\nMuito bem!',
                  style: AppTypography.body(context.cTextMuted)
                      .copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 350.ms),

                const SizedBox(height: AppSpacing.sp32),

                // ── Grid de resumo ───────────────────────────
                _StatsGrid(stats: stats)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),

                if (stillPending > 0) ...[
                  const SizedBox(height: AppSpacing.sp20),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sp12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: AppSpacing.sp8),
                        Expanded(
                          child: Text(
                            '$stillPending tarefa${stillPending != 1 ? "s" : ""} ainda pendente${stillPending != 1 ? "s" : ""}. '
                            'Elas continuam no seu backlog.',
                            style: AppTypography.body(AppColors.warning)
                                .copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 280.ms, duration: 300.ms),
                ],

                const SizedBox(height: AppSpacing.sp40),

                // ── Botões ───────────────────────────────────
                _ActionButtons(
                  onDashboard: () => context.go(AppRoutes.dashboard),
                  onPending: stats.skipped > 0
                      ? () {
                          ref
                              .read(taskOverdueFilterProvider.notifier)
                              .state = true;
                          context.go(AppRoutes.tasks);
                        }
                      : null,
                  onRestart: () {
                    ref.read(focusSessionProvider.notifier).restart();
                    context.go(AppRoutes.focus);
                  },
                ).animate().fadeIn(delay: 320.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stats Grid ───────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final FocusSessionStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Concluídas', stats.completed, AppColors.success,
          Icons.check_circle_outline_rounded),
      _StatItem('Adiadas', stats.postponed, AppColors.warning,
          Icons.calendar_month_rounded),
      _StatItem('Bloqueadas', stats.blocked, AppColors.error,
          Icons.block_rounded),
      _StatItem('Delegadas', stats.delegated, AppColors.primary,
          Icons.person_add_alt_1_rounded),
      _StatItem('Puladas', stats.skipped, AppColors.textMuted,
          Icons.skip_next_rounded),
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppSpacing.sp8,
      mainAxisSpacing: AppSpacing.sp8,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatItem(this.label, this.count, this.color, this.icon);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: item.count > 0
              ? item.color.withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.border),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 18, color: item.color),
          const SizedBox(height: 4),
          Text(
            item.count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.cTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            item.label,
            style:
                AppTypography.body(context.cTextMuted).copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onDashboard;
  final VoidCallback? onPending;
  final VoidCallback onRestart;

  const _ActionButtons({
    required this.onDashboard,
    required this.onPending,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: onDashboard,
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: const Text(
              'Ir para o Dashboard',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
        if (onPending != null) ...[
          const SizedBox(height: AppSpacing.sp8),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onPending,
              icon: const Icon(Icons.list_alt_rounded, size: 16),
              label: const Text('Ver tarefas pendentes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(
                    color: AppColors.warning, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sp8),
        TextButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reiniciar foco'),
          style: TextButton.styleFrom(
            foregroundColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
