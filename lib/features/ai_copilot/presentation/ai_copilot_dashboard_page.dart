import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/index.dart';
import '../../../../shared/widgets/common/flow_button.dart';
import '../../../../shared/widgets/common/skeleton.dart';
import '../../auth/domain/data_providers.dart';
import '../domain/models/ai_copilot_models.dart';
import '../data/repositories/ai_repository.dart';
import 'widgets/ai_task_copilot_card.dart';

class AiCopilotDashboardPage extends ConsumerStatefulWidget {
  const AiCopilotDashboardPage({super.key});

  @override
  ConsumerState<AiCopilotDashboardPage> createState() => _AiCopilotDashboardPageState();
}

class _AiCopilotDashboardPageState extends ConsumerState<AiCopilotDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _generatingReport = false;
  AiWeeklyReport? _weeklyReport;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkApiKey();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final aiService = ref.read(aiServiceProvider);
    final key = await aiService.getApiKey();
    if (key == null || key.isEmpty) {
      setState(() {
        _apiError = 'A chave da API do Gemini não foi configurada. Acesse as Configurações para adicioná-la e usar o Copiloto IA.';
      });
    } else {
      setState(() {
        _apiError = null;
      });
    }
  }

  Future<void> _generateWeeklyReport(List<TaskData> tasks) async {
    setState(() {
      _generatingReport = true;
      _apiError = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final report = await aiService.generateWeeklyReport(allTasks: tasks);
      
      setState(() {
        _weeklyReport = report;
      });

      // Log in audit log
      final repo = ref.read(aiRepositoryProvider);
      await repo.logAuditEntry(
        actionType: 'ai_weekly_report_generated',
        newValue: 'weekly_summary generated with ${tasks.length} tasks',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resumo executivo semanal gerado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _apiError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _generatingReport = false;
      });
    }
  }

  void _copyReportToClipboard() {
    if (_weeklyReport == null) return;

    final text = '''
=== RESUMO EXECUTIVO SEMANAL — FLOWSPACE ===
${_weeklyReport!.weeklySummary}

Gargalos Críticos:
${_weeklyReport!.criticalBottlenecks}

Riscos Emergentes:
${_weeklyReport!.emergingRisks}

Recomendações da Semana:
${_weeklyReport!.recommendations.map((r) => '- $r').join('\n')}

Pontos de Decisão Humana Obrigatória:
${_weeklyReport!.humanDecisionPoints.map((d) => '- $d').join('\n')}
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resumo copiado para a área de transferência!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final recommendationsAsync = ref.watch(workspaceRecommendationsProvider);
    final isDesktop = Responsive.isDesktop(context);

    // If API key error check again on build
    _checkApiKey();

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'Copiloto IA',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.cTextMuted,
          tabs: const [
            Tab(text: 'Visão Geral & Recomendações'),
            Tab(text: 'Resumo Executivo Semanal'),
          ],
        ),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (allTasks) {
          // Heuristic task counts
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          final openTasks = allTasks.where((t) => t.status != 'done' && t.status != 'cancelled').toList();
          
          final criticalCount = openTasks.where((t) => t.isSlaCritical || t.isOverdue).length;
          
          final nearDueCount = openTasks.where((t) {
            if (t.dueDate == null) return false;
            final diff = t.dueDate!.difference(today).inDays;
            return diff >= 0 && diff <= 3;
          }).length;

          final noAssigneeCount = openTasks.where((t) => t.assigneeId == null || t.assigneeId!.isEmpty).length;

          final stalledCount = openTasks.where((t) {
            if (t.createdAt == null) return false;
            return now.difference(t.createdAt!).inDays >= 7;
          }).length;

          final incompleteCount = openTasks.where((t) {
            return (t.description == null || t.description!.trim().isEmpty) ||
                   t.dueDate == null;
          }).length;

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Visão Geral & Recomendações ──────────────────
              SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSpacing.sp32 : AppSpacing.sp20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_apiError != null)
                      _buildApiErrorBanner()
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: -0.1, end: 0),
                    
                    // Cards de Visão Geral
                    _buildOverviewGrid(
                      critical: criticalCount,
                      nearDue: nearDueCount,
                      noAssignee: noAssigneeCount,
                      stalled: stalledCount,
                      incomplete: incompleteCount,
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: AppSpacing.sp28),

                    // Recomendações Recentes Section
                    Text(
                      'Recomendações Pendentes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sp12),
                    
                    recommendationsAsync.when(
                      loading: () => const Column(
                        children: [
                          SkeletonBox(height: 120, width: double.infinity, radius: AppRadius.lg),
                          SizedBox(height: 12),
                          SkeletonBox(height: 120, width: double.infinity, radius: AppRadius.lg),
                        ],
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text('Erro ao carregar recomendações: $err', style: const TextStyle(color: AppColors.error)),
                      ),
                      data: (List<AiRecommendation> recs) {
                        final pendingRecs = recs.where((r) => r.status == 'pending').toList();

                        if (pendingRecs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: context.isDark ? AppColors.borderDark : AppColors.border),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success.withValues(alpha: 0.7)),
                                const SizedBox(height: 12),
                                Text(
                                  'Tudo sob controle!',
                                  style: context.bodyMd.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'O Copiloto IA não identificou novos alertas ou sugestões pendentes no momento.',
                                  style: AppTypography.caption(context.cTextMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: pendingRecs.map((r) => AiTaskCopilotCard(recommendation: r)).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Tab 2: Resumo Executivo Semanal ─────────────────────
              SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSpacing.sp32 : AppSpacing.sp20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_apiError != null) _buildApiErrorBanner(),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sp20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.accent.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumo Executivo Semanal',
                                  style: context.bodyMd.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Consolide todas as tarefas em aberto e concluídas em um relatório de alto nível estruturado pela IA para reuniões de alinhamento.',
                                  style: context.bodySm.copyWith(color: context.cTextMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          FlowButton(
                            label: _generatingReport ? 'Gerando...' : 'Gerar Relatório',
                            leadingIcon: Icons.bolt_rounded,
                            onPressed: _generatingReport || _apiError != null
                                ? null
                                : () => _generateWeeklyReport(allTasks),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),

                    if (_generatingReport)
                      const Column(
                        children: [
                          SizedBox(height: 40),
                          Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          SizedBox(height: 16),
                          Center(child: Text('Analisando tarefas operacionais e estruturando relatório...')),
                        ],
                      )
                    else if (_weeklyReport != null)
                      _buildWeeklyReportView()
                          .animate()
                          .fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApiErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp20),
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _apiError!,
              style: TextStyle(color: context.isDark ? Colors.red.shade200 : Colors.red.shade800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          FlowButton(
            label: 'Configurar',
            onPressed: () => context.go('/settings'),
            variant: FlowButtonVariant.outline,
            size: FlowButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid({
    required int critical,
    required int nearDue,
    required int noAssignee,
    required int stalled,
    required int incomplete,
    required bool isDesktop,
  }) {
    final widgets = [
      _OverviewCard(
        label: 'Tarefas em Risco Crítico',
        value: critical.toString(),
        color: AppColors.error,
        icon: Icons.dangerous_outlined,
        onTap: () {
          ref.read(taskFilterProvider.notifier).update((s) => s.copyWith(status: 'todo'));
          context.go('/tasks');
        },
      ),
      _OverviewCard(
        label: 'Prazos nos próx. 3 dias',
        value: nearDue.toString(),
        color: AppColors.warning,
        icon: Icons.hourglass_empty_rounded,
        onTap: () => context.go('/tasks'),
      ),
      _OverviewCard(
        label: 'Sem Responsável',
        value: noAssignee.toString(),
        color: AppColors.primary,
        icon: Icons.person_off_rounded,
        onTap: () => context.go('/tasks'),
      ),
      _OverviewCard(
        label: 'Paradas > 7 dias',
        value: stalled.toString(),
        color: const Color(0xFF8B5CF6),
        icon: Icons.history_toggle_off_rounded,
        onTap: () => context.go('/tasks'),
      ),
      _OverviewCard(
        label: 'Dados Incompletos',
        value: incomplete.toString(),
        color: context.cTextMuted,
        icon: Icons.error_outline_rounded,
        onTap: () => context.go('/tasks'),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: widgets
            .asMap()
            .entries
            .map((e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: e.key < widgets.length - 1 ? 10.0 : 0),
                    child: e.value,
                  ),
                ))
            .toList(),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: widgets,
      );
    }
  }

  Widget _buildWeeklyReportView() {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Relatório Gerado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            FlowButton(
              label: 'Copiar Relatório',
              leadingIcon: Icons.copy_rounded,
              variant: FlowButtonVariant.outline,
              onPressed: _copyReportToClipboard,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp16),
        
        // General Summary Card
        _buildSectionCard(
          title: 'Resumo Geral',
          icon: Icons.summarize_outlined,
          color: AppColors.primary,
          content: _weeklyReport!.weeklySummary,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sp16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSectionCard(
                title: 'Gargalos Identificados',
                icon: Icons.grid_off_rounded,
                color: AppColors.error,
                content: _weeklyReport!.criticalBottlenecks,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sp16),
            Expanded(
              child: _buildSectionCard(
                title: 'Riscos Emergentes',
                icon: Icons.trending_up_rounded,
                color: AppColors.warning,
                content: _weeklyReport!.emergingRisks,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp16),

        // List fields
        _buildListSectionCard(
          title: 'Recomendações Operacionais',
          icon: Icons.playlist_add_check_rounded,
          color: AppColors.success,
          items: _weeklyReport!.recommendations,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sp16),

        _buildListSectionCard(
          title: 'Decisões Humanas Obrigatórias',
          icon: Icons.gavel_rounded,
          color: AppColors.error,
          items: _weeklyReport!.humanDecisionPoints,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: context.bodyMd.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: context.cTextPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: context.bodyMd.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Nenhum item identificado.',
              style: TextStyle(fontSize: 13, color: context.cTextMuted, fontStyle: FontStyle.italic),
            )
          else
            Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(fontSize: 13, color: context.cTextPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: color),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.caption(context.cTextMuted).copyWith(height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
