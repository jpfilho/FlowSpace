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
Você deve retornar obrigatoriamente apenas um objeto JSON válido, sem Markdown, sem comentários e sem texto adicional fora do JSON.

Use exatamente o seguinte formato:

{
  "workspace_health": "Saudável | Atenção | Crítico | Instável",
  "weekly_summary": "Resumo executivo simples e objetivo do status do workspace, destacando produtividade, eficiência e riscos principais.",
  "productivity_analysis": "Análise agregada da produtividade com base nas tarefas concluídas, abertas, vencidas e críticas.",
  "critical_bottlenecks": "Descrição dos principais gargalos operacionais identificados, agrupando problemas por categoria, projeto ou tipo de risco.",
  "emerging_risks": "Descrição dos riscos que podem afetar produtividade, prazos, SLA ou qualidade da entrega nos próximos dias.",
  "efficiency_opportunities": [
    "Oportunidade objetiva para melhorar eficiência 1",
    "Oportunidade objetiva para melhorar eficiência 2"
  ],
  "recommendations": [
    "Recomendação prática 1 para o gestor aumentar produtividade ou reduzir risco",
    "Recomendação prática 2 para o gestor aumentar produtividade ou reduzir risco"
  ],
  "human_decision_points": [
    "Decisão humana obrigatória 1",
    "Decisão humana obrigatória 2"
  ],
  "priority_actions_next_7_days": [
    "Ação prioritária 1 para os próximos 7 dias",
    "Ação prioritária 2 para os próximos 7 dias"
  ],
  "data_quality_notes": "Observações sobre limitações dos dados, campos ausentes ou informações necessárias para melhorar a análise."
}
''';
  }
}
