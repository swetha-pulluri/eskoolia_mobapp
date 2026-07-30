import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'onboard_field_widgets.dart';

/// Verbatim copy of the real web's `const DISABILITY_STATUSES = [...]`
/// (`hr/onboard/page.tsx`) — a fixed client-side vocabulary on the web too,
/// not backend-driven, so hardcoding it here matches web exactly.
const _disabilityStatuses = ['None', 'Physical disability', 'Visual impairment', 'Hearing impairment', 'Speech or language disability', 'Cognitive / learning disability', 'Multiple disabilities', 'Prefer not to say'];
const _eyeExamResults = ['Pass', 'Fail'];
const _colourBlindnessLevels = ['Normal', 'Mild', 'Moderate', 'Severe'];

/// Step 7 — Medical & fitness. Real fields: `med_cert_no`/`med_exam_date`/
/// `cert_valid_till`, `disability_status` (+ `disability_cert_no`/`_pct`/
/// `_authority` hard-required when set to anything but None),
/// `workplace_accommodations`, transport-staff block (`eye_exam_result`/
/// `colour_blindness`/`dl_medical_exam`). Medical/disability certificate
/// file pickers are intentionally local-widget-state only, never written to
/// the form or submitted — this matches a confirmed real bug in the web app
/// itself (`medCertFile`/`disabCertFile` are picked but never passed to
/// `set()`), preserved here rather than silently fixed.
class StepMedical extends StatefulWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepMedical({super.key, required this.form, required this.onChange});

  @override
  State<StepMedical> createState() => _StepMedicalState();
}

class _StepMedicalState extends State<StepMedical> {
  String? _medCertFileName;
  String? _disabCertFileName;

  Future<void> _pick(void Function(String?) onPicked) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    onPicked(result?.files.firstOrNull?.name);
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final disabilityStatus = form['disability_status'] as String? ?? 'None';
    final hasDisability = disabilityStatus != 'None' && disabilityStatus.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Medical & fitness', 'Health, transport, fitness'),
          onboardFieldGrid([
            onboardText(label: 'Medical Certificate No.', value: form['med_cert_no'] as String? ?? '', onChanged: (v) => widget.onChange('med_cert_no', v)),
            onboardDateField(context, label: 'Exam Date', value: form['med_exam_date'] as String?, lastDate: DateTime.now(), onPicked: (v) => widget.onChange('med_exam_date', v)),
            onboardDateField(context, label: 'Certificate Valid Till', value: form['cert_valid_till'] as String?, onPicked: (v) => widget.onChange('cert_valid_till', v)),
          ]),
          const SizedBox(height: 8),
          _fileRow('Medical certificate file', _medCertFileName, () => _pick((n) => setState(() => _medCertFileName = n))),
          const SizedBox(height: 20),
          onboardSectionLabel('Disability'),
          onboardFieldGrid([
            onboardDropdown<String>(
              label: 'Disability Status',
              value: disabilityStatus,
              items: [for (final s in _disabilityStatuses) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => widget.onChange('disability_status', v ?? 'None'),
            ),
            if (hasDisability) onboardText(label: 'Certificate No.', required: true, value: form['disability_cert_no'] as String? ?? '', onChanged: (v) => widget.onChange('disability_cert_no', v)),
            if (hasDisability) onboardText(label: 'Percentage', required: true, value: form['disability_pct'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => widget.onChange('disability_pct', v)),
            if (hasDisability) onboardText(label: 'Certifying Authority', required: true, value: form['disability_authority'] as String? ?? '', onChanged: (v) => widget.onChange('disability_authority', v)),
          ]),
          if (hasDisability) ...[
            const SizedBox(height: 8),
            _fileRow('Disability certificate file', _disabCertFileName, () => _pick((n) => setState(() => _disabCertFileName = n))),
          ],
          const SizedBox(height: 12),
          onboardText(label: 'Workplace Accommodations', value: form['workplace_accommodations'] as String? ?? '', maxLines: 2, onChanged: (v) => widget.onChange('workplace_accommodations', v)),
          const SizedBox(height: 20),
          onboardSectionLabel('Transport staff (drivers)'),
          onboardFieldGrid([
            onboardDropdown<String>(label: 'Eye Exam Result', value: form['eye_exam_result'] as String?, items: [for (final r in _eyeExamResults) DropdownMenuItem(value: r, child: Text(r))], onChanged: (v) => widget.onChange('eye_exam_result', v)),
            onboardDropdown<String>(label: 'Colour Blindness', value: form['colour_blindness'] as String?, items: [for (final c in _colourBlindnessLevels) DropdownMenuItem(value: c, child: Text(c))], onChanged: (v) => widget.onChange('colour_blindness', v)),
            onboardDateField(context, label: 'DL Medical Exam', value: form['dl_medical_exam'] as String?, lastDate: DateTime.now(), onPicked: (v) => widget.onChange('dl_medical_exam', v)),
          ]),
        ],
      ),
    );
  }

  Widget _fileRow(String label, String? fileName, VoidCallback onPick) {
    return Row(children: [
      Expanded(child: Text(fileName ?? label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: fileName != null ? Colors.black87 : Colors.grey.shade600))),
      TextButton(onPressed: onPick, child: Text(fileName == null ? 'Upload' : 'Replace')),
    ]);
  }
}
