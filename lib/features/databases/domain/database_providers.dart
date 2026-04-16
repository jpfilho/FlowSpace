import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/data_providers.dart';

// ── Models ───────────────────────────────────────────────────

class DbColumnData {
  final String id;
  final String name;
  final String type; // 'text', 'number', 'date', 'select', 'checkbox'
  final int position;
  final int width;
  final Map<String, dynamic> options;

  const DbColumnData({
    required this.id,
    required this.name,
    this.type = 'text',
    this.position = 0,
    this.width = 200,
    this.options = const {},
  });

  factory DbColumnData.fromJson(Map<String, dynamic> j) => DbColumnData(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String? ?? 'text',
        position: j['position'] as int? ?? 0,
        width: j['width'] as int? ?? 200,
        options: j['options'] != null ? j['options'] as Map<String, dynamic> : {},
      );
}

class DbRowData {
  final String id;
  final int position;
  final Map<String, dynamic> data;

  const DbRowData({
    required this.id,
    this.position = 0,
    this.data = const {},
  });

  factory DbRowData.fromJson(Map<String, dynamic> j) => DbRowData(
        id: j['id'] as String,
        position: j['position'] as int? ?? 0,
        data: j['data'] != null ? j['data'] as Map<String, dynamic> : {},
      );

  DbRowData copyWithData(Map<String, dynamic> newData) {
    return DbRowData(
      id: id,
      position: position,
      data: Map<String, dynamic>.from(data)..addAll(newData),
    );
  }
}

class DatabaseData {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String color;

  const DatabaseData({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color = '#5B6AF3',
  });

  factory DatabaseData.fromJson(Map<String, dynamic> j) => DatabaseData(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        icon: j['icon'] as String?,
        color: j['color'] as String? ?? '#5B6AF3',
      );
}

// ── Providers ────────────────────────────────────────────────

class DatabasesNotifier extends AsyncNotifier<List<DatabaseData>> {
  @override
  Future<List<DatabaseData>> build() async {
    final ws = await ref.watch(currentWorkspaceProvider.future);
    if (ws == null) return [];

    final client = ref.read(supabaseProvider);
    final data = await client
        .from('databases')
        .select()
        .eq('workspace_id', ws.id)
        .order('created_at', ascending: false);

    return data.map((j) => DatabaseData.fromJson(j)).toList();
  }

  Future<DatabaseData> create(String name, {String? description}) async {
    final ws = await ref.read(currentWorkspaceProvider.future);
    if (ws == null) throw Exception('No workspace');

    final client = ref.read(supabaseProvider);
    
    // Create DB
    final row = await client.from('databases').insert({
      'workspace_id': ws.id,
      'name': name,
      'description': description,
    }).select().single();
    
    final db = DatabaseData.fromJson(row);

    // Create 1 default column (text)
    await client.from('db_columns').insert({
      'database_id': db.id,
      'name': 'Nome',
      'type': 'text',
      'position': 0,
    });

    state = AsyncData([db, ...state.valueOrNull ?? []]);
    return db;
  }

  Future<void> delete(String id) async {
    final client = ref.read(supabaseProvider);
    await client.from('databases').delete().eq('id', id);
    state = AsyncData(
        (state.valueOrNull ?? []).where((d) => d.id != id).toList());
  }
}

final databasesProvider =
    AsyncNotifierProvider<DatabasesNotifier, List<DatabaseData>>(
        DatabasesNotifier.new);

// ── Database detail (Columns & DB Info) ──────────────────────

class DatabaseDetail {
  final DatabaseData database;
  final List<DbColumnData> columns;

  const DatabaseDetail(this.database, this.columns);
}

final databaseDetailProvider =
    FutureProvider.family<DatabaseDetail?, String>((ref, dbId) async {
  final client = ref.read(supabaseProvider);
  
  final dbRes = await client.from('databases').select().eq('id', dbId).maybeSingle();
  if (dbRes == null) return null;
  
  final colsRes = await client.from('db_columns').select().eq('database_id', dbId).order('position');
  
  return DatabaseDetail(
    DatabaseData.fromJson(dbRes),
    colsRes.map((j) => DbColumnData.fromJson(j)).toList(),
  );
});

// ── Database Rows Stream ────────────────────────────────────

final databaseRowsProvider = StreamProvider.family<List<DbRowData>, String>((ref, dbId) {
  final client = ref.read(supabaseProvider);
  return client
      .from('db_rows')
      .stream(primaryKey: ['id'])
      .eq('database_id', dbId)
      .order('position', ascending: true)
      .map((list) => list.map((j) => DbRowData.fromJson(j)).toList());
});

// ── Cell Operations ──────────────────────────────────────────

Future<void> updateDbCell(
    dynamic ref, String rowId, String colId, dynamic value) async {
  final client = ref.read(supabaseProvider);
  
  // We need to merge the JSON. We can use jsonb_set or just read and write.
  // Easiest is to let PostgREST handle jsonb merge via or we can just fetch, modify, save.
  // Actually, Supabase supports partial updates for JSONB via nested keys but it's simpler to do a read-modify-write
  // since rows are relatively small. OR simpler, use a custom RPC or use PostgREST RPC if exist.
  
  final res = await client.from('db_rows').select('data').eq('id', rowId).single();
  final currentData = res['data'] as Map<String, dynamic>? ?? {};
  
  currentData[colId] = value;
  
  await client.from('db_rows').update({
    'data': currentData,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', rowId);
}

Future<void> addDbRow(dynamic ref, String dbId, Map<String, dynamic> initialData) async {
  final client = ref.read(supabaseProvider);
  
  // Get max position
  final res = await client.from('db_rows').select('position').eq('database_id', dbId).order('position', ascending: false).limit(1).maybeSingle();
  final maxPos = res != null ? (res['position'] as int? ?? 0) : 0;
  
  await client.from('db_rows').insert({
    'database_id': dbId,
    'position': maxPos + 1000,
    'data': initialData,
  });
}

Future<void> deleteDbRow(dynamic ref, String rowId) async {
  final client = ref.read(supabaseProvider);
  await client.from('db_rows').delete().eq('id', rowId);
}
