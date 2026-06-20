import '../../../auth/domain/data_providers.dart';

class AiPromptBuilder {
  static const String systemInstruction = '''
Você é o Copiloto de IA de Gestão Operacional do FlowSpace. Sua função é apoiar gestores e equipes na identificação de riscos, prazos críticos, gargalos e próximos passos.
Você deve agir de forma responsável e transparente:
1. Você sugere, mas NÃO decide. Toda recomendação ou classificação deve ser justificada.
2. Não julgue ou aponte culpados individuais. Foque em riscos de processos e melhoria de qualidade de dados.
3. Se houver dados insuficientes, informe de forma clara quais informações estão faltando.
4. Classifique riscos de forma conservadora.
5. Indique claramente quando a decisão humana é obrigatória (ex: alterar prazos, mudar responsáveis, reclassificar como crítica).
''';

  /// Builds a prompt for analyzing a specific task
  static String buildTaskAnalysisPrompt({
    required TaskData task,
    required List<Map<String, dynamic>> comments,
    required DateTime now,
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
Analise a seguinte tarefa do FlowSpace de acordo com os princípios operacionais:

DADOS DA TAREFA:
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

Você deve retornar obrigatoriamente um objeto JSON com o seguinte formato exato (sem Markdown em volta, apenas o JSON bruto):

{
  "risk_level": "low" | "medium" | "high" | "critical",
  "risk_reason": "Justificativa clara e baseada em fatos para a classificação de risco.",
  "suggested_priority": "low" | "medium" | "high" | "urgent" | "critical",
  "missing_information": "O que está faltando para a tarefa progredir (ex: data prevista, responsável confirmado)? Se nada estiver faltando, deixe null.",
  "suggested_next_step": "Ação imediata recomendada para o gestor ou equipe.",
  "confidence_score": 0.0 a 1.0 (nível de confiança na análise),
  "smart_alerts": [
    "Lista de alertas inteligentes em formato de texto, ex: 'Tarefa próxima do vencimento sem atualização recente.', 'Prazo crítico sem responsável definido.'"
  ]
}

REGRAS ADICIONAIS:
- A classificação de risco deve ser:
  * 'critical' se o prazo SLA ou due_date expirou e o status não é done/cancelled, ou se for SLA Crítico e faltar menos de 24 horas.
  * 'high' se faltam menos de 3 dias, a tarefa está com status 'todo' ou 'in_progress', e não possui comentários recentes.
  * 'medium' se há atrasos de andamento ou dependências.
  * 'low' se está em dia e com informações completas.
- O campo "risk_reason" deve explicar de forma curta e objetiva por que esse nível de risco foi selecionado.
- Os "smart_alerts" devem listar alertas relevantes para a tarefa de forma direta.
''';
  }

  /// Builds a prompt for the weekly executive summary
  static String buildWeeklyReportPrompt({
    required List<TaskData> allTasks,
    required DateTime now,
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
Gere um Resumo Executivo Semanal de Operações para o FlowSpace com base nos dados consolidados a seguir:

ESTATÍSTICAS DA SEMANA (Data de referência da análise: ${now.toIso8601String()}):
- Total de tarefas em aberto: $totalOpen
- Total de tarefas concluídas: $totalCompleted
- Total de tarefas de SLA Crítico em aberto: $totalCriticalSla
- Total de tarefas vencidas: $overdueCount
- Total de tarefas que vencem nos próximos 7 dias: $next7DaysCount

LISTA DE TAREFAS ATIVAS DO WORKSPACE:
$tasksDetails

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

Linguagem: Simples, objetiva, corporativa de alto nível, focada em riscos do processo e aprendizado, não em ranqueamento individual de pessoas.
''';
  }
}
