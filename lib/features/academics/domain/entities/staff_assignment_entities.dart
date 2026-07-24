// Staff Assignment — Source: components/academics/StaffAssignmentPanels.tsx.
// Backend: apps/academics — Staff*View ViewSets under /api/v1/academics/staff/.

import 'package:flutter/material.dart';

class StaffTeacher {
  final int id;
  final int staffId;
  final String staffNo;
  final String fullName;
  final String designation;
  final String department;
  final int? periodsPerWeek;

  const StaffTeacher({
    required this.id,
    required this.staffId,
    required this.staffNo,
    required this.fullName,
    required this.designation,
    required this.department,
    this.periodsPerWeek,
  });

  factory StaffTeacher.fromJson(Map<String, dynamic> json) {
    return StaffTeacher(
      id: json['id'] as int,
      staffId: json['staff_id'] as int? ?? 0,
      staffNo: (json['staff_no'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      designation: (json['designation'] as String?) ?? '',
      department: (json['department'] as String?) ?? '',
      periodsPerWeek: json['periods_per_week'] as int?,
    );
  }
}

class CTAssignment {
  final int id;
  final int sectionId;
  final String sectionName;
  final int classId;
  final String className;
  final int teacherId;
  final String teacherName;
  final int? academicYearId;
  final bool isLocked;

  const CTAssignment({
    required this.id,
    required this.sectionId,
    required this.sectionName,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    this.academicYearId,
    this.isLocked = false,
  });

  factory CTAssignment.fromJson(Map<String, dynamic> json) {
    return CTAssignment(
      id: json['id'] as int,
      sectionId: json['section_id'] as int? ?? 0,
      sectionName: (json['section_name'] as String?) ?? '',
      classId: json['class_id'] as int? ?? 0,
      className: (json['class_name'] as String?) ?? '',
      teacherId: json['teacher_id'] as int? ?? 0,
      teacherName: (json['teacher_name'] as String?) ?? '',
      academicYearId: json['academic_year_id'] as int?,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }
}

/// Subject assignment row from /staff/subject-assignments/.
/// `sectionId` is null for a class-level (Foundation) assignment.
class StaffSubjectRow {
  final int id;
  final int classId;
  final int? sectionId;
  final int subjectId;
  final String subjectName;
  final int? teacherId;
  final String teacherName;
  final int? academicYearId;
  final bool isOptional;

  const StaffSubjectRow({
    required this.id,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    this.academicYearId,
    this.isOptional = false,
  });

  factory StaffSubjectRow.fromJson(Map<String, dynamic> json) {
    return StaffSubjectRow(
      id: json['id'] as int,
      classId: json['class_id'] as int? ?? 0,
      sectionId: json['section_id'] as int?,
      subjectId: json['subject_id'] as int? ?? 0,
      subjectName: (json['subject_name'] as String?) ?? '',
      teacherId: json['teacher_id'] as int?,
      teacherName: (json['teacher_name'] as String?) ?? '',
      academicYearId: json['academic_year_id'] as int?,
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }
}

class StaffKpi {
  final int totalTeachers;
  final int ctAssigned;
  final double avgLoad;
  final int overloaded;

  const StaffKpi({required this.totalTeachers, required this.ctAssigned, required this.avgLoad, required this.overloaded});

  factory StaffKpi.fromJson(Map<String, dynamic> json) {
    return StaffKpi(
      totalTeachers: json['total_teachers'] as int? ?? 0,
      ctAssigned: json['ct_assigned'] as int? ?? 0,
      avgLoad: (json['avg_load'] as num?)?.toDouble() ?? 0,
      overloaded: json['overloaded'] as int? ?? 0,
    );
  }
}

class StaffAuditLogEntry {
  final int id;
  final String sectionName;
  final String className;
  final String oldTeacherName;
  final String newTeacherName;
  final String reason;
  final String changedByName;
  final String changedAt;

  const StaffAuditLogEntry({
    required this.id,
    required this.sectionName,
    required this.className,
    required this.oldTeacherName,
    required this.newTeacherName,
    required this.reason,
    required this.changedByName,
    required this.changedAt,
  });

  factory StaffAuditLogEntry.fromJson(Map<String, dynamic> json) {
    return StaffAuditLogEntry(
      id: json['id'] as int,
      sectionName: (json['section_name'] as String?) ?? '',
      className: (json['class_name'] as String?) ?? '',
      oldTeacherName: (json['old_teacher_name'] as String?) ?? '',
      newTeacherName: (json['new_teacher_name'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      changedByName: (json['changed_by_name'] as String?) ?? '',
      changedAt: (json['changed_at'] as String?) ?? '',
    );
  }
}

class StaffWorkloadEntry {
  final int teacherId;
  final String teacherName;
  final int periodsPerWeek;
  final int maxPeriods;
  final int subjectsCount;
  final int sectionsCount;
  final double loadPct;
  final bool isOverloaded;
  final String status; // "normal" | "near-limit" | "overloaded"

  const StaffWorkloadEntry({
    required this.teacherId,
    required this.teacherName,
    required this.periodsPerWeek,
    required this.maxPeriods,
    required this.subjectsCount,
    required this.sectionsCount,
    required this.loadPct,
    required this.isOverloaded,
    required this.status,
  });

  factory StaffWorkloadEntry.fromJson(Map<String, dynamic> json) {
    return StaffWorkloadEntry(
      teacherId: json['teacher_id'] as int,
      teacherName: (json['teacher_name'] as String?) ?? '',
      periodsPerWeek: json['periods_per_week'] as int? ?? 0,
      maxPeriods: json['max_periods'] as int? ?? 28,
      subjectsCount: json['subjects_count'] as int? ?? 0,
      sectionsCount: json['sections_count'] as int? ?? 0,
      loadPct: (json['load_pct'] as num?)?.toDouble() ?? 0,
      isOverloaded: json['is_overloaded'] as bool? ?? false,
      status: (json['status'] as String?) ?? 'normal',
    );
  }
}

/// Mirrors StaffAssignmentPanels.tsx's `CLASS_LEVEL_MAP`.
const Map<String, List<String>> staffClassLevelMap = {
  'Pre-Primary': ['Nursery', 'LKG', 'UKG'],
  'Primary': ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'],
  'Middle': ['Grade 6', 'Grade 7', 'Grade 8'],
  'Secondary': ['Grade 9', 'Grade 10'],
  'Senior Secondary': ['Grade 11', 'Grade 12'],
};

String staffClassLevel(String name) {
  for (final entry in staffClassLevelMap.entries) {
    if (entry.value.contains(name)) return entry.key;
  }
  return 'Other';
}

/// Mirrors `CLASS_BADGE_COLORS` (Tailwind bg-*-100 text-*-800 pairs).
const List<(Color bg, Color fg)> staffClassBadgeColors = [
  (Color(0xFFD1FAE5), Color(0xFF065F46)), // emerald
  (Color(0xFFFEF3C7), Color(0xFF92400E)), // amber
  (Color(0xFFDBEAFE), Color(0xFF1E40AF)), // blue
  (Color(0xFFEDE9FE), Color(0xFF5B21B6)), // purple
  (Color(0xFFFFE4E6), Color(0xFF9F1239)), // rose
  (Color(0xFFCCFBF1), Color(0xFF115E59)), // teal
  (Color(0xFFE0E7FF), Color(0xFF3730A3)), // indigo
  (Color(0xFFFFEDD5), Color(0xFF9A3412)), // orange
  (Color(0xFFCFFAFE), Color(0xFF155E75)), // cyan
  (Color(0xFFFCE7F3), Color(0xFF9D174D)), // pink
  (Color(0xFFECFCCB), Color(0xFF3F6212)), // lime
  (Color(0xFFFAE8FF), Color(0xFF86198F)), // fuchsia
];

/// Global CSS custom-property tokens (app/globals.css) used throughout this
/// module — distinct from Foundation's own hardcoded #5B4FCF brand purple,
/// except for the page title's italic "Assignment" word, which the reference
/// hardcodes to #5B4FCF directly rather than using var(--brand).
const Color staffBrand = Color(0xFF6D4AFF); // var(--brand)
const Color staffBrandStrong = Color(0xFF4F35CC); // var(--strong) — hover
const Color staffBrandSoft = Color(0xFFEEEAFF); // var(--soft)
const Color staffLine = Color(0xFFDBE4F0); // var(--line)
const Color staffTitleAssignmentPurple = Color(0xFF5B4FCF); // hardcoded in the title only

/// Mirrors `SUBJECT_PILL_COLORS` (bg-*-100 text-*-800 border-*-200 triples).
const List<(Color bg, Color fg, Color border)> staffSubjectPillColors = [
  (Color(0xFFCFFAFE), Color(0xFF155E75), Color(0xFFA5F3FC)), // cyan
  (Color(0xFFDCFCE7), Color(0xFF166534), Color(0xFFBBF7D0)), // green
  (Color(0xFFFFE4E6), Color(0xFF9F1239), Color(0xFFFECDD3)), // rose
  (Color(0xFFEDE9FE), Color(0xFF5B21B6), Color(0xFFDDD6FE)), // purple
  (Color(0xFFFFEDD5), Color(0xFF9A3412), Color(0xFFFED7AA)), // orange
  (Color(0xFFDBEAFE), Color(0xFF1E40AF), Color(0xFFBFDBFE)), // blue
  (Color(0xFFFEF9C3), Color(0xFF854D0E), Color(0xFFFEF08A)), // yellow
  (Color(0xFFE0E7FF), Color(0xFF3730A3), Color(0xFFC7D2FE)), // indigo
  (Color(0xFFFCE7F3), Color(0xFF9D174D), Color(0xFFFBCFE8)), // pink
  (Color(0xFFCCFBF1), Color(0xFF115E59), Color(0xFF99F6E4)), // teal
  (Color(0xFFECFCCB), Color(0xFF3F6212), Color(0xFFD9F99D)), // lime
  (Color(0xFFFAE8FF), Color(0xFF86198F), Color(0xFFF5D0FE)), // fuchsia
];
