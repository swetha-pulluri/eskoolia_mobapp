import 'package:flutter/material.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/entities/marketing_event_entity.dart';
import 'campaign_modals.dart' show kMarketingBlue;

/// New Event — there is no "Create Event" form on the real web
/// `AdmissionsMarketing.tsx` (its "New Event" button has no onClick at
/// all), so this has no web source to convert from. Modelled after the
/// same local-only-mock pattern as `NewCampaignModal`/`CampaignEditModal`
/// in this module: a real, working form, but purely in-memory (lost on
/// refresh) since there is no backend Event model to persist to.
class NewEventModal extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<MarketingEventEntity> onSave;
  final int nextId;
  const NewEventModal({super.key, required this.onClose, required this.onSave, required this.nextId});

  @override
  State<NewEventModal> createState() => _NewEventModalState();
}

class _NewEventModalState extends State<NewEventModal> {
  final _name = TextEditingController();
  final _capacity = TextEditingController(text: '40');
  DateTime? _dateTime;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _save() {
    final name = _name.text.trim();
    final capacity = int.tryParse(_capacity.text.trim());
    if (name.isEmpty || _dateTime == null || capacity == null || capacity < 1 || capacity > 500) {
      setState(() => _error = name.isEmpty
          ? 'Event name is required.'
          : _dateTime == null
              ? 'Pick a date & time.'
              : 'Capacity must be between 1 and 500.');
      return;
    }
    widget.onSave(MarketingEventEntity(
      id: 'e${widget.nextId}',
      name: name,
      date: _formatDate(_dateTime!),
      time: _formatTime(_dateTime!),
      rsvp: 0,
      capacity: capacity,
    ));
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
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('New Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                    IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
                  ]),
                  const SizedBox(height: 6),
                  _labeled('Event Name', TextField(controller: _name, decoration: _dec(hint: 'e.g. Open House'))),
                  const SizedBox(height: 14),
                  _labeled(
                    'Date & Time',
                    InkWell(
                      onTap: _pickDateTime,
                      child: InputDecorator(
                        decoration: _dec(),
                        child: Text(
                          _dateTime == null ? 'Tap to pick a date & time' : '${_formatDate(_dateTime!)}, ${_formatTime(_dateTime!)}',
                          style: TextStyle(fontSize: 13, color: _dateTime == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _labeled('Capacity', TextField(controller: _capacity, keyboardType: TextInputType.number, decoration: _dec(hint: 'e.g. 40'))),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                  ],
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: widget.onClose, child: const Text('Cancel')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white),
                      child: const Text('Create Event'),
                    ),
                  ]),
                ]),
              ),
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

/// Manage RSVPs — no such sub-view exists on the real web app (its "Manage
/// RSVPs" button has no onClick at all, and there is no backend RSVP model
/// to list real invitee names from). This mock version edits the local
/// confirmed-RSVP count only — the same "local numeric total" pattern
/// already used by Command Center's real "Edit Seats" dialog — rather than
/// fabricating a fake list of attendee names that don't exist anywhere.
class ManageRsvpsModal extends StatefulWidget {
  final MarketingEventEntity event;
  final VoidCallback onClose;
  final ValueChanged<int> onSave;
  const ManageRsvpsModal({super.key, required this.event, required this.onClose, required this.onSave});

  @override
  State<ManageRsvpsModal> createState() => _ManageRsvpsModalState();
}

class _ManageRsvpsModalState extends State<ManageRsvpsModal> {
  late int _rsvp = widget.event.rsvp;

  void _adjust(int delta) {
    setState(() => _rsvp = (_rsvp + delta).clamp(0, widget.event.capacity));
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    final ratio = ev.capacity == 0 ? 0.0 : _rsvp / ev.capacity;
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
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Manage RSVPs — ${ev.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
                ]),
                const SizedBox(height: 2),
                Text('📅 ${ev.date} · ⏰ ${ev.time}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 18),
                Text('Confirmed RSVPs', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(onPressed: _rsvp > 0 ? () => _adjust(-1) : null, icon: const Icon(Icons.remove_circle_outline)),
                  SizedBox(
                    width: 90,
                    child: Text('$_rsvp / ${ev.capacity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  ),
                  IconButton(onPressed: _rsvp < ev.capacity ? () => _adjust(1) : null, icon: const Icon(Icons.add_circle_outline)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: const Color(0xFFF3F4F6), color: const Color(0xFF0EA5E9))),
                const SizedBox(height: 6),
                Text('${(ev.capacity - _rsvp).clamp(0, ev.capacity)} seats remaining', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(onPressed: widget.onClose, child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => widget.onSave(_rsvp),
                    style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white),
                    child: const Text('Save'),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// View Report — no such sub-view exists on the real web app (its "View
/// Report" button has no onClick at all). This mock version presents the
/// same metrics already shown inline on the campaign card (sent count,
/// delivered %, replies) in a dedicated read-only view — it doesn't
/// fabricate any figure that isn't already a real field on `CampaignEntity`.
class CampaignReportModal extends StatelessWidget {
  final CampaignEntity campaign;
  final VoidCallback onClose;
  const CampaignReportModal({super.key, required this.campaign, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return GestureDetector(
      onTap: onClose,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Report — ${c.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280))),
                ]),
                Text('${c.channel} · ${c.audience}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                if (c.sentAt != null) Text('Sent ${c.sentAt}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _stat('${c.sentCount}', 'Recipients')),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('${c.deliveredPct ?? 0}%', 'Delivered')),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('${c.replies ?? 0}', 'Replies')),
                ]),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white),
                    child: const Text('Close'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ]),
    );
  }
}
