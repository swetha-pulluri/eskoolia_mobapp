import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../attendance/domain/entities/attendance_entities.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../hr/domain/entities/department_entity.dart';
import '../../../hr/presentation/providers/hr_provider.dart';
import '../../../student/domain/models/school_class.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/repositories/reports_repository.dart';

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
  return ReportsRemoteDataSource(ref.watch(dioClientProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.watch(reportsRemoteDataSourceProvider));
});

/// All departments for the Staff Attendance Report's Department filter —
/// reuses HR's existing `hrRepositoryProvider.getAllDepartments()` (`GET
/// /api/v1/hr/departments/?page_size=200`) rather than the web frontend's
/// `/api/v1/reports/criteria/` call, which doesn't exist on the real
/// backend (verified — `apps/reports/urls.py` has no `criteria/` route).
final reportsDepartmentsProvider = FutureProvider.autoDispose<List<DepartmentEntity>>((ref) async {
  final result = await ref.watch(hrRepositoryProvider).getAllDepartments();
  return result.results;
});

// ── Shared Class/Section lookups — one warm fetch reused across every
// report submodule instead of each page independently re-hitting
// `/api/v1/core/classes/`/`/api/v1/core/sections/` from a cold start.
// Deliberately NOT `.autoDispose`: the class/section list is small and
// effectively static for the session, so keeping it cached for as long as
// the app runs (until an explicit `ref.invalidate`) is strictly better
// than refetching every time a report page is opened, closed, and reopened.

/// Classes + nested sections for the Student Attendance Report's Class/
/// Section filters. Reuses the Attendance module's existing
/// `getClasses()` repository call (`GET /api/v1/core/classes/`) — but,
/// unlike Attendance's own `classesProvider`
/// (`attendance_provider.dart:71`), does NOT also fetch
/// `/student-attendance/class-summary/` (this report shows no
/// present/absent tiles, so that second call was pure waste) and is not
/// tied to `attendanceReloadProvider`/`selectedDateProvider` — Reports has
/// no reason to refetch just because Attendance's own selected date
/// changed elsewhere in the app. Keeps the same school-scoping fix
/// `classesProvider` applies (superuser accounts otherwise get every
/// school's classes unscoped).
final reportsClassesProvider = FutureProvider<List<ClassInfoEntity>>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  final currentSchoolId = ref.watch(authNotifierProvider).maybeWhen(authenticated: (u) => u.schoolId, orElse: () => null);
  final classes = await repository.getClasses();
  return currentSchoolId == null ? classes : classes.where((c) => c.schoolId == null || c.schoolId == currentSchoolId).toList();
});

/// Class dropdown options for the generic Report Explorer (all 29 report
/// definitions' `LookupSource.classes` filter field) — `(id, label)`
/// pairs via `ReportsRepository.getClassOptions()`. Shared across every
/// report definition instead of each one's own page instance keeping a
/// throwaway local cache that's lost the moment you navigate away.
final reportsClassOptionsProvider = FutureProvider<List<(int, String)>>((ref) {
  return ref.watch(reportsRepositoryProvider).getClassOptions();
});

/// Section dropdown options for the generic Report Explorer's
/// `LookupSource.sections` filter field, keyed by the selected class id
/// (`null` = unfiltered/"all sections", matching how `getSectionOptions`
/// itself treats a null `classId`). `.family` gives each distinct class
/// its own cached result, so switching back to a previously-selected class
/// reuses that class's sections instead of re-fetching them.
final reportsSectionOptionsProvider = FutureProvider.family<List<(int, String)>, int?>((ref, classId) {
  return ref.watch(reportsRepositoryProvider).getSectionOptions(classId: classId);
});

/// Classes + nested sections for the Student Export report's Class/Section
/// filters, via the Student feature's existing `fetchClasses()` (`GET
/// /api/v1/core/classes/`). Cached so revisiting Student Export within the
/// same session reuses the previous fetch instead of reloading from a cold
/// start every time the page mounts.
final reportsExportClassesProvider = FutureProvider<List<SchoolClass>>((ref) {
  return ref.watch(studentRepositoryProvider).fetchClasses();
});
