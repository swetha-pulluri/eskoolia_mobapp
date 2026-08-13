import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/student_profile_entity.dart';

/// Mirrors `BehaviourTab` in `StudentProfileDrawer.tsx`.
class BehaviourTab extends StatelessWidget {
  final List<BehaviourRecordEntity>? records;
  final int? totalPoints;
  const BehaviourTab({super.key, required this.records, required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    final rows = records ?? const [];
    final points = totalPoints ?? 0;
    final pointColor = points > 0 ? const Color(0xFF15803D) : (points < 0 ? const Color(0xFFB91C1C) : AppColors.ink2);
    final contextLine = rows.isEmpty ? 'No behaviour records yet' : (points > 0 ? 'Positive behaviour overall' : (points < 0 ? 'Needs improvement' : ''));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BEHAVIOUR SCORE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.ink2, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(points > 0 ? '+$points' : '$points', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: pointColor)),
                  ],
                ),
              ),
              if (contextLine.isNotEmpty)
                Expanded(
                  child: Text(contextLine, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No behaviour records found.', style: TextStyle(fontSize: 12, color: AppColors.ink2))),
          )
        else
          for (final r in rows) _incidentCard(r),
      ],
    );
  }

  Widget _incidentCard(BehaviourRecordEntity r) {
    final positive = r.point >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: positive ? const Color(0xFF22C55E) : const Color(0xFFEF4444), width: 3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(r.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1))),
              Text(
                positive ? '+${r.point}' : '${r.point}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: positive ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
              ),
            ],
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.description, style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
          ],
          const SizedBox(height: 6),
          Text(
            r.assignedBy.isNotEmpty ? '${r.date} · by ${r.assignedBy}' : r.date,
            style: const TextStyle(fontSize: 10, color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}
