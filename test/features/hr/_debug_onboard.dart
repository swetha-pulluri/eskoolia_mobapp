import 'package:eskoolia_mobapp/features/administration/domain/entities/paginated_result.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/department_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/master_option_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/onboard_document_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/onboard_draft_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/staff_form_options_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/entities/staff_lite_entity.dart';
import 'package:eskoolia_mobapp/features/hr/domain/repositories/hr_repository.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/pages/staff_onboard_page.dart';
import 'package:eskoolia_mobapp/features/hr/presentation/providers/hr_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHrRepository implements HrRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<PaginatedResult<DepartmentEntity>> getAllDepartments() async => const PaginatedResult(results: <DepartmentEntity>[], count: 0);
  @override
  Future<PaginatedResult<StaffLiteEntity>> getActiveStaff() async => const PaginatedResult(results: <StaffLiteEntity>[], count: 0);
  @override
  Future<List<OnboardDraftEntity>> getOnboardDrafts() async => const <OnboardDraftEntity>[];
  @override
  Future<List<OnboardDocumentEntity>> getOnboardDocuments() async => const <OnboardDocumentEntity>[];
  @override
  Future<String> getNextStaffNo() async => 'STF-0001';
  @override
  Future<StaffFormOptionsEntity> getStaffFormOptions() async => const StaffFormOptionsEntity();
  @override
  Future<List<MasterOptionEntity>> getMasterLanguages() async => const <MasterOptionEntity>[];
  @override
  Future<List<MasterOptionEntity>> getMasterReligions() async => const <MasterOptionEntity>[];
  @override
  Future<List<MasterOptionEntity>> getMasterCountries() async => const <MasterOptionEntity>[];
  @override
  Future<List<MasterOptionEntity>> getMasterEmploymentTypes() async => const <MasterOptionEntity>[];
}

void main() {
  testWidgets('debug', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hrRepositoryProvider.overrideWithValue(_FakeHrRepository())],
        child: const MaterialApp(home: StaffOnboardPage()),
      ),
    );
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('exception after initial pump: ${tester.takeException()}');

    final iconFinder = find.byIcon(Icons.unfold_more);
    // ignore: avoid_print
    print('icon count: ${iconFinder.evaluate().length}');
    final rect = tester.getRect(iconFinder);
    // ignore: avoid_print
    print('icon rect: $rect');

    await tester.tap(iconFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('exception after tap: ${tester.takeException()}');
    // ignore: avoid_print
    print('listtile count: ${find.byType(ListTile).evaluate().length}');
  });
}
