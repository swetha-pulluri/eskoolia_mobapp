import '../../domain/models/ai_message.dart';
import '../../domain/models/ai_todo_item.dart';

/// Mirrors AIBot.tsx's collection of `useState` hooks that drive the panel.
class AiAssistantState {
  final bool open;
  final List<AiMsg> msgs;
  final bool loading;
  final List<AiTodoItem> todos;
  final bool showTodos;
  final bool showChips;

  const AiAssistantState({
    this.open = false,
    this.msgs = const [],
    this.loading = false,
    this.todos = const [],
    this.showTodos = false,
    this.showChips = false,
  });

  AiAssistantState copyWith({
    bool? open,
    List<AiMsg>? msgs,
    bool? loading,
    List<AiTodoItem>? todos,
    bool? showTodos,
    bool? showChips,
  }) {
    return AiAssistantState(
      open: open ?? this.open,
      msgs: msgs ?? this.msgs,
      loading: loading ?? this.loading,
      todos: todos ?? this.todos,
      showTodos: showTodos ?? this.showTodos,
      showChips: showChips ?? this.showChips,
    );
  }
}
