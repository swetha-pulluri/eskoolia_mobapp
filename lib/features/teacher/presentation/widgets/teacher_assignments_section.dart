import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/teacher_me_entity.dart';
import '../../../dashboard/presentation/widgets/section_label.dart';
import '../providers/teacher_providers.dart';

/// "Your Assignments" — `ClassTeacherCard` + one `SubjectCard` per
/// `subjectAssignments` entry, ported from `home/page.tsx`'s inline
/// components. "Mark Attendance" now routes to the real Teacher Attendance
/// page (`/teacher/attendance`). "View Students" still shows a "Coming
/// Soon" snackbar — My Classes navigation from this card is out of scope
/// for the Attendance submodule (see the Teacher module catalog's
/// `comingSoon` flag, unchanged for that entry).
class TeacherAssignmentsSection extends ConsumerWidget {
  const TeacherAssignmentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(teacherMeProvider);

    return meAsync.maybeWhen(
      data: (me) {
        final hasClassTeacher = me.classTeacherFor != null;
        final totalCount = (hasClassTeacher ? 1 : 0) + me.subjectAssignments.length;
        if (totalCount == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(title: 'YOUR ASSIGNMENTS', count: totalCount),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (hasClassTeacher) _ClassTeacherCard(classRef: me.classTeacherFor!),
                  for (final subject in me.subjectAssignments) _SubjectCard(subject: subject),
                ],
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature — Coming Soon')),
  );
}

class _ClassTeacherCard extends StatelessWidget {
  final TeacherClassRefEntity classRef;
  const _ClassTeacherCard({required this.classRef});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(left: BorderSide(color: AppColors.brandPurple, width: 3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.ink1.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.star_outline, size: 18, color: AppColors.brandPurple),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('CLASS TEACHER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.brandPurple)),
                    const SizedBox(height: 2),
                    Text('${classRef.className} · ${classRef.sectionName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                    Text('${classRef.studentCount} students', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/teacher/attendance'),
                  icon: const Icon(Icons.check_box_outlined, size: 15),
                  label: const Text('Mark Attendance'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPurple,
                    side: const BorderSide(color: AppColors.brandPurple),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showComingSoon(context, 'View Students'),
                  icon: const Icon(Icons.people_outline, size: 15),
                  label: const Text('View Students'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink1,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  final TeacherSubjectAssignmentEntity subject;
  const _SubjectCard({required this.subject});

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(9)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.ink2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(subject.subjectName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                      Text(
                        '${subject.totalSections} section${subject.totalSections == 1 ? '' : 's'} · ${subject.totalStudents} students',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.ink3),
                      ),
                    ],
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.ink3),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            for (final section in subject.sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 42),
                    Expanded(
                      child: Text(
                        '${section.className} · ${section.sectionName}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
                      ),
                    ),
                    Text('${section.studentCount}', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
