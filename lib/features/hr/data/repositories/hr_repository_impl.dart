import '../../../administration/domain/entities/paginated_result.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/attendance_daily_summary_entity.dart';
import '../../domain/entities/attendance_import_result_entity.dart';
import '../../domain/entities/attendance_monthly_report_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/department_type_entity.dart';
import '../../domain/entities/designation_entity.dart';
import '../../domain/entities/master_option_entity.dart';
import '../../domain/entities/onboard_document_entity.dart';
import '../../domain/entities/onboard_draft_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_files_draft.dart';
import '../../domain/entities/staff_form_options_entity.dart';
import '../../domain/entities/staff_lite_entity.dart';
import '../../domain/repositories/hr_repository.dart';
import '../datasources/hr_remote_datasource.dart';

class HrRepositoryImpl implements HrRepository {
  final HrRemoteDataSource _remoteDataSource;

  HrRepositoryImpl(this._remoteDataSource);

  @override
  Future<PaginatedResult<DepartmentEntity>> getDepartments({required int page, int pageSize = 10}) {
    return _remoteDataSource.getDepartments(page: page, pageSize: pageSize);
  }

  @override
  Future<PaginatedResult<DepartmentEntity>> getAllDepartments() {
    return _remoteDataSource.getAllDepartments();
  }

  @override
  Future<PaginatedResult<DepartmentEntity>> getHierarchyDepartments({required int page}) {
    return _remoteDataSource.getHierarchyDepartments(page: page);
  }

  @override
  Future<DepartmentEntity> createDepartment(DepartmentEntity draft) {
    return _remoteDataSource.createDepartment(draft);
  }

  @override
  Future<DepartmentEntity> updateDepartment(int id, DepartmentEntity draft) {
    return _remoteDataSource.updateDepartment(id, draft);
  }

  @override
  Future<void> deleteDepartment(int id) {
    return _remoteDataSource.deleteDepartment(id);
  }

  @override
  Future<List<DepartmentTypeEntity>> getDepartmentTypes() {
    return _remoteDataSource.getDepartmentTypes();
  }

  @override
  Future<DepartmentTypeEntity> createDepartmentType(String name) {
    return _remoteDataSource.createDepartmentType(name);
  }

  @override
  Future<PaginatedResult<StaffLiteEntity>> getActiveStaff() {
    return _remoteDataSource.getActiveStaff();
  }

  @override
  Future<PaginatedResult<DesignationEntity>> getDesignations({int? departmentId}) {
    return _remoteDataSource.getDesignations(departmentId: departmentId);
  }

  @override
  Future<DesignationEntity> createDesignation(DesignationEntity draft) {
    return _remoteDataSource.createDesignation(draft);
  }

  @override
  Future<DesignationEntity> updateDesignation(int id, DesignationEntity draft) {
    return _remoteDataSource.updateDesignation(id, draft);
  }

  @override
  Future<void> deleteDesignation(int id) {
    return _remoteDataSource.deleteDesignation(id);
  }

  @override
  Future<PaginatedResult<StaffEntity>> getStaffPage({
    required int page,
    required int pageSize,
    String? search,
    int? roleId,
    int? departmentId,
    int? designationId,
    String? status,
  }) {
    return _remoteDataSource.getStaffPage(
      page: page,
      pageSize: pageSize,
      search: search,
      roleId: roleId,
      departmentId: departmentId,
      designationId: designationId,
      status: status,
    );
  }

  @override
  Future<StaffEntity> getStaffById(int id) {
    return _remoteDataSource.getStaffById(id);
  }

  @override
  Future<StaffEntity> createStaff(StaffEntity draft, {StaffFilesDraft files = const StaffFilesDraft(), List<PickedOtherDocument> otherDocuments = const []}) {
    return _remoteDataSource.createStaff(draft, files: files, otherDocuments: otherDocuments);
  }

  @override
  Future<StaffEntity> updateStaff(int id, StaffEntity draft, {StaffFilesDraft files = const StaffFilesDraft(), List<PickedOtherDocument> otherDocuments = const []}) {
    return _remoteDataSource.updateStaff(id, draft, files: files, otherDocuments: otherDocuments);
  }

  @override
  Future<void> deleteStaff(int id) {
    return _remoteDataSource.deleteStaff(id);
  }

  @override
  Future<void> updateStaffStatus(int id, String status) {
    return _remoteDataSource.updateStaffStatus(id, status);
  }

  @override
  Future<StaffFormOptionsEntity> getStaffFormOptions() {
    return _remoteDataSource.getStaffFormOptions();
  }

  @override
  Future<String> getNextStaffNo() {
    return _remoteDataSource.getNextStaffNo();
  }

  @override
  Future<List<RoleEntity>> getRoles() {
    return _remoteDataSource.getRoles();
  }

  @override
  Future<PaginatedResult<StaffAttendanceEntity>> getAttendanceForDate(String date) {
    return _remoteDataSource.getAttendanceForDate(date);
  }

  @override
  Future<PaginatedResult<StaffAttendanceEntity>> getAllAttendance() {
    return _remoteDataSource.getAllAttendance();
  }

  @override
  Future<int> bulkSaveAttendance(List<StaffAttendanceEntity> rows) {
    return _remoteDataSource.bulkSaveAttendance(rows);
  }

  @override
  Future<AttendanceReportEntity> getAttendanceReport({String? attendanceDate}) {
    return _remoteDataSource.getAttendanceReport(attendanceDate: attendanceDate);
  }

  @override
  Future<AttendanceDailySummaryEntity> getDailySummary({required String date, int? departmentId}) {
    return _remoteDataSource.getDailySummary(date: date, departmentId: departmentId);
  }

  @override
  Future<AttendanceMonthlyReportEntity> getMonthlyReport({required int month, required int year, int? departmentId, int? staffId}) {
    return _remoteDataSource.getMonthlyReport(month: month, year: year, departmentId: departmentId, staffId: staffId);
  }

  @override
  Future<List<int>> downloadSampleAttendance() {
    return _remoteDataSource.downloadSampleAttendance();
  }

  @override
  Future<List<int>> exportAttendance({String? date, String? department, String? attendanceType, String fmt = 'xlsx'}) {
    return _remoteDataSource.exportAttendance(date: date, department: department, attendanceType: attendanceType, fmt: fmt);
  }

  @override
  Future<AttendanceImportResultEntity> importAttendance({required String attendanceDate, required PickedAttachment file}) {
    return _remoteDataSource.importAttendance(attendanceDate: attendanceDate, file: file);
  }

  @override
  Future<List<OnboardDraftEntity>> getOnboardDrafts() {
    return _remoteDataSource.getOnboardDrafts();
  }

  @override
  Future<OnboardDraftEntity> saveOnboardDraft({int? id, required Map<String, dynamic> formData, required int currentStep}) {
    return _remoteDataSource.saveOnboardDraft(id: id, formData: formData, currentStep: currentStep);
  }

  @override
  Future<void> deleteOnboardDraft(int id) {
    return _remoteDataSource.deleteOnboardDraft(id);
  }

  @override
  Future<List<int>> downloadBlankForm({int copies = 1}) {
    return _remoteDataSource.downloadBlankForm(copies: copies);
  }

  @override
  Future<List<int>> downloadFilledForm(Map<String, dynamic> formData) {
    return _remoteDataSource.downloadFilledForm(formData);
  }

  @override
  Future<OnboardDocumentEntity> uploadOnboardDocument({required PickedAttachment file, required String docKey, required String docLabel}) {
    return _remoteDataSource.uploadOnboardDocument(file: file, docKey: docKey, docLabel: docLabel);
  }

  @override
  Future<List<OnboardDocumentEntity>> getOnboardDocuments() {
    return _remoteDataSource.getOnboardDocuments();
  }

  @override
  Future<void> deleteOnboardDocument(int id) {
    return _remoteDataSource.deleteOnboardDocument(id);
  }

  @override
  Future<List<int>> previewOnboardDocument(int id) {
    return _remoteDataSource.previewOnboardDocument(id);
  }

  @override
  Future<List<MasterOptionEntity>> getMasterLanguages() {
    return _remoteDataSource.getMasterLanguages();
  }

  @override
  Future<List<MasterOptionEntity>> getMasterReligions() {
    return _remoteDataSource.getMasterReligions();
  }

  @override
  Future<List<MasterOptionEntity>> getMasterCountries() {
    return _remoteDataSource.getMasterCountries();
  }

  @override
  Future<List<MasterOptionEntity>> getMasterEmploymentTypes() {
    return _remoteDataSource.getMasterEmploymentTypes();
  }

  @override
  Future<PincodeLookupResult> lookupPincode(String pincode) {
    return _remoteDataSource.lookupPincode(pincode);
  }
}
