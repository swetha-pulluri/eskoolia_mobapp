// THROWAWAY test — verifies StaffDirectoryPage has no RenderFlex overflow at
// real phone widths after the hr module responsiveness pass. Delete before
// done.
import 'package:eskoolia_mobapp/features/administration/domain/entities/paginated_result.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/department_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/designation_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/staff_attendance_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/staff_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/repositories/hr_repository.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/pages/staff_directory_page.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/providers/hr_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHrRepository implements HrRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PaginatedResult<DepartmentEntity>> getAllDepartments() async =>
      const PaginatedResult(results: <DepartmentEntity>[], count: 0);

  @override
  Future<PaginatedResult<DesignationEntity>> getDesignations({int? departmentId}) async =>
      const PaginatedResult(results: <DesignationEntity>[], count: 0);

  @override
  Future<PaginatedResult<StaffEntity>> getStaffPage({
    required int page,
    required int pageSize,
    String? search,
    int? roleId,
    int? departmentId,
    int? designationId,
    String? status,
  }) async =>
      const PaginatedResult(results: <StaffEntity>[], count: 0);

  @override
  Future<PaginatedResult<StaffAttendanceEntity>> getAttendanceForDate(String date) async =>
      const PaginatedResult(results: <StaffAttendanceEntity>[], count: 0);
}

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [hrRepositoryProvider.overrideWithValue(_FakeHrRepository())],
      child: const MaterialApp(home: StaffDirectoryPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('StaffDirectoryPage has no overflow at 320dp', (tester) async {
    await _pumpAtWidth(tester, 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaffDirectoryPage has no overflow at 360dp', (tester) async {
    await _pumpAtWidth(tester, 360);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaffDirectoryPage has no overflow at 390dp', (tester) async {
    await _pumpAtWidth(tester, 390);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StaffDirectoryPage has no overflow at 412dp', (tester) async {
    await _pumpAtWidth(tester, 412);
    expect(tester.takeException(), isNull);
  });
}
