import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/data_providers.dart';
import '../../data/models/task_5w2h_model.dart';
import '../../data/repositories/task_5w2h_repository.dart';

// ── Repository Provider ──────────────────────────────────────

/// Provê uma instância do [Task5w2hRepository] conectada ao Supabase.
final task5w2hRepositoryProvider = Provider<Task5w2hRepository>((ref) {
  return Task5w2hRepository(ref.read(supabaseProvider));
});

// ── Notifier ─────────────────────────────────────────────────

/// Notifier que gerencia a LISTA de 5W2H de uma tarefa.
///
/// Suporta: carregar, adicionar novo, salvar item existente, deletar item.
class Task5w2hListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Task5w2hModel>, String> {
  @override
  Future<List<Task5w2hModel>> build(String arg) async {
    final repo = ref.read(task5w2hRepositoryProvider);
    return repo.fetchByTaskId(arg);
  }

  /// Adiciona um novo registro 5W2H em branco.
  Future<void> add({String title = '5W2H'}) async {
    final repo = ref.read(task5w2hRepositoryProvider);
    final current = state.valueOrNull ?? [];
    final newItem = await repo.create(arg, title: title);
    state = AsyncValue.data([...current, newItem]);
  }

  /// Salva (atualiza) um registro 5W2H existente.
  Future<void> save(Task5w2hModel model) async {
    final repo = ref.read(task5w2hRepositoryProvider);
    final saved = await repo.upsert(model);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((e) => e.id == saved.id ? saved : e).toList(),
    );
  }

  /// Remove um registro 5W2H pelo id.
  Future<void> delete(String id) async {
    final repo = ref.read(task5w2hRepositoryProvider);
    await repo.deleteById(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
  }

  /// Atualiza apenas o título de um registro (inline edit).
  Future<void> rename(String id, String newTitle) async {
    final current = state.valueOrNull ?? [];
    final item = current.firstWhere((e) => e.id == id);
    await save(item.copyWith(title: newTitle));
  }
}

/// Provider da lista de 5W2H de uma tarefa.
final task5w2hListProvider = AsyncNotifierProvider.autoDispose
    .family<Task5w2hListNotifier, List<Task5w2hModel>, String>(
  Task5w2hListNotifier.new,
);

// ── Provider legado para compatibilidade (único item, agora o primeiro) ──────

/// @deprecated — mantido para não quebrar código existente.
/// Use [task5w2hListProvider] em código novo.
final task5w2hProvider =
    FutureProvider.autoDispose.family<Task5w2hModel?, String>(
  (ref, taskId) async {
    final list = await ref.watch(task5w2hListProvider(taskId).future);
    return list.isEmpty ? null : list.first;
  },
);
