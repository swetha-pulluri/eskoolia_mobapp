import 'package:flutter/material.dart';
import '../../../domain/entities/attendance_entities.dart';

const List<String> kQuickAbsentReasons = ['Parent applied leave', 'Parent informed — student is sick', 'No intimation'];
const String kNoIntimationReason = 'No intimation';

/// Absent Note Dialog — converted from web
/// `attendance/student/components/AbsentNoteDialog.tsx`.
class AbsentNoteDialog extends StatefulWidget {
  final AttendanceStudentEntity student;
  final String initialReason;
  final ValueChanged<String> onConfirm;
  final VoidCallback onSkip;

  const AbsentNoteDialog({super.key, required this.student, this.initialReason = '', required this.onConfirm, required this.onSkip});

  @override
  State<AbsentNoteDialog> createState() => _AbsentNoteDialogState();
}

class _AbsentNoteDialogState extends State<AbsentNoteDialog> {
  String? _selected;
  late final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kQuickAbsentReasons.contains(widget.initialReason)) {
      _selected = widget.initialReason;
    } else {
      _customController.text = widget.initialReason;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = _customController.text.trim().isNotEmpty ? _customController.text.trim() : (_selected ?? '');
    final shouldCountWithReason = reason.isNotEmpty && reason != kNoIntimationReason;

    return GestureDetector(
      onTap: widget.onSkip,
      child: Container(
        color: const Color(0x66000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFFCE8EE), shape: BoxShape.circle), alignment: Alignment.center, child: const Icon(Icons.cancel_outlined, size: 12, color: Color(0xFFC2264E))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Mark ${widget.student.fullName} Absent', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
                      const SizedBox(height: 2),
                      const Text('Select a reason to track this absence.', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B7B))),
                    ]),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QUICK REASONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
                    const SizedBox(height: 6),
                    ...kQuickAbsentReasons.map((r) {
                      final isSelected = _selected == r && _customController.text.isEmpty;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() {
                            _selected = r;
                            _customController.clear();
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFCE8EE) : const Color(0xFFFAFAFD),
                              border: Border.all(color: isSelected ? const Color(0x66C2264E) : const Color(0xFFE6E6EC)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFF7C1030) : const Color(0xFF3A3A4A))),
                          ),
                        ),
                      );
                    }),
                    TextField(
                      controller: _customController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Or type a custom reason…',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4729F4))),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: const Color(0xFFFAFAFD),
                // `Wrap` (not a bare `Row`) — "Mark Absent with Reason" plus
                // "Skip" can exceed the 420px-capped dialog's width on a
                // 320-360dp phone; `mainAxisAlignment: end` alone doesn't
                // stop the Row from overflowing, it just doesn't help avoid
                // it either. `WrapAlignment.end` gives the same visual
                // right-alignment but lets the buttons drop to a second
                // line instead.
                child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
                  OutlinedButton(onPressed: widget.onSkip, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Skip')),
                  ElevatedButton(
                    onPressed: () => widget.onConfirm(reason),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2264E), foregroundColor: Colors.white),
                    child: Text(shouldCountWithReason ? 'Mark Absent with Reason' : 'Mark Absent'),
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
