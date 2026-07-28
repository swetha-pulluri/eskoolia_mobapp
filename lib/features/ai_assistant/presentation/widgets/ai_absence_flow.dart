import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../data/ai_assistant_remote_datasource.dart';
import '../providers/ai_assistant_providers.dart';
import 'ai_assistant_colors.dart';

class AiAbsenceStudentOption {
  final int id;
  final String name;
  final String className;
  final String sectionName;
  final String? admissionNo;

  const AiAbsenceStudentOption({required this.id, required this.name, required this.className, required this.sectionName, this.admissionNo});
}

const _absenceReasons = [
  (value: 'sick', label: '🤒 Sick / Unwell'),
  (value: 'appointment', label: '🏥 Medical Appointment'),
  (value: 'family', label: '👨‍👩‍👧 Family Emergency'),
  (value: 'travel', label: '✈️ Travel / Out of Town'),
  (value: 'other', label: '📝 Other'),
];

/// Mirrors frontend components/aibot/AbsenceFlow.tsx exactly: a two-step
/// (search → confirm) card that posts to the real chatbot-mark endpoint via
/// [AiAssistantRemoteDataSource.markAbsence].
class AiAbsenceFlow extends ConsumerStatefulWidget {
  final String? prefillName;
  final void Function(AiAbsenceMarkResult result) onComplete;
  final VoidCallback onCancel;

  const AiAbsenceFlow({super.key, this.prefillName, required this.onComplete, required this.onCancel});

  @override
  ConsumerState<AiAbsenceFlow> createState() => _AiAbsenceFlowState();
}

enum _Step { search, confirm, loading }

class _AiAbsenceFlowState extends ConsumerState<AiAbsenceFlow> {
  _Step _step = _Step.search;
  late final TextEditingController _searchCtrl;
  List<AiAbsenceStudentOption> _results = [];
  bool _searching = false;
  Timer? _debounce;
  AiAbsenceStudentOption? _selected;
  String _reason = 'sick';
  final TextEditingController _noteCtrl = TextEditingController();
  late DateTime _date;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.prefillName ?? '');
    _date = DateTime.now();
    if (_searchCtrl.text.trim().length >= 2) {
      _scheduleSearch(_searchCtrl.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _scheduleSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final page = await ref.read(studentRepositoryProvider).fetchStudentsFiltered(search: q, pageSize: 6);
      if (!mounted) return;
      setState(() {
        _results = page.results
            .map((s) => AiAbsenceStudentOption(id: s.id, name: s.fullName, className: s.className, sectionName: s.sectionName, admissionNo: s.admissionNo))
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() {
      _step = _Step.loading;
      _error = '';
    });
    final reasonEntry = _absenceReasons.firstWhere((r) => r.value == _reason, orElse: () => _absenceReasons.first);
    final reasonLabel = reasonEntry.label.replaceFirst(RegExp(r'^\S+ '), '');
    final note = _noteCtrl.text.trim();
    final notes = note.isNotEmpty ? '$reasonLabel — $note' : reasonLabel;
    final dateStr = '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    try {
      final result = await ref.read(aiAssistantRemoteDataSourceProvider).markAbsence(studentId: selected.id, notes: notes, attendanceDate: dateStr);
      if (!mounted) return;
      widget.onComplete(result);
    } on AiAbsenceMarkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _step = _Step.confirm;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error. Please try again.';
        _step = _Step.confirm;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(12), color: aiBg0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          if (_step == _Step.search) _searchBody(),
          if (_step == _Step.confirm && _selected != null) _confirmBody(),
          if (_step == _Step.loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Marking attendance…', style: TextStyle(fontSize: 12.5, color: aiInk3))),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(color: Color(0x0FDC2626), border: Border(bottom: BorderSide(color: aiBorder))),
      child: Row(
        children: [
          const Expanded(
            child: Text('🏥 Report Absence', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
          ),
          InkWell(
            onTap: widget.onCancel,
            child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 18, color: aiInk3)),
          ),
        ],
      ),
    );
  }

  Widget _searchBody() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Which student is absent today?', style: TextStyle(fontSize: 12, color: aiInk2)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: _scheduleSearch,
            decoration: InputDecoration(
              hintText: 'Type student name…',
              isDense: true,
              filled: true,
              fillColor: aiBg2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
            ),
            style: const TextStyle(fontSize: 12.5),
          ),
          if (_searching) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Searching…', style: TextStyle(fontSize: 11, color: aiInk3))),
          if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final s in _results) ...[
                        _studentOptionTile(s),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (!_searching && _searchCtrl.text.trim().length >= 2 && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(child: Text('No students found for "${_searchCtrl.text}"', style: const TextStyle(fontSize: 12, color: aiInk3))),
            ),
        ],
      ),
    );
  }

  Widget _studentOptionTile(AiAbsenceStudentOption s) {
    return InkWell(
      onTap: () => setState(() {
        _selected = s;
        _step = _Step.confirm;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(8), color: aiBg1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: aiInk1)),
            Text(
              [
                [s.className, s.sectionName].where((e) => e.isNotEmpty).join(' – '),
                if (s.admissionNo?.isNotEmpty ?? false) s.admissionNo!,
              ].where((e) => e.isNotEmpty).join(' · '),
              style: const TextStyle(fontSize: 11, color: aiInk3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmBody() {
    final s = _selected!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: aiBg2, borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: aiInk1)),
                Text([s.className, s.sectionName].where((e) => e.isNotEmpty).join(' – '), style: const TextStyle(fontSize: 11, color: aiInk3)),
              ],
            ),
          ),
          const Text('Reason', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: aiInk2)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(8), color: aiBg2),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _reason,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(fontSize: 12.5, color: aiInk1),
                items: [for (final r in _absenceReasons) DropdownMenuItem(value: r.value, child: Text(r.label))],
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Date', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: aiInk2)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(8), color: aiBg2),
              child: Text('${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12.5, color: aiInk1)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Additional note (optional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: aiInk2)),
          const SizedBox(height: 4),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: 'e.g., fever, will return tomorrow',
              isDense: true,
              filled: true,
              fillColor: aiBg2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
            ),
            style: const TextStyle(fontSize: 12.5),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error, style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626))),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _selected = null;
                    _step = _Step.search;
                    _error = '';
                  }),
                  style: OutlinedButton.styleFrom(foregroundColor: aiInk2, side: const BorderSide(color: aiBorder), padding: const EdgeInsets.symmetric(vertical: 7)),
                  child: const Text('← Back', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 7), elevation: 0),
                  child: const Text('✓ Mark Absent', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
