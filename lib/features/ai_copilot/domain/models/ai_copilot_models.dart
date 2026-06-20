
class AiRecommendation {
  final String id;
  final String? taskId;
  final String workspaceId;
  final String? userId;
  final String recommendationType; // 'risk_alert' | 'priority_suggestion' | 'next_steps' | 'weekly_summary'
  final String recommendationText;
  final String justification;
  final String riskLevel; // 'low' | 'medium' | 'high' | 'critical'
  final String suggestedPriority; // 'low' | 'medium' | 'high' | 'urgent' | 'critical'
  final double confidenceScore;
  final DateTime createdAt;
  final String status; // 'pending' | 'accepted' | 'rejected' | 'adjusted'
  final String? humanAction;
  final String? humanFeedback; // 'useful' | 'incorrect_risk' | 'missing_context'
  final String? feedbackComment;

  const AiRecommendation({
    required this.id,
    this.taskId,
    required this.workspaceId,
    this.userId,
    required this.recommendationType,
    required this.recommendationText,
    required this.justification,
    required this.riskLevel,
    required this.suggestedPriority,
    required this.confidenceScore,
    required this.createdAt,
    required this.status,
    this.humanAction,
    this.humanFeedback,
    this.feedbackComment,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      id: json['id'] as String,
      taskId: json['task_id'] as String?,
      workspaceId: json['workspace_id'] as String,
      userId: json['user_id'] as String?,
      recommendationType: json['recommendation_type'] as String? ?? '',
      recommendationText: json['recommendation_text'] as String? ?? '',
      justification: json['justification'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'low',
      suggestedPriority: json['suggested_priority'] as String? ?? 'medium',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 1.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      humanAction: json['human_action'] as String?,
      humanFeedback: json['human_feedback'] as String?,
      feedbackComment: json['feedback_comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'workspace_id': workspaceId,
      'user_id': userId,
      'recommendation_type': recommendationType,
      'recommendation_text': recommendationText,
      'justification': justification,
      'risk_level': riskLevel,
      'suggested_priority': suggestedPriority,
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'human_action': humanAction,
      'human_feedback': humanFeedback,
      'feedback_comment': feedbackComment,
    };
  }

  AiRecommendation copyWith({
    String? status,
    String? humanAction,
    String? humanFeedback,
    String? feedbackComment,
  }) {
    return AiRecommendation(
      id: id,
      taskId: taskId,
      workspaceId: workspaceId,
      userId: userId,
      recommendationType: recommendationType,
      recommendationText: recommendationText,
      justification: justification,
      riskLevel: riskLevel,
      suggestedPriority: suggestedPriority,
      confidenceScore: confidenceScore,
      createdAt: createdAt,
      status: status ?? this.status,
      humanAction: humanAction ?? this.humanAction,
      humanFeedback: humanFeedback ?? this.humanFeedback,
      feedbackComment: feedbackComment ?? this.feedbackComment,
    );
  }
}

class AiTaskAnalysis {
  final String id;
  final String taskId;
  final String workspaceId;
  final String riskLevel; // 'low' | 'medium' | 'high' | 'critical'
  final String riskReason;
  final String? missingInformation;
  final String? suggestedNextStep;
  final DateTime analyzedAt;

  const AiTaskAnalysis({
    required this.id,
    required this.taskId,
    required this.workspaceId,
    required this.riskLevel,
    required this.riskReason,
    this.missingInformation,
    this.suggestedNextStep,
    required this.analyzedAt,
  });

  factory AiTaskAnalysis.fromJson(Map<String, dynamic> json) {
    return AiTaskAnalysis(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      workspaceId: json['workspace_id'] as String,
      riskLevel: json['risk_level'] as String? ?? 'low',
      riskReason: json['risk_reason'] as String? ?? '',
      missingInformation: json['missing_information'] as String?,
      suggestedNextStep: json['suggested_next_step'] as String?,
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'workspace_id': workspaceId,
      'risk_level': riskLevel,
      'risk_reason': riskReason,
      'missing_information': missingInformation,
      'suggested_next_step': suggestedNextStep,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}

class AiAuditLog {
  final String id;
  final String? taskId;
  final String workspaceId;
  final String? userId;
  final String actionType; // 'view' | 'accept_recommendation' | 'reject_recommendation' | 'adjust_recommendation'
  final String? previousValue;
  final String? newValue;
  final String? aiRecommendationId;
  final DateTime createdAt;

  const AiAuditLog({
    required this.id,
    this.taskId,
    required this.workspaceId,
    this.userId,
    required this.actionType,
    this.previousValue,
    this.newValue,
    this.aiRecommendationId,
    required this.createdAt,
  });

  factory AiAuditLog.fromJson(Map<String, dynamic> json) {
    return AiAuditLog(
      id: json['id'] as String,
      taskId: json['task_id'] as String?,
      workspaceId: json['workspace_id'] as String,
      userId: json['user_id'] as String?,
      actionType: json['action_type'] as String? ?? '',
      previousValue: json['previous_value'] as String?,
      newValue: json['new_value'] as String?,
      aiRecommendationId: json['ai_recommendation_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'workspace_id': workspaceId,
      'user_id': userId,
      'action_type': actionType,
      'previous_value': previousValue,
      'new_value': newValue,
      'ai_recommendation_id': aiRecommendationId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AiWeeklyReport {
  final String weeklySummary;
  final String criticalBottlenecks;
  final String emergingRisks;
  final List<String> recommendations;
  final List<String> humanDecisionPoints;

  const AiWeeklyReport({
    required this.weeklySummary,
    required this.criticalBottlenecks,
    required this.emergingRisks,
    required this.recommendations,
    required this.humanDecisionPoints,
  });

  factory AiWeeklyReport.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    return AiWeeklyReport(
      weeklySummary: json['weekly_summary'] as String? ?? '',
      criticalBottlenecks: json['critical_bottlenecks'] as String? ?? '',
      emergingRisks: json['emerging_risks'] as String? ?? '',
      recommendations: parseList(json['recommendations']),
      humanDecisionPoints: parseList(json['human_decision_points']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekly_summary': weeklySummary,
      'critical_bottlenecks': criticalBottlenecks,
      'emerging_risks': emergingRisks,
      'recommendations': recommendations,
      'human_decision_points': humanDecisionPoints,
    };
  }
}
