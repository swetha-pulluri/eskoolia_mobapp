import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/widgets/greeting_section.dart';
import '../../../dashboard/presentation/widgets/section_label.dart';
import '../../domain/entities/teacher_me_entity.dart';
import '../../domain/entities/teacher_module_entity.dart';
import '../widgets/quick_broadcast_card.dart';
import '../widgets/smart_todo_card.dart';
import '../widgets/teacher_assignments_section.dart';
import '../widgets/teacher_pending_chips_row.dart';
import '../widgets/teacher_quick_access_tile.dart';
import '../widgets/today_schedule_card.dart';
import '../widgets/week_ahead_card.dart';

/// LKG Teacher Home — shown instead of the generic [_TeacherHomeContent]
/// (in `teacher_home_page.dart`) when the authenticated teacher's own
/// `class_teacher_for.class_name` (from `GET /api/v1/teacher/me/`, already
/// fetched by `teacherMeProvider`) is exactly `"LKG"`. This is a
/// reorganization, not a reduction: every widget and module a regular
/// teacher sees is still here — nothing hidden — only reordered so the
/// class-teacher card (attendance + students, the two things an LKG
/// homeroom teacher needs first) appears immediately after the greeting,
/// ahead of the module grids, instead of below them.
///
/// No web precedent exists for this screen (confirmed by inspection — the
/// web Teacher Portal has one generic home page for every class), so this
/// composition reuses the app's own existing teacher-portal widgets/design
/// system rather than porting a web layout that doesn't exist.
class LkgTeacherHomeContent extends StatelessWidget {
  final TeacherMeEntity teacherMe;
  final bool Function(String id) isEnabled;

  const LkgTeacherHomeContent({super.key, required this.teacherMe, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final quickAccessModules = TeacherModules.all.where((m) => m.id != 'teacher-home').toList();
    final allModules = quickAccessModules;
    final classRef = teacherMe.classTeacherFor;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GreetingSection(borderColor: AppColors.border, nameColor: AppColors.financeIc),
          if (classRef != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _LkgBadge(classRef: classRef),
            ),
          const SizedBox(height: 8),
          const TeacherPendingChipsRow(),
          // Class-teacher card foregrounded — an LKG homeroom teacher's
          // most-used actions (Mark Attendance, View Students) come first.
          const TeacherAssignmentsSection(),
          const SizedBox(height: 4),
          if (isEnabled('teacher-day-plan')) const TodayScheduleCard(),
          // Quick Access — ONE outer card wrapping the heading + grid, same
          // treatment as the generic Teacher Home for visual consistency
          // between the two variants. No horizontal padding on the card
          // itself: the heading/grid already carry their own 16px insets.
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(title: 'QUICK ACCESS', count: quickAccessModules.length),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TeacherModuleWrapGrid(
                    modules: quickAccessModules,
                    iconAssetFor: quickAccessIconAssetFor,
                    onModuleTap: (module) => context.go(module.path),
                  ),
                ),
              ],
            ),
          ),
          // Same single-outer-card treatment as Quick Access above.
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(title: 'ALL MODULES', count: allModules.length),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TeacherModuleWrapGrid(
                    modules: allModules,
                    iconAssetFor: quickAccessIconAssetFor,
                    onModuleTap: (module) => context.go(module.path),
                  ),
                ),
              ],
            ),
          ),
          if (isEnabled('week-ahead')) const WeekAheadCard(),
          if (isEnabled('smart-todo')) const SmartTodoCard(),
          if (isEnabled('broadcast')) const QuickBroadcastCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LkgBadge extends StatelessWidget {
  final TeacherClassRefEntity classRef;
  const _LkgBadge({required this.classRef});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.purpleSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.child_care, size: 14, color: AppColors.brandPurple),
          const SizedBox(width: 6),
          Text(
            '${classRef.className} · ${classRef.sectionName} Homeroom',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandPurple),
          ),
        ],
      ),
    );
  }
}
