import 'package:flutter/material.dart';

/// Shared numbered pagination footer — extracted from
/// student_class_accordion.dart's pager (same `.sl-pager` look) so every
/// Students sub-screen (Disabled/Deleted/Unassigned/Categories/Groups) uses
/// one implementation instead of five near-identical copies.
class StudentPagerFooter extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  const StudentPagerFooter({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
    final resultsOnPage = (totalCount - (page - 1) * pageSize).clamp(0, pageSize);
    final end = (start + resultsOnPage - 1).clamp(0, totalCount);
    final totalPages = (totalCount / pageSize).ceil().clamp(1, 999);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            '$start–$end of $totalCount',
            style: const TextStyle(fontSize: 12, color: Color(0xFF747896)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pagerButton(icon: Icons.chevron_left_rounded, onTap: page > 1 ? () => onPageChanged(page - 1) : null),
              for (var p = 1; p <= totalPages; p++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _pagerNumber(page: p, isActive: p == page, onTap: () => onPageChanged(p)),
                ),
              _pagerButton(
                icon: Icons.chevron_right_rounded,
                onTap: page < totalPages ? () => onPageChanged(page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pagerButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E4F2)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 14, color: onTap != null ? const Color(0xFF42455D) : const Color(0xFFD8DAEA)),
      ),
    );
  }

  Widget _pagerNumber({required int page, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F39F6) : Colors.white,
          border: Border.all(color: isActive ? const Color(0xFF4F39F6) : const Color(0xFFE0E4F2)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF42455D),
          ),
        ),
      ),
    );
  }
}
