import 'package:flutter/material.dart';
import 'fee_config_styles.dart';

/// The "Help & Information" modal opened from the Fee Schedules tab's "i"
/// button. Mirrors FeeConfigurationPanel.tsx's `isHelpModalOpen` dialog
/// exactly — its content is generic (not tab-specific), unlike the
/// per-tab `HELP_CONTENT` object elsewhere in the source, which is declared
/// but never actually rendered by anything.
class FeeConfigHelpModal extends StatelessWidget {
  const FeeConfigHelpModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Help & Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Section(
                      title: 'WHAT IS THIS PAGE?',
                      body:
                          'This module allows you to structure how fees are collected across your institution. You can define various fee groups (like Day Scholars or Hostellers), fee types (Tuition, Transport), and most importantly, the schedules that dictate when these fees are due and how they are split.',
                    ),
                    SizedBox(height: 22),
                    _Section.list(
                      title: 'HOW TO SET IT UP?',
                      items: [
                        'Create Fee Groups: Define student categories that share the same fee structure.',
                        'Define Fee Types: Create the individual line items (e.g., Admission Fee, Library Fee).',
                        'Configure Schedules: Link a group to a type, set the total amount, and define the installments.',
                      ],
                    ),
                    SizedBox(height: 22),
                    _Section.list(
                      title: 'WHAT ARE THOSE OPTIONS?',
                      items: [
                        'Collection Structure: Determines if a fee is collected monthly, quarterly, or yearly.',
                        'Grace Period: Number of days after the due date before late fees start applying.',
                        'Late Fee Rule: The specific penalty calculation method to use.',
                      ],
                    ),
                    SizedBox(height: 22),
                    _Section(
                      title: 'SUGGESTIONS',
                      body:
                          'Always ensure your Academic Calendar (at the top) is correct before generating monthly slots, as due dates are calculated based on your academic year start and end dates.',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Align(
                alignment: Alignment.centerRight,
                child: FeeConfigPrimaryButton(label: 'Got it', onPressed: () => Navigator.of(context).pop()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final List<String>? items;
  const _Section({required this.title, required this.body}) : items = null;
  const _Section.list({required this.title, required this.items}) : body = null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: feeConfigPurple, letterSpacing: 0.6)),
        const SizedBox(height: 12),
        if (body != null) Text(body!, style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.6)),
        if (items != null)
          for (var i = 0; i < items!.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.6),
                  children: [
                    TextSpan(text: '${i + 1}. '),
                    TextSpan(text: items![i]),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
