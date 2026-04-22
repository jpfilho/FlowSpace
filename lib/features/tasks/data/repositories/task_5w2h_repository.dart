import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_5w2h_model.dart';

/// Repository responsável pelo acesso ao banco de dados da tabela task_5w2h.
///
/// Suporta múltiplos registros por tarefa (UNIQUE(task_id) foi removida).
class Task5w2hRepository {
  const Task5w2hRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'task_5w2h';

  // ── Leitura ──────────────────────────────────────────────────

  /// Busca todos os registros 5W2H de uma tarefa, ordenados por [order_index].
  Future<List<Task5w2hModel>> fetchByTaskId(String taskId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('task_id', taskId)
        .order('order_index');

    return (data as List<dynamic>)
        .map((e) => Task5w2hModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Busca TODOS os registros 5W2H do workspace em uma única query.
  ///
  /// Retorna um Map de taskId → List<Task5w2hModel>, ordenado por order_index.
  Future<Map<String, List<Task5w2hModel>>> fetchAllForWorkspace() async {
    final data = await _client
        .from(_table)
        .select()
        .order('order_index');

    final result = <String, List<Task5w2hModel>>{};
    for (final row in data as List<dynamic>) {
      final model = Task5w2hModel.fromMap(row as Map<String, dynamic>);
      result.putIfAbsent(model.taskId, () => []).add(model);
    }
    return result;
  }

  // ── Escrita ──────────────────────────────────────────────────

  /// Cria um novo registro 5W2H em branco para a tarefa.
  ///
  /// O [orderIndex] é calculado automaticamente como o maior + 1.
  Future<Task5w2hModel> create(String taskId, {String title = '5W2H'}) async {
    // Busca o maior order_index atual para esta tarefa
    final existing = await fetchByTaskId(taskId);
    final nextIndex = existing.isEmpty
        ? 0
        : existing.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

    final response = await _client
        .from(_table)
        .insert({
          'task_id': taskId,
          'title': title,
          'order_index': nextIndex,
        })
        .select()
        .single();

    return Task5w2hModel.fromMap(response);
  }

  /// Atualiza um registro 5W2H existente (por id).
  Future<Task5w2hModel> upsert(Task5w2hModel model) async {
    final response = await _client
        .from(_table)
        .upsert(model.toMap(), onConflict: 'id')
        .select()
        .single();

    return Task5w2hModel.fromMap(response);
  }

  // ── Deleção ──────────────────────────────────────────────────

  /// Remove um registro 5W2H específico pelo seu id.
  Future<void> deleteById(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Remove TODOS os registros 5W2H de uma tarefa.
  Future<void> deleteByTaskId(String taskId) async {
    await _client.from(_table).delete().eq('task_id', taskId);
  }
}
