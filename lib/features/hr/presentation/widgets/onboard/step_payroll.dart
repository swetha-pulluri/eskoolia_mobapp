import 'package:flutter/material.dart';
import '../hr_theme.dart';
import 'onboard_field_widgets.dart';

/// Step 8 — Payroll setup. Real fields: `basic_salary_input` (required),
/// `hra_input`/`da_input`/`travel_allowance_input`/`medical_allowance_input`/
/// `special_allowance_input` (each capped as a % of basic, matching the real
/// web's own caps), `custom_earnings`/`custom_deductions` (repeatable). The
/// live CTC preview is a client-side computation only (matches the web's
/// own formula exactly, including its hardcoded `tds = 0`), never submitted.
class StepPayroll extends StatelessWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepPayroll({super.key, required this.form, required this.onChange});

  double _num(String key) => double.tryParse(form[key]?.toString() ?? '') ?? 0;

  List<Map<String, dynamic>> _list(String key) => ((form[key] as List?) ?? const []).cast<Map<String, dynamic>>();
  void _setList(String key, List<Map<String, dynamic>> list) => onChange(key, list);

  double _rowsTotal(List<Map<String, dynamic>> rows) => rows.fold<double>(0, (sum, r) => sum + (double.tryParse(r['amount']?.toString() ?? '0') ?? 0));

  @override
  Widget build(BuildContext context) {
    final basic = _num('basic_salary_input');
    final hra = _num('hra_input');
    final da = _num('da_input');
    final travel = _num('travel_allowance_input');
    final medical = _num('medical_allowance_input');
    final special = _num('special_allowance_input');
    final customEarnings = _list('custom_earnings');
    final customDeductions = _list('custom_deductions');

    final gross = basic + hra + da + travel + medical + special + _rowsTotal(customEarnings);
    final pf = (basic * 0.12).round();
    final esi = gross <= 21000 ? (gross * 0.0075).round() : 0;
    final pt = gross > 15000 ? 200 : 0;
    const tds = 0;
    final totalDeductions = pf + esi + pt + tds + _rowsTotal(customDeductions);
    final netHome = gross - totalDeductions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Payroll setup', 'CTC and deductions'),
          onboardFieldGrid([
            onboardText(label: 'Basic Salary', required: true, value: form['basic_salary_input'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => onChange('basic_salary_input', v)),
            onboardText(label: 'HRA (≤50% of basic)', value: form['hra_input'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => onChange('hra_input', v)),
            onboardText(label: 'DA (≤50% of basic)', value: form['da_input'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => onChange('da_input', v)),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardText(label: 'Travel Allowance (≤25%)', value: form['travel_allowance_input'] as String? ?? '1600', keyboardType: TextInputType.number, onChanged: (v) => onChange('travel_allowance_input', v)),
            onboardText(label: 'Medical Allowance (≤20%)', value: form['medical_allowance_input'] as String? ?? '1250', keyboardType: TextInputType.number, onChanged: (v) => onChange('medical_allowance_input', v)),
            onboardText(label: 'Special Allowance', value: form['special_allowance_input'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => onChange('special_allowance_input', v)),
          ]),
          const SizedBox(height: 20),
          _rowsSection('Custom earnings', customEarnings, 'custom_earnings'),
          const SizedBox(height: 16),
          _rowsSection('Custom deductions', customDeductions, 'custom_deductions'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: HrColors.soft, border: Border.all(color: const Color(0xFFDDD6FE)), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LIVE CTC PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: HrColors.muted)),
              const SizedBox(height: 8),
              _previewRow('Gross', gross),
              _previewRow('PF (12% of basic)', -pf.toDouble()),
              _previewRow('ESI', -esi.toDouble()),
              _previewRow('Professional Tax', -pt.toDouble()),
              const Divider(height: 16),
              _previewRow('Net take-home', netHome, bold: true),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? HrColors.ink : HrColors.muted)),
        Text('₹${value.toStringAsFixed(0)}', style: TextStyle(fontSize: bold ? 18 : 13, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: bold ? HrColors.brand : HrColors.ink)),
      ]),
    );
  }

  Widget _rowsSection(String title, List<Map<String, dynamic>> rows, String key) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: onboardSectionLabel(title)),
        TextButton.icon(onPressed: () => _setList(key, [...rows, <String, dynamic>{}]), icon: const Icon(Icons.add, size: 16), label: const Text('Add row')),
      ]),
      for (var i = 0; i < rows.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: onboardText(label: 'Name', value: rows[i]['name'] as String? ?? '', onChanged: (v) => _updateRow(rows, i, key, 'name', v))),
            const SizedBox(width: 10),
            SizedBox(width: 110, child: onboardText(label: 'Amount', value: rows[i]['amount'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => _updateRow(rows, i, key, 'amount', v))),
            IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _setList(key, [for (var j = 0; j < rows.length; j++) if (j != i) rows[j]])),
          ]),
        ),
    ]);
  }

  void _updateRow(List<Map<String, dynamic>> rows, int index, String key, String field, String value) {
    final next = [...rows];
    next[index] = {...rows[index], field: value};
    _setList(key, next);
  }
}
