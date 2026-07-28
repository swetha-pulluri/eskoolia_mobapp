import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/year_end_fee_amount_row.dart';
import '../providers/fees_year_end_providers.dart';
import '../utils/fee_assignment_format.dart' show groupIndian;
import 'fees_year_end_styles.dart';

const _scheduleLabels = {
  'term_wise': 'Term-wise',
  'monthly': 'Monthly',
  'quarterly': 'Quarterly',
  'half_yearly': 'Half-yearly',
  'yearly': 'Yearly',
  'one_time': 'One-time',
};

({Color bg, Color fg}) _scheduleStyle(String scheduleType) {
  if (scheduleType == 'term_wise') return (bg: const Color(0xFFEDE9FE), fg: const Color(0xFF7C3AED));
  if (scheduleType == 'monthly') return (bg: const Color(0xFFE0F2FE), fg: const Color(0xFF0369A1));
  return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFD97706));
}

/// "Edit Fee Amounts" modal (Year-End screen's Archive & Rollover wizard,
/// step 3 → "Edit Amounts") — mirrors YearEndPage.tsx's `editModal` block
/// exactly: a % hike quick-apply box plus a per-fee-type table with a live
/// CURRENT → NEW % change column.
class FyEditAmountsDialog extends ConsumerStatefulWidget {
  final int groupId;
  final String groupName;
  final void Function(String message) onToast;

  const FyEditAmountsDialog({super.key, required this.groupId, required this.groupName, required this.onToast});

  static Future<void> show(BuildContext context, {required int groupId, required String groupName, required void Function(String) onToast}) {
    return showDialog(
      context: context,
      barrierColor: const Color(0x6B000000), // rgba(0,0,0,0.42)
      builder: (_) => FyEditAmountsDialog(groupId: groupId, groupName: groupName, onToast: onToast),
    );
  }

  @override
  ConsumerState<FyEditAmountsDialog> createState() => _FyEditAmountsDialogState();
}

class _FyEditAmountsDialogState extends ConsumerState<FyEditAmountsDialog> {
  List<YearEndFeeAmountRow> _rows = [];
  bool _loading = true;
  bool _saving = false;
  final _hikeCtrl = TextEditingController();
  final Map<int, TextEditingController> _amountCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _hikeCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(YearEndFeeAmountRow row) {
    return _amountCtrls.putIfAbsent(row.id, () => TextEditingController(text: row.newAmount));
  }

  Future<void> _loadRows() async {
    try {
      final rows = await ref.read(feesYearEndRepositoryProvider).fetchGroupAmounts(widget.groupId);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      widget.onToast('Failed to load fee types.');
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _updateRow(int id, String value) {
    setState(() => _rows = [for (final r in _rows) r.id == id ? r.copyWith(newAmount: value) : r]);
  }

  void _applyHike() {
    final pct = double.tryParse(_hikeCtrl.text);
    if (pct == null) {
      widget.onToast('Enter a valid percentage.');
      return;
    }
    setState(() {
      _rows = [
        for (final r in _rows)
          r.copyWith(newAmount: ((double.tryParse(r.currentTotal) ?? 0) * (1 + pct / 100)).round().toString())
      ];
      for (final r in _rows) {
        _ctrlFor(r).text = r.newAmount;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(feesYearEndRepositoryProvider).saveGroupAmounts(widget.groupId, _rows);
      widget.onToast('New amounts staged for ${widget.groupName}.');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      widget.onToast('Failed to save amounts.');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 780, maxHeight: MediaQuery.of(context).size.height * 0.88),
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
                            Text('Edit Fee Amounts — ${widget.groupName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fyInk1)),
                            const SizedBox(height: 3),
                            const Text('New-year (2026-27) amounts. Changes are staged and applied when rollover executes.', style: TextStyle(fontSize: 13, color: fyInk3)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                          child: const Text('×', style: TextStyle(fontSize: 18, color: Color(0xFF6B7280), height: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: fyBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(color: fyPurpleTint, border: Border.all(color: fyPurpleBorder), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fyPurple)),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _hikeCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 10',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fyPurpleBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fyPurpleBorder)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fyPurple)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  const Text('% hike to all amounts', style: TextStyle(fontSize: 13, color: fyPurple, fontWeight: FontWeight.w500)),
                                  ElevatedButton(
                                    onPressed: _applyHike,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: fyPurple,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: const Size(0, 32),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    child: const Text('Apply →'),
                                  ),
                                  const Text('Quick shortcut — you can still edit individual rows below', style: TextStyle(fontSize: 12, color: fyInk3)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('Loading fee types…', style: TextStyle(fontSize: 14, color: fyInk3))),
                          )
                        else if (_rows.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('No fee types found for this group.', style: TextStyle(fontSize: 14, color: fyInk3))),
                          )
                        else
                          _feeTypesTable(),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: fyBorder))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: fyInk1,
                          elevation: 0,
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: fyBorder, width: 1.5)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _saving ? null : const [BoxShadow(color: Color(0x4D6D4AFF), blurRadius: 10, offset: Offset(0, 2))],
                        ),
                        child: ElevatedButton(
                          onPressed: (_saving || _loading) ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fyPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: fyPurple.withValues(alpha: 0.7),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          child: Text(_saving ? 'Saving…' : 'Save Amounts for ${widget.groupName}'),
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

  Widget _feeTypesTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(3.0),
        2: FlexColumnWidth(1.6),
        3: FlexColumnWidth(2.0),
        4: FlexColumnWidth(1.2),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text('FEE TYPE', style: fyThStyle)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text('CURRENT BREAKDOWN', style: fyThStyle)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text('CURRENT TOTAL', style: fyThStyle)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text('NEW AMOUNT (2026-27)', style: fyThStyle)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text('CHANGE', style: fyThStyle, textAlign: TextAlign.center)),
          ],
        ),
        for (var i = 0; i < _rows.length; i++) _rowTableRow(_rows[i], i < _rows.length - 1),
      ],
    );
  }

  TableRow _rowTableRow(YearEndFeeAmountRow row, bool hasDivider) {
    final current = double.tryParse(row.currentTotal) ?? 0;
    final newAmt = double.tryParse(row.newAmount) ?? 0;
    final diff = current > 0 ? ((newAmt - current) / current) * 100 : null;
    final changeLabel = (diff == null || newAmt == current) ? '—' : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}%';
    final changeColor = (diff == null || diff == 0) ? fyInk3 : (diff > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626));
    final schedule = _scheduleStyle(row.scheduleType);
    final decoration = BoxDecoration(border: Border(bottom: hasDivider ? const BorderSide(color: fyBorder) : BorderSide.none));

    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: decoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(row.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: row.isDeleted ? const Color(0xFF9CA3AF) : fyInk1)),
                  if (row.isDeleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                      child: const Text('Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: schedule.bg, borderRadius: BorderRadius.circular(20)),
                child: Text(_scheduleLabels[row.scheduleType] ?? 'Custom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: schedule.fg)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: decoration,
          alignment: Alignment.centerLeft,
          child: Text(row.breakdown, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: decoration,
          alignment: Alignment.centerLeft,
          child: Text('₹${groupIndian(current.round().toString())}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fyInk1)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: decoration,
          child: TextField(
            controller: _ctrlFor(row),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => _updateRow(row.id, v),
            decoration: fyFieldDecoration(),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: decoration,
          alignment: Alignment.center,
          child: Text(changeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: changeColor)),
        ),
      ],
    );
  }
}
