import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/entities/message_template_entity.dart';

const Color kMarketingBlue = Color(0xFF1D4ED8);

/// Edit Campaign — converted from web's `CampaignEditModal`. Web's own
/// Save button is a no-op (`onClick={() => { onClose(); }}` — it never
/// writes the edited name back to the campaign), so this is faithfully
/// reproduced as a close-only Save here too.
class CampaignEditModal extends StatefulWidget {
  final CampaignEntity campaign;
  final VoidCallback onClose;
  const CampaignEditModal({super.key, required this.campaign, required this.onClose});

  @override
  State<CampaignEditModal> createState() => _CampaignEditModalState();
}

class _CampaignEditModalState extends State<CampaignEditModal> {
  late final _name = TextEditingController(text: widget.campaign.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Edit Campaign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF))),
              ]),
              const SizedBox(height: 6),
              _labeled('Campaign Name', TextField(controller: _name, decoration: _dec())),
              const SizedBox(height: 14),
              _labeled('Channel', TextField(controller: TextEditingController(text: widget.campaign.channel), readOnly: true, decoration: _dec(readOnly: true))),
              const SizedBox(height: 14),
              _labeled('Audience', TextField(controller: TextEditingController(text: widget.campaign.audience), readOnly: true, decoration: _dec(readOnly: true))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: widget.onClose, child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white),
                    child: const Text('Save Changes'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget field) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 4),
      field,
    ]);
  }

  InputDecoration _dec({bool readOnly = false}) {
    return InputDecoration(
      isDense: true,
      filled: readOnly,
      fillColor: readOnly ? const Color(0xFFF9FAFB) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? const Color(0xFFF3F4F6) : const Color(0xFFE5E7EB))),
    );
  }
}

/// Template Preview — converted from web's `TemplatePreviewModal`. Shows
/// the template body inside a WhatsApp-style green bubble for `whatsapp`
/// templates, or a plain email card (with subject line) for `email`.
class TemplatePreviewModal extends StatefulWidget {
  final MessageTemplateEntity template;
  final VoidCallback onClose;
  const TemplatePreviewModal({super.key, required this.template, required this.onClose});

  @override
  State<TemplatePreviewModal> createState() => _TemplatePreviewModalState();
}

class _TemplatePreviewModalState extends State<TemplatePreviewModal> {
  bool _copied = false;

  List<InlineSpan> _highlightVars(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\{[^}]+\})');
    var last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(backgroundColor: Color(0xFFDBEAFE), color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500, fontSize: 12),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x80000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 4),
                      Row(children: [
                        _chip(t.channel, t.channel == 'whatsapp' ? const Color(0xFFDCFCE7) : t.channel == 'email' ? const Color(0xFFDBEAFE) : const Color(0xFFFEF9C3), t.channel == 'whatsapp' ? const Color(0xFF15803D) : t.channel == 'email' ? const Color(0xFF1D4ED8) : const Color(0xFFA16207)),
                        const SizedBox(width: 6),
                        _chip(t.category, const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
                      ]),
                    ]),
                  ),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF))),
                ]),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (t.channel == 'whatsapp')
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFF128C7E), borderRadius: BorderRadius.circular(14)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFECE5DD), borderRadius: BorderRadius.circular(12)),
                          child: Text.rich(TextSpan(children: _highlightVars(t.body), style: const TextStyle(fontSize: 12.5, color: Color(0xFF1F2937), height: 1.5))),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (t.subject != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                              child: Text.rich(TextSpan(children: [
                                const TextSpan(text: 'Subject: ', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                TextSpan(text: t.subject, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                              ])),
                            ),
                          Padding(padding: const EdgeInsets.all(12), child: Text.rich(TextSpan(children: _highlightVars(t.body), style: const TextStyle(fontSize: 12.5, color: Color(0xFF1F2937), height: 1.5)))),
                        ]),
                      ),
                    const SizedBox(height: 10),
                    Text('💡 Use case: ${t.useCase}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
                  ]),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: t.body));
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _copied = false);
                        });
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: _copied ? const Color(0xFF15803D) : const Color(0xFF4B5563), side: BorderSide(color: _copied ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB))),
                      child: Text(_copied ? '✓ Copied!' : '📋 Copy Text'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white),
                      child: const Text('Close'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

const List<String> kCampaignChannelOptions = ['WhatsApp', 'Email', 'WhatsApp + Email', 'SMS'];
const List<String> kCampaignAudienceOptions = [
  'All active inquiries',
  'All active inquiries (Grade 1–5)',
  'Cold leads (10+ days no contact)',
  'Post-visit (not yet enrolled)',
  'All enrolled families',
  'Custom filter',
];

/// New Campaign — converted from web's "NEW CAMPAIGN MODAL" +
/// `NewCampaignForm`. Draft if no schedule date is set, else Scheduled.
class NewCampaignModal extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<CampaignEntity> onSave;
  final int nextId;
  const NewCampaignModal({super.key, required this.onClose, required this.onSave, required this.nextId});

  @override
  State<NewCampaignModal> createState() => _NewCampaignModalState();
}

class _NewCampaignModalState extends State<NewCampaignModal> {
  final _name = TextEditingController();
  String _channel = 'WhatsApp';
  String _audience = 'All active inquiries';
  DateTime? _scheduledFor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() => _scheduledFor = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    final scheduled = _scheduledFor;
    widget.onSave(CampaignEntity(
      id: 'c${widget.nextId}',
      name: _name.text.trim(),
      channel: _channel,
      audience: _audience,
      status: scheduled != null ? 'scheduled' : 'draft',
      sentCount: 0,
      scheduledFor: scheduled != null ? _formatScheduled(scheduled) : null,
    ));
  }

  String _formatScheduled(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${hour12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('New Campaign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
                ]),
                const SizedBox(height: 6),
                _labeled('Campaign Name', TextField(controller: _name, decoration: _dec(hint: 'e.g. Open House May 2026'))),
                const SizedBox(height: 14),
                _labeled('Channel', _dropdown(_channel, kCampaignChannelOptions, (v) => setState(() => _channel = v!))),
                const SizedBox(height: 14),
                _labeled('Audience', _dropdown(_audience, kCampaignAudienceOptions, (v) => setState(() => _audience = v!))),
                const SizedBox(height: 14),
                _labeled(
                  'Schedule Date & Time',
                  InkWell(
                    onTap: _pickSchedule,
                    child: InputDecorator(
                      decoration: _dec(),
                      child: Text(_scheduledFor == null ? 'Tap to pick a date & time' : _formatScheduled(_scheduledFor!), style: TextStyle(fontSize: 13, color: _scheduledFor == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827))),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(onPressed: widget.onClose, child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white),
                    child: Text(_scheduledFor != null ? 'Schedule Campaign' : 'Save Draft'),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget field) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
      const SizedBox(height: 4),
      field,
    ]);
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _dec(),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _dec({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    );
  }
}
