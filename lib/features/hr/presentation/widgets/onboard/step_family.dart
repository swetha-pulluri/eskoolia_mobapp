import 'package:flutter/material.dart';
import 'onboard_field_widgets.dart';

const _maritalStatuses = ['Single', 'Married', 'Widowed', 'Divorced'];

/// Step 4 — Family & emergency. Real fields: `marital_status`, `num_children`
/// + `spouse_parent_name` (only relevant when not Single; spouse name
/// required if Married), `emergency_contacts` (repeatable list, name/
/// relationship/mobile required on row 0 only — matches the real form's own
/// legacy-flat-key behavior), `nominees` (repeatable list, share% must sum
/// to 100 across all rows).
class StepFamily extends StatelessWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepFamily({super.key, required this.form, required this.onChange});

  List<Map<String, dynamic>> _list(String key) => ((form[key] as List?) ?? const []).cast<Map<String, dynamic>>();

  void _setList(String key, List<Map<String, dynamic>> list) => onChange(key, list);

  @override
  Widget build(BuildContext context) {
    final maritalStatus = form['marital_status'] as String? ?? '';
    final isSingle = maritalStatus == 'Single' || maritalStatus.isEmpty;
    final emergencyContacts = _list('emergency_contacts');
    final nominees = _list('nominees');
    final totalShare = nominees.fold<double>(0, (sum, n) => sum + (double.tryParse(n['share']?.toString() ?? '0') ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Family & emergency', 'Nominees and contacts'),
          onboardFieldGrid([
            onboardDropdown<String>(
              label: 'Marital Status',
              value: maritalStatus.isEmpty ? null : maritalStatus,
              items: [for (final m in _maritalStatuses) DropdownMenuItem(value: m, child: Text(m))],
              onChanged: (v) {
                onChange('marital_status', v ?? '');
                if (v == 'Single') {
                  onChange('num_children', '');
                  onChange('spouse_parent_name', '');
                }
              },
            ),
            if (!isSingle) onboardText(label: 'Number of Children', value: form['num_children'] as String? ?? '', keyboardType: TextInputType.number, maxLength: 2, onChanged: (v) => onChange('num_children', v)),
            if (!isSingle)
              onboardText(
                label: maritalStatus == 'Married' ? 'Spouse Name' : 'Spouse/Parent Name',
                required: maritalStatus == 'Married',
                value: form['spouse_parent_name'] as String? ?? '',
                onChanged: (v) => onChange('spouse_parent_name', v),
              ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: onboardSectionLabel('Emergency contacts')),
            TextButton.icon(
              onPressed: () => _setList('emergency_contacts', [...emergencyContacts, <String, dynamic>{}]),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add contact'),
            ),
          ]),
          if (emergencyContacts.isEmpty) _emptyHint('No emergency contacts added yet.'),
          for (var i = 0; i < emergencyContacts.length; i++) _emergencyContactRow(context, i, emergencyContacts),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: onboardSectionLabel('Nominees')),
            TextButton.icon(
              onPressed: () => _setList('nominees', [...nominees, <String, dynamic>{}]),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add nominee'),
            ),
          ]),
          if (nominees.isEmpty) _emptyHint('No nominees added yet.'),
          for (var i = 0; i < nominees.length; i++) _nomineeRow(context, i, nominees),
          if (nominees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Total share: ${totalShare.toStringAsFixed(0)}% ${(totalShare - 100).abs() > 0.01 ? '(must equal 100%)' : '✓'}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: (totalShare - 100).abs() > 0.01 ? const Color(0xFFE0463A) : const Color(0xFF16A34A)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))));

  Widget _emergencyContactRow(BuildContext context, int index, List<Map<String, dynamic>> rows) {
    final row = rows[index];
    void update(String key, String value) {
      final next = [...rows];
      next[index] = {...row, key: value};
      _setList('emergency_contacts', next);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E8EE)), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Contact ${index + 1}${index == 0 ? ' (required)' : ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => _setList('emergency_contacts', [for (var i = 0; i < rows.length; i++) if (i != index) rows[i]]),
          ),
        ]),
        onboardFieldGrid([
          onboardText(label: 'Name', required: index == 0, value: row['name'] as String? ?? '', onChanged: (v) => update('name', v)),
          onboardText(label: 'Relationship', required: index == 0, value: row['relationship'] as String? ?? '', onChanged: (v) => update('relationship', v)),
          onboardText(label: 'Mobile', required: index == 0, value: row['mobile'] as String? ?? '', keyboardType: TextInputType.phone, maxLength: 10, onChanged: (v) => update('mobile', v)),
          onboardText(label: 'Alt Mobile', value: row['alt_mobile'] as String? ?? '', keyboardType: TextInputType.phone, maxLength: 10, onChanged: (v) => update('alt_mobile', v)),
          onboardText(label: 'Email', value: row['email'] as String? ?? '', keyboardType: TextInputType.emailAddress, onChanged: (v) => update('email', v)),
        ], minFieldWidth: 180),
      ]),
    );
  }

  Widget _nomineeRow(BuildContext context, int index, List<Map<String, dynamic>> rows) {
    final row = rows[index];
    void update(String key, String value) {
      final next = [...rows];
      next[index] = {...row, key: value};
      _setList('nominees', next);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E8EE)), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: onboardText(label: 'Name', required: true, value: row['name'] as String? ?? '', onChanged: (v) => update('name', v))),
        const SizedBox(width: 10),
        Expanded(child: onboardText(label: 'Relationship', value: row['relationship'] as String? ?? '', onChanged: (v) => update('relationship', v))),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: onboardText(label: 'Share %', value: row['share'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => update('share', v))),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: rows.length > 1 ? () => _setList('nominees', [for (var i = 0; i < rows.length; i++) if (i != index) rows[i]]) : null,
        ),
      ]),
    );
  }
}
