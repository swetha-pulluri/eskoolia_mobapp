import 'package:flutter/material.dart';
import '../../../domain/entities/attendance_entities.dart';

const List<String> kSchoolApprovedReasons = ['Bus delay', 'School event or trip', 'Medical appointment', 'Traffic / weather conditions', 'Other school-approved reason'];
const List<String> kUnapprovedReasons = ['Overslept', 'Personal errand', 'No reason provided'];

/// Late Comer Dialog — converted from web
/// `attendance/student/components/LateCommerDialog.tsx`.
class LateComerDialog extends StatefulWidget {
  final AttendanceStudentEntity student;
  final int minutesLate;
  final String initialMessage;
  final ValueChanged<String> onMarkLate;
  final ValueChanged<String> onSchoolApproved;
  final ValueChanged<String>? onMarkAbsent;
  final VoidCallback onSkip;

  const LateComerDialog({
    super.key,
    required this.student,
    required this.minutesLate,
    this.initialMessage = '',
    required this.onMarkLate,
    required this.onSchoolApproved,
    this.onMarkAbsent,
    required this.onSkip,
  });

  @override
  State<LateComerDialog> createState() => _LateComerDialogState();
}

class _LateComerDialogState extends State<LateComerDialog> {
  /// 'school_approved' | 'unapproved' | 'custom'
  String _kind = 'unapproved';
  String? _selectedLabel;
  late final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMessage;
    if (initial.toLowerCase().startsWith('school approved:')) {
      _kind = 'custom';
      _customController.text = initial.substring(initial.indexOf(':') + 1).trim();
    } else if (initial.isNotEmpty) {
      _kind = 'custom';
      _customController.text = initial;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool get _useCustom => _kind == 'custom';

  String get _finalText => _useCustom ? _customController.text.trim() : (_selectedLabel ?? '');

  bool get _canSubmit => _finalText.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSkip,
      child: Container(
        color: const Color(0x66000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: _body()),
              ),
              _footer(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final s = widget.student;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFFDF1DC), shape: BoxShape.circle), alignment: Alignment.center, child: const Icon(Icons.access_time, size: 12, color: Color(0xFFB4721B))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Late Arrival Detected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
            const SizedBox(height: 2),
            Text.rich(TextSpan(children: [
              TextSpan(text: s.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' arrived '),
              TextSpan(text: '${widget.minutesLate}', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' minute${widget.minutesLate == 1 ? "" : "s"} after class start. Pick a reason below — school-approved reasons keep the student marked Present.'),
            ]), style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B7B))),
          ]),
        ),
      ]),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SCHOOL-APPROVED (COUNTS AS PRESENT)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0A8C5A), letterSpacing: 0.3)),
        const SizedBox(height: 6),
        ...kSchoolApprovedReasons.map((r) => _reasonButton(r, kind: 'school_approved', selectedBg: const Color(0xFFE4F6ED), selectedBorder: const Color(0x800A8C5A), selectedFg: const Color(0xFF0A5C3A))),
        const SizedBox(height: 12),
        const Text('UNAPPROVED (COUNTS AS LATE)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB4721B), letterSpacing: 0.3)),
        const SizedBox(height: 6),
        ...kUnapprovedReasons.map((r) => _reasonButton(r, kind: 'unapproved', selectedBg: const Color(0xFFFDF1DC), selectedBorder: const Color(0x80B4721B), selectedFg: const Color(0xFF7A4A0F))),
        const SizedBox(height: 12),
        const Text('CUSTOM REASON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4729F4), letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextField(
          controller: _customController,
          onChanged: (v) => setState(() => _kind = 'custom'),
          onTap: () => setState(() => _kind = 'custom'),
          decoration: InputDecoration(
            hintText: 'Type a custom reason…',
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)),
            isDense: true,
            filled: true,
            fillColor: _useCustom ? const Color(0xFFF4F2FF) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _useCustom ? const Color(0xFF4729F4) : const Color(0xFFE6E6EC))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4729F4))),
          ),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _reasonButton(String label, {required String kind, required Color selectedBg, required Color selectedBorder, required Color selectedFg}) {
    final isSelected = _kind == kind && _selectedLabel == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => setState(() {
          _kind = kind;
          _selectedLabel = label;
          _customController.clear();
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : const Color(0xFFFAFAFD),
            border: Border.all(color: isSelected ? selectedBorder : const Color(0xFFE6E6EC)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? selectedFg : const Color(0xFF3A3A4A))),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFFAFAFD),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(onPressed: widget.onSkip, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Skip')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (_useCustom && widget.onMarkAbsent != null)
              Tooltip(
                message: 'Reject this custom reason and mark the student absent',
                child: ElevatedButton(
                  onPressed: _canSubmit ? () => widget.onMarkAbsent!(_finalText) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2264E), foregroundColor: Colors.white),
                  child: const Text('Mark Absent'),
                ),
              ),
            if (_useCustom)
              Tooltip(
                message: 'Approve this custom reason — student stays Present',
                child: ElevatedButton(
                  onPressed: _canSubmit ? () => widget.onSchoolApproved(_finalText) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8C5A), foregroundColor: Colors.white),
                  child: const Text('Approve as School-Approved'),
                ),
              ),
            ElevatedButton(
              onPressed: !_canSubmit
                  ? null
                  : _kind == 'school_approved'
                      ? () => widget.onSchoolApproved(_finalText)
                      : () => widget.onMarkLate(_finalText),
              style: ElevatedButton.styleFrom(backgroundColor: _kind == 'school_approved' ? const Color(0xFF0A8C5A) : const Color(0xFFB4721B), foregroundColor: Colors.white),
              child: Text(_kind == 'school_approved' ? 'Mark Present (Approved)' : 'Mark as Late'),
            ),
          ]),
        ],
      ),
    );
  }
}
