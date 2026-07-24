import 'package:flutter/material.dart';
import 'fee_assignment_styles.dart';

typedef FaPaymentPlan = ({String id, String label, String desc});

const _plans = <FaPaymentPlan>[
  (id: '2-term', label: '2-Term Plan', desc: 'Two equal instalments per year'),
  (id: '3-term', label: '3-Term Plan', desc: 'Three equal instalments per year'),
  (id: '4-term', label: '4-Term Plan', desc: 'Four equal instalments per year'),
  (id: 'monthly', label: 'Monthly Plan', desc: '12 equal monthly payments'),
  (id: 'custom', label: 'Custom Plan', desc: 'Admin-defined irregular schedule'),
];

/// "Change Payment Plan" modal — converted from FeesAssignmentPanel.tsx's
/// Modal 2. Purely cosmetic in the source: `confirmPlanSwitch` never calls
/// any API, it just closes the modal and shows a toast — there is no real
/// payment-plan backend to persist to. Reproduced faithfully: this dialog
/// does not touch the network either, it only returns the chosen plan so
/// the caller can show the same toast.
class FaChangePlanDialog extends StatefulWidget {
  final String studentName;
  const FaChangePlanDialog({super.key, required this.studentName});

  static Future<FaPaymentPlan?> show(BuildContext context, {required String studentName}) {
    return showDialog<FaPaymentPlan>(
      context: context,
      builder: (_) => FaChangePlanDialog(studentName: studentName),
    );
  }

  @override
  State<FaChangePlanDialog> createState() => _FaChangePlanDialogState();
}

class _FaChangePlanDialogState extends State<FaChangePlanDialog> {
  String _selected = '3-term';
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FaModalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaModalHeader(title: 'Change Payment Plan', subtitle: '${widget.studentName} · current: 3-Term Plan', onClose: () => Navigator.of(context).pop()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switching plans takes effect from the next due date. A plan-change record is logged automatically.',
                  style: TextStyle(fontSize: 12.5, color: faInk2, height: 1.6),
                ),
                const SizedBox(height: 16),
                for (final plan in _plans) _planTile(plan),
                const SizedBox(height: 12),
                const Text('REASON FOR CHANGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: faInk3)),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'e.g. Parent requested monthly billing from June 2026',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: faBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: faBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: faPurple)),
                  ),
                ),
              ],
            ),
          ),
          FaModalFooter(children: [
            FaOutlineButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
            FaPrimaryButton(
              label: 'Confirm Plan Switch',
              onPressed: () => Navigator.of(context).pop(_plans.firstWhere((p) => p.id == _selected)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _planTile(FaPaymentPlan plan) {
    final isChosen = _selected == plan.id;
    final isCurrent = plan.id == '3-term';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => setState(() => _selected = plan.id),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isChosen ? const Color(0xFFF5F3FF) : Colors.white,
            border: Border.all(color: isChosen ? faPurple : faBorder),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Radio<String>(value: plan.id, groupValue: _selected, onChanged: (v) => setState(() => _selected = v!), activeColor: faPurple, visualDensity: VisualDensity.compact),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(plan.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: faInk1)),
                        if (isCurrent) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF86EFAC))),
                            child: const Text('Current', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                          ),
                        ],
                      ],
                    ),
                    Text(plan.desc, style: const TextStyle(fontSize: 12, color: faInk3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
