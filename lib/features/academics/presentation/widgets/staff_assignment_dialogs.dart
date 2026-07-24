// Staff Assignment modals — ports of CTChangeModal and BulkAssignModal from
// components/academics/StaffAssignmentPanels.tsx.

import 'package:flutter/material.dart';

import '../../domain/entities/class_entity.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/entities/staff_assignment_entities.dart';

InputDecoration _staffFieldDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF9FAFB), // bg-gray-50
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: staffBrand)),
  );
}

Widget _staffFieldLabel(String text, {bool required = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.3),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444))),
        ],
      ),
    ),
  );
}

Widget _modalHeader({required Widget leading, required String title, required VoidCallback onClose}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      leading,
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
      InkWell(onTap: onClose, child: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF))),
    ]),
  );
}

Widget _modalFooter(List<Widget> actions) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
  );
}

Widget _spinner({Color color = Colors.white, double size = 14}) {
  return SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 2, color: color));
}

/// Port of CTChangeModal — used to change (and re-lock) a section's class teacher.
Future<void> showStaffCTChangeDialog({
  required BuildContext context,
  required String currentTeacherName,
  required List<StaffTeacher> teachers,
  required Future<void> Function(int newTeacherId, String reason) onConfirm,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _StaffCTChangeDialog(currentTeacherName: currentTeacherName, teachers: teachers, onConfirm: onConfirm),
  );
}

class _StaffCTChangeDialog extends StatefulWidget {
  final String currentTeacherName;
  final List<StaffTeacher> teachers;
  final Future<void> Function(int newTeacherId, String reason) onConfirm;
  const _StaffCTChangeDialog({required this.currentTeacherName, required this.teachers, required this.onConfirm});

  @override
  State<_StaffCTChangeDialog> createState() => _StaffCTChangeDialogState();
}

class _StaffCTChangeDialogState extends State<_StaffCTChangeDialog> {
  int? _newId;
  final _reasonController = TextEditingController();
  String _err = '';
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _err = 'Please enter a reason to continue.');
      return;
    }
    if (_newId == null) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirm(_newId!, _reasonController.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _modalHeader(
            leading: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFDE68A))),
              child: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFFD97706)),
            ),
            title: 'Change Class Teacher',
            onClose: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Current: ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    TextSpan(text: widget.currentTeacherName.isEmpty ? '—' : widget.currentTeacherName, style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w700, fontSize: 13)),
                  ])),
                ),
                const SizedBox(height: 12),
                _staffFieldLabel('New Teacher', required: true),
                DropdownButtonFormField<int>(
                  initialValue: _newId,
                  isExpanded: true,
                  decoration: _staffFieldDecoration(hint: 'Select teacher…'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                  items: widget.teachers
                      .map((t) => DropdownMenuItem(value: t.id, child: Text('${t.fullName}${t.designation.isNotEmpty ? ' (${t.designation})' : ''}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _newId = v),
                ),
                const SizedBox(height: 12),
                _staffFieldLabel('Reason for Change', required: true),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  onChanged: (v) {
                    if (v.trim().isNotEmpty && _err.isNotEmpty) setState(() => _err = '');
                  },
                  decoration: _staffFieldDecoration(hint: 'Enter reason for changing class teacher…'),
                ),
                if (_err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_err, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
              ],
            ),
          ),
          _modalFooter([
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4B5563), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (_saving || _newId == null) ? null : _confirm,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0, disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_saving) ...[_spinner(), const SizedBox(width: 8)],
                const Text('Confirm Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Port of BulkAssignModal — assigns one teacher as CT to a section or a whole class.
Future<void> showStaffBulkAssignDialog({
  required BuildContext context,
  required List<StaffTeacher> teachers,
  required List<FoundationClass> classes,
  required List<FoundationSection> sections,
  required Future<void> Function(int classId, int? sectionId, int teacherId, bool bulkClass) onConfirm,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _StaffBulkAssignDialog(teachers: teachers, classes: classes, sections: sections, onConfirm: onConfirm),
  );
}

class _StaffBulkAssignDialog extends StatefulWidget {
  final List<StaffTeacher> teachers;
  final List<FoundationClass> classes;
  final List<FoundationSection> sections;
  final Future<void> Function(int classId, int? sectionId, int teacherId, bool bulkClass) onConfirm;
  const _StaffBulkAssignDialog({required this.teachers, required this.classes, required this.sections, required this.onConfirm});

  @override
  State<_StaffBulkAssignDialog> createState() => _StaffBulkAssignDialogState();
}

class _StaffBulkAssignDialogState extends State<_StaffBulkAssignDialog> {
  int? _classId;
  int? _sectionId;
  int? _teacherId;
  bool _bulk = false;
  bool _saving = false;

  List<FoundationSection> get _filteredSections => widget.sections.where((s) => s.classId == _classId).toList();

  Future<void> _confirm() async {
    if (_teacherId == null || _classId == null) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirm(_classId!, _bulk ? null : _sectionId, _teacherId!, _bulk);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _teacherId != null && _classId != null && (_bulk || _sectionId != null);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _modalHeader(leading: const Icon(Icons.bolt, size: 18, color: staffBrand), title: 'Bulk Assign Class Teacher', onClose: () => Navigator.of(context).pop()),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _staffFieldLabel('Teacher', required: true),
                DropdownButtonFormField<int>(
                  initialValue: _teacherId,
                  isExpanded: true,
                  decoration: _staffFieldDecoration(hint: 'Select teacher…'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                  items: widget.teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _teacherId = v),
                ),
                const SizedBox(height: 12),
                _staffFieldLabel('Class', required: true),
                DropdownButtonFormField<int>(
                  initialValue: _classId,
                  isExpanded: true,
                  decoration: _staffFieldDecoration(hint: 'Select class…'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                  items: widget.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() {
                    _classId = v;
                    _sectionId = null;
                  }),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _bulk = !_bulk),
                  child: Row(children: [
                    Checkbox(value: _bulk, onChanged: (v) => setState(() => _bulk = v ?? false), activeColor: staffBrand, visualDensity: VisualDensity.compact),
                    const Flexible(child: Text('Assign to all sections of this class', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
                  ]),
                ),
                if (!_bulk && _classId != null) ...[
                  const SizedBox(height: 12),
                  _staffFieldLabel('Section'),
                  DropdownButtonFormField<int>(
                    initialValue: _sectionId,
                    isExpanded: true,
                    decoration: _staffFieldDecoration(hint: 'Select section…'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                    items: _filteredSections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _sectionId = v),
                  ),
                ],
              ],
            ),
          ),
          _modalFooter([
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4B5563), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (_saving || !canConfirm) ? null : _confirm,
              style: ElevatedButton.styleFrom(backgroundColor: staffBrand, foregroundColor: Colors.white, elevation: 0, disabledBackgroundColor: staffBrand.withValues(alpha: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_saving) ...[_spinner(), const SizedBox(width: 8)],
                const Text('Assign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}
