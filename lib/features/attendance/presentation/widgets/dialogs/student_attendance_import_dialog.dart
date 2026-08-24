import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/file_download_helper.dart';
import '../../../domain/entities/attendance_entities.dart';
import '../../providers/attendance_provider.dart';

/// Student Attendance Import Dialog — converted from web
/// `attendance/student/components/StudentAttendanceImportDialog.tsx`.
/// "Download Sample" and "Confirm Import" now call the real
/// `GET .../download-sample/` and `POST .../bulk-store/` endpoints.
class StudentAttendanceImportDialog extends ConsumerStatefulWidget {
  final bool open;
  final List<ClassInfoEntity> classes;
  final VoidCallback onClose;
  final void Function(String message, String tone) onNotify;
  final void Function({required int classId, required int sectionId, required String date, required int imported})? onImported;

  const StudentAttendanceImportDialog({super.key, required this.open, required this.classes, required this.onClose, required this.onNotify, this.onImported});

  @override
  ConsumerState<StudentAttendanceImportDialog> createState() => _StudentAttendanceImportDialogState();
}

class _StudentAttendanceImportDialogState extends ConsumerState<StudentAttendanceImportDialog> {
  int? _classId;
  int? _sectionId;
  late String _date = _todayIso();
  PlatformFile? _file;
  bool _saving = false;
  double _progress = 0;
  bool _confirmOpen = false;
  Map<String, String> _errors = {};

  static String _todayIso() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  List<SectionSummaryEntity> get _sections {
    if (_classId == null) return const [];
    final cls = widget.classes.where((c) => c.id == _classId).toList();
    return cls.isEmpty ? const [] : cls.first.sections;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx', 'xls'], withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.first;
        _errors.remove('file');
      });
    }
  }

  Future<void> _downloadSample() async {
    try {
      final bytes = await ref.read(attendanceRepositoryProvider).downloadSample();
      await saveBytesForDownload(bytes: bytes, filename: 'student_attendance_sheet.xlsx');
      widget.onNotify('Sample attendance template downloaded.', 'success');
    } catch (e) {
      widget.onNotify('Unable to download sample: $e', 'error');
    }
  }

  Map<String, String> _validate() {
    final errs = <String, String>{};
    if (_classId == null) errs['class'] = 'Please select a class';
    if (_sectionId == null) errs['section'] = 'Please select a section';
    if (_date.isEmpty) errs['date'] = 'Please select an attendance date';
    if (_file == null) errs['file'] = 'Please upload a file';
    return errs;
  }

  Future<void> _confirmImport() async {
    final file = _file;
    if (file == null || file.bytes == null || _classId == null || _sectionId == null) return;
    setState(() {
      _saving = true;
      _progress = 0.3;
    });
    try {
      final result = await ref.read(attendanceRepositoryProvider).bulkImport(
            classId: _classId!,
            sectionId: _sectionId!,
            attendanceDate: _date,
            fileBytes: file.bytes!,
            fileName: file.name,
          );
      if (!mounted) return;
      setState(() => _progress = 1);
      final data = (result['data'] as Map<String, dynamic>?) ?? const {};
      final imported = (data['imported'] as num?)?.toInt() ?? (result['imported_count'] as num?)?.toInt() ?? 0;
      final failed = (data['failed'] as num?)?.toInt() ?? (result['failed_count'] as num?)?.toInt() ?? 0;
      final success = result['success'] != false;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _progress = 0;
        _confirmOpen = false;
      });
      widget.onNotify(
        success
            ? (failed > 0 ? '$imported record(s) imported, $failed failed.' : 'Successfully imported $imported attendance record(s).')
            : (result['message'] as String? ?? 'Import failed.'),
        success ? 'success' : 'error',
      );
      if (success && imported > 0 && widget.onImported != null) {
        widget.onImported!(classId: _classId!, sectionId: _sectionId!, date: _date, imported: imported);
      }
      if (success) widget.onClose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _progress = 0;
      });
      widget.onNotify('Import failed: $e', 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();
    return Container(
      color: const Color(0x66000000),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Stack(children: [
        SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(),
              Padding(padding: const EdgeInsets.all(20), child: _form()),
              _footer(),
            ]),
          ),
        ),
        if (_confirmOpen) _confirmSubModal(),
      ]),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Import Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const Text('Upload a CSV or Excel file to bulk-import student attendance', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B80))),
          ]),
        ),
        InkWell(onTap: widget.onClose, borderRadius: BorderRadius.circular(8), child: Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close, size: 18, color: Color(0xFF6B6B80)))),
      ]),
    );
  }

  Widget _form() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _selectField(label: 'Select Class', required: true, error: _errors['class'], value: _classId?.toString(), hint: 'Select Class', items: widget.classes.map((c) => MapEntry('${c.id}', c.displayLabel)).toList(), onChanged: (v) => setState(() { _classId = v == null ? null : int.parse(v); _sectionId = null; _errors.remove('class'); }))),
        const SizedBox(width: 16),
        Expanded(child: _selectField(label: 'Select Section', required: true, error: _errors['section'], value: _sectionId?.toString(), hint: _classId == null ? 'Select class first' : 'Select Section', items: _sections.map((s) => MapEntry('${s.id}', 'Section ${s.name}')).toList(), onChanged: _classId == null ? null : (v) => setState(() { _sectionId = v == null ? null : int.parse(v); _errors.remove('section'); }))),
      ]),
      const SizedBox(height: 16),
      _labeled('Attendance Date', required: true, error: _errors['date'], child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(_date) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
          if (picked != null) setState(() { _date = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}'; _errors.remove('date'); });
        },
        child: InputDecorator(
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _errors.containsKey('date') ? const Color(0xFFDC2626) : const Color(0xFFE6E6EC)))),
          child: Text(_date, style: const TextStyle(fontSize: 13)),
        ),
      )),
      const Padding(padding: EdgeInsets.only(top: 4), child: Text('Format: DD-MM-YYYY', style: TextStyle(fontSize: 11, color: Color(0xFF6B6B80)))),
      const SizedBox(height: 16),
      Row(children: [
        Text.rich(TextSpan(children: const [TextSpan(text: 'Upload File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))), TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))])),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _downloadSample,
          icon: const Icon(Icons.download_outlined, size: 13),
          label: const Text('Download Sample (XLSX)'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A1A2E), side: const BorderSide(color: Color(0xFFE6E6EC)), backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 8),
      InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(color: _errors.containsKey('file') ? const Color(0xFFFEF2F2) : const Color(0xFFFAFAFD), border: Border.all(color: _errors.containsKey('file') ? const Color(0xFFDC2626) : const Color(0xFFE6E6EC), width: 2, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE6E6EC))), alignment: Alignment.center, child: const Icon(Icons.cloud_upload_outlined, size: 22, color: Color(0xFF4729F4))),
            const SizedBox(height: 10),
            Text(_file?.name ?? 'Drag & drop your file here', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text(_file != null ? '${_formatSize(_file!.size)} · CSV or Excel file' : 'or click to select (.csv, .xlsx, .xls, max 5MB)', style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B80))),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          if (_file != null) TextButton(onPressed: () => setState(() => _file = null), style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626), padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('Remove file', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          const Spacer(),
          const Text('Allowed: CSV/XLSX/XLS · Max 5MB', style: TextStyle(fontSize: 11, color: Color(0xFF6B6B80))),
        ]),
      ),
      if (_errors.containsKey('file')) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_errors['file']!, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
      if (_saving) ...[
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: _progress, minHeight: 6, backgroundColor: const Color(0xFFE6E6EC), color: const Color(0xFF4729F4))),
        const Padding(padding: EdgeInsets.only(top: 4), child: Text('Uploading…', style: TextStyle(fontSize: 11, color: Color(0xFF6B6B80)))),
      ],
    ]);
  }

  Widget _labeled(String label, {required Widget child, bool required = false, String? error}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(TextSpan(children: [TextSpan(text: label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))), if (required) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))])),
      const SizedBox(height: 4),
      child,
      if (error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(error, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
    ]);
  }

  Widget _selectField({required String label, required bool required, String? error, String? value, required String hint, required List<MapEntry<String, String>> items, ValueChanged<String?>? onChanged}) {
    final disabled = onChanged == null;
    return _labeled(
      label,
      required: required,
      error: error,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: disabled ? const Color(0xFFF5F5FA) : Colors.white, border: Border.all(color: error != null ? const Color(0xFFDC2626) : const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA0AE))),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
            items: items.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        OutlinedButton(onPressed: _saving ? null : widget.onClose, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Cancel')),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            final errs = _validate();
            if (errs.isNotEmpty) {
              setState(() => _errors = errs);
              return;
            }
            setState(() => _confirmOpen = true);
          },
          icon: Icon(_saving ? Icons.hourglass_empty : Icons.file_upload_outlined, size: 14),
          label: Text(_saving ? 'Importing…' : 'Import Attendance'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _confirmSubModal() {
    final clsName = _classId != null ? (widget.classes.where((c) => c.id == _classId).toList().isNotEmpty ? widget.classes.firstWhere((c) => c.id == _classId).displayLabel : '-') : '-';
    final secName = _sections.where((s) => s.id == _sectionId).toList().isNotEmpty ? 'Section ${_sections.firstWhere((s) => s.id == _sectionId).name}' : '-';
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _confirmOpen = false),
        child: Container(
          color: const Color(0x80000000),
          alignment: Alignment.center,
          // 16dp breathing room on narrow phones — every other modal in this
          // module pads its scrim the same way; this one didn't, so on a
          // 320dp-wide screen it rendered truly edge-to-edge (rounded
          // corners clipped flush against the screen edges).
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Confirm Attendance Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 4),
                    const Text('Review the details before importing.', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B80))),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    _reviewRow('Class', clsName),
                    _reviewRow('Section', secName),
                    _reviewRow('Date', _date),
                    _reviewRow('File', _file != null ? '${_file!.name} (${_formatSize(_file!.size)})' : '-'),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: () => setState(() => _confirmOpen = false), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _confirmImport, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white), child: const Text('Confirm Import')),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B80))),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
      ]),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
