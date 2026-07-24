/// Multi Subject Assignment — Source: frontend
/// components/students/StudentMultiClassPanel.tsx (route folder named
/// "multi-class", but the actual screen is optional-subject enrollment per
/// student — 2nd/3rd language, sport, art — NOT literal multi-class
/// homeroom membership; see the page's own doc comment). Backend: apps/
/// students — StudentViewSet's `subject-assignment-stats`/
/// `class-section-tree`/`section-students` actions +
/// StudentSubjectAssignmentViewSet's `upsert-optional`.
class SubjectAssignmentStats {
  final int enrolled;
  final int assigned;
  final int partial;
  final int pending;

  const SubjectAssignmentStats({
    required this.enrolled,
    required this.assigned,
    required this.partial,
    required this.pending,
  });

  factory SubjectAssignmentStats.fromJson(Map<String, dynamic> json) {
    return SubjectAssignmentStats(
      enrolled: json['enrolled'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      partial: json['partial'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }
}

class AssignmentStudentRow {
  final int id;
  final String name;
  final String admissionNo;
  final String rollNo;
  final String lang2;
  final String lang3;
  final String sport;
  final String art;
  final String status; // 'done' | 'partial' | 'empty'
  final List<String> optionalSubjects;

  const AssignmentStudentRow({
    required this.id,
    required this.name,
    required this.admissionNo,
    required this.rollNo,
    required this.lang2,
    required this.lang3,
    required this.sport,
    required this.art,
    required this.status,
    this.optionalSubjects = const [],
  });

  factory AssignmentStudentRow.fromJson(Map<String, dynamic> json) {
    final rawOptional = (json['optionalSubjects'] as List<dynamic>?) ?? const [];
    return AssignmentStudentRow(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      admissionNo: (json['admNo'] as String?) ?? '',
      rollNo: (json['rollNo'] as String?) ?? '',
      lang2: (json['lang2'] as String?) ?? '',
      lang3: (json['lang3'] as String?) ?? '',
      sport: (json['sport'] as String?) ?? '',
      art: (json['art'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'empty',
      optionalSubjects: rawOptional.map((e) => e.toString()).toList(),
    );
  }

  AssignmentStudentRow copyWith({
    String? lang2,
    String? lang3,
    String? sport,
    String? art,
    String? status,
    List<String>? optionalSubjects,
  }) {
    return AssignmentStudentRow(
      id: id,
      name: name,
      admissionNo: admissionNo,
      rollNo: rollNo,
      lang2: lang2 ?? this.lang2,
      lang3: lang3 ?? this.lang3,
      sport: sport ?? this.sport,
      art: art ?? this.art,
      status: status ?? this.status,
      optionalSubjects: optionalSubjects ?? this.optionalSubjects,
    );
  }
}

class AssignmentSectionNode {
  final int id;
  final String letter;
  final List<AssignmentStudentRow> students;
  final int studentTotal;
  final int studentPageSize;

  const AssignmentSectionNode({
    required this.id,
    required this.letter,
    required this.students,
    required this.studentTotal,
    this.studentPageSize = 10,
  });

  AssignmentSectionNode copyWithStudents(List<AssignmentStudentRow> students) {
    return AssignmentSectionNode(id: id, letter: letter, students: students, studentTotal: studentTotal, studentPageSize: studentPageSize);
  }

  factory AssignmentSectionNode.fromJson(Map<String, dynamic> json) {
    final rawStudents = (json['students'] as List<dynamic>?) ?? const [];
    return AssignmentSectionNode(
      id: json['id'] as int,
      letter: (json['letter'] as String?) ?? '',
      students: rawStudents.map((e) => AssignmentStudentRow.fromJson(e as Map<String, dynamic>)).toList(),
      studentPageSize: json['student_page_size'] as int? ?? 10,
      studentTotal: json['student_total'] as int? ?? 0,
    );
  }
}

class AssignmentClassNode {
  final int id;
  final String label;
  final List<AssignmentSectionNode> sections;

  const AssignmentClassNode({required this.id, required this.label, required this.sections});

  AssignmentClassNode copyWithSections(List<AssignmentSectionNode> sections) {
    return AssignmentClassNode(id: id, label: label, sections: sections);
  }

  factory AssignmentClassNode.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List<dynamic>?) ?? const [];
    return AssignmentClassNode(
      id: json['id'] as int,
      label: (json['label'] as String?) ?? '',
      sections: rawSections.map((e) => AssignmentSectionNode.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// GET section-students response — a fresh page for one section.
class AssignmentSectionPage {
  final List<AssignmentStudentRow> students;
  final int count;
  final int page;
  final int totalPages;

  const AssignmentSectionPage({
    required this.students,
    required this.count,
    required this.page,
    required this.totalPages,
  });

  factory AssignmentSectionPage.fromJson(Map<String, dynamic> json) {
    final rawStudents = (json['students'] as List<dynamic>?) ?? const [];
    return AssignmentSectionPage(
      students: rawStudents.map((e) => AssignmentStudentRow.fromJson(e as Map<String, dynamic>)).toList(),
      count: json['count'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}
