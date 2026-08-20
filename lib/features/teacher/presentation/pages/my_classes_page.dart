import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/my_class_entity.dart';
import '../providers/my_classes_providers.dart';
import '../widgets/my_classes/class_tab_pill.dart';
import '../widgets/my_classes/load_error_card.dart';
import '../widgets/my_classes/student_roster.dart';

/// Class Overview — mirrors `(teacher-portal)/teacher/classes/page.tsx`.
/// The dead "Student Profiles" sub-nav tab on web (no page exists behind
/// it — see `MyClassEntity`'s module entry) is aliased to this same route
/// in `app_router.dart` rather than left as a broken destination.
class MyClassesPage extends ConsumerWidget {
  const MyClassesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(myClassesProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myClassesProvider);
            ref.invalidate(studentsForActiveClassProvider);
          },
          child: classesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _errorPage(ref, error),
            data: (classes) => classes.isEmpty ? _emptyPage() : _content(context, ref, classes),
          ),
        ),
      ),
    );
  }

  Widget _pageHeader() {
    // Now its own card — same white/bordered/shadowed style already used
    // by the roster card below — instead of floating text directly on the
    // page background, per explicit request.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.ink1.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TEACHER PORTAL · MY CLASSES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.ink2),
            ),
            const SizedBox(height: 6),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink1),
                children: [
                  TextSpan(text: 'My '),
                  TextSpan(text: 'Classes', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.brandPurple)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('Select a class tab to view the student roster.', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }

  Widget _errorPage(WidgetRef ref, Object error) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: LoadErrorCard(
              title: 'Could not load classes',
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(myClassesProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyPage() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 36, color: AppColors.ink2.withValues(alpha: 0.35)),
                  const SizedBox(height: 12),
                  const Text('No classes assigned yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                  const SizedBox(height: 6),
                  const Text(
                    'Ask your administrator to assign you to a class or subject.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.ink2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, List<MyClassEntity> classes) {
    final activeIndex = ref.watch(activeClassIndexProvider).clamp(0, classes.length - 1);
    final activeClass = classes[activeIndex];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < classes.length; i++)
                  ClassTabPill(
                    cls: classes[i],
                    index: i,
                    isActive: i == activeIndex,
                    onTap: () => ref.read(activeClassIndexProvider.notifier).state = i,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.ink1.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _activeClassHeader(activeClass),
                  const SizedBox(height: 16),
                  StudentRoster(
                    key: ValueKey(activeIndex),
                    onSelectStudent: (id) => context.push('/teacher/classes/students/$id'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _activeClassHeader(MyClassEntity cls) {
    // LayoutBuilder gives the subjects line below a real maxWidth to
    // truncate against — inside a bare Wrap, children get unbounded
    // constraints, so a long subject list overflowed instead of wrapping.
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink1),
                    children: [
                      TextSpan(text: '${cls.className} — '),
                      TextSpan(
                        text: 'Section ${cls.sectionName}',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: AppColors.brandPurple),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (cls.isClassTeacher)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('★ Class Teacher', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      ),
                    if (cls.subjects.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_outlined, size: 11, color: AppColors.ink2),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                cls.subjects.join(' · '),
                                style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 13, color: AppColors.ink2),
                const SizedBox(width: 6),
                Text('${cls.studentCount} student${cls.studentCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink1)),
              ],
            ),
          ),
        ],
      );
    });
  }
}
