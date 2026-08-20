import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/school_entity.dart';
import '../providers/school_tenancy_provider.dart';

/// Mobile equivalent of web's "Add a new school" / "Edit school" accordion
/// **content** (`schools/page.tsx` — Accordion 01, `handleProvisionSubmit`,
/// `handleEditInForm`). This is embedded inline in `schools_tab.dart`'s own
/// numbered accordion, directly above "Smart filters" — matching web's
/// single-page accordion layout exactly (this was previously a separate
/// pushed page, which didn't match web; web never navigates anywhere for
/// this, it just expands section "01" in place on the Schools page).
///
/// Web renders 9 numbered sections (Modules, numbered 08 in the source, is
/// `className="hidden"` and never actually shown — skipped here too).
///
/// Backend contract (re-verified against the live `ProvisionSchoolSerializer`
/// / `SchoolProvisionView.post()` in `apps/tenancy/super_admin/`, which
/// replaced an earlier `apps/super_admin/` implementation this file's
/// comments used to describe): on create, the backend now genuinely
/// persists `name`, `subdomain_url`, `state`, `board`, `plan`,
/// `shard_region`, `storage_region`, `backup_retention`, `sso_method`,
/// `short_code`, `gstin`, `pan`, `udise_code`, `seats`, `brand_color`,
/// `logo_url` — all wired into `_submitCreate`'s payload below. It also
/// declares (but this form doesn't yet collect matching, correctly-typed
/// values for) `student_seat_limit`/`staff_seat_limit`/`storage_cap_gb`/
/// `trial_days`/`go_live_date`/`billing_cycle` — the "Plan & capacity
/// limits" section's Trial period/Go-live date/Staff seat limit/Storage cap/
/// Billing cycle fields remain the same kind of decorative, uncontrolled
/// inputs web itself has partial support for (web's own `editFields.*`
/// state, not yet mirrored here) — a disclosed gap, not a silent omission.
/// `admin_username`/`admin_password` are collected and sent (matching web's
/// `provisionForm.admin_username`/`admin_password`) but neither this
/// backend view nor `provision_tenant()` currently reads or acts on them —
/// no admin user account is actually created from them yet, on web or here.
class AddSchoolForm extends ConsumerStatefulWidget {
  final SchoolEntity? editSchool;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const AddSchoolForm({
    super.key,
    this.editSchool,
    required this.onCancel,
    required this.onSaved,
  });

  @override
  ConsumerState<AddSchoolForm> createState() => _AddSchoolFormState();
}

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

const _kBoardOptions = [
  ['CBSE', 'CBSE — Central Board (Delhi)'],
  ['ICSE', 'ICSE — CISCE'],
  ['SSC_TG', 'SSC TG — Telangana State Board'],
  ['SSC_AP', 'SSC AP — Andhra Pradesh Board'],
  ['OTHER', 'IB / Cambridge / Other'],
];

// Full real state/UT list — verbatim from the backend's own
// `SchoolFormChoicesView._STATES` (`apps/super_admin/views.py`), sorted by
// name to match. The live `main` backend (what the local dev server
// actually runs) has no `schools/form-choices/` route to fetch this from
// at runtime — that endpoint only exists on the unmerged `demo` branch —
// so this is the same real, hardcoded-server-side list ported directly,
// not an invented one.
const _kStateOptions = [
  ['35', 'Andaman and Nicobar Islands'],
  ['37', 'Andhra Pradesh'],
  ['12', 'Arunachal Pradesh'],
  ['18', 'Assam'],
  ['10', 'Bihar'],
  ['04', 'Chandigarh'],
  ['22', 'Chhattisgarh'],
  ['26', 'Dadra and Nagar Haveli and Daman and Diu'],
  ['07', 'Delhi'],
  ['30', 'Goa'],
  ['24', 'Gujarat'],
  ['06', 'Haryana'],
  ['02', 'Himachal Pradesh'],
  ['01', 'Jammu and Kashmir'],
  ['20', 'Jharkhand'],
  ['29', 'Karnataka'],
  ['32', 'Kerala'],
  ['38', 'Ladakh'],
  ['31', 'Lakshadweep'],
  ['23', 'Madhya Pradesh'],
  ['27', 'Maharashtra'],
  ['14', 'Manipur'],
  ['17', 'Meghalaya'],
  ['15', 'Mizoram'],
  ['13', 'Nagaland'],
  ['21', 'Odisha'],
  ['34', 'Puducherry'],
  ['03', 'Punjab'],
  ['08', 'Rajasthan'],
  ['11', 'Sikkim'],
  ['33', 'Tamil Nadu'],
  ['36', 'Telangana'],
  ['16', 'Tripura'],
  ['09', 'Uttar Pradesh'],
  ['05', 'Uttarakhand'],
  ['19', 'West Bengal'],
];

// Web's Section 07 "Subscription plan" select (`schools/page.tsx`) doesn't
// use the backend's create-time `ProvisionSchoolRequestSerializer.plan`
// choice list at all — it renders the real, server-driven billing plans
// catalog (`getPlans()` → `GET /api/super-admin/billing/plans/`, the exact
// same endpoint and shape [`plansProvider`] already backs the Billing tab
// with), `<option value={p.code}>{p.name}</option>` per plan, in whatever
// order the API returns. `validate_plan` on the backend
// (`apps/super_admin/serializers.py`) confirms this: it accepts any
// `SubscriptionPlan.code` from that same table, plus the two special
// literals `trial`/`custom` — it does not accept a fixed enum. This
// fallback (shown only while the catalog hasn't loaded yet, or came back
// empty) exactly matches web's own fallback branch — plain names, no price
// suffix, no `custom` entry (web's Section 07 select never offers one).
const _kPlanFallbackOptions = [
  ['starter', 'Starter'],
  ['premium', 'Premium'],
  ['enterprise', 'Enterprise'],
];

const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class _AddSchoolFormState extends ConsumerState<AddSchoolForm> {
  bool get _isEdit => widget.editSchool != null;

  // ── Real, submitted fields ────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _udiseController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _seatsController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _mobileController = TextEditingController();

  // SMTP configuration (section 10, web `schools/page.tsx` — create-only,
  // same as Admin login credentials above; `provisionSchool()` on web
  // sends these as part of the very same request body, not a separate
  // endpoint/save step).
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '587');
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  final _smtpFromEmailController = TextEditingController();
  final _smtpSenderNameController = TextEditingController();
  bool _smtpUseTls = true;

  String _board = 'OTHER';
  String? _stateCode;
  String _plan = 'trial';
  String _shardRegion = 'ap-south-1';
  int _backupRetention = 30;
  String _ssoMethod = 'native';
  String _apiAccess = 'disabled';
  String _brandColor = _kPaletteColors[0];

  Uint8List? _logoBytes;
  String? _logoFilename;
  String? _existingLogoUrl;

  bool _submitting = false;
  String? _error;
  String? _mobileError;

  // ── Academic year start — a real, interactive field matching web's
  // "Academic year start" picker (`schools/page.tsx` `acadYears`/
  // `addingAcadYear`/`acadYearDraft`), including its real behavior: never
  // actually submitted (`ProvisionSchoolRequestSerializer` has no such
  // field either), purely a client-side convenience list.
  List<String> _acadYears = _defaultAcadYears();
  String? _acadYearSelected;
  bool _addingAcadYear = false;
  String _acadStartMonth = 'June';
  String _acadEndMonth = 'May';
  final _acadStartYearController = TextEditingController();
  final _acadEndYearController = TextEditingController();

  static List<String> _defaultAcadYears() {
    final y = DateTime.now().year;
    return [
      'June $y – May ${y + 1}',
      'April $y – March ${y + 1}',
      'June ${y - 1} – May $y',
      'April ${y - 1} – March $y',
    ];
  }

  // ── Decorative-only fields (visible on web, never actually submitted —
  // see class doc comment) — kept as a single bag of ephemeral values so
  // every field is still genuinely interactive without a controller each.
  final Map<String, dynamic> _decorative = {};

  @override
  void initState() {
    super.initState();
    final y = DateTime.now().year;
    _acadStartYearController.text = y.toString();
    _acadEndYearController.text = (y + 1).toString();
    _acadYearSelected = _acadYears.first;
    final school = widget.editSchool;
    if (school != null) {
      _nameController.text = school.name;
      _shortCodeController.text = school.shortCode;
      _subdomainController.text = school.subdomainUrl;
      _udiseController.text = school.udiseCode ?? '';
      _gstinController.text = school.gstin ?? '';
      _panController.text = school.pan ?? '';
      _seatsController.text = school.seats > 0 ? school.seats.toString() : '';
      _board = (school.board == null || school.board!.isEmpty) ? 'OTHER' : school.board!;
      // An empty string (the model's real blank=True default) must become
      // an actual `null`, not stay `''` — `AppDropdown`'s hint only shows
      // for a `null` value; `''` matches no item and crashes instead.
      _stateCode = (school.state?.isEmpty ?? true) ? null : school.state;
      _plan = school.plan.isEmpty ? 'trial' : school.plan;
      _shardRegion = school.shardRegion.isEmpty
          ? 'ap-south-1'
          : school.shardRegion;
      _backupRetention = school.backupRetention;
      _ssoMethod = school.ssoMethod.isEmpty ? 'native' : school.ssoMethod;
      _apiAccess = school.apiAccess ? 'enabled' : 'disabled';
      _brandColor = school.brandColor ?? _kPaletteColors[0];
      _existingLogoUrl = school.logoUrl;
    } else {
      _restoreDraft();
    }
    // Live-updates the Admin username placeholder to reflect the current
    // subdomain, matching web's `${subdomain}_admin` dynamic placeholder.
    _subdomainController.addListener(_onSubdomainChanged);
  }

  void _onSubdomainChanged() => setState(() {});

  @override
  void dispose() {
    _subdomainController.removeListener(_onSubdomainChanged);
    _nameController.dispose();
    _shortCodeController.dispose();
    _subdomainController.dispose();
    _udiseController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _seatsController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _smtpFromEmailController.dispose();
    _smtpSenderNameController.dispose();
    _mobileController.dispose();
    _acadStartYearController.dispose();
    _acadEndYearController.dispose();
    super.dispose();
  }

  static const _draftPrefsKey = 'school_add_draft';

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftPrefsKey);
      if (raw == null || !mounted) return;
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _nameController.text = draft['name'] as String? ?? '';
        _shortCodeController.text = draft['short_code'] as String? ?? '';
        _subdomainController.text = draft['subdomain_url'] as String? ?? '';
        _udiseController.text = draft['udise_code'] as String? ?? '';
        _gstinController.text = draft['gstin'] as String? ?? '';
        _panController.text = draft['pan'] as String? ?? '';
        _seatsController.text = draft['seats'] as String? ?? '';
        _adminUsernameController.text =
            draft['admin_username'] as String? ?? '';
        _board = draft['board'] as String? ?? _board;
        _stateCode = draft['state'] as String? ?? _stateCode;
        _plan = draft['plan'] as String? ?? _plan;
        _shardRegion = draft['shard_region'] as String? ?? _shardRegion;
        _backupRetention =
            draft['backup_retention'] as int? ?? _backupRetention;
        _ssoMethod = draft['sso_method'] as String? ?? _ssoMethod;
        _apiAccess = draft['api_access'] as String? ?? _apiAccess;
        _brandColor = draft['brand_color'] as String? ?? _brandColor;
      });
    } catch (_) {
      // Storage unavailable or malformed draft — ignore, matching web's
      // own `try { ... } catch { /* storage unavailable */ }`.
    }
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _draftPrefsKey,
        jsonEncode({
          'name': _nameController.text,
          'short_code': _shortCodeController.text,
          'subdomain_url': _subdomainController.text,
          'udise_code': _udiseController.text,
          'gstin': _gstinController.text,
          'pan': _panController.text,
          'seats': _seatsController.text,
          'admin_username': _adminUsernameController.text,
          'board': _board,
          'state': _stateCode,
          'plan': _plan,
          'shard_region': _shardRegion,
          'backup_retention': _backupRetention,
          'sso_method': _ssoMethod,
          'api_access': _apiAccess,
          'brand_color': _brandColor,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Draft saved — your progress is preserved for this session.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save draft.')),
        );
      }
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftPrefsKey);
    } catch (_) {
      // Storage unavailable — nothing to clear.
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'svg', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes != null) {
      setState(() {
        _logoBytes = file!.bytes;
        _logoFilename = file.name;
      });
    }
  }

  void _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#\$';
    const symbols = '!@#\$';
    final random = List.generate(14, (i) {
      if (i == 0) {
        return chars.substring(0, 26)[DateTime.now().microsecondsSinceEpoch %
            26];
      }
      if (i == 13) {
        return symbols[(DateTime.now().microsecondsSinceEpoch + i) %
            symbols.length];
      }
      return chars[(DateTime.now().microsecondsSinceEpoch + i * 7) %
          chars.length];
    }).join();
    setState(() => _adminPasswordController.text = random);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final name = _nameController.text.trim();
    if (name.isEmpty || _stateCode == null || _stateCode!.isEmpty) {
      setState(() => _error = 'School name and state are required.');
      return;
    }

    if (_isEdit) {
      await _submitEdit(name);
    } else {
      await _submitCreate(name);
    }
  }

  Future<void> _submitEdit(String name) async {
    setState(() => _submitting = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      String? logoUrl;
      if (_logoBytes != null) {
        try {
          logoUrl = await repository.uploadSchoolLogo(
            widget.editSchool!.tenantId,
            _logoBytes!,
            _logoFilename ?? 'logo.png',
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logo upload failed — other changes were saved.'),
              ),
            );
          }
        }
      }
      await repository.updateSchoolFields(widget.editSchool!.tenantId, {
        'name': name,
        'state': _stateCode,
        'board': _board,
        'plan': _plan,
        'shard_region': _shardRegion,
        'storage_region': _shardRegion,
        'backup_retention': _backupRetention,
        'sso_method': _ssoMethod,
        if (_shortCodeController.text.trim().isNotEmpty)
          'short_code': _shortCodeController.text.trim(),
        if (_gstinController.text.trim().isNotEmpty)
          'gstin': _gstinController.text.trim(),
        if (_panController.text.trim().isNotEmpty)
          'pan': _panController.text.trim(),
        if (_udiseController.text.trim().isNotEmpty)
          'udise_code': _udiseController.text.trim(),
        if (_seatsController.text.trim().isNotEmpty)
          'seats': int.tryParse(_seatsController.text.trim()),
        'api_access': _apiAccess == 'enabled',
        'brand_color': _brandColor,
        'logo_url': ?logoUrl,
      });
      ref.invalidate(schoolsProvider);
      ref.invalidate(schoolsGlobalStatsProvider);
      ref.invalidate(schoolTenancyDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name updated.')));
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _error = 'Update failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitCreate(String name) async {
    final sub = _subdomainController.text.trim().toLowerCase();
    if (sub.isEmpty) {
      setState(() => _error = 'Subdomain is required.');
      return;
    }
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(sub)) {
      setState(
        () => _error =
            'Subdomain may only contain lowercase letters, numbers, and hyphens.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final result = await repository.provisionSchool({
        'name': name,
        'subdomain_url': sub,
        'state': _stateCode,
        'board': _board,
        'plan': _plan,
        'shard_region': _shardRegion,
        'storage_region': _shardRegion,
        'backup_retention': _backupRetention,
        'sso_method': _ssoMethod,
        // Now real, persisted `ProvisionSchoolSerializer` fields (see this
        // class's doc comment) — previously omitted here on the mistaken
        // belief the backend ignored them on create.
        if (_shortCodeController.text.trim().isNotEmpty)
          'short_code': _shortCodeController.text.trim(),
        if (_gstinController.text.trim().isNotEmpty)
          'gstin': _gstinController.text.trim(),
        if (_panController.text.trim().isNotEmpty)
          'pan': _panController.text.trim(),
        if (_udiseController.text.trim().isNotEmpty)
          'udise_code': _udiseController.text.trim(),
        if (_seatsController.text.trim().isNotEmpty)
          'seats': int.tryParse(_seatsController.text.trim()),
        'brand_color': _brandColor,
        if (_adminUsernameController.text.trim().isNotEmpty)
          'admin_username': _adminUsernameController.text.trim(),
        if (_adminPasswordController.text.trim().isNotEmpty)
          'admin_password': _adminPasswordController.text.trim(),
        // SMTP configuration — always sent (matches web's unconditional
        // `...provisionForm` spread in `handleProvisionSubmit`), empty
        // strings included, so a school can be provisioned with SMTP left
        // blank and configured later in Settings > SMTP Settings.
        'smtp_host': _smtpHostController.text.trim(),
        'smtp_port': int.tryParse(_smtpPortController.text.trim()) ?? 587,
        'smtp_username': _smtpUsernameController.text.trim(),
        'smtp_password': _smtpPasswordController.text.trim(),
        'smtp_from_email': _smtpFromEmailController.text.trim(),
        'smtp_sender_name': _smtpSenderNameController.text.trim(),
        'smtp_use_tls': _smtpUseTls,
      });

      if (_logoBytes != null) {
        try {
          await repository.uploadSchoolLogo(
            result.tenantId,
            _logoBytes!,
            _logoFilename ?? 'logo.png',
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Logo upload failed — school was provisioned successfully.',
                ),
              ),
            );
          }
        }
      }

      // Refresh every screen that shows tenant data — the Schools list, its
      // global stats strip, and the Super Admin Dashboard (a newly
      // provisioned school changes school/plan counts there too).
      ref.invalidate(schoolsProvider);
      ref.invalidate(schoolsGlobalStatsProvider);
      ref.invalidate(schoolTenancyDashboardProvider);
      await _clearDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name provisioned — admin credentials ready below.')),
        );
        await _showCredentialsDialog(result);
        if (mounted) widget.onSaved();
      }
    } catch (e) {
      // `e` (a `SchoolTenancyApiException`) already carries the backend's
      // own descriptive message (which itself may already read like
      // "Provisioning failed: …") — adding another "Provisioning failed: "
      // prefix here produced a visibly doubled message.
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showCredentialsDialog(ProvisionSchoolResultEntity result) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('School provisioned'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant ID: ${result.tenantId}',
              style: AppTextStyles.boardLabel.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (result.adminUsername != null)
              Text(
                'Admin username: ${result.adminUsername}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            if (result.adminPassword != null)
              Text(
                'Admin password: ${result.adminPassword}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            const SizedBox(height: 8),
            const Text(
              'Save these credentials now — they will not be shown again.',
              style: TextStyle(fontSize: 11.5),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // How tenant isolation works
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.purpleTint,
              border: Border.all(color: AppColors.purpleSoft),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How tenant isolation works',
                        style: AppTextStyles.boardLabel.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On submit, Eskoolia provisions a new tenant with an immutable tenant_id, a dedicated DB schema in the '
                        'chosen region, and a sandboxed S3 bucket. All ERP queries run with WHERE tenant_id = :school. '
                        'Zero cross-tenant visibility — only Super Admin can read across.',
                        style: AppTextStyles.sectionSubtitle.copyWith(
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _section('01', 'School identity', [
            _field(
              'School name',
              required: true,
              child: _textCtl(
                _nameController,
                'e.g. Vasavi Vidyalaya Public School',
              ),
            ),
            _field(
              'Short code',
              hint: 'Uppercase',
              required: true,
              child: _textCtl(
                _shortCodeController,
                'VVP-HYD',
                mono: true,
                upper: true,
                maxLength: 10,
              ),
            ),
            _field(
              'Subdomain URL',
              required: !_isEdit,
              hint: _isEdit
                  ? 'Immutable · cannot be changed'
                  : 'Lowercase · no spaces',
              // ONE single bordered box (matches web's actual
              // `overflow-hidden rounded-lg border` group) — "https://" and
              // ".eskoolia.com" are shaded end-caps *inside* this same box
              // (only an inner divider line between each and the input, not
              // a full border of their own), not separate boxes with gaps.
              child: Container(
                height: 46,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.borderSecondary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _urlAffix('https://', isLeft: true),
                    Expanded(
                      child: TextField(
                        controller: _subdomainController,
                        // `readOnly` (not `enabled: false`) for the
                        // immutable-on-edit case — Flutter's `enabled:
                        // false` overrides the rendered text to a greyed
                        // "disabled" color regardless of `style.color`,
                        // which is exactly what made typed text hard to
                        // see. `readOnly` blocks editing without touching
                        // color at all, matching web's own
                        // `readOnly={!!editSchool}` (web dims the whole
                        // group via a separate opacity wrapper instead —
                        // not per-character text greying).
                        readOnly: _isEdit,
                        textAlign: TextAlign.left,
                        textAlignVertical: TextAlignVertical.center,
                        // Deliberately bold + pure black + larger than the
                        // 12px affixes, so the typed value is unmistakably
                        // the visual focus of this field, not the muted
                        // "https://"/".eskoolia.com" chrome around it. No
                        // explicit `height` on the style — the previous
                        // `isCollapsed`+zero-padding box left the IME no
                        // vertical room to draw its own underlined
                        // "composing" span while typing, which rendered as
                        // garbled/overlapping glyphs instead of the actual
                        // text (an Android input-method rendering quirk,
                        // not a color/visibility bug — the plain
                        // `contentPadding` below gives it that room back).
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        cursorColor: AppColors.primaryPurple,
                        cursorWidth: 2,
                        // Matches web's `maxLength={63}` — the one real
                        // input constraint the web field has. No
                        // `counterText` shown, matching web (a native
                        // HTML maxlength attribute has no visible
                        // counter either).
                        maxLength: 63,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          hintText: 'vasavi-hyd',
                          hintStyle: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w400),
                          filled: false,
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    _urlAffix('.eskoolia.com', isLeft: false),
                  ],
                ),
              ),
            ),
            _field(
              'School type',
              required: true,
              child: _decorativeDropdown('school_type', const [
                'K-12 · Day school',
                'K-12 · Residential',
                'Pre-primary only',
                'Secondary only',
                'Higher Secondary / Jr. College',
              ]),
            ),
            _field(
              'Established year',
              child: _decorativeText(
                'established_year',
                hint: '1998',
                number: true,
              ),
            ),
            _field(
              'Medium of instruction',
              child: _decorativeDropdown('medium', const [
                'English',
                'English & Hindi',
                'English & Telugu',
                'Telugu',
              ]),
            ),
            _field(
              'Academic year start',
              child: _acadYearField(),
            ),
          ]),

          _section('02', 'Board affiliation', [
            _field(
              'Board',
              required: true,
              child: AppDropdown<String>(
                value: _board,
                items: _withCurrentValue(
                  _kBoardOptions
                      .map(
                        (o) => DropdownMenuItem(
                          value: o[0],
                          child: Text(o[1], overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  _board,
                ),
                onChanged: (v) => setState(() => _board = v ?? 'OTHER'),
              ),
            ),
            _field(
              'Affiliation number',
              child: _decorativeText(
                'affiliation_no',
                hint: 'CBSE/AFF/930451',
                mono: true,
              ),
            ),
            _field(
              'UDISE+ code',
              hint: '11 digits',
              child: _textCtl(
                _udiseController,
                '36050200101',
                mono: true,
                maxLength: 11,
              ),
            ),
            _field(
              'State',
              required: true,
              child: AppDropdown<String>(
                value: _stateCode,
                hint: const Text(
                  'Select state…',
                  style: TextStyle(fontSize: 13),
                ),
                items: _withCurrentValue(
                  _kStateOptions
                      .map(
                        (o) => DropdownMenuItem(
                          value: o[0],
                          child: Text('${o[1]} (${o[0]})'),
                        ),
                      )
                      .toList(),
                  _stateCode,
                ),
                onChanged: (v) => setState(() => _stateCode = v),
              ),
            ),
            _field(
              'Affiliation valid till',
              child: _decorativeDate(
                'affiliation_valid',
                DateTime(2030, 3, 31),
              ),
            ),
          ]),

          _section('03', 'Branding', [
            _field('School logo', child: _logoPicker()),
            _field('Primary brand color', child: _colorPicker()),
          ]),

          _section('04', 'Principal & primary contact', [
            _field(
              'Principal name',
              required: true,
              child: _decorativeText('principal_name', hint: 'Dr. M. Iyer'),
            ),
            _field(
              'Designation',
              child: _decorativeText('designation', initial: 'Principal'),
            ),
            _field(
              'Email',
              required: true,
              child: _decorativeText(
                'principal_email',
                hint: 'principal@school.edu.in',
              ),
            ),
            _field(
              'Mobile',
              required: true,
              child: _mobileField(),
            ),
            _field(
              'Alternate contact',
              child: _decorativeText('alt_contact', hint: '+91 98765 43211'),
            ),
            _field(
              'Owner role at school',
              child: _decorativeDropdown('owner_role', const [
                'Principal',
                'Correspondent',
                'Trustee / Secretary',
                'Owner / Founder',
                'IT Admin',
              ]),
            ),
          ]),

          _section('05', 'Campus address & geography', [
            _field(
              'Street address',
              child: _decorativeText(
                'street',
                hint: 'Plot 22, Road No. 12, Banjara Hills',
                lines: 3,
              ),
            ),
            _field(
              'City',
              child: _decorativeText('city', hint: 'Hyderabad'),
            ),
            _field(
              'State',
              child: _decorativeDropdown(
                'campus_state',
                _kStateOptions.map((o) => '${o[1]} (${o[0]})').toList(),
              ),
            ),
            _field(
              'PIN code',
              child: _decorativeText(
                'pin',
                hint: '500034',
                mono: true,
                maxLength: 6,
              ),
            ),
          ]),

          _section('06', 'GST & legal', [
            _field(
              'GST registration',
              child: _decorativeDropdown('gst_reg', const [
                'GST-registered',
                'Unregistered (exempt)',
              ]),
            ),
            _field(
              'GSTIN',
              hint: '15 chars',
              child: _textCtl(
                _gstinController,
                '36AAACE9988K1ZP',
                mono: true,
                upper: true,
                maxLength: 15,
              ),
            ),
            _field(
              'PAN',
              required: true,
              child: _textCtl(
                _panController,
                'AAACE9988K',
                mono: true,
                upper: true,
                maxLength: 10,
              ),
            ),
            _field(
              'Legal entity name',
              child: _decorativeText(
                'entity_name',
                hint: 'Vasavi Educational Trust',
              ),
            ),
            _field(
              'Entity type',
              child: _decorativeDropdown('entity_type', const [
                'Educational Trust',
                'Society (Reg. Soc. Act 1860)',
                'Section 8 Company',
                'Private Limited',
                'Sole proprietorship',
              ]),
            ),
            _field(
              'Trust / Reg. number',
              child: _decorativeText(
                'reg_no',
                hint: 'AP/2008/SOC/01122',
                mono: true,
              ),
            ),
          ]),

          _section('07', 'Plan & capacity limits', [
            _field(
              'Subscription plan',
              required: true,
              child: Builder(
                builder: (context) {
                  final plansAsync = ref.watch(plansProvider);
                  final catalogPlans = plansAsync.maybeWhen(
                    data: (catalog) => catalog.plans,
                    orElse: () => const <SubscriptionPlanEntity>[],
                  );
                  final options = catalogPlans.isNotEmpty
                      ? catalogPlans
                            .map((p) => [p.code, p.name])
                            .toList()
                      : _kPlanFallbackOptions;
                  return AppDropdown<String>(
                    value: _plan,
                    items: _withCurrentValue(
                      options
                          .map(
                            (o) => DropdownMenuItem(
                              value: o[0],
                              child: Text(o[1], overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      _plan,
                    ),
                    onChanged: (v) => setState(() => _plan = v ?? 'trial'),
                  );
                },
              ),
            ),
            _field(
              'Trial period',
              child: _decorativeDropdown('trial_period', const [
                '30 days',
                '14 days',
                'No trial',
              ]),
            ),
            _field(
              'Go-live date',
              child: _decorativeDate('go_live', DateTime(2026, 6, 1)),
            ),
            _field(
              'Student seat limit',
              child: _textCtl(_seatsController, '2000', number: true),
            ),
            _field(
              'Staff seat limit',
              child: _decorativeText(
                'staff_seats',
                initial: '200',
                number: true,
              ),
            ),
            _field(
              'Storage cap',
              hint: 'GB',
              child: _decorativeText(
                'storage_cap',
                initial: '50',
                number: true,
              ),
            ),
            _field(
              'Billing cycle',
              child: _decorativeDropdown('billing_cycle', const [
                'Annual · pay upfront',
                'Half-yearly',
                'Quarterly',
                'Monthly',
              ]),
            ),
          ]),

          _section('08', 'Data residency & provisioning', [
            _field(
              'Tenant ID',
              hint: 'Auto · immutable',
              child: _lockedField(
                widget.editSchool?.tenantId ?? 'Auto-generated',
              ),
            ),
            _field(
              'DB shard region',
              child: AppDropdown<String>(
                value: _shardRegion,
                items: _withCurrentValue(const [
                  DropdownMenuItem(
                    value: 'ap-south-1',
                    child: Text('ap-south-1 · Mumbai'),
                  ),
                  DropdownMenuItem(
                    value: 'ap-south-2',
                    child: Text('ap-south-2 · Hyderabad'),
                  ),
                ], _shardRegion),
                onChanged: (v) =>
                    setState(() => _shardRegion = v ?? 'ap-south-1'),
              ),
            ),
            _field(
              'Storage bucket',
              child: _lockedField(
                _isEdit
                    ? 'eskoolia-${widget.editSchool!.tenantId.toLowerCase().replaceAll('_', '-')}'
                    : 'Auto-generated',
              ),
            ),
            _field(
              'Backup retention',
              child: AppDropdown<String>(
                value: _backupRetention.toString(),
                items: _withCurrentValue(const [
                  DropdownMenuItem(
                    value: '30',
                    child: Text('30 days · daily snapshots'),
                  ),
                  DropdownMenuItem(value: '90', child: Text('90 days')),
                  DropdownMenuItem(value: '365', child: Text('1 year')),
                ], _backupRetention.toString()),
                onChanged: (v) => setState(
                  () => _backupRetention = int.tryParse(v ?? '30') ?? 30,
                ),
              ),
            ),
            _field(
              'SSO method',
              child: AppDropdown<String>(
                value: _ssoMethod,
                items: _withCurrentValue(const [
                  DropdownMenuItem(
                    value: 'native',
                    child: Text('Email + password'),
                  ),
                  DropdownMenuItem(
                    value: 'google',
                    child: Text('Google Workspace'),
                  ),
                  DropdownMenuItem(
                    value: 'microsoft',
                    child: Text('Microsoft 365'),
                  ),
                  DropdownMenuItem(value: 'saml', child: Text('SAML 2.0')),
                ], _ssoMethod),
                onChanged: (v) => setState(() => _ssoMethod = v ?? 'native'),
              ),
            ),
            _field(
              'API access',
              child: AppDropdown<String>(
                value: _apiAccess,
                items: const [
                  DropdownMenuItem(
                    value: 'disabled',
                    child: Text('Disabled (default)'),
                  ),
                  DropdownMenuItem(
                    value: 'enabled',
                    child: Text('Enabled (read + write)'),
                  ),
                ],
                onChanged: (v) => setState(() => _apiAccess = v ?? 'disabled'),
              ),
            ),
          ]),

          if (!_isEdit)
            _section('09', 'Admin login credentials', [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'These credentials let the school admin log in to the ERP portal. Fill them in manually, or tap Generate — '
                  'either way they appear in a dialog after provisioning.',
                  style: AppTextStyles.sectionSubtitle.copyWith(
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ),
              _field(
                'Admin username',
                hint: 'Lowercase · no spaces · e.g. vasavi_admin',
                child: _adminUsernameField(),
              ),
              _field(
                'Admin password',
                hint: 'Min 10 chars · mix of letters, numbers, symbols',
                child: Row(
                  children: [
                    Expanded(
                      child: _textCtl(
                        _adminPasswordController,
                        'Leave blank to auto-generate',
                        mono: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.refresh, size: 13),
                      label: const Text('Generate'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),

          if (!_isEdit)
            _section(
              '10',
              'SMTP configuration',
              [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    border: Border.all(color: AppColors.borderSecondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Many schools don't know how to configure this themselves. Fill it in now so email "
                          '(fee reminders, notices, credential resets) works immediately — or leave blank and '
                          'set it up later in Settings > SMTP Settings.',
                          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, height: 1.55),
                        ),
                      ),
                    ],
                  ),
                ),
                _field(
                  'SMTP host',
                  hint: 'e.g. smtp.gmail.com',
                  child: _textCtl(_smtpHostController, 'smtp.gmail.com'),
                ),
                _field(
                  'Port',
                  child: _textCtl(_smtpPortController, '587', number: true),
                ),
                _field(
                  'Username',
                  child: _textCtl(_smtpUsernameController, 'smtp username'),
                ),
                _field(
                  'Password',
                  child: _textCtl(_smtpPasswordController, 'smtp password / app password'),
                ),
                _field(
                  'From email',
                  hint: 'Must be set if host is set',
                  child: _textCtl(_smtpFromEmailController, 'noreply@school.edu.in'),
                ),
                _field(
                  'Sender name',
                  child: _textCtl(_smtpSenderNameController, 'Vasavi Vidyalaya Public School'),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _smtpUseTls,
                      onChanged: (v) => setState(() => _smtpUseTls = v ?? true),
                    ),
                    const Text(
                      'Use TLS',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              note: 'Optional — can also be set up later',
            ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isEdit
                        ? 'Tenant ID & subdomain are immutable. Only name, plan, board, state and regions can be changed.'
                        : 'Tenant ID & subdomain are immutable once provisioned. A welcome email is sent to the principal automatically.',
                    style: AppTextStyles.sectionSubtitle.copyWith(
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.dangerRed,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : widget.onCancel,
                  // Explicit shape/color — the app theme has no
                  // `outlinedButtonTheme`, so this would otherwise fall back
                  // to Material 3's default `StadiumBorder` (pill) shape and
                  // purple text, unlike web's flat, black-text ghost button.
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _saveDraft,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Save as draft'),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    _submitting
                        ? (_isEdit ? 'Saving…' : 'Provisioning…')
                        : (_isEdit ? 'Save changes' : 'Provision school'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Layout helpers ─────────────────────────────────────────────────────

  Widget _section(String num, String title, List<Widget> fields, {String? note}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
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
                decoration: BoxDecoration(
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  num,
                  style: AppTextStyles.numberedBadge.copyWith(
                    color: AppColors.purpleDeep,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // `Expanded`+ellipsis — this bare `Text` had no shrink
              // fallback, and several section titles ("Admin login
              // credentials", "Principal & primary contact", "Campus
              // address & geography") are long enough to overflow this
              // Row's available width (~284px) on a 320dp phone by itself.
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
                ),
              ),
              // Matches web's `<span className="ml-auto ... normal-case
              // tracking-normal text-[var(--ink-4)]">` next to "SMTP
              // configuration" — `Flexible` (not a fixed-width `Text`) so
              // it shrinks instead of overflowing on a narrow screen.
              if (note != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    note,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w400, color: AppColors.textQuaternary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...fields,
        ],
      ),
    );
  }

  Widget _field(
    String label, {
    bool required = false,
    String? hint,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.sectionSubtitle.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(color: AppColors.dangerRed, fontSize: 11.5),
                ),
              if (hint != null) ...[
                const SizedBox(width: 8),
                // `Expanded`+right-align (not a bare `Spacer` + `Text`) —
                // a `Spacer` only claims whatever space happens to be left
                // over, which doesn't stop the trailing hint `Text` from
                // overflowing the Row on the right when it's long (e.g.
                // "Min 10 chars · mix of letters, numbers, symbols" for
                // Admin password). `Expanded` claims all remaining width
                // and right-aligns the hint within it — visually identical
                // to "pushed flush right" — while letting it ellipsize
                // instead of overflowing if it still doesn't fit.
                Expanded(
                  child: Text(
                    hint,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  /// Appends [value] as an extra item (labeled with its own raw string) if
  /// it isn't already among [base]'s values. Without this, editing a real
  /// school whose stored value predates the current fixed option list (e.g.
  /// `plan: 'starter'`/`'standard'` — real values seen in the
  /// `subscription_plans` table but not in `main`'s create-time
  /// `ProvisionSchoolRequestSerializer` choices — or `shard_region:
  /// 'default'`, the literal fallback `SchoolTenantProvisionView` writes
  /// when a region isn't supplied) crashes with `DropdownButton`'s "exactly
  /// one item with this value" assertion, since a value with zero matching
  /// items is just as invalid as one with two. This keeps the school's real
  /// stored value visible and preserved on save instead of silently
  /// snapping it to a default the moment the form opens.
  List<DropdownMenuItem<String>> _withCurrentValue(
    List<DropdownMenuItem<String>> base,
    String? value,
  ) {
    if (value == null || value.isEmpty) return base;
    if (base.any((item) => item.value == value)) return base;
    return [...base, DropdownMenuItem(value: value, child: Text(value))];
  }

  InputDecoration _fieldDecoration({String? hintText, bool noBorder = false}) {
    final border = noBorder
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderPrimary),
          );
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      filled: !noBorder,
      fillColor: AppColors.bgSecondary,
      border: border,
      enabledBorder: noBorder ? InputBorder.none : border,
      focusedBorder: noBorder
          ? InputBorder.none
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryPurple,
                width: 2,
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _textCtl(
    TextEditingController controller,
    String hint, {
    bool mono = false,
    bool upper = false,
    bool number = false,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      textCapitalization: upper
          ? TextCapitalization.characters
          : TextCapitalization.none,
      onChanged: upper
          ? (v) {
              final u = v.toUpperCase();
              if (u != v) {
                controller.value = controller.value.copyWith(
                  text: u,
                  selection: TextSelection.collapsed(offset: u.length),
                );
              }
            }
          : null,
      style: TextStyle(fontFamily: mono ? 'monospace' : null, fontSize: 13),
      decoration: _fieldDecoration(hintText: hint).copyWith(counterText: ''),
    );
  }

  /// Admin username — matches web's real behavior exactly: manual and
  /// optional (left blank, the backend auto-generates
  /// `{subdomain}_admin` — `SchoolTenantProvisionView.post()`), with a
  /// placeholder that live-updates to the actual subdomain, and live
  /// lowercase + underscore formatting as you type
  /// (`e.target.value.toLowerCase().replace(/\s/g, '_')` in
  /// `schools/page.tsx`).
  Widget _adminUsernameField() {
    final sub = _subdomainController.text.trim().toLowerCase();
    final placeholder = sub.isNotEmpty
        ? '${sub.replaceAll('-', '_')}_admin'
        : 'Auto: subdomain_admin';
    return TextField(
      controller: _adminUsernameController,
      style: const TextStyle(fontSize: 13),
      decoration: _fieldDecoration(hintText: placeholder).copyWith(
        counterText: '',
      ),
      onChanged: (v) {
        final formatted = v.toLowerCase().replaceAll(RegExp(r'\s'), '_');
        if (formatted != v) {
          _adminUsernameController.value = _adminUsernameController.value
              .copyWith(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
        }
      },
    );
  }

  /// Principal mobile — real, validated field matching web's exact rule
  /// (`RE_MOBILE_IN = /^[6-9]\d{9}$/` in `schools/page.tsx`): digits only,
  /// exactly 10, must start 6-9. Still not part of the create payload —
  /// neither `main` nor `demo`'s `SchoolTenant` model has a
  /// `principal_phone` column reachable from `ProvisionSchoolRequestSerializer`
  /// on the currently-running backend (`main`), so, like the other
  /// decorative fields in this class, it's genuinely validated but not
  /// submitted.
  Widget _mobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(fontSize: 13),
          decoration: _fieldDecoration(hintText: '98765 43210')
              .copyWith(counterText: ''),
          onChanged: (v) => setState(() {
            if (v.isEmpty) {
              _mobileError = null;
            } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
              _mobileError = v.length < 10
                  ? 'Enter 10 digits.'
                  : 'Must start with 6-9.';
            } else {
              _mobileError = null;
            }
          }),
        ),
        if (_mobileError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _mobileError!,
              style: const TextStyle(
                color: AppColors.dangerRed,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  /// A field visible and interactive on web but never read by
  /// `handleProvisionSubmit`/`updateSchool` — see class doc comment.
  Widget _decorativeText(
    String key, {
    String? hint,
    String? initial,
    bool mono = false,
    bool number = false,
    int lines = 1,
    int? maxLength,
    bool noBorder = false,
  }) {
    return TextFormField(
      initialValue: (_decorative[key] as String?) ?? initial,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLines: lines,
      maxLength: maxLength,
      style: TextStyle(fontFamily: mono ? 'monospace' : null, fontSize: 13),
      onChanged: (v) => _decorative[key] = v,
      decoration: _fieldDecoration(
        hintText: hint,
        noBorder: noBorder,
      ).copyWith(counterText: ''),
    );
  }

  /// "Academic year start" picker matching web's real behavior exactly:
  /// a dropdown of computed year labels plus a "+" button that opens an
  /// inline start/end month+year add-form (same duplicate / same-month /
  /// end-before-start checks as `schools/page.tsx`'s `acadYearDraft`
  /// validation). Purely client-side — never submitted (see class doc
  /// comment; `ProvisionSchoolRequestSerializer` has no such field).
  Widget _acadYearField() {
    if (_addingAcadYear) {
      final startYear = _acadStartYearController.text;
      final endYear = _acadEndYearController.text;
      final label = '$_acadStartMonth $startYear – $_acadEndMonth $endYear';
      final isDup = _acadYears.contains(label);
      final startVal =
          (int.tryParse(startYear) ?? 0) * 12 +
          _kMonths.indexOf(_acadStartMonth);
      final endVal =
          (int.tryParse(endYear) ?? 0) * 12 + _kMonths.indexOf(_acadEndMonth);
      final isSameMonth = endVal == startVal;
      final isEndBefore = endVal < startVal;
      final hasError = isDup || isSameMonth || isEndBefore;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _monthYearPicker(isStart: true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('–'),
              ),
              Expanded(child: _monthYearPicker(isStart: false)),
            ],
          ),
          if (isEndBefore)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'End month must come after start month.',
                style: TextStyle(color: AppColors.dangerRed, fontSize: 11),
              ),
            ),
          if (isSameMonth)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Start and end cannot be the same month.',
                style: TextStyle(color: AppColors.dangerRed, fontSize: 11),
              ),
            ),
          if (isDup)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '"$label" is already in the list.',
                style: const TextStyle(color: Colors.amber, fontSize: 11),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton(
                onPressed: hasError
                    ? null
                    : () => setState(() {
                        _acadYears = [label, ..._acadYears];
                        _acadYearSelected = label;
                        _addingAcadYear = false;
                      }),
                child: const Text('Add'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _addingAcadYear = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      );
    }
    final options = _acadYears.toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (_acadYearSelected == null || !options.contains(_acadYearSelected)) {
      _acadYearSelected = options.isNotEmpty ? options.first : null;
    }
    return Row(
      children: [
        Expanded(
          child: AppDropdown<String>(
            value: _acadYearSelected,
            items: options
                .map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(o, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _acadYearSelected = v),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          height: 36,
          child: OutlinedButton(
            onPressed: () => setState(() => _addingAcadYear = true),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _monthYearPicker({required bool isStart}) {
    final month = isStart ? _acadStartMonth : _acadEndMonth;
    final yearController = isStart
        ? _acadStartYearController
        : _acadEndYearController;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AppDropdown<String>(
            value: month,
            items: _kMonths
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() {
              if (v == null) return;
              if (isStart) {
                _acadStartMonth = v;
              } else {
                _acadEndMonth = v;
              }
            }),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextField(
            controller: yearController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: const TextStyle(fontSize: 13),
            decoration: _fieldDecoration(hintText: 'YYYY').copyWith(
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _decorativeDropdown(String key, List<String> options) {
    return AppDropdown<String>(
      value: (_decorative[key] as String?) ?? options.first,
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _decorative[key] = v),
    );
  }

  Widget _decorativeDate(String key, DateTime initial) {
    final value = (_decorative[key] as DateTime?) ?? initial;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _decorative[key] = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
          style: AppTextStyles.boardLabel.copyWith(fontSize: 13),
        ),
      ),
    );
  }

  Widget _lockedField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: AppTextStyles.sectionSubtitle.copyWith(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  /// One end-cap of the Subdomain URL group — matches web's `<span
  /// className="border-r|border-l border-[var(--bd-2)] bg-[var(--bg-2)]
  /// px-[11px] font-mono text-[12px] text-[var(--ink-3)]">`: shaded, with
  /// only an inner divider border on the side facing the input (the outer
  /// group `Container` supplies the actual outline) — both end-caps and the
  /// input live inside that one shared box, not separate boxes of their own.
  Widget _urlAffix(String text, {required bool isLeft}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          right: isLeft ? const BorderSide(color: AppColors.borderSecondary) : BorderSide.none,
          left: isLeft ? BorderSide.none : const BorderSide(color: AppColors.borderSecondary),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Gradient initials avatar — the logo picker's empty/error state.
  /// Matches web's own fallback exactly: real initials computed from the
  /// entered school name, falling back to the literal 'VV' placeholder
  /// only when no name has been typed yet
  /// (`provisionForm.name ? schoolInitials(provisionForm.name) : 'VV'`).
  Widget _logoPlaceholder() {
    final name = _nameController.text.trim();
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isEmpty
        ? 'VV'
        : words.length >= 2
            ? '${words[0][0]}${words[1][0]}'.toUpperCase()
            : words[0].substring(0, words[0].length < 2 ? 1 : 2).toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5BFF), Color(0xFF5836E0)],
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _logoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickLogo,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              border: Border.all(
                color: AppColors.borderSecondary,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                if (_logoBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.memory(
                      _logoBytes!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  )
                else if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      _existingLogoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      // The backend's `logo_url` is `blank=True` (empty
                      // string, not null) for schools without a logo, and
                      // some stored URLs 404 to an HTML error page rather
                      // than an image — both crashed this widget with an
                      // `ImageCodecException` before this fallback existed.
                      errorBuilder: (context, error, stackTrace) => _logoPlaceholder(),
                    ),
                  )
                else
                  _logoPlaceholder(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _logoFilename ?? 'Tap to choose a PNG, SVG or JPG',
                        style: AppTextStyles.boardLabel.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '1:1 ratio · max 1 MB',
                        style: AppTextStyles.sectionSubtitle.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_logoBytes != null)
          TextButton(
            onPressed: () => setState(() {
              _logoBytes = null;
              _logoFilename = null;
            }),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Remove selected file',
              style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _colorPicker() {
    return Wrap(
      spacing: 8,
      children: _kPaletteColors.map((hex) {
        final selected = _brandColor == hex;
        final color = Color(int.parse('FF${hex.substring(1)}', radix: 16));
        return InkWell(
          onTap: () => setState(() => _brandColor = hex),
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected ? AppColors.textPrimary : Colors.transparent,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(
                    Icons.circle_outlined,
                    color: Colors.white,
                    size: 14,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
