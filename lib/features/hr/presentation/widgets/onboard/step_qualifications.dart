import 'package:flutter/material.dart';
import 'onboard_field_widgets.dart';

const _degrees = ['10th', '12th', 'Diploma', 'B.A.', 'B.Sc.', 'B.Com.', 'B.Ed.', 'B.Tech.', 'M.A.', 'M.Sc.', 'M.Com.', 'M.Ed.', 'M.Tech.', 'Ph.D.', 'Other'];

/// Step 6 — Qualifications. Real fields: `qualifications` (repeatable:
/// Degree/University/Year of Passing/Specialisation/Percentage), `bed_reg_no`
/// / `ctet_score` / `subjects_qualified`, `previous_employment` (repeatable:
/// Employer/Designation/Experience/From/To/Last Drawn Salary — only rows
/// with an employer filled require From/To dates, per `onboard_validators`).
class StepQualifications extends StatelessWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepQualifications({super.key, required this.form, required this.onChange});

  List<Map<String, dynamic>> _list(String key) => ((form[key] as List?) ?? const []).cast<Map<String, dynamic>>();
  void _setList(String key, List<Map<String, dynamic>> list) => onChange(key, list);

  @override
  Widget build(BuildContext context) {
    final qualifications = _list('qualifications');
    final previousEmployment = _list('previous_employment');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Qualifications', 'Education and experience'),
          Row(children: [
            Expanded(child: onboardSectionLabel('Education')),
            TextButton.icon(onPressed: () => _setList('qualifications', [...qualifications, <String, dynamic>{}]), icon: const Icon(Icons.add, size: 16), label: const Text('Add qualification')),
          ]),
          for (var i = 0; i < qualifications.length; i++) _qualificationRow(i, qualifications),
          const SizedBox(height: 16),
          onboardFieldGrid([
            onboardText(label: 'B.Ed Registration No.', value: form['bed_reg_no'] as String? ?? '', onChanged: (v) => onChange('bed_reg_no', v)),
            onboardText(label: 'CTET Score', value: form['ctet_score'] as String? ?? '', onChanged: (v) => onChange('ctet_score', v)),
            onboardText(label: 'Subjects Qualified', value: form['subjects_qualified'] as String? ?? '', onChanged: (v) => onChange('subjects_qualified', v)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: onboardSectionLabel('Previous employment')),
            TextButton.icon(onPressed: () => _setList('previous_employment', [...previousEmployment, <String, dynamic>{}]), icon: const Icon(Icons.add, size: 16), label: const Text('Add employer')),
          ]),
          if (previousEmployment.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No previous employment added.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          for (var i = 0; i < previousEmployment.length; i++) _employmentRow(context, i, previousEmployment),
        ],
      ),
    );
  }

  Widget _qualificationRow(int index, List<Map<String, dynamic>> rows) {
    final row = rows[index];
    void update(String key, String value) {
      final next = [...rows];
      next[index] = {...row, key: value};
      _setList('qualifications', next);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E8EE)), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Qualification ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
          IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _setList('qualifications', [for (var i = 0; i < rows.length; i++) if (i != index) rows[i]])),
        ]),
        onboardFieldGrid([
          onboardDropdown<String>(label: 'Degree', value: row['degree'] as String?, items: [for (final d in _degrees) DropdownMenuItem(value: d, child: Text(d))], onChanged: (v) => update('degree', v ?? '')),
          onboardText(label: 'University', value: row['university'] as String? ?? '', onChanged: (v) => update('university', v)),
          onboardText(label: 'Year of Passing', value: row['year'] as String? ?? '', keyboardType: TextInputType.number, maxLength: 4, onChanged: (v) => update('year', v)),
          onboardText(label: 'Specialisation', value: row['specialisation'] as String? ?? '', onChanged: (v) => update('specialisation', v)),
          onboardText(label: 'Percentage / CGPA', value: row['percentage'] as String? ?? '', onChanged: (v) => update('percentage', v)),
        ], minFieldWidth: 180),
      ]),
    );
  }

  Widget _employmentRow(BuildContext context, int index, List<Map<String, dynamic>> rows) {
    final row = rows[index];
    void update(String key, String value) {
      final next = [...rows];
      next[index] = {...row, key: value};
      _setList('previous_employment', next);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E8EE)), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Employer ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
          IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _setList('previous_employment', [for (var i = 0; i < rows.length; i++) if (i != index) rows[i]])),
        ]),
        onboardFieldGrid([
          onboardText(label: 'Employer', value: row['employer'] as String? ?? '', onChanged: (v) => update('employer', v)),
          onboardText(label: 'Designation', value: row['designation'] as String? ?? '', onChanged: (v) => update('designation', v)),
          onboardText(label: 'Experience (yrs)', value: row['experience'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => update('experience', v)),
          onboardText(label: 'Last Drawn Salary', value: row['last_salary'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => update('last_salary', v)),
          onboardDateField(context, label: 'From Date', value: row['from_date'] as String?, onPicked: (v) => update('from_date', v)),
          onboardDateField(context, label: 'To Date', value: row['to_date'] as String?, onPicked: (v) => update('to_date', v)),
        ], minFieldWidth: 180),
      ]),
    );
  }
}
