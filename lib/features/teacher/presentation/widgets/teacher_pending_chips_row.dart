import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/teacher_providers.dart';

/// The "N attendance to mark" / "N homework to review" pending-action
/// chips, ported from `(teacher-portal)/teacher/home/page.tsx`'s inline
/// markup (not part of the shared `Greeting`/`GreetingSection`). Matches
/// web's own disclosed, non-real semantics exactly: `attendancePending` is
/// a boolean (rendered as the literal text "1", never a real count) and
/// `homeworkToReview` is always `0` server-side, so that chip never shows
/// in practice — see `TeacherPendingItemsEntity`'s doc comment.
class TeacherPendingChipsRow extends ConsumerWidget {
  const TeacherPendingChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(teacherMeProvider);
    return meAsync.maybeWhen(
      data: (me) {
        final chips = <Widget>[];
        if (me.pendingItems.attendancePending) {
          chips.add(_chip(icon: Icons.check_box_outlined, label: '1 attendance to mark', color: AppColors.warning));
        }
        if (me.pendingItems.homeworkToReview > 0) {
          chips.add(_chip(
            icon: Icons.menu_book_outlined,
            label: '${me.pendingItems.homeworkToReview} homework to review',
            color: AppColors.brandPurple,
          ));
        }
        if (chips.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 8, runSpacing: 8, children: chips),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _chip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
