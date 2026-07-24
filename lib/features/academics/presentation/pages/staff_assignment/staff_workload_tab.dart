// Workload tab — port of WorkloadTab from
// components/academics/StaffAssignmentPanels.tsx.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/staff_assignment_entities.dart';
import '../../providers/academics_providers.dart';

class StaffWorkloadTab extends ConsumerStatefulWidget {
  final int? academicYearId;
  const StaffWorkloadTab({super.key, required this.academicYearId});

  @override
  ConsumerState<StaffWorkloadTab> createState() => _StaffWorkloadTabState();
}

class _StaffWorkloadTabState extends ConsumerState<StaffWorkloadTab> {
  List<StaffWorkloadEntry> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StaffWorkloadTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.academicYearId != widget.academicYearId) _load();
  }

  Future<void> _load() async {
    if (widget.academicYearId == null) return;
    setState(() => _loading = true);
    try {
      final data = await ref.read(academicsRepositoryProvider).fetchStaffWorkload(academicYearId: widget.academicYearId);
      if (mounted) setState(() => _data = data);
    } catch (_) {
      // best-effort — matches the reference's silent .catch(() => {})
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _barColor(String status) {
    return status == 'overloaded' ? const Color(0xFFEF4444) : (status == 'near-limit' ? const Color(0xFFFBBF24) : const Color(0xFF22C55E));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 64), child: Center(child: Text('Loading workload data…', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))));
    }
    if (_data.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 64), child: Center(child: Text('No workload data. Assign timetable periods first.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))));
    }

    const colTeacher = 140.0, colSubjects = 84.0, colSections = 84.0, colPeriods = 110.0, colLoad = 170.0, colStatus = 110.0;
    const tableWidth = colTeacher + colSubjects + colSections + colPeriods + colLoad + colStatus + 32; // + row horizontal padding (16 * 2)

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: staffLine), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))]),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
              child: Row(children: [
                SizedBox(width: colTeacher, child: _header('Teacher')),
                SizedBox(width: colSubjects, child: _header('Subjects')),
                SizedBox(width: colSections, child: _header('Sections')),
                SizedBox(width: colPeriods, child: _header('Periods / Week')),
                SizedBox(width: colLoad, child: _header('Load')),
                SizedBox(width: colStatus, child: _header('Status')),
              ]),
            ),
            for (final row in _data)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFFAFAFA)))),
                child: Row(children: [
                  SizedBox(width: colTeacher, child: Text(row.teacherName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
                  SizedBox(width: colSubjects, child: Text('${row.subjectsCount}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
                  SizedBox(width: colSections, child: Text('${row.sectionsCount}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
                  SizedBox(width: colPeriods, child: Text('${row.periodsPerWeek} / ${row.maxPeriods}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
                  SizedBox(
                    width: colLoad,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(value: (row.loadPct.clamp(0, 100)) / 100, minHeight: 6, backgroundColor: const Color(0xFFE5E7EB), valueColor: AlwaysStoppedAnimation(_barColor(row.status))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 36, child: Text('${row.loadPct}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
                      ]),
                    ),
                  ),
                  SizedBox(width: colStatus, child: _statusBadge(row.status)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _header(String text) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.3));

  Widget _statusBadge(String status) {
    final (bg, fg, label) = status == 'overloaded'
        ? (const Color(0xFFFEE2E2), const Color(0xFFB91C1C), 'Overloaded')
        : status == 'near-limit'
            ? (const Color(0xFFFEF3C7), const Color(0xFFB45309), 'Near Limit')
            : (const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Normal');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
