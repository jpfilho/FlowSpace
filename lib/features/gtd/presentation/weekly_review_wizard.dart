import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';

// ─────────────────────────────────────────────────────────────
// WEEKLY REVIEW WIZARD
// ─────────────────────────────────────────────────────────────

/// Opens the GTD Weekly Review wizard as a full-screen dialog.
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

// ─────────────────────────────────────────────────────────────
// Step data
// ─────────────────────────────────────────────────────────────

class _ReviewStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> checklist;

  const _ReviewStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.checklist,
  });
}

const _reviewSteps = [
  _ReviewStep(
    title: 'Esvaziar a Cabeça',
    description:
        'Capture tudo que está na sua mente. Qualquer ideia, preocupação ou tarefa pendente.',
    icon: Icons.psychology_outlined,
    color: AppColors.primary,
    checklist: [
      'Anote tudo que está incomodando ou preocupando',
      'Revise anotações físicas (cadernos, post-its)',
      'Verifique galeria de fotos por capturas úteis',
      'Esvazie a sua bolsa/mochila de papéis',
    ],
  ),
  _ReviewStep(
    title: 'Processar o Inbox',
    description:
        'Decida o que fazer com cada item capturado. Nada fica no inbox — cada coisa tem um destino.',
    icon: Icons.inbox_rounded,
    color: AppColors.accent,
    checklist: [
      'Processe todos os items do Inbox GTD',
      'Revise email e mensagens não lidas',
      'Processe inbox do sistema (abas, downloads)',
      'Cada item: fazer, delegar, adiar ou descartar',
    ],
  ),
  _ReviewStep(
    title: 'Revisar Projetos',
    description:
        'Cada projeto deve ter pelo menos uma próxima ação definida. Projetos sem ação ficam travados.',
    icon: Icons.folder_outlined,
    color: AppColors.success,
    checklist: [
      'Revise cada projeto ativo',
      'Garanta que cada projeto tem próxima ação',
      'Encerre projetos concluídos',
      'Adicione novos projetos identificados',
    ],
  ),
  _ReviewStep(
    title: 'Revisar Listas de Ação',
    description:
        'Suas listas refletem o que você pode realmente fazer. Remova o que ficou obsoleto.',
    icon: Icons.checklist_rounded,
    color: AppColors.warning,
    checklist: [
      'Revise tarefas "Em progresso" – ainda relevantes?',
      'Revise tarefas "Aguardando" – cobrar de alguém?',
      'Revise "Algum dia/Talvez" – promover algo?',
      'Marque como concluído o que já foi feito',
    ],
  ),
  _ReviewStep(
    title: 'Olhar o Calendário',
    description:
        'O calendário é a sua realidade imutável. Garanta que você está preparado para o futuro próximo.',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFF8B5CF6),
    checklist: [
      'Revise últimos 7 dias – algo esquecido?',
      'Revise próximos 14 dias – alguma preparação?',
      'Bloqueie tempo para projetos prioritários',
      'Confirme compromissos da próxima semana',
    ],
  ),
  _ReviewStep(
    title: 'Revisar Metas e Visão',
    description:
        'Alinhe seu dia a dia com suas metas de mais alto nível. O GTD funciona em 6 altitudes.',
    icon: Icons.rocket_launch_rounded,
    color: Color(0xFFEC4899),
    checklist: [
      'Revise suas metas de curto prazo (1–3 meses)',
      'Revise áreas de responsabilidade da sua vida',
      'Suas ações de hoje estão alinhadas com seus objetivos?',
      'Existe algo importante que você está adiando?',
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// Dialog
// ─────────────────────────────────────────────────────────────

class _WeeklyReviewDialog extends ConsumerStatefulWidget {
  const _WeeklyReviewDialog();

  @override
  ConsumerState<_WeeklyReviewDialog> createState() =>
      _WeeklyReviewDialogState();
}

class _WeeklyReviewDialogState
    extends ConsumerState<_WeeklyReviewDialog> {
  int _currentStep = 0;
  // checked[stepIndex][checkIndex]
  final Map<int, Set<int>> _checked = {};

  bool get _isLastStep => _currentStep == _reviewSteps.length - 1;

  double get _progress =>
      (_currentStep + 1) / _reviewSteps.length;

  int get _totalChecked =>
      _checked.values.fold(0, (sum, s) => sum + s.length);

  int get _totalItems =>
      _reviewSteps.fold(0, (s, step) => s + step.checklist.length);

  void _toggle(int step, int item) {
    setState(() {
      _checked.putIfAbsent(step, () => {});
      if (_checked[step]!.contains(item)) {
        _checked[step]!.remove(item);
      } else {
        _checked[step]!.add(item);
      }
    });
  }

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

  void _finish() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
                'Revisão semanal concluída! $_totalChecked/$_totalItems itens ✓'),
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
            onTap: () => _showExitDialog(),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),

          // Card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Top bar ────────────────────────────
                      _TopBar(
                        step: _currentStep,
                        total: _reviewSteps.length,
                        progress: _progress,
                        stepColor: step.color,
                        onClose: _showExitDialog,
                      ),

                      // ── Step content ───────────────────────
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 4, 28, 4),
                          child: _StepContent(
                            key: ValueKey(_currentStep),
                            step: step,
                            stepIndex: _currentStep,
                            checked: _checked[_currentStep] ?? {},
                            onToggle: (i) => _toggle(_currentStep, i),
                          ),
                        ),
                      ),

                      // ── Bottom nav ─────────────────────────
                      _BottomNav(
                        currentStep: _currentStep,
                        totalSteps: _reviewSteps.length,
                        stepColor: step.color,
                        totalChecked: _totalChecked,
                        totalItems: _totalItems,
                        onPrev: _prev,
                        onNext: _next,
                        isLast: _isLastStep,
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

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da revisão?'),
        content: const Text(
            'Seu progresso não será salvo. Deseja sair mesmo assim?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuar revisão'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text('Sair',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int step;
  final int total;
  final double progress;
  final Color stepColor;
  final VoidCallback onClose;

  const _TopBar({
    required this.step,
    required this.total,
    required this.progress,
    required this.stepColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(28, 24, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stepColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Etapa ${step + 1} de $total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stepColor,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textMuted,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor:
                  stepColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(stepColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Step Content
// ─────────────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  final _ReviewStep step;
  final int stepIndex;
  final Set<int> checked;
  final ValueChanged<int> onToggle;

  const _StepContent({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + title
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
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.05, duration: 300.ms),

        const SizedBox(height: 12),

        Text(
          step.description,
          style: context.bodySm.copyWith(
              color: context.cTextMuted, height: 1.5),
        )
            .animate()
            .fadeIn(delay: 60.ms, duration: 300.ms),

        const SizedBox(height: 20),

        // Checklist
        ...step.checklist.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final done = checked.contains(i);
          return GestureDetector(
            onTap: () => onToggle(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: done
                    ? step.color.withValues(alpha: 0.06)
                    : (context.isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: done
                      ? step.color.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color:
                          done ? step.color : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: done
                            ? step.color
                            : context.isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: done
                            ? context.cTextMuted
                            : context.cTextPrimary,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
                    delay: Duration(milliseconds: 80 + i * 50),
                    duration: 250.ms)
                .slideX(
                    begin: 0.03,
                    delay: Duration(milliseconds: 80 + i * 50),
                    duration: 250.ms),
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom Nav
// ─────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color stepColor;
  final int totalChecked;
  final int totalItems;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool isLast;

  const _BottomNav({
    required this.currentStep,
    required this.totalSteps,
    required this.stepColor,
    required this.totalChecked,
    required this.totalItems,
    required this.onPrev,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.isDark
                ? AppColors.borderDark
                : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Progress counter
          Text(
            '$totalChecked / $totalItems itens',
            style: TextStyle(
              fontSize: 12,
              color: context.cTextMuted,
            ),
          ),
          const Spacer(),
          if (currentStep > 0)
            OutlinedButton(
              onPressed: onPrev,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
              child: const Text('Voltar'),
            ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onNext,
            icon: Icon(
              isLast
                  ? Icons.celebration_rounded
                  : Icons.arrow_forward_rounded,
              size: 16,
            ),
            label: Text(isLast ? 'Concluir Revisão!' : 'Próximo'),
            style: FilledButton.styleFrom(
              backgroundColor: stepColor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
