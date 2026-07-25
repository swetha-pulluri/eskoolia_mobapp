import 'dart:typed_data';
import '../entities/attendance_entities.dart';

abstract class AttendanceRepository {
  Future<List<ClassInfoEntity>> getClasses();
  Future<List<SectionSummaryEntity>> getSectionsForClass(int classId);

  Future<KpiDataEntity> getDailySummary(String date);
  Future<List<ClassSummaryTileEntity>> getClassSummary(String date);

  Future<List<AttendanceStudentEntity>> searchStudents({required int classId, required int sectionId, required String date});

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
  });

  Future<List<MonthlyReportRowEntity>> getMonthlyReport({
    required int classId,
    required int sectionId,
    required int month,
    required int year,
    String? academicYear,
  });

  Future<ReportInsightsEntity> getReportInsights({
    required int month,
    required int year,
    int? classId,
    int? sectionId,
    String? academicYear,
  });

  Future<List<DailyAttendanceRecordEntity>> getRawRecordsForReport({
    required int month,
    required int year,
    int? classId,
    int? sectionId,
    String? academicYear,
  });

  Future<Uint8List> downloadSample();

  Future<Uint8List> exportAttendance({
    String fmt,
    int? classId,
    int? sectionId,
    int? month,
    int? year,
    String? academicYear,
    String? date,
    String? dateFrom,
    String? dateTo,
  });

  Future<List<Map<String, dynamic>>> getImportClasses();

  Future<Map<String, dynamic>> bulkImport({
    required int classId,
    required int sectionId,
    required String attendanceDate,
    required Uint8List fileBytes,
    required String fileName,
  });
}
