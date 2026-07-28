/// Mirrors frontend components/AIBot.tsx's `TodoItem` interface, persisted
/// under the same `eskoolia_todos` local-storage key.
class AiTodoItem {
  final String id;
  final String text;
  final bool done;

  const AiTodoItem({required this.id, required this.text, this.done = false});

  AiTodoItem copyWith({bool? done}) => AiTodoItem(id: id, text: text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory AiTodoItem.fromJson(Map<String, dynamic> json) => AiTodoItem(
        id: json['id'] as String,
        text: (json['text'] as String?) ?? '',
        done: json['done'] as bool? ?? false,
      );
}
