import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/widgets/greeting_section.dart';
import '../../../dashboard/presentation/widgets/module_card.dart';
import '../../../dashboard/presentation/widgets/section_label.dart';
import '../../../widgets_panel/presentation/providers/widget_prefs_provider.dart';
import '../../domain/entities/teacher_module_entity.dart';
import '../providers/teacher_providers.dart';
import '../widgets/quick_broadcast_card.dart';
import '../widgets/smart_todo_card.dart';
import '../widgets/teacher_assignments_section.dart';
import '../widgets/teacher_pending_chips_row.dart';
import '../widgets/today_schedule_card.dart';
import '../widgets/week_ahead_card.dart';

/// Teacher Home Screen — the Teacher Portal's landing page after login
/// (`/teacher/home`, equivalent to web's `(teacher-portal)/teacher/home`).
/// Single-column mobile-first composition, same simplification
/// `AdminHomePage` already makes over web's 3-column desktop grid.
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherMeProvider);
        },
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PortalLoadError(error: error, onRetry: () => ref.invalidate(teacherMeProvider)),
          data: (_) => _TeacherHomeContent(isEnabled: isEnabled),
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
            child: GreetingSection(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: TeacherPendingChipsRow(),
          ),
          const SizedBox(height: 12),
          if (isEnabled('teacher-day-plan')) const TodayScheduleCard(),
          const SizedBox(height: 10),
          SectionLabel(title: 'QUICK ACCESS', count: quickAccessModules.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                for (final module in quickAccessModules)
                  ModuleCardGrid(module: module, onTap: () => context.go(module.path)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const TeacherAssignmentsSection(),
          const SizedBox(height: 10),
          SectionLabel(title: 'ALL MODULES', count: allModules.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: [
                for (final module in allModules)
                  ModuleCardGrid(module: module, onTap: () => context.go(module.path)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (isEnabled('week-ahead')) const WeekAheadCard(),
          if (isEnabled('smart-todo')) const SmartTodoCard(),
          if (isEnabled('broadcast')) const QuickBroadcastCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
