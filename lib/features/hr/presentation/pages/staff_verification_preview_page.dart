import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';
import '../widgets/hr_theme.dart';
import '../widgets/onboard/onboard_field_widgets.dart';

/// A new, standalone in-app preview screen for the Onboarding Wizard's "PDF"
/// action — this exact screen does not exist anywhere in the real web
/// frontend or backend (confirmed via an exhaustive search across every
/// branch), so it's a fresh Flutter design rather than a web port. It shows
/// the wizard's own already-collected real data (never invented), grouped
/// into the same sections the real backend's reportlab PDF generator uses
/// (`apps/hr/views.py`'s `_section("1. Personal Identity")` etc.). Print and
/// Save PDF both hand off to the real `/api/v1/hr/onboard/filled-form/`
/// PDF — this screen is a nicer reading view of the same real data, not a
/// replacement generator.
class StaffVerificationPreviewPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> form;

  const StaffVerificationPreviewPage({super.key, required this.form});

  @override
  ConsumerState<StaffVerificationPreviewPage> createState() => _StaffVerificationPreviewPageState();
}

class _StaffVerificationPreviewPageState extends ConsumerState<StaffVerificationPreviewPage> {
  bool _showHeader = true;
  bool _working = false;

  String _s(String key) {
    final v = widget.form[key];
    if (v == null) return '';
    return v.toString();
  }

  String _v(String key) {
    final val = _s(key).trim();
    return val.isEmpty ? '—' : val;
  }

  Future<List<int>> _getPdfBytes() {
    return ref.read(hrRepositoryProvider).downloadFilledForm(widget.form);
  }

  Future<void> _print() async {
    setState(() => _working = true);
    try {
      final bytes = await _getPdfBytes();
      await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes));
    } catch (e) {
      if (mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to print.', type: 'error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _savePdf() async {
    setState(() => _working = true);
    try {
      final bytes = await _getPdfBytes();
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), name: 'staff-verification-form.pdf', mimeType: 'application/pdf')]);
    } catch (e) {
      if (mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to save PDF.', type: 'error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _stub(String message) => showHrToast(context, message, type: 'info');

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final formOptionsAsync = ref.watch(staffFormOptionsProvider);
    final rolesAsync = ref.watch(rolesProvider);
    final departments = formOptionsAsync.valueOrNull?.departments ?? const [];
    final designations = formOptionsAsync.valueOrNull?.designations ?? const [];
    final roles = rolesAsync.valueOrNull ?? const [];

    String lookup(String formKey, List<dynamic> options) {
      final id = int.tryParse(_s(formKey));
      if (id == null) return '—';
      final match = options.where((o) => o.id == id).map((o) => o.name as String).firstOrNull;
      return match ?? '—';
    }

    final fullName = [_s('first_name'), _s('middle_name'), _s('last_name')].where((p) => p.trim().isNotEmpty).join(' ');
    final qualifications = (form['qualifications'] as List?) ?? const [];
    final previousEmployment = (form['previous_employment'] as List?) ?? const [];
    final emergencyContacts = (form['emergency_contacts'] as List?) ?? const [];
    final row0 = emergencyContacts.isNotEmpty ? emergencyContacts.first as Map : const {};

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          _buildToolbar(context),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_showHeader) ...[
                  Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: const Color(0xFFFDE9D9), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Text('🏫', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'Your School',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: HrColors.ink),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                ],
                Center(
                  child: Column(children: [
                    const Text('STAFF VERIFICATION FORM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1, color: HrColors.ink)),
                    const SizedBox(height: 6),
                    const Text('Please verify all details. Contact HR if any information is incorrect.', style: TextStyle(fontSize: 13, color: HrColors.muted), textAlign: TextAlign.center),
                  ]),
                ),
                const SizedBox(height: 24),
                _section('1. Personal Identity', [
                  _photoAndRows([
                    ('Full Name', fullName.isEmpty ? '—' : fullName),
                    ('Staff Code', _v('staff_no')),
                    ('Date of Birth', _v('date_of_birth')),
                    ('Gender', _v('gender')),
                    ('Blood Group', _v('blood_group_input')),
                    ('Mother Tongue', _v('mother_tongue')),
                    ('Religion', _v('religion')),
                    ('Nationality', _v('nationality')),
                    ('Status', _v('status')),
                  ]),
                ]),
                _section('2. Role & Employment', [
                  _rows([
                    ('Department', lookup('department', departments)),
                    ('Designation', fixedDesignationNameFor(int.tryParse(_s('designation'))) ?? lookup('designation', designations)),
                    ('Role', lookup('role', roles)),
                    ('Joining Date', _v('joining_date')),
                    ('Employment Type', _v('employment_type')),
                    ('Reporting Manager', '—'),
                    ('Probation Period', form['probation_value'] != null && _s('probation_value').isNotEmpty ? '${_s('probation_value')} ${_s('probation_unit').isEmpty ? 'months' : _s('probation_unit')}' : '—'),
                  ]),
                ]),
                _section('3. Contact & Address', [
                  _rows([
                    ('Mobile', _v('mobile')),
                    ('WhatsApp', _v('whatsapp')),
                    ('Personal Email', _v('personal_email')),
                    ('Official Email', _v('official_email')),
                    ('Preferred Communication', _v('preferred_communication')),
                    ('Current Address', _v('current_address')),
                    ('City', _v('city')),
                    ('State', _v('state')),
                    ('PIN Code', _v('current_pin')),
                  ]),
                ]),
                _section('4. Family & Emergency', [
                  _rows([
                    ('Marital Status', _v('marital_status')),
                    ('No. of Children', _v('num_children')),
                    ('Spouse / Parent Name', _v('spouse_parent_name')),
                    ('Emergency Contact', (row0['name'] as String?)?.isNotEmpty == true ? row0['name'] as String : '—'),
                    ('Relationship', (row0['relationship'] as String?)?.isNotEmpty == true ? row0['relationship'] as String : '—'),
                    ('Emergency Mobile', (row0['mobile'] as String?)?.isNotEmpty == true ? row0['mobile'] as String : '—'),
                  ]),
                ]),
                _section('5. Government Identity', [
                  _rows([
                    ('Aadhaar Number', _v('nin')),
                    ('PAN Number', _v('pan')),
                    ('Passport Number', _v('passport_no')),
                    ('Driving Licence', _v('driving_licence')),
                    ('UAN', _v('uan')),
                    ('ESI Number', _v('esi_no')),
                    ('IFSC Code', _v('ifsc_code')),
                    ('Bank Account No.', _v('bank_account_no')),
                    ('Bank Name', _v('bank_name')),
                    ('Account Holder Name', _v('bank_account_name')),
                  ]),
                ]),
                _section('6. Qualifications & Experience', [
                  _rows([
                    ('Qualifications', qualifications.isEmpty ? '—' : '${qualifications.length} added'),
                    ('B.Ed Registration No.', _v('bed_reg_no')),
                    ('CTET Score', _v('ctet_score')),
                    ('Previous Employment', previousEmployment.isEmpty ? '—' : '${previousEmployment.length} added'),
                  ]),
                ]),
                _section('7. Medical & Fitness', [
                  _rows([
                    ('Medical Certificate No.', _v('med_cert_no')),
                    ('Exam Date', _v('med_exam_date')),
                    ('Certificate Valid Till', _v('cert_valid_till')),
                    ('Disability Status', _v('disability_status')),
                  ]),
                ]),
                _section('8. Payroll', [
                  _rows([
                    ('Basic Salary', form['basic_salary_input'] != null && _s('basic_salary_input').isNotEmpty ? '₹${_s('basic_salary_input')}' : '—'),
                    ('HRA', _v('hra_input')),
                    ('DA', _v('da_input')),
                    ('Travel Allowance', _v('travel_allowance_input')),
                    ('Medical Allowance', _v('medical_allowance_input')),
                  ]),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18, color: HrColors.ink),
            label: const Text('Close', style: TextStyle(color: HrColors.ink, fontWeight: FontWeight.w700)),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton.icon(
                onPressed: () => _stub('AI Assist coming soon'),
                icon: const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                label: const Text('AI Assist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showHeader = !_showHeader),
              icon: const Icon(Icons.settings_outlined, size: 15),
              label: Text(_showHeader ? 'Hide Header' : 'Show Header'),
            ),
            OutlinedButton.icon(
              onPressed: _working ? null : _print,
              icon: const Icon(Icons.print_outlined, size: 15),
              label: const Text('Print'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
              onPressed: _working ? null : _savePdf,
              icon: _working
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_outlined, size: 15, color: Colors.white),
              label: const Text('Save PDF', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: HrColors.brand)),
        const SizedBox(height: 4),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Widget _rows(List<(String, String)> pairs) {
    return Column(children: [for (final (label, value) in pairs) _infoRow(label, value)]);
  }

  Widget _photoAndRows(List<(String, String)> pairs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 90,
          height: 120,
          margin: const EdgeInsets.only(right: 16, top: 4),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD8D8E4), style: BorderStyle.solid), borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: const Text('Photo', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ),
        Expanded(child: _rows(pairs)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: HrColors.ink))),
      ]),
    );
  }
}
