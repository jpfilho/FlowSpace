/// Model para a tabela task_5w2h.
///
/// Suporta múltiplos registros por tarefa (sem UNIQUE task_id).
/// Cada registro tem um título e índice de ordenação.
class Task5w2hModel {
  final String id;
  final String taskId;
  final String title;
  final int orderIndex;
  final String? what;
  final String? why;
  final String? whereTask;
  final String? whenDetails;
  final String? whoDetails;
  final String? how;
  final String? howMuch;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Task5w2hModel({
    required this.id,
    required this.taskId,
    this.title = '5W2H',
    this.orderIndex = 0,
    this.what,
    this.why,
    this.whereTask,
    this.whenDetails,
    this.whoDetails,
    this.how,
    this.howMuch,
    this.createdAt,
    this.updatedAt,
  });

  /// Constrói um model vazio para criação de novo registro.
  factory Task5w2hModel.empty(String taskId, {int orderIndex = 0}) =>
      Task5w2hModel(
        id: '',
        taskId: taskId,
        title: '5W2H',
        orderIndex: orderIndex,
      );

  /// Desserializa a partir de um Map retornado pelo Supabase.
  factory Task5w2hModel.fromMap(Map<String, dynamic> map) => Task5w2hModel(
        id: map['id'] as String? ?? '',
        taskId: map['task_id'] as String? ?? '',
        title: map['title'] as String? ?? '5W2H',
        orderIndex: map['order_index'] as int? ?? 0,
        what: map['what'] as String?,
        why: map['why'] as String?,
        whereTask: map['where_task'] as String?,
        whenDetails: map['when_details'] as String?,
        whoDetails: map['who_details'] as String?,
        how: map['how'] as String?,
        howMuch: map['how_much'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
      );

  /// Serializa para Map no formato esperado pelo Supabase.
  Map<String, dynamic> toMap() => {
        if (id.isNotEmpty) 'id': id,
        'task_id': taskId,
        'title': title,
        'order_index': orderIndex,
        'what': what,
        'why': why,
        'where_task': whereTask,
        'when_details': whenDetails,
        'who_details': whoDetails,
        'how': how,
        'how_much': howMuch,
      };

  /// Cria uma cópia com campos substituídos.
  Task5w2hModel copyWith({
    String? id,
    String? taskId,
    String? title,
    int? orderIndex,
    String? what,
    String? why,
    String? whereTask,
    String? whenDetails,
    String? whoDetails,
    String? how,
    String? howMuch,
  }) =>
      Task5w2hModel(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        orderIndex: orderIndex ?? this.orderIndex,
        what: what ?? this.what,
        why: why ?? this.why,
        whereTask: whereTask ?? this.whereTask,
        whenDetails: whenDetails ?? this.whenDetails,
        whoDetails: whoDetails ?? this.whoDetails,
        how: how ?? this.how,
        howMuch: howMuch ?? this.howMuch,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Retorna true se todos os campos de conteúdo forem nulos ou vazios.
  bool get isEmpty =>
      (what?.trim().isEmpty ?? true) &&
      (why?.trim().isEmpty ?? true) &&
      (whereTask?.trim().isEmpty ?? true) &&
      (whenDetails?.trim().isEmpty ?? true) &&
      (whoDetails?.trim().isEmpty ?? true) &&
      (how?.trim().isEmpty ?? true) &&
      (howMuch?.trim().isEmpty ?? true);

  /// Conta campos preenchidos.
  int get filledCount {
    int c = 0;
    if (what?.trim().isNotEmpty == true) c++;
    if (why?.trim().isNotEmpty == true) c++;
    if (whereTask?.trim().isNotEmpty == true) c++;
    if (whenDetails?.trim().isNotEmpty == true) c++;
    if (whoDetails?.trim().isNotEmpty == true) c++;
    if (how?.trim().isNotEmpty == true) c++;
    if (howMuch?.trim().isNotEmpty == true) c++;
    return c;
  }

  @override
  String toString() =>
      'Task5w2hModel(id: $id, taskId: $taskId, title: $title)';
}
