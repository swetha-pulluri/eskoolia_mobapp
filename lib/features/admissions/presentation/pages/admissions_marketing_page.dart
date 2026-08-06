import 'package:flutter/material.dart';
import '../../domain/entities/campaign_entity.dart';
import '../../domain/entities/message_template_entity.dart';
import '../../domain/entities/marketing_event_entity.dart';
import '../providers/admissions_local_data.dart';
import '../widgets/admissions_layout.dart';
import '../widgets/campaign_modals.dart';
import '../widgets/event_modals.dart';

const Map<String, ({Color color, String emoji})> kCategoryStyles = {
  'Welcome': (color: Color(0xFF3B82F6), emoji: '👋'),
  'Follow-up': (color: Color(0xFF14B8A6), emoji: '📞'),
  'Visit': (color: Color(0xFFF59E0B), emoji: '🏫'),
  'Urgency': (color: Color(0xFFEF4444), emoji: '🔥'),
  'Offer': (color: Color(0xFF8B5CF6), emoji: '🎁'),
  'Enrollment': (color: Color(0xFF22C55E), emoji: '🎉'),
  'Re-engagement': (color: Color(0xFF6366F1), emoji: '💙'),
  'Event': (color: Color(0xFFEC4899), emoji: '🌟'),
  'Post-Visit': (color: Color(0xFFF59E0B), emoji: '🤝'),
  'Nurture': (color: Color(0xFF0EA5E9), emoji: '🌱'),
  'Save': (color: Color(0xFFEF4444), emoji: '💔'),
  'Referral': (color: Color(0xFF10B981), emoji: '🎯'),
};

/// Admissions Marketing — converted from `AdmissionsMarketing.tsx`. Zero
/// API calls on web (verified by reading the full source) — campaigns,
/// templates, and events are all local/mock state there too, reproduced
/// verbatim via `AdmissionsLocalData` per that file's architecture notes.
class AdmissionsMarketingPage extends StatefulWidget {
  const AdmissionsMarketingPage({super.key});

  @override
  State<AdmissionsMarketingPage> createState() => _AdmissionsMarketingPageState();
}

class _AdmissionsMarketingPageState extends State<AdmissionsMarketingPage> {
  String _templateTab = 'whatsapp';
  String _searchQ = '';
  int _nextCampaignId = 100;
  int _nextEventId = 100;

  List<MessageTemplateEntity> get _filteredTemplates => AdmissionsLocalData.templates.where((t) {
        if (t.channel != _templateTab) return false;
        if (_searchQ.isEmpty) return true;
        final q = _searchQ.toLowerCase();
        return t.name.toLowerCase().contains(q) || t.category.toLowerCase().contains(q);
      }).toList();

  void _openNewCampaign() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'New Campaign',
      pageBuilder: (dialogContext, a1, a2) => NewCampaignModal(
        nextId: _nextCampaignId++,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onSave: (camp) {
          Navigator.of(dialogContext).maybePop();
          setState(() => AdmissionsLocalData.campaigns.insert(0, camp));
        },
      ),
    );
  }

  void _editCampaign(CampaignEntity c) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'Edit Campaign',
      pageBuilder: (dialogContext, a1, a2) => CampaignEditModal(campaign: c, onClose: () => Navigator.of(dialogContext).maybePop()),
    );
  }

  void _cancelCampaign(CampaignEntity c) {
    setState(() => AdmissionsLocalData.campaigns.removeWhere((x) => x.id == c.id));
  }

  void _previewTemplate(MessageTemplateEntity t) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'Template Preview',
      pageBuilder: (dialogContext, a1, a2) => TemplatePreviewModal(template: t, onClose: () => Navigator.of(dialogContext).maybePop()),
    );
  }

  void _viewReport(CampaignEntity c) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'Campaign Report',
      pageBuilder: (dialogContext, a1, a2) => CampaignReportModal(campaign: c, onClose: () => Navigator.of(dialogContext).maybePop()),
    );
  }

  void _openNewEvent() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'New Event',
      pageBuilder: (dialogContext, a1, a2) => NewEventModal(
        nextId: _nextEventId++,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onSave: (ev) {
          Navigator.of(dialogContext).maybePop();
          setState(() => AdmissionsLocalData.events.insert(0, ev));
        },
      ),
    );
  }

  void _manageRsvps(MarketingEventEntity ev) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'Manage RSVPs',
      pageBuilder: (dialogContext, a1, a2) => ManageRsvpsModal(
        event: ev,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onSave: (rsvp) {
          Navigator.of(dialogContext).maybePop();
          setState(() {
            final i = AdmissionsLocalData.events.indexWhere((e) => e.id == ev.id);
            if (i != -1) AdmissionsLocalData.events[i] = ev.copyWith(rsvp: rsvp);
          });
        },
      ),
    );
  }

  void _sendReminder(MarketingEventEntity ev) {
    final pending = (ev.capacity - ev.rsvp).clamp(0, ev.capacity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder sent to ${ev.rsvp} confirmed RSVP${ev.rsvp == 1 ? '' : 's'} for "${ev.name}"${pending > 0 ? ' · $pending seat${pending == 1 ? '' : 's'} still open' : ''}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = AdmissionsLocalData.campaigns;
    return AdmissionsLayout(
      child: Container(
        color: const Color(0xFFF9FAFB),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
                _campaignsCard(campaigns),
                const SizedBox(height: 16),
                _templatesCard(),
                const SizedBox(height: 16),
                _eventsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: const Color(0xFFFDF2F8), borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: const Icon(Icons.send_outlined, size: 18, color: Color(0xFFA21CAF)),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admissions Marketing', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
            Text('Campaigns, templates, and event management', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
          ],
        ),
      ),
      ElevatedButton.icon(
        onPressed: _openNewCampaign,
        icon: const Icon(Icons.add, size: 14),
        label: const Text('New Campaign'),
        style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _sectionHeader({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: child,
    );
  }

  Widget _campaignsCard(List<CampaignEntity> campaigns) {
    final hasSent = campaigns.any((c) => c.status == 'sent');
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            child: Row(children: [
              const Icon(Icons.bolt, size: 15, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text('Campaigns', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
              const SizedBox(width: 8),
              _countPill('${campaigns.length}'),
            ]),
          ),
          if (campaigns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              child: Column(children: [
                const Icon(Icons.send_outlined, size: 40, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 12),
                const Text('No campaigns yet.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                const Text('Create your first campaign to start reaching parents at scale.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openNewCampaign,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Create Campaign'),
                  style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white),
                ),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: campaigns.map(_campaignTile).toList()),
            ),
          if (hasSent) _campaignSummaryBar(campaigns),
        ],
      ),
    );
  }

  Widget _countPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
    );
  }

  Widget _campaignTile(CampaignEntity c) {
    final stripeColor = c.status == 'scheduled'
        ? const Color(0xFF3B82F6)
        : c.status == 'sent'
            ? const Color(0xFF22C55E)
            : c.status == 'active'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF9CA3AF);
    final channelIcon = c.channel.contains('WhatsApp') && c.channel.contains('Email')
        ? '💬📧'
        : c.channel.contains('WhatsApp')
            ? '💬'
            : c.channel.contains('Email')
                ? '📧'
                : '📱';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
                padding: const EdgeInsets.fromLTRB(17, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
                      _statusBadge(c.status),
                    ]),
                    const SizedBox(height: 4),
                    Text('$channelIcon ${c.channel} · 👥 ${c.audience}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    if (c.status == 'sent') ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _pill('${c.sentCount} parents', const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
                        _pill('${c.deliveredPct}% delivered', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
                        _pill('${c.replies} replies', const Color(0xFFFAF5FF), const Color(0xFF7E22CE)),
                      ]),
                    ],
                    if (c.status == 'scheduled') ...[
                      const SizedBox(height: 6),
                      Text('Scheduled: ${c.scheduledFor} · ${c.sentCount} recipients', style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB))),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      OutlinedButton(
                        onPressed: () => _editCampaign(c),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      if (c.status == 'sent')
                        ElevatedButton(
                          onPressed: () => _viewReport(c),
                          style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
                          child: const Text('View Report'),
                        ),
                      if (c.status == 'scheduled')
                        ElevatedButton(
                          onPressed: () => _cancelCampaign(c),
                          style: ElevatedButton.styleFrom(backgroundColor: kMarketingBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
                          child: const Text('Cancel'),
                        ),
                    ]),
                  ],
                ),
          ),
          Positioned(left: 0, top: 0, bottom: 0, width: 5, child: Container(color: stripeColor)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final map = {
      'draft': (bg: const Color(0xFFF3F4F6), fg: const Color(0xFF6B7280), label: '✏️ Draft'),
      'scheduled': (bg: const Color(0xFFEFF6FF), fg: const Color(0xFF1D4ED8), label: '⏰ Scheduled'),
      'active': (bg: const Color(0xFFFFFBEB), fg: const Color(0xFFB45309), label: '● Active'),
      'sent': (bg: const Color(0xFFF0FDF4), fg: const Color(0xFF15803D), label: '✓ Sent'),
    };
    final s = map[status] ?? map['draft']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(s.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: s.fg)),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10.5, color: fg)),
    );
  }

  Widget _campaignSummaryBar(List<CampaignEntity> campaigns) {
    final sentCampaigns = campaigns.where((c) => c.sentCount > 0).toList();
    final totalSent = sentCampaigns.fold<int>(0, (a, c) => a + c.sentCount);
    final deliveredCampaigns = campaigns.where((c) => c.deliveredPct != null).toList();
    final avgDelivery = deliveredCampaigns.isEmpty ? 0 : (deliveredCampaigns.fold<int>(0, (a, c) => a + (c.deliveredPct ?? 0)) / deliveredCampaigns.length).round();
    final totalReplies = campaigns.fold<int>(0, (a, c) => a + (c.replies ?? 0));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(children: [
        Expanded(child: _summaryStat('📨', const Color(0xFFDBEAFE), '$totalSent', 'Total Sent', null)),
        const SizedBox(width: 10),
        Expanded(child: _summaryStat('✅', const Color(0xFFDCFCE7), '$avgDelivery%', 'Avg Delivery', 'Industry avg: 90%')),
        const SizedBox(width: 10),
        Expanded(child: _summaryStat('💬', const Color(0xFFF3E8FF), '$totalReplies', 'Total Replies', '7.5% reply rate')),
      ]),
    );
  }

  Widget _summaryStat(String emoji, Color iconBg, String value, String label, String? sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(emoji, style: const TextStyle(fontSize: 14))),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
          if (sub != null) Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _templatesCard() {
    final channels = ['whatsapp', 'email', 'sms'];
    final channelLabels = {'whatsapp': '💬 WhatsApp', 'email': '📧 Email', 'sms': '📱 SMS'};
    final channelBadgeColors = {'whatsapp': const Color(0xFF22C55E), 'email': const Color(0xFF3B82F6), 'sms': const Color(0xFFEAB308)};
    final filtered = _filteredTemplates;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.chat_bubble_outline, size: 15, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Message Templates Library', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111111)))),
                _countPill('${AdmissionsLocalData.templates.length} templates'),
              ]),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => setState(() => _searchQ = v),
                decoration: InputDecoration(
                  hintText: 'Search templates…',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: channels.map((ch) {
                    final isActive = _templateTab == ch;
                    final cnt = AdmissionsLocalData.templates.where((t) => t.channel == ch).length;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _templateTab = ch),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(9), boxShadow: isActive ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3)] : null),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Flexible(
                              child: Text(channelLabels[ch]!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280))),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: channelBadgeColors[ch], borderRadius: BorderRadius.circular(999)),
                              child: Text('$cnt', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: filtered.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No templates match your search.', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)))))
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: filtered.map(_templateCard).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(MessageTemplateEntity t) {
    final catStyle = kCategoryStyles[t.category] ?? (color: const Color(0xFF6B7280), emoji: '📄');
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 32, color: catStyle.color, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(catStyle.emoji, style: const TextStyle(fontSize: 17))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(t.useCase, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                  Row(children: [
                    _channelBadge(t.channel),
                    const Spacer(),
                    InkWell(
                      onTap: () => _previewTemplate(t),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelBadge(String channel) {
    final bg = channel == 'whatsapp' ? const Color(0xFFDCFCE7) : channel == 'email' ? const Color(0xFFDBEAFE) : const Color(0xFFFEF9C3);
    final fg = channel == 'whatsapp' ? const Color(0xFF15803D) : channel == 'email' ? const Color(0xFF1D4ED8) : const Color(0xFFA16207);
    final label = channel == 'whatsapp' ? 'WhatsApp' : channel == 'email' ? 'Email' : 'SMS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _eventsCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Events Manager', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111111)))),
              ElevatedButton.icon(
                onPressed: _openNewEvent,
                icon: const Icon(Icons.add, size: 12),
                label: const Text('New Event'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              ...AdmissionsLocalData.events.map((ev) {
                final ratio = ev.capacity == 0 ? 0.0 : ev.rsvp / ev.capacity;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
                      const SizedBox(height: 2),
                      Text('📅 ${ev.date} · ⏰ ${ev.time} · 🎟️ ${ev.rsvp}/${ev.capacity} RSVPs', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(3), child: SizedBox(width: 180, height: 5, child: LinearProgressIndicator(value: ratio, backgroundColor: const Color(0xFFF3F4F6), color: const Color(0xFF0EA5E9)))),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        OutlinedButton(
                          onPressed: () => _manageRsvps(ev),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 11.5)),
                          child: const Text('Manage RSVPs'),
                        ),
                        OutlinedButton(
                          onPressed: () => _sendReminder(ev),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1D4ED8), backgroundColor: const Color(0xFFEFF6FF), side: const BorderSide(color: Color(0xFFBFDBFE)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), textStyle: const TextStyle(fontSize: 11.5)),
                          child: const Text('Send Reminder'),
                        ),
                      ]),
                    ],
                  ),
                );
              }),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Create an event to auto-generate RSVP links and bulk-invite all active inquiries with one click.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
