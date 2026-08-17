import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/todo_item_entity.dart';
import '../providers/todos_providers.dart';

const _tabs = [
  ('all', 'All'),
  ('academic', 'Academic'),
  ('ops', 'Ops'),
  ('comms', 'Comms'),
  ('personal', 'Personal'),
];

final _hashtagPattern = RegExp(r'#(academic|ops|comms|personal)', caseSensitive: false);
final _hashtagStripPattern = RegExp(r'#\w+');

/// "Smart To-Do" — real CRUD against `/api/user/todos/` (shared with
/// Admin). Exact copy match with web's `SmartTodoList.tsx`: hashtag-based
/// category parsing on add, `{n} pending` counter, empty-state text.
class SmartTodoCard extends ConsumerStatefulWidget {
  const SmartTodoCard({super.key});

  @override
  ConsumerState<SmartTodoCard> createState() => _SmartTodoCardState();
}

class _SmartTodoCardState extends ConsumerState<SmartTodoCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(selectedTodoCategoryProvider);
    final todosAsync = ref.watch(todosProvider);
    final pendingCount = todosAsync.maybeWhen(data: (todos) => todos.where((t) => !t.completed).length, orElse: () => 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bg1, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.ink1),
              const SizedBox(width: 6),
              const Expanded(child: Text('Smart To-Do', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink1))),
              Text('$pendingCount pending', style: const TextStyle(fontSize: 11.5, color: AppColors.ink3)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tab in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _tabChip(tab.$2, activeTab == tab.$1, () => ref.read(selectedTodoCategoryProvider.notifier).state = tab.$1),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a task… (#academic #ops #comms)',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.bg2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _addTask(activeTab),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _addTask(activeTab),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.brandPurple, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          todosAsync.when(
            data: (todos) => todos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No tasks — enjoy the clear day ✓', style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
                  )
                : Column(children: [for (final todo in todos) _todoRow(todo)]),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$e', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => ref.invalidate(todosProvider),
                    child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandPurple)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTask(String activeTab) {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final match = _hashtagPattern.firstMatch(raw);
    final category = match != null ? match.group(1)!.toLowerCase() : (activeTab == 'all' ? 'personal' : activeTab);
    final text = raw.replaceAll(_hashtagStripPattern, '').trim();
    createTodo(ref, text: text, category: category);
    _controller.clear();
  }

  Widget _tabChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPurple : AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.ink2)),
      ),
    );
  }

  Widget _todoRow(TodoItemEntity todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => toggleTodoCompleted(ref, todo),
            child: Icon(
              todo.completed ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: todo.completed ? AppColors.brandPurple : AppColors.ink3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              todo.text,
              style: TextStyle(
                fontSize: 13,
                color: todo.completed ? AppColors.ink3 : AppColors.ink1,
                decoration: todo.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          InkWell(
            onTap: () => deleteTodoItem(ref, todo.id),
            child: const Icon(Icons.close, size: 14, color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}
