import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entities.dart';

/// Section Tabs — converted from web
/// `attendance/student/components/SectionTabs.tsx`.
class SectionTabs extends StatelessWidget {
  final List<SectionSummaryEntity> sections;
  final int activeSection;
  final ValueChanged<int> onChange;
  final Map<String, List<AttendanceStudentEntity>> students;
  final int classId;

  const SectionTabs({super.key, required this.sections, required this.activeSection, required this.onChange, required this.students, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF1F1F5)))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: sections.map((sec) {
            final isActive = sec.id == activeSection;
            final key = '$classId-${sec.id}';
            final sectionStudents = students[key] ?? const [];
            final markedCount = sectionStudents.where((s) => s.status != 'unmarked').length;
            final totalCount = sectionStudents.length;
            final isComplete = totalCount > 0 && markedCount == totalCount;
            final isPartial = totalCount > 0 && markedCount > 0 && markedCount < totalCount;

            Color badgeBg, badgeFg;
            if (isComplete) {
              badgeBg = const Color(0xFFDCFCE7);
              badgeFg = const Color(0xFF15803D);
            } else if (isPartial) {
              badgeBg = const Color(0xFFFEF9C3);
              badgeFg = const Color(0xFFA16207);
            } else if (isActive) {
              badgeBg = const Color(0xFFEEEBFF);
              badgeFg = const Color(0xFF4729F4);
            } else {
              badgeBg = const Color(0xFFF1F1F5);
              badgeFg = const Color(0xFF9CA0AE);
            }

            return InkWell(
              onTap: () => onChange(sec.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF4729F4) : Colors.transparent, width: 2))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Section ${sec.name}', style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? const Color(0xFF4729F4) : const Color(0xFF9CA0AE))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                      child: Text('${sec.studentCount}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: badgeFg)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
