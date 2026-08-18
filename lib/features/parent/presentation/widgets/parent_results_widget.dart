import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/child_detail_entity.dart';

const Color _headerIconBg = Color(0xFFEEEAFF);
const Color _brandPurple = Color(0xFF6D4AFF);
const Color _ok = Color(0xFF0E9F6E);
const Color _warn = Color(0xFFD97706);
const Color _danger = Color(0xFFDC2626);

/// Home screen → "Recent Results" widget — mobile port of web's
/// `ParentResultsWidget.tsx`: the selected child's last 5 exam marks, most
/// recent first.
class ParentResultsWidget extends StatelessWidget {
  final String? childName;
  final ChildDetailEntity? detail;
  final bool loading;

  const ParentResultsWidget({super.key, required this.childName, required this.detail, required this.loading});

  @override
  Widget build(BuildContext context) {
    final marks = (detail?.recentMarks ?? const <ExamMarkEntity>[]);
    final shown = marks.length > 5 ? marks.sublist(marks.length - 5).reversed.toList() : marks.reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PremiumCard(
        radius: 14,
        color: Colors.white,
        borderColor: AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: _headerIconBg, borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu_book_outlined, size: 13, color: _brandPurple),
                  ),
                  const SizedBox(width: 7),
                  const Text('Recent Results', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.showSnackBar('Results - Coming Soon'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('All', style: TextStyle(fontSize: 11.5, color: _brandPurple, fontWeight: FontWeight.w500)),
                        Icon(Icons.chevron_right, size: 13, color: _brandPurple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: _body(shown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(List<ExamMarkEntity> marks) {
    if (loading && detail == null) {
      return const SizedBox(
        height: 60,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (detail == null) {
      return const SizedBox(
        height: 40,
        child: Center(child: Text('No child selected', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
      );
    }
    if (marks.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(child: Text('No exam records yet', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (childName != null) ...[
          Text(
            childName!.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _brandPurple, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < marks.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _MarkRow(mark: marks[i]),
        ],
      ],
    );
  }
}

class _MarkRow extends StatelessWidget {
  final ExamMarkEntity mark;
  const _MarkRow({required this.mark});

  @override
  Widget build(BuildContext context) {
    final pct = mark.fullMarks > 0 ? (mark.obtained / mark.fullMarks * 100).round() : 0;
    final color = pct >= 75 ? _ok : (pct >= 50 ? _warn : _danger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mark.subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink1), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(mark.examName, style: const TextStyle(fontSize: 10.5, color: AppColors.ink3), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              mark.absent ? 'Absent' : '$pct%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        if (!mark.absent) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ],
    );
  }
}
