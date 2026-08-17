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

class _EditSchoolPageState extends ConsumerState<EditSchoolPage> {
  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _seatsController = TextEditingController();
  final _udiseController = TextEditingController();
  final _panController = TextEditingController();
  final _backupRetentionController = TextEditingController();

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
                        Text(
                          'SCHOOL TENANCY · EDIT',
                          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text('Edit School', style: AppTextStyles.pageTitle.copyWith(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(widget.tenantId, style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 11.5)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: _saving ? null : _back,
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: const Icon(Icons.save_outlined, size: 14),
                              label: Text(_saving ? 'Saving…' : 'Save changes'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(onPressed: _saving ? null : _back, child: const Text('Cancel')),
                      const SizedBox(width: 8),
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
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number || digitsOnly ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
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
}
