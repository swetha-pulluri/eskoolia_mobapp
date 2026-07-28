import '../../../administration/domain/entities/paginated_result.dart';
import '../entities/attendance_daily_summary_entity.dart';
import '../entities/attendance_import_result_entity.dart';
import '../entities/attendance_monthly_report_entity.dart';
import '../entities/department_entity.dart';
import '../entities/department_type_entity.dart';
import '../entities/designation_entity.dart';
import '../entities/master_option_entity.dart';
import '../entities/onboard_document_entity.dart';
import '../entities/onboard_draft_entity.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../entities/role_entity.dart';
import '../entities/staff_attendance_entity.dart';
import '../entities/staff_entity.dart';
import '../entities/staff_files_draft.dart';
import '../entities/staff_form_options_entity.dart';
import '../entities/staff_lite_entity.dart';

/// Thrown on a DRF validation/permission/not-found error from the HR API.
/// The real backend's HR viewsets use their own `handle_exception` override:
/// `{"success": false, "message": "<msg>", "errors": {field: [messages]}}`.
class HrApiException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const HrApiException(this.message, [this.fieldErrors = const {}]);

  @override
  String toString() => message;
}

abstract class HrRepository {
  Future<PaginatedResult<DepartmentEntity>> getDepartments({required int page, int pageSize = 10});

  Future<PaginatedResult<DepartmentEntity>> getAllDepartments();

  Future<PaginatedResult<DepartmentEntity>> getHierarchyDepartments({required int page});

  Future<DepartmentEntity> createDepartment(DepartmentEntity draft);

  Future<DepartmentEntity> updateDepartment(int id, DepartmentEntity draft);

  Future<void> deleteDepartment(int id);

  /// GET `/api/v1/hr/department-types/` — real, confirmed endpoint on the
  /// branch that actually powers the live Department Type dropdown
  /// (predefined types + the school's own custom ones).
  Future<List<DepartmentTypeEntity>> getDepartmentTypes();

  /// POST `/api/v1/hr/department-types/` — creates a school-scoped custom
  /// department type.
  Future<DepartmentTypeEntity> createDepartmentType(String name);

  Future<PaginatedResult<StaffLiteEntity>> getActiveStaff();

  Future<PaginatedResult<DesignationEntity>> getDesignations({int? departmentId});

  Future<DesignationEntity> createDesignation(DesignationEntity draft);

  Future<DesignationEntity> updateDesignation(int id, DesignationEntity draft);

  Future<void> deleteDesignation(int id);

  // ─── Staff Directory & Onboarding ───────────────────────────────────

  Future<PaginatedResult<StaffEntity>> getStaffPage({
    required int page,
    required int pageSize,
    String? search,
    int? roleId,
    int? departmentId,
    int? designationId,
    String? status,
  });

  Future<StaffEntity> getStaffById(int id);

  Future<StaffEntity> createStaff(StaffEntity draft, {StaffFilesDraft files = const StaffFilesDraft(), List<PickedOtherDocument> otherDocuments = const []});

  Future<StaffEntity> updateStaff(int id, StaffEntity draft, {StaffFilesDraft files = const StaffFilesDraft(), List<PickedOtherDocument> otherDocuments = const []});

  Future<void> deleteStaff(int id);

  Future<void> updateStaffStatus(int id, String status);

  Future<StaffFormOptionsEntity> getStaffFormOptions();

  Future<String> getNextStaffNo();

  Future<List<RoleEntity>> getRoles();

  // ─── Staff Attendance ────────────────────────────────────────────────

  /// GET `/api/v1/hr/staff-attendance/?attendance_date=X&page_size=500` —
  /// real, confirmed filterable field. No `department` param (unconfirmed
  /// on the real ViewSet) — callers group client-side instead.
  Future<PaginatedResult<StaffAttendanceEntity>> getAttendanceForDate(String date);

  /// GET `/api/v1/hr/staff-attendance/?page_size=1000` over an arbitrary
  /// date range, fetched unfiltered and narrowed client-side (the real
  /// `attendance_date` filter is exact-match only, no range lookup) — used
  /// for the simplified real Monthly Report.
  Future<PaginatedResult<StaffAttendanceEntity>> getAllAttendance();

  /// POST `/api/v1/hr/staff-attendance/bulk-store/` — a real, confirmed
  /// custom action (`{"rows": [...]}` -> `{"detail","count"}`).
  Future<int> bulkSaveAttendance(List<StaffAttendanceEntity> rows);

  /// GET `/api/v1/hr/staff-attendance/report/?attendance_date=X` — a real,
  /// confirmed custom action returning `{total, by_type}` for whatever
  /// filters are applied to the underlying queryset.
  Future<AttendanceReportEntity> getAttendanceReport({String? attendanceDate});

  /// GET `/api/v1/hr/staff-attendance/daily-summary/?date=&department=` —
  /// real, confirmed custom action on `origin/demo` (the actual live HR
  /// backend) returning the school-scoped active-staff total plus
  /// per-status counts and `late_arrivals` — the true source for the
  /// Attendance page's KPI row (NOT a locally-fetched staff list's length).
  Future<AttendanceDailySummaryEntity> getDailySummary({required String date, int? departmentId});

  /// GET `/api/v1/hr/staff-attendance/monthly-report/?month=&year=&department=&staff=`
  /// — real, confirmed custom action on `origin/demo` returning
  /// `{records, rows, insights}` for the Monthly Attendance Report.
  Future<AttendanceMonthlyReportEntity> getMonthlyReport({required int month, required int year, int? departmentId, int? staffId});

  /// GET `/api/v1/hr/staff-attendance/download-sample/` — a real, standalone
  /// `APIView` (`apps/hr/attendance_endpoints.py`, registered directly in
  /// `urls.py`, not a ViewSet `@action`) returning a blank import-template
  /// `.xlsx`.
  Future<List<int>> downloadSampleAttendance();

  /// GET `/api/v1/hr/staff-attendance/export/?date=&department=&attendance_type=&fmt=`
  /// — real, standalone `APIView` (same file as above) that takes
  /// precedence over the ViewSet's own same-path `export` action because
  /// `urls.py` lists it first. Returns real `.xlsx`/`.csv` bytes.
  Future<List<int>> exportAttendance({String? date, String? department, String? attendanceType, String fmt = 'xlsx'});

  /// POST `/api/v1/hr/staff-attendance/import/` (multipart: `attendance_date`
  /// + `file`) — real, standalone `APIView`; returns `{imported, failed,
  /// errors}`.
  Future<AttendanceImportResultEntity> importAttendance({required String attendanceDate, required PickedAttachment file});

  // ─── Staff Onboarding Wizard ─────────────────────────────────────────
  // Real, confirmed endpoints (verified read-only on `demo`/`BugFix`'s
  // `apps/hr/{models,serializers,views,urls}.py`) — `StaffOnboardDraft`
  // model, reportlab-based PDF views, `StaffOnboardDocument` model.

  /// GET `/api/v1/hr/onboard/drafts/`.
  Future<List<OnboardDraftEntity>> getOnboardDrafts();

  /// POST `/api/v1/hr/onboard/drafts/save/` — the real backend caps this at
  /// `MAX_DRAFTS_PER_USER = 10` and returns a 400 (surfaced as
  /// [HrApiException]) past that; it does not auto-evict the oldest draft.
  Future<OnboardDraftEntity> saveOnboardDraft({int? id, required Map<String, dynamic> formData, required int currentStep});

  /// DELETE `/api/v1/hr/onboard/drafts/{id}/`.
  Future<void> deleteOnboardDraft(int id);

  /// GET `/api/v1/hr/onboard/blank-form/?copies=N` — real reportlab-rendered
  /// PDF bytes (a genuine multi-section form, not a placeholder).
  Future<List<int>> downloadBlankForm({int copies = 1});

  /// POST `/api/v1/hr/onboard/filled-form/` — real reportlab-rendered PDF
  /// bytes with the given `formData` mapped onto ~40+ real form fields.
  Future<List<int>> downloadFilledForm(Map<String, dynamic> formData);

  /// POST `/api/v1/hr/onboard/documents/upload/` — multipart, real server-side
  /// size (5MB) and content-type (pdf/jpg/jpeg/png) validation.
  Future<OnboardDocumentEntity> uploadOnboardDocument({required PickedAttachment file, required String docKey, required String docLabel});

  /// GET `/api/v1/hr/onboard/documents/`.
  Future<List<OnboardDocumentEntity>> getOnboardDocuments();

  /// DELETE `/api/v1/hr/onboard/documents/{id}/` — real, ownership-checked,
  /// deletes the file from disk.
  Future<void> deleteOnboardDocument(int id);

  /// GET `/api/v1/hr/onboard/documents/{id}/preview/` — real bytes, streamed
  /// from local disk storage.
  Future<List<int>> previewOnboardDocument(int id);

  /// GET `/api/v1/master/languages/` — real endpoint backed by a fixed
  /// server-side constant list (no migrations, but genuinely live).
  Future<List<MasterOptionEntity>> getMasterLanguages();

  /// GET `/api/v1/master/religions/`.
  Future<List<MasterOptionEntity>> getMasterReligions();

  /// GET `/api/v1/master/countries/`.
  Future<List<MasterOptionEntity>> getMasterCountries();

  /// GET `/api/v1/master/employment-types/`.
  Future<List<MasterOptionEntity>> getMasterEmploymentTypes();

  /// GET `/api/v1/core/pincode-lookup/?pincode=` — real proxy to the Indian
  /// Postal PIN code API.
  Future<PincodeLookupResult> lookupPincode(String pincode);
}

/// A single "Other Documents" entry — mirrors web's `OtherDocumentEntry`.
/// Only [name] is ever actually transmitted to the backend (matching a
/// confirmed real quirk in the web app: selected file bytes are never
/// uploaded for this field, only the filename) — see the "Other Documents"
/// note in the Staff form page's doc comment.
class PickedOtherDocument {
  final String name;
  const PickedOtherDocument(this.name);
}
