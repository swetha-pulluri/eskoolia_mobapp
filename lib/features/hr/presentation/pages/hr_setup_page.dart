import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/designation_entity.dart';
import '../../domain/entities/staff_lite_entity.dart';
import '../providers/hr_provider.dart';
import '../widgets/hr_department_card.dart';
import '../widgets/hr_department_form.dart';
import '../widgets/hr_designation_dept_card.dart';
import '../widgets/hr_designation_form.dart';
import '../widgets/hr_layout.dart';
import '../widgets/hr_theme.dart';

const _wizardSteps = [
  HrStep('Departments', 'Add independently'),
  HrStep('Designations', 'Add independently'),
  HrStep('Review', 'Confirm HR structure'),
];

/// A literal port of the real, deployed `HrSetupPage` (`hr/setup/page.tsx`
/// on the `demo`/`mobile`/`BugFix` branches — the branch actually running
/// at app.eskoolia.com; `main` is stale for HR). 3-step wizard: Departments
/// -> Designations -> Review, exact copy/behavior/validation/colors.
class HrSetupPage extends ConsumerStatefulWidget {
  const HrSetupPage({super.key});

  @override
  ConsumerState<HrSetupPage> createState() => _HrSetupPageState();
}

class _HrSetupPageState extends ConsumerState<HrSetupPage> {
  int _step = 1;
  bool _showAddDeptForm = false;
  DepartmentEntity? _editDept;
  DesignationEntity? _editDesig;
  int? _desigDefaultDept;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _desigCountForDept(List<DesignationEntity> allDesigs, int deptId) {
    return allDesigs.where((d) => d.departmentId == deptId).length;
  }

  /// Real, client-computed per-department active-staff headcount — the
  /// backend's `DepartmentSerializer` has no `staff_count` field, so this
  /// mirrors the same approach already used for `designationCount`: group
  /// the real `/staff/` list (active only, matching the "Staff Assigned"
  /// KPI's own filter) by `department`.
  int _staffCountForDept(List<StaffLiteEntity> activeStaff, int deptId) {
    return activeStaff.where((s) => s.departmentId != null && s.departmentId == deptId).length;
  }

  Future<void> _deleteDepartment(int id) async {
    try {
      await ref.read(hrRepositoryProvider).deleteDepartment(id);
      if (!mounted) return;
      showHrToast(context, 'Department deleted');
      invalidateHrSetupData(ref);
    } catch (e) {
      if (!mounted) return;
      showHrToast(context, 'Failed to delete', type: 'error');
    }
  }

  Future<void> _deleteDesignation(int id) async {
    try {
      await ref.read(hrRepositoryProvider).deleteDesignation(id);
      if (!mounted) return;
      showHrToast(context, 'Designation deleted');
      invalidateHrSetupData(ref);
    } catch (e) {
      if (!mounted) return;
      showHrToast(context, 'Failed to delete', type: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);
    final allDeptsAsync = ref.watch(allDepartmentsProvider);
    final hierDeptsAsync = ref.watch(hierarchyDepartmentsProvider);
    final desigsAsync = ref.watch(designationsProvider);
    final staffAsync = ref.watch(activeStaffProvider);
    final allDepartments = allDeptsAsync.valueOrNull?.results ?? const <DepartmentEntity>[];
    final allDesignations = desigsAsync.valueOrNull?.results ?? const <DesignationEntity>[];
    final activeStaff = staffAsync.valueOrNull?.results ?? const <StaffLiteEntity>[];

    return HrLayout(
      currentPath: '/hr/setup',
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildKpiRow(deptsAsync.valueOrNull?.count, desigsAsync.valueOrNull?.count, staffAsync.valueOrNull?.count),
            const SizedBox(height: 16),
            HrStepWizard(steps: _wizardSteps, currentStep: _step, onStepTap: (s) => setState(() => _step = s)),
            const SizedBox(height: 20),
            if (_step == 1) _buildStep1Departments(deptsAsync, allDesignations, activeStaff),
            if (_step == 2) _buildStep2Designations(hierDeptsAsync, desigsAsync, allDepartments),
            if (_step == 3) _buildStep3Review(deptsAsync.valueOrNull?.count ?? 0, desigsAsync.valueOrNull?.count ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Was a Row(Expanded(title), Wrap(buttons)) — a Row gives its
    // non-flexible children (the button Wrap) an UNBOUNDED main-axis
    // constraint, so that inner Wrap never actually wraps; once "Import" +
    // "Add Department" together are wider than the row (320-412dp, once
    // page padding is subtracted), it hard-overflows regardless of the
    // Expanded title shrinking to 0. Making the whole header itself a
    // top-level Wrap (bounded by the page's Column, same as the pager/
    // step-wizard fixes elsewhere in this file) lets the button group drop
    // to its own line instead of overflowing.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('HR CONFIGURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
            const SizedBox(height: 2),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: HrColors.ink),
                children: [TextSpan(text: 'Staff '), TextSpan(text: 'setup', style: TextStyle(color: HrColors.brand, fontWeight: FontWeight.w400))],
              ),
            ),
            const SizedBox(height: 4),
            const Text('Define your organisation structure — departments and designations.', style: TextStyle(fontSize: 13, color: HrColors.muted)),
          ],
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () => showHrToast(context, 'Import from CSV — available in full build', type: 'info'),
            icon: const Icon(Icons.upload_outlined, size: 15),
            label: const Text('Import'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF475569), side: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _showAddDeptForm = true;
                _editDept = null;
              });
            },
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Add Department'),
            style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
          ),
        ]),
      ],
    );
  }

  Widget _buildKpiRow(int? deptCount, int? desigCount, int? staffCount) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 24) / 2;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        SizedBox(width: cardWidth, child: HrKpiCard(label: 'Departments', value: deptCount?.toString() ?? '--')),
        SizedBox(width: cardWidth, child: HrKpiCard(label: 'Designations', value: desigCount?.toString() ?? '--')),
        SizedBox(width: cardWidth, child: HrKpiCard(label: 'Staff Assigned', value: staffCount?.toString() ?? '--')),
        SizedBox(width: cardWidth, child: const HrKpiCard(label: 'Missing Role', value: '--', color: HrColors.red)),
      ]);
    });
  }

  Widget _buildStep1Departments(AsyncValue<dynamic> deptsAsync, List<DesignationEntity> allDesignations, List<StaffLiteEntity> activeStaff) {
    final state = deptsAsync;
    final departments = (state.valueOrNull?.results as List<DepartmentEntity>?) ?? const <DepartmentEntity>[];
    final count = state.valueOrNull?.count as int? ?? 0;
    final page = ref.watch(deptPageProvider);
    final totalPages = (count / 10).ceil().clamp(1, 1 << 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showAddDeptForm && _editDept == null)
          HrDepartmentForm(
            onSaved: (addAnother) {
              invalidateHrSetupData(ref);
              if (!addAnother) {
                setState(() {
                  _showAddDeptForm = false;
                  _step = 2;
                });
              }
            },
            onCancel: () => setState(() => _showAddDeptForm = false),
          ),
        if (_editDept != null)
          HrDepartmentForm(
            key: ValueKey('edit-dept-${_editDept!.id}'),
            initial: _editDept,
            stepLabel: 'EDIT DEPARTMENT',
            onSaved: (_) {
              invalidateHrSetupData(ref);
              setState(() => _editDept = null);
            },
            onCancel: () => setState(() => _editDept = null),
          ),
        if (state.isLoading)
          const HrSkeleton()
        else if (departments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E8F0)), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('No departments yet. Click "+ Add Department" to get started.', style: TextStyle(color: HrColors.muted))),
          )
        else
          Column(
            children: [
              for (final dept in departments) ...[
                HrDepartmentCard(
                  dept: dept,
                  designationCount: _desigCountForDept(allDesignations, dept.id),
                  staffCount: _staffCountForDept(activeStaff, dept.id),
                  onEdit: () => setState(() {
                    _editDept = dept;
                    _showAddDeptForm = false;
                  }),
                  onDelete: () => showHrConfirmDialog(
                    context,
                    title: 'Delete Department',
                    message: 'Staff assigned to it will be unlinked.',
                    confirmLabel: 'Yes, Delete',
                    danger: true,
                    onConfirm: () => _deleteDepartment(dept.id),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        if (count > 10) ...[
          const SizedBox(height: 8),
          // Was a plain Row(spaceBetween) — the "Showing X–Y of Z" label has
          // no Expanded/Flexible and the nav-button Row has no wrap, so on a
          // 320dp screen the two sides' combined width can exceed the
          // available space and throw a RenderFlex overflow. Wrap lets the
          // nav controls drop to their own line instead of overflowing.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('Showing ${(page - 1) * 10 + 1}–${(page * 10).clamp(0, count)} of $count', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                OutlinedButton(onPressed: page > 1 ? () => ref.read(deptPageProvider.notifier).state = page - 1 : null, child: const Text('← Prev')),
                Text('Page $page of $totalPages', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                OutlinedButton(onPressed: page < totalPages ? () => ref.read(deptPageProvider.notifier).state = page + 1 : null, child: const Text('Next →')),
              ]),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
            onPressed: () => setState(() => _step = 2),
            child: const Text('Go to Designations'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Designations(AsyncValue<dynamic> hierDeptsAsync, AsyncValue<dynamic> desigsAsync, List<DepartmentEntity> allDepartments) {
    final hierDepts = (hierDeptsAsync.valueOrNull?.results as List<DepartmentEntity>?) ?? const <DepartmentEntity>[];
    final hierCount = hierDeptsAsync.valueOrNull?.count as int? ?? 0;
    final allDesignations = (desigsAsync.valueOrNull?.results as List<DesignationEntity>?) ?? const <DesignationEntity>[];
    final desigPage = ref.watch(desigDeptPageProvider);
    final totalPages = (hierCount / 5).ceil().clamp(1, 1 << 30);
    final loading = hierDeptsAsync.isLoading || desigsAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HrDesignationForm(
          key: ValueKey(_editDesig != null ? 'edit-${_editDesig!.id}' : 'add-${_desigDefaultDept ?? 0}'),
          initial: _editDesig,
          defaultDeptId: _desigDefaultDept,
          departments: allDepartments,
          onSaved: (addAnother) {
            invalidateHrSetupData(ref);
            ref.read(desigDeptPageProvider.notifier).state = 1;
            if (!addAnother) {
              final wasEdit = _editDesig != null;
              setState(() {
                _editDesig = null;
                _desigDefaultDept = null;
              });
              if (!wasEdit) {
                setState(() => _step = 3);
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
              }
            }
          },
          onCancel: _editDesig != null ? () => setState(() { _editDesig = null; _desigDefaultDept = null; }) : null,
        ),
        if (loading || hierCount > 0) ...[
          const Text('DESIGNATIONS ADDED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
        ],
        if (loading)
          const HrSkeleton()
        else ...[
          Column(
            children: [
              for (final dept in hierDepts) ...[
                HrDesignationDeptCard(
                  dept: dept,
                  deptDesigs: allDesignations.where((d) => d.departmentId == dept.id).toList(),
                  onAddChild: () => setState(() {
                    _editDesig = null;
                    _desigDefaultDept = dept.id;
                  }),
                  onEdit: (d) => setState(() {
                    _editDesig = d;
                    _desigDefaultDept = null;
                  }),
                  onDelete: (id) => showHrConfirmDialog(
                    context,
                    title: 'Delete Designation',
                    message: 'Staff with this designation will be unlinked.',
                    confirmLabel: 'Yes, Delete',
                    danger: true,
                    onConfirm: () => _deleteDesignation(id),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
          if (hierCount > 5) ...[
            const SizedBox(height: 8),
            // Same fix as the Step 1 pager above: Row(spaceBetween) with an
            // unwrapped Text + nav-button Row overflows at 320dp once the
            // "…of N departments" label grows; Wrap lets it fall to a new
            // line instead of forcing a RenderFlex overflow.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text('Showing ${(desigPage - 1) * 5 + 1}–${(desigPage * 5).clamp(0, hierCount)} of $hierCount departments', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                  OutlinedButton(onPressed: desigPage > 1 ? () => ref.read(desigDeptPageProvider.notifier).state = desigPage - 1 : null, child: const Text('← Prev')),
                  Text('Page $desigPage of $totalPages', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                  OutlinedButton(onPressed: desigPage < totalPages ? () => ref.read(desigDeptPageProvider.notifier).state = desigPage + 1 : null, child: const Text('Next →')),
                ]),
              ],
            ),
          ],
        ],
        const SizedBox(height: 20),
        // `Wrap` (not a bare `Row(spaceBetween)`) — "← Departments" and
        // "Finish Setup →" together can exceed a 320-360dp screen with no
        // Expanded/Flexible sibling to absorb it; letting them drop to a
        // second line avoids the overflow instead of just relying on
        // spaceBetween, which doesn't stop a Row from overflowing.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            TextButton(onPressed: () => setState(() => _step = 1), child: const Text('← Departments', style: TextStyle(color: Color(0xFF475569)))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
              onPressed: () => setState(() => _step = 3),
              child: const Text('Finish Setup →'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Review(int deptCount, int desigCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E8F0)), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          const Text('✅', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: HrColors.ink),
              children: [TextSpan(text: 'HR Structure '), TextSpan(text: 'Configured', style: TextStyle(color: HrColors.brand))],
            ),
          ),
          const SizedBox(height: 12),
          Text('$deptCount departments and $desigCount designations set up.', style: const TextStyle(color: HrColors.muted)),
          const SizedBox(height: 24),
          Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
            OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Edit Setup')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
              // Matches web's `onClick={() => { window.location.href =
              // "/hr/onboard"; }}` (`hr/setup/page.tsx:927`) — the real
              // 10-step onboarding wizard, already fully built and routed
              // in this app (`staff_directory_page.dart`'s own "Add Staff"
              // button uses the same route).
              onPressed: () => context.push('/hr/onboard'),
              child: const Text('Start Onboarding'),
            ),
          ]),
        ],
      ),
    );
  }
}
