import '../../../auth/domain/data_providers.dart';
import '../models/ai_agent_models.dart';

class AiPromptBuilder {
  /// Builds a prompt for analyzing a specific task
  static String buildTaskAnalysisPrompt({
    required TaskData task,
    required List<Map<String, dynamic>> comments,
    required DateTime now,
    required AiAgentConfig config,
  }) {
    final Map<String, String> statusMap = {
      'todo': 'A Fazer',
      'in_progress': 'Em progresso',
      'review': 'Em revisão',
      'done': 'Concluído',
      'cancelled': 'Cancelado',
    };

    final Map<String, String> priorityMap = {
      'urgent': 'Urgente',
      'high': 'Alta',
      'medium': 'Média',
      'low': 'Baixa',
    };

    final formattedComments = comments.map((c) {
      final author = c['profiles']?['name'] ?? 'Membro';
      final text = c['content'] ?? '';
      final date = c['created_at'] ?? '';
      return '[$date] $author: "$text"';
    }).join('\n');

    final daysRemaining = task.dueDate?.difference(DateTime(now.year, now.month, now.day)).inDays;

    final openDays = task.createdAt != null
        ? now.difference(task.createdAt!).inDays
        : null;

    return '''
PAPEL DO ASSISTENTE:
${config.systemInstruction}

REGRAS DE NEGÓCIO:
${config.businessRules}

TOM DE VOZ:
${config.toneOfVoice}

O QUE EVITAR:
${config.avoidRules}

EXEMPLOS DE ANALISE:
${config.examples}

---
DADOS DINÂMICOS DA TAREFA A SER ANALISADA:
- Título: ${task.title}
- Descrição: ${task.description ?? 'Sem descrição'}
- Status Atual: ${statusMap[task.status] ?? task.status}
- Prioridade Definida pelo Gestor: ${priorityMap[task.priority] ?? task.priority}
- Projeto: ${task.projectName ?? 'Nenhum'}
- Data de Início: ${task.startDate != null ? task.startDate!.toIso8601String() : 'Não informada'}
- Data Limite/Vencimento (due_date): ${task.dueDate != null ? task.dueDate!.toIso8601String() : 'Não informada'}
- Prazo Crítico SLA (deadline_at): ${task.deadlineAt != null ? task.deadlineAt!.toIso8601String() : 'Não informado'}
- É SLA Crítico: ${task.isSlaCritical ? 'Sim' : 'Não'}
- Data de Criação: ${task.createdAt != null ? task.createdAt!.toIso8601String() : 'Não informada'}
- Dias em aberto: ${openDays ?? 'N/A'}
- Dias restantes para o vencimento: ${daysRemaining ?? 'N/A (sem vencimento)'}
- Hora de referência da análise: ${now.toIso8601String()}

HISTÓRICO DE COMENTÁRIOS E ATUALIZAÇÕES:
${formattedComments.isEmpty ? 'Nenhum comentário registrado.' : formattedComments}

---
CONTRATO DE SAÍDA JSON OBRIGATÓRIO (FIXO):
Você deve retornar obrigatoriamente um objeto JSON com o seguinte formato exato (sem Markdown em volta, apenas o JSON bruto):

{
  "risk_level": "low" | "medium" | "high" | "critical",
  "risk_reason": "Justificativa clara e baseada em fatos para a classificação de risco.",
  "suggested_priority": "low" | "medium" | "high" | "urgent" | "critical",
  "missing_information": "O que está faltando para a tarefa progredir (ex: data prevista, responsável confirmado)? Se nada estiver faltando, deixe null.",
  "suggested_next_step": "Ação imediata recomendada para o gestor ou equipe.",
  "confidence_score": 0.0 a 1.0 (nível de confiança na análise),
  "smart_alerts": [
    "Lista de alertas inteligentes em formato de texto"
  ]
}
''';
  }

  /// Builds a prompt for the weekly executive summary
  static String buildWeeklyReportPrompt({
    required List<TaskData> allTasks,
    required DateTime now,
    required AiAgentConfig config,
  }) {
    final totalOpen = allTasks.where((t) => t.status != 'done' && t.status != 'cancelled').length;
    final totalCompleted = allTasks.where((t) => t.status == 'done').length;
    final totalCriticalSla = allTasks.where((t) => t.isSlaCritical && t.status != 'done' && t.status != 'cancelled').length;
    
    final daysLimit = now.add(const Duration(days: 7));
    final next7DaysCount = allTasks.where((t) {
      if (t.status == 'done' || t.status == 'cancelled' || t.dueDate == null) return false;
      return t.dueDate!.isBefore(daysLimit);
    }).length;

    final overdueCount = allTasks.where((t) {
      if (t.status == 'done' || t.status == 'cancelled' || t.dueDate == null) return false;
      return t.dueDate!.isBefore(now);
    }).length;

    final tasksDetails = allTasks.map((t) {
      return '- Título: "${t.title}", Status: "${t.status}", Prioridade: "${t.priority}", Projeto: "${t.projectName ?? 'Nenhum'}", Vence em: "${t.dueDate?.toIso8601String() ?? 'N/A'}", SLA Crítico: ${t.isSlaCritical ? 'Sim' : 'Não'}';
    }).join('\n');

    return '''
PAPEL DO ASSISTENTE:
${config.systemInstruction}

REGRAS DE NEGÓCIO:
${config.businessRules}

TOM DE VOZ:
${config.toneOfVoice}

O QUE EVITAR:
${config.avoidRules}

EXEMPLOS DE RELATORIO:
${config.examples}

---
DADOS DINÂMICOS DO WORKSPACE A SEREM ANALISADOS:
- Data de referência da análise: ${now.toIso8601String()}
- Total de tarefas em aberto: $totalOpen
- Total de tarefas concluídas: $totalCompleted
- Total de tarefas de SLA Crítico em aberto: $totalCriticalSla
- Total de tarefas vencidas: $overdueCount
- Total de tarefas que vencem nos próximos 7 dias: $next7DaysCount

LISTA DE TAREFAS ATIVAS DO WORKSPACE:
$tasksDetails

---
CONTRATO DE SAÍDA JSON OBRIGATÓRIO (FIXO):
Você deve retornar obrigatoriamente um objeto JSON com o seguinte formato exato (sem Markdown em volta, apenas o JSON bruto):

{
  "weekly_summary": "Visão geral executiva simples do status do workspace esta semana.",
  "critical_bottlenecks": "Descrição dos principais gargalos operacionais identificados (ex: acúmulo de tarefas urgentes, atrasos recorrentes).",
  "emerging_risks": "Descrição de riscos operacionais que podem surgir nos próximos dias.",
  "recommendations": [
    "Recomendação 1 para o gestor",
    "Recomendação 2 para o gestor"
  ],
  "human_decision_points": [
    "Ponto de decisão humana obrigatório 1",
    "Ponto de decisão humana obrigatório 2"
  ]
}
''';
  }
}
