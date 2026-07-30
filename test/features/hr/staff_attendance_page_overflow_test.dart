// THROWAWAY test — verifies StaffAttendancePage (including the inline
// MonthlyAttendanceReport and the AttendanceAbsentDialog it can open) has no
// RenderFlex overflow at real phone widths after the hr attendance
// responsiveness pass. Delete before done.
import 'package:eskoolia_mobapp/features/administration/domain/entities/paginated_result.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/attendance_daily_summary_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/department_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/staff_attendance_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/staff_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/repositories/hr_repository.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/pages/staff_attendance_page.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/providers/hr_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String _todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

// A deliberately long name to exercise the department-card header overflow
// fix (`Flexible` + ellipsis around the department name `Text`).
const _dept = DepartmentEntity(id: 1, name: 'Administration, Human Resources & Compliance Department');

const _staff = <StaffEntity>[
  StaffEntity(id: 1, firstName: 'Aishwarya', lastName: 'Venkataraghavan Subramaniam', staffNo: 'STF-001', joinDate: '2020-01-01', departmentId: 1),
  StaffEntity(id: 2, firstName: 'Bob', lastName: 'Singh', staffNo: 'STF-002', joinDate: '2021-01-01', departmentId: 1),
  StaffEntity(id: 3, firstName: 'Charlie', lastName: 'Rao', staffNo: 'STF-003', joinDate: '2021-06-01', departmentId: 1),
];

class _FakeHrRepository implements HrRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PaginatedResult<DepartmentEntity>> getAllDepartments() async => const PaginatedResult(results: [_dept], count: 1);

  @override
  Future<PaginatedResult<StaffEntity>> getStaffPage({
    required int page,
    required int pageSize,
    String? search,
    int? roleId,
    int? departmentId,
    int? designationId,
    String? status,
  }) async => const PaginatedResult(results: _staff, count: 3);

  @override
  Future<PaginatedResult<StaffAttendanceEntity>> getAttendanceForDate(String date) async {
    final today = _todayIso();
    return PaginatedResult(results: [
      StaffAttendanceEntity(staffId: 1, attendanceDate: today, attendanceType: 'P', signInTime: '09:00', arrivalTime: '09:00'),
      StaffAttendanceEntity(staffId: 2, attendanceDate: today, attendanceType: 'A', note: 'Personal leave'),
      // staff 3 intentionally has no record — its ABSENT switch stays enabled.
    ], count: 2);
  }

  @override
  Future<PaginatedResult<StaffAttendanceEntity>> getAllAttendance() async {
    final today = _todayIso();
    return PaginatedResult(results: [
      StaffAttendanceEntity(staffId: 1, attendanceDate: today, attendanceType: 'P', signInTime: '09:00', arrivalTime: '09:00'),
      StaffAttendanceEntity(staffId: 2, attendanceDate: today, attendanceType: 'A', note: 'Personal leave'),
    ], count: 2);
  }

  @override
  Future<AttendanceDailySummaryEntity> getDailySummary({required String date, int? departmentId}) async =>
      const AttendanceDailySummaryEntity(totalStaff: 3, present: 1, absent: 1, lateArrivals: 0);
}

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [hrRepositoryProvider.overrideWithValue(_FakeHrRepository())],
      child: const MaterialApp(home: StaffAttendancePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 412.0]) {
    testWidgets('StaffAttendancePage (incl. Monthly Report) has no overflow at ${width}dp', (tester) async {
      await _pumpAtWidth(tester, width);
      expect(tester.takeException(), isNull);
      // Sanity: real rows actually rendered, not just an empty state.
      expect(find.text('STF-001'), findsOneWidget);
      expect(find.textContaining('Administration'), findsWidgets);
    });
  }

  testWidgets('AttendanceAbsentDialog opens without overflow at 320dp', (tester) async {
    await _pumpAtWidth(tester, 320);

    // Staff 3 has no existing mark, so its ABSENT switch is enabled. The row
    // has two `Switch`es (ABSENT, then LUNCH) — take the first.
    final row3 = find.ancestor(of: find.text('STF-003'), matching: find.byType(Row)).first;
    final absentSwitch = find.descendant(of: row3, matching: find.byType(Switch)).first;
    await tester.ensureVisible(absentSwitch);
    await tester.pumpAndSettle();
    await tester.tap(absentSwitch);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Confirm dialog -> "Mark absent" opens AttendanceAbsentDialog.
    await tester.tap(find.text('Mark absent'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('QUICK REASONS'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
