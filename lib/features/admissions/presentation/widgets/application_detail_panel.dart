import 'package:flutter/material.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../providers/admissions_local_data.dart';

const List<Map<String, String>> kRequiredDocs = [
  {'key': 'birth_cert', 'label': 'Birth Certificate'},
  {'key': 'tc', 'label': 'Transfer Certificate (TC)'},
  {'key': 'aadhar', 'label': 'Aadhar Card Copy'},
  {'key': 'photos', 'label': 'Passport Photos (4)'},
  {'key': 'report_card', 'label': 'Previous Report Card'},
  {'key': 'address_proof', 'label': 'Address Proof'},
];

const List<Map<String, String>> kDetailStageOptions = [
  {'value': 'new', 'label': 'New'},
  {'value': 'contacted', 'label': 'In Conversation'},
  {'value': 'visited', 'label': 'Decision Pending'},
  {'value': 'enrolled', 'label': 'Enrolled'},
  {'value': 'waitlisted', 'label': 'Waitlist'},
  {'value': 'declined', 'label': 'Cold / Dropped'},
];

const Map<String, Color> kDetailStageFg = {
  'new': Color(0xFF1D4ED8),
  'contacted': Color(0xFF4338CA),
  'visited': Color(0xFF92400E),
  'enrolled': Color(0xFF15803D),
  'waitlisted': Color(0xFF6D28D9),
  'declined': Color(0xFF6B7280),
};
const Map<String, Color> kDetailStageBg = {
  'new': Color(0xFFDBEAFE),
  'contacted': Color(0xFFE0E7FF),
  'visited': Color(0xFFFEF3C7),
  'enrolled': Color(0xFFDCFCE7),
  'waitlisted': Color(0xFFF3E8FF),
  'declined': Color(0xFFF3F4F6),
};
const Map<String, String> kDetailStageLabel = {
  'new': 'New',
  'contacted': 'In Conversation',
  'visited': 'Decision Pending',
  'enrolled': 'Enrolled',
  'waitlisted': 'Waitlist',
  'declined': 'Cold / Dropped',
};

Map<String, String> _parseDocStatus(String raw) {
  if (raw.isEmpty) return {};
  final result = <String, String>{};
  for (final part in raw.split(',')) {
    final kv = part.split(':');
    if (kv.length == 2 && kv[0].trim().isNotEmpty) {
      result[kv[0].trim()] = kv[1].trim();
    }
  }
  return result;
}

String _formatLongDate(String? v) {
  if (v == null) return '–';
  final d = DateTime.tryParse(v);
  if (d == null) return v;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Application Detail Panel — full-width slide-in panel opened from any
/// row in the Class Workspace table. Converted from web
/// `command-center/ApplicationDetailPanel.tsx`. Mutations go straight to
/// `AdmissionsLocalData` (no backend), matching this module's architecture.
class ApplicationDetailPanel extends StatefulWidget {
  final InquiryEntity? inquiry;
  final bool isOpen;
  final VoidCallback onClose;
  final ValueChanged<InquiryEntity> onOpenLog;
  final ValueChanged<InquiryEntity> onOpenCall;
  final ValueChanged<InquiryEntity> onOpenWA;
  final ValueChanged<InquiryEntity> onEdit;
  final String today;
  final VoidCallback onReload;

  const ApplicationDetailPanel({
    super.key,
    required this.inquiry,
    required this.isOpen,
    required this.onClose,
    required this.onOpenLog,
    required this.onOpenCall,
    required this.onOpenWA,
    required this.onEdit,
    required this.today,
    required this.onReload,
  });

  @override
  State<ApplicationDetailPanel> createState() => _ApplicationDetailPanelState();
}

class _ApplicationDetailPanelState extends State<ApplicationDetailPanel> {
  final _noteController = TextEditingController();
  bool _noteSaving = false;
  String? _localStatus;
  Map<String, String> _localDocStatus = {};
  String? _docSavingKey;
  String _localNotes = '';
  int? _lastInquiryId;

  @override
  void didUpdateWidget(ApplicationDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final inq = widget.inquiry;
    if (inq != null && inq.id != _lastInquiryId) {
      _lastInquiryId = inq.id;
      _noteController.clear();
      _localStatus = null;
      _localNotes = inq.note;
      _localDocStatus = _parseDocStatus(inq.documentsStatus);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleStageChange(String status) async {
    final inq = widget.inquiry;
    if (inq == null) return;
    setState(() => _localStatus = status);
    await AdmissionsLocalData.updateInquiry(inq.id, (current) => current.copyWith(
          status: status,
          activeStatus: status == 'enrolled' || status == 'declined' ? 2 : 1,
          followUpDate: widget.today,
        ));
    widget.onReload();
  }

  Future<void> _handleDocToggle(String docKey) async {
    final inq = widget.inquiry;
    if (inq == null) return;
    final current = _localDocStatus[docKey];
    final next = current == 'received' ? 'missing' : current == 'missing' ? '' : 'received';
    final updated = Map<String, String>.from(_localDocStatus);
    if (next.isEmpty) {
      updated.remove(docKey);
    } else {
      updated[docKey] = next;
    }
    setState(() {
      _localDocStatus = updated;
      _docSavingKey = docKey;
    });
    final serialized = updated.entries.map((e) => '${e.key}:${e.value}').join(',');
    await AdmissionsLocalData.updateInquiry(inq.id, (c) => c.copyWith(documentsStatus: serialized));
    if (mounted) setState(() => _docSavingKey = null);
    widget.onReload();
  }

  Future<void> _saveNote() async {
    final inq = widget.inquiry;
    final text = _noteController.text.trim();
    if (inq == null || text.isEmpty) return;
    setState(() => _noteSaving = true);
    final now = DateTime.now();
    final timestamp = '${now.day}/${now.month}/${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final entry = '[$timestamp] $text';
    final updated = _localNotes.isNotEmpty ? '$_localNotes\n$entry' : entry;
    await AdmissionsLocalData.updateInquiry(inq.id, (c) => c.copyWith(note: updated));
    if (mounted) {
      setState(() {
        _localNotes = updated;
        _noteController.clear();
        _noteSaving = false;
      });
    }
    widget.onReload();
  }

  @override
  Widget build(BuildContext context) {
    final inq = widget.inquiry;
    if (!widget.isOpen || inq == null) return const SizedBox.shrink();

    final displayStatus = _localStatus ?? inq.status;
    final activityLines = _localNotes.split('\n').where((l) => l.isNotEmpty).toList().reversed.toList();

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x4D000000),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480),
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(inq.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: kDetailStageBg[displayStatus] ?? const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
                                      child: Text(kDetailStageLabel[displayStatus] ?? displayStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kDetailStageFg[displayStatus] ?? const Color(0xFF4B5563))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(spacing: 12, children: [
                                  if (inq.classNameResolved != null) Text('📚 ${inq.classNameResolved}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                  if (inq.assigned.isNotEmpty) Text('👤 ${inq.assigned}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                ]),
                              ],
                            ),
                          ),
                          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick actions
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _stageDropdownButton(displayStatus),
                                  _outlineActionChip('Log', Icons.access_time, const Color(0xFF374151), const Color(0xFFE5E7EB), () => widget.onOpenLog(inq)),
                                  if (inq.phone.isNotEmpty) ...[
                                    _outlineActionChip('Call', Icons.call_outlined, const Color(0xFF15803D), const Color(0xFFBBF7D0), () => widget.onOpenCall(inq)),
                                    _outlineActionChip('WhatsApp', Icons.chat_bubble_outline, const Color(0xFF15803D), const Color(0xFFBBF7D0), () => widget.onOpenWA(inq)),
                                  ],
                                  _outlineActionChip('Edit', Icons.edit_outlined, const Color(0xFF4338CA), const Color(0xFFC7D2FE), () => widget.onEdit(inq)),
                                ],
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF9FAFB))),

                            // Details
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DETAILS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.4)),
                                  const SizedBox(height: 8),
                                  if (inq.phone.isNotEmpty) _detailRow('Phone', inq.phone),
                                  if (inq.email.isNotEmpty) _detailRow('Email', inq.email),
                                  if ((inq.sourceName ?? '').isNotEmpty) _detailRow('Source', inq.sourceName!),
                                  if (inq.queryDate != null) _detailRow('Inquiry', _formatLongDate(inq.queryDate)),
                                  if (inq.nextFollowUpDate != null)
                                    _detailRow(
                                      'Follow-up',
                                      '${_formatLongDate(inq.nextFollowUpDate)}${inq.nextFollowUpDate!.compareTo(widget.today) < 0 ? ' (overdue)' : ''}',
                                      valueColor: inq.nextFollowUpDate!.compareTo(widget.today) < 0 ? const Color(0xFFDC2626) : const Color(0xFF1F2937),
                                    ),
                                  if (inq.leadScore >= 40)
                                    _detailRow('Score', '${inq.leadScore >= 70 ? "🔥" : "🟡"} ${inq.leadScore}', valueColor: inq.leadScore >= 70 ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                                  if (inq.description.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(8),
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                                      child: Text(inq.description, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4)),
                                    ),
                                ],
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF9FAFB))),

                            // Documents
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text.rich(TextSpan(children: [
                                    TextSpan(text: 'DOCUMENTS ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.4)),
                                    TextSpan(text: '(tap to toggle)', style: TextStyle(fontSize: 9.5, color: Color(0xFF9CA3AF))),
                                  ])),
                                  const SizedBox(height: 8),
                                  ...kRequiredDocs.map((d) => _docRow(d['key']!, d['label']!)),
                                ],
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF9FAFB))),

                            // Activity log
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ACTIVITY LOG', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.4)),
                                  const SizedBox(height: 8),
                                  if (activityLines.isEmpty)
                                    const Text('No activity logged yet.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic))
                                  else
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 192),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: activityLines
                                              .map((line) => Container(
                                                    width: double.infinity,
                                                    margin: const EdgeInsets.only(bottom: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                                                    child: Text(line, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4)),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Add note
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ADD NOTE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.4)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _noteController,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
                                    decoration: InputDecoration(
                                      hintText: 'Type a quick note…',
                                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _noteController.text.trim().isEmpty || _noteSaving ? null : _saveNote,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    child: Text(_noteSaving ? 'Saving…' : 'Save Note'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stageDropdownButton(String displayStatus) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 34),
      itemBuilder: (context) => kDetailStageOptions.map((s) {
        final isCurrent = displayStatus == s['value'];
        return PopupMenuItem<String>(
          value: s['value'],
          height: 36,
          child: Text(s['label']!, style: TextStyle(fontSize: 12.5, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal, color: isCurrent ? const Color(0xFF4F46E5) : const Color(0xFF374151))),
        );
      }).toList(),
      onSelected: _handleStageChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Move Stage', style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 13, color: Color(0xFF374151)),
        ]),
      ),
    );
  }

  Widget _outlineActionChip(String label, IconData icon, Color fg, Color border, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color valueColor = const Color(0xFF1F2937)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: valueColor))),
        ],
      ),
    );
  }

  Widget _docRow(String key, String label) {
    final status = _localDocStatus[key];
    final isReceived = status == 'yes' || status == 'received';
    final isMissing = status == 'no' || status == 'missing';
    final isSaving = _docSavingKey == key;
    final bg = isReceived ? const Color(0xFFF0FDF4) : isMissing ? const Color(0xFFFEF2F2) : Colors.transparent;
    final fg = isReceived ? const Color(0xFF166534) : isMissing ? const Color(0xFFB91C1C) : const Color(0xFF374151);
    final icon = isReceived ? Icons.check_circle : isMissing ? Icons.cancel : Icons.radio_button_unchecked;
    final iconColor = isReceived ? const Color(0xFF22C55E) : isMissing ? const Color(0xFFF87171) : const Color(0xFFD1D5DB);
    return InkWell(
      onTap: isSaving ? null : () => _handleDocToggle(key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Opacity(
          opacity: isSaving ? 0.5 : 1,
          child: Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: fg))),
              Text(
                isReceived ? '✓ Received' : isMissing ? '✗ Missing' : 'Pending',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isReceived ? const Color(0xFF16A34A) : isMissing ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
