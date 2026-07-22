import 'package:flutter/material.dart';
import '../../../domain/entities/attendance_entities.dart';

/// Notes Modal (add/edit a single note) — converted from web
/// `attendance/student/components/NotesModal.tsx`.
class NotesModal extends StatefulWidget {
  final AttendanceStudentEntity student;
  final String initialNote;
  final void Function(AttendanceStudentEntity student, String note) onSave;
  final VoidCallback onClose;

  const NotesModal({super.key, required this.student, this.initialNote = '', required this.onSave, required this.onClose});

  @override
  State<NotesModal> createState() => _NotesModalState();
}

class _NotesModalState extends State<NotesModal> {
  late final _controller = TextEditingController(text: widget.initialNote);
  bool get _isEditing => widget.initialNote.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x66000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_isEditing ? 'Edit Note' : 'Add Note', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(
                    controller: _controller,
                    maxLength: 250,
                    maxLines: 4,
                    minLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter a note for this student...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4729F4), width: 2)),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0B0B14)),
                  ),
                  Align(alignment: Alignment.centerRight, child: Text('${_controller.text.length}/250', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA0AE)))),
                ]),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(onPressed: widget.onClose, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _controller.text.trim().isEmpty ? null : () => widget.onSave(widget.student, _controller.text.trim()),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white),
                    child: Text(_isEditing ? 'Update Note' : 'Save Note'),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
