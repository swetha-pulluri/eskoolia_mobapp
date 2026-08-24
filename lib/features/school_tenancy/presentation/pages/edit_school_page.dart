import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/school_entity.dart';
import '../providers/school_tenancy_provider.dart';

/// Dedicated "Edit School" screen — mirrors web's
/// `/super-admin/schools/[tenantId]/edit` page exactly (a flat 5-section
/// form distinct from the 9-section "Add a new school" wizard, with its own
/// field set/choices: `region` here is a direction word — north/south/east/
/// west/northeast — not the AWS-style shard/storage region, `status` is
/// directly editable, and `plan` includes 'starter'/'standard'/'custom' —
/// none of which apply to the create-time flow).
class EditSchoolPage extends ConsumerStatefulWidget {
  final String tenantId;

  const EditSchoolPage({super.key, required this.tenantId});

  @override
  ConsumerState<EditSchoolPage> createState() => _EditSchoolPageState();
}

const _kPlanOptions = [
  ['trial', 'Trial'],
  ['starter', 'Starter'],
  ['standard', 'Standard'],
  ['premium', 'Premium'],
  ['enterprise', 'Enterprise'],
  ['custom', 'Custom'],
];
const _kStatusOptions = [
  ['pending', 'Pending'],
  ['provisioning', 'Provisioning'],
  ['onboarding', 'Onboarding'],
  ['active', 'Active'],
  ['trial', 'Trial'],
  ['suspended', 'Suspended'],
  ['archived', 'Archived'],
];
const _kBoardOptions = [
  ['CBSE', 'CBSE'],
  ['ICSE', 'ICSE'],
  ['SSC_TG', 'SSC TG'],
  ['SSC_AP', 'SSC AP'],
  ['OTHER', 'Other'],
];
const _kStateOptions = [
  ['36', 'Telangana (36)'],
  ['37', 'Andhra Pradesh (37)'],
  ['29', 'Karnataka (29)'],
  ['33', 'Tamil Nadu (33)'],
  ['27', 'Maharashtra (27)'],
  ['07', 'Delhi (07)'],
  ['09', 'Uttar Pradesh (09)'],
  ['06', 'Haryana (06)'],
  ['08', 'Rajasthan (08)'],
  ['19', 'West Bengal (19)'],
  ['21', 'Odisha (21)'],
  ['32', 'Kerala (32)'],
  ['24', 'Gujarat (24)'],
];
const _kGeoRegionOptions = [
  ['north', 'North'],
  ['south', 'South'],
  ['east', 'East'],
  ['west', 'West'],
  ['northeast', 'North East'],
];
const _kShardRegionOptions = [
  ['ap-south-1', 'Asia Pacific — Mumbai (ap-south-1)'],
  ['ap-southeast-1', 'Asia Pacific — Singapore (ap-southeast-1)'],
  ['us-east-1', 'US East — N. Virginia (us-east-1)'],
  ['eu-west-1', 'Europe — Ireland (eu-west-1)'],
];
const _kSsoOptions = [
  ['native', 'Native (username/password)'],
  ['google', 'Google OAuth'],
  ['microsoft', 'Microsoft OAuth'],
  ['saml', 'SAML 2.0'],
];
// Same preset palette as the "Add a new school" wizard's brand-color swatch
// grid (`add_school_page.dart`) — web's Edit School page uses a native
// `<input type="color">` swatch instead, which has no cross-platform Flutter
// equivalent without a new picker dependency; reusing the app's own existing
// palette keeps a real tappable color swatch (not just a hex text field)
// while staying consistent with the rest of the module.
const _kPaletteColors = [
  '#5836E0',
  '#A65D08',
  '#1A4ACF',
  '#0E9F6E',
  '#992558',
  '#0369A1',
  '#06794F',
  '#E0463A',
];

// Matches web's `MEDIUM_OF_INSTRUCTION_OPTIONS` exactly (`lib/school-choices.ts`).
const _kMediumOfInstructionOptions = [
  'English',
  'English & Hindi',
  'English & Telugu',
  'Telugu',
  'Hindi',
  'Urdu',
  'Kannada',
  'Tamil',
  'Marathi',
];

class _EditSchoolPageState extends ConsumerState<EditSchoolPage> {
  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _seatsController = TextEditingController();
  final _udiseController = TextEditingController();
  final _panController = TextEditingController();
  final _backupRetentionController = TextEditingController();
  // Section 06 — Contact & address.
  final _principalNameController = TextEditingController();
  final _principalEmailController = TextEditingController();
  final _principalPhoneController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _campusAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _countryController = TextEditingController();
  // Section 07 — Identity extras & branding.
  final _schoolTypeController = TextEditingController();
  final _yearEstablishedController = TextEditingController();
  final _mottoController = TextEditingController();
  final _affiliationNumberController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _brandColorController = TextEditingController();

  String _plan = 'trial';
  String _status = 'active';
  bool _apiAccess = true;
  String _board = 'OTHER';
  String _state = '';
  String _region = '';
  String _gstRegistered = 'yes';
  String _shardRegion = '';
  String _storageRegion = '';
  String _ssoMethod = 'native';
  String _mediumOfInstruction = '';

  bool _loaded = false;
  bool _saving = false;

  void _loadFrom(SchoolEntity school) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = school.name;
    _shortCodeController.text = school.shortCode;
    _subdomainController.text = school.subdomainUrl;
    _plan = school.plan.isEmpty ? 'trial' : school.plan;
    _status = school.status.isEmpty ? 'active' : school.status;
    _apiAccess = school.apiAccess;
    _board = (school.board == null || school.board!.isEmpty) ? 'OTHER' : school.board!;
    _state = school.state ?? '';
    _region = school.region ?? '';
    _gstRegistered = (school.gstin?.isNotEmpty ?? false) ? 'yes' : 'no';
    _panController.text = school.pan ?? '';
    _udiseController.text = school.udiseCode ?? '';
    _seatsController.text = school.seats > 0 ? school.seats.toString() : '';
    _shardRegion = school.shardRegion;
    _storageRegion = school.storageRegion;
    _backupRetentionController.text = school.backupRetention.toString();
    _ssoMethod = school.ssoMethod.isEmpty ? 'native' : school.ssoMethod;
    _principalNameController.text = school.principalName ?? '';
    _principalEmailController.text = school.principalEmail ?? '';
    _principalPhoneController.text = school.principalPhone ?? '';
    _schoolPhoneController.text = school.schoolPhone ?? '';
    _schoolEmailController.text = school.schoolEmail ?? '';
    _websiteController.text = school.website ?? '';
    _campusAddressController.text = school.campusAddress ?? '';
    _cityController.text = school.city ?? '';
    _pinCodeController.text = school.pinCode ?? '';
    _countryController.text = (school.country?.isNotEmpty ?? false) ? school.country! : 'India';
    _schoolTypeController.text = school.schoolType ?? '';
    _mediumOfInstruction = school.mediumOfInstruction ?? '';
    _yearEstablishedController.text = school.yearEstablished != null ? school.yearEstablished.toString() : '';
    _mottoController.text = school.motto ?? '';
    _affiliationNumberController.text = school.affiliationNumber ?? '';
    _logoUrlController.text = school.logoUrl ?? '';
    _brandColorController.text = school.brandColor ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    _subdomainController.dispose();
    _seatsController.dispose();
    _udiseController.dispose();
    _panController.dispose();
    _backupRetentionController.dispose();
    _principalNameController.dispose();
    _principalEmailController.dispose();
    _principalPhoneController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    _websiteController.dispose();
    _campusAddressController.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _countryController.dispose();
    _schoolTypeController.dispose();
    _yearEstablishedController.dispose();
    _mottoController.dispose();
    _affiliationNumberController.dispose();
    _logoUrlController.dispose();
    _brandColorController.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/super-admin/schools/${widget.tenantId}');

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('School name is required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      await repository.updateSchoolFields(widget.tenantId, {
        'name': name,
        if (_shortCodeController.text.trim().isNotEmpty) 'short_code': _shortCodeController.text.trim(),
        if (_subdomainController.text.trim().isNotEmpty) 'subdomain_url': _subdomainController.text.trim(),
        'plan': _plan,
        'status': _status,
        'api_access': _apiAccess,
        'board': _board,
        if (_state.isNotEmpty) 'state': _state,
        if (_region.isNotEmpty) 'region': _region,
        if (_panController.text.trim().isNotEmpty) 'pan': _panController.text.trim().toUpperCase(),
        if (_udiseController.text.trim().isNotEmpty) 'udise_code': _udiseController.text.trim(),
        if (_seatsController.text.trim().isNotEmpty) 'seats': int.tryParse(_seatsController.text.trim()),
        if (_shardRegion.isNotEmpty) 'shard_region': _shardRegion,
        if (_storageRegion.isNotEmpty) 'storage_region': _storageRegion,
        if (_backupRetentionController.text.trim().isNotEmpty)
          'backup_retention': int.tryParse(_backupRetentionController.text.trim()),
        'sso_method': _ssoMethod,
        // Matches web's `handleSave()` exactly (`edit/page.tsx:155-190`) —
        // most contact/identity fields are omitted when blank, but
        // school_phone/school_email/website/medium_of_instruction/motto are
        // always sent (even empty), clearing them server-side if the user
        // blanks them out.
        if (_principalNameController.text.trim().isNotEmpty) 'principal_name': _principalNameController.text.trim(),
        if (_principalEmailController.text.trim().isNotEmpty) 'principal_email': _principalEmailController.text.trim(),
        if (_principalPhoneController.text.trim().isNotEmpty) 'principal_phone': _principalPhoneController.text.trim(),
        'school_phone': _schoolPhoneController.text.trim(),
        'school_email': _schoolEmailController.text.trim(),
        'website': _websiteController.text.trim(),
        if (_campusAddressController.text.trim().isNotEmpty) 'campus_address': _campusAddressController.text.trim(),
        if (_cityController.text.trim().isNotEmpty) 'city': _cityController.text.trim(),
        if (_pinCodeController.text.trim().isNotEmpty) 'pin_code': _pinCodeController.text.trim(),
        if (_countryController.text.trim().isNotEmpty) 'country': _countryController.text.trim(),
        if (_schoolTypeController.text.trim().isNotEmpty) 'school_type': _schoolTypeController.text.trim(),
        'medium_of_instruction': _mediumOfInstruction,
        if (_yearEstablishedController.text.trim().isNotEmpty)
          'year_established': int.tryParse(_yearEstablishedController.text.trim()),
        'motto': _mottoController.text.trim(),
        if (_affiliationNumberController.text.trim().isNotEmpty)
          'affiliation_number': _affiliationNumberController.text.trim(),
        if (_logoUrlController.text.trim().isNotEmpty) 'logo_url': _logoUrlController.text.trim(),
        if (_brandColorController.text.trim().isNotEmpty) 'brand_color': _brandColorController.text.trim(),
      });
      ref.invalidate(schoolDetailProvider(widget.tenantId));
      ref.invalidate(schoolsProvider);
      ref.invalidate(schoolsGlobalStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name updated successfully.')));
        context.go('/super-admin/schools');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(schoolDetailProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: schoolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load school.\n$error', textAlign: TextAlign.center, style: AppTextStyles.pageSubtitle),
          ),
        ),
        data: (school) {
          _loadFrom(school);
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: _saving ? null : _back,
                          icon: const Icon(Icons.arrow_back, size: 14),
                          label: const Text('Back to Schools'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary, padding: EdgeInsets.zero),
                        ),
                        const SizedBox(height: 8),
                        // Own card — same white/gray-bordered style already
                        // used by every `_section` below — instead of
                        // floating text directly on the page background.
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary,
                            border: Border.all(color: AppColors.borderPrimary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SCHOOL TENANCY · EDIT',
                                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                              ),
                              const SizedBox(height: 4),
                              Text('Edit School', style: AppTextStyles.pageTitle.copyWith(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(widget.tenantId, style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 11.5)),
                              const SizedBox(height: 14),
                              // `Wrap` (not `Row`) — a plain Row of these two
                              // fixed-size buttons overflowed by a few pixels
                              // now that this header sits inside its own
                              // card, whose padding narrows the available
                              // width slightly versus floating on the full
                              // page background.
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: _saving ? null : _back,
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _saving ? null : _save,
                                    icon: const Icon(Icons.save_outlined, size: 14),
                                    label: Text(_saving ? 'Saving…' : 'Save changes'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        _section('01', 'Basic identity', [
                          _field('School name', required: true, child: _textField(_nameController, 'e.g. Delhi Public School')),
                          _fieldRow([
                            _field('Short code', child: _textField(_shortCodeController, 'DPS', mono: true, upper: true, maxLength: 10)),
                            _field('Subdomain URL', child: _textField(_subdomainController, 'dps-noida', lower: true)),
                          ]),
                        ]),

                        _section('02', 'Plan & status', [
                          _fieldRow([
                            _field('Plan', child: _dropdown(_plan, _kPlanOptions, (v) => setState(() => _plan = v ?? 'trial'))),
                            _field('Status', child: _dropdown(_status, _kStatusOptions, (v) => setState(() => _status = v ?? 'active'))),
                          ]),
                          _fieldRow([
                            _field('Seats (licensed)', child: _textField(_seatsController, '500', number: true)),
                            _field('API access', child: _dropdown(
                              _apiAccess ? 'yes' : 'no',
                              const [['yes', 'Enabled'], ['no', 'Disabled']],
                              (v) => setState(() => _apiAccess = v == 'yes'),
                            )),
                          ]),
                        ]),

                        _section('03', 'Academic & geography', [
                          _fieldRow([
                            _field('Board', child: _dropdown(_board, _kBoardOptions, (v) => setState(() => _board = v ?? 'OTHER'))),
                            _field('State', child: _dropdown(
                              _state.isEmpty ? null : _state,
                              _kStateOptions,
                              (v) => setState(() => _state = v ?? ''),
                              hint: '— Select —',
                            )),
                          ]),
                          _fieldRow([
                            _field('Region', child: _dropdown(
                              _region.isEmpty ? null : _region,
                              _kGeoRegionOptions,
                              (v) => setState(() => _region = v ?? ''),
                              hint: '— Select —',
                            )),
                            _field('UDISE Code', child: _textField(_udiseController, '36201012801', mono: true, digitsOnly: true, maxLength: 11)),
                          ]),
                        ]),

                        _section('04', 'GST & legal', [
                          _fieldRow([
                            _field('GST registration', child: _dropdown(
                              _gstRegistered,
                              const [['yes', 'GST-registered'], ['no', 'Unregistered (exempt)']],
                              (v) => setState(() => _gstRegistered = v ?? 'yes'),
                            )),
                            _field('PAN', child: _textField(_panController, 'AAACE9988K', mono: true, upper: true, maxLength: 10)),
                          ]),
                        ]),

                        _section('05', 'Technical & infrastructure', [
                          _fieldRow([
                            _field('Shard region', child: _dropdown(
                              _shardRegion.isEmpty ? null : _shardRegion,
                              _kShardRegionOptions,
                              (v) => setState(() => _shardRegion = v ?? ''),
                              hint: '— Select —',
                            )),
                            _field('Storage region', child: _dropdown(
                              _storageRegion.isEmpty ? null : _storageRegion,
                              _kShardRegionOptions,
                              (v) => setState(() => _storageRegion = v ?? ''),
                              hint: '— Select —',
                            )),
                          ]),
                          _fieldRow([
                            _field('SSO method', child: _dropdown(_ssoMethod, _kSsoOptions, (v) => setState(() => _ssoMethod = v ?? 'native'))),
                            _field('Backup retention (days)', child: _textField(_backupRetentionController, '30', number: true)),
                          ]),
                        ]),

                        _section('06', 'Contact & address', [
                          _fieldRow([
                            _field('Principal name', child: _textField(_principalNameController, 'Dr. Anjali Rao')),
                            _field('Principal email', child: _textField(_principalEmailController, 'principal@school.edu')),
                          ]),
                          _fieldRow([
                            _field('Principal phone', child: _textField(_principalPhoneController, '+91 98765 43210')),
                            _field('Front-office phone', child: _textField(_schoolPhoneController, '+91 40 1234 5678')),
                          ]),
                          _fieldRow([
                            _field('Front-office email', child: _textField(_schoolEmailController, 'info@school.edu')),
                            _field('Website', child: _textField(_websiteController, 'https://school.edu')),
                          ]),
                          _field('Campus address', child: _textField(_campusAddressController, 'Street, area, landmark', multiline: true)),
                          _fieldRow([
                            _field('City', child: _textField(_cityController, 'Hyderabad')),
                            _field('PIN code', child: _textField(_pinCodeController, '500081', digitsOnly: true, maxLength: 6)),
                          ]),
                          _field('Country', child: _textField(_countryController, 'India')),
                        ]),

                        _section('07', 'Identity extras & branding', [
                          _fieldRow([
                            _field('School type', child: _textField(_schoolTypeController, 'K-12 · Day school')),
                            _field('Medium of instruction', child: _dropdown(
                              _mediumOfInstruction.isEmpty ? null : _mediumOfInstruction,
                              _kMediumOfInstructionOptions.map((m) => [m, m]).toList(),
                              (v) => setState(() => _mediumOfInstruction = v ?? ''),
                              hint: '— Select —',
                            )),
                          ]),
                          _fieldRow([
                            _field('Year established', child: _textField(_yearEstablishedController, '1998', number: true, maxLength: 4)),
                            _field('Board affiliation number', child: _textField(_affiliationNumberController, 'e.g. 1234567')),
                          ]),
                          _field('Motto / tagline', child: _textField(_mottoController, 'Knowledge is Power')),
                          _field('Logo URL', child: _textField(_logoUrlController, 'https://…/logo.png')),
                          _field('Brand color', child: _brandColorField()),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Sticky footer — matches web's own duplicated Cancel/Save
                // changes row pinned below the scrollable form content.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.bgPrimary,
                    border: Border(top: BorderSide(color: AppColors.borderPrimary)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(onPressed: _saving ? null : _back, child: const Text('Cancel')),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined, size: 14),
                        label: Text(_saving ? 'Saving…' : 'Save changes'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String num, String title, List<Widget> fields) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(999)),
                child: Text(num, style: AppTextStyles.numberedBadge.copyWith(color: AppColors.purpleDeep, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              // `Expanded`+ellipsis — a bare `Text` had no shrink fallback,
              // and "Technical & infrastructure" is long enough to overflow
              // this Row's available width on a narrow phone by itself.
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...fields,
        ],
      ),
    );
  }

  Widget _fieldRow(List<Widget> fields) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: fields[i]),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, {bool required = false, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // `Flexible`+ellipsis — a bare `Text` had no shrink fallback,
              // and at a 2-column field width (`_fieldRow`) a longer label
              // like "Trust / Reg. number" is enough to overflow this Row
              // on a narrow phone by itself.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (required) const Text(' *', style: TextStyle(color: AppColors.dangerRed, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    bool mono = false,
    bool upper = false,
    bool lower = false,
    bool number = false,
    bool digitsOnly = false,
    bool multiline = false,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number || digitsOnly ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 5 : 1,
      style: TextStyle(fontFamily: mono ? 'monospace' : null, fontSize: 13),
      onChanged: (upper || lower)
          ? (v) {
              final transformed = upper ? v.toUpperCase() : v.toLowerCase();
              if (transformed != v) {
                controller.value = controller.value.copyWith(
                  text: transformed,
                  selection: TextSelection.collapsed(offset: transformed.length),
                );
              }
            }
          : null,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        filled: true,
        fillColor: AppColors.bgSecondary,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _dropdown(
    String? value,
    List<List<String>> options,
    ValueChanged<String?> onChanged, {
    String? hint,
  }) {
    final items = [
      if (hint != null) DropdownMenuItem<String>(value: null, child: Text(hint, style: const TextStyle(fontSize: 13))),
      ...options.map((o) => DropdownMenuItem(value: o[0], child: Text(o[1], overflow: TextOverflow.ellipsis))),
    ];
    final safeItems = (value != null && !options.any((o) => o[0] == value))
        ? [...items, DropdownMenuItem(value: value, child: Text(value))]
        : items;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: safeItems,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Color? _hexToColor(String hex) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  /// Matches web's brand-color field layout — a colored swatch next to the
  /// hex text input (`edit/page.tsx`'s `<input type="color">` + text pair).
  /// Flutter has no cross-platform native color-input equivalent, so the
  /// swatch opens the same preset palette already used by the "Add a new
  /// school" wizard instead of a full picker — still a real, tappable color
  /// swatch (not just a hex code), just constrained to that palette.
  Widget _brandColorField() {
    return AnimatedBuilder(
      animation: _brandColorController,
      builder: (context, _) {
        final color = _hexToColor(_brandColorController.text) ?? const Color(0xFF6D4AFF);
        return Row(
          children: [
            InkWell(
              onTap: _openColorPalettePicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _textField(_brandColorController, '#6d4aff', mono: true)),
          ],
        );
      },
    );
  }

  void _openColorPalettePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brand color', style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _kPaletteColors.map((hex) {
                final selected = _brandColorController.text.toLowerCase() == hex.toLowerCase();
                return InkWell(
                  onTap: () {
                    setState(() => _brandColorController.text = hex);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? AppColors.textPrimary : Colors.transparent, width: 2),
                    ),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
