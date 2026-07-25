import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../providers/admissions_provider.dart';

/// AI Message Composer — converted from `AIMessageComposer.tsx`. Generates
/// two variants (Formal/Friendly) via `POST /api/v1/admissions/ai/generate/`
/// and sends the chosen one via `POST /inquiries/{id}/actions/{channel}/`.
///
/// Both endpoints currently fail on the real, deployed backend — confirmed
/// directly against the backend source: `AIGenerateView` calls
/// `AIMessageService.generate(inquiry=..., template=..., tone_preferences=...)`
/// but that method only accepts `system_prompt`/`user_prompt` kwargs
/// (`apps/admissions/providers.py`), so it always 500s; the `actions/*`
/// routes have no `permission_codes` entry on `AdmissionInquiryViewSet`, so
/// `AdminSectionRBACMixin` always raises `PermissionDenied` before checking
/// `is_superuser`, 403-ing for every account. Both are backend-only
/// defects, out of scope to fix here — this widget is wired exactly like
/// the real web `AIMessageComposer.tsx` and surfaces the real error either
/// endpoint returns, rather than hiding the button.
class AiMessageComposerModal extends ConsumerStatefulWidget {
  final InquiryEntity inquiry;
  final VoidCallback onClose;
  final VoidCallback onSent;

  const AiMessageComposerModal({
    super.key,
    required this.inquiry,
    required this.onClose,
    required this.onSent,
  });

  @override
  ConsumerState<AiMessageComposerModal> createState() => _AiMessageComposerModalState();
}

class _AiMessageComposerModalState extends ConsumerState<AiMessageComposerModal> {
  bool _generating = false;
  bool _sending = false;
  bool _consentChecked = false;
  String? _error;
  String _formal = '';
  String _friendly = '';
  int _selected = 0; // 0 = formal, 1 = friendly

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final result = await ref.read(admissionsRepositoryProvider).generateAiMessage(widget.inquiry.id);
      final data = (result['data'] as Map<String, dynamic>?) ?? result;
      setState(() {
        _formal = data['formal']?.toString() ?? data['variant_a']?.toString() ?? '';
        _friendly = data['friendly']?.toString() ?? data['variant_b']?.toString() ?? '';
      });
    } catch (e) {
      setState(() => _error = 'Failed to generate variants: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _send() async {
    if (!_consentChecked) {
      setState(() => _error = 'You must confirm consent before sending.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final body = _selected == 0 ? _formal : _friendly;
      await ref.read(admissionsRepositoryProvider).sendInquiryAction(widget.inquiry.id, 'whatsapp', {'body': body});
      widget.onSent();
    } catch (e) {
      setState(() => _error = 'Send failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
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
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)])),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('AI Compose — ${widget.inquiry.fullName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Colors.white)),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(10)),
                        child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C))),
                      ),
                    if (_generating)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Generating…', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)))))
                    else ...[
                      _variantCard('Formal', _formal, 0),
                      const SizedBox(height: 8),
                      _variantCard('Friendly', _friendly, 1),
                      const SizedBox(height: 12),
                      Row(children: [
                        Checkbox(value: _consentChecked, onChanged: (v) => setState(() => _consentChecked = v ?? false)),
                        const Expanded(child: Text('I confirm consent to message this contact.', style: TextStyle(fontSize: 12))),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        OutlinedButton(onPressed: _generate, child: const Text('Regenerate')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sending ? null : _send,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: Text(_sending ? 'Sending…' : 'Send'),
                          ),
                        ),
                      ]),
                    ],
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

  Widget _variantCard(String label, String body, int index) {
    final selected = _selected == index;
    return InkWell(
      onTap: () => setState(() => _selected = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5F3FF) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: body,
              maxLines: 5,
              style: const TextStyle(fontSize: 12.5),
              onChanged: (v) {
                if (index == 0) {
                  _formal = v;
                } else {
                  _friendly = v;
                }
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
