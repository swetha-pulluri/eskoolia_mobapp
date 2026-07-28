import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../administration/domain/entities/paginated_result.dart';
import '../../data/datasources/hr_remote_datasource.dart';
import '../../data/repositories/hr_repository_impl.dart';
import '../../domain/entities/attendance_daily_summary_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/department_type_entity.dart';
import '../../domain/entities/designation_entity.dart';
import '../../domain/entities/master_option_entity.dart';
import '../../domain/entities/onboard_document_entity.dart';
import '../../domain/entities/onboard_draft_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_form_options_entity.dart';
import '../../domain/entities/staff_lite_entity.dart';
import '../../domain/repositories/hr_repository.dart';

final hrRemoteDataSourceProvider = Provider<HrRemoteDataSource>((ref) {
  return HrRemoteDataSource(ref.watch(dioClientProvider));
});

final hrRepositoryProvider = Provider<HrRepository>((ref) {
  return HrRepositoryImpl(ref.watch(hrRemoteDataSourceProvider));
});

/// Step 1 department list page (10/page), matching web's `deptPage`.
final deptPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final departmentsProvider = FutureProvider.autoDispose<PaginatedResult<DepartmentEntity>>((ref) {
  final page = ref.watch(deptPageProvider);
  return ref.watch(hrRepositoryProvider).getDepartments(page: page);
});

/// Unpaginated-ish (200/page) department list for dropdowns (Designation
/// form's department picker), matching web's `useAllDepartments()`.
final allDepartmentsProvider = FutureProvider.autoDispose<PaginatedResult<DepartmentEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getAllDepartments();
});

/// Step 2 hierarchy department list page (5/page), matching web's `desigDeptPage`.
final desigDeptPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final hierarchyDepartmentsProvider = FutureProvider.autoDispose<PaginatedResult<DepartmentEntity>>((ref) {
  final page = ref.watch(desigDeptPageProvider);
  return ref.watch(hrRepositoryProvider).getHierarchyDepartments(page: page);
});

/// All designations (200/page, no filter) — grouped client-side by
/// department, matching web's `useDesignations()` + in-memory `.filter()`.
final designationsProvider = FutureProvider.autoDispose<PaginatedResult<DesignationEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getDesignations();
});

/// Active staff — source for the "Staff Assigned" KPI card's count, and for
/// the Add/Edit Department drawer's Department Head / Deputy Head pickers
/// (matches web's own `useStaffList()`).
final activeStaffProvider = FutureProvider.autoDispose<PaginatedResult<StaffLiteEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getActiveStaff();
});

/// Department Type dropdown options — predefined types + the school's own
/// custom ones, matching web's `useDepartmentTypes()`.
final departmentTypesProvider = FutureProvider.autoDispose<List<DepartmentTypeEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getDepartmentTypes();
});

/// Refreshes every HR Setup data provider — matches web's practice of
/// calling multiple `refetchX()` calls together after a mutation
/// (e.g. `refetchDepts(); refetchAllDepts(); refetchHierDepts();`).
void invalidateHrSetupData(WidgetRef ref) {
  ref.invalidate(departmentsProvider);
  ref.invalidate(allDepartmentsProvider);
  ref.invalidate(hierarchyDepartmentsProvider);
  ref.invalidate(designationsProvider);
  ref.invalidate(activeStaffProvider);
  ref.invalidate(departmentTypesProvider);
}

// ─── Staff Directory ────────────────────────────────────────────────────
// Matches `HrStaffDirectoryPanel`'s own filter/pagination state exactly:
// search + role/department/designation/status filters, page_size default 25.

final staffSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final staffRoleFilterProvider = StateProvider.autoDispose<int?>((ref) => null);
final staffDepartmentFilterProvider = StateProvider.autoDispose<int?>((ref) => null);
final staffDesignationFilterProvider = StateProvider.autoDispose<int?>((ref) => null);
final staffStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');
final staffPageProvider = StateProvider.autoDispose<int>((ref) => 1);
/// 50, matching the real `HrDirectoryPage`'s own fixed `page_size: "50"`
/// (that page has no pagination controls — it just loads up to 50 and
/// groups them into department accordions).
final staffPageSizeProvider = StateProvider.autoDispose<int>((ref) => 50);

final staffDirectoryProvider = FutureProvider.autoDispose<PaginatedResult<StaffEntity>>((ref) {
  final page = ref.watch(staffPageProvider);
  final pageSize = ref.watch(staffPageSizeProvider);
  final search = ref.watch(staffSearchProvider);
  final role = ref.watch(staffRoleFilterProvider);
  final department = ref.watch(staffDepartmentFilterProvider);
  final designation = ref.watch(staffDesignationFilterProvider);
  final status = ref.watch(staffStatusFilterProvider);
  return ref.watch(hrRepositoryProvider).getStaffPage(
        page: page,
        pageSize: pageSize,
        search: search,
        roleId: role,
        departmentId: department,
        designationId: designation,
        status: status == 'all' ? null : status,
      );
});

/// Roles for the Staff Directory's Role filter — matches web's own
/// `GET /api/v1/access-control/roles/` (separate from `form-options`).
final rolesProvider = FutureProvider.autoDispose<List<RoleEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getRoles();
});

/// Bundled roles/departments/designations for the Add/Edit Staff form.
final staffFormOptionsProvider = FutureProvider.autoDispose<StaffFormOptionsEntity>((ref) {
  return ref.watch(hrRepositoryProvider).getStaffFormOptions();
});

/// "Present today" Smart Filter — real backend data (today's
/// `/api/v1/hr/staff-attendance/` records), independent of the Attendance
/// page's own selectable date so visiting that page first can't change
/// what "today" means here.
final staffPresentTodayFilterProvider = StateProvider.autoDispose<String>((ref) => 'any');

final todayAttendanceProvider = FutureProvider.autoDispose<PaginatedResult<StaffAttendanceEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getAttendanceForDate(_todayIso());
});

void invalidateStaffDirectory(WidgetRef ref) {
  ref.invalidate(staffDirectoryProvider);
  ref.invalidate(activeStaffProvider);
  ref.invalidate(todayAttendanceProvider);
}

// ─── Staff Attendance ───────────────────────────────────────────────────
// Matches the real `HrStaffAttendancePage`'s own state shape (date, search,
// status filter, department filter), backed only by the confirmed real API
// surface: plain `/staff-attendance/` CRUD + `bulk-store/` + `report/`.

String _todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

final attendanceDateProvider = StateProvider.autoDispose<String>((ref) => _todayIso());
final attendanceSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final attendanceStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');
final attendanceDeptFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

/// All active staff (200/page) — the roster attendance is marked against,
/// matching web's own `useStaffList()`/`useStaff({status:'active'})` fetch.
final allActiveStaffProvider = FutureProvider.autoDispose<PaginatedResult<StaffEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getStaffPage(page: 1, pageSize: 200, status: 'active');
});

final attendanceForDateProvider = FutureProvider.autoDispose<PaginatedResult<StaffAttendanceEntity>>((ref) {
  final date = ref.watch(attendanceDateProvider);
  return ref.watch(hrRepositoryProvider).getAttendanceForDate(date);
});

final attendanceReportProvider = FutureProvider.autoDispose<AttendanceReportEntity>((ref) {
  final date = ref.watch(attendanceDateProvider);
  return ref.watch(hrRepositoryProvider).getAttendanceReport(attendanceDate: date);
});

/// Real source for the KPI row — `/staff-attendance/daily-summary/`'s
/// school-scoped active-staff total + per-status counts + `late_arrivals`,
/// matching web's own `kpiSummary` (NOT a client-computed `allStaff.length`).
final dailySummaryProvider = FutureProvider.autoDispose<AttendanceDailySummaryEntity>((ref) {
  final date = ref.watch(attendanceDateProvider);
  final deptId = ref.watch(attendanceDeptFilterProvider);
  return ref.watch(hrRepositoryProvider).getDailySummary(date: date, departmentId: deptId);
});

void invalidateAttendanceData(WidgetRef ref) {
  ref.invalidate(attendanceForDateProvider);
  ref.invalidate(attendanceReportProvider);
  ref.invalidate(dailySummaryProvider);
}

// ─── Staff Onboarding Wizard ──────────────────────────────────────────────
// Matches the real `/hr/onboard` 10-step wizard's own state shape: a single
// flat form-data map shared across all steps (mirroring web's own `form`
// useState object), current/highest step, and the real backend-confirmed
// drafts/documents/master-data endpoints.

final onboardDraftsProvider = FutureProvider.autoDispose<List<OnboardDraftEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getOnboardDrafts();
});

void invalidateOnboardDrafts(WidgetRef ref) {
  ref.invalidate(onboardDraftsProvider);
}

/// The in-progress wizard's shared flat form-data map — every step widget
/// reads/writes only the keys it owns, exactly matching the real web's
/// single shared `form` state object.
final onboardFormProvider = StateProvider.autoDispose<Map<String, dynamic>>((ref) => <String, dynamic>{});

/// The currently-saved draft's id, if any (null until the first save).
final onboardDraftIdProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Current step (1-10), matching web's `step`.
final onboardStepProvider = StateProvider.autoDispose<int>((ref) => 1);

/// Highest step reached (1-10), matching web's `highestStep` — visiting past
/// a step marks it "done" in the step-jump sheet, same rule as the real page.
final onboardHighestStepProvider = StateProvider.autoDispose<int>((ref) => 1);

final onboardDocumentsProvider = FutureProvider.autoDispose<List<OnboardDocumentEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getOnboardDocuments();
});

void invalidateOnboardDocuments(WidgetRef ref) {
  ref.invalidate(onboardDocumentsProvider);
}

final masterLanguagesProvider = FutureProvider.autoDispose<List<MasterOptionEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getMasterLanguages();
});

final masterReligionsProvider = FutureProvider.autoDispose<List<MasterOptionEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getMasterReligions();
});

final masterCountriesProvider = FutureProvider.autoDispose<List<MasterOptionEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getMasterCountries();
});

final masterEmploymentTypesProvider = FutureProvider.autoDispose<List<MasterOptionEntity>>((ref) {
  return ref.watch(hrRepositoryProvider).getMasterEmploymentTypes();
});
