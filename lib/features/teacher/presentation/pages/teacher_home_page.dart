import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/widgets/greeting_section.dart';
import '../../../dashboard/presentation/widgets/section_label.dart';
import '../../../widgets_panel/presentation/providers/widget_prefs_provider.dart';
import '../../domain/entities/teacher_module_entity.dart';
import '../providers/teacher_providers.dart';
import '../widgets/quick_broadcast_card.dart';
import '../widgets/smart_todo_card.dart';
import '../widgets/teacher_assignments_section.dart';
import '../widgets/teacher_pending_chips_row.dart';
import '../widgets/teacher_quick_access_tile.dart';
import '../widgets/today_schedule_card.dart';
import '../widgets/week_ahead_card.dart';
import 'lkg_teacher_home_content.dart';

/// Class name an LKG homeroom teacher's `class_teacher_for` carries —
/// backend-normalized (`backend/apps/core/models.py`'s fixed `class_names`
/// list), so an exact match here is safe and never a guess from
/// username/password or a hardcoded per-teacher condition.
const _lkgClassName = 'LKG';

/// Teacher Home Screen — the Teacher Portal's landing page after login
/// (`/teacher/home`, equivalent to web's `(teacher-portal)/teacher/home`).
/// Single-column mobile-first composition, same simplification
/// `AdminHomePage` already makes over web's 3-column desktop grid.
///
/// No separate route/portal_type exists for an LKG teacher — role routing
/// (`portal_routes.dart`) only resolves as far as `/teacher/home` for every
/// teacher. Once here, this page decides between the generic
/// [_TeacherHomeContent] and [LkgTeacherHomeContent] using
/// `teacherMeProvider`'s already-fetched `class_teacher_for.class_name`
/// (`GET /api/v1/teacher/me/`) — real, authenticated backend data, not a
/// username/password check or a hardcoded per-teacher condition.
class TeacherHomePage extends ConsumerWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `ref.watch` (not `.notifier` alone) so this page rebuilds when a
    // widget preference is toggled in the settings panel; the map itself
    // is read through `notifier.isEnabled` below for its existing
    // per-widget default-value fallback logic.
    ref.watch(widgetPrefsProvider);
    final notifier = ref.read(widgetPrefsProvider.notifier);
    bool isEnabled(String id) => notifier.isEnabled(id);

    // Mirrors web's `home/page.tsx`, which gates its ENTIRE center column
    // (greeting through All Modules) on `fetchTeacherMe()` succeeding and
    // shows a full "Could not load your portal" card on failure — rather
    // than letting each section fail independently and silently disappear.
    final meAsync = ref.watch(teacherMeProvider);

    return Scaffold(
      // Pure white, overriding the app-wide theme's `scaffoldBackgroundColor`
      // (a very light grey, shared with Admin) — scoped to just this page
      // rather than touching the shared theme.
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherMeProvider);
        },
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PortalLoadError(error: error, onRetry: () => ref.invalidate(teacherMeProvider)),
          data: (teacherMe) => teacherMe.classTeacherFor?.className == _lkgClassName
              ? LkgTeacherHomeContent(teacherMe: teacherMe, isEnabled: isEnabled)
              : _TeacherHomeContent(isEnabled: isEnabled),
        ),
      ),
    );
  }
}

class _PortalLoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _PortalLoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 32, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text('Could not load your portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                  const SizedBox(height: 6),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherHomeContent extends StatelessWidget {
  final bool Function(String id) isEnabled;
  const _TeacherHomeContent({required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final quickAccessModules = TeacherModules.all.where((m) => m.id != 'teacher-home').toList();
    // "All Modules" — the teacher portal's own module list shown in full,
    // matching web's `getModulesForUser()` base-list behavior (a teacher's
    // own nav is never permission-gated, unlike admin's). Web additionally
    // layers in any admin modules explicitly granted to this teacher via
    // Roles & Permissions ("extra admin-granted modules") — that layer is
    // not yet ported here, since Flutter's `ModuleEntity`/admin `Modules.all`
    // carry no `permission` metadata to resolve it against; disclosed here
    // rather than silently omitted.
    final allModules = quickAccessModules;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 0),
            child: GreetingSection(borderColor: AppColors.border, nameColor: AppColors.financeIc),
          ),
          const TeacherPendingChipsRow(),
          if (isEnabled('teacher-day-plan')) const TodayScheduleCard(),
          // Quick Access — ONE outer card wrapping the heading + grid,
          // instead of a bare section label floating over bare tiles, so it
          // reads as a distinct section like Greeting/Attendance/Today's
          // Schedule above. No horizontal padding on the card itself: the
          // heading and grid already carry their own 16px horizontal insets
          // (via `SectionLabel` and the `Padding` below), so adding a second
          // 16px here would just double it up.
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
          const TeacherAssignmentsSection(),
          // Same single-outer-card treatment as Quick Access, so the whole
          // Home screen reads as a consistent stack of cards rather than
          // Quick Access being the only carded module grid.
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
