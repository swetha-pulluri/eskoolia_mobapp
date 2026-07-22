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
      ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export is coming soon.')),
                ),
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
