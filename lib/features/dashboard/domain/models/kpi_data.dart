/// KPI (Key Performance Indicator) Data Model
/// Matches frontend API response: /api/v1/dashboard/kpis/
/// Source: frontend/app/(dashboard)/dashboard/page.tsx
class KpiData {
  final int? totalStudents;
  final String? attendanceToday;
  final String? feesCollectedMtd;
  final int? openAdmissions;
  final int? totalStaff;
  final int? libraryBooks;
  final int? pendingHomework;
  final int? examsThisWeek;

  const KpiData({
    this.totalStudents,
    this.attendanceToday,
    this.feesCollectedMtd,
    this.openAdmissions,
    this.totalStaff,
    this.libraryBooks,
    this.pendingHomework,
    this.examsThisWeek,
  });

  /// Factory constructor for JSON deserialization
  factory KpiData.fromJson(Map<String, dynamic> json) {
    return KpiData(
      totalStudents: json['total_students'] as int?,
      attendanceToday: json['attendance_today'] as String?,
      feesCollectedMtd: json['fees_collected_mtd'] as String?,
      openAdmissions: json['open_admissions'] as int?,
      totalStaff: json['total_staff'] as int?,
      libraryBooks: json['library_books'] as int?,
      pendingHomework: json['pending_homework'] as int?,
      examsThisWeek: json['exams_this_week'] as int?,
    );
  }

  /// Convert to JSON (for caching/storage)
  Map<String, dynamic> toJson() {
    return {
      'total_students': totalStudents,
      'attendance_today': attendanceToday,
      'fees_collected_mtd': feesCollectedMtd,
      'open_admissions': openAdmissions,
      'total_staff': totalStaff,
      'library_books': libraryBooks,
      'pending_homework': pendingHomework,
      'exams_this_week': examsThisWeek,
    };
  }

  /// Mock data for development (matches screenshot values)
  factory KpiData.mock() {
    return const KpiData(
      totalStudents: 92,
      attendanceToday: null, // Shows as '—'
      feesCollectedMtd: '₹0',
      openAdmissions: 25,
      totalStaff: 11,
      libraryBooks: 5,
      pendingHomework: 1,
      examsThisWeek: 0,
    );
  }
}
