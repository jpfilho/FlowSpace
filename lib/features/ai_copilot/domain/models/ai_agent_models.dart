enum AiAgentType {
  taskRiskAnalysis,
  weeklyExecutiveReport;

  String get nameString => switch (this) {
        AiAgentType.taskRiskAnalysis => 'Análise de Risco de Tarefas',
        AiAgentType.weeklyExecutiveReport => 'Relatório Executivo Semanal',
      };
}

class AiAgentConfig {
  final AiAgentType agentType;
  final String systemInstruction;
  final String businessRules;
  final String toneOfVoice;
  final String avoidRules;
  final String examples;

  const AiAgentConfig({
    required this.agentType,
    required this.systemInstruction,
    required this.businessRules,
    required this.toneOfVoice,
    required this.avoidRules,
    required this.examples,
  });

  Map<String, dynamic> toJson() {
    return {
      'agentType': agentType.name,
      'systemInstruction': systemInstruction,
      'businessRules': businessRules,
      'toneOfVoice': toneOfVoice,
      'avoidRules': avoidRules,
      'examples': examples,
    };
  }

  factory AiAgentConfig.fromJson(Map<String, dynamic> json) {
    return AiAgentConfig(
      agentType: AiAgentType.values.firstWhere(
        (e) => e.name == json['agentType'],
        orElse: () => AiAgentType.taskRiskAnalysis,
      ),
      systemInstruction: json['systemInstruction'] as String? ?? '',
      businessRules: json['businessRules'] as String? ?? '',
      toneOfVoice: json['toneOfVoice'] as String? ?? '',
      avoidRules: json['avoidRules'] as String? ?? '',
      examples: json['examples'] as String? ?? '',
    );
  }

  AiAgentConfig copyWith({
    AiAgentType? agentType,
    String? systemInstruction,
    String? businessRules,
    String? toneOfVoice,
    String? avoidRules,
    String? examples,
  }) {
    return AiAgentConfig(
      agentType: agentType ?? this.agentType,
      systemInstruction: systemInstruction ?? this.systemInstruction,
      businessRules: businessRules ?? this.businessRules,
      toneOfVoice: toneOfVoice ?? this.toneOfVoice,
      avoidRules: avoidRules ?? this.avoidRules,
      examples: examples ?? this.examples,
    );
  }
}
