import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/auth/domain/auth_provider.dart';
import '../../../features/auth/domain/data_providers.dart';
import '../../../features/tasks/presentation/tasks_page.dart'
    show taskStatusFilterProvider, taskOverdueFilterProvider;
import '../../../shared/widgets/common/skeleton.dart';
import 'widgets/stat_card.dart';
import 'widgets/today_tasks_widget.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/recent_activity_widget.dart';
import 'widgets/dashboard_charts.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runStartupTasks();
      });
    }
  }

  Future<void> _runStartupTasks() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // 1. Invoca RPC para notificar sobre tarefas com prazo próximo
    try {
      await ref.read(supabaseProvider).rpc(
        'create_due_date_notifications_for_user',
        params: {'p_user_id': user.id},
      );
    } catch (_) {
      // Falha silenciosa: se o RPC não existir ou der erro, não quebra a UI
    }

    // 2. Onboarding modal se for a primeira vez
    final done = user.userMetadata?['onboarding_done'] == true;
    if (!done && mounted) {
      _showOnboardingModal(user);
    }
  }

  void _showOnboardingModal(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.waving_hand_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('Boas-vindas!', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Este é o seu FlowSpace.', style: context.bodyMd.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Aqui você organiza tarefas, projetos, acompanha suas métricas e documenta sua rotina de forma rápida e inteligente.',
                style: context.bodyMd),
            const SizedBox(height: 16),
            Text('💡 Dica: Pressione "Cmd+K" para abrir a Busca e Navegação Rápida em qualquer lugar.',
                style: context.bodySm.copyWith(color: context.cTextMuted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(supabaseProvider).auth.updateUser(
                  UserAttributes(data: {'onboarding_done': true}),
                );
              } catch (_) {}
            },
            child: const Text('Começar o Flow'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600)
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final name = (user?.userMetadata?['name'] as String?)?.split(' ').first
        ?? 'Usuário';
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: context.cBackground,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isDesktop ? AppSpacing.sp32 : AppSpacing.sp20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.pageMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _DashboardHeader(name: name)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05, end: 0, duration: 400.ms),

              const SizedBox(height: AppSpacing.sp24),

              // Quick Actions
              QuickActionsWidget()
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 350.ms),

              const SizedBox(height: AppSpacing.sp24),

              // Stats Row — real data
              _StatsRow(isDesktop: isDesktop || isTablet)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 350.ms),

              const SizedBox(height: AppSpacing.sp24),

              // Charts
              const DashboardChartsWidget(),

              const SizedBox(height: AppSpacing.sp24),

              // Main content
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: TodayTasksWidget()),
                    const SizedBox(width: AppSpacing.sp20),
                    Expanded(flex: 2, child: RecentActivityWidget()),
                  ],
                )
              else
                Column(
                  children: [
                    TodayTasksWidget(),
                    const SizedBox(height: AppSpacing.sp20),
                    RecentActivityWidget(),
                  ],
                ),

              const SizedBox(height: AppSpacing.sp40),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String name;
  const _DashboardHeader({required this.name});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    final dateStr =
        '${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateStr,
          style: AppTypography.label(context.cTextMuted).copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sp6),
        Text(
          '${_greeting()}, $name 👋',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sp4),
        Text(
          'Aqui está um resumo do seu trabalho hoje.',
          style: AppTypography.body(context.cTextMuted),
        ),
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  final bool isDesktop;
  const _StatsRow({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      data: (stats) {
        /// Reseta filtros anteriores, aplica o filtro do card e navega.
        void goToTasks({String status = 'all', bool overdue = false}) {
          ref.read(taskStatusFilterProvider.notifier).state = status;
          ref.read(taskOverdueFilterProvider.notifier).state = overdue;
          context.go('/tasks');
        }

        final statList = [
          _StatData(
            label: 'Total de tarefas',
            value: ref.watch(tasksProvider).valueOrNull?.length.toString() ?? '0',
            icon: Icons.check_box_outlined,
            color: AppColors.primary,
            trend: 'No workspace',
            trendUp: null,
            onTap: () => goToTasks(),
          ),
          _StatData(
            label: 'Concluídas',
            value: stats.completed.toString(),
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
            trend: stats.completed > 0 ? '${stats.completed} feitas' : 'Nenhuma ainda',
            trendUp: stats.completed > 0 ? true : null,
            onTap: () => goToTasks(status: 'done'),
          ),
          _StatData(
            label: 'Em progresso',
            value: stats.inProgress.toString(),
            icon: Icons.pending_actions_rounded,
            color: AppColors.warning,
            trend: stats.inProgress > 0 ? 'Em andamento' : 'Tudo parado',
            trendUp: null,
            onTap: () => goToTasks(status: 'in_progress'),
          ),
          _StatData(
            label: 'Atrasadas',
            value: stats.overdue.toString(),
            icon: Icons.alarm_rounded,
            color: AppColors.error,
            trend: stats.overdue == 0 ? 'Em dia ✓' : '${stats.overdue} vencida${stats.overdue > 1 ? "s" : ""}',
            trendUp: stats.overdue == 0 ? true : false,
            onTap: stats.overdue > 0 ? () => goToTasks(overdue: true) : null,
          ),
        ];

        if (isDesktop) {
          return Row(
            children: statList
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: e.key < statList.length - 1 ? AppSpacing.sp12 : 0,
                        ),
                        child: StatCard(
                          label: e.value.label,
                          value: e.value.value,
                          icon: e.value.icon,
                          color: e.value.color,
                          trend: e.value.trend,
                          trendUp: e.value.trendUp,
                          onTap: e.value.onTap,
                        ).animate().fadeIn(delay: (e.key * 50).ms, duration: 400.ms),
                      ),
                    ))
                .toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sp12,
            crossAxisSpacing: AppSpacing.sp12,
            childAspectRatio: 1.6,
          ),
          itemCount: statList.length,
          itemBuilder: (_, i) => StatCard(
            label: statList[i].label,
            value: statList[i].value,
            icon: statList[i].icon,
            color: statList[i].color,
            trend: statList[i].trend,
            trendUp: statList[i].trendUp,
            onTap: statList[i].onTap,
          ),
        );
      },
      loading: () => SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isDesktop(context)
                ? AppSpacing.sp32
                : AppSpacing.sp20,
          ),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sp12),
          itemBuilder: (_, __) => const SizedBox(
            width: 180,
            child: SkeletonStatCard(),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendUp,
    this.onTap,
  });
}
