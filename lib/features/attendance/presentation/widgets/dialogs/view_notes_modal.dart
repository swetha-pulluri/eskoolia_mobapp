import 'package:flutter/material.dart';
import '../../../domain/entities/attendance_entities.dart';

/// View Notes Modal — converted from web
/// `attendance/student/components/ViewNotesModal.tsx`.
class ViewNotesModal extends StatefulWidget {
  final AttendanceStudentEntity student;
  final void Function(String noteId, String newText) onEditNote;
  final void Function(String noteId) onDeleteNote;
  final VoidCallback onClose;

  const ViewNotesModal({super.key, required this.student, required this.onEditNote, required this.onDeleteNote, required this.onClose});

  @override
  State<ViewNotesModal> createState() => _ViewNotesModalState();
}

class _ViewNotesModalState extends State<ViewNotesModal> {
  final Set<String> _expanded = {};
  String? _editingId;
  String? _confirmingDeleteId;
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.student.notes;
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x66000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
                      Text(widget.student.fullName, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA0AE))),
                    ]),
                  ),
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF4F4F8), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.close, size: 14, color: Color(0xFF6B6B7B))),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: notes.isEmpty
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No notes added yet.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)))))
                      : Column(children: List.generate(notes.length, (i) => _noteCard(notes[i], i))),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  ElevatedButton(onPressed: widget.onClose, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white), child: const Text('Close')),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _noteCard(StudentNoteEntity note, int index) {
    final isExpanded = _expanded.contains(note.id);
    final isEditing = _editingId == note.id;
    final isConfirmingDelete = _confirmingDeleteId == note.id;
    final preview = note.text.length > 60 ? '${note.text.substring(0, 60)}…' : note.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: isEditing
                ? null
                : () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(note.id);
                      } else {
                        _expanded.add(note.id);
                      }
                    }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFFAFAFD),
              child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: const Color(0xFFEEEBFF), borderRadius: BorderRadius.circular(4)), child: Text('#${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4729F4)))),
                const SizedBox(width: 8),
                Expanded(child: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3A3A4A)))),
                if (note.createdAt.isNotEmpty) Text(note.createdAt, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA0AE))),
                _tinyIconBtn(Icons.edit_outlined, tooltip: 'Edit note', onTap: () => setState(() {
                      _confirmingDeleteId = null;
                      _editingId = note.id;
                      _editController.text = note.text;
                      _expanded.add(note.id);
                    })),
                _tinyIconBtn(Icons.delete_outline, tooltip: 'Delete note', hoverBg: const Color(0xFFFCE8EE), hoverFg: const Color(0xFFC2264E), onTap: () => setState(() {
                      _editingId = null;
                      _confirmingDeleteId = note.id;
                    })),
                AnimatedRotation(turns: isExpanded || isEditing ? 0.5 : 0, duration: const Duration(milliseconds: 150), child: const Icon(Icons.expand_more, size: 14, color: Color(0xFF6B6B7B))),
              ]),
            ),
          ),
          if (isConfirmingDelete)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(color: Color(0xFFFFF5F7), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
              child: Row(children: [
                const Expanded(child: Text('Delete this note?', style: TextStyle(fontSize: 11, color: Color(0xFFC2264E)))),
                TextButton(onPressed: () => setState(() => _confirmingDeleteId = null), style: TextButton.styleFrom(backgroundColor: const Color(0xFFF4F4F8), foregroundColor: const Color(0xFF6B6B7B), minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)), child: const Text('Cancel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                const SizedBox(width: 6),
                TextButton(onPressed: () => widget.onDeleteNote(note.id), style: TextButton.styleFrom(backgroundColor: const Color(0xFFC2264E), foregroundColor: Colors.white, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)), child: const Text('Delete', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
              ]),
            )
          else if (isExpanded || isEditing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
              child: isEditing
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      TextField(controller: _editController, autofocus: true, maxLines: 3, style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A4A)), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE6E6EC))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF4729F4))))),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(onPressed: () => setState(() => _editingId = null), style: TextButton.styleFrom(backgroundColor: const Color(0xFFF4F4F8), foregroundColor: const Color(0xFF6B6B7B), minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)), child: const Text('Cancel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: _editController.text.trim().isEmpty
                              ? null
                              : () {
                                  widget.onEditNote(note.id, _editController.text.trim());
                                  setState(() => _editingId = null);
                                },
                          style: TextButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          child: const Text('Save', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ])
                  : Text(note.text, style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A4A), height: 1.4)),
            ),
        ],
      ),
    );
  }

  Widget _tinyIconBtn(IconData icon, {required String tooltip, required VoidCallback onTap, Color hoverBg = const Color(0xFFEEEBFF), Color hoverFg = const Color(0xFF4729F4)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(width: 20, height: 20, alignment: Alignment.center, child: Icon(icon, size: 13, color: const Color(0xFF6B6B7B))),
        ),
      ),
    );
  }
}
