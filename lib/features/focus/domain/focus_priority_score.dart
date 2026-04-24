import '../../auth/domain/data_providers.dart';

/// Calcula o score de prioridade de uma tarefa no contexto do Focus Start.
///
/// Quanto maior o score, mais urgente/importante, e a tarefa aparece primeiro.
int calcFocusScore(TaskData task, {required bool isOverdue, required bool isDueToday}) {
  int score = 0;

  // Urgência temporal
  if (isOverdue) score += 50;
  if (isDueToday) score += 30;

  // Prioridade da tarefa
  score += switch (task.priority) {
    'urgent' => 25,
    'high'   => 20,
    'medium' => 10,
    'low'    => 2,
    _        => 0,
  };

  // Penalidades
  if (task.status == 'review') score -= 15;   // em revisão/bloqueada
  if (task.status == 'blocked') score -= 20;  // bloqueada explicitamente

  return score;
}
