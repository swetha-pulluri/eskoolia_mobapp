import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/master_option_entity.dart';
import '../../providers/hr_provider.dart';
import 'onboard_field_widgets.dart';

const _probationUnits = ['days', 'months', 'years'];

/// Designation options come from `fixedDesignationNames`
/// (`onboard_field_widgets.dart`) — a fixed list, per direct request,
/// replacing the live `/api/v1/hr/designations/` list entirely for this
/// dropdown. Deduplicated to unique names (the source list repeated common
/// titles once per department); "swetha" (a person's name, not a title) was
/// dropped as an evident data-entry mistake. Selecting one stores a negative
/// sentinel id (`-(i+1)`) — it doesn't correspond to any real
/// `/api/v1/hr/designations/` row, so `_submit()` in `staff_onboard_page.dart`
/// treats a negative id as "no designation" rather than sending it to the
/// backend (the `designation` FK is nullable, so this is a real, valid
/// state, not an error). The list is shared (not kept private to this file)
/// so Step 10's review and the PDF preview can resolve it back to a name via
/// `fixedDesignationNameFor`.

/// Verbatim copy of the real backend's `apps/master/constants.py`'s
/// `EMPLOYMENT_TYPES` — same rationale as the Step 1 master-data fallbacks
/// (`_fallbackLanguages` etc. in `step_identity.dart`): the live
/// `/api/v1/master/employment-types/` endpoint isn't deployed on `main` yet.
/// Safe to fall back to locally (unlike Role/Department/Designation below)
/// because `employment_type` has no dedicated backend column — it's a plain
/// label stored in the schema-less `custom_field`, not a foreign-key id.
const _fallbackEmploymentTypes = ['Full Time', 'Part Time', 'Contract', 'Temporary', 'Internship', 'Consultant', 'Outsourced', 'Probation', 'Permanent', 'Other'];

/// Step 2 — Role & placement. Real fields: `department` (real
/// `/api/v1/hr/departments/`, matching web's `useAllDepartments()` — NOT
/// `staff/form-options/`'s smaller active-only list), `designation` (a
/// fixed list — see [_fixedDesignations] — NOT the live
/// `/api/v1/hr/designations/`, per explicit request), `role` (real `staff/form-options/`'s `roles`
/// field, matching web's `useStaffFormOptions()` — NOT
/// `/api/v1/access-control/roles/`, which the web never calls for this
/// screen), `joining_date`, `employment_type` (+ free-text `_other`, bound
/// to the real `/api/v1/master/employment-types/`), `probation_value`/
/// `_unit`, `reporting_manager` (from the real active-staff list).
class StepRole extends ConsumerWidget {
  final Map<String, dynamic> form;
  final void Function(String key, dynamic value) onChange;

  const StepRole({super.key, required this.form, required this.onChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDepartmentsAsync = ref.watch(allDepartmentsProvider);
    final formOptionsAsync = ref.watch(staffFormOptionsProvider);
    final empTypesAsync = ref.watch(masterEmploymentTypesProvider);
    final staffAsync = ref.watch(activeStaffProvider);

    final departments = allDepartmentsAsync.valueOrNull?.results ?? const [];
    final selectedDeptId = int.tryParse(form['department']?.toString() ?? '');
    final roles = formOptionsAsync.valueOrNull?.roles ?? const [];
    final liveEmpTypes = empTypesAsync.valueOrNull ?? const [];
    final empTypes = liveEmpTypes.isNotEmpty ? liveEmpTypes : [for (var i = 0; i < _fallbackEmploymentTypes.length; i++) MasterOptionEntity(id: i + 1, name: _fallbackEmploymentTypes[i])];
    final staffList = staffAsync.valueOrNull?.results ?? const [];
    final empType = form['employment_type'] as String?;
    final empTypeNames = empTypes.map((e) => e.name).where((n) => n != 'Other').toList();
    final empTypeHasOther = empTypes.any((e) => e.name == 'Other');
    final isCustomEmpType = empType == 'Other';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Role & placement', 'Department, role, joining'),
          onboardFieldGrid([
            onboardDropdown<int>(
              label: 'Department',
              required: true,
              value: selectedDeptId,
              items: [for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) {
                onChange('department', v?.toString() ?? '');
                onChange('designation', '');
              },
            ),
            onboardDropdown<int>(
              label: 'Designation',
              required: true,
              value: int.tryParse(form['designation']?.toString() ?? ''),
              items: [for (var i = 0; i < fixedDesignationNames.length; i++) DropdownMenuItem(value: -(i + 1), child: Text(fixedDesignationNames[i], overflow: TextOverflow.ellipsis))],
              onChanged: (v) => onChange('designation', v?.toString() ?? ''),
            ),
            onboardDropdown<int>(
              label: 'Role / Access',
              required: true,
              value: int.tryParse(form['role']?.toString() ?? ''),
              items: [for (final r in roles) DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => onChange('role', v?.toString() ?? ''),
            ),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardDateField(context, label: 'Joining Date', required: true, value: form['joining_date'] as String?, onPicked: (v) => onChange('joining_date', v)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                onboardDropdown<String>(
                  label: 'Employment Type',
                  required: true,
                  value: empType,
                  items: [
                    for (final n in empTypeNames) DropdownMenuItem(value: n, child: Text(n)),
                    if (empTypeHasOther) const DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    onChange('employment_type', v);
                    if (v != 'Other') onChange('employment_type_other', '');
                  },
                ),
                if (isCustomEmpType)
                  Padding(padding: const EdgeInsets.only(top: 8), child: onboardText(label: 'Employment Type (other)', value: form['employment_type_other'] as String? ?? '', onChanged: (v) => onChange('employment_type_other', v))),
              ],
            ),
            onboardDropdown<int>(
              label: 'Reporting Manager',
              value: int.tryParse(form['reporting_manager']?.toString() ?? ''),
              items: [for (final s in staffList) DropdownMenuItem(value: s.id, child: Text(s.displayName, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => onChange('reporting_manager', v?.toString() ?? ''),
              placeholder: 'Select staff (optional)',
            ),
          ]),
          const SizedBox(height: 14),
          onboardFieldGrid([
            onboardText(label: 'Probation Period', value: form['probation_value'] as String? ?? '', keyboardType: TextInputType.number, onChanged: (v) => onChange('probation_value', v)),
            onboardDropdown<String>(
              label: 'Probation Unit',
              value: form['probation_unit'] as String? ?? 'months',
              items: [for (final u in _probationUnits) DropdownMenuItem(value: u, child: Text(u))],
              onChanged: (v) => onChange('probation_unit', v ?? 'months'),
            ),
          ]),
        ],
      ),
    );
  }

}
