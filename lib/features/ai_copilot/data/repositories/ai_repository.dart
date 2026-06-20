import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/data_providers.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/models/ai_copilot_models.dart';
import '../../domain/services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref);
});

class AiRepository {
  final Ref _ref;

  AiRepository(this._ref);

  /// Fetches the latest risk analysis for a specific task
  Future<AiTaskAnalysis?> getTaskAnalysis(String taskId) async {
    final client = _ref.read(supabaseProvider);
    final data = await client
        .from('ai_task_analysis')
        .select('*')
        .eq('task_id', taskId)
        .maybeSingle();

    if (data == null) return null;
    return AiTaskAnalysis.fromJson(data);
  }

  /// Fetches recommendations for the current workspace
  Future<List<AiRecommendation>> getWorkspaceRecommendations(String workspaceId) async {
    final client = _ref.read(supabaseProvider);
    final data = await client
        .from('ai_recommendations')
        .select('*')
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => AiRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upserts task risk analysis
  Future<AiTaskAnalysis> upsertTaskAnalysis({
    required String taskId,
    required String workspaceId,
    required String riskLevel,
    required String riskReason,
    String? missingInformation,
    String? suggestedNextStep,
  }) async {
    final client = _ref.read(supabaseProvider);
    final data = await client.from('ai_task_analysis').upsert({
      'task_id': taskId,
      'workspace_id': workspaceId,
      'risk_level': riskLevel,
      'risk_reason': riskReason,
      'missing_information': missingInformation,
      'suggested_next_step': suggestedNextStep,
      'analyzed_at': DateTime.now().toIso8601String(),
    }).select().single();

    return AiTaskAnalysis.fromJson(data);
  }

  /// Creates a new AI recommendation in the database
  Future<AiRecommendation> createRecommendation({
    String? taskId,
    required String workspaceId,
    required String recommendationType,
    required String recommendationText,
    required String justification,
    required String riskLevel,
    required String suggestedPriority,
    required double confidenceScore,
  }) async {
    final client = _ref.read(supabaseProvider);
    final user = _ref.read(currentUserProvider);

    final data = await client.from('ai_recommendations').insert({
      'task_id': taskId,
      'workspace_id': workspaceId,
      'user_id': user?.id,
      'recommendation_type': recommendationType,
      'recommendation_text': recommendationText,
      'justification': justification,
      'risk_level': riskLevel,
      'suggested_priority': suggestedPriority,
      'confidence_score': confidenceScore,
      'status': 'pending',
    }).select().single();

    return AiRecommendation.fromJson(data);
  }

  /// Saves feedback for a recommendation and creates an audit log
  Future<void> saveFeedback({
    required String recommendationId,
    required String action, // 'accepted' | 'rejected' | 'adjusted'
    required String feedback, // 'useful' | 'incorrect_risk' | 'missing_context'
    String? comment,
    String? taskId,
    String? previousValue,
    String? newValue,
  }) async {
    final client = _ref.read(supabaseProvider);
    final user = _ref.read(currentUserProvider);
    final workspace = await _ref.read(currentWorkspaceProvider.future);

    if (workspace == null) throw Exception('Workspace não selecionado.');

    // 1. Update the recommendation row
    await client.from('ai_recommendations').update({
      'status': action,
      'human_action': 'Human action taken: $action',
      'human_feedback': feedback,
      'feedback_comment': comment,
    }).eq('id', recommendationId);

    // 2. Log in audit table
    await client.from('ai_audit_logs').insert({
      'task_id': taskId,
      'workspace_id': workspace.id,
      'user_id': user?.id,
      'action_type': 'submit_feedback_$action',
      'previous_value': previousValue,
      'new_value': newValue,
      'ai_recommendation_id': recommendationId,
    });
  }

  /// Inserts a simple audit log entry
  Future<void> logAuditEntry({
    String? taskId,
    required String actionType,
    String? previousValue,
    String? newValue,
    String? recommendationId,
  }) async {
    final client = _ref.read(supabaseProvider);
    final user = _ref.read(currentUserProvider);
    final workspace = await _ref.read(currentWorkspaceProvider.future);

    if (workspace == null) return;

    await client.from('ai_audit_logs').insert({
      'task_id': taskId,
      'workspace_id': workspace.id,
      'user_id': user?.id,
      'action_type': actionType,
      'previous_value': previousValue,
      'new_value': newValue,
      'ai_recommendation_id': recommendationId,
    });
  }
}

// ── Providers ────────────────────────────────────────────────

/// Provider for a single task's risk analysis
final taskAnalysisProvider = FutureProvider.autoDispose.family<AiTaskAnalysis?, String>((ref, taskId) async {
  final repo = ref.watch(aiRepositoryProvider);
  return await repo.getTaskAnalysis(taskId);
});

/// Provider for active recommendations in the current workspace
final workspaceRecommendationsProvider = FutureProvider.autoDispose<List<AiRecommendation>>((ref) async {
  final repo = ref.watch(aiRepositoryProvider);
  final workspace = await ref.watch(currentWorkspaceProvider.future);
  if (workspace == null) return [];
  return await repo.getWorkspaceRecommendations(workspace.id);
});

/// StateNotifier for performing task risk analysis live
class TaskAnalysisStateNotifier extends StateNotifier<AsyncValue<AiTaskAnalysis?>> {
  final Ref _ref;

  TaskAnalysisStateNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> runAnalysis(String taskId) async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(supabaseProvider);
      final repo = _ref.read(aiRepositoryProvider);
      final aiService = _ref.read(aiServiceProvider);
      final workspace = await _ref.read(currentWorkspaceProvider.future);

      if (workspace == null) throw Exception('Workspace não encontrado.');

      // 1. Fetch task details
      final taskMap = await client
          .from('tasks')
          .select('id, title, description, status, priority, due_date, start_date, deadline_at, is_sla_critical, created_at, completed_at, projects(name)')
          .eq('id', taskId)
          .single();

      final task = TaskData.fromJson(taskMap);

      // 2. Fetch task comments
      final commentsData = await client
          .from('task_comments')
          .select('id, content, created_at, author_id, profiles(name)')
          .eq('task_id', taskId);

      final List<Map<String, dynamic>> comments = (commentsData as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // 3. Call AI Service
      final aiResult = await aiService.analyzeTask(task: task, comments: comments);

      // 4. Save analysis to Database
      final analysis = await repo.upsertTaskAnalysis(
        taskId: taskId,
        workspaceId: workspace.id,
        riskLevel: aiResult['risk_level'] as String? ?? 'low',
        riskReason: aiResult['risk_reason'] as String? ?? 'Sem justificativa.',
        missingInformation: aiResult['missing_information'] as String?,
        suggestedNextStep: aiResult['suggested_next_step'] as String?,
      );

      // 5. Create specific AI recommendation entry (like a priority suggestion or alert)
      final suggestedPriority = aiResult['suggested_priority'] as String? ?? 'medium';
      
      // If AI recommends a priority that differs from current task priority, log it as priority_suggestion recommendation
      if (suggestedPriority != task.priority) {
        await repo.createRecommendation(
          taskId: taskId,
          workspaceId: workspace.id,
          recommendationType: 'priority_suggestion',
          recommendationText: 'Sugerimos prioridade "$suggestedPriority" para a tarefa.',
          justification: aiResult['risk_reason'] as String? ?? '',
          riskLevel: analysis.riskLevel,
          suggestedPriority: suggestedPriority,
          confidenceScore: (aiResult['confidence_score'] as num?)?.toDouble() ?? 0.85,
        );
      }

      // Also create recommendations for any smart alert
      final List<dynamic> alerts = aiResult['smart_alerts'] ?? [];
      for (final alert in alerts) {
        await repo.createRecommendation(
          taskId: taskId,
          workspaceId: workspace.id,
          recommendationType: 'risk_alert',
          recommendationText: alert.toString(),
          justification: aiResult['risk_reason'] as String? ?? '',
          riskLevel: analysis.riskLevel,
          suggestedPriority: task.priority,
          confidenceScore: (aiResult['confidence_score'] as num?)?.toDouble() ?? 0.90,
        );
      }

      // Log in audit log that AI analyzed the task
      await repo.logAuditEntry(
        taskId: taskId,
        actionType: 'ai_task_analyzed',
        newValue: 'risk: ${analysis.riskLevel}, suggested_priority: $suggestedPriority',
      );

      // Invalidate providers
      _ref.invalidate(taskAnalysisProvider(taskId));
      _ref.invalidate(workspaceRecommendationsProvider);

      state = AsyncValue.data(analysis);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final runTaskAnalysisProvider = StateNotifierProvider<TaskAnalysisStateNotifier, AsyncValue<AiTaskAnalysis?>>((ref) {
  return TaskAnalysisStateNotifier(ref);
});
