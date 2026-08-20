import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/teacher_providers.dart';

// Same amber/brown text color the Admin module uses for its own equivalent
// "N items need your attention" callout (`attention_banner.dart`'s
// `_attentionText`), per explicit request to match it.
const _attentionText = Color(0xFF92400E);

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
          // Text/icon color matches the Admin module's own equivalent
          // callout, per explicit request; background stays plain white.
          chips.add(_chip(icon: Icons.check_box_outlined, label: '1 attendance to mark', color: _attentionText));
        }
        if (me.pendingItems.homeworkToReview > 0) {
          chips.add(_chip(
            icon: Icons.menu_book_outlined,
            label: '${me.pendingItems.homeworkToReview} homework to review',
            color: AppColors.brandPurple,
          ));
        }
        if (chips.isEmpty) return const SizedBox.shrink();
        // Its own card (same style as `TodayScheduleCard`/the Quick Access
        // card) so Attendance reads as a separate section rather than
        // floating chips merging visually into Greeting above or Today's
        // Schedule below.
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg1,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          // `LayoutBuilder` gives the card's real available width, so each
          // chip can be capped to it below — without a real bound to pass
          // to `_chip`, a single long chip (e.g. under large accessibility
          // text scaling) could exceed the screen instead of ellipsizing.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final chip in chips) _sizeCap(chip, constraints.maxWidth)],
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _sizeCap(Widget chip, double maxWidth) {
    return ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: chip);
  }

  Widget _chip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      // Plain white fill, no border — per explicit request.
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
