import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/data_providers.dart';
import 'focus_priority_score.dart';

// ─────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────

/// Tarefa enriquecida para o contexto de foco.
class FocusTask {
  final TaskData task;
  final bool isOverdue;
  final bool isDueToday;
  final int score;

  const FocusTask({
    required this.task,
    required this.isOverdue,
    required this.isDueToday,
    required this.score,
  });
}

/// Estatísticas acumuladas da sessão de foco.
class FocusSessionStats {
  final int completed;
  final int postponed;
  final int blocked;
  final int delegated;
  final int skipped;

  const FocusSessionStats({
    this.completed = 0,
    this.postponed = 0,
    this.blocked = 0,
    this.delegated = 0,
    this.skipped = 0,
  });

  int get total => completed + postponed + blocked + delegated + skipped;

  FocusSessionStats copyWith({
    int? completed,
    int? postponed,
    int? blocked,
    int? delegated,
    int? skipped,
  }) =>
      FocusSessionStats(
        completed: completed ?? this.completed,
        postponed: postponed ?? this.postponed,
        blocked: blocked ?? this.blocked,
        delegated: delegated ?? this.delegated,
        skipped: skipped ?? this.skipped,
      );
}

/// Estado completo da sessão de foco.
class FocusSessionState {
  final List<FocusTask> tasks;
  final int currentIndex;
  final FocusSessionStats stats;
  final Set<String> skippedIds; // IDs das tarefas puladas

  const FocusSessionState({
    required this.tasks,
    required this.currentIndex,
    required this.stats,
    required this.skippedIds,
  });

  bool get isComplete => tasks.isEmpty || currentIndex >= tasks.length;
  FocusTask? get currentTask =>
      isComplete ? null : tasks[currentIndex];

  FocusSessionState copyWith({
    int? currentIndex,
    FocusSessionStats? stats,
    Set<String>? skippedIds,
  }) =>
      FocusSessionState(
        tasks: tasks,
        currentIndex: currentIndex ?? this.currentIndex,
        stats: stats ?? this.stats,
        skippedIds: skippedIds ?? this.skippedIds,
      );
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

/// Lista de tarefas críticas (atrasadas + vencendo hoje), ordenadas por score.
final focusTasksProvider = Provider<List<FocusTask>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final focusTasks = <FocusTask>[];
  for (final t in tasks) {
    final effStatus = t.effectiveStatus;
    if (effStatus == 'done' || effStatus == 'cancelled') continue;
    if (t.dueDate == null) continue;

    final isOverdue = t.dueDate!.isBefore(today);
    final isDueToday = t.dueDate! == today;
    if (!isOverdue && !isDueToday) continue;

    focusTasks.add(FocusTask(
      task: t,
      isOverdue: isOverdue,
      isDueToday: isDueToday,
      score: calcFocusScore(t, isOverdue: isOverdue, isDueToday: isDueToday),
    ));
  }

  // Ordena: primeiro atrasadas, depois de hoje, por score decrescente
  focusTasks.sort((a, b) {
    if (a.isOverdue && !b.isOverdue) return -1;
    if (!a.isOverdue && b.isOverdue) return 1;
    return b.score.compareTo(a.score);
  });

  return focusTasks;
});

// ── Session Notifier ──────────────────────────────────────────

class FocusSessionNotifier extends AutoDisposeNotifier<FocusSessionState> {
  @override
  FocusSessionState build() {
    // Congela a lista no início da sessão — não reage a mudanças posteriores
    final tasks = ref.read(focusTasksProvider);
    return FocusSessionState(
      tasks: tasks,
      currentIndex: 0,
      stats: const FocusSessionStats(),
      skippedIds: {},
    );
  }

  void _advance() {
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void recordCompleted() {
    state = state.copyWith(stats: state.stats.copyWith(
      completed: state.stats.completed + 1,
    ));
    _advance();
  }

  void recordPostponed() {
    state = state.copyWith(stats: state.stats.copyWith(
      postponed: state.stats.postponed + 1,
    ));
    _advance();
  }

  void recordBlocked() {
    state = state.copyWith(stats: state.stats.copyWith(
      blocked: state.stats.blocked + 1,
    ));
    _advance();
  }

  void recordDelegated() {
    state = state.copyWith(stats: state.stats.copyWith(
      delegated: state.stats.delegated + 1,
    ));
    _advance();
  }

  void recordSkipped(String taskId) {
    state = state.copyWith(
      stats: state.stats.copyWith(skipped: state.stats.skipped + 1),
      skippedIds: {...state.skippedIds, taskId},
    );
    _advance();
  }

  /// Reinicia a sessão com as tarefas atuais (para "Reiniciar foco").
  void restart() {
    final tasks = ref.read(focusTasksProvider);
    state = FocusSessionState(
      tasks: tasks,
      currentIndex: 0,
      stats: const FocusSessionStats(),
      skippedIds: {},
    );
  }
}

/// Provider da sessão de foco. autoDispose garante reset ao sair das telas.
final focusSessionProvider = NotifierProvider.autoDispose<FocusSessionNotifier, FocusSessionState>(
  FocusSessionNotifier.new,
);
