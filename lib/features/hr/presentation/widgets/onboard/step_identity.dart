import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../administration/domain/entities/picked_attachment.dart';
import '../../../../student/presentation/utils/camera_capture_helper.dart';
import '../../../domain/entities/master_option_entity.dart';
import '../../providers/hr_provider.dart';
import '../hr_theme.dart';
import 'onboard_field_widgets.dart';

const _genders = ['Male', 'Female', 'Other'];
const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// Client-side fallback, used only while `masterLanguagesProvider` etc. come
/// back empty — the real `/api/v1/master/languages/` endpoint isn't deployed
/// on `main` yet (confirmed via `git ls-tree main -- backend/apps/master`
/// returning empty), but it IS real on `demo`/`BugFix`
/// (`apps/master/constants.py`'s `LANGUAGES`). This list is copied verbatim
/// from that real backend constant so the dropdown shows correct, real
/// options today and hands off to the live endpoint the moment it's deployed
/// (`_withFallback` below always prefers the live list when non-empty).
const _fallbackLanguages = [
  'Assamese', 'Bengali', 'Bodo', 'Dogri', 'English', 'Gujarati', 'Hindi',
  'Kannada', 'Kashmiri', 'Khasi', 'Konkani', 'Maithili', 'Malayalam',
  'Manipuri', 'Marathi', 'Mizo', 'Nagamese', 'Nepali', 'Odia', 'Punjabi',
  'Sanskrit', 'Santali', 'Sindhi', 'Tamil', 'Telugu', 'Urdu',
  'Arabic', 'Chinese (Mandarin)', 'French', 'German', 'Hausa', 'Igbo',
  'Italian', 'Japanese', 'Korean', 'Portuguese', 'Russian', 'Spanish',
  'Swahili', 'Yoruba', 'Zulu', 'Amharic', 'Other',
];

/// Same rationale as [_fallbackLanguages] — verbatim copy of the real
/// backend's `apps/master/constants.py`'s `RELIGIONS`.
const _fallbackReligions = [
  'Hinduism', 'Islam', 'Christianity', 'Sikhism', 'Buddhism', 'Jainism',
  'Zoroastrianism', 'Judaism', "Bahá'í Faith", 'Tribal / Indigenous',
  'Atheism / No Religion', 'Prefer not to say', 'Other',
];

/// Same rationale as [_fallbackLanguages] — verbatim copy of the real
/// backend's `apps/master/constants.py`'s `COUNTRIES`.
const _fallbackCountries = [
  'Afghanistan', 'Albania', 'Algeria', 'Angola', 'Argentina', 'Armenia',
  'Australia', 'Austria', 'Azerbaijan', 'Bahrain', 'Bangladesh', 'Belarus',
  'Belgium', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Brazil',
  'Bulgaria', 'Cameroon', 'Canada', 'Chile', 'China', 'Colombia', 'Croatia',
  'Cuba', 'Czech Republic', 'Denmark', 'Egypt', 'Ethiopia', 'Finland',
  'France', 'Germany', 'Ghana', 'Greece', 'Hungary', 'India', 'Indonesia',
  'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Japan', 'Jordan',
  'Kazakhstan', 'Kenya', 'Kuwait', 'Lebanon', 'Libya', 'Malaysia', 'Mexico',
  'Morocco', 'Mozambique', 'Myanmar', 'Nepal', 'Netherlands', 'New Zealand',
  'Nigeria', 'Norway', 'Oman', 'Pakistan', 'Peru', 'Philippines', 'Poland',
  'Portugal', 'Qatar', 'Romania', 'Russia', 'Saudi Arabia', 'Senegal',
  'Serbia', 'Singapore', 'South Africa', 'South Korea', 'Spain', 'Sri Lanka',
  'Sudan', 'Sweden', 'Switzerland', 'Syria', 'Tanzania', 'Thailand',
  'Tunisia', 'Turkey', 'Uganda', 'Ukraine', 'United Arab Emirates',
  'United Kingdom', 'United States', 'Venezuela', 'Vietnam', 'Yemen',
  'Zambia', 'Zimbabwe', 'Other',
];

List<MasterOptionEntity> _withFallback(List<MasterOptionEntity> live, List<String> fallback) {
  if (live.isNotEmpty) return live;
  return [for (var i = 0; i < fallback.length; i++) MasterOptionEntity(id: i + 1, name: fallback[i])];
}

/// Step 1 — Staff identity. Real fields: `first_name`/`middle_name`/
/// `last_name`, `date_of_birth`, `gender`, `blood_group_input`,
/// `mother_tongue`/`religion`/`nationality` (+ free-text `_other` fallback,
/// bound to the real `/api/v1/master/{languages,religions,countries}/`
/// endpoints), `status`, `biometric_rfid`, `staff_no` (auto-fetched from the
/// real `next-staff-no` endpoint, always read-only here — matches web's own
/// `readOnly` "Staff Code" `<HrInput>`, `hr/onboard/page.tsx:507-513`).
/// "Take photo" reuses the Student Enroll flow's own platform-conditional
/// camera capture (`camera_capture_helper.dart`): native OS camera on
/// mobile/desktop, an in-page `getUserMedia` modal on web — mirroring the
/// real web's own `onCameraClick`/camera modal exactly.
class StepIdentity extends ConsumerStatefulWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;
  final PickedAttachment? photo;
  final ValueChanged<PickedAttachment?> onPhotoChanged;

  const StepIdentity({super.key, required this.form, required this.onChange, required this.photo, required this.onPhotoChanged});

  @override
  ConsumerState<StepIdentity> createState() => _StepIdentityState();
}

class _StepIdentityState extends ConsumerState<StepIdentity> {
  bool _fetchingStaffNo = false;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    if ((widget.form['staff_no'] as String? ?? '').isEmpty) _fetchStaffNo();
  }

  Future<void> _fetchStaffNo() async {
    setState(() => _fetchingStaffNo = true);
    try {
      final no = await ref.read(hrRepositoryProvider).getNextStaffNo();
      if (mounted && no.isNotEmpty) widget.onChange('staff_no', no);
    } catch (_) {
      // Non-blocking — staff_no can be filled manually if the lookup fails.
    } finally {
      if (mounted) setState(() => _fetchingStaffNo = false);
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    setState(() => _photoError = null);
    widget.onPhotoChanged(PickedAttachment(name: file!.name, bytes: file.bytes!, size: file.size));
  }

  /// "Take photo" — matches web's `onCameraClick` exactly (reuses the same
  /// platform-conditional capture already built for Student Enroll: native
  /// OS camera on mobile/desktop, in-page camera modal on web).
  Future<void> _takePhoto() async {
    Uint8List? bytes;
    try {
      bytes = await captureStudentPhotoViaCamera(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoError = 'Could not open the camera: $e');
      return;
    }
    if (bytes == null || !mounted) return;
    setState(() => _photoError = null);
    widget.onPhotoChanged(PickedAttachment(name: 'staff-photo-${DateTime.now().millisecondsSinceEpoch}.jpg', bytes: bytes, size: bytes.length));
  }

  /// Matches web's red "X" remove button on the photo circle exactly
  /// (`onPhotoRemove`, `hr/onboard/page.tsx:482-491`).
  void _removePhoto() {
    setState(() => _photoError = null);
    widget.onPhotoChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(masterLanguagesProvider);
    final religionsAsync = ref.watch(masterReligionsProvider);
    final countriesAsync = ref.watch(masterCountriesProvider);
    final form = widget.form;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Staff identity', 'Basic profile, DOB, photo'),
          Row(children: [
            // Photo circle + red "X" remove badge — matches web's
            // `.onboard-photo-circle` + `onPhotoRemove` button exactly
            // (`hr/onboard/page.tsx:466-492`).
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: widget.photo != null ? MemoryImage(Uint8List.fromList(widget.photo!.bytes)) : null,
                    child: widget.photo == null ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF94A3B8)) : null,
                  ),
                ),
                if (widget.photo != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: InkWell(
                      onTap: _removePhoto,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Staff photo', style: TextStyle(fontWeight: FontWeight.w800, color: HrColors.ink)),
                const Text('Square JPG or PNG, at least 400×400px. Used for ID card, directory, payroll and attendance.', style: TextStyle(fontSize: 12, color: HrColors.muted)),
                if (_photoError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_photoError!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                  ),
                Wrap(spacing: 4, children: [
                  TextButton(onPressed: _pickPhoto, child: Text(widget.photo == null ? 'Upload file' : 'Change')),
                  TextButton(onPressed: _takePhoto, child: const Text('Take photo')),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          onboardFieldGrid([
            onboardText(
              label: 'Staff Code',
              required: true,
              readOnly: true,
              value: (form['staff_no'] as String?)?.isNotEmpty == true
                  ? form['staff_no'] as String
                  : (_fetchingStaffNo ? 'Generating…' : 'Auto generated on save'),
              onChanged: (_) {},
            ),
            onboardText(label: 'Biometric / RFID Code', value: form['biometric_rfid'] as String? ?? '', maxLength: 30, onChanged: (v) => widget.onChange('biometric_rfid', v.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))),
            onboardDropdown<String>(
              label: 'Status',
              value: form['status'] as String? ?? 'active',
              items: const [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'inactive', child: Text('Inactive'))],
              onChanged: (v) => widget.onChange('status', v ?? 'active'),
            ),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardText(label: 'First Name', required: true, value: form['first_name'] as String? ?? '', maxLength: 50, onChanged: (v) => widget.onChange('first_name', v)),
            onboardText(label: 'Middle Name', value: form['middle_name'] as String? ?? '', maxLength: 50, onChanged: (v) => widget.onChange('middle_name', v)),
            onboardText(label: 'Last Name', required: true, value: form['last_name'] as String? ?? '', maxLength: 50, onChanged: (v) => widget.onChange('last_name', v)),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardDateField(context, label: 'Date of Birth', required: true, value: form['date_of_birth'] as String?, lastDate: DateTime.now(), onPicked: (v) => widget.onChange('date_of_birth', v)),
            onboardDropdown<String>(label: 'Gender', required: true, value: form['gender'] as String?, items: [for (final g in _genders) DropdownMenuItem(value: g, child: Text(g))], onChanged: (v) => widget.onChange('gender', v)),
            onboardDropdown<String>(label: 'Blood Group', value: form['blood_group_input'] as String?, items: [for (final b in _bloodGroups) DropdownMenuItem(value: b, child: Text(b))], onChanged: (v) => widget.onChange('blood_group_input', v)),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            _masterOrOther('Mother Tongue', 'mother_tongue', _withFallback(languagesAsync.valueOrNull ?? const [], _fallbackLanguages), form, widget.onChange, false),
            _masterOrOther('Religion', 'religion', _withFallback(religionsAsync.valueOrNull ?? const [], _fallbackReligions), form, widget.onChange, false),
            _masterOrOther('Nationality', 'nationality', _withFallback(countriesAsync.valueOrNull ?? const [], _fallbackCountries), form, widget.onChange, true),
          ]),
        ],
      ),
    );
  }

  /// Mirrors the real web's `SearchableSelect` contract exactly: the master
  /// list (`languages`/`religions`/`countries`) already ends in its own
  /// "Other" entry, so this dedupes it and pins a single trailing "Other"
  /// item (`baseOptions`/`hasOther` in `SearchableSelect.tsx`) instead of
  /// appending a second one — two `DropdownMenuItem`s sharing `value:
  /// 'Other'` is a real Flutter crash the moment that value is selected.
  /// Selecting "Other" stores the literal string `'Other'` in [key] (not
  /// empty), exactly like the web's `onChange={(v) => set(key, v)}` — the
  /// free-text goes only into `${key}_other`, shown whenever `value ==
  /// 'Other'` (web: `value === "Other"`).
  Widget _masterOrOther(String label, String key, List<dynamic> options, Map<String, dynamic> form, void Function(String, dynamic) onChange, bool required) {
    final value = form[key] as String?;
    final names = options.map((o) => o.name as String).where((n) => n != 'Other').toList();
    final hasOther = options.any((o) => o.name == 'Other');
    final isOther = value == 'Other';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        onboardDropdown<String>(
          label: label,
          required: required,
          value: value,
          items: [
            for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
            if (hasOther) const DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (v) {
            onChange(key, v);
            if (v != 'Other') onChange('${key}_other', '');
          },
        ),
        if (isOther)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: onboardText(label: '$label (other)', value: form['${key}_other'] as String? ?? '', onChanged: (v) => onChange('${key}_other', v)),
          ),
      ],
    );
  }
}
