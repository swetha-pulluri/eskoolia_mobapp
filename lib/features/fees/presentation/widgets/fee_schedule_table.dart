import 'package:flutter/material.dart';
import '../../domain/models/fee_group.dart';
import '../utils/fee_assignment_format.dart';
import 'fee_assignment_styles.dart';

/// One row of a fee group's read-only schedule preview — mirrors
/// FeesAssignmentPanel.tsx's `FeeRow` interface (`FEE_SCHEDULES` useMemo).
class FeeRow {
  final String type;
  final String schedule; // Term-wise | Monthly | Custom | whatever collection_frequency the backend returns
  final String howPaid;
  final double annual;
  const FeeRow({required this.type, required this.schedule, this.howPaid = 'From config', required this.annual});
}

const _scheduleBadge = {
  'Term-wise': (bg: Color(0xFFDCFCE7), color: Color(0xFF15803D), border: Color(0xFF86EFAC)),
  'Monthly': (bg: Color(0xFFFEF3C7), color: Color(0xFFD97706), border: Color(0xFFFDE68A)),
  'Custom': (bg: Color(0xFFFEE2E2), color: Color(0xFFDC2626), border: Color(0xFFFCA5A5)),
};

/// Mirrors `parseConcessionPct` — extracts a "NN%" substring, or 1.0 for any
/// label containing "full" (case-insensitive), else 0.
double parseConcessionPct(String concession) {
  final m = RegExp(r'(\d+(\.\d+)?)\s*%').firstMatch(concession);
  if (m != null) return double.parse(m.group(1)!) / 100;
  if (RegExp('full', caseSensitive: false).hasMatch(concession)) return 1;
  return 0;
}

/// Mirrors `FeeScheduleTable` — shared by the Assign and Edit Assignment
/// modals: a Fee Group / Concession selector pair plus a read-only preview
/// of that group's fee schedule (from Fee Configuration), with concession
/// discount applied live.
class FeeScheduleTable extends StatelessWidget {
  final String group;
  final String concession;
  final ValueChanged<String> onGroupChange;
  final ValueChanged<String> onConcessionChange;
  final Map<String, List<FeeRow>> feeSchedules;
  final List<String> concessions;
  final List<FeesGroup> groups;

  const FeeScheduleTable({
    super.key,
    required this.group,
    required this.concession,
    required this.onGroupChange,
    required this.onConcessionChange,
    required this.feeSchedules,
    required this.concessions,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final rows = feeSchedules[group] ?? const <FeeRow>[];
    final pct = parseConcessionPct(concession);
    final total = rows.fold<double>(0, (s, r) => s + r.annual * (1 - pct));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _select('FEE GROUP', group, groups.map((g) => g.name).toList(), onGroupChange)),
              const SizedBox(width: 14),
              Expanded(child: _select('CONCESSION', concession, concessions, onConcessionChange)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(border: Border.all(color: faBorder), borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: const Color(0xFFF8F8FB),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('FEE SCHEDULE — ${group.toUpperCase()}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: faInk1, letterSpacing: 0.5)),
                      ),
                      const Text('Defined in Fee Configuration · read-only', style: TextStyle(fontSize: 10.5, color: faInk3)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: const Color(0xFFFAFAFA),
                  child: const Row(
                    children: [
                      Expanded(flex: 16, child: Text('Fee Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: faInk3))),
                      Expanded(flex: 10, child: Text('Payment Schedule', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: faInk3))),
                      Expanded(flex: 14, child: Text("How it's paid", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: faInk3))),
                      SizedBox(width: 66, child: Text('Annual Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: faInk3), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                    child: Center(child: Text('No fee schedule configured for this group yet.', style: TextStyle(color: faInk3, fontSize: 12.5))),
                  )
                else
                  for (var i = 0; i < rows.length; i++) _feeRow(rows[i], i < rows.length - 1, pct),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: const BoxDecoration(color: Color(0xFFF8F8FB), border: Border(top: BorderSide(color: faBorder, width: 2))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Annual fees for this group', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: faInk1)),
                      Text(fmtInr(total), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: faInk1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Each fee type's payment schedule is set in Fee Configuration. To customise a schedule for this student, use the Enroll Student tab → Step 11.",
            style: TextStyle(fontSize: 11.5, color: faInk3, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(FeeRow row, bool hasDivider, double pct) {
    final badge = _scheduleBadge[row.schedule] ?? (bg: Colors.white, color: Colors.black, border: const Color(0xFFCCCCCC));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: hasDivider ? const BorderSide(color: Color(0xFFF0F0F0)) : BorderSide.none),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 16, child: Text(row.type, style: const TextStyle(fontSize: 12.5, color: faInk1))),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: badge.border)),
                child: Text(row.schedule, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: badge.color)),
              ),
            ),
          ),
          Expanded(flex: 14, child: Text(row.howPaid, style: const TextStyle(fontSize: 12, color: faInk2))),
          SizedBox(
            width: 66,
            child: pct > 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fmtInr(row.annual), style: const TextStyle(fontSize: 11, color: faInk3, decoration: TextDecoration.lineThrough)),
                      Text(fmtInr(row.annual * (1 - pct)), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: faInk1)),
                    ],
                  )
                : Text(fmtInr(row.annual), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: faInk1)),
          ),
        ],
      ),
    );
  }

  Widget _select(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    final safeOptions = options.contains(value) || options.isEmpty ? options : [value, ...options];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: faInk3)),
        const SizedBox(height: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: faBorder), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeOptions.contains(value) ? value : null,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF8B8EA8)),
              style: const TextStyle(fontSize: 12.5, color: faInk1),
              items: [for (final o in safeOptions) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
