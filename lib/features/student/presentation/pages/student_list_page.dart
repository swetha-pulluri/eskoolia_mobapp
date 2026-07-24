import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/student_list_notifier.dart';
import '../providers/student_list_state.dart';
import '../providers/student_providers.dart';
import '../widgets/student_class_accordion.dart';
import '../widgets/student_filters_panel.dart';
import '../widgets/student_module_sub_nav.dart';
import '../widgets/student_stats_grid.dart';

/// Student List Page — mirrors frontend
/// components/students/StudentListPanel.tsx: page head (title + Export +
/// Enroll Student), stats grid, smart-filters panel, and the browse-by-class
/// accordion.
class StudentListPage extends ConsumerWidget {
  const StudentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentListNotifierProvider);
    final notifier = ref.read(studentListNotifierProvider.notifier);

    ref.listen<StudentListState>(studentListNotifierProvider, (previous, next) {
      if (next.flashSuccess != null && next.flashSuccess != previous?.flashSuccess) {
        _showSnack(context, next.flashSuccess!, success: true);
        notifier.dismissFlash();
      } else if (next.flashError != null && next.flashError != previous?.flashError) {
        _showSnack(context, next.flashError!, success: false);
        notifier.dismissFlash();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.studentListPageBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              // Mirrors `<ModuleSubNav />`, rendered above the page content
              // by the frontend's dashboard shell for whichever module is
              // active — full-bleed, sitting above the "Student List" card
              // rather than inside its padding.
              const StudentModuleSubNav(active: StudentModuleTab.enrollList),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => notifier.refresh(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildPageHead(context, notifier),
                            const SizedBox(height: 12),
                            StudentStatsGrid(loading: state.loadingStats, stats: state.stats),
                            const SizedBox(height: 12),
                            const StudentFiltersPanel(),
                            const SizedBox(height: 12),
                            const StudentClassAccordion(),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mobile adaptation (disclosed): the frontend cross-links its Students
  /// sub-screens (Categories, Groups, Disabled, Deleted/Restore,
  /// Unassigned, Multi Subject Assignment, Promotion) via breadcrumbs and
  /// buttons scattered across each of those pages rather than one central
  /// menu — there's no single equivalent "hub" in the reference frontend.
  /// A bottom sheet from the List screen's own "More" button is the
  /// natural mobile entry point for the same set of destinations.
  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final items = [
          ('Categories', Icons.category_outlined, '/students/categories'),
          ('Groups & Clubs', Icons.groups_outlined, '/students/groups'),
          ('Disabled Students', Icons.block_outlined, '/students/disabled'),
          ('Delete / Restore Records', Icons.delete_outline, '/students/deleted'),
          ('Unassigned Students', Icons.person_search_outlined, '/students/unassigned'),
          ('Multi Subject Assignment', Icons.menu_book_outlined, '/students/multi-subject-assignment'),
          ('Student Promotion', Icons.trending_up, '/students/promote'),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('More Students tools', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              for (final item in items)
                ListTile(
                  leading: Icon(item.$2, color: AppColors.studentListBrand),
                  title: Text(item.$1, style: const TextStyle(fontSize: 13)),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(item.$3);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPageHead(BuildContext context, StudentListNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.15,
                    color: Color(0xFF0F172A),
                  ),
                  children: [
                    TextSpan(text: 'Student '),
                    TextSpan(
                      text: 'List',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6C3CE1),
                      ),
                    ),
                  ],
                ),
              ),
              // Mirrors `.page-head > div:first-child p` exactly.
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Browse, search, and manage every enrolled student · Click any row to see full profile.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B6A65)),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/students/export'),
                icon: const Icon(Icons.file_download_outlined, size: 14),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.studentListInk,
                  side: const BorderSide(color: Color(0x1F000000)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showMoreMenu(context),
                icon: const Icon(Icons.more_horiz, size: 16),
                label: const Text('More'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.studentListInk,
                  side: const BorderSide(color: Color(0x1F000000)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final enrolled = await context.push<bool>('/students/enroll');
                  if (enrolled == true) {
                    notifier.refresh();
                    if (context.mounted) {
                      _showSnack(context, 'Student enrolled successfully.', success: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.studentListCta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Enroll Student'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
