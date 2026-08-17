import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../attendance/domain/entities/attendance_entities.dart';
import '../../domain/entities/student_attendance_report_row_entity.dart';
import '../providers/reports_providers.dart';

/// Student Attendance Report — mirrors web's
/// `app/(dashboard)/reports/student-attendance/page.tsx` (one of only two
/// live report pages under the Reports module's nav; the other 11 are
/// still "Coming Soon" on web itself). Filters/columns/behavior match that
/// page exactly; the Class/Section lookup reuses the Admin Attendance
/// module's underlying `GET /api/v1/core/classes/` call via
/// [reportsClassesProvider] (not Attendance's own `classesProvider`, which
/// also fetches a `class-summary` this report doesn't need — see that
/// provider's doc comment) instead of web's own `/api/v1/reports/criteria/`
/// call, which doesn't exist on the real backend.
class StudentAttendanceReportPage extends ConsumerStatefulWidget {
  const StudentAttendanceReportPage({super.key});

  @override
  ConsumerState<StudentAttendanceReportPage> createState() => _StudentAttendanceReportPageState();
}

const _kAttendanceTypeOptions = [
  (null, 'All'),
  ('P', 'Present'),
  ('A', 'Absent'),
  ('L', 'Late'),
  ('F', 'Half Day'),
  ('H', 'Holiday'),
];

class _StudentAttendanceReportPageState extends ConsumerState<StudentAttendanceReportPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _classId;
  int? _sectionId;
  String? _attendanceType;

  bool _loading = false;
  bool _hasSearched = false;
  bool _exporting = false;
  String? _error;
  List<StudentAttendanceReportRowEntity> _rows = const [];
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
      final result = await ref.read(reportsRepositoryProvider).getStudentAttendanceReport(
            page: page,
            classId: _classId,
            sectionId: _sectionId,
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
      final bytes = await ref.read(reportsRepositoryProvider).exportStudentAttendanceReportCsv(
            classId: _classId,
            sectionId: _sectionId,
            startDate: _fmtDate(_startDate),
            endDate: _fmtDate(_endDate),
            attendanceType: _attendanceType,
          );
      await saveBytesForDownload(bytes: Uint8List.fromList(bytes), filename: 'student-attendance-report.csv');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report exported.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(reportsClassesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 6, children: [
                Text('Student Attendance', style: AppTextStyles.pageTitle.copyWith(fontSize: 22)),
                Text('Report', style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 24)),
              ]),
              const SizedBox(height: 6),
              const Text('Attendance records across classes and sections.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
              const SizedBox(height: 16),
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
                          'Class',
                          SizedBox(
                            width: 170,
                            child: classesAsync.when(
                              data: (classes) => AppDropdown<int?>(
                                value: _classId,
                                hint: const Text('All Classes', style: TextStyle(fontSize: 12)),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Classes')),
                                  ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) => setState(() {
                                  _classId = v;
                                  _sectionId = null;
                                }),
                              ),
                              loading: () => const SizedBox(height: 36, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                              error: (_, _) => const Text('Unable to load classes', style: TextStyle(fontSize: 11, color: AppColors.dangerRed)),
                            ),
                          ),
                        ),
                        _filterField(
                          'Section',
                          SizedBox(
                            width: 150,
                            child: AppDropdown<int?>(
                              value: _sectionId,
                              hint: const Text('All Sections', style: TextStyle(fontSize: 12)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Sections')),
                                ..._sectionsForSelectedClass(classesAsync.value).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                              ],
                              onChanged: (v) => setState(() => _sectionId = v),
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

  List<SectionSummaryEntity> _sectionsForSelectedClass(List<ClassInfoEntity>? classes) {
    if (classes == null || _classId == null) return const [];
    final match = classes.where((c) => c.id == _classId).toList();
    return match.isEmpty ? const [] : match.first.sections;
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
  static const _colAdmission = 110.0;
  static const _colName = 160.0;
  static const _colClass = 100.0;
  static const _colSection = 90.0;
  static const _colDate = 100.0;
  static const _colStatus = 100.0;
  static const _tableWidth = _colNo + _colAdmission + _colName + _colClass + _colSection + _colDate + _colStatus + 32;

  static const _thStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textTertiary);

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: AppColors.bgSecondary, border: Border(bottom: BorderSide(color: AppColors.borderPrimary))),
      child: const Row(children: [
        SizedBox(width: _colNo, child: Text('#', style: _thStyle)),
        SizedBox(width: _colAdmission, child: Text('ADMISSION NO', style: _thStyle)),
        SizedBox(width: _colName, child: Text('STUDENT NAME', style: _thStyle)),
        SizedBox(width: _colClass, child: Text('CLASS', style: _thStyle)),
        SizedBox(width: _colSection, child: Text('SECTION', style: _thStyle)),
        SizedBox(width: _colDate, child: Text('DATE', style: _thStyle)),
        SizedBox(width: _colStatus, child: Text('STATUS', style: _thStyle)),
      ]),
    );
  }

  Widget _dataRow(int index, StudentAttendanceReportRowEntity row, {required bool isLast}) {
    final (label, color) = _attendanceBadge(row.attendanceType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : const BorderSide(color: AppColors.borderPrimary))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _colNo, child: Text('${(_page - 1) * _pageSize + index + 1}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary))),
          SizedBox(width: _colAdmission, child: Text(row.admissionNo, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondary))),
          SizedBox(width: _colName, child: Text(row.studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          SizedBox(width: _colClass, child: Text(row.className, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(width: _colSection, child: Text(row.sectionName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(width: _colDate, child: Text(row.attendanceDate, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
          SizedBox(
            width: _colStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
            ),
          ),
        ],
      ),
    );
  }

  /// Matches web's `ATTENDANCE_LABELS`/`ATTENDANCE_COLORS` for the student
  /// attendance report exactly: P=Present(green), A=Absent(red),
  /// L=Late(amber), F=Half Day(blue), H=Holiday(gray).
  (String, Color) _attendanceBadge(String code) {
    switch (code) {
      case 'P':
        return ('Present', AppColors.successGreen);
      case 'A':
        return ('Absent', AppColors.dangerRed);
      case 'L':
        return ('Late', AppColors.warningAmber);
      case 'F':
        return ('Half Day', AppColors.infoBlue);
      case 'H':
        return ('Holiday', AppColors.textTertiary);
      default:
        return (code, AppColors.textTertiary);
    }
  }
}
