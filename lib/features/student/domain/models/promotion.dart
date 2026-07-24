/// Student Promotion — Source: frontend app/(dashboard)/students/promote +
/// PromotePageContainer.tsx & friends. Backend: apps/students —
/// PromotionBatch/PromotionRecord models, PromotionBatchViewSet (fully
/// real, transactional, audit-logged — see views.py `confirm` action, which
/// is where students actually move class/section/academic-year).
class PromotionKpi {
  final int total;
  final int promoted;
  final int notPromoted;
  final int pending;
  final double completionPercentage;

  const PromotionKpi({
    required this.total,
    required this.promoted,
    required this.notPromoted,
    required this.pending,
    required this.completionPercentage,
  });

  factory PromotionKpi.fromJson(Map<String, dynamic> json) {
    return PromotionKpi(
      total: json['total'] as int? ?? 0,
      promoted: json['promoted'] as int? ?? 0,
      notPromoted: json['not_promoted'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PromotionRecord {
  final int id;
  final int studentId;
  final String studentName;
  final String admissionNo;
  final int? fromClassId;
  final String fromClassName;
  final int? fromSectionId;
  final String fromSectionName;
  final int? toClassId;
  final String toClassName;
  final int? toSectionId;
  final String toSectionName;
  final String status; // 'pending' | 'promote' | 'not_promoted'
  final String retentionReason;
  final String notes;
  final String aiRecommendation;

  const PromotionRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    this.fromClassId,
    required this.fromClassName,
    this.fromSectionId,
    required this.fromSectionName,
    this.toClassId,
    required this.toClassName,
    this.toSectionId,
    required this.toSectionName,
    required this.status,
    required this.retentionReason,
    required this.notes,
    required this.aiRecommendation,
  });

  factory PromotionRecord.fromJson(Map<String, dynamic> json) {
    return PromotionRecord(
      id: json['id'] as int,
      studentId: json['student'] as int,
      studentName: (json['student_name'] as String?) ?? '',
      admissionNo: (json['admission_no'] as String?) ?? '',
      fromClassId: json['from_class'] as int?,
      fromClassName: (json['from_class_name'] as String?) ?? '',
      fromSectionId: json['from_section'] as int?,
      fromSectionName: (json['from_section_name'] as String?) ?? '',
      toClassId: json['to_class'] as int?,
      toClassName: (json['to_class_name'] as String?) ?? '',
      toSectionId: json['to_section'] as int?,
      toSectionName: (json['to_section_name'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      retentionReason: (json['retention_reason'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      aiRecommendation: (json['ai_recommendation'] as String?) ?? '',
    );
  }
}

class PromotionBatch {
  final int id;
  final int academicYearId;
  final String academicYearName;
  final int targetYearId;
  final String targetYearName;
  final String status; // 'draft' | 'in_progress' | 'confirmed' | 'finalized'
  final int totalStudents;
  final int promotedCount;
  final int retainedCount;
  final PromotionKpi kpi;
  final List<PromotionRecord> records;

  const PromotionBatch({
    required this.id,
    required this.academicYearId,
    required this.academicYearName,
    required this.targetYearId,
    required this.targetYearName,
    required this.status,
    required this.totalStudents,
    required this.promotedCount,
    required this.retainedCount,
    required this.kpi,
    required this.records,
  });

  factory PromotionBatch.fromJson(Map<String, dynamic> json) {
    final rawRecords = (json['records'] as List<dynamic>?) ?? const [];
    return PromotionBatch(
      id: json['id'] as int,
      academicYearId: json['academic_year'] as int? ?? 0,
      academicYearName: (json['academic_year_name'] as String?) ?? '',
      targetYearId: json['target_year'] as int? ?? 0,
      targetYearName: (json['target_year_name'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'draft',
      totalStudents: json['total_students'] as int? ?? 0,
      promotedCount: json['promoted_count'] as int? ?? 0,
      retainedCount: json['retained_count'] as int? ?? 0,
      kpi: PromotionKpi.fromJson(json['kpi'] as Map<String, dynamic>? ?? const {}),
      records: rawRecords.map((e) => PromotionRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Matches the reference frontend's NotPromotedDialog reason options, which
/// map 1:1 onto the backend's `REASON_CHOICES` (models.py:500-512).
const List<(String value, String label)> promotionRetentionReasons = [
  ('academic', 'Academic performance'),
  ('attendance', 'Attendance'),
  ('medical', 'Medical'),
  ('behavioral', 'Behavioral'),
  ('parent_request', 'Parent request'),
  ('other', 'Other'),
];
