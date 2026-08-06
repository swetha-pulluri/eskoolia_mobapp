import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../domain/entities/note_entity.dart';
import '../providers/notes_provider.dart';
import 'note_colors.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk2 = Color(0xFF5A607A);
const _navInk3 = Color(0xFF9197AE);

/// Mobile reshape of web's `AllNotes.tsx` modal — a near-fullscreen sheet
/// with search + color filter + archived toggle over every note the user
/// has, as a single scrollable column (not web's masonry grid).
Future<void> showAllNotesSheet(BuildContext navContext) {
  return showModalBottomSheet(
    context: navContext,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => const _AllNotesSheetContent(),
  );
}

class _AllNotesSheetContent extends ConsumerStatefulWidget {
  const _AllNotesSheetContent();

  @override
  ConsumerState<_AllNotesSheetContent> createState() => _AllNotesSheetContentState();
}

class _AllNotesSheetContentState extends ConsumerState<_AllNotesSheetContent> {
  String _search = '';
  String? _colorFilter;
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(child: Text('All my notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navInk1))),
                InkWell(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, size: 18, color: _navInk3)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search notes…',
                prefixIcon: const Icon(Icons.search, size: 16),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF3F4FB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('All', _colorFilter == null, () => setState(() => _colorFilter = null)),
                for (final c in noteColors) _filterChip(c.label, _colorFilter == c.key, () => setState(() => _colorFilter = c.key)),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _showArchived = !_showArchived),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_showArchived ? Icons.check_box_outlined : Icons.check_box_outline_blank, size: 16, color: _navInk2),
                      const SizedBox(width: 4),
                      const Text('Archived', style: TextStyle(fontSize: 11, color: _navInk2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _navBorder),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final filtered = notes.where((n) {
                  if (n.archived != _showArchived) return false;
                  if (_colorFilter != null && n.color != _colorFilter) return false;
                  if (_search.trim().isNotEmpty) {
                    final q = _search.toLowerCase();
                    if (!n.text.toLowerCase().contains(q) && !n.route.toLowerCase().contains(q)) return false;
                  }
                  return true;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No notes found', style: TextStyle(fontSize: 13, color: _navInk3)));
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _AllNoteRow(note: filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e', style: const TextStyle(fontSize: 12, color: _navInk3))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6D4AFF) : const Color(0xFFF3F4FB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : _navInk2)),
        ),
      ),
    );
  }
}

class _AllNoteRow extends ConsumerWidget {
  final NoteEntity note;
  const _AllNoteRow({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorDef = noteColorFor(note.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colorDef.background, border: Border.all(color: colorDef.border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(appRouterProvider).go(note.route);
                    Navigator.of(context).pop();
                  },
                  child: Text(note.route, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6D4AFF), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ),
              ),
              InkWell(
                onTap: () => updateNote(ref, note.id, pinned: !note.pinned),
                child: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 14, color: note.pinned ? colorDef.swatch : _navInk3),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => updateNote(ref, note.id, archived: !note.archived),
                child: Icon(note.archived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 14, color: _navInk3),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => deleteNote(ref, note.id),
                child: const Icon(Icons.delete_outline, size: 14, color: _navInk3),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note.text.isEmpty ? '(empty note)' : note.text,
            style: TextStyle(fontSize: 13, color: note.text.isEmpty ? _navInk3 : _navInk1),
          ),
        ],
      ),
    );
  }
}
