import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/ms_graph_service.dart';
import 'auth_provider.dart';

// ── Supabase client helper ───────────────────────────────────
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─────────────────────────────────────────────────────────────
// WORKSPACE
// ─────────────────────────────────────────────────────────────

class WorkspaceData {
  final String id;
  final String name;
  final String slug;

  const WorkspaceData({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory WorkspaceData.fromJson(Map<String, dynamic> j) => WorkspaceData(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
      );
}

final currentWorkspaceProvider =
    FutureProvider<WorkspaceData?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseProvider);
  final data = await client
      .from('workspaces')
      .select('id, name, slug')
      .order('created_at')
      .limit(1)
      .maybeSingle();

  if (data == null) return null;
  return WorkspaceData.fromJson(data);
});

// ─────────────────────────────────────────────────────────────
// TASKS
// ─────────────────────────────────────────────────────────────

class TaskData {
  final String id;
  final String title;
  final String status;
  final String priority;
  final String? projectId;
  final String? projectName;
  final String? assigneeId;
  final DateTime? startDate;
  final DateTime? dueDate;
  final bool completed;
  final bool isSomeday;
  // Recurrence
  final String recurrenceType;     // none | daily | weekly | monthly | yearly
  final int recurrenceInterval;    // every N days/weeks/months
  final DateTime? recurrenceEndsAt; // null = forever

  const TaskData({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.projectId,
    this.projectName,
    this.assigneeId,
    this.startDate,
    this.dueDate,
    this.completed = false,
    this.isSomeday = false,
    this.recurrenceType = 'none',
    this.recurrenceInterval = 1,
    this.recurrenceEndsAt,
  });

  bool get isDone => status == 'done';
  bool get isRecurring => recurrenceType != 'none';

  factory TaskData.fromJson(Map<String, dynamic> j) {
    DateTime? parseDateSafe(String? s) {
      if (s == null) return null;
      final d = DateTime.parse(s);
      return DateTime(d.year, d.month, d.day);
    }
    
    return TaskData(
        id: j['id'] as String,
        title: j['title'] as String,
        status: j['status'] as String? ?? 'todo',
        priority: j['priority'] as String? ?? 'medium',
        projectId: j['project_id'] as String?,
        projectName: j['projects'] != null
            ? (j['projects'] as Map<String, dynamic>)['name'] as String?
            : null,
        assigneeId: j['assignee_id'] as String?,
        startDate: parseDateSafe(j['start_date'] as String?),
        dueDate: parseDateSafe(j['due_date'] as String?),
        completed: j['status'] == 'done',
        isSomeday: j['is_someday'] as bool? ?? false,
        recurrenceType: j['recurrence_type'] as String? ?? 'none',
        recurrenceInterval: (j['recurrence_interval'] as num?)?.toInt() ?? 1,
        recurrenceEndsAt: parseDateSafe(j['recurrence_ends_at'] as String?),
      );
  }

  TaskData copyWith({
    String? title,
    String? status,
    String? priority,
    String? projectId,
    String? projectName,
    String? assigneeId,
    DateTime? startDate,
    DateTime? dueDate,
    bool? completed,
    bool? isSomeday,
    bool clearStartDate = false,
    bool clearDueDate = false,
    bool clearProjectId = false,
    String? recurrenceType,
    int? recurrenceInterval,
    DateTime? recurrenceEndsAt,
    bool clearRecurrenceEndsAt = false,
  }) =>
      TaskData(
        id: id,
        title: title ?? this.title,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        projectId: clearProjectId ? null : (projectId ?? this.projectId),
        projectName: clearProjectId ? null : (projectName ?? this.projectName),
        assigneeId: assigneeId ?? this.assigneeId,
        startDate: clearStartDate ? null : (startDate ?? this.startDate),
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        completed: completed ?? this.completed,
        isSomeday: isSomeday ?? this.isSomeday,
        recurrenceType: recurrenceType ?? this.recurrenceType,
        recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
        recurrenceEndsAt: clearRecurrenceEndsAt
            ? null
            : (recurrenceEndsAt ?? this.recurrenceEndsAt),
      );

  /// Calculates the next due date based on recurrence settings.
  DateTime? get nextDueDate {
    if (dueDate == null || recurrenceType == 'none') return null;
    switch (recurrenceType) {
      case 'daily':
        return dueDate!.add(Duration(days: recurrenceInterval));
      case 'weekly':
        return dueDate!.add(Duration(days: 7 * recurrenceInterval));
      case 'monthly':
        return DateTime(
          dueDate!.year,
          dueDate!.month + recurrenceInterval,
          dueDate!.day,
        );
      case 'yearly':
        return DateTime(
          dueDate!.year + recurrenceInterval,
          dueDate!.month,
          dueDate!.day,
        );
      default:
        return null;
    }
  }
}


// Filter state
class TaskFilter {
  final String status; // all | todo | in_progress | review | done
  final String priority; // all | urgent | high | medium | low

  const TaskFilter({
    this.status = 'all',
    this.priority = 'all',
  });

  TaskFilter copyWith({String? status, String? priority}) => TaskFilter(
        status: status ?? this.status,
        priority: priority ?? this.priority,
      );
}

final taskFilterProvider = StateProvider<TaskFilter>((ref) => const TaskFilter());

// Tasks notifier — manages real-time list
class TasksNotifier extends AsyncNotifier<List<TaskData>> {
  @override
  Future<List<TaskData>> build() async {
    return _fetchTasks();
  }

  Future<List<TaskData>> _fetchTasks() async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    if (workspace == null) return [];

    final client = ref.read(supabaseProvider);
    final data = await client
        .from('tasks')
        .select('id, title, status, priority, project_id, assignee_id, start_date, due_date, is_someday, recurrence_type, recurrence_interval, recurrence_ends_at, projects(name)')
        .eq('workspace_id', workspace.id)
        .order('created_at', ascending: false)
        .limit(500);

    return (data as List)
        .map((e) => TaskData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchTasks());
  }

  Future<({String? id, String? error})> createTask({
    required String title,
    String status = 'todo',
    String priority = 'medium',
    String? projectId,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    if (workspace == null) return (id: null, error: 'Nenhum workspace encontrado');

    final user = ref.read(currentUserProvider);
    if (user == null) return (id: null, error: 'Não autenticado');

    final client = ref.read(supabaseProvider);
    try {
      final result = await client.from('tasks').insert({
        'workspace_id': workspace.id,
        'title': title.trim(),
        'status': status,
        'priority': priority,
        if (projectId != null) 'project_id': projectId,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
        'created_by': user.id,
        'assignee_id': user.id,
      }).select('id').single();
      await refresh();
      return (id: result['id'] as String?, error: null);
    } catch (e) {
      return (id: null, error: 'Erro ao criar tarefa: $e');
    }
  }

  Future<String?> updateTaskDates(String taskId, DateTime? start, DateTime? due) async {
    final client = ref.read(supabaseProvider);
    try {
      await client
          .from('tasks')
          .update({
            'start_date': start?.toIso8601String(),
            'due_date': due?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);

      // Optimistic upate
      state = state.whenData((list) => list.map((t) {
            if (t.id == taskId) {
              return t.copyWith(
                startDate: start,
                clearStartDate: start == null,
                dueDate: due,
                clearDueDate: due == null,
              );
            }
            return t;
          }).toList());
      return null;
    } catch (e) {
      return 'Erro ao atualizar datas: $e';
    }
  }

  Future<String?> updateStatus(String taskId, String newStatus) async {
    final client = ref.read(supabaseProvider);
    try {
      await client
          .from('tasks')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', taskId);

      // ── Recurrence: if marking done, spawn next occurrence ──
      if (newStatus == 'done') {
        final current = (state.valueOrNull ?? [])
            .where((t) => t.id == taskId)
            .firstOrNull;
        if (current != null && current.isRecurring) {
          final next = current.nextDueDate;
          final endsAt = current.recurrenceEndsAt;
          final withinWindow =
              endsAt == null || (next != null && next.isBefore(endsAt));
          if (next != null && withinWindow) {
            final workspace = await ref.read(currentWorkspaceProvider.future);
            final user = ref.read(currentUserProvider);
            if (workspace != null && user != null) {
              await client.from('tasks').insert({
                'workspace_id': workspace.id,
                'title': current.title,
                'status': 'todo',
                'priority': current.priority,
                if (current.projectId != null) 'project_id': current.projectId,
                if (current.assigneeId != null)
                  'assignee_id': current.assigneeId,
                'due_date': next.toIso8601String(),
                'created_by': user.id,
                'recurrence_type': current.recurrenceType,
                'recurrence_interval': current.recurrenceInterval,
                if (current.recurrenceEndsAt != null)
                  'recurrence_ends_at':
                      current.recurrenceEndsAt!.toIso8601String(),
              });
            }
          }
        }
      }

      // Optimistic update
      state = state.whenData((list) => list
          .map((t) => t.id == taskId ? t.copyWith(status: newStatus) : t)
          .toList());

      // Refresh to pick up any new occurrence created
      if (newStatus == 'done') await refresh();

      return null;
    } catch (e) {
      return 'Erro ao atualizar: $e';
    }
  }

  Future<String?> deleteTask(String taskId) async {
    final client = ref.read(supabaseProvider);
    try {
      await client.from('tasks').delete().eq('id', taskId);
      state = state.whenData(
          (list) => list.where((t) => t.id != taskId).toList());
      return null;
    } catch (e) {
      return 'Erro ao excluir: $e';
    }
  }

  Future<String?> updateTask({
    required String taskId,
    String? title,
    String? status,
    String? priority,
    String? projectId,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool clearProjectId = false,
    String? recurrenceType,
    int? recurrenceInterval,
    DateTime? recurrenceEndsAt,
    bool clearRecurrenceEndsAt = false,
  }) async {
    final client = ref.read(supabaseProvider);
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        if (title != null) 'title': title.trim(),
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (clearProjectId) 'project_id': null,
        if (!clearProjectId && projectId != null) 'project_id': projectId,
        if (clearDueDate) 'due_date': null,
        if (!clearDueDate && dueDate != null)
          'due_date': dueDate.toIso8601String(),
        if (recurrenceType != null) 'recurrence_type': recurrenceType,
        if (recurrenceInterval != null)
          'recurrence_interval': recurrenceInterval,
        if (clearRecurrenceEndsAt) 'recurrence_ends_at': null,
        if (!clearRecurrenceEndsAt && recurrenceEndsAt != null)
          'recurrence_ends_at': recurrenceEndsAt.toIso8601String(),
      };

      await client.from('tasks').update(updates).eq('id', taskId);

      // Optimistic update
      state = state.whenData((list) => list
          .map((t) => t.id == taskId
              ? t.copyWith(
                  title: title,
                  status: status,
                  priority: priority,
                  projectId: projectId,
                  dueDate: dueDate,
                  clearDueDate: clearDueDate,
                  clearProjectId: clearProjectId,
                  recurrenceType: recurrenceType,
                  recurrenceInterval: recurrenceInterval,
                  recurrenceEndsAt: recurrenceEndsAt,
                  clearRecurrenceEndsAt: clearRecurrenceEndsAt,
                )
              : t)
          .toList());

      return null;
    } catch (e) {
      return 'Erro ao atualizar: $e';
    }
  }
  Future<String?> setSomeday(String taskId, bool value) async {
    final client = ref.read(supabaseProvider);
    try {
      await client
          .from('tasks')
          .update({'is_someday': value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', taskId);
      // Optimistic update
      state = state.whenData((list) => list
          .map((t) => t.id == taskId ? t.copyWith(isSomeday: value) : t)
          .toList());
      return null;
    } catch (e) {
      return 'Erro ao atualizar: $e';
    }
  }
}

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<TaskData>>(TasksNotifier.new);

// Derived provider: tarefas marcadas como "Algum dia"
final somedayTasksProvider = Provider<AsyncValue<List<TaskData>>>((ref) {
  return ref.watch(tasksProvider).whenData(
    (tasks) => tasks.where((t) => t.isSomeday).toList(),
  );
});

// ─────────────────────────────────────────────────────────────
// PAGED TASKS — Scroll Infinito para TasksPage
// ─────────────────────────────────────────────────────────────

const int _kTasksPageSize = 30;

class PagedTasksState {
  final List<TaskData> items;
  final bool isLoadingMore;
  final bool hasMore;
  final String statusFilter;
  final String priorityFilter;

  const PagedTasksState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.statusFilter = 'all',
    this.priorityFilter = 'all',
  });

  PagedTasksState copyWith({
    List<TaskData>? items,
    bool? isLoadingMore,
    bool? hasMore,
    String? statusFilter,
    String? priorityFilter,
  }) =>
      PagedTasksState(
        items: items ?? this.items,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        statusFilter: statusFilter ?? this.statusFilter,
        priorityFilter: priorityFilter ?? this.priorityFilter,
      );
}

class PagedTasksNotifier
    extends AutoDisposeAsyncNotifier<PagedTasksState> {
  @override
  Future<PagedTasksState> build() async => _loadPage(0, const PagedTasksState());

  Future<PagedTasksState> _loadPage(int offset, PagedTasksState current) async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    if (workspace == null) return current;

    final client = ref.read(supabaseProvider);

    var query = client
        .from('tasks')
        .select('id, title, status, priority, project_id, assignee_id, due_date, projects(name)')
        .eq('workspace_id', workspace.id)
        .order('created_at', ascending: false)
        .range(offset, offset + _kTasksPageSize - 1);

    final data = await query as List<dynamic>;

    final newItems = data
        .map((e) => TaskData.fromJson(e as Map<String, dynamic>))
        .toList();

    return current.copyWith(
      items: offset == 0 ? newItems : [...current.items, ...newItems],
      hasMore: data.length == _kTasksPageSize,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _loadPage(current.items.length, current);
      state = AsyncData(next);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> applyFilter({String? status, String? priority}) async {
    final current = state.valueOrNull ?? const PagedTasksState();
    final newFilter = current.copyWith(
      statusFilter: status ?? current.statusFilter,
      priorityFilter: priority ?? current.priorityFilter,
    );
    state = const AsyncLoading();
    state = AsyncData(await _loadPage(0, newFilter));
  }

  Future<void> resetAndReload() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadPage(0, const PagedTasksState()));
  }
}

final pagedTasksProvider =
    AsyncNotifierProvider.autoDispose<PagedTasksNotifier, PagedTasksState>(
  PagedTasksNotifier.new,
);

// ─────────────────────────────────────────────────────────────
// GTD INBOX
// ─────────────────────────────────────────────────────────────

class InboxItem {
  final String id;
  final String content;
  final bool isProcessed;
  final DateTime createdAt;

  const InboxItem({
    required this.id,
    required this.content,
    required this.isProcessed,
    required this.createdAt,
  });

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
        id: j['id'] as String,
        content: j['content'] as String,
        isProcessed: j['is_processed'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class GtdInboxNotifier extends AsyncNotifier<List<InboxItem>> {
  @override
  Future<List<InboxItem>> build() async {
    return _fetch();
  }

  Future<List<InboxItem>> _fetch() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return [];

    final client = ref.read(supabaseProvider);
    final data = await client
        .from('gtd_inbox')
        .select('*')
        .eq('user_id', user.id)
        .eq('is_processed', false)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => InboxItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> capture(String content) async {
    if (content.trim().isEmpty) return 'Digite algo para capturar';

    final user = ref.read(currentUserProvider);
    if (user == null) return 'Não autenticado';

    final workspace = await ref.read(currentWorkspaceProvider.future);
    final client = ref.read(supabaseProvider);

    try {
      await client.from('gtd_inbox').insert({
        'user_id': user.id,
        if (workspace != null) 'workspace_id': workspace.id,
        'content': content.trim(),
      });
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetch());
      return null;
    } catch (e) {
      return 'Erro ao capturar: $e';
    }
  }

  Future<String?> markProcessed(String id) async {
    final client = ref.read(supabaseProvider);
    try {
      await client.from('gtd_inbox').update({
        'is_processed': true,
        'processed_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      state = state.whenData(
          (list) => list.where((i) => i.id != id).toList());
      return null;
    } catch (e) {
      return 'Erro: $e';
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final gtdInboxProvider =
    AsyncNotifierProvider<GtdInboxNotifier, List<InboxItem>>(GtdInboxNotifier.new);

// ─────────────────────────────────────────────────────────────
// PROJECTS
// ─────────────────────────────────────────────────────────────

class ProjectData {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String priority;
  final int progress;
  final int memberCount;
  final String? color;

  const ProjectData({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.priority,
    required this.progress,
    this.memberCount = 0,
    this.color,
  });

  String get statusDisplay => switch (status) {
        'active' => 'Ativo',
        'in_progress' => 'Em progresso',
        'review' => 'Em revisão',
        'completed' => 'Concluído',
        'archived' => 'Arquivado',
        _ => status,
      };

  factory ProjectData.fromJson(Map<String, dynamic> j) => ProjectData(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        status: j['status'] as String? ?? 'active',
        priority: j['priority'] as String? ?? 'medium',
        progress: (j['progress'] as num?)?.toInt() ?? 0,
        memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
        color: j['color'] as String?,
      );
}

class ProjectsNotifier extends AsyncNotifier<List<ProjectData>> {
  @override
  Future<List<ProjectData>> build() async {
    return _fetch();
  }

  Future<List<ProjectData>> _fetch() async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    if (workspace == null) return [];

    final client = ref.read(supabaseProvider);
    // Use RPC or manual count via project_members
    final data = await client
        .from('projects')
        .select('id, name, description, status, priority, progress, color')
        .eq('workspace_id', workspace.id)
        .order('created_at', ascending: false);

    // Get member counts separately
    final memberData = await client
        .from('project_members')
        .select('project_id')
        .inFilter('project_id',
            (data as List).map((e) => e['id'] as String).toList());

    final memberCounts = <String, int>{};
    for (final m in memberData as List) {
      final pid = m['project_id'] as String;
      memberCounts[pid] = (memberCounts[pid] ?? 0) + 1;
    }

    return data
        .map((e) => ProjectData.fromJson({
              ...e,
              'member_count': memberCounts[e['id']] ?? 0,
            }))
        .toList();
  }

  Future<String?> createProject({
    required String name,
    String? description,
    String status = 'active',
    String priority = 'medium',
  }) async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    if (workspace == null) return 'Nenhum workspace encontrado';
    final user = ref.read(currentUserProvider);
    if (user == null) return 'Não autenticado';

    final client = ref.read(supabaseProvider);
    try {
      await client.from('projects').insert({
        'workspace_id': workspace.id,
        'name': name.trim(),
        if (description != null && description.isNotEmpty)
          'description': description.trim(),
        'status': status,
        'priority': priority,
        'progress': 0,
        'created_by': user.id,
        'owner_id': user.id,
      });
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetch());
      return null;
    } catch (e) {
      return 'Erro ao criar projeto: $e';
    }
  }

  Future<String?> updateProgress(String projectId, int progress) async {
    final client = ref.read(supabaseProvider);
    try {
      await client
          .from('projects')
          .update({'progress': progress, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', projectId);
      state = state.whenData((list) => list
          .map((p) => p.id == projectId
              ? ProjectData(
                  id: p.id, name: p.name, description: p.description,
                  status: p.status, priority: p.priority,
                  progress: progress, memberCount: p.memberCount)
              : p)
          .toList());
      return null;
    } catch (e) {
      return 'Erro: $e';
    }
  }

  Future<String?> deleteProject(String projectId) async {
    final client = ref.read(supabaseProvider);
    try {
      // Optimistic: remove from local state immediately
      state = state.whenData(
          (list) => list.where((p) => p.id != projectId).toList());

      // Delete from DB
      await client.from('projects').delete().eq('id', projectId);

      // Verify deletion succeeded by checking if row still exists
      final check = await client
          .from('projects')
          .select('id')
          .eq('id', projectId)
          .maybeSingle();

      if (check != null) {
        // Row still exists — DB rejected the delete (RLS or constraint)
        // Revert optimistic update by re-fetching
        state = const AsyncLoading();
        state = await AsyncValue.guard(() => _fetch());
        return 'Sem permissão para excluir este projeto';
      }
      return null;
    } catch (e) {
      // Revert optimistic update on error
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetch());
      return 'Erro ao excluir: $e';
    }
  }

  Future<String?> updateProject({
    required String projectId,
    String? name,
    String? description,
    String? status,
    String? priority,
    int? progress,
    bool clearDescription = false,
  }) async {
    final client = ref.read(supabaseProvider);
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        if (name != null) 'name': name.trim(),
        if (clearDescription) 'description': null,
        if (!clearDescription && description != null)
          'description': description.trim(),
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (progress != null) 'progress': progress,
      };
      await client.from('projects').update(updates).eq('id', projectId);

      // Optimistic update
      state = state.whenData((list) => list
          .map((p) => p.id == projectId
              ? ProjectData(
                  id: p.id,
                  name: name ?? p.name,
                  description:
                      clearDescription ? null : (description ?? p.description),
                  status: status ?? p.status,
                  priority: priority ?? p.priority,
                  progress: progress ?? p.progress,
                  memberCount: p.memberCount,
                  color: p.color,
                )
              : p)
          .toList());
      return null;
    } catch (e) {
      return 'Erro ao atualizar projeto: $e';
    }
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<ProjectData>>(ProjectsNotifier.new);

// Provider nomeado para tarefas de um projeto específico (evita FutureProvider anônimo)
final projectTasksProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, projectId) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('tasks')
      .select('id, title, status, priority')
      .eq('project_id', projectId)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List).cast<Map<String, dynamic>>();
});

// ─────────────────────────────────────────────────────────────
// DASHBOARD STATS
// ─────────────────────────────────────────────────────────────

class DashboardStats {
  final int totalToday;
  final int completed;
  final int inProgress;
  final int overdue;

  const DashboardStats({
    this.totalToday = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.overdue = 0,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final tasks = await ref.watch(tasksProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final todayTasks = tasks.where((t) {
    if (t.dueDate == null) return false;
    final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
    return d.isAtSameMomentAs(today);
  }).toList();

  final completed = tasks.where((t) => t.status == 'done').length;
  final inProgress = tasks.where((t) => t.status == 'in_progress').length;
  final overdue = tasks.where((t) {
    if (t.dueDate == null || t.status == 'done') return false;
    return t.dueDate!.isBefore(today);
  }).length;

  return DashboardStats(
    totalToday: todayTasks.length,
    completed: completed,
    inProgress: inProgress,
    overdue: overdue,
  );
});

// ─────────────────────────────────────────────────────────────
// PAGES
// ─────────────────────────────────────────────────────────────

class PageData {
  final String id;
  final String title;
  final String? icon;
  final String? parentId;
  final bool isFavorite;
  final int position;
  final DateTime updatedAt;

  const PageData({
    required this.id,
    required this.title,
    this.icon,
    this.parentId,
    this.isFavorite = false,
    this.position = 0,
    required this.updatedAt,
  });

  factory PageData.fromJson(Map<String, dynamic> j) => PageData(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Sem título',
        icon: j['icon'] as String?,
        parentId: j['parent_id'] as String?,
        isFavorite: j['is_favorite'] as bool? ?? false,
        position: (j['position'] as num?)?.toInt() ?? 0,
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : DateTime.now(),
      );

  PageData copyWith({
    String? title,
    String? icon,
    bool? isFavorite,
    // To clear icon, pass clearIcon: true
    bool clearIcon = false,
  }) =>
      PageData(
        id: id,
        title: title ?? this.title,
        icon: clearIcon ? null : (icon ?? this.icon),
        parentId: parentId,
        isFavorite: isFavorite ?? this.isFavorite,
        position: position,
        updatedAt: DateTime.now(),
      );
}

class PagesNotifier extends AsyncNotifier<List<PageData>> {
  @override
  Future<List<PageData>> build() => _fetch();

  Future<List<PageData>> _fetch() async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    if (workspace == null) return [];
    final client = ref.read(supabaseProvider);
    final data = await client
        .from('pages')
        .select('id, title, icon, parent_id, is_favorite, position, updated_at')
        .eq('workspace_id', workspace.id)
        .isFilter('parent_id', null) // root-level pages only
        .order('position', ascending: true);
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(PageData.fromJson)
        .toList();
  }

  Future<PageData?> createPage({
    String title = 'Sem título',
    String? parentId,
  }) async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    final user = ref.read(currentUserProvider);
    if (workspace == null || user == null) return null;
    final client = ref.read(supabaseProvider);
    try {
      final rows = await client.from('pages').insert({
        'workspace_id': workspace.id,
        'title': title,
        if (parentId != null) 'parent_id': parentId,
        'created_by': user.id,
        'last_edited_by': user.id,
      }).select('id, title, icon, parent_id, is_favorite, position, updated_at');
      final newPage = PageData.fromJson(
          (rows as List).first as Map<String, dynamic>);
      // Optimistic insert
      state = state.whenData((list) => [newPage, ...list]);
      return newPage;
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePage(String pageId,
      {String? title, String? icon, bool? isFavorite}) async {
    final client = ref.read(supabaseProvider);
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (isFavorite != null) 'is_favorite': isFavorite,
    };
    await client.from('pages').update(updates).eq('id', pageId);
    state = state.whenData((list) => list
        .map((p) => p.id == pageId ? p.copyWith(title: title, isFavorite: isFavorite) : p)
        .toList());
  }

  Future<void> deletePage(String pageId) async {
    final client = ref.read(supabaseProvider);
    state = state.whenData(
        (list) => list.where((p) => p.id != pageId).toList());
    await client.from('pages').delete().eq('id', pageId);
  }
}

final pagesProvider =
    AsyncNotifierProvider<PagesNotifier, List<PageData>>(PagesNotifier.new);

// ─────────────────────────────────────────────────────────────
// BLOCKS
// ─────────────────────────────────────────────────────────────

class BlockData {
  final String id;
  final String pageId;
  final String type; // paragraph|heading1|heading2|heading3|bulleted_list|numbered_list|checklist|divider|quote|code
  final Map<String, dynamic> content;
  final int position;

  const BlockData({
    required this.id,
    required this.pageId,
    required this.type,
    required this.content,
    required this.position,
  });

  String get text => content['text'] as String? ?? '';
  bool get checked => content['checked'] as bool? ?? false;
  String get language => content['language'] as String? ?? 'dart';

  factory BlockData.fromJson(Map<String, dynamic> j) => BlockData(
        id: j['id'] as String,
        pageId: j['page_id'] as String,
        type: j['type'] as String? ?? 'paragraph',
        content: (j['content'] as Map<String, dynamic>?) ?? {},
        position: (j['position'] as num?)?.toInt() ?? 0,
      );

  BlockData copyWith({
    String? type,
    Map<String, dynamic>? content,
    int? position,
  }) =>
      BlockData(
        id: id,
        pageId: pageId,
        type: type ?? this.type,
        content: content ?? this.content,
        position: position ?? this.position,
      );

  Map<String, dynamic> toInsertMap(String pageId) => {
        'page_id': pageId,
        'type': type,
        'content': content,
        'position': position,
      };
}

/// Notifier that manages all blocks for a specific page.
class BlocksNotifier extends FamilyAsyncNotifier<List<BlockData>, String> {
  @override
  Future<List<BlockData>> build(String pageId) => _fetch(pageId);

  Future<List<BlockData>> _fetch(String pageId) async {
    final client = ref.read(supabaseProvider);
    final data = await client
        .from('blocks')
        .select('id, page_id, type, content, position')
        .eq('page_id', pageId)
        .order('position', ascending: true);
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(BlockData.fromJson)
        .toList();
  }

  /// Insert a new block at the given position, shifting others down.
  Future<BlockData?> insertBlock({
    required String pageId,
    required String type,
    required int position,
    Map<String, dynamic>? content,
  }) async {
    final client = ref.read(supabaseProvider);
    try {
      // Shift existing blocks >= position down by 1
      final currentBlocks = state.valueOrNull ?? [];
      final shifted = currentBlocks
          .map((b) => b.position >= position
              ? b.copyWith(position: b.position + 1)
              : b)
          .toList();

      // Persist shift in DB (bulk update would be ideal; for now update individually)
      for (final b in shifted.where((b) => b.position > position)) {
        await client
            .from('blocks')
            .update({'position': b.position}).eq('id', b.id);
      }

      // Insert new block
      final rows = await client.from('blocks').insert({
        'page_id': pageId,
        'type': type,
        'content': content ?? (type == 'checklist' ? {'text': '', 'checked': false} : {'text': ''}),
        'position': position,
      }).select('id, page_id, type, content, position');

      final newBlock =
          BlockData.fromJson((rows as List).first as Map<String, dynamic>);

      // Update local state
      final withNew = [...shifted, newBlock]
        ..sort((a, b) => a.position.compareTo(b.position));
      state = AsyncData(withNew);
      return newBlock;
    } catch (_) {
      return null;
    }
  }

  /// Update a block's content and/or type.
  Future<void> updateBlock(String blockId,
      {String? type, Map<String, dynamic>? content}) async {
    final client = ref.read(supabaseProvider);
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (type != null) 'type': type,
      if (content != null) 'content': content,
    };
    // Optimistic
    state = state.whenData((blocks) => blocks
        .map((b) => b.id == blockId ? b.copyWith(type: type, content: content) : b)
        .toList());
    await client.from('blocks').update(updates).eq('id', blockId);
  }

  /// Delete a block.
  Future<void> deleteBlock(String blockId) async {
    final client = ref.read(supabaseProvider);
    state = state.whenData(
        (blocks) => blocks.where((b) => b.id != blockId).toList());
    await client.from('blocks').delete().eq('id', blockId);
  }

  /// Reorder blocks after a drag.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final blocks = [...(state.valueOrNull ?? [])];
    if (oldIndex < newIndex) newIndex--;
    final moved = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, moved);
    // Re-assign positions
    final reordered = List<BlockData>.generate(
        blocks.length, (i) => blocks[i].copyWith(position: i));
    state = AsyncData(reordered);
    // Persist
    final client = ref.read(supabaseProvider);
    for (final b in reordered) {
      await client
          .from('blocks')
          .update({'position': b.position}).eq('id', b.id);
    }
  }
}

final blocksProvider =
    AsyncNotifierProviderFamily<BlocksNotifier, List<BlockData>, String>(
        BlocksNotifier.new);

/// Single page metadata provider (for editor header)
final pageMetaProvider =
    FutureProvider.autoDispose.family<PageData?, String>((ref, pageId) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('pages')
      .select('id, title, icon, parent_id, is_favorite, position, updated_at')
      .eq('id', pageId)
      .maybeSingle();
  if (data == null) return null;
  return PageData.fromJson(data);
});

// ─────────────────────────────────────────────────────────────
// NOTIFICATIONS
// ─────────────────────────────────────────────────────────────

class NotificationData {
  final String id;
  final String userId;
  final String? workspaceId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationData({
    required this.id,
    required this.userId,
    this.workspaceId,
    required this.type,
    required this.title,
    this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationData.fromJson(Map<String, dynamic> j) =>
      NotificationData(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        workspaceId: j['workspace_id'] as String?,
        type: j['type'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        data: (j['data'] as Map<String, dynamic>?) ?? {},
        isRead: j['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  /// Icon based on notification type
  static (dynamic, dynamic) typeVisual(String type) {
    return switch (type) {
      'task_assigned'    => ('check_box_rounded',        'primary'),
      'task_completed'   => ('task_alt_rounded',         'success'),
      'comment'          => ('comment_rounded',          'accent'),
      'mention'          => ('alternate_email_rounded',  'warning'),
      'project_update'   => ('folder_rounded',           'accent'),
      'deadline'         => ('alarm_rounded',            'error'),
      _                  => ('notifications_rounded',    'primary'),
    };
  }
}

class NotificationsNotifier extends AsyncNotifier<List<NotificationData>> {
  @override
  Future<List<NotificationData>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final client = ref.read(supabaseProvider);
    final data = await client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((e) => NotificationData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    final client = ref.read(supabaseProvider);
    await client.from('notifications').update({'is_read': true}).eq('id', id);

    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((n) {
      if (n.id == id) {
        return NotificationData(
          id: n.id,
          userId: n.userId,
          workspaceId: n.workspaceId,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList());
  }

  Future<void> markAllRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final client = ref.read(supabaseProvider);
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);

    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((n) => NotificationData(
      id: n.id,
      userId: n.userId,
      workspaceId: n.workspaceId,
      type: n.type,
      title: n.title,
      body: n.body,
      data: n.data,
      isRead: true,
      createdAt: n.createdAt,
    )).toList());
  }

  Future<void> delete(String id) async {
    final client = ref.read(supabaseProvider);
    await client.from('notifications').delete().eq('id', id);

    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((n) => n.id != id).toList());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationData>>(
        NotificationsNotifier.new);

/// Count of unread notifications
final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});

// ─────────────────────────────────────────────────────────────
// LABELS
// ─────────────────────────────────────────────────────────────

class LabelData {
  final String id;
  final String name;
  final String color;

  const LabelData({
    required this.id,
    required this.name,
    required this.color,
  });

  factory LabelData.fromJson(Map<String, dynamic> j) => LabelData(
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] as String? ?? '#5B6AF3',
      );
}

class LabelsNotifier extends AsyncNotifier<List<LabelData>> {
  @override
  Future<List<LabelData>> build() async {
    final ws = await ref.watch(currentWorkspaceProvider.future);
    if (ws == null) return [];

    final client = ref.read(supabaseProvider);
    final data = await client
        .from('labels')
        .select()
        .eq('workspace_id', ws.id)
        .order('name');

    return data.map((j) => LabelData.fromJson(j)).toList();
  }

  Future<LabelData> create(String name, String color) async {
    final ws = await ref.read(currentWorkspaceProvider.future);
    if (ws == null) throw Exception('No workspace');

    final client = ref.read(supabaseProvider);
    final row = await client.from('labels').insert({
      'workspace_id': ws.id,
      'name': name,
      'color': color,
    }).select().single();

    final label = LabelData.fromJson(row);
    state = AsyncData([...state.valueOrNull ?? [], label]);
    return label;
  }

  Future<void> delete(String id) async {
    final client = ref.read(supabaseProvider);
    await client.from('labels').delete().eq('id', id);
    state = AsyncData(
        (state.valueOrNull ?? []).where((l) => l.id != id).toList());
  }

  Future<void> updateLabel(String id, {String? name, String? color}) async {
    final client = ref.read(supabaseProvider);
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (color != null) updates['color'] = color;
    if (updates.isEmpty) return;

    await client.from('labels').update(updates).eq('id', id);
    state = AsyncData((state.valueOrNull ?? []).map((l) {
      if (l.id != id) return l;
      return LabelData(
        id: l.id,
        name: name ?? l.name,
        color: color ?? l.color,
      );
    }).toList());
  }
}

final labelsProvider =
    AsyncNotifierProvider<LabelsNotifier, List<LabelData>>(
        LabelsNotifier.new);

/// Labels assigned to a specific task
final taskLabelsProvider =
    FutureProvider.family<List<LabelData>, String>((ref, taskId) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('task_labels')
      .select('label_id, labels(*)')
      .eq('task_id', taskId);

  return data
      .map((row) => LabelData.fromJson(row['labels'] as Map<String, dynamic>))
      .toList();
});

/// Add a label to a task
Future<void> addLabelToTask(SupabaseClient client, String taskId, String labelId) async {
  await client.from('task_labels').upsert({
    'task_id': taskId,
    'label_id': labelId,
  });
}

/// Remove a label from a task
Future<void> removeLabelFromTask(SupabaseClient client, String taskId, String labelId) async {
  await client
      .from('task_labels')
      .delete()
      .eq('task_id', taskId)
      .eq('label_id', labelId);
}

// ─────────────────────────────────────────────────────────────
// CALENDAR EVENTS
// ─────────────────────────────────────────────────────────────

class CalendarEventData {
  final String id;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String color;
  final String? location;
  final String? taskId;
  final String eventType; // 'event' | 'task'

  const CalendarEventData({
    required this.id,
    required this.title,
    this.description,
    required this.startsAt,
    this.endsAt,
    this.allDay = false,
    this.color = '#5B6AF3',
    this.location,
    this.taskId,
    this.eventType = 'event',
  });

  factory CalendarEventData.fromJson(Map<String, dynamic> j) => CalendarEventData(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        startsAt: j['starts_at'] != null
            ? DateTime.parse(j['starts_at'] as String)
            : DateTime.now(),
        endsAt: j['ends_at'] != null
            ? DateTime.parse(j['ends_at'] as String)
            : null,
        allDay: j['all_day'] as bool? ?? false,
        color: j['color'] as String? ?? '#5B6AF3',
        location: j['location'] as String?,
        taskId: j['task_id'] as String?,
        eventType: j['event_type'] as String? ?? 'event',
      );

  DateTime get effectiveEnd => endsAt ?? startsAt;

  CalendarEventData copyWith({
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? allDay,
    String? color,
    String? location,
  }) => CalendarEventData(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        startsAt: startsAt ?? this.startsAt,
        endsAt: endsAt ?? this.endsAt,
        allDay: allDay ?? this.allDay,
        color: color ?? this.color,
        location: location ?? this.location,
        taskId: taskId,
        eventType: eventType,
      );
}

class CalendarEventsNotifier
    extends FamilyAsyncNotifier<List<CalendarEventData>, DateTime> {
  @override
  Future<List<CalendarEventData>> build(DateTime month) => _fetch(month);

  Future<List<CalendarEventData>> _fetch(DateTime month) async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    if (workspace == null) return [];

    final client = ref.read(supabaseProvider);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    try {
      final data = await client.rpc('get_calendar_range', params: {
        'p_workspace': workspace.id,
        'p_start': '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01',
        'p_end':
            '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}',
      }) as List<dynamic>;

      return data
          .map((e) => CalendarEventData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback: fetch directly from table
      final data = await client
          .from('calendar_events')
          .select()
          .eq('workspace_id', workspace.id)
          .gte('starts_at', firstDay.toIso8601String())
          .lte('starts_at', lastDay.add(const Duration(days: 1)).toIso8601String())
          .order('starts_at');

      return (data as List)
          .map((e) => CalendarEventData.fromJson({
                ...e as Map<String, dynamic>,
                'event_type': 'event',
              }))
          .toList();
    }
  }

  Future<CalendarEventData?> createEvent({
    required String title,
    required DateTime startsAt,
    DateTime? endsAt,
    bool allDay = true,
    String color = '#5B6AF3',
    String? description,
    String? location,
  }) async {
    final workspace = await ref.read(currentWorkspaceProvider.future);
    final user = ref.read(currentUserProvider);
    if (workspace == null || user == null) return null;

    final client = ref.read(supabaseProvider);
    try {
      final rows = await client.from('calendar_events').insert({
        'workspace_id': workspace.id,
        'title': title.trim(),
        'starts_at': startsAt.toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
        'all_day': allDay,
        'color': color,
        if (description != null && description.isNotEmpty)
          'description': description.trim(),
        if (location != null && location.isNotEmpty) 'location': location.trim(),
        'created_by': user.id,
      }).select();

      final event = CalendarEventData.fromJson({
        ...(rows as List).first as Map<String, dynamic>,
        'event_type': 'event',
      });

      state = state.whenData((list) => [...list, event]
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt)));
      return event;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final client = ref.read(supabaseProvider);
    await client.from('calendar_events').delete().eq('id', eventId);
    state = state.whenData(
        (list) => list.where((e) => e.id != eventId).toList());
  }

  Future<CalendarEventData?> updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required String color,
    String? description,
    bool allDay = true,
  }) async {
    final client = ref.read(supabaseProvider);
    try {
      final rows = await client
          .from('calendar_events')
          .update({
            'title': title.trim(),
            'starts_at': startsAt.toIso8601String(),
            'all_day': allDay,
            'color': color,
            'description':
                description != null && description.isNotEmpty ? description.trim() : null,
          })
          .eq('id', eventId)
          .select();

      final updated = CalendarEventData.fromJson({
        ...(rows as List).first as Map<String, dynamic>,
        'event_type': 'event',
      });

      state = state.whenData((list) => list
          .map((e) => e.id == eventId ? updated : e)
          .toList());
      return updated;
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh(DateTime month) async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch(month));
  }
}

final calendarEventsProvider = AsyncNotifierProviderFamily<
    CalendarEventsNotifier, List<CalendarEventData>, DateTime>(
  CalendarEventsNotifier.new,
);

// ── Integração Microsoft Graph ───────────────────────────────
final msGraphServiceProvider = Provider<MSGraphService>((ref) {
  return MSGraphService();
});

final msGraphEventsProvider = FutureProvider.family<List<CalendarEventData>, DateTime>((ref, month) async {
  final service = ref.watch(msGraphServiceProvider);
  return await service.fetchEvents(month);
});
