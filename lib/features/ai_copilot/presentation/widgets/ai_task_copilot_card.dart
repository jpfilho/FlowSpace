import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/index.dart';
import '../../../../shared/widgets/common/flow_button.dart';
import '../../../tasks/presentation/task_detail_page.dart' show taskDetailProvider;
import '../../../auth/domain/data_providers.dart';
import '../../domain/models/ai_copilot_models.dart';
import '../../data/repositories/ai_repository.dart';

class AiTaskCopilotCard extends ConsumerStatefulWidget {
  final AiRecommendation recommendation;
  final VoidCallback? onActionTaken;

  const AiTaskCopilotCard({
    super.key,
    required this.recommendation,
    this.onActionTaken,
  });

  @override
  ConsumerState<AiTaskCopilotCard> createState() => _AiTaskCopilotCardState();
}

class _AiTaskCopilotCardState extends ConsumerState<AiTaskCopilotCard> {
  bool _showFeedbackForm = false;
  bool _submitting = false;

  // Feedback fields
  bool? _isUseful;
  bool? _isRiskCorrect;
  bool? _isContextMissing;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Color get _riskColor => switch (widget.recommendation.riskLevel) {
        'critical' => AppColors.error,
        'high' => AppColors.priorityHigh,
        'medium' => AppColors.priorityMedium,
        _ => AppColors.priorityLow,
      };

  String get _riskLabel => switch (widget.recommendation.riskLevel) {
        'critical' => 'Risco Crítico',
        'high' => 'Risco Alto',
        'medium' => 'Risco Médio',
        _ => 'Risco Baixo',
      };

  Future<void> _handleAccept() async {
    setState(() => _submitting = true);
    try {
      final repo = ref.read(aiRepositoryProvider);
      
      // If it's a priority suggestion, update the task priority
      if (widget.recommendation.recommendationType == 'priority_suggestion' &&
          widget.recommendation.taskId != null) {
        final client = ref.read(supabaseProvider);
        
        // Fetch current priority before update
        final currentTaskData = await client
            .from('tasks')
            .select('priority')
            .eq('id', widget.recommendation.taskId!)
            .single();
        final currentPriority = currentTaskData['priority'] as String? ?? 'medium';

        // Update task priority in Database
        await ref.read(tasksProvider.notifier).updateTask(
              taskId: widget.recommendation.taskId!,
              priority: widget.recommendation.suggestedPriority,
            );
        
        // Log Audit
        await repo.saveFeedback(
          recommendationId: widget.recommendation.id,
          action: 'accepted',
          feedback: 'useful',
          comment: 'Accepted priority recommendation of ${widget.recommendation.suggestedPriority}',
          taskId: widget.recommendation.taskId,
          previousValue: 'priority: $currentPriority',
          newValue: 'priority: ${widget.recommendation.suggestedPriority}',
        );
      } else {
        await repo.saveFeedback(
          recommendationId: widget.recommendation.id,
          action: 'accepted',
          feedback: 'useful',
          taskId: widget.recommendation.taskId,
        );
      }

      ref.invalidate(tasksProvider);
      if (widget.recommendation.taskId != null) {
        ref.invalidate(taskDetailProvider(widget.recommendation.taskId!));
      }
      ref.invalidate(workspaceRecommendationsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recomendação aceita com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      widget.onActionTaken?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleReject() async {
    setState(() => _showFeedbackForm = true);
  }

  Future<void> _handleAdjust() async {
    final selectedPriority = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Ajustar Prioridade para:'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'urgent'),
            child: const Text('🔴 Urgente'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'high'),
            child: const Text('🟠 Alta'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'medium'),
            child: const Text('🔵 Média'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'low'),
            child: const Text('⚪ Baixa'),
          ),
        ],
      ),
    );

    if (selectedPriority != null && widget.recommendation.taskId != null) {
      setState(() => _submitting = true);
      try {
        final repo = ref.read(aiRepositoryProvider);
        final client = ref.read(supabaseProvider);
        
        final currentTaskData = await client
            .from('tasks')
            .select('priority')
            .eq('id', widget.recommendation.taskId!)
            .single();
        final currentPriority = currentTaskData['priority'] as String? ?? 'medium';

        await ref.read(tasksProvider.notifier).updateTask(
              taskId: widget.recommendation.taskId!,
              priority: selectedPriority,
            );

        await repo.saveFeedback(
          recommendationId: widget.recommendation.id,
          action: 'adjusted',
          feedback: 'adjusted_manually',
          comment: 'Adjusted priority recommendation to $selectedPriority (AI suggested ${widget.recommendation.suggestedPriority})',
          taskId: widget.recommendation.taskId,
          previousValue: 'priority: $currentPriority',
          newValue: 'priority: $selectedPriority',
        );

        ref.invalidate(tasksProvider);
        ref.invalidate(taskDetailProvider(widget.recommendation.taskId!));
        ref.invalidate(workspaceRecommendationsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prioridade ajustada e registrada!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        widget.onActionTaken?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_isUseful == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe se a sugestão foi útil.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(aiRepositoryProvider);
      
      String feedbackString = 'useful:${_isUseful == true}';
      if (_isRiskCorrect != null) feedbackString += ',risk_correct:${_isRiskCorrect == true}';
      if (_isContextMissing != null) feedbackString += ',missing_context:${_isContextMissing == true}';

      await repo.saveFeedback(
        recommendationId: widget.recommendation.id,
        action: 'rejected',
        feedback: feedbackString,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        taskId: widget.recommendation.taskId,
      );

      ref.invalidate(workspaceRecommendationsProvider);
      if (widget.recommendation.taskId != null) {
        ref.invalidate(taskDetailProvider(widget.recommendation.taskId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback registrado para melhorias futuros.'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _showFeedbackForm = false;
        });
      }
      widget.onActionTaken?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar feedback: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final rec = widget.recommendation;

    IconData typeIcon = Icons.info_outline;
    String typeLabel = 'Alerta';
    Color typeColor = AppColors.primary;

    if (rec.recommendationType == 'risk_alert') {
      typeIcon = Icons.warning_amber_rounded;
      typeLabel = 'Alerta de Risco';
      typeColor = AppColors.error;
    } else if (rec.recommendationType == 'priority_suggestion') {
      typeIcon = Icons.trending_up_rounded;
      typeLabel = 'Sugestão de Prioridade';
      typeColor = AppColors.warning;
    } else if (rec.recommendationType == 'next_steps') {
      typeIcon = Icons.assistant_direction_rounded;
      typeLabel = 'Próximos Passos';
      typeColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _riskLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _riskColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'IA Copiloto • Confiança ${(rec.confidenceScore * 100).toInt()}%',
                  style: AppTypography.caption(context.cTextMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp12),

            // Text
            Text(
              rec.recommendationText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.cTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sp8),

            // Justification
            Text(
              'Justificativa: ${rec.justification}',
              style: TextStyle(
                fontSize: 13,
                color: context.cTextMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sp16),

            // Actions or Feedback Form
            if (!_showFeedbackForm)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FlowButton(
                    label: 'Aceitar',
                    leadingIcon: Icons.check_circle_outline,
                    onPressed: _submitting ? null : _handleAccept,
                    size: FlowButtonSize.sm,
                  ),
                  if (rec.recommendationType == 'priority_suggestion')
                    FlowButton(
                      label: 'Ajustar',
                      leadingIcon: Icons.tune_rounded,
                      variant: FlowButtonVariant.outline,
                      onPressed: _submitting ? null : _handleAdjust,
                      size: FlowButtonSize.sm,
                    ),
                  FlowButton(
                    label: 'Rejeitar',
                    leadingIcon: Icons.cancel_outlined,
                    variant: FlowButtonVariant.ghost,
                    onPressed: _submitting ? null : _handleReject,
                    size: FlowButtonSize.sm,
                  ),
                  FlowButton(
                    label: 'Faltou contexto',
                    leadingIcon: Icons.help_outline_rounded,
                    variant: FlowButtonVariant.ghost,
                    onPressed: _submitting ? null : () {
                      setState(() {
                        _showFeedbackForm = true;
                        _isContextMissing = true;
                      });
                    },
                    size: FlowButtonSize.sm,
                  ),
                ],
              )
            else ...[
              const Divider(height: 24),
              Text(
                'Feedback sobre a IA',
                style: context.bodySm.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sp8),
              
              // Q1
              _buildFeedbackQuestion(
                label: 'A sugestão foi útil?',
                value: _isUseful,
                onChanged: (val) => setState(() => _isUseful = val),
              ),
              
              // Q2
              _buildFeedbackQuestion(
                label: 'A IA acertou a classificação de risco?',
                value: _isRiskCorrect,
                onChanged: (val) => setState(() => _isRiskCorrect = val),
              ),

              // Q3
              _buildFeedbackQuestion(
                label: 'Faltou algum contexto de negócio à IA?',
                value: _isContextMissing,
                onChanged: (val) => setState(() => _isContextMissing = val),
              ),

              const SizedBox(height: AppSpacing.sp8),
              TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  hintText: 'Adicione um comentário explicativo (opcional)...',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sp12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _showFeedbackForm = false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FlowButton(
                    label: 'Enviar Feedback',
                    onPressed: _submitting ? null : _submitFeedback,
                    size: FlowButtonSize.sm,
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackQuestion({
    required String label,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          InkWell(
            onTap: () => onChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: value == true ? AppColors.success.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sim',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: value == true ? FontWeight.bold : FontWeight.normal,
                  color: value == true ? AppColors.success : context.cTextMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => onChanged(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: value == false ? AppColors.error.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Não',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: value == false ? FontWeight.bold : FontWeight.normal,
                  color: value == false ? AppColors.error : context.cTextMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
