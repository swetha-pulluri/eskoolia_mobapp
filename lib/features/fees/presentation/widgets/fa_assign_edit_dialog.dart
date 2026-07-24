import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/fee_assignment.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fee_schedule.dart';
import '../../domain/repositories/fees_config_repository.dart' show FeesConfigValidationException;
import '../providers/fees_assignment_providers.dart';
import 'fee_assignment_styles.dart';
import 'fee_schedule_table.dart';

typedef FaAssignResult = ({String group, String concession, double netAnnual});

/// "Assign Fees" / "Edit Assignment" modal — converted from
/// FeesAssignmentPanel.tsx's Modal 1 + `confirmAssign`. One assignment
/// (student, fees_type) is created/updated per fee-type row in the
/// selected group's schedule — matching the source's per-schedule loop
/// exactly, including its client-side create-vs-update branch per fee type.
class FaAssignEditDialog extends ConsumerStatefulWidget {
  final String studentName;
  final String studentAdmNo;
  final String className;
  final bool isEdit;
  final String initialGroup;
  final String initialConcession;
  final List<FeesGroup> groups;
  final Map<String, List<FeeRow>> feeSchedules;
  final List<String> concessions;
  final List<FeeSchedule> schedules;
  final int studentId;
  final int academicYearId;
  final List<FeeAssignment> existingAssignments;

  const FaAssignEditDialog({
    super.key,
    required this.studentName,
    required this.studentAdmNo,
    required this.className,
    required this.isEdit,
    required this.initialGroup,
    required this.initialConcession,
    required this.groups,
    required this.feeSchedules,
    required this.concessions,
    required this.schedules,
    required this.studentId,
    required this.academicYearId,
    required this.existingAssignments,
  });

  static Future<FaAssignResult?> show(
    BuildContext context, {
    required String studentName,
    required String studentAdmNo,
    required String className,
    required bool isEdit,
    required String initialGroup,
    required String initialConcession,
    required List<FeesGroup> groups,
    required Map<String, List<FeeRow>> feeSchedules,
    required List<String> concessions,
    required List<FeeSchedule> schedules,
    required int studentId,
    required int academicYearId,
    required List<FeeAssignment> existingAssignments,
  }) {
    return showDialog<FaAssignResult>(
      context: context,
      builder: (_) => FaAssignEditDialog(
        studentName: studentName,
        studentAdmNo: studentAdmNo,
        className: className,
        isEdit: isEdit,
        initialGroup: initialGroup,
        initialConcession: initialConcession,
        groups: groups,
        feeSchedules: feeSchedules,
        concessions: concessions,
        schedules: schedules,
        studentId: studentId,
        academicYearId: academicYearId,
        existingAssignments: existingAssignments,
      ),
    );
  }

  @override
  ConsumerState<FaAssignEditDialog> createState() => _FaAssignEditDialogState();
}

class _FaAssignEditDialogState extends ConsumerState<FaAssignEditDialog> {
  late String _group = widget.initialGroup;
  late String _concession = widget.initialConcession;
  bool _saving = false;
  String? _error;

  Future<void> _confirm() async {
    final rows = widget.feeSchedules[_group] ?? const <FeeRow>[];
    final grp = widget.groups.where((g) => g.name == _group).firstOrNull;
    final matchingSchedules = grp == null ? const <FeeSchedule>[] : widget.schedules.where((s) => s.feeGroup?.toString() == grp.id.toString()).toList();

    if (matchingSchedules.isEmpty) {
      setState(() => _error = 'No fee schedules found for "$_group". Please create fee schedules for this group first (Fee Schedules section).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(feesAssignmentRepositoryProvider);
    final errors = <String>[];
    final processedFeeTypes = <int>{};

    for (final schedule in matchingSchedules) {
      final feeTypeId = schedule.feeType;
      if (processedFeeTypes.contains(feeTypeId)) continue;
      processedFeeTypes.add(feeTypeId);

      final existingAsgn = widget.existingAssignments
          .where((a) => a.student == widget.studentId && a.feesType == feeTypeId)
          .firstOrNull;

      final rawAmount = double.tryParse(schedule.amount) ?? 0;
      final concPct = parseConcessionPct(_concession);
      final concAmt = (rawAmount * concPct).toStringAsFixed(2);

      try {
        if (existingAsgn != null) {
          await repo.updateAssignment(
            existingAsgn.id,
            academicYear: widget.academicYearId,
            student: widget.studentId,
            feesType: feeTypeId,
            amount: schedule.amount,
            discountAmount: '0.00',
            concessionAmount: concAmt,
            dueDate: schedule.dueDate.isEmpty ? null : schedule.dueDate,
          );
        } else {
          await repo.createAssignment(
            academicYear: widget.academicYearId,
            student: widget.studentId,
            feesType: feeTypeId,
            amount: schedule.amount,
            discountAmount: '0.00',
            concessionAmount: concAmt,
            dueDate: schedule.dueDate.isEmpty ? null : schedule.dueDate,
          );
        }
      } on FeesConfigValidationException catch (e) {
        errors.add('${schedule.feeTypeName ?? feeTypeId}: ${e.message}');
      } catch (e) {
        errors.add('${schedule.feeTypeName ?? feeTypeId}: $e');
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (errors.isNotEmpty) {
      setState(() => _error = 'Partial save — ${errors.length} fee type(s) failed: ${errors.first}');
      return;
    }

    final concPctSave = parseConcessionPct(_concession);
    final netTotal = rows.fold<double>(0, (s, r) => s + r.annual * (1 - concPctSave));
    Navigator.of(context).pop((group: _group, concession: _concession, netAnnual: netTotal));
  }

  @override
  Widget build(BuildContext context) {
    return FaModalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaModalHeader(
            title: widget.isEdit ? 'Edit Assignment' : 'Assign Fees',
            subtitle: '${widget.studentName} · ${widget.studentAdmNo} · ${widget.className}',
            onClose: () => Navigator.of(context).pop(),
          ),
          FeeScheduleTable(
            group: _group,
            concession: _concession,
            onGroupChange: (g) => setState(() => _group = g),
            onConcessionChange: (c) => setState(() => _concession = c),
            feeSchedules: widget.feeSchedules,
            concessions: widget.concessions,
            groups: widget.groups,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B))),
              ),
            ),
          FaModalFooter(children: [
            FaOutlineButton(label: 'Cancel', onPressed: _saving ? null : () => Navigator.of(context).pop()),
            FaPrimaryButton(label: _saving ? 'Saving…' : (widget.isEdit ? 'Save Changes' : 'Assign Fees'), onPressed: _saving ? null : _confirm),
          ]),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
