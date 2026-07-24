import 'package:flutter/material.dart';
import 'fee_assignment_styles.dart';

const _infoSteps = [
  (n: 1, title: 'Select a fee group', body: 'e.g. Day Scholar, Full Boarder. This determines which fee types apply.'),
  (n: 2, title: 'Choose an instalment plan', body: 'term-wise, monthly, or a custom split. This controls when payments are due.'),
  (n: 3, title: 'Apply a concession', body: 'if eligible — Merit, Staff Ward, Sibling, etc. Discounts are computed automatically.'),
  (n: 4, title: 'Save the assignment', body: 'the student moves from Unassigned → Assigned and appears in the Collection tab.'),
  (n: 5, title: 'Use Bulk Assign', body: 'to process a whole class at once when group and plan are the same for all students.'),
];

/// "How Fee Assignment works" info modal — converted from
/// FeesAssignmentPanel.tsx's Modal 5.
class FaInfoDialog extends StatelessWidget {
  const FaInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (_) => const FaInfoDialog());
  }

  @override
  Widget build(BuildContext context) {
    return FaModalShell(
      maxWidth: 620,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaModalHeader(title: 'How Fee Assignment works', subtitle: 'A quick guide to assigning fees to students', onClose: () => Navigator.of(context).pop()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in _infoSteps) _stepTile(step),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(9)),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E), height: 1.6),
                      children: [
                        TextSpan(text: '💡 '),
                        TextSpan(text: 'Tip: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: 'For custom fee arrangements agreed with parents, use the '),
                        TextSpan(text: 'Enroll Student', style: TextStyle(fontStyle: FontStyle.italic)),
                        TextSpan(text: ' tab (Step 11) to build a documented fee plan first, then assign here.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          FaModalFooter(children: [FaPrimaryButton(label: 'Got it', onPressed: () => Navigator.of(context).pop())]),
        ],
      ),
    );
  }

  Widget _stepTile(({int n, String title, String body}) step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: faBorder), borderRadius: BorderRadius.circular(9)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: faPurple),
              child: Text('${step.n}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: step.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: faInk1)),
                      TextSpan(text: ' — ${step.body}', style: const TextStyle(fontSize: 13, color: faInk2)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
