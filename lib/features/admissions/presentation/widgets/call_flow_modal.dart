import 'package:flutter/material.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../providers/admissions_local_data.dart';

enum _CallStep { contact, coaching, converted }

class _CallTip {
  final String tip;
  final String type; // goal | question | objection | insight
  const _CallTip(this.tip, this.type);
}

String _detectParentType(String note) {
  final n = note.toLowerCase();
  if (RegExp(r'rude|angry|upset|complain|threaten|difficult|aggressive|shout').hasMatch(n)) return 'difficult';
  if (RegExp(r'busy|no time|call back|call me later|not now|tied up|in a meeting').hasMatch(n)) return 'busy';
  if (RegExp(r'fee|expensive|costly|afford|budget|price|cheap|discount|scholarship').hasMatch(n)) return 'fee_sensitive';
  final qCount = RegExp(r'\?').allMatches(n).length;
  if (qCount >= 2 || RegExp(r'curriculum|syllabus|ratio|extracurricular|how many|what about|is there').hasMatch(n)) return 'faq_heavy';
  return 'standard';
}

List<_CallTip> _generateCallScript(InquiryEntity inq) {
  final grade = inq.classNameResolved ?? 'the grade';
  final first = inq.fullName.trim().split(RegExp(r'\s+')).firstOrNull ?? 'the parent';
  final parentType = _detectParentType(inq.note);

  if (parentType == 'difficult') {
    return [
      const _CallTip('[Goal] De-escalate first — do NOT push enrollment on this call', 'goal'),
      _CallTip('[Opener] "Hello $first, I\'m calling personally to address your concerns."', 'insight'),
      const _CallTip('[Listen] Let them speak fully without interruption — say "I understand" and "That\'s valid."', 'insight'),
      const _CallTip('[Empathy] "I completely understand your frustration. Let me personally ensure this is resolved."', 'question'),
      const _CallTip('[Offer] Offer a direct callback with the Head of Admissions within 24 hours', 'objection'),
      const _CallTip('[Close] "Can I schedule a call with our Admissions Head tomorrow at a time that suits you?"', 'goal'),
    ];
  }
  if (parentType == 'busy') {
    return [
      _CallTip('[Goal] Land a visit commitment in under 60 seconds — no small talk', 'goal'),
      _CallTip('[Opener] "Hi $first, just 30 seconds — I know you\'re busy. We have a seat opening in $grade."', 'insight'),
      const _CallTip('[Pitch] One sentence: "Top faculty, strong results, safe campus — your child deserves this."', 'insight'),
      const _CallTip('[Ask] "Can we do a 20-minute visit this Saturday? I\'ll keep it brief and to the point."', 'question'),
      const _CallTip('[If no] "I\'ll WhatsApp you a 1-minute video tour. What time is best to send it?"', 'objection'),
      const _CallTip('[After call] Text them immediately to confirm the slot before they forget', 'goal'),
    ];
  }
  if (parentType == 'fee_sensitive') {
    return [
      const _CallTip('[Goal] Reframe value before touching numbers — never lead with fees', 'goal'),
      _CallTip('[Opener] "Hello $first, before we talk fees — let me share what makes us truly worth it."', 'insight'),
      const _CallTip('[Value] Highlight outcomes: board results, alumni success, co-curricular achievements', 'insight'),
      const _CallTip('[Flex] "We have quarterly payment options and limited merit scholarships available."', 'question'),
      const _CallTip('[Compare] "Many parents find fees comparable to private tuition + school separately."', 'objection'),
      const _CallTip('[Close] Invite for campus visit: "Come see the facilities — the investment will make sense."', 'goal'),
    ];
  }
  if (parentType == 'faq_heavy') {
    return [
      const _CallTip('[Goal] Don\'t answer questions one-by-one — invite to an open Q&A visit instead', 'goal'),
      _CallTip('[Opener] "Hello $first, you\'ve asked some great questions. Let me do better — invite you to our open house."', 'insight'),
      const _CallTip('[Redirect] "Our Principal and Dept. Heads will answer everything in person with real examples."', 'insight'),
      const _CallTip('[Triage] Answer only the 1 most urgent question — defer the rest to the visit', 'question'),
      const _CallTip('[Offer] "I\'ll send our school FAQ brochure now. Let\'s book a 30-min Q&A visit too."', 'objection'),
      const _CallTip('[Close] "When works this week? I\'ll block time with our Admissions Head personally."', 'goal'),
    ];
  }

  final tips = <_CallTip>[_CallTip('[Goal] Schedule campus visit within 48 hours for $grade', 'goal')];
  if (inq.followUpDate == null || inq.status == 'new') {
    tips.add(_CallTip('[Opener] "Hello! Calling about $grade admission. Good time to talk?"', 'insight'));
    tips.add(const _CallTip('[Question] "What made you consider our school for your child?"', 'question'));
  } else if (inq.status == 'contacted') {
    tips.add(const _CallTip('[Tip] Reference previous conversation — show continuity.', 'insight'));
    tips.add(const _CallTip('[Question] "What\'s holding you back from scheduling a campus visit?"', 'question'));
  } else if (inq.status == 'visited') {
    tips.add(const _CallTip('[Post-visit] "How did you find the campus? Any questions on fees?"', 'insight'));
  }
  tips.add(const _CallTip('[Objection] Fees concern: "We have flexible quarterly payment plans."', 'objection'));
  tips.add(const _CallTip('[Objection] Distance concern: "We have transport routes covering most areas."', 'objection'));
  return tips;
}

const List<Map<String, String>> kConversionChoices = [
  {'key': 'fee_structure', 'label': 'Share Fee Structure'},
  {'key': 'school_tour', 'label': 'Book School Tour'},
  {'key': 'parent_visit', 'label': 'Parent Meet Appointment'},
  {'key': 'document_collection', 'label': 'Document Checklist'},
  {'key': 'form_filling', 'label': 'Enrollment Form'},
];

const Map<String, Map<String, Color>> _tipColors = {
  'goal': {'bg': Color(0xFFEFF6FF), 'border': Color(0xFFBFDBFE), 'fg': Color(0xFF1D4ED8)},
  'question': {'bg': Color(0xFFF0FDF4), 'border': Color(0xFFBBF7D0), 'fg': Color(0xFF047857)},
  'objection': {'bg': Color(0xFFFEFCE8), 'border': Color(0xFFFDE68A), 'fg': Color(0xFF92400E)},
  'insight': {'bg': Color(0xFFF5F3FF), 'border': Color(0xFFDDD6FE), 'fg': Color(0xFF6D28D9)},
};

/// Call Flow — converted from `AdmissionsCommandCenter.tsx`'s "CALL FLOW
/// MODAL". A 3-step guided calling flow: confirm contact details → live
/// AI call-coach tips (branch on detected parent sentiment) → post-call
/// conversion actions once a student enrolls.
class CallFlowModal extends StatefulWidget {
  final InquiryEntity inquiry;
  final String today;
  final VoidCallback onClose;
  final VoidCallback onEnrolled;
  final ValueChanged<InquiryEntity> onLogUpdate;

  const CallFlowModal({
    super.key,
    required this.inquiry,
    required this.today,
    required this.onClose,
    required this.onEnrolled,
    required this.onLogUpdate,
  });

  @override
  State<CallFlowModal> createState() => _CallFlowModalState();
}

class _CallFlowModalState extends State<CallFlowModal> {
  _CallStep _step = _CallStep.contact;
  late final List<_CallTip> _tips = _generateCallScript(widget.inquiry);

  void _placeCall() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening dialer…')));
    setState(() => _step = _CallStep.coaching);
  }

  Future<void> _handleEnrolled() async {
    setState(() => _step = _CallStep.converted);
    await AdmissionsLocalData.updateInquiry(widget.inquiry.id, (c) => c.copyWith(
          status: 'enrolled',
          activeStatus: 2,
          followUpDate: widget.today,
        ));
    widget.onEnrolled();
  }

  void _handleLogUpdate() {
    widget.onClose();
    widget.onLogUpdate(widget.inquiry);
  }

  void _handleConversionChoice(String key) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening WhatsApp…')));
    widget.onClose();
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
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(child: _content()),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_step) {
      case _CallStep.contact:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _gradientHeader(const [Color(0xFF059669), Color(0xFF10B981)], 'Ready to Call', 'Review contact details before dialing', widget.onClose),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), border: Border.all(color: const Color(0xFF10B981), width: 2), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.inquiry.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                  Text('Phone: ${widget.inquiry.phone}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                  if (widget.inquiry.classNameResolved != null) Text('Grade: ${widget.inquiry.classNameResolved}', style: const TextStyle(fontSize: 13, color: Color(0xFF059669))),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _placeCall,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Call via App', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _placeCall,
                    style: OutlinedButton.styleFrom(foregroundColor: kAdmIndigoLocal, backgroundColor: const Color(0xFFEFF6FF), side: const BorderSide(color: Color(0xFFBFDBFE)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Landline / Desk', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
        ]);
      case _CallStep.coaching:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _gradientHeader(const [Color(0xFF6D28D9), Color(0xFF7C3AED)], 'AI Call Coach', null, widget.onClose, icon: Icons.auto_awesome),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              ..._tips.map((t) {
                final c = _tipColors[t.type]!;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: c['bg'], border: Border.all(color: c['border']!), borderRadius: BorderRadius.circular(8)),
                  child: Text(t.tip, style: TextStyle(fontSize: 12, color: c['fg'])),
                );
              }),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleEnrolled,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Student Enrolled!', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleLogUpdate,
                    style: OutlinedButton.styleFrom(foregroundColor: kAdmIndigoLocal, backgroundColor: const Color(0xFFEFF6FF), side: const BorderSide(color: Color(0xFFBFDBFE)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Log Update', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
        ]);
      case _CallStep.converted:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          _gradientHeader(const [Color(0xFF059669), Color(0xFF10B981)], 'Congratulations! Student enrolled!', null, widget.onClose),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: kConversionChoices
                  .map((opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _handleConversionChoice(opt['key']!),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              Text(opt['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              const Text('Send via WA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                            ]),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ]);
    }
  }

  Widget _gradientHeader(List<Color> colors, String title, String? subtitle, VoidCallback onClose, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Row(children: [
        if (icon != null) Padding(padding: const EdgeInsets.only(right: 10), child: Icon(icon, size: 20, color: Colors.white)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xE6FFFFFF))),
          ]),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18, color: Colors.white)),
      ]),
    );
  }
}

const Color kAdmIndigoLocal = Color(0xFF4F46E5);
