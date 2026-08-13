/// Mirrors `TodoItemSerializer`'s exact camelCase wire fields
/// (`GET/POST /api/user/todos/`, `PATCH/DELETE /api/user/todos/{id}/`).
/// `category` is one of `academic|ops|comms|personal` (backend
/// `CharField(choices=...)`, plain `String` here — same convention as
/// `NoteEntity.color`).
class TodoItemEntity {
  final int id;
  final String text;
  final String category;
  final String priority;
  final DateTime? dueAt;
  final bool aiGenerated;
  final String aiReason;
  final bool completed;

  const TodoItemEntity({
    required this.id,
    required this.text,
    required this.category,
    this.priority = 'normal',
    this.dueAt,
    this.aiGenerated = false,
    this.aiReason = '',
    this.completed = false,
  });

  factory TodoItemEntity.fromJson(Map<String, dynamic> json) => TodoItemEntity(
        id: json['id'] as int,
        text: (json['text'] as String?) ?? '',
        category: (json['category'] as String?) ?? 'personal',
        priority: (json['priority'] as String?) ?? 'normal',
        dueAt: json['dueAt'] != null ? DateTime.tryParse(json['dueAt'] as String) : null,
        aiGenerated: json['aiGenerated'] as bool? ?? false,
        aiReason: (json['aiReason'] as String?) ?? '',
        completed: json['completed'] as bool? ?? false,
      );
}
