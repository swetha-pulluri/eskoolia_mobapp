import 'package:flutter/material.dart';
import '../utils/fee_assignment_format.dart' show fmtRs, groupIndian;
import '../utils/fees_collection_format.dart' show fmtDate;
import 'fees_collection_models.dart';
import 'fees_collection_styles.dart';

/// "Student Ledger View" modal — mirrors FeesCollectionPanel.tsx's
/// `showLedger` block (§12 of the port spec), including the
/// "Late Fee Calculator Preview" block that only renders when
/// `student.lateFeeCalc` is non-null (always null in the current app,
/// same as the source — `lateFeeCalc` is typed but never populated).
class FcStudentLedgerDialog extends StatelessWidget {
  final FcStudentRecord student;
  final VoidCallback onGeneratePdf;
  final void Function(String message) onToast;

  const FcStudentLedgerDialog({super.key, required this.student, required this.onGeneratePdf, required this.onToast});

  static Future<void> show(
    BuildContext context, {
    required FcStudentRecord student,
    required VoidCallback onGeneratePdf,
    required void Function(String) onToast,
  }) {
    return showDialog(
      context: context,
      barrierColor: const Color(0x660E1020),
      builder: (_) => FcStudentLedgerDialog(student: student, onGeneratePdf: onGeneratePdf, onToast: onToast),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = fcStatusStyle[student.status] ?? fcStatusStyle['unassigned']!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 64, offset: Offset(0, 24))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Student Ledger View', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fcInk1)),
                            const SizedBox(height: 3),
                            Text('${student.name} · ${student.admNo} · Class ${student.cls}', style: const TextStyle(fontSize: 12, color: fcInk3)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fcBorder)),
                          child: const Text('×', style: TextStyle(fontSize: 17, color: fcInk3, height: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: fcBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: fcPurpleTint, border: Border.all(color: fcPurpleBorder), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              FcAvatar(name: student.name, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(student.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fcInk1)),
                                    Text('${student.admNo} · Class ${student.cls} · ${student.group}', style: const TextStyle(fontSize: 12, color: fcInk3)),
                                  ],
                                ),
                              ),
                              FcStatusPill(label: student.status, bg: st.bg, color: st.color),
                            ],
                          ),
                        ),
                        for (final e in student.fullLedger) ...[_ledgerRow(e, const Color(0xFFE8E8EE)), const SizedBox(height: 8)],
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ledger balance', style: TextStyle(fontSize: 14, color: fcInk2)),
                              Text(fmtRs(student.ledgerBalance), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fcPurple)),
                            ],
                          ),
                        ),
                        if (student.lateFeeCalc != null) _lateFeeBlock(student.lateFeeCalc!),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: fcBorder))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: fcInk1,
                          elevation: 0,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: fcBorder)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Color(0x336D4AFF), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: ElevatedButton(
                          onPressed: onGeneratePdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fcPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Generate Ledger PDF'),
                        ),
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

  Widget _ledgerRow(FcLedgerEntry e, Color borderColor) {
    final color = e.type == FcLedgerType.credit
        ? const Color(0xFF16A34A)
        : (e.type == FcLedgerType.charge ? const Color(0xFFDC2626) : fcInk3);
    final amountText = e.amount != null ? '${e.type == FcLedgerType.credit ? '−' : ''}Rs. ${groupIndian(e.amount!.round().abs().toString())}' : 'Note';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(fmtDate(e.date), style: const TextStyle(fontSize: 11.5, color: fcInk3, height: 1.4)))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fcInk1)),
                const SizedBox(height: 3),
                Text(e.note, style: const TextStyle(fontSize: 12, color: fcInk3, height: 1.4)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: 2), child: Text(amountText, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color))),
        ],
      ),
    );
  }

  Widget _lateFeeBlock(FcLateFeeCalc calc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(color: Color(0xFFF8F8FB), border: Border(bottom: BorderSide(color: fcBorder))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Late Fee Calculator Preview', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fcInk1)),
                      const SizedBox(height: 2),
                      const Text('Transparent penalty calculation shown before reminder, receipt, or ledger posting.', style: TextStyle(fontSize: 12, color: fcInk3)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FcOutlineButton(small: true, label: 'Copy Breakdown', onPressed: () => onToast('Breakdown copied to clipboard.')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(calc.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fcInk1)),
                const SizedBox(height: 4),
                Text(calc.dueRule, style: const TextStyle(fontSize: 12, color: fcInk3)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statTile('OUTSTANDING', fmtRs(calc.outstanding)),
                    const SizedBox(width: 10),
                    _statTile('DAYS OVERDUE', '${calc.daysOverdue}'),
                    const SizedBox(width: 10),
                    _statTile('CHARGEABLE DAYS', '${calc.chargeableDays}'),
                    const SizedBox(width: 10),
                    _statTile('RAW PENALTY', fmtRs(calc.rawPenalty)),
                    const SizedBox(width: 10),
                    _statTile('FINAL DUE', fmtRs(calc.finalDue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: fcInk3)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fcInk1)),
          ],
        ),
      ),
    );
  }
}
