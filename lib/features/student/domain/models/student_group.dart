/// A House or Club record — Source: frontend
/// app/(dashboard)/student-groups/page.tsx → StudentGroupPage.tsx. Backend:
/// apps/students — StudentGroup model / StudentGroupSerializer.
class StudentGroup {
  final int id;
  final String name;
  final String type; // 'HOUSE' | 'CLUB' | 'CUSTOM'
  final String emoji;
  final String description;
  final String color;
  final String bgColor;
  final int capacity;
  final int studentsCount;

  const StudentGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.capacity,
    required this.studentsCount,
  });

  bool get isHouse => type == 'HOUSE';
  bool get isClub => type == 'CLUB';

  /// Mirrors `splitDescription` — first non-empty line is the slogan, the
  /// rest (joined with a space) is the body.
  ({String slogan, String body}) get splitDescription {
    final lines = description.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return (slogan: '', body: '');
    return (slogan: lines.first, body: lines.skip(1).join(' '));
  }

  factory StudentGroup.fromJson(Map<String, dynamic> json) {
    return StudentGroup(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Untitled Group',
      type: (json['type'] as String?)?.toUpperCase() ?? 'CUSTOM',
      emoji: (json['emoji'] as String?) ?? '📌',
      description: (json['description'] as String?) ?? '',
      color: (json['color'] as String?) ?? '#00b894',
      bgColor: (json['bg_color'] as String?) ?? (json['bgColor'] as String?) ?? '#e6f9f5',
      capacity: json['capacity'] as int? ?? 40,
      studentsCount: json['students_count'] as int? ?? json['studentCount'] as int? ?? 0,
    );
  }
}

/// GET /groups/stats/ response.
class StudentGroupStats {
  final int totalStudents;
  final int assigned;
  final int unassigned;
  final int houseCount;
  final int clubCount;

  const StudentGroupStats({
    required this.totalStudents,
    required this.assigned,
    required this.unassigned,
    required this.houseCount,
    required this.clubCount,
  });

  factory StudentGroupStats.fromJson(Map<String, dynamic> json) {
    return StudentGroupStats(
      totalStudents: json['totalStudents'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      unassigned: json['unassigned'] as int? ?? 0,
      houseCount: json['houseCount'] as int? ?? 0,
      clubCount: json['clubCount'] as int? ?? 0,
    );
  }
}

/// One row of GET /groups/students/ — a student plus their house/club
/// assignments (house is a single FK, clubs are M2M).
class GroupStudentRow {
  final int id;
  final String name;
  final String admissionNo;
  final String className;
  final String sectionName;
  final int classIndex;
  final int? currentGroupId;
  final List<int> clubIds;

  const GroupStudentRow({
    required this.id,
    required this.name,
    required this.admissionNo,
    required this.className,
    required this.sectionName,
    this.classIndex = 99,
    this.currentGroupId,
    this.clubIds = const [],
  });

  GroupStudentRow copyWith({int? currentGroupId, bool clearGroup = false, List<int>? clubIds}) {
    return GroupStudentRow(
      id: id,
      name: name,
      admissionNo: admissionNo,
      className: className,
      sectionName: sectionName,
      classIndex: classIndex,
      currentGroupId: clearGroup ? null : (currentGroupId ?? this.currentGroupId),
      clubIds: clubIds ?? this.clubIds,
    );
  }

  factory GroupStudentRow.fromJson(Map<String, dynamic> json) {
    return GroupStudentRow(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Student',
      admissionNo: (json['admissionNo'] as String?) ?? '-',
      className: (json['class'] as String?) ?? '-',
      sectionName: (json['section'] as String?) ?? '-',
      classIndex: json['classIndex'] as int? ?? 99,
      currentGroupId: json['currentGroupId'] as int?,
      clubIds: (json['clubIds'] as List<dynamic>? ?? const []).map((e) => e as int).toList(),
    );
  }
}

/// One house's share of a Sortwell preview/run — GET sortwell-preview.
class SortwellPreviewItem {
  final int groupId;
  final String groupName;
  final String emoji;
  final String color;
  final String bgColor;
  final int count;

  const SortwellPreviewItem({
    required this.groupId,
    required this.groupName,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.count,
  });

  factory SortwellPreviewItem.fromJson(Map<String, dynamic> json) {
    return SortwellPreviewItem(
      groupId: json['groupId'] as int? ?? 0,
      groupName: (json['groupName'] as String?) ?? '-',
      emoji: (json['emoji'] as String?) ?? '📌',
      color: (json['color'] as String?) ?? '#00b894',
      bgColor: (json['bg_color'] as String?) ?? (json['bgColor'] as String?) ?? '#e6f9f5',
      count: json['count'] as int? ?? 0,
    );
  }
}

/// POST /groups/sortwell/ response.
class SortwellResult {
  final int assigned;
  const SortwellResult({required this.assigned});

  factory SortwellResult.fromJson(Map<String, dynamic> json) {
    return SortwellResult(assigned: json['assigned'] as int? ?? 0);
  }
}
