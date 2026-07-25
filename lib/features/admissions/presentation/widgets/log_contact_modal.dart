import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../providers/admissions_provider.dart';
import 'enquiry_form_modal.dart' show kAdmIndigo;

const List<Map<String, String>> kLogOutcomes = [
  {'value': 'called_interested', 'label': 'Called - Interested'},
  {'value': 'called_no_answer', 'label': 'Called - No Answer'},
  {'value': 'called_callback', 'label': 'Called - Callback Requested'},
  {'value': 'called_not_interested', 'label': 'Called - Not Interested'},
  {'value': 'whatsapp_sent', 'label': 'WhatsApp Sent'},
  {'value': 'visit_scheduled', 'label': 'Campus Visit Scheduled'},
  {'value': 'visit_done', 'label': 'Campus Visit Done'},
  {'value': 'documents_collected', 'label': 'Documents Collected'},
  {'value': 'enrolled', 'label': 'Enrolled'},
];

String _statusForOutcome(String outcome, String fallbackStatus) {
  if (outcome == 'enrolled') return 'enrolled';
  if (outcome == 'called_not_interested') return 'declined';
  if (outcome == 'visit_done' || outcome == 'visit_scheduled') return 'visited';
  if (outcome.startsWith('called_') || outcome == 'whatsapp_sent') return 'contacted';
  return fallbackStatus;
}

/// Log Contact Update — converted from `AdmissionsCommandCenter.tsx`'s
/// "LOG MODAL". Records an outcome + optional note against an inquiry and
/// advances its stage/follow-up date accordingly.
class LogContactModal extends ConsumerStatefulWidget {
  final InquiryEntity inquiry;
  final String today;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final String? prefilledOutcome;
  final String? prefilledNote;

  const LogContactModal({
    super.key,
    required this.inquiry,
    required this.today,
    required this.onClose,
    required this.onSaved,
    this.prefilledOutcome,
    this.prefilledNote,
  });

  @override
  ConsumerState<LogContactModal> createState() => _LogContactModalState();
}

class _LogContactModalState extends ConsumerState<LogContactModal> {
  late String _outcome = widget.prefilledOutcome ?? '';
  late final _note = TextEditingController(text: widget.prefilledNote ?? '');
  late String _nextFollowUpDate = DateTime.parse(widget.today).add(const Duration(days: 2)).toIso8601String().substring(0, 10);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_outcome.isEmpty) {
      setState(() => _error = 'Please select an outcome.');
      return;
    }
    final outcomeLabel = kLogOutcomes.firstWhere((o) => o['value'] == _outcome)['label']!;
    final now = DateTime.now();
    final timestamp = '${now.day}/${now.month}/${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final logEntry = '[$timestamp] $outcomeLabel${_note.text.isNotEmpty ? ': ${_note.text}' : ''}';
    final newStatus = _statusForOutcome(_outcome, widget.inquiry.status);
    setState(() => _saving = true);
    try {
      await ref.read(admissionsRepositoryProvider).updateInquiry(widget.inquiry.id, (c) => c.copyWith(
            note: c.note.isNotEmpty ? '${c.note}\n$logEntry' : logEntry,
            followUpDate: widget.today,
            nextFollowUpDate: _nextFollowUpDate,
            status: newStatus,
            activeStatus: newStatus == 'enrolled' || newStatus == 'declined' ? 2 : 1,
          ));
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x80000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          // `Material` ancestor required — see `EnquiryFormModal`'s same fix.
          child: Material(
            type: MaterialType.transparency,
            child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: kAdmIndigo,
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Log Contact Update', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(widget.inquiry.fullName, style: const TextStyle(fontSize: 12, color: Color(0xD9FFFFFF))),
                      ]),
                    ),
                    IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Colors.white)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Outcome *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _outcome.isEmpty ? null : _outcome,
                      isExpanded: true,
                      hint: const Text('Select outcome...', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _error != null ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB))),
                      ),
                      items: kLogOutcomes.map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!, style: const TextStyle(fontSize: 12.5)))).toList(),
                      onChanged: (v) => setState(() {
                        _outcome = v ?? '';
                        _error = null;
                      }),
                    ),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
                    const SizedBox(height: 14),
                    const Text('Note (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'What was discussed?',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Next Follow-up Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _dateField(),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: [
                      _quickChip('+1 day', 1),
                      _quickChip('+2 days', 2),
                      _quickChip('+1 week', 7),
                      _quickChip('+2 weeks', 14),
                    ]),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                  child: Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: kAdmIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: Text(_saving ? 'Saving...' : 'Save Log'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(onPressed: widget.onClose, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('Cancel')),
                    ),
                  ]),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    return TextField(
      controller: TextEditingController(text: _nextFollowUpDate),
      readOnly: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 14),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(_nextFollowUpDate) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) setState(() => _nextFollowUpDate = picked.toIso8601String().substring(0, 10));
      },
    );
  }

  Widget _quickChip(String label, int days) {
    return OutlinedButton(
      onPressed: () => setState(() => _nextFollowUpDate = DateTime.parse(widget.today).add(Duration(days: days)).toIso8601String().substring(0, 10)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), minimumSize: Size.zero, textStyle: const TextStyle(fontSize: 11)),
      child: Text(label),
    );
  }
}
