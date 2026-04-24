import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/index.dart';
import '../../auth/domain/data_providers.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/weekly_review_providers.dart';
import '../../tasks/presentation/edit_task_sheet.dart';

// ─────────────────────────────────────────────────────────────
// WEEKLY REVIEW WIZARD
// ─────────────────────────────────────────────────────────────

Future<void> showWeeklyReview(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Weekly Review',
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (ctx, anim, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    pageBuilder: (ctx, _, __) => const _WeeklyReviewDialog(),
  );
}

class _ReviewStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ReviewStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _reviewSteps = [
  _ReviewStep(
    title: 'Coletar e Esvaziar',
    description: 'Capture tudo que está na mente para não esquecer nada.',
    icon: Icons.psychology_outlined,
    color: AppColors.primary,
  ),
  _ReviewStep(
    title: 'Processar Inbox',
    description: 'Transforme capturas em tarefas, projetos ou descarte.',
    icon: Icons.inbox_rounded,
    color: AppColors.accent,
  ),
  _ReviewStep(
    title: 'Revisar Tarefas',
    description: 'Atenção às tarefas atrasadas ou sem prazo.',
    icon: Icons.task_alt_rounded,
    color: AppColors.warning,
  ),
  _ReviewStep(
    title: 'Revisar Projetos',
    description: 'Garanta que projetos ativos tenham próximas ações.',
    icon: Icons.folder_outlined,
    color: AppColors.success,
  ),
  _ReviewStep(
    title: 'Aguardando Resposta',
    description: 'Cobre pendências com terceiros ou tarefas delegadas.',
    icon: Icons.hourglass_empty_rounded,
    color: Color(0xFF8B5CF6),
  ),
  _ReviewStep(
    title: 'Olhar Calendário',
    description: 'Revise os eventos passados e futuros importantes.',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFFF59E0B),
  ),
  _ReviewStep(
    title: 'Fechamento',
    description: 'Defina o seu foco para a semana e conclua a revisão.',
    icon: Icons.rocket_launch_rounded,
    color: Color(0xFFEC4899),
  ),
];

class _WeeklyReviewDialog extends ConsumerStatefulWidget {
  const _WeeklyReviewDialog();
  @override
  ConsumerState<_WeeklyReviewDialog> createState() => _WeeklyReviewDialogState();
}

class _WeeklyReviewDialogState extends ConsumerState<_WeeklyReviewDialog> {
  int _currentStep = 0;

  bool get _isLastStep => _currentStep == _reviewSteps.length - 1;
  double get _progress => (_currentStep + 1) / _reviewSteps.length;

  void _next() {
    if (_isLastStep) {
      _finish();
    } else {
      setState(() => _currentStep++);
    }
  }

  void _prev() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _finish() async {
    await ref.read(weeklyReviewSessionProvider.notifier).completeSession();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Revisão semanal concluída com sucesso!'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _reviewSteps[_currentStep];
    final isDark = context.isDark;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: _showExitDialog,
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),

          // Card Flow Responsivo
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 850),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: step.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    'Etapa ${_currentStep + 1} de ${_reviewSteps.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: step.color,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _showExitDialog,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 4,
                                backgroundColor: step.color.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation(step.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Body dinâmico das 7 etapas
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: step.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                    child: Icon(step.icon, color: step.color, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      step.title,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, duration: 300.ms),
                              const SizedBox(height: 12),
                              Text(
                                step.description,
                                style: context.bodySm.copyWith(color: context.cTextMuted, height: 1.5),
                              ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
                              const SizedBox(height: 20),
                              
                              // Injeção da View específica
                              Expanded(
                                child: _buildStepView(_currentStep),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer Navigation
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentStep > 0)
                              OutlinedButton(
                                onPressed: _prev,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: const Text('Voltar'),
                              )
                            else
                              const SizedBox.shrink(),
                            FilledButton.icon(
                              onPressed: _next,
                              icon: Icon(
                                _isLastStep ? Icons.celebration_rounded : Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: Text(_isLastStep ? 'Concluir Revisão!' : 'Próximo'),
                              style: FilledButton.styleFrom(
                                backgroundColor: step.color,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepView(int stepIndex) {
    return switch (stepIndex) {
      0 => const _StepCapture(),
      1 => const _StepInbox(),
      2 => const _StepTasks(),
      3 => const _StepProjects(),
      4 => const _StepWaiting(),
      5 => const _StepCalendar(),
      6 => const _StepClosing(),
      _ => const SizedBox.shrink(),
    };
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da revisão?'),
        content: const Text('Seu progresso da sessão atual não será computado. Sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuar revisão'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // dialog
              Navigator.of(context).pop(); // modal
            },
            child: Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ETAPAS OPERACIONAIS
// ─────────────────────────────────────────────────────────────

class _StepCapture extends ConsumerStatefulWidget {
  const _StepCapture();
  @override
  ConsumerState<_StepCapture> createState() => _StepCaptureState();
}

class _StepCaptureState extends ConsumerState<_StepCapture> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isLoading = true);
    final err = await ref.read(gtdInboxProvider.notifier).capture(text);
    setState(() => _isLoading = false);
    if (err == null) {
      _ctrl.clear();
      if (mounted) FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'Digite o que está na sua cabeça...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flash_on_rounded),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isLoading ? null : _add,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Capturar'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('No Inbox agora:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer(builder: (ctx, ref, child) {
            final inboxState = ref.watch(gtdInboxProvider);
            return inboxState.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Inbox limpo! Ótimo.'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.circle, size: 12),
                    title: Text(items[i].content),
                    dense: true,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Erro: $e'),
            );
          }),
        ),
      ],
    );
  }
}

class _StepInbox extends ConsumerWidget {
  const _StepInbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(gtdInboxProvider);
    
    return inboxState.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Seu Inbox está completamente zerado.', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final item = items[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.task_alt, size: 16),
                        label: const Text('Para Tarefa'),
                        onPressed: () => _openCreateTask(context, item.content, ref, item.id),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Descartar', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          await ref.read(gtdInboxProvider.notifier).markProcessed(item.id);
                          ref.read(weeklyReviewSessionProvider.notifier).incrementInboxProcessed();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Erro: $e'),
    );
  }

  Future<void> _openCreateTask(BuildContext context, String content, WidgetRef ref, String itemId) async {
    final nav = Navigator.of(context);
    
    // Mark as processed
    await ref.read(gtdInboxProvider.notifier).markProcessed(itemId);
    ref.read(weeklyReviewSessionProvider.notifier).incrementInboxProcessed();
    
    // Create task behind the scenes
    final result = await ref.read(tasksProvider.notifier).createTask(title: content);
    if (result.error != null) return;
    
    // Find task and open modal
    final tasks = ref.read(tasksProvider).valueOrNull ?? [];
    final newTask = tasks.where((t) => t.id == result.id).firstOrNull;
    if (newTask != null) {
      showModalBottomSheet(
        context: nav.context,
        isScrollControlled: true,
        builder: (ctx) => EditTaskSheet(task: newTask),
      );
    }
  }
}

class _StepTasks extends ConsumerWidget {
  const _StepTasks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);
    
    return tasksState.when(
      data: (allTasks) {
        final now = DateTime.now();
        final criticalTasks = allTasks.where((t) {
          if (t.isDone) return false;
          if (t.dueDate == null) return true; // sem data
          final bool overdue = t.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
          return overdue;
        }).toList();

        if (criticalTasks.isEmpty) {
          return const Center(child: Text('Nenhuma tarefa crítica pendente.'));
        }

        return ListView.builder(
          itemCount: criticalTasks.length,
          itemBuilder: (_, i) {
            final t = criticalTasks[i];
            final overdue = t.dueDate?.isBefore(DateTime(now.year, now.month, now.day)) ?? false;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: overdue ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(t.title, style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  t.dueDate == null 
                     ? 'Sem data de entrega' 
                     : 'Atrasada: ${DateFormat('dd/MM').format(t.dueDate!)}',
                  style: TextStyle(color: overdue ? Colors.red[400] : Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                      onPressed: () {
                         showModalBottomSheet(
                           context: context,
                           isScrollControlled: true,
                           builder: (ctx) => EditTaskSheet(task: t),
                         );
                         ref.read(weeklyReviewSessionProvider.notifier).incrementTasksReviewed();
                      },
                      tooltip: 'Editar/Adiar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      onPressed: () async {
                         await ref.read(tasksProvider.notifier).updateStatus(t.id, 'done');
                         ref.read(weeklyReviewSessionProvider.notifier).incrementTasksReviewed();
                      },
                      tooltip: 'Concluir agora',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erro: $e'),
    );
  }
}

class _StepProjects extends ConsumerWidget {
  const _StepProjects();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final tasksAsync = ref.watch(tasksProvider);

    if (projectsAsync.isLoading || tasksAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final projects = projectsAsync.valueOrNull ?? [];
    final tasks = tasksAsync.valueOrNull ?? [];

    final activeProjects = projects.where((p) => p.status == 'active').toList();
    
    // Projetos sem proxima acao (sem task pendente)
    final projectsWithoutAction = activeProjects.where((p) {
      final projectTasks = tasks.where((t) => t.projectId == p.id && !t.isDone);
      return projectTasks.isEmpty;
    }).toList();

    if (projectsWithoutAction.isEmpty) {
      return const Center(child: Text('Todos os projetos ativos têm próximas ações!'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Atenção! Pela regra do GTD, projetos sem tarefas ativas ficam travados. Adicione tarefas para destravá-los.',
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: projectsWithoutAction.length,
            itemBuilder: (_, i) {
              final p = projectsWithoutAction[i];
              return Card(
                elevation: 0,
                color: context.isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.description ?? 'Sem descrição'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.add_task, size: 16),
                    label: const Text('Criar Ação'),
                    onPressed: () async {
                      final result = await ref.read(tasksProvider.notifier).createTask(title: 'Nova Tarefa', projectId: p.id);
                      if (result.error == null) {
                        final tasks = ref.read(tasksProvider).valueOrNull ?? [];
                        final newTask = tasks.where((t) => t.id == result.id).firstOrNull;
                        if (newTask != null && context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) => EditTaskSheet(task: newTask),
                          );
                          ref.read(weeklyReviewSessionProvider.notifier).incrementProjectsReviewed();
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StepWaiting extends ConsumerWidget {
  const _StepWaiting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final userAsync = ref.watch(currentUserProvider);

    return tasksAsync.when(
      data: (tasks) {
        final waitingTasks = tasks.where((t) {
          if (t.isDone) return false;
          // Está em review ou designado para outra pessoa (alguem da equipe)
          return t.status == 'review' || (t.assigneeId != null && t.assigneeId != userAsync?.id);
        }).toList();

        if (waitingTasks.isEmpty) {
          return const Center(child: Text('Nenhuma pendência aguardando terceiros.'));
        }

        return ListView.builder(
          itemCount: waitingTasks.length,
          itemBuilder: (_, i) {
            final t = waitingTasks[i];
            return ListTile(
              leading: const Icon(Icons.supervisor_account_rounded),
              title: Text(t.title),
              subtitle: Text(t.status == 'review' ? 'Em revisão' : 'Delegada a um colega'),
              trailing: IconButton(
                icon: const Icon(Icons.call_made_rounded, size: 20),
                tooltip: 'Abrir Tarefa',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => EditTaskSheet(task: t),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erro: $e'),
    );
  }
}

class _StepCalendar extends StatelessWidget {
  const _StepCalendar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Revisão de Agenda (Mock)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Integração futura com Microsoft 365 / Outlook para carregar\neventos automáticos e extrair pendências.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Agenda Revisada Manualmente'),
            onPressed: () {}, // Noop
          ),
        ],
      ),
    );
  }
}

class _StepClosing extends ConsumerWidget {
  const _StepClosing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(weeklyReviewSessionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.done_all_rounded, size: 60, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'Ótimo progresso!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'Inbox Processado', value: session.inboxProcessedCount.toString(), color: AppColors.accent),
              _Stat(label: 'Tarefas Atuadas', value: session.tasksReviewedCount.toString(), color: AppColors.warning),
              _Stat(label: 'Projetos Revisados', value: session.projectsReviewedCount.toString(), color: AppColors.success),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          maxLines: 3,
          onChanged: (val) => ref.read(weeklyReviewSessionProvider.notifier).setWeeklyFocus(val),
          decoration: const InputDecoration(
            labelText: 'Qual o SEU FOCO absoluto para essa nova semana?',
            hintText: 'Escreva de 1 a 3 prioridades essenciais...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
