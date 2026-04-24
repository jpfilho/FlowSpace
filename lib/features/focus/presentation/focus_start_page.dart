import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/index.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/auth/domain/auth_provider.dart';
import '../domain/focus_providers.dart';

class FocusStartPage extends ConsumerStatefulWidget {
  const FocusStartPage({super.key});

  @override
  ConsumerState<FocusStartPage> createState() => _FocusStartPageState();
}

class _FocusStartPageState extends ConsumerState<FocusStartPage> {
  bool _skipping = false;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _skipToDashboard() async {
    setState(() => _skipping = true);
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool(
      'focus_done_${now.year}_${now.month}_${now.day}',
      true,
    );
    if (mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final name = (user?.userMetadata?['name'] as String?)?.split(' ').first ?? 'Usuário';
    final focusTasks = ref.watch(focusTasksProvider);
    final overdue = focusTasks.where((t) => t.isOverdue).length;
    final today = focusTasks.where((t) => t.isDueToday).length;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.sp40 : AppSpacing.sp20,
            vertical: AppSpacing.sp40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ícone de foco ────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: AppColors.warning, size: 30),
                )
                    .animate()
                    .scale(begin: const Offset(0.6, 0.6), duration: 400.ms,
                        curve: Curves.elasticOut),

                const SizedBox(height: AppSpacing.sp24),

                // ── Saudação ─────────────────────────────────
                Text(
                  '${_greeting()}, $name.',
                  style: Theme.of(context).textTheme.headlineLarge,
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 350.ms)
                    .slideY(begin: 0.04, end: 0),

                const SizedBox(height: AppSpacing.sp8),

                Text(
                  'Antes de abrir o dashboard, vamos organizar\no que precisa da sua atenção agora.',
                  style: AppTypography.body(context.cTextMuted)
                      .copyWith(height: 1.5),
                )
                    .animate()
                    .fadeIn(delay: 130.ms, duration: 350.ms),

                const SizedBox(height: AppSpacing.sp32),

                // ── Cards de resumo ───────────────────────────
                LayoutBuilder(builder: (ctx, constraints) {
                  final cols = constraints.maxWidth > 480 ? 3 : 1;
                  if (cols == 3) {
                    return Row(
                      children: [
                        Expanded(child: _SummaryCard(
                          icon: Icons.alarm_rounded,
                          color: AppColors.error,
                          label: 'Atrasadas',
                          count: overdue,
                        ).animate().fadeIn(delay: 180.ms, duration: 300.ms)),
                        const SizedBox(width: AppSpacing.sp12),
                        Expanded(child: _SummaryCard(
                          icon: Icons.today_rounded,
                          color: AppColors.warning,
                          label: 'Vencem hoje',
                          count: today,
                        ).animate().fadeIn(delay: 220.ms, duration: 300.ms)),
                        const SizedBox(width: AppSpacing.sp12),
                        Expanded(child: _SummaryCard(
                          icon: Icons.checklist_rounded,
                          color: AppColors.primary,
                          label: 'Total do dia',
                          count: focusTasks.length,
                        ).animate().fadeIn(delay: 260.ms, duration: 300.ms)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _SummaryCard(
                        icon: Icons.alarm_rounded,
                        color: AppColors.error,
                        label: 'Atrasadas',
                        count: overdue,
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      _SummaryCard(
                        icon: Icons.today_rounded,
                        color: AppColors.warning,
                        label: 'Vencem hoje',
                        count: today,
                      ),
                      const SizedBox(height: AppSpacing.sp8),
                      _SummaryCard(
                        icon: Icons.checklist_rounded,
                        color: AppColors.primary,
                        label: 'Total do dia',
                        count: focusTasks.length,
                      ),
                    ],
                  );
                }),

                const SizedBox(height: AppSpacing.sp40),

                // ── Botão principal ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.focusFlow),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'Começar agora',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: AppSpacing.sp12),

                // ── Link secundário ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _skipping ? null : _skipToDashboard,
                    style: TextButton.styleFrom(
                      foregroundColor: context.cTextMuted,
                    ),
                    child: _skipping
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Ir direto para o dashboard'),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 380.ms, duration: 300.ms),

                const SizedBox(height: AppSpacing.sp16),

                // ── Nota anti-procrastinação ─────────────────
                if (overdue > 0)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sp12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: AppSpacing.sp8),
                        Expanded(
                          child: Text(
                            'Você tem $overdue tarefa${overdue > 1 ? "s" : ""} atrasada${overdue > 1 ? "s" : ""}. '
                            'Revisá-las agora ajuda a manter o controle e reduzir o acúmulo.',
                            style: AppTypography.body(AppColors.error)
                                .copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 420.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary Card ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: count > 0
              ? color.withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.border),
          width: count > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.body(context.cTextMuted)
                      .copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
