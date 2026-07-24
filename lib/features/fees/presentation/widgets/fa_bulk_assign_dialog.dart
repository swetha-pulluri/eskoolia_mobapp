import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/fee_assignment.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fee_schedule.dart';
import '../pages/fee_assignment_page.dart' show FaClassRoster, FaRosterStudent;
import '../providers/fees_assignment_providers.dart';
import 'fee_assignment_styles.dart';
import 'fee_schedule_table.dart';

typedef FaBulkAssignResult = ({String group, List<String> assignedStudentIds, int successCount, List<String> errors, double annualTotal});

/// "Bulk Assign Fees" modal — converted from FeesAssignmentPanel.tsx's
/// Modal 3/4 + `confirmBulkAssign`. Since there is no bulk-assign endpoint
/// on the backend (confirmed against `apps/fees/urls.py`), this loops
/// individual create calls per unassigned student × fee type, exactly like
/// the source.
class FaBulkAssignDialog extends ConsumerStatefulWidget {
  final String initialClassId;
  final List<FaClassRoster> classData;
  final List<FeesGroup> groups;
  final Set<String> selectedStudentIds;
  final Map<String, List<FeeRow>> feeSchedules;
  final List<FeeSchedule> schedules;
  final List<FeeAssignment> assignments;
  final int academicYearId;
  final bool Function(FaRosterStudent) isAssignedFn;

  const FaBulkAssignDialog({
    super.key,
    required this.initialClassId,
    required this.classData,
    required this.groups,
    required this.selectedStudentIds,
    required this.feeSchedules,
    required this.schedules,
    required this.assignments,
    required this.academicYearId,
    required this.isAssignedFn,
  });

  static Future<FaBulkAssignResult?> show(
    BuildContext context, {
    required String initialClassId,
    required List<FaClassRoster> classData,
    required List<FeesGroup> groups,
    required Set<String> selectedStudentIds,
    required Map<String, List<FeeRow>> feeSchedules,
    required List<FeeSchedule> schedules,
    required List<FeeAssignment> assignments,
    required int academicYearId,
    required bool Function(FaRosterStudent) isAssignedFn,
  }) {
    return showDialog<FaBulkAssignResult>(
      context: context,
      builder: (_) => FaBulkAssignDialog(
        initialClassId: initialClassId,
        classData: classData,
        groups: groups,
        selectedStudentIds: selectedStudentIds,
        feeSchedules: feeSchedules,
        schedules: schedules,
        assignments: assignments,
        academicYearId: academicYearId,
        isAssignedFn: isAssignedFn,
      ),
    );
  }

  @override
  ConsumerState<FaBulkAssignDialog> createState() => _FaBulkAssignDialogState();
}

class _FaBulkAssignDialogState extends ConsumerState<FaBulkAssignDialog> {
  late String _bulkClass = widget.initialClassId;
  late String _bulkGroup = widget.groups.isNotEmpty ? widget.groups.first.name : '';
  bool _saving = false;
  String? _error;

  String get _className => _bulkClass == 'all' ? 'All Classes' : (widget.classData.where((c) => c.id == _bulkClass).firstOrNull?.name ?? _bulkClass);

  Future<void> _confirm() async {
    final targetIds = _bulkClass == 'all' ? widget.classData.map((c) => c.id).toList() : [_bulkClass];
    final rows = widget.feeSchedules[_bulkGroup] ?? const <FeeRow>[];
    final total = rows.fold<double>(0, (s, r) => s + r.annual);

    final grp = widget.groups.where((g) => g.name == _bulkGroup).firstOrNull;
    final matchingSchedules = grp == null ? const <FeeSchedule>[] : widget.schedules.where((s) => s.feeGroup?.toString() == grp.id.toString()).toList();

    if (matchingSchedules.isEmpty) {
      setState(() => _error = 'No fee schedules found for "$_bulkGroup". Please create fee schedules for this group first.');
      return;
    }

    final hasSelection = widget.selectedStudentIds.isNotEmpty;
    final unassignedStudents = <FaRosterStudent>[];
    for (final cls in widget.classData) {
      if (!targetIds.contains(cls.id)) continue;
      for (final st in cls.students) {
        if (hasSelection && !widget.selectedStudentIds.contains(st.id)) continue;
        if (!widget.isAssignedFn(st)) unassignedStudents.add(st);
      }
    }

    if (unassignedStudents.isEmpty) {
      setState(() => _error = hasSelection ? 'All selected students are already assigned.' : 'All students in ${_bulkClass == 'all' ? 'all classes' : 'this class'} are already assigned.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(feesAssignmentRepositoryProvider);
    var successCount = 0;
    final errors = <String>[];

    for (final st in unassignedStudents) {
      final processedFeeTypes = <int>{};
      for (final schedule in matchingSchedules) {
        final feeTypeId = schedule.feeType;
        if (processedFeeTypes.contains(feeTypeId)) continue;
        processedFeeTypes.add(feeTypeId);

        final existingAsgn = widget.assignments.where((a) => a.student.toString() == st.id && a.feesType == feeTypeId).firstOrNull;
        if (existingAsgn != null) continue;

        try {
          await repo.createAssignment(
            academicYear: widget.academicYearId,
            student: int.parse(st.id),
            feesType: feeTypeId,
            amount: schedule.amount,
            discountAmount: '0.00',
            concessionAmount: '0.00',
            dueDate: schedule.dueDate.isEmpty ? null : schedule.dueDate,
          );
          successCount++;
        } catch (e) {
          errors.add('${st.name}: $e');
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop((
      group: _bulkGroup,
      assignedStudentIds: unassignedStudents.map((s) => s.id).toList(),
      successCount: successCount,
      errors: errors,
      annualTotal: total,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedStudentIds.isNotEmpty;
    return FaModalShell(
      maxWidth: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaModalHeader(
            title: 'Bulk Assign Fees',
            subtitle: hasSelection
                ? 'Assign to ${widget.selectedStudentIds.length} selected student${widget.selectedStudentIds.length > 1 ? 's' : ''} (unassigned only).'
                : 'Assign a fee group to all unassigned students in $_className.',
            onClose: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasSelection)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), border: Border.all(color: const Color(0xFFC7D2FE)), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.selectedStudentIds.length} student${widget.selectedStudentIds.length > 1 ? 's' : ''} selected — only these will be assigned.',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => widget.selectedStudentIds.clear()),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Clear selection', style: TextStyle(fontSize: 11, color: faPurple, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _select('CLASS', _bulkClass, ['all', for (final c in widget.classData) c.id], (id) => id == 'all' ? 'All Classes' : widget.classData.firstWhere((c) => c.id == id).name.replaceFirst('Class ', ''), (v) => setState(() => _bulkClass = v))),
                    const SizedBox(width: 14),
                    Expanded(child: _select('FEE GROUP', _bulkGroup, [for (final g in widget.groups) g.name], (n) => n, (v) => setState(() => _bulkGroup = v))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  hasSelection
                      ? 'Applies to the selected students only. Already-assigned students in the selection are skipped.'
                      : 'Applies to unassigned rows only. A plan-history entry is created for each student assigned.',
                  style: const TextStyle(fontSize: 12, color: faInk2),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B))),
                  ),
                ],
              ],
            ),
          ),
          FaModalFooter(children: [
            FaOutlineButton(label: 'Cancel', onPressed: _saving ? null : () => Navigator.of(context).pop()),
            FaPrimaryButton(label: _saving ? 'Assigning…' : 'Assign to Unassigned', onPressed: _saving ? null : _confirm),
          ]),
        ],
      ),
    );
  }

  Widget _select(String label, String value, List<String> options, String Function(String) labelOf, ValueChanged<String> onChanged) {
    final safeOptions = options.contains(value) ? options : [value, ...options];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: faInk3)),
        const SizedBox(height: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: faBorder), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF8B8EA8)),
              style: const TextStyle(fontSize: 12.5, color: faInk1),
              items: [for (final o in safeOptions) DropdownMenuItem(value: o, child: Text(labelOf(o), overflow: TextOverflow.ellipsis))],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
