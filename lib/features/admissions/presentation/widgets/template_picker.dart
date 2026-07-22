import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/inquiry_entity.dart';

class _Template {
  final String label;
  final String Function(InquiryEntity inq) body;
  const _Template(this.label, this.body);
}

class _TemplateGroup {
  final String category;
  final List<_Template> templates;
  const _TemplateGroup(this.category, this.templates);
}

String _firstName(InquiryEntity inq) {
  final parts = inq.fullName.trim().split(RegExp(r'\s+'));
  return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'there';
}

final List<_TemplateGroup> _kTemplateGroups = [
  _TemplateGroup('Welcome', [
    _Template('Warm Welcome', (inq) {
      final first = _firstName(inq);
      final grade = inq.classNameResolved != null ? 'Grade ${inq.classNameResolved}' : 'your chosen grade';
      return 'Hello $first! 👋\n\nThank you for your interest in admission for $grade.\n\nWe\'d love to show you around our campus. Would you be available for a visit this week?\n\nPlease reply with a convenient time!\n\nWarm regards,\nAdmissions Team';
    }),
  ]),
  _TemplateGroup('Follow-up', [
    _Template('Gentle Reminder', (inq) {
      final first = _firstName(inq);
      final grade = inq.classNameResolved != null ? 'Grade ${inq.classNameResolved}' : 'the grade';
      return 'Hi $first! 😊\n\nJust following up on your admission inquiry for $grade.\n\nWe still have seats available for the upcoming academic year — but they\'re filling up fast!\n\n🗓️ Book your campus visit today. Reply with a convenient time.\n\nBest wishes,\nAdmissions Team';
    }),
    _Template('Second Follow-up', (inq) {
      final first = _firstName(inq);
      return 'Hi $first,\n\nHope you\'re doing well! We wanted to follow up once more about your child\'s admission.\n\nWe\'d love to answer any questions you might have about our programs, fees, or facilities.\n\nFeel free to call us anytime — we\'re here to help! 📞\n\nAdmissions Team';
    }),
  ]),
  _TemplateGroup('Visit', [
    _Template('Visit Invitation', (inq) {
      final first = _firstName(inq);
      return 'Dear $first,\n\n🏫 We\'d like to invite you for a personal campus tour!\n\nDuring the visit you\'ll get to:\n✅ Meet our faculty\n✅ See our facilities & classrooms\n✅ Speak with the Admissions Head\n\nPlease reply with your preferred date and we\'ll arrange everything.\n\nAdmissions Team';
    }),
    _Template('Visit Confirmation', (inq) {
      final first = _firstName(inq);
      return 'Dear $first,\n\n✅ Your campus visit is confirmed!\n\nPlease arrive 10 minutes early and ask for the Admissions Desk.\n\nLooking forward to meeting you!\n\nAdmissions Team';
    }),
  ]),
  _TemplateGroup('Offer', [
    _Template('Seat Offer', (inq) {
      final first = _firstName(inq);
      final grade = inq.classNameResolved != null ? 'Grade ${inq.classNameResolved}' : 'your chosen grade';
      return 'Dear $first,\n\n🎉 We are pleased to offer your child a seat in $grade!\n\nPlease visit us at your earliest convenience to complete the enrollment formalities.\n\nAdmissions Team';
    }),
    _Template('Seat Urgency', (inq) {
      final first = _firstName(inq);
      return 'Hi $first! ⚠️\n\nWe have very limited seats remaining for the upcoming academic year.\n\nPlease confirm your interest soon to avoid missing out!\n\nAdmissions Team';
    }),
  ]),
  _TemplateGroup('Waitlist', [
    _Template('Waitlist Notification', (inq) {
      final first = _firstName(inq);
      return 'Dear $first,\n\nThank you for your interest. Your child has been added to our waitlist.\n\nWe will contact you as soon as a seat becomes available.\n\nAdmissions Team';
    }),
  ]),
  _TemplateGroup('Rejection', [
    _Template('Polite Decline', (inq) {
      final first = _firstName(inq);
      return 'Dear $first,\n\nThank you for considering our school for your child\'s education.\n\nUnfortunately, we are unable to offer admission at this time due to limited availability.\n\nWe wish your family the very best.\n\nAdmissions Team';
    }),
  ]),
  _TemplateGroup('Difficult Parent', [
    _Template('Acknowledge & Escalate', (inq) {
      final first = _firstName(inq);
      return 'Dear $first,\n\nThank you for sharing your concerns with us. We take all feedback very seriously.\n\nOur Admissions Head will personally reach out to you within 24 hours to address each point.\n\nWe genuinely want to make this right for your family.\n\nWarm regards,\nAdmissions Team';
    }),
    _Template('Personal Assurance', (inq) {
      final first = _firstName(inq);
      return 'Dear $first,\n\nI want to personally assure you that your child\'s experience at our school is our highest priority.\n\nI\'ve escalated your concern directly and we will have a resolution for you shortly.\n\nPlease feel free to call me directly at any time.\n\nWith respect,\nAdmissions Head';
    }),
  ]),
  _TemplateGroup('Busy Parent', [
    _Template('30-Second Pitch', (inq) {
      final first = _firstName(inq);
      final grade = inq.classNameResolved != null ? 'Grade ${inq.classNameResolved}' : 'your child\'s grade';
      return 'Hi $first ⚡\n\nQuick update — seats for $grade are filling fast.\n\n✅ Top faculty\n✅ Strong results\n✅ Safe campus\n\nCan we do a 20-min campus visit this Saturday? I\'ll keep it brief.\n\nReply YES and I\'ll block a slot for you.\n\nAdmissions Team';
    }),
    _Template('Video Tour Offer', (inq) {
      final first = _firstName(inq);
      return 'Hi $first,\n\nNo problem if you\'re busy — I\'ll send you a 60-second video tour of our campus right now.\n\nTake a look whenever you get a moment, and I\'m happy to answer any questions over WhatsApp at your convenience.\n\nAdmissions Team 🏫';
    }),
  ]),
  _TemplateGroup('FAQ Parent', [
    _Template('Open House Invite', (inq) {
      final first = _firstName(inq);
      return 'Dear $first,\n\nThank you for your thoughtful questions! You\'ve asked all the right things.\n\n🎓 Rather than reply one-by-one, I\'d love to invite you to our Open House where our Principal and Department Heads will answer everything in person.\n\nDate: [Open House Date]\nTime: [Time]\nVenue: School Campus\n\nShall I reserve a spot for you?\n\nAdmissions Team';
    }),
    _Template('FAQ Brochure + Q&A Offer', (inq) {
      final first = _firstName(inq);
      return 'Hi $first! 📋\n\nI\'m sharing our detailed FAQ brochure that covers:\n✅ Curriculum & syllabus\n✅ Faculty credentials\n✅ Fee structure & scholarships\n✅ Transport & facilities\n✅ Co-curricular programs\n\nI\'d also love to book a personal 30-min Q&A session with our Admissions Head.\n\nWhen are you available this week?\n\nAdmissions Team';
    }),
  ]),
];

/// Template Picker — centered modal for choosing a bulk WhatsApp message
/// template. Converted from web `command-center/TemplatePicker.tsx`.
class TemplatePicker extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;
  final InquiryEntity? inquiry;

  const TemplatePicker({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onSelect,
    required this.inquiry,
  });

  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker> {
  String _activeCategory = _kTemplateGroups.first.category;
  String? _selectedTemplate;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();
    final activeGroup = _kTemplateGroups.firstWhere((g) => g.category == _activeCategory);
    final inquiry = widget.inquiry;
    String previewBody = '';
    if (_selectedTemplate != null && inquiry != null) {
      previewBody = _selectedTemplate!;
    } else if (inquiry != null && activeGroup.templates.isNotEmpty) {
      previewBody = activeGroup.templates.first.body(inquiry);
    }

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x80000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Message Templates', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
                      IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                Flexible(
                  child: SizedBox(
                    height: 420,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 130,
                          child: Container(
                            decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFF3F4F6)))),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: _kTemplateGroups.map((g) {
                                final isActive = _activeCategory == g.category;
                                return InkWell(
                                  onTap: () => setState(() {
                                    _activeCategory = g.category;
                                    _selectedTemplate = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
                                      border: Border(right: BorderSide(color: isActive ? const Color(0xFF4F46E5) : Colors.transparent, width: 2)),
                                    ),
                                    child: Text(g.category, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? const Color(0xFF4338CA) : const Color(0xFF4B5563))),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_activeCategory.toUpperCase()} TEMPLATES', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.3)),
                                const SizedBox(height: 10),
                                ...activeGroup.templates.map((t) {
                                  final body = inquiry != null ? t.body(inquiry) : '';
                                  final isActive = _selectedTemplate == body;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedTemplate = body),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
                                          border: Border.all(color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB)),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF4338CA) : const Color(0xFF1F2937))),
                                            const SizedBox(height: 3),
                                            Text(
                                              body.length > 100 ? '${body.substring(0, 100)}…' : body,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                if (previewBody.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), border: Border.all(color: const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Preview:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
                                        const SizedBox(height: 6),
                                        Text(previewBody, style: const TextStyle(fontSize: 11.5, color: Color(0xFF374151), height: 1.4)),
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
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: previewBody.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(ClipboardData(text: previewBody));
                                setState(() => _copied = true);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) setState(() => _copied = false);
                                });
                              },
                        icon: Icon(_copied ? Icons.check_circle : Icons.copy, size: 14, color: _copied ? const Color(0xFF22C55E) : null),
                        label: Text(_copied ? 'Copied!' : 'Copy'),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: previewBody.isEmpty
                            ? null
                            : () {
                                widget.onSelect(previewBody);
                                widget.onClose();
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                        child: const Text('Use Template →'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
