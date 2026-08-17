import '../../../administration/domain/entities/paginated_result.dart';
import '../../domain/entities/staff_attendance_report_row_entity.dart';
import '../../domain/entities/student_attendance_report_row_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource _remoteDataSource;

  ReportsRepositoryImpl(this._remoteDataSource);

  @override
  Future<PaginatedResult<StudentAttendanceReportRowEntity>> getStudentAttendanceReport({
    required int page,
    int? classId,
    int? sectionId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) {
    return _remoteDataSource.getStudentAttendanceReport(
      page: page,
      classId: classId,
      sectionId: sectionId,
      startDate: startDate,
      endDate: endDate,
      attendanceType: attendanceType,
    );
  }

  @override
  Future<List<int>> exportStudentAttendanceReportCsv({
    int? classId,
    int? sectionId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) {
    return _remoteDataSource.exportStudentAttendanceReportCsv(
      classId: classId,
      sectionId: sectionId,
      startDate: startDate,
      endDate: endDate,
      attendanceType: attendanceType,
    );
  }

  @override
  Future<PaginatedResult<StaffAttendanceReportRowEntity>> getStaffAttendanceReport({
    required int page,
    int? departmentId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) {
    return _remoteDataSource.getStaffAttendanceReport(
      page: page,
      departmentId: departmentId,
      startDate: startDate,
      endDate: endDate,
      attendanceType: attendanceType,
    );
  }

  @override
  Future<List<int>> exportStaffAttendanceReportCsv({
    int? departmentId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) {
    return _remoteDataSource.exportStaffAttendanceReportCsv(
      departmentId: departmentId,
      startDate: startDate,
      endDate: endDate,
      attendanceType: attendanceType,
    );
  }

  @override
  Future<Map<String, dynamic>> getReportPage(String endpoint, {required int page, required Map<String, dynamic> filters}) {
    return _remoteDataSource.getReportPage(endpoint, page: page, filters: filters);
  }

  @override
  Future<List<int>> exportReport(String endpoint, String format, Map<String, dynamic> filters) {
    return _remoteDataSource.exportReport(endpoint, format, filters);
  }

  @override
  Future<List<(int, String)>> getClassOptions() => _remoteDataSource.getClassOptions();

  @override
  Future<List<(int, String)>> getSectionOptions({int? classId}) => _remoteDataSource.getSectionOptions(classId: classId);

  @override
  Future<List<(int, String)>> getStudentOptions({int? classId, int? sectionId}) => _remoteDataSource.getStudentOptions(classId: classId, sectionId: sectionId);

  @override
  Future<List<(int, String)>> getSubjectOptions() => _remoteDataSource.getSubjectOptions();

  @override
  Future<List<(int, String)>> getExamTypeOptions() => _remoteDataSource.getExamTypeOptions();

  @override
  Future<List<(int, String)>> getDepartmentOptions() => _remoteDataSource.getDepartmentOptions();

  @override
  Future<List<(int, String)>> getDesignationOptions({int? departmentId}) => _remoteDataSource.getDesignationOptions(departmentId: departmentId);

  @override
  Future<List<(int, String)>> getStaffOptions({int? departmentId, int? designationId}) => _remoteDataSource.getStaffOptions(departmentId: departmentId, designationId: designationId);

  @override
  Future<List<(int, String)>> getRouteOptions() => _remoteDataSource.getRouteOptions();

  @override
  Future<List<(int, String)>> getVehicleOptions() => _remoteDataSource.getVehicleOptions();

  @override
  Future<List<(int, String)>> getBookOptions() => _remoteDataSource.getBookOptions();

  @override
  Future<List<(int, String)>> getCategoryOptions() => _remoteDataSource.getCategoryOptions();

  @override
  Future<List<(int, String)>> getSupplierOptions() => _remoteDataSource.getSupplierOptions();

  @override
  Future<List<(int, String)>> getIncidentOptions() => _remoteDataSource.getIncidentOptions();
}
