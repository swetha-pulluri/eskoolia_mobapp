import 'dart:typed_data';
import '../../domain/entities/attendance_entities.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _remote;
  AttendanceRepositoryImpl(this._remote);

  @override
  Future<List<ClassInfoEntity>> getClasses() => _remote.getClasses();

  @override
  Future<List<SectionSummaryEntity>> getSectionsForClass(int classId) => _remote.getSectionsForClass(classId);

  @override
  Future<KpiDataEntity> getDailySummary(String date) => _remote.getDailySummary(date);

  @override
  Future<List<ClassSummaryTileEntity>> getClassSummary(String date) => _remote.getClassSummary(date);

  @override
  Future<List<AttendanceStudentEntity>> searchStudents({required int classId, required int sectionId, required String date}) {
    return _remote.searchStudents(classId: classId, sectionId: sectionId, date: date);
  }

  @override
  Future<void> storeAttendance({
    required String date,
    required int classId,
    required int sectionId,
    int? academicYearId,
    required List<int> ids,
    required Map<int, String> attendance,
    Map<int, String>? note,
    Map<int, String>? arrivalTime,
    Map<int, String>? signInTime,
    Map<int, String>? signOutTime,
    Map<int, String>? pickupTime,
    Map<int, String>? pickupBy,
    Map<int, bool>? lunch,
    bool lockAttendance = false,
  }) {
    return _remote.storeAttendance(
      date: date,
      classId: classId,
      sectionId: sectionId,
      academicYearId: academicYearId,
      ids: ids,
      attendance: attendance,
      note: note,
      arrivalTime: arrivalTime,
      signInTime: signInTime,
      signOutTime: signOutTime,
      pickupTime: pickupTime,
      pickupBy: pickupBy,
      lunch: lunch,
      lockAttendance: lockAttendance,
    );
  }

  @override
  Future<List<MonthlyReportRowEntity>> getMonthlyReport({
    required int classId,
    required int sectionId,
    required int month,
    required int year,
    String? academicYear,
  }) {
    return _remote.getMonthlyReport(classId: classId, sectionId: sectionId, month: month, year: year, academicYear: academicYear);
  }

  @override
  Future<ReportInsightsEntity> getReportInsights({
    required int month,
    required int year,
    int? classId,
    int? sectionId,
    String? academicYear,
  }) {
    return _remote.getReportInsights(month: month, year: year, classId: classId, sectionId: sectionId, academicYear: academicYear);
  }

  @override
  Future<List<DailyAttendanceRecordEntity>> getRawRecordsForReport({
    required int month,
    required int year,
    int? classId,
    int? sectionId,
    String? academicYear,
  }) {
    return _remote.getRawRecordsForReport(month: month, year: year, classId: classId, sectionId: sectionId, academicYear: academicYear);
  }

  @override
  Future<Uint8List> downloadSample() => _remote.downloadSample();

  @override
  Future<Uint8List> exportAttendance({
    String fmt = 'xlsx',
    int? classId,
    int? sectionId,
    int? month,
    int? year,
    String? academicYear,
    String? date,
    String? dateFrom,
    String? dateTo,
  }) {
    return _remote.exportAttendance(
      fmt: fmt,
      classId: classId,
      sectionId: sectionId,
      month: month,
      year: year,
      academicYear: academicYear,
      date: date,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getImportClasses() => _remote.getImportClasses();

  @override
  Future<Map<String, dynamic>> bulkImport({
    required int classId,
    required int sectionId,
    required String attendanceDate,
    required Uint8List fileBytes,
    required String fileName,
  }) {
    return _remote.bulkImport(classId: classId, sectionId: sectionId, attendanceDate: attendanceDate, fileBytes: fileBytes, fileName: fileName);
  }
}
