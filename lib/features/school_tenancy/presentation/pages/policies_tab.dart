import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/policy_entity.dart' show PolicyEntity;
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Policies & Settings page.
/// Converts the web `/super-admin/policies` page (eyebrow header, category
/// tabs, policy rows with locked/unsaved badges, read-only Platform Settings
/// panel, Quick Actions panel) into a single scrollable mobile column —
/// the desktop's side-by-side layout is stacked vertically.
class SuperAdminPoliciesPage extends ConsumerStatefulWidget {
  const SuperAdminPoliciesPage({super.key});

  @override
  ConsumerState<SuperAdminPoliciesPage> createState() => _SuperAdminPoliciesPageState();
}

class _CategoryCfg {
  final String label;
  final String desc;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _CategoryCfg(this.label, this.desc, this.icon, this.iconBg, this.iconColor);
}

class _SuperAdminPoliciesPageState extends ConsumerState<SuperAdminPoliciesPage> {
  String _activeTab = 'security';
  final Map<String, bool> _draftToggles = {};
  final Map<String, num> _draftNumbers = {};

  static const Map<String, _CategoryCfg> _catConfig = {
    'security': _CategoryCfg('Security', 'Authentication, session & access controls', Icons.shield_outlined,
        Color(0xFFFEF2F2), Color(0xFFEF4444)),
    'data_isolation': _CategoryCfg('Data Isolation', 'Tenancy boundaries & audit retention', Icons.storage_outlined,
        Color(0xFFF0F9FF), Color(0xFF0EA5E9)),
    'billing': _CategoryCfg('Billing', 'GST rates & invoice payment terms', Icons.bolt_outlined,
        Color(0xFFF5F3FF), Color(0xFF9333EA)),
    'system': _CategoryCfg('System', 'Infrastructure, backups & tenancy switches', Icons.settings_outlined,
        Color(0xFFECFDF5), Color(0xFF059669)),
  };

  List<PolicyEntity> _policiesFor(dynamic state, String cat) {
    switch (cat) {
      case 'security':
        return state.security as List<PolicyEntity>;
      case 'data_isolation':
        return state.dataIsolation as List<PolicyEntity>;
      case 'billing':
        return state.billing as List<PolicyEntity>;
      default:
        return state.system as List<PolicyEntity>;
    }
  }

  bool _isDirty(PolicyEntity p) {
    if (p.isToggle) {
      return _draftToggles.containsKey(p.key) && _draftToggles[p.key] != p.value;
    }
    return _draftNumbers.containsKey(p.key) && _draftNumbers[p.key] != p.value;
  }

  @override
  Widget build(BuildContext context) {
    final policiesState = ref.watch(policiesProvider);
    final settings = ref.watch(platformSettingsProvider);
    final activePolicies = _policiesFor(policiesState, _activeTab);
    final dirtyInActive = activePolicies.where(_isDirty).length;
    final cfg = _catConfig[_activeTab]!;

    return SchoolTenancyLayout(
      currentPath: '/super-admin/policies',
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER — eyebrow + plain bold title
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Super Admin',
                              style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 12, fontWeight: FontWeight.w300)),
                          Text(' · Config', style: AppTextStyles.kpiLabel.copyWith(fontSize: 11, letterSpacing: 1.5)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Policies & Settings',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Platform-wide configuration and feature controls', style: AppTextStyles.pageSubtitle),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.amberSoft,
                              border: Border.all(color: AppColors.amberBorder),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('Demo data',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                          ),
                          _smallButton(Icons.refresh, 'Refresh', () => setState(() {})),
                          _smallButton(Icons.download, 'JSON', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Export JSON — not yet wired to a live API.')),
                            );
                          }),
                          _smallButton(Icons.download, 'YAML', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Export YAML — not yet wired to a live API.')),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // CATEGORY CHIP TABS
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _catConfig.entries.map((entry) {
                      final key = entry.key;
                      final c = entry.value;
                      final active = _activeTab == key;
                      final hasDirty = _policiesFor(policiesState, key).any(_isDirty);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: active ? AppColors.purpleTint : AppColors.bgSecondary,
                              border: Border.all(color: active ? AppColors.purpleSoft : AppColors.borderPrimary),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: active ? AppColors.purpleSoft : c.iconBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(c.icon, size: 12, color: active ? AppColors.purpleDeep : c.iconColor),
                                ),
                                const SizedBox(width: 8),
                                Text(c.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: active ? AppColors.purpleDeep : AppColors.textSecondary,
                                    )),
                                if (hasDirty) ...[
                                  const SizedBox(width: 6),
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryPurple, shape: BoxShape.circle)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // ACTIVE CATEGORY PANEL
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    border: Border.all(color: AppColors.borderPrimary),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: cfg.iconBg, borderRadius: BorderRadius.circular(10)),
                            child: Icon(cfg.icon, size: 16, color: cfg.iconColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cfg.label, style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(cfg.desc, style: AppTextStyles.sectionSubtitle, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...activePolicies.map((p) => _buildPolicyRow(p)),
                      const SizedBox(height: 4),
                      const Divider(color: AppColors.borderPrimary, height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dirtyInActive > 0 ? '$dirtyInActive unsaved change${dirtyInActive == 1 ? '' : 's'}' : 'No pending changes',
                              style: AppTextStyles.sectionSubtitle,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: dirtyInActive > 0
                                ? () {
                                    setState(() {
                                      _draftToggles.clear();
                                      _draftNumbers.clear();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Policies saved (not yet wired to a live API).')),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primaryPurple.withValues(alpha: 0.4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Save changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // PLATFORM SETTINGS (read-only)
                Row(
                  children: [
                    const Icon(Icons.public, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text('Platform Settings', style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.bgTertiary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(999)),
                      child: const Text('read-only', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...settings.entries.map((e) => _SettingSection(title: e.key, data: e.value)),

                const SizedBox(height: 20),

                // QUICK ACTIONS
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text('Quick Actions', style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                _quickAction('Reset to defaults', 'Restore all policies to their default values'),
                _quickAction('Force MFA enrollment', 'Send MFA setup emails to all admins'),
                _quickAction('Flush all sessions', 'Immediately invalidate all active user sessions'),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.borderPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _quickAction(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title — not yet wired to a live API.')),
          );
        },
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          side: const BorderSide(color: AppColors.borderPrimary),
          backgroundColor: AppColors.bgPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.boardLabel.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyRow(PolicyEntity policy) {
    final dirty = _isDirty(policy);
    final value = policy.isToggle
        ? (_draftToggles[policy.key] ?? policy.value as bool)
        : (_draftNumbers[policy.key] ?? policy.value as num);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dirty ? AppColors.purpleTint : AppColors.bgSecondary,
        border: Border.all(color: dirty ? AppColors.purpleSoft : AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(policy.key, style: AppTextStyles.policyKey),
                    if (!policy.isOverridable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.bgTertiary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(999)),
                        child: const Text('locked', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                      ),
                    if (dirty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.purpleTint, border: Border.all(color: AppColors.purpleSoft), borderRadius: BorderRadius.circular(999)),
                        child: const Text('unsaved', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.purpleDeep)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(policy.description, style: AppTextStyles.policyDescription),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (policy.isToggle)
            Switch(
              value: value as bool,
              onChanged: policy.isOverridable == false && policy.key == 'mfa.required'
                  ? null
                  : (v) => setState(() => _draftToggles[policy.key] = v),
              activeTrackColor: AppColors.primaryPurple,
            )
          else
            SizedBox(
              width: 64,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: AppTextStyles.policyKey.copyWith(fontSize: 12),
                controller: TextEditingController(text: '$value')
                  ..selection = TextSelection.collapsed(offset: '$value'.length),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.bgTertiary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (v) {
                  final n = num.tryParse(v);
                  if (n != null) setState(() => _draftNumbers[policy.key] = n);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Collapsible read-only settings section (web `SettingSection`).
class _SettingSection extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;
  const _SettingSection({required this.title, required this.data});

  @override
  State<_SettingSection> createState() => _SettingSectionState();
}

class _SettingSectionState extends State<_SettingSection> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: AppTextStyles.kpiLabel.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Icon(_open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: widget.data.entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: AppColors.textTertiary)),
                              Text(
                                '${e.value}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: e.value == true
                                      ? const Color(0xFF059669)
                                      : e.value == false
                                          ? AppColors.dangerRed
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
