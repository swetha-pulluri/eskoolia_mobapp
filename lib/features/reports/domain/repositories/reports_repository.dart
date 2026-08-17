import '../../../administration/domain/entities/paginated_result.dart';
import '../entities/staff_attendance_report_row_entity.dart';
import '../entities/student_attendance_report_row_entity.dart';

abstract class ReportsRepository {
  /// `GET /api/v1/reports/students/attendance/`.
  Future<PaginatedResult<StudentAttendanceReportRowEntity>> getStudentAttendanceReport({
    required int page,
    int? classId,
    int? sectionId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  });

  /// `GET /api/v1/reports/students/attendance/?export=csv&...`.
  Future<List<int>> exportStudentAttendanceReportCsv({
    int? classId,
    int? sectionId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  });

  /// `GET /api/v1/reports/hr/staff-attendance/`.
  Future<PaginatedResult<StaffAttendanceReportRowEntity>> getStaffAttendanceReport({
    required int page,
    int? departmentId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  });

  /// `GET /api/v1/reports/hr/staff-attendance/?export=csv&...`.
  Future<List<int>> exportStaffAttendanceReportCsv({
    int? departmentId,
    String? startDate,
    String? endDate,
    String? attendanceType,
  });

  // ── Generic Report Explorer engine ──────────────────────────────────────

  Future<Map<String, dynamic>> getReportPage(String endpoint, {required int page, required Map<String, dynamic> filters});
  Future<List<int>> exportReport(String endpoint, String format, Map<String, dynamic> filters);
  Future<List<(int, String)>> getClassOptions();
  Future<List<(int, String)>> getSectionOptions({int? classId});
  Future<List<(int, String)>> getStudentOptions({int? classId, int? sectionId});
  Future<List<(int, String)>> getSubjectOptions();
  Future<List<(int, String)>> getExamTypeOptions();
  Future<List<(int, String)>> getDepartmentOptions();
  Future<List<(int, String)>> getDesignationOptions({int? departmentId});
  Future<List<(int, String)>> getStaffOptions({int? departmentId, int? designationId});
  Future<List<(int, String)>> getRouteOptions();
  Future<List<(int, String)>> getVehicleOptions();
  Future<List<(int, String)>> getBookOptions();
  Future<List<(int, String)>> getCategoryOptions();
  Future<List<(int, String)>> getSupplierOptions();
  Future<List<(int, String)>> getIncidentOptions();
}
