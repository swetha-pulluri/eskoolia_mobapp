import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/ifsc_lookup.dart';
import '../hr_theme.dart';
import 'onboard_field_widgets.dart';

/// Step 5 — Government identity. Real fields: `nin` (Aadhaar)/`pan`/
/// `passport_no`/`driving_licence`/`uan`/`esi_no`/`pt_registration`,
/// `ifsc_code`/`bank_account_no`/`bank_name`/`bank_branch`/`bank_city`/
/// `bank_state`/`bank_account_name`. IFSC lookup hits the same real
/// `ifsc.razorpay.com` API the existing Staff form uses (shared helper),
/// auto-filling and locking bank name/branch on success.
class StepGovId extends ConsumerStatefulWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepGovId({super.key, required this.form, required this.onChange});

  @override
  ConsumerState<StepGovId> createState() => _StepGovIdState();
}

class _StepGovIdState extends ConsumerState<StepGovId> {
  bool _ifscLoading = false;
  bool _ifscAutoFilled = false;
  String? _ifscError;

  Future<void> _onIfscChanged(String value) async {
    final normalized = value.trim().toUpperCase();
    widget.onChange('ifsc_code', normalized);
    setState(() {
      _ifscError = null;
      _ifscAutoFilled = false;
    });
    if (!isValidIfscFormat(normalized)) return;
    setState(() => _ifscLoading = true);
    final result = await lookupIfsc(normalized);
    if (!mounted) return;
    setState(() {
      _ifscLoading = false;
      if (result != null && !result.isEmpty) {
        _ifscAutoFilled = true;
        if (result.bankName.isNotEmpty) widget.onChange('bank_name', result.bankName);
        if (result.branch.isNotEmpty) widget.onChange('bank_branch', result.branch);
      } else {
        _ifscError = 'Could not auto-fill bank details for this IFSC.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Government identity', 'Aadhaar, PAN, etc.'),
          onboardSectionLabel('Identity documents'),
          onboardFieldGrid([
            onboardText(label: 'Aadhaar Number', required: true, value: form['nin'] as String? ?? '', keyboardType: TextInputType.number, maxLength: 12, onChanged: (v) => widget.onChange('nin', v)),
            onboardText(label: 'PAN Number', required: true, value: form['pan'] as String? ?? '', textCapitalization: TextCapitalization.characters, maxLength: 10, onChanged: (v) => widget.onChange('pan', v.toUpperCase())),
            onboardText(label: 'Passport Number', value: form['passport_no'] as String? ?? '', textCapitalization: TextCapitalization.characters, onChanged: (v) => widget.onChange('passport_no', v.toUpperCase())),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardText(label: 'Driving Licence', value: form['driving_licence'] as String? ?? '', textCapitalization: TextCapitalization.characters, onChanged: (v) => widget.onChange('driving_licence', v.toUpperCase())),
            onboardText(label: 'UAN (PF)', value: form['uan'] as String? ?? '', keyboardType: TextInputType.number, maxLength: 12, onChanged: (v) => widget.onChange('uan', v)),
            onboardText(label: 'ESI Number', value: form['esi_no'] as String? ?? '', keyboardType: TextInputType.number, maxLength: 17, onChanged: (v) => widget.onChange('esi_no', v)),
            onboardText(label: 'PT Registration', value: form['pt_registration'] as String? ?? '', onChanged: (v) => widget.onChange('pt_registration', v)),
          ]),
          const SizedBox(height: 20),
          onboardSectionLabel('Bank details'),
          onboardFieldGrid([
            onboardText(
              label: 'IFSC Code',
              required: true,
              value: form['ifsc_code'] as String? ?? '',
              textCapitalization: TextCapitalization.characters,
              maxLength: 11,
              error: _ifscError,
              hint: _ifscLoading ? 'Looking up…' : null,
              onChanged: _onIfscChanged,
            ),
            onboardText(label: 'Account Number', required: true, value: form['bank_account_no'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => widget.onChange('bank_account_no', v)),
            onboardText(label: 'Account Holder Name', required: true, value: form['bank_account_name'] as String? ?? '', onChanged: (v) => widget.onChange('bank_account_name', v)),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            _lockable('Bank Name', 'bank_name', form, _ifscAutoFilled),
            _lockable('Branch', 'bank_branch', form, _ifscAutoFilled),
            _lockable('City', 'bank_city', form, true),
            _lockable('State', 'bank_state', form, true),
          ]),
        ],
      ),
    );
  }

  Widget _lockable(String label, String key, Map<String, dynamic> form, bool locked) {
    return HrField(
      label: label,
      child: TextFormField(
        initialValue: form[key] as String? ?? '',
        enabled: !locked,
        onChanged: locked ? null : (v) => widget.onChange(key, v),
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
      ),
    );
  }
}
