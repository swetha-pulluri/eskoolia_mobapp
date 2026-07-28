import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hr_provider.dart';
import '../hr_theme.dart';
import 'onboard_field_widgets.dart';

/// Step 10 — Review & onboard. Pure read-only summary of already-collected
/// form state — no new data is fetched or posted here (matches the real
/// web exactly; the actual create/update call happens on Submit, handled by
/// the page). `send_welcome`/`activate_attendance` are collected but never
/// read at submit time, even on the real web — kept for UI parity only.
class StepReview extends ConsumerWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepReview({super.key, required this.form, required this.onChange});

  String _s(String key) => (form[key] as String? ?? '').trim();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formOptionsAsync = ref.watch(staffFormOptionsProvider);
    final departments = formOptionsAsync.valueOrNull?.departments ?? const [];
    final designations = formOptionsAsync.valueOrNull?.designations ?? const [];
    final deptId = int.tryParse(_s('department'));
    final desigId = int.tryParse(_s('designation'));
    final deptName = departments.where((d) => d.id == deptId).map((d) => d.name).firstOrNull ?? '—';
    final desigName = fixedDesignationNameFor(desigId) ?? designations.where((d) => d.id == desigId).map((d) => d.name).firstOrNull ?? '—';
    final fullName = [_s('first_name'), _s('middle_name'), _s('last_name')].where((p) => p.isNotEmpty).join(' ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Review & onboard', 'Confirm and create'),
          _section('Personal', [
            _row('Full Name', fullName.isEmpty ? '—' : fullName),
            _row('Gender', _s('gender').isEmpty ? '—' : _s('gender')),
            _row('Date of Birth', _s('date_of_birth').isEmpty ? '—' : _s('date_of_birth')),
            _row('Mobile', _s('mobile').isEmpty ? '—' : _s('mobile')),
            _row('Personal Email', _s('personal_email').isEmpty ? '—' : _s('personal_email')),
            _row('Nationality', _s('nationality').isEmpty ? '—' : _s('nationality')),
          ]),
          _section('Employment', [
            _row('Department', deptName),
            _row('Designation', desigName),
            _row('Employment Type', _s('employment_type').isEmpty ? _s('employment_type_other') : _s('employment_type')),
            _row('Joining Date', _s('joining_date').isEmpty ? '—' : _s('joining_date')),
            _row('Basic Salary', _s('basic_salary_input').isEmpty ? '—' : '₹${_s('basic_salary_input')}'),
          ]),
          _section('Bank', [
            _row('Bank Name', _s('bank_name').isEmpty ? '—' : _s('bank_name')),
            _row('Account Number', _s('bank_account_no').isEmpty ? '—' : _s('bank_account_no')),
          ]),
          const SizedBox(height: 16),
          onboardFieldGrid([
            onboardDropdown<String>(
              label: 'Send Welcome Message Via',
              value: form['send_welcome'] as String?,
              items: const [DropdownMenuItem(value: 'email', child: Text('Email')), DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')), DropdownMenuItem(value: 'both', child: Text('Both')), DropdownMenuItem(value: 'no', child: Text('No'))],
              onChanged: (v) => onChange('send_welcome', v),
            ),
            onboardDropdown<String>(
              label: 'Activate Attendance',
              value: form['activate_attendance'] as String?,
              items: const [DropdownMenuItem(value: 'immediately', child: Text('Immediately')), DropdownMenuItem(value: 'from_joining', child: Text('From joining date')), DropdownMenuItem(value: 'manually', child: Text('Manually'))],
              onChanged: (v) => onChange('activate_attendance', v),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E8EE)), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1, color: HrColors.muted)),
        const SizedBox(height: 8),
        ...rows,
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: HrColors.muted)),
        Flexible(child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: HrColors.ink))),
      ]),
    );
  }
}
