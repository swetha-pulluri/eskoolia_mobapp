// THROWAWAY test — verifies HrSetupPage has no RenderFlex overflow at real
// phone widths after the hr module responsiveness pass. Delete before done.
import 'package:eskoolia_mobapp/features/administration/domain/entities/paginated_result.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/department_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/department_type_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/designation_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/staff_lite_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/repositories/hr_repository.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/pages/hr_setup_page.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/providers/hr_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHrRepository implements HrRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PaginatedResult<DepartmentEntity>> getDepartments({required int page, int pageSize = 10}) async =>
      const PaginatedResult(results: <DepartmentEntity>[], count: 0);

  @override
  Future<PaginatedResult<DepartmentEntity>> getAllDepartments() async =>
      const PaginatedResult(results: <DepartmentEntity>[], count: 0);

  @override
  Future<PaginatedResult<DepartmentEntity>> getHierarchyDepartments({required int page}) async =>
      const PaginatedResult(results: <DepartmentEntity>[], count: 0);

  @override
  Future<List<DepartmentTypeEntity>> getDepartmentTypes() async => const <DepartmentTypeEntity>[];

  @override
  Future<PaginatedResult<StaffLiteEntity>> getActiveStaff() async =>
      const PaginatedResult(results: <StaffLiteEntity>[], count: 0);

  @override
  Future<PaginatedResult<DesignationEntity>> getDesignations({int? departmentId}) async =>
      const PaginatedResult(results: <DesignationEntity>[], count: 0);
}

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [hrRepositoryProvider.overrideWithValue(_FakeHrRepository())],
      child: const MaterialApp(home: HrSetupPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('HrSetupPage has no overflow at 320dp', (tester) async {
    await _pumpAtWidth(tester, 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HrSetupPage has no overflow at 360dp', (tester) async {
    await _pumpAtWidth(tester, 360);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HrSetupPage has no overflow at 390dp', (tester) async {
    await _pumpAtWidth(tester, 390);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HrSetupPage has no overflow at 412dp', (tester) async {
    await _pumpAtWidth(tester, 412);
    expect(tester.takeException(), isNull);
  });
}
