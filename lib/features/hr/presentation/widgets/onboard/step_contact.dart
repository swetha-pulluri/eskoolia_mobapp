import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hr_provider.dart';
import 'onboard_field_widgets.dart';

const _preferredCommOptions = [
  ('mobile', 'Mobile'),
  ('whatsapp', 'WhatsApp'),
  ('personal_email', 'Personal Email'),
  ('official_email', 'Official Email'),
];

/// Step 3 — Contact & address. Real fields: `mobile`/`alternate_mobile`/
/// `whatsapp`, `official_email`/`personal_email`, `preferred_communication`,
/// `current_address`/`current_address_line2`/`city`/`state`/`current_pin`/
/// `current_country`, `permanent_*` (mirror set). PIN lookup hits the real
/// `GET /api/v1/core/pincode-lookup/?pincode=` proxy and auto-fills
/// city/state/country, matching the web exactly.
class StepContact extends ConsumerStatefulWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepContact({super.key, required this.form, required this.onChange});

  @override
  ConsumerState<StepContact> createState() => _StepContactState();
}

class _StepContactState extends ConsumerState<StepContact> {
  bool _pinLoading = false;
  String? _pinError;

  Future<void> _lookupPincode(String pin) async {
    if (!RegExp(r'^\d{5,6}$').hasMatch(pin)) return;
    setState(() {
      _pinLoading = true;
      _pinError = null;
    });
    try {
      final result = await ref.read(hrRepositoryProvider).lookupPincode(pin);
      widget.onChange('city', result.city);
      widget.onChange('state', result.state);
      widget.onChange('current_country', result.country);
    } catch (_) {
      if (mounted) setState(() => _pinError = 'Could not look up this PIN code.');
    } finally {
      if (mounted) setState(() => _pinLoading = false);
    }
  }

  void _syncPermanentFromCurrent() {
    widget.onChange('permanent_address', widget.form['current_address'] ?? '');
    widget.onChange('permanent_city', widget.form['city'] ?? '');
    widget.onChange('permanent_state', widget.form['state'] ?? '');
    widget.onChange('permanent_pin', widget.form['current_pin'] ?? '');
    widget.onChange('permanent_country', widget.form['current_country'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final sameAddress = form['same_address'] == 'true';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Contact & address', 'Phone, email, location'),
          onboardFieldGrid([
            onboardText(label: 'Mobile', required: true, value: form['mobile'] as String? ?? '', keyboardType: TextInputType.phone, maxLength: 10, onChanged: (v) => widget.onChange('mobile', v)),
            onboardText(label: 'Alternate Mobile', value: form['alternate_mobile'] as String? ?? '', keyboardType: TextInputType.phone, maxLength: 10, onChanged: (v) => widget.onChange('alternate_mobile', v)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              onboardText(label: 'WhatsApp', value: form['whatsapp'] as String? ?? '', keyboardType: TextInputType.phone, maxLength: 10, onChanged: (v) => widget.onChange('whatsapp', v)),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Same as mobile', style: TextStyle(fontSize: 12)),
                value: form['whatsapp'] == form['mobile'] && (form['mobile'] as String? ?? '').isNotEmpty,
                onChanged: (v) => widget.onChange('whatsapp', v == true ? (form['mobile'] ?? '') : ''),
              ),
            ]),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardText(label: 'Official Email', value: form['official_email'] as String? ?? '', keyboardType: TextInputType.emailAddress, onChanged: (v) => widget.onChange('official_email', v)),
            onboardText(label: 'Personal Email', required: true, value: form['personal_email'] as String? ?? '', keyboardType: TextInputType.emailAddress, onChanged: (v) => widget.onChange('personal_email', v)),
            onboardDropdown<String>(
              label: 'Preferred Communication',
              required: true,
              value: form['preferred_communication'] as String?,
              items: [for (final (value, label) in _preferredCommOptions) DropdownMenuItem(value: value, child: Text(label))],
              onChanged: (v) => widget.onChange('preferred_communication', v),
            ),
          ]),
          const SizedBox(height: 20),
          onboardSectionLabel('Current address'),
          onboardFieldGrid([
            onboardText(label: 'Address Line 1', required: true, value: form['current_address'] as String? ?? '', maxLength: 150, onChanged: (v) => widget.onChange('current_address', v)),
            onboardText(label: 'Address Line 2', value: form['current_address_line2'] as String? ?? '', maxLength: 100, onChanged: (v) => widget.onChange('current_address_line2', v)),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardText(
              label: 'PIN Code',
              required: true,
              value: form['current_pin'] as String? ?? '',
              keyboardType: TextInputType.number,
              maxLength: 6,
              error: _pinError,
              hint: _pinLoading ? 'Looking up…' : null,
              onChanged: (v) {
                widget.onChange('current_pin', v);
                _lookupPincode(v.trim());
              },
            ),
            onboardText(label: 'City', required: true, value: form['city'] as String? ?? '', onChanged: (v) => widget.onChange('city', v)),
            onboardText(label: 'State', required: true, value: form['state'] as String? ?? '', onChanged: (v) => widget.onChange('state', v)),
            onboardText(label: 'Country', value: form['current_country'] as String? ?? 'India', onChanged: (v) => widget.onChange('current_country', v)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: onboardSectionLabel('Permanent address')),
            Checkbox(
              value: sameAddress,
              onChanged: (v) {
                widget.onChange('same_address', v == true ? 'true' : 'false');
                if (v == true) _syncPermanentFromCurrent();
              },
            ),
            // `Flexible` — this label plus the checkbox is wide enough to
            // overflow the Row on a 320-360dp phone even with the section
            // label `Expanded` (the label can shrink to 0 and it still
            // wouldn't be enough).
            const Flexible(
              child: Text('Same as current address', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
            ),
          ]),
          onboardFieldGrid([
            onboardText(label: 'Address Line 1', value: sameAddress ? (form['current_address'] as String? ?? '') : (form['permanent_address'] as String? ?? ''), onChanged: sameAddress ? (_) {} : (v) => widget.onChange('permanent_address', v)),
            onboardText(label: 'PIN Code', value: sameAddress ? (form['current_pin'] as String? ?? '') : (form['permanent_pin'] as String? ?? ''), keyboardType: TextInputType.number, maxLength: 6, onChanged: sameAddress ? (_) {} : (v) => widget.onChange('permanent_pin', v)),
            onboardText(label: 'City', value: sameAddress ? (form['city'] as String? ?? '') : (form['permanent_city'] as String? ?? ''), onChanged: sameAddress ? (_) {} : (v) => widget.onChange('permanent_city', v)),
            onboardText(label: 'State', value: sameAddress ? (form['state'] as String? ?? '') : (form['permanent_state'] as String? ?? ''), onChanged: sameAddress ? (_) {} : (v) => widget.onChange('permanent_state', v)),
          ]),
        ],
      ),
    );
  }
}
