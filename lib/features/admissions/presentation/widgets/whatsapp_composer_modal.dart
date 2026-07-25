import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/inquiry_entity.dart';
import 'ai_message_composer_modal.dart';

List<String> generateWhatsAppMessages(InquiryEntity inq) {
  final firstName = inq.fullName.trim().split(RegExp(r'\s+')).firstOrNull ?? 'there';
  final grade = inq.classNameResolved != null ? 'Grade ${inq.classNameResolved}' : "your child's grade";
  return [
    'Hello $firstName!\n\nThank you for your inquiry about admission for $grade.\n\nWe\'d love to give you a personal campus tour.\n\nWould you like to schedule a visit this week?\n\nWarm regards,\nAdmissions Team',
    'Hi $firstName!\n\nFriendly reminder about your admission inquiry for $grade.\n\nSeats are filling up fast! Book a visit today.\n\nBest wishes,\nAdmissions Team',
    'Dear $firstName,\n\nGreat speaking with you about $grade admission!\n\nWe offer:\n- Experienced faculty & modern infrastructure\n- Holistic development programs\n- Safe & supportive environment\n\nAdmissions Team',
  ];
}

/// WhatsApp Composer — converted from `AdmissionsCommandCenter.tsx`'s
/// "WHATSAPP MODAL". Three pre-written templates, an editable message
/// body, copy-to-clipboard, and "Open WhatsApp" (a `https://wa.me/91{phone}`
/// deep link, matching web's `sendWADirect` — there is no backend WhatsApp
/// send API, web itself only ever opens this link), which also logs a
/// `whatsapp_sent` contact update. "AI Compose" hands off to
/// [AiMessageComposerModal] (`/api/v1/admissions/ai/generate/` +
/// `/actions/{channel}/` — see that file for the real, currently-broken
/// backend behavior this faithfully reproduces).
class WhatsAppComposerModal extends ConsumerStatefulWidget {
  final InquiryEntity inquiry;
  final VoidCallback onClose;
  final VoidCallback onSent;

  const WhatsAppComposerModal({
    super.key,
    required this.inquiry,
    required this.onClose,
    required this.onSent,
  });

  @override
  ConsumerState<WhatsAppComposerModal> createState() => _WhatsAppComposerModalState();
}

class _WhatsAppComposerModalState extends ConsumerState<WhatsAppComposerModal> {
  late final List<String> _messages = generateWhatsAppMessages(widget.inquiry);
  int _selected = 0;
  late final _editedController = TextEditingController(text: _messages.first);
  bool _copied = false;

  @override
  void dispose() {
    _editedController.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _editedController.text));
    setState(() => _copied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied!')));
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _send() async {
    final phone = widget.inquiry.phone.trim();
    final uri = Uri.parse('https://wa.me/91$phone?text=${Uri.encodeComponent(_editedController.text)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
      return;
    }
    widget.onSent();
  }

  void _openAiCompose() {
    widget.onClose();
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'AI Compose',
      pageBuilder: (dialogContext, a1, a2) => AiMessageComposerModal(
        inquiry: widget.inquiry,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onSent: () {
          Navigator.of(dialogContext).maybePop();
          widget.onSent();
        },
      ),
    );
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
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF15803D), Color(0xFF16A34A)])),
                child: Row(children: [
                  const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('WhatsApp Composer — ${widget.inquiry.fullName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                  ),
                  TextButton.icon(
                    onPressed: _openAiCompose,
                    icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    label: const Text('AI Compose', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Colors.white)),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ...List.generate(_messages.length, (i) {
                      final isSelected = _selected == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() {
                            _selected = i;
                            _editedController.text = _messages[i];
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                              border: Border.all(color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB), width: isSelected ? 1.5 : 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text.rich(TextSpan(children: [
                              TextSpan(text: 'Template ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF111827))),
                              TextSpan(text: '  ${_messages[i].length > 100 ? _messages[i].substring(0, 100) : _messages[i]}...', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                            ])),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _editedController,
                      minLines: 6,
                      maxLines: 10,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      OutlinedButton.icon(
                        onPressed: _copy,
                        icon: Icon(_copied ? Icons.check_circle : Icons.copy, size: 14, color: _copied ? const Color(0xFF059669) : null),
                        label: Text(_copied ? 'Copied!' : 'Copy'),
                        style: OutlinedButton.styleFrom(foregroundColor: _copied ? const Color(0xFF059669) : const Color(0xFF111111), side: const BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _send,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                          child: const Text('Open WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
            ),
          ),
        ),
      ),
    );
  }
}
