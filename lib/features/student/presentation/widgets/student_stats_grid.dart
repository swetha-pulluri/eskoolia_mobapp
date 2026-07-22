import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/student_stats.dart';

/// Stats grid — mirrors frontend StudentListPanel.tsx's `.stats-grid` (4
/// cards: Total enrolled / Active / New this month / Docs pending). Uses a
/// fixed mainAxisExtent grid (this codebase's established overflow-safe
/// pattern) instead of the frontend's 4-column desktop grid, and prefers
/// 2-up on phones per the Mobile UI Guidelines ("side by side whenever
/// screen width allows") rather than stacking 4 full-width cards.
class StudentStatsGrid extends StatelessWidget {
  final bool loading;
  final StudentStats? stats;

  const StudentStatsGrid({super.key, required this.loading, this.stats});

  @override
  Widget build(BuildContext context) {
    final docsPending = stats?.docsPendingCount ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 280 ? 1 : (width < 560 ? 2 : 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 130,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _StatCard(
                  label: 'TOTAL ENROLLED',
                  value: loading ? '…' : '${stats?.totalCount ?? 0}',
                  hint: '+12 since last week',
                );
              case 1:
                final total = stats?.totalCount ?? 0;
                final active = stats?.activeCount ?? 0;
                final pct = total > 0 ? ((active / total) * 100).round() : null;
                return _StatCard(
                  label: 'ACTIVE',
                  value: loading ? '…' : '$active',
                  hint: pct != null ? '$pct% of total' : 'No data',
                );
              case 2:
                return _StatCard(
                  label: 'NEW THIS MONTH',
                  value: loading ? '…' : '${stats?.newCount ?? 0}',
                  hint: 'Enrolled this month',
                );
              default:
                return _StatCard(
                  label: 'DOCS PENDING',
                  value: loading ? '…' : '$docsPending',
                  hint: docsPending == 0
                      ? 'All documents up to date'
                      : '$docsPending document${docsPending == 1 ? '' : 's'} need review',
                  attention: !loading && docsPending > 0,
                );
            }
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final bool attention;

  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
    this.attention = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: attention ? AppColors.studentStatAttentionBg : Colors.white,
        border: Border.all(
          color: attention ? AppColors.studentStatAttentionBorder : AppColors.studentListLine,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF72758B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: const Color(0xFF10122B),
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF72758B)),
          ),
        ],
      ),
    );
  }
}
