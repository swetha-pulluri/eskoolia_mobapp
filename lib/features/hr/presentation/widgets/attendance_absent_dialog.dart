import 'dart:math' as math;

import 'package:flutter/material.dart';

const _quickReasons = ['Personal leave', 'Medical/Sick leave', 'No intimation'];

/// A literal port of the real `StaffAbsentNoteDialog.tsx` on `origin/demo`.
/// "AI Suggest Reason" is a fake local template cycler in the real app too
/// (no LLM call) — ported as-is since it has no backend dependency.
class AttendanceAbsentDialog extends StatefulWidget {
  final String staffName;
  final String? initialReason;

  const AttendanceAbsentDialog({super.key, required this.staffName, this.initialReason});

  static Future<String?> show(BuildContext context, {required String staffName, String? initialReason}) {
    return showDialog<String>(
      context: context,
      builder: (context) => AttendanceAbsentDialog(staffName: staffName, initialReason: initialReason),
    );
  }

  @override
  State<AttendanceAbsentDialog> createState() => _AttendanceAbsentDialogState();
}

class _AttendanceAbsentDialogState extends State<AttendanceAbsentDialog> {
  String? _selected;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReason;
    if (initial != null && _quickReasons.contains(initial)) {
      _selected = initial;
    } else if (initial != null && initial.isNotEmpty) {
      _customCtrl.text = initial;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  String get _reason => _customCtrl.text.trim().isNotEmpty ? _customCtrl.text.trim() : (_selected ?? '');
  bool get _shouldCountWithReason => _reason.isNotEmpty && _reason != 'No intimation';

  void _aiSuggest() {
    final templates = [
      '${widget.staffName} is on approved personal leave today.',
      '${widget.staffName} is unwell and has informed HR in advance.',
      '${widget.staffName} has a medical appointment and is expected to rejoin tomorrow.',
      '${widget.staffName} reported a transport issue and could not attend today.',
    ];
    final idx = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 4;
    setState(() {
      _selected = null;
      _customCtrl.text = templates[idx];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.cancel, color: Color(0xFFC2264E), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text('Mark ${widget.staffName} Absent', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
      ]),
      content: ConstrainedBox(
        // A hardcoded desktop width overflows a 320-360dp phone screen once
        // the dialog's own insets are subtracted; cap it to whichever is
        // smaller.
        constraints: BoxConstraints(maxWidth: math.min(380, MediaQuery.sizeOf(context).width - 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a reason to track this absence.', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B6B80))),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _aiSuggest, icon: const Icon(Icons.auto_awesome, size: 14), label: const Text('AI Suggest Reason')),
            const SizedBox(height: 14),
            const Text('QUICK REASONS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF9CA0AE))),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final r in _quickReasons)
                ChoiceChip(
                  label: Text(r, style: const TextStyle(fontSize: 12.5)),
                  selected: _selected == r,
                  selectedColor: const Color(0xFFFCE8EE),
                  labelStyle: TextStyle(color: _selected == r ? const Color(0xFF7C1030) : null, fontWeight: _selected == r ? FontWeight.w700 : FontWeight.w500),
                  onSelected: (_) => setState(() {
                    _selected = _selected == r ? null : r;
                    if (_selected != null) _customCtrl.clear();
                  }),
                ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _customCtrl,
              decoration: const InputDecoration(hintText: 'Or type a custom reason…', border: OutlineInputBorder(), isDense: true),
              maxLines: 2,
              onChanged: (v) {
                if (v.isNotEmpty) setState(() => _selected = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        // Skip still marks the staff member Absent — it only skips
        // attaching a reason (matches web's `onSkip` semantics: the
        // dialog only ever appears after the user already chose "A").
        TextButton(onPressed: () => Navigator.of(context).pop(''), child: const Text('Skip')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC2264E)),
          onPressed: () => Navigator.of(context).pop(_reason),
          child: Text(_shouldCountWithReason ? 'Mark Absent with Reason' : 'Mark Absent'),
        ),
      ],
    );
  }
}
