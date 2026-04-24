import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/data_providers.dart';
import '../../auth/domain/auth_provider.dart';

// Model do estado atual
class WeeklyReviewSessionState {
  final DateTime startedAt;
  final int inboxProcessedCount;
  final int tasksReviewedCount;
  final int projectsReviewedCount;
  final bool isCompleted;
  final String weeklyFocus;

  WeeklyReviewSessionState({
    required this.startedAt,
    this.inboxProcessedCount = 0,
    this.tasksReviewedCount = 0,
    this.projectsReviewedCount = 0,
    this.isCompleted = false,
    this.weeklyFocus = '',
  });

  WeeklyReviewSessionState copyWith({
    int? inboxProcessedCount,
    int? tasksReviewedCount,
    int? projectsReviewedCount,
    bool? isCompleted,
    String? weeklyFocus,
  }) {
    return WeeklyReviewSessionState(
      startedAt: startedAt,
      inboxProcessedCount: inboxProcessedCount ?? this.inboxProcessedCount,
      tasksReviewedCount: tasksReviewedCount ?? this.tasksReviewedCount,
      projectsReviewedCount: projectsReviewedCount ?? this.projectsReviewedCount,
      isCompleted: isCompleted ?? this.isCompleted,
      weeklyFocus: weeklyFocus ?? this.weeklyFocus,
    );
  }
}

// Notifier
class WeeklyReviewSessionNotifier
    extends AutoDisposeNotifier<WeeklyReviewSessionState> {
  @override
  WeeklyReviewSessionState build() {
    return WeeklyReviewSessionState(startedAt: DateTime.now());
  }

  void incrementInboxProcessed() {
    state = state.copyWith(
        inboxProcessedCount: state.inboxProcessedCount + 1);
  }

  void incrementTasksReviewed() {
    state = state.copyWith(
        tasksReviewedCount: state.tasksReviewedCount + 1);
  }

  void incrementProjectsReviewed() {
    state = state.copyWith(
        projectsReviewedCount: state.projectsReviewedCount + 1);
  }

  void setWeeklyFocus(String focus) {
    state = state.copyWith(weeklyFocus: focus);
  }

  Future<void> completeSession() async {
    final client = ref.read(supabaseProvider);
    final user = ref.read(currentUserProvider);
    
    if (user != null) {
      await client.from('weekly_reviews').insert({
        'user_id': user.id,
        'started_at': state.startedAt.toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
        'inbox_processed_count': state.inboxProcessedCount,
        'tasks_reviewed_count': state.tasksReviewedCount,
        'projects_reviewed_count': state.projectsReviewedCount,
        'weekly_focus': state.weeklyFocus,
      });
    }
    state = state.copyWith(isCompleted: true);
  }
  
  void restart() {
    state = WeeklyReviewSessionState(startedAt: DateTime.now());
  }
}

final weeklyReviewSessionProvider = AutoDisposeNotifierProvider<
    WeeklyReviewSessionNotifier,
    WeeklyReviewSessionState>(WeeklyReviewSessionNotifier.new);
