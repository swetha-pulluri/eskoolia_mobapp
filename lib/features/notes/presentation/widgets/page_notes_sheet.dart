import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note_entity.dart';
import '../providers/notes_provider.dart';
import 'all_notes_sheet.dart';
import 'note_colors.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk3 = Color(0xFF9197AE);

/// Mobile reshape of web's freeform, draggable `PageNotesPanel`/
/// `StickyNoteCard`s into a single scrollable bottom sheet: color-tag
/// "new note" row up top, then the current screen's notes as a list.
Future<void> showPageNotesSheet(BuildContext navContext) {
  return showModalBottomSheet(
    context: navContext,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => const _PageNotesSheetContent(),
  );
}

class _PageNotesSheetContent extends ConsumerWidget {
  const _PageNotesSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesForCurrentRouteProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined, size: 16, color: _navInk1),
                const SizedBox(width: 8),
                const Expanded(child: Text('Notes for this page', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navInk1))),
                InkWell(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, size: 16, color: _navInk3)),
              ],
            ),
          ),
          const Divider(height: 1, color: _navBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final c in noteColors)
                  InkWell(
                    onTap: () => createNoteForCurrentRoute(ref, c.key),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: c.swatch, shape: BoxShape.circle),
                          child: const Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(c.label, style: const TextStyle(fontSize: 9, color: _navInk3)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _navBorder),
          Expanded(
            child: notesAsync.when(
              data: (notes) => notes.isEmpty
                  ? const Center(child: Text('No notes on this page yet', style: TextStyle(fontSize: 13, color: _navInk3)))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: notes.length,
                      itemBuilder: (context, index) => _NoteCard(note: notes[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e', style: const TextStyle(fontSize: 12, color: _navInk3))),
            ),
          ),
          const Divider(height: 1, color: _navBorder),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              showAllNotesSheet(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Open all my notes →', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6D4AFF))),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerStatefulWidget {
  final NoteEntity note;
  const _NoteCard({required this.note});

  @override
  ConsumerState<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<_NoteCard> {
  late final TextEditingController _controller = TextEditingController(text: widget.note.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_controller.text != widget.note.text) {
      updateNote(ref, widget.note.id, text: _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorDef = noteColorFor(widget.note.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colorDef.background, border: Border.all(color: colorDef.border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
            style: const TextStyle(fontSize: 13, color: _navInk1),
            decoration: const InputDecoration(hintText: 'Write a note…', border: InputBorder.none, isDense: true),
          ),
          Row(
            children: [
              if (widget.note.authorInitials != null) ...[
                Text(widget.note.authorInitials!, style: const TextStyle(fontSize: 10, color: _navInk3)),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              InkWell(
                onTap: () => updateNote(ref, widget.note.id, pinned: !widget.note.pinned),
                child: Icon(widget.note.pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 15, color: widget.note.pinned ? colorDef.swatch : _navInk3),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => deleteNote(ref, widget.note.id),
                child: const Icon(Icons.delete_outline, size: 15, color: _navInk3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
