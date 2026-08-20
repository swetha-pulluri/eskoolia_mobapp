import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/school_choices.dart';
import '../providers/school_info_wizard_state.dart';
import '../providers/settings_provider.dart';
import '../widgets/school_info_color_field.dart';
import '../widgets/school_info_field.dart';
import '../widgets/school_info_logo_field.dart';
import '../widgets/school_info_map.dart';
import '../widgets/school_info_review.dart';
import '../widgets/school_info_select_field.dart';
import '../widgets/school_info_step_indicator.dart';
import '../widgets/settings_card.dart';

/// Settings → School Info — a 1:1 port of
/// `frontend/components/settings/SchoolInfoPanel.tsx`: a 6-step wizard over
/// the single school-tenant profile record (`/api/v1/settings/school-info/`).
class SchoolInfoPage extends ConsumerWidget {
  const SchoolInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolInfoNotifierProvider);
    final notifier = ref.read(schoolInfoNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.load,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('Loading…', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(state.error!, style: const TextStyle(fontSize: 13, color: AppColors.dangerRed)),
                  ),
                if (state.success != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(state.success!, style: const TextStyle(fontSize: 13, color: AppColors.successGreen)),
                  ),
                if (!state.loading && state.info != null) ...[
                  const SizedBox(height: 14),
                  SettingsCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              children: [
                                TextSpan(
                                  text: state.info!.schoolName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                TextSpan(text: '   Code: ${state.info!.schoolCode}'),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SettingsCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SchoolInfoStepIndicator(currentStep: state.step, onStepTap: notifier.setStep),
                        _stepBody(state, notifier),
                        _footerNav(context, state, notifier),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    // Own card — same white/gray-bordered style already used by every
    // other section on this page (the school-name pill, the wizard body
    // via `SettingsCard`) — instead of floating text directly on the page
    // background.
    return SettingsCard(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('School ', style: AppTextStyles.pageTitle),
              Text('Info', style: AppTextStyles.pageTitleAccent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Auto-filled from School Tenancy — edit identity, contact, address, compliance and branding '
            'details used across the ERP. Jump straight to any section, or save and move on without '
            'stepping through the rest.',
            style: AppTextStyles.pageSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _stepBody(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    switch (state.step) {
      case 0:
        return _identityStep(state, notifier);
      case 1:
        return _principalStep(state, notifier);
      case 2:
        return _addressStep(state, notifier);
      case 3:
        return _complianceStep(state, notifier);
      case 4:
        return _brandingStep(state, notifier);
      default:
        return _reviewStep(state, notifier);
    }
  }

  Widget _identityStep(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final form = state.form;
    return _grid([
      SchoolInfoSelectField(
        label: 'Board',
        value: form['board'] as String?,
        options: [for (final b in boardOptions) MapEntry(b.value, b.label)],
        onChanged: (v) => notifier.setField('board', v ?? ''),
      ),
      SchoolInfoField(
        label: 'School Type',
        value: form['school_type'] as String?,
        onChanged: (v) => notifier.setField('school_type', v),
      ),
      SchoolInfoSelectField(
        label: 'Medium of Instruction',
        value: form['medium_of_instruction'] as String?,
        options: [for (final m in mediumOfInstructionOptions) MapEntry(m, m)],
        onChanged: (v) => notifier.setField('medium_of_instruction', v ?? ''),
      ),
      SchoolInfoField(
        label: 'Year Established',
        value: form['year_established']?.toString(),
        keyboardType: TextInputType.number,
        onChanged: (v) => notifier.setField('year_established', v.trim().isEmpty ? null : int.tryParse(v)),
      ),
      SchoolInfoField(
        label: 'Motto / Tagline',
        value: form['motto'] as String?,
        onChanged: (v) => notifier.setField('motto', v),
      ),
    ]);
  }

  Widget _principalStep(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final form = state.form;
    return _grid([
      SchoolInfoField(
        label: 'Principal Name',
        value: form['principal_name'] as String?,
        onChanged: (v) => notifier.setField('principal_name', v),
      ),
      SchoolInfoField(
        label: 'Principal Email',
        value: form['principal_email'] as String?,
        keyboardType: TextInputType.emailAddress,
        onChanged: (v) => notifier.setField('principal_email', v),
      ),
      SchoolInfoField(
        label: 'Principal Phone',
        value: form['principal_phone'] as String?,
        keyboardType: TextInputType.phone,
        onChanged: (v) => notifier.setField('principal_phone', v),
      ),
      SchoolInfoField(
        label: 'Front-office Phone',
        value: form['school_phone'] as String?,
        keyboardType: TextInputType.phone,
        onChanged: (v) => notifier.setField('school_phone', v),
      ),
      SchoolInfoField(
        label: 'Front-office Email',
        value: form['school_email'] as String?,
        keyboardType: TextInputType.emailAddress,
        onChanged: (v) => notifier.setField('school_email', v),
      ),
      SchoolInfoField(
        label: 'Website',
        value: form['website'] as String?,
        keyboardType: TextInputType.url,
        onChanged: (v) => notifier.setField('website', v),
      ),
    ]);
  }

  Widget _complianceStep(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final form = state.form;
    return _grid([
      SchoolInfoField(
        label: 'Board Affiliation Number',
        value: form['affiliation_number'] as String?,
        onChanged: (v) => notifier.setField('affiliation_number', v),
      ),
      SchoolInfoField(
        label: 'UDISE Code',
        value: form['udise_code'] as String?,
        onChanged: (v) => notifier.setField('udise_code', v),
      ),
      SchoolInfoField(
        label: 'GSTIN',
        value: form['gstin'] as String?,
        onChanged: (v) => notifier.setField('gstin', v),
      ),
      SchoolInfoField(
        label: 'PAN',
        value: form['pan'] as String?,
        onChanged: (v) => notifier.setField('pan', v),
      ),
    ]);
  }

  Widget _brandingStep(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final form = state.form;
    return _grid([
      const SchoolInfoLogoField(),
      SchoolInfoColorField(
        value: form['brand_color'] as String?,
        onChanged: (v) => notifier.setField('brand_color', v),
      ),
    ]);
  }

  Widget _addressStep(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final form = state.form;
    final latitude = double.tryParse((form['latitude'] as String?) ?? '');
    final longitude = double.tryParse((form['longitude'] as String?) ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grid([
          SchoolInfoField(
            label: 'Campus Address',
            value: form['campus_address'] as String?,
            multiline: true,
            onChanged: (v) => notifier.setField('campus_address', v),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SchoolInfoField(
                label: 'City',
                value: form['city'] as String?,
                onChanged: (v) => notifier.setField('city', v),
              ),
              const SizedBox(height: 18),
              SchoolInfoField(
                label: 'PIN Code',
                value: form['pin_code'] as String?,
                keyboardType: TextInputType.number,
                onChanged: (v) => notifier.setField('pin_code', v),
              ),
            ],
          ),
          SchoolInfoSelectField(
            label: 'State',
            value: form['state'] as String?,
            options: [for (final s in indianStateOptions) MapEntry(s.code, '${s.name} (${s.code})')],
            onChanged: (v) => notifier.setField('state', v ?? ''),
          ),
          SchoolInfoSelectField(
            label: 'Region',
            value: form['region'] as String?,
            options: [for (final r in regionOptions) MapEntry(r, regionLabel(r))],
            onChanged: (v) => notifier.setField('region', v ?? ''),
          ),
          SchoolInfoField(
            label: 'Country',
            value: form['country'] as String?,
            onChanged: (v) => notifier.setField('country', v),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SettingsCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `Wrap` rather than a plain `Row`: if the "Use My Current
                // Location" button and the "Campus Location" label can't
                // both fit on one line at phone width, this drops the
                // button to its own line below instead of overflowing.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text('Campus Location', style: schoolInfoLabelStyle),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: state.locating ? null : notifier.useCurrentLocation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.purpleAccent,
                        side: const BorderSide(color: AppColors.purpleSoft),
                        backgroundColor: AppColors.bgPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: state.locating
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleAccent),
                            )
                          : const Icon(Icons.my_location, size: 13),
                      label: Text(
                        state.locating ? 'Locating…' : 'Use My Current Location',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 12),
                  child: Text(
                    "Tap the map to drop a pin on the campus, or drag the pin to adjust. This point will be "
                    "used to geofence staff clock-in/out once that feature ships. If the location implies a "
                    "different City, PIN Code, State, Region or Country than what's set above, you'll be "
                    "asked to confirm the change (and why) — confirming saves it immediately.",
                    style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                  ),
                ),
                SchoolInfoMap(
                  latitude: latitude,
                  longitude: longitude,
                  radiusMeters: form['geofence_radius_meters'] as int?,
                  onChanged: notifier.setLocation,
                ),
                if (state.geocoding)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textTertiary),
                        ),
                        SizedBox(width: 6),
                        Text('Looking up address for this location…', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                if (state.locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(state.locationError!, style: const TextStyle(fontSize: 12, color: AppColors.dangerRed)),
                  ),
                if (state.pendingLocationUpdate != null)
                  _pendingLocationPanel(state, notifier),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Latitude/Longitude are short enough to pair on one
                      // row even at phone width.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SchoolInfoField(
                              label: 'Latitude',
                              value: form['latitude'] as String?,
                              onChanged: (v) => notifier.setField('latitude', v),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SchoolInfoField(
                              label: 'Longitude',
                              value: form['longitude'] as String?,
                              onChanged: (v) => notifier.setField('longitude', v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SchoolInfoField(
                        label: 'Geofence Radius (metres)',
                        value: form['geofence_radius_meters']?.toString(),
                        keyboardType: TextInputType.number,
                        placeholder: 'e.g. 200',
                        onChanged: (v) => notifier.setField('geofence_radius_meters', v.trim().isEmpty ? null : int.tryParse(v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pendingLocationPanel(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final pending = state.pendingLocationUpdate!;
    final reasonFilled = state.locationUpdateReason.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purpleTint,
        border: Border.all(color: AppColors.purpleSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update address from this location?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          for (final d in pending.diff)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  children: [
                    TextSpan(text: '${d.label}: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    TextSpan(text: '${d.from} → ${d.to}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          SchoolInfoField(
            label: 'Reason for this update',
            value: state.locationUpdateReason,
            placeholder: 'e.g. Corrected pin to the actual campus gate',
            onChanged: notifier.setLocationUpdateReason,
          ),
          const SizedBox(height: 12),
          // Stacked, full-width buttons rather than side-by-side — "Update
          // & Save Address" / "Keep Current Address" are long enough that
          // a Row split between them overflows at phone width.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (reasonFilled && !state.saving) ? notifier.confirmLocationUpdate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: state.saving
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 6),
                        Text('Saving…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : const Text('Update & Save Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: state.saving ? null : notifier.discardLocationUpdate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderSecondary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Keep Current Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewStep(SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final form = state.form;
    final groups = <_ReviewGroup>[
      _ReviewGroup('Identity', Icons.verified_outlined, 0, const [
        MapEntry('board', 'Board'),
        MapEntry('school_type', 'School Type'),
        MapEntry('medium_of_instruction', 'Medium of Instruction'),
        MapEntry('year_established', 'Year Established'),
        MapEntry('motto', 'Motto / Tagline'),
      ]),
      _ReviewGroup('Principal Contact', Icons.person_outline, 1, const [
        MapEntry('principal_name', 'Principal Name'),
        MapEntry('principal_email', 'Principal Email'),
        MapEntry('principal_phone', 'Principal Phone'),
        MapEntry('school_phone', 'Front-office Phone'),
        MapEntry('school_email', 'Front-office Email'),
        MapEntry('website', 'Website'),
      ]),
      _ReviewGroup('Address', Icons.location_on_outlined, 2, const [
        MapEntry('campus_address', 'Campus Address'),
        MapEntry('city', 'City'),
        MapEntry('state', 'State'),
        MapEntry('region', 'Region'),
        MapEntry('pin_code', 'PIN Code'),
        MapEntry('country', 'Country'),
        MapEntry('latitude', 'Latitude'),
        MapEntry('longitude', 'Longitude'),
        MapEntry('geofence_radius_meters', 'Geofence Radius (m)'),
      ]),
      _ReviewGroup('Compliance', Icons.account_balance_outlined, 3, const [
        MapEntry('affiliation_number', 'Board Affiliation Number'),
        MapEntry('udise_code', 'UDISE Code'),
        MapEntry('gstin', 'GSTIN'),
        MapEntry('pan', 'PAN'),
      ]),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SchoolInfoReviewSection(
                title: group.title,
                icon: group.icon,
                onEdit: () => notifier.setStep(group.step),
                child: Column(
                  children: [
                    for (var i = 0; i < group.fields.length; i++)
                      SchoolInfoReviewRow(
                        label: group.fields[i].value,
                        value: _reviewValue(group.fields[i].key, form),
                        last: i == group.fields.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          SchoolInfoReviewSection(
            title: 'Branding',
            icon: Icons.palette_outlined,
            onEdit: () => notifier.setStep(4),
            child: _brandingReviewRow(state),
          ),
        ],
      ),
    );
  }

  Widget _brandingReviewRow(SchoolInfoWizardState state) {
    final hasLogo = state.logoBytes != null || (state.info?.logoUrl.isNotEmpty ?? false);
    final brandColor = (state.form['brand_color'] as String?) ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSecondary),
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: hasLogo
                ? null
                : const Icon(Icons.business_outlined, size: 17, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Logo', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                Text(
                  hasLogo ? 'Uploaded' : 'Not set',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: brandColor.isNotEmpty ? _tryParseColor(brandColor) : AppColors.purpleAccent,
              border: Border.all(color: AppColors.borderSecondary),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            brandColor.isEmpty ? '—' : brandColor,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _footerNav(BuildContext context, SchoolInfoWizardState state, SchoolInfoNotifier notifier) {
    final isLastStep = state.step == SchoolInfoWizardState.stepCount - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Container(
        padding: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
        // A Column (Back above, actions below, each action `Expanded`)
        // instead of one wide Row — three buttons side by side reliably
        // overflowed at phone width, especially with "Saving…" states.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.step > 0) ...[
              TextButton.icon(
                onPressed: () => notifier.setStep(state.step - 1),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.chevron_left, size: 15),
                label: const Text('Back', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                if (!isLastStep)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.saving
                          ? null
                          : () async {
                              try {
                                await notifier.save(silent: true);
                                notifier.setStep(SchoolInfoWizardState.stepCount - 1);
                              } catch (_) {
                                // Error already surfaced via state.error.
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.purpleAccent,
                        side: const BorderSide(color: AppColors.purpleSoft),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: state.saving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleAccent)),
                                SizedBox(width: 6),
                                Text('Saving…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 15),
                                SizedBox(width: 6),
                                Text('Save & Exit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                if (!isLastStep) const SizedBox(width: 10),
                Expanded(
                  child: isLastStep
                      ? ElevatedButton(
                          onPressed: state.saving
                              ? null
                              : () async {
                                  try {
                                    await notifier.save();
                                  } catch (_) {
                                    // Error already surfaced via state.error.
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: state.saving
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    SizedBox(width: 6),
                                    Text('Saving…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 15),
                                    SizedBox(width: 6),
                                    Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        )
                      : ElevatedButton(
                          onPressed: () => notifier.setStep(state.step + 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Next', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              SizedBox(width: 6),
                              Icon(Icons.chevron_right, size: 15),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays out fields one-per-row, full width. `SchoolInfoPanel.tsx`'s web
/// grid packs 2 (or 3, for Latitude/Longitude/Geofence Radius) fields per
/// row — on a phone-width column that leaves each field too narrow for its
/// label/value (this was the source of the Settings → School Info overflow
/// issues), so every step stacks its fields vertically instead.
Widget _grid(List<Widget> fields) {
  final rows = <Widget>[];
  for (var i = 0; i < fields.length; i++) {
    rows.add(fields[i]);
    if (i != fields.length - 1) rows.add(const SizedBox(height: 16));
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
}

class _ReviewGroup {
  final String title;
  final IconData icon;
  final int step;
  final List<MapEntry<String, String>> fields;

  const _ReviewGroup(this.title, this.icon, this.step, this.fields);
}

String _reviewValue(String key, Map<String, dynamic> form) {
  final raw = form[key];
  if (key == 'state') return stateLabel(raw as String?);
  if (key == 'region') return regionLabel(raw as String?);
  if (key == 'board') {
    for (final b in boardOptions) {
      if (b.value == raw) return b.label;
    }
  }
  if (raw == null) return '—';
  if (raw is int) return raw.toString();
  final s = raw.toString();
  return s.isEmpty ? '—' : s;
}

Color _tryParseColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return AppColors.purpleAccent;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? AppColors.purpleAccent : Color(parsed);
}
