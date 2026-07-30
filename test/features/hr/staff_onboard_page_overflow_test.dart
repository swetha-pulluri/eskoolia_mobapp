// THROWAWAY test — verifies the 10-step StaffOnboardPage wizard has no
// RenderFlex overflow at real phone widths after the hr module
// responsiveness pass. Delete before done.
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
import 'package:eskoolia_mobapp/features/hr/presentation/widgets/onboard/onboard_steps.dart';
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
  Future<PaginatedResult<StaffLiteEntity>> getActiveStaff() async =>
      const PaginatedResult(results: <StaffLiteEntity>[], count: 0);

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

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
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
}

/// Jumps directly to [stepNum] (1-10) via the step-jump bottom sheet, which
/// (unlike the Next button) has no validation gate — the only way to force
/// every step to actually render without filling in the whole form first.
Future<void> _goToStep(WidgetTester tester, int stepNum) async {
  await tester.tap(find.byIcon(Icons.unfold_more));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ListTile).at(stepNum - 1));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 412.0]) {
    testWidgets('StaffOnboardPage has no overflow across all 10 steps at ${width}dp', (tester) async {
      await _pumpAtWidth(tester, width);
      expect(tester.takeException(), isNull, reason: 'initial render at ${width}dp');

      for (var step = 1; step <= onboardTotalSteps; step++) {
        await _goToStep(tester, step);
        expect(tester.takeException(), isNull, reason: 'step $step at ${width}dp');
      }
    });
  }
}
