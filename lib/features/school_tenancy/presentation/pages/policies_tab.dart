import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../domain/entities/policy_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Matches web's `CAT_CONFIG` exactly (`policies/page.tsx:16-21`) — the
/// per-category header (icon badge + label + description) shown above each
/// tab's policy list, previously missing from Flutter entirely (each tab
/// just showed the bare policy rows with no heading).
class _CategoryMeta {
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _CategoryMeta({required this.label, required this.description, required this.icon, required this.color});
}

const _kCategoryMeta = {
  'security': _CategoryMeta(label: 'Security', description: 'Authentication, session & access controls', icon: Icons.shield_outlined, color: Color(0xFFDC2626)),
  'data_isolation': _CategoryMeta(label: 'Data Isolation', description: 'Tenancy boundaries & audit retention', icon: Icons.storage_outlined, color: Color(0xFF0369A1)),
  'billing': _CategoryMeta(label: 'Billing', description: 'GST rates & invoice payment terms', icon: Icons.bolt_outlined, color: Color(0xFF6D28D9)),
  'system': _CategoryMeta(label: 'System', description: 'Infrastructure, backups & tenancy switches', icon: Icons.settings_outlined, color: Color(0xFF059669)),
};

/// Super Admin Policies Page
/// Exact conversion of web frontend policies structure
class SuperAdminPoliciesPage extends ConsumerStatefulWidget {
  const SuperAdminPoliciesPage({super.key});

  @override
  ConsumerState<SuperAdminPoliciesPage> createState() => _SuperAdminPoliciesPageState();
}

class _SuperAdminPoliciesPageState extends ConsumerState<SuperAdminPoliciesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _draftToggles = {};
  final Map<String, num> _draftNumbers = {};
  final Map<String, TextEditingController> _numberControllers = {};
  bool _saving = false;
  bool _exportingFormat = false;

  /// Exports policies as JSON/YAML — mirrors web's `exportPolicies()`
  /// (`GET /policies/export/?format=`).
  Future<void> _handleExportPolicies(String format) async {
    setState(() => _exportingFormat = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final bytes = await repository.exportPolicies(format);
      await saveBytesForDownload(bytes: bytes, filename: 'policies.$format');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policies exported.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingFormat = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _numberControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Reuses one controller per policy key instead of constructing a new one
  /// on every rebuild (the old code did `TextEditingController(text: ...)`
  /// inline in `build()`, which reset the cursor/selection on every keystroke).
  TextEditingController _controllerFor(String key, num initialValue) {
    return _numberControllers.putIfAbsent(key, () => TextEditingController(text: initialValue.toString()));
  }

  Widget _buildCategoryTab(IconData icon, String label, Color color) {
    // `Flexible`+ellipsis on the label (not a bare `Text`) — a non-scrollable
    // 4-tab `TabBar` gives each tab a fixed, fairly narrow width slice on
    // phone-width screens, and the un-constrained Row previously overflowed
    // horizontally at that width (reproduced via widget test at 360-400px).
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPolicyRow({
    required String key,
    required String description,
    required bool isToggle,
    required bool isOverridable,
    required dynamic value,
    required bool isDirty,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDirty ? AppColors.purpleTint : AppColors.bgPrimary,
        border: Border.all(
          color: isDirty ? AppColors.purpleSoft : AppColors.borderPrimary,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key and badges
          Row(
            children: [
              Expanded(
                child: Text(
                  key,
                  style: AppTextStyles.policyKey,
                ),
              ),
              if (!isOverridable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    border: Border.all(color: AppColors.borderPrimary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'locked',
                    style: AppTextStyles.chipLabel().copyWith(fontSize: 9),
                  ),
                ),
              if (isDirty) const SizedBox(width: 6),
              if (isDirty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purpleTint,
                    border: Border.all(color: AppColors.purpleSoft),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'unsaved',
                    style: AppTextStyles.chipLabel(color: AppColors.purpleDeep).copyWith(fontSize: 9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),

          // Control
          if (isToggle)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                  value: _draftToggles[key] ?? (value as bool),
                  onChanged: (val) => setState(() => _draftToggles[key] = val),
                  activeTrackColor: AppColors.primaryPurple,
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.policyKey.copyWith(fontSize: 12),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderPrimary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AppColors.bgSecondary,
                    ),
                    controller: _controllerFor(key, (value as num)),
                    onChanged: (val) {
                      final parsed = num.tryParse(val);
                      if (parsed != null) setState(() => _draftNumbers[key] = parsed);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(policiesProvider);
    final refreshing = policiesAsync.isLoading;

    if (policiesAsync.isLoading && !policiesAsync.hasValue) {
      return const SchoolTenancyLayout(
        currentPath: '/super-admin/policies',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (policiesAsync.hasError && !policiesAsync.hasValue) {
      return SchoolTenancyLayout(
        currentPath: '/super-admin/policies',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load policies.\n${policiesAsync.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageSubtitle,
            ),
          ),
        ),
      );
    }

    final policiesState = policiesAsync.value!;

    return SchoolTenancyLayout(
      currentPath: '/super-admin/policies',
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          child: Column(
          children: [
            // PAGE HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      Text('Policies', style: AppTextStyles.pageTitle),
                      Text('& Settings', style: AppTextStyles.pageTitleAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Platform-wide configuration and feature controls',
                    style: AppTextStyles.pageSubtitle,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showPlatformSettings(context),
                        icon: const Icon(Icons.tune, size: 14),
                        label: const Text('Platform Settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: AppTextStyles.buttonSecondary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showQuickActions(context, [
                          ...policiesState.security,
                          ...policiesState.dataIsolation,
                          ...policiesState.billing,
                          ...policiesState.system,
                        ]),
                        icon: const Icon(Icons.lock_outline, size: 14),
                        label: const Text('Quick Actions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: AppTextStyles.buttonSecondary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: refreshing
                            ? null
                            : () {
                                setState(() {
                                  _draftToggles.clear();
                                  _draftNumbers.clear();
                                  for (final controller in _numberControllers.values) {
                                    controller.dispose();
                                  }
                                  _numberControllers.clear();
                                });
                                ref.invalidate(policiesProvider);
                              },
                        icon: refreshing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 14),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: AppTextStyles.buttonSecondary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _exportingFormat ? null : () => _handleExportPolicies('json'),
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text('JSON'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: AppTextStyles.buttonSecondary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _exportingFormat ? null : () => _handleExportPolicies('yaml'),
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text('YAML'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: AppTextStyles.buttonSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // CATEGORY TABS
            Container(
              decoration: const BoxDecoration(
                color: AppColors.bgPrimary,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderPrimary),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryPurple,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryPurple,
                indicatorWeight: 2,
                tabs: [
                  _buildCategoryTab(Icons.shield_outlined, 'Security', const Color(0xFFDC2626)),
                  _buildCategoryTab(Icons.storage_outlined, 'Data Isolation', const Color(0xFF0369A1)),
                  _buildCategoryTab(Icons.bolt_outlined, 'Billing', const Color(0xFF6D28D9)),
                  _buildCategoryTab(Icons.settings_outlined, 'System', const Color(0xFF059669)),
                ],
              ),
            ),

            // TAB CONTENT
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryContent(policiesState.security, _kCategoryMeta['security']!),
                  _buildCategoryContent(policiesState.dataIsolation, _kCategoryMeta['data_isolation']!),
                  _buildCategoryContent(policiesState.billing, _kCategoryMeta['billing']!),
                  _buildCategoryContent(policiesState.system, _kCategoryMeta['system']!),
                ],
              ),
            ),

            // SAVE BAR — matches web exactly (`policies/page.tsx:376-387`):
            // a pending-change count plus a single Save button. Web has no
            // separate Reset/Discard control in this bar.
            Builder(builder: (context) {
              final allPolicies = [
                ...policiesState.security,
                ...policiesState.dataIsolation,
                ...policiesState.billing,
                ...policiesState.system,
              ];
              final dirtyCount = allPolicies.where(_isDirty).length;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border(top: BorderSide(color: AppColors.borderPrimary)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // `Expanded`+ellipsis (not a bare `Text`) — at narrow
                    // phone widths the unsaved-changes label and the Save
                    // button together overflowed horizontally (reproduced
                    // via widget test at 360px width).
                    Expanded(
                      child: Text(
                        dirtyCount > 0
                            ? '$dirtyCount unsaved change${dirtyCount > 1 ? 's' : ''}'
                            : 'No pending changes',
                        style: AppTextStyles.sectionSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: (_saving || dirtyCount == 0) ? null : () => _handleSave(allPolicies),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(_saving ? 'Saving…' : 'Save changes'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),      ),    );
  }

  bool _isDirty(PolicyEntity policy) {
    if (_draftToggles.containsKey(policy.key)) {
      return _draftToggles[policy.key] != policy.value;
    }
    if (_draftNumbers.containsKey(policy.key)) {
      return _draftNumbers[policy.key]!.toDouble() != (policy.value as num).toDouble();
    }
    return false;
  }

  Future<void> _handleSave(List<PolicyEntity> allPolicies) async {
    final updates = <String, dynamic>{};
    for (final policy in allPolicies) {
      if (_isDirty(policy)) {
        updates[policy.key] = _draftToggles[policy.key] ?? _draftNumbers[policy.key];
      }
    }
    if (updates.isEmpty) return;

    setState(() => _saving = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      await repository.updatePolicies(updates);
      ref.invalidate(policiesProvider);
      setState(() {
        _draftToggles.clear();
        _draftNumbers.clear();
        for (final controller in _numberControllers.values) {
          controller.dispose();
        }
        _numberControllers.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policies saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed — check your connection and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Quick Actions — converted from web's `policies/page.tsx:423-441`
  /// sidebar card (adapted to a bottom sheet, matching the same
  /// sidebar-panel→bottom-sheet pattern already used for Platform
  /// Settings above). On the real, currently-running web app all 3
  /// buttons there are inert stubs (no `onClick`, no confirmation, no API
  /// call, no backend support at all for MFA enforcement or session
  /// revocation — confirmed directly against both the live frontend and
  /// backend source). "Reset to defaults" IS made real here — it only
  /// needs the already-real `GET`/`PATCH /policies/` endpoints (using the
  /// `default_value` the GET response already returns per policy), so it
  /// doesn't require any backend change or invented data. "Force MFA
  /// enrollment" and "Flush all sessions" have no backend to connect to
  /// at all (no MFA/session-revocation infrastructure exists anywhere in
  /// this codebase), so tapping them surfaces that honestly via a
  /// SnackBar — the same "not available" disclosure pattern already used
  /// by this file's JSON/YAML export buttons above, rather than either
  /// silently doing nothing or fabricating a fake success.
  void _showQuickActions(BuildContext context, List<PolicyEntity> allPolicies) {
    var resetting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('Quick Actions', style: AppTextStyles.sectionTitle.copyWith(fontSize: 15)),
                    ]),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                  ],
                ),
                const SizedBox(height: 12),
                _quickActionButton(
                  title: 'Reset to defaults',
                  subtitle: 'Restore all policies to their default values',
                  loading: resetting,
                  onTap: () async {
                    final confirmed = await _confirmResetDialog(sheetContext);
                    if (confirmed != true) return;
                    setSheetState(() => resetting = true);
                    final result = await _handleResetToDefaults(allPolicies);
                    setSheetState(() => resetting = false);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(result)));
                    }
                  },
                ),
                const SizedBox(height: 8),
                _quickActionButton(
                  title: 'Force MFA enrollment',
                  subtitle: 'Send MFA setup emails to all admins',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Force MFA enrollment is not available — no backend support exists for this action yet.')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _quickActionButton(
                  title: 'Flush all sessions',
                  subtitle: 'Immediately invalidate all active user sessions',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Flushing sessions is not available — no backend support exists for this action yet.')),
                    );
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<bool?> _confirmResetDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all policies to defaults?'),
        content: const Text('This restores every policy value to its platform default. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed, foregroundColor: Colors.white),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Builds the PATCH payload from each policy's real `default_value`
  /// (already returned by `GET /policies/`, see [PolicyEntity.defaultValue])
  /// and calls the same real `updatePolicies` endpoint the Save bar uses.
  /// Returns a short user-facing result message (success or failure).
  Future<String> _handleResetToDefaults(List<PolicyEntity> allPolicies) async {
    final updates = <String, dynamic>{};
    for (final policy in allPolicies) {
      if (policy.defaultValue == null) continue;
      if (policy.value != policy.defaultValue) {
        updates[policy.key] = policy.defaultValue;
      }
    }
    if (updates.isEmpty) return 'All policies already match their defaults.';

    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      await repository.updatePolicies(updates);
      ref.invalidate(policiesProvider);
      if (mounted) {
        setState(() {
          _draftToggles.clear();
          _draftNumbers.clear();
          for (final controller in _numberControllers.values) {
            controller.dispose();
          }
          _numberControllers.clear();
        });
      }
      return 'All policies reset to their defaults.';
    } catch (e) {
      return 'Reset failed — check your connection and try again.';
    }
  }

  Widget _quickActionButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.policyKey.copyWith(fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11)),
                ],
              ),
            ),
            if (loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent(List<PolicyEntity> policies, _CategoryMeta meta) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header — matches web's icon badge + label + description
          // block shown above every category's policy list
          // (`policies/page.tsx:344-360`).
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: meta.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(meta.icon, size: 18, color: meta.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.label, style: AppTextStyles.boardLabel.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(meta.description, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (policies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_outlined, size: 28, color: AppColors.textTertiary),
                    const SizedBox(height: 10),
                    Text('No policies loaded', style: AppTextStyles.sectionSubtitle),
                  ],
                ),
              ),
            )
          else
            ...policies.map<Widget>((policy) {
              final isDirty = (_draftToggles.containsKey(policy.key) && _draftToggles[policy.key] != policy.value) ||
                  (_draftNumbers.containsKey(policy.key) && _draftNumbers[policy.key] != policy.value);

              return _buildPolicyRow(
                key: policy.key,
                description: policy.description,
                isToggle: policy.isToggle,
                isOverridable: policy.isOverridable,
                value: policy.value,
                isDirty: isDirty,
              );
            }),
        ],
      ),
    );
  }

  /// Mobile equivalent of web's always-visible "Platform Settings" sidebar
  /// panel (`policies/page.tsx:397-419`) — read-only, fed by the same
  /// `getPolicySettings()` endpoint, sections shown in the same order
  /// (system/notification/integrations/storage/api), collapsible sidebar
  /// adapted to a bottom sheet for mobile.
  void _showPlatformSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(builder: (context, ref, _) {
              final settingsAsync = ref.watch(policySettingsProvider);
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Platform Settings', style: AppTextStyles.sectionTitle.copyWith(fontSize: 15)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.bgTertiary,
                                border: Border.all(color: AppColors.borderPrimary),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('read-only', style: AppTextStyles.chipLabel().copyWith(fontSize: 9)),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (settingsAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (settingsAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Failed to load platform settings.\n${settingsAsync.error}',
                          style: AppTextStyles.sectionSubtitle,
                        ),
                      )
                    else
                      ...settingsAsync.value!.entries.map((section) => _buildSettingSection(section.key, section.value as Map<String, dynamic>)),
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }

  Widget _buildSettingSection(String title, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            title.toUpperCase(),
            style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.6, fontSize: 11),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: data.entries.map((entry) {
            final value = entry.value;
            final valueColor = value == true
                ? AppColors.successGreen
                : value == false
                    ? AppColors.dangerRed
                    : AppColors.textPrimary;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(entry.key, style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 12)),
                  ),
                  Text('$value', style: AppTextStyles.boardLabel.copyWith(fontSize: 12, color: valueColor)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
