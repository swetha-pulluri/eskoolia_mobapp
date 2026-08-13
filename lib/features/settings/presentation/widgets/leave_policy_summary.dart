import '../../../hr/domain/entities/department_entity.dart';
import '../../../hr/domain/entities/designation_entity.dart';
import '../../domain/leave_policy_choices.dart';

/// Mirrors `eligibilitySummary()` — a one-line summary of who a leave type
/// applies to, resolving department/designation IDs (stored as strings) to
/// names. Shared by the list card's stat tile and the wizard's Review step,
/// since both need it against slightly different data shapes (a loaded
/// [LeavePolicyEntity] vs. the wizard's in-progress `draft` map) — callers
/// pass the raw values rather than the entity/map itself.
String leaveEligibilitySummary({
  required String gender,
  required List<String> departmentIds,
  required List<String> designationIds,
  required List<String> employmentTypes,
  required int minimumServicePeriod,
  required List<DepartmentEntity> departments,
  required List<DesignationEntity> designations,
}) {
  final parts = <String>[];

  if (gender != 'all') {
    parts.add(gender == 'male' ? 'Male only' : 'Female only');
  }

  final deptNames = departmentIds
      .map((id) => departments.where((d) => d.id.toString() == id).map((d) => d.name).firstOrNull)
      .whereType<String>()
      .toList();
  if (deptNames.isNotEmpty) parts.add(deptNames.join(', '));

  final desigNames = designationIds
      .map((id) => designations.where((d) => d.id.toString() == id).map((d) => d.name).firstOrNull)
      .whereType<String>()
      .toList();
  if (desigNames.isNotEmpty) parts.add(desigNames.join(', '));

  final empLabels = employmentTypes
      .map((value) => employmentTypeOptions.where((t) => t.value == value).map((t) => t.label).firstOrNull)
      .whereType<String>()
      .toList();
  if (empLabels.isNotEmpty) parts.add(empLabels.join(', '));

  if (minimumServicePeriod > 0) parts.add('${minimumServicePeriod}mo+ service');

  return parts.isEmpty ? 'All staff' : parts.join(' · ');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
