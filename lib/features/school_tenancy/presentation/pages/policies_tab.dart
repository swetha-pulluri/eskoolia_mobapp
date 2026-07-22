import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

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
  final Map<String, int> _draftNumbers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCategoryTab(IconData icon, String label, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
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
                    controller: TextEditingController(
                      text: (_draftNumbers[key] ?? value).toString(),
                    ),
                    onChanged: (val) {
                      final num = int.tryParse(val);
                      if (num != null) setState(() => _draftNumbers[key] = num);
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
    final policiesState = ref.watch(policiesProvider);

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
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: AppTextStyles.buttonSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {},
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
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {},
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
                  _buildCategoryTab(Icons.storage_outlined, 'Data', const Color(0xFF0369A1)),
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
                  // Security
                  _buildCategoryContent(policiesState.security),
                  // Data Isolation
                  _buildCategoryContent(policiesState.dataIsolation),
                  // Billing
                  _buildCategoryContent(policiesState.billing),
                  // System
                  _buildCategoryContent(policiesState.system),
                ],
              ),
            ),

            // SAVE/RESET BUTTONS
            if (_draftToggles.isNotEmpty || _draftNumbers.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border(top: BorderSide(color: AppColors.borderPrimary)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _draftToggles.clear();
                            _draftNumbers.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _draftToggles.clear();
                            _draftNumbers.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),      ),    );
  }

  Widget _buildCategoryContent(List policies) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: policies.map<Widget>((policy) {
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
        }).toList(),
      ),
    );
  }
}
