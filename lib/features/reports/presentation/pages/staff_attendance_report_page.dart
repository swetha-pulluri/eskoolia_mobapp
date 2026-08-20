import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/staff_attendance_report_row_entity.dart';
import '../providers/reports_providers.dart';

/// Staff Attendance Report — mirrors web's
/// `app/(dashboard)/reports/staff-attendance/page.tsx` (the other of the
/// two live report pages under the Reports module's nav). Department
/// lookup reuses HR's existing `hrRepositoryProvider.getAllDepartments()`
/// instead of web's own `/api/v1/reports/criteria/` call, which doesn't
/// exist on the real backend.
class StaffAttendanceReportPage extends ConsumerStatefulWidget {
  const StaffAttendanceReportPage({super.key});

  @override
  ConsumerState<StaffAttendanceReportPage> createState() => _StaffAttendanceReportPageState();
}

// Matches the real backend vocabulary for STAFF attendance exactly
// (`apps/hr/models.py`: STATUS_PRESENT/ABSENT/LEAVE/HALF_DAY/HOLIDAY) —
// "Leave", not "Late" (that's the student-attendance report's own,
// different vocabulary).
const _kAttendanceTypeOptions = [
  (null, 'All'),
  ('P', 'Present'),
  ('A', 'Absent'),
  ('L', 'Leave'),
  ('H', 'Holiday'),
  ('F', 'Half Day'),
];

class _StaffAttendanceReportPageState extends ConsumerState<StaffAttendanceReportPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _departmentId;
  String? _attendanceType;

  bool _loading = false;
  bool _hasSearched = false;
  bool _exporting = false;
  String? _error;
  List<StaffAttendanceReportRowEntity> _rows = const [];
  int _count = 0;
  int _page = 1;

  static const _pageSize = 20;
  int get _totalPages => (_count / _pageSize).ceil().clamp(1, 999999);

  String? _fmtDate(DateTime? d) => d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _search({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(reportsRepositoryProvider).getStaffAttendanceReport(
            page: page,
            departmentId: _departmentId,
            startDate: _fmtDate(_startDate),
            endDate: _fmtDate(_endDate),
            attendanceType: _attendanceType,
          );
      if (mounted) {
        setState(() {
          _rows = result.results;
          _count = result.count;
          _page = page;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(reportsRepositoryProvider).exportStaffAttendanceReportCsv(
            departmentId: _departmentId,
            startDate: _fmtDate(_startDate),
            endDate: _fmtDate(_endDate),
            attendanceType: _attendanceType,
          );
      await saveBytesForDownload(bytes: Uint8List.fromList(bytes), filename: 'staff-attendance-report.csv');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report exported.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(reportsDepartmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Own card — same white/gray-bordered style already used by
              // the filter bar and results table below — instead of
              // floating text directly on the page background.
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(spacing: 6, children: [
                      Text('Staff Attendance', style: AppTextStyles.pageTitle.copyWith(fontSize: 22)),
                      Text('Report', style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 24)),
                    ]),
                    const SizedBox(height: 6),
                    const Text('Attendance records across staff departments.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _filterField('Date From', SizedBox(width: 150, child: _dateBox(_startDate, () => _pickDate(isStart: true)))),
                        _filterField('Date To', SizedBox(width: 150, child: _dateBox(_endDate, () => _pickDate(isStart: false)))),
                        _filterField(
                          'Department',
                          SizedBox(
                            width: 180,
                            child: departmentsAsync.when(
                              data: (departments) => AppDropdown<int?>(
                                value: _departmentId,
                                hint: const Text('All Departments', style: TextStyle(fontSize: 12)),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Departments')),
                                  ...departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) => setState(() => _departmentId = v),
                              ),
                              loading: () => const SizedBox(height: 36, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                              error: (_, _) => const Text('Unable to load departments', style: TextStyle(fontSize: 11, color: AppColors.dangerRed)),
                            ),
                          ),
                        ),
                        _filterField(
                          'Attendance',
                          SizedBox(
                            width: 140,
                            child: AppDropdown<String?>(
                              value: _attendanceType,
                              hint: const Text('All', style: TextStyle(fontSize: 12)),
                              items: _kAttendanceTypeOptions.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2))).toList(),
                              onChanged: (v) => setState(() => _attendanceType = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _loading ? null : () => _search(page: 1),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: Text(_loading ? 'Loading…' : 'Search'),
                        ),
                        if (_hasSearched)
                          OutlinedButton.icon(
                            onPressed: _exporting ? null : _exportCsv,
                            icon: _exporting ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download, size: 14),
                            label: Text(_exporting ? 'Exporting…' : 'Export CSV'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.borderPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 12.5))),
              if (_hasSearched) ...[
                Text('Total Records: $_count', style: AppTextStyles.sectionSubtitle),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: _rows.isEmpty
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No records found.', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _tableWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _headerRow(),
                                for (var i = 0; i < _rows.length; i++) _dataRow(i, _rows[i], isLast: i == _rows.length - 1),
                              ],
                            ),
                          ),
                        ),
                ),
                if (_totalPages > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page $_page of $_totalPages', style: AppTextStyles.sectionSubtitle),
                      Row(children: [
                        OutlinedButton(onPressed: _loading || _page <= 1 ? null : () => _search(page: _page - 1), child: const Text('Previous')),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _loading || _page >= _totalPages ? null : () => _search(page: _page + 1), child: const Text('Next')),
                      ]),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _dateBox(DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: AppColors.bgSecondary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(child: Text(value == null ? 'Select date' : _fmtDate(value)!, style: TextStyle(fontSize: 12, color: value == null ? AppColors.textTertiary : AppColors.textPrimary))),
        ]),
      ),
    );
  }

  static const _colNo = 40.0;
  static const _colStaffNo = 100.0;
  static const _colName = 150.0;
  static const _colDept = 140.0;
  static const _colDate = 100.0;
  static const _colStatus = 90.0;
  static const _colNote = 160.0;
  static const _tableWidth = _colNo + _colStaffNo + _colName + _colDept + _colDate + _colStatus + _colNote + 32;

  static const _thStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textTertiary);

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: AppColors.bgSecondary, border: Border(bottom: BorderSide(color: AppColors.borderPrimary))),
      child: const Row(children: [
        SizedBox(width: _colNo, child: Text('#', style: _thStyle)),
        SizedBox(width: _colStaffNo, child: Text('STAFF NO', style: _thStyle)),
        SizedBox(width: _colName, child: Text('STAFF NAME', style: _thStyle)),
        SizedBox(width: _colDept, child: Text('DEPARTMENT', style: _thStyle)),
        SizedBox(width: _colDate, child: Text('DATE', style: _thStyle)),
        SizedBox(width: _colStatus, child: Text('STATUS', style: _thStyle)),
        SizedBox(width: _colNote, child: Text('NOTE', style: _thStyle)),
      ]),
    );
  }

  Widget _dataRow(int index, StaffAttendanceReportRowEntity row, {required bool isLast}) {
    final (label, color) = _attendanceBadge(row.attendanceType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : const BorderSide(color: AppColors.borderPrimary))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _colNo, child: Text('${(_page - 1) * _pageSize + index + 1}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary))),
          SizedBox(width: _colStaffNo, child: Text(row.staffNo, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondary))),
          SizedBox(width: _colName, child: Text(row.staffName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          SizedBox(width: _colDept, child: Text(row.department, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(width: _colDate, child: Text(row.attendanceDate, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
          SizedBox(
            width: _colStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
            ),
          ),
          SizedBox(width: _colNote, child: Text(row.note.isEmpty ? '—' : row.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary))),
        ],
      ),
    );
  }

  /// Matches the real backend's staff-attendance vocabulary exactly
  /// (`apps/hr/models.py` STATUS_* constants) — "Leave", not "Late".
  (String, Color) _attendanceBadge(String code) {
    switch (code) {
      case 'P':
        return ('Present', AppColors.successGreen);
      case 'A':
        return ('Absent', AppColors.dangerRed);
      case 'L':
        return ('Leave', AppColors.warningAmber);
      case 'F':
        return ('Half Day', AppColors.infoBlue);
      case 'H':
        return ('Holiday', AppColors.textTertiary);
      default:
        return (code, AppColors.textTertiary);
    }
  }
}
