import 'package:flutter/material.dart';

/// Exact color tokens from the real web's `app/globals.css` `:root` scope
/// used inline by `HrStaffPanel`/`HrStaffDirectoryPanel` via `var(--line)`,
/// `var(--primary)`, etc. Deliberately separate from `HrColors` (used by
/// HR Setup) — Setup borrows visual components from the unmerged `demo`
/// branch's purple `HrUi.tsx`, but Staff has no such equivalent and must
/// match its own real, dormant-but-real inline styling exactly.
class HrStaffColors {
  HrStaffColors._();

  static const line = Color(0xFFDBE4F0);
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const primary = Color(0xFF1D4ED8);
  static const warning = Color(0xFFD97706);
  static const success = Color(0xFF16A34A);
  static const errorRed = Color(0xFFDC2626);
  static const editBlue = Color(0xFF0EA5E9);
  static const darkSlate = Color(0xFF334155);
  static const secondaryGrey = Color(0xFF64748B);
}

/// Status pill — matches `HrStaffDirectoryPanel`'s inline Active/Inactive
/// coloring (green-tinted for active, red-tinted background for inactive
/// row, per the panel's own row-level `#fef2f2` background rule).
Widget hrStaffStatusPill(String status) {
  final isActive = status == 'active';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
    ),
    child: Text(
      isActive ? 'Active' : 'Inactive',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B)),
    ),
  );
}

/// Numbered pagination footer — matches `buildPageButtons`'s 5-wide window
/// algorithm exactly (shared with HR Setup's own pagination bar, but kept
/// as a separate copy here to avoid a cross-theme dependency between the
/// two visually-distinct HR submodules).
class HrStaffPaginationBar extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool loading;
  final ValueChanged<int> onPageChange;
  final ValueChanged<int> onPageSizeChange;

  const HrStaffPaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.loading,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);
    final start = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
    final end = totalCount == 0 ? 0 : (start + pageSize - 1).clamp(0, totalCount);

    List<int> pageButtons() {
      const windowSize = 5;
      if (totalPages <= windowSize) return List.generate(totalPages, (i) => i + 1);
      final half = windowSize ~/ 2;
      var pStart = (page - half).clamp(1, totalPages);
      final pEnd = (pStart + windowSize - 1).clamp(1, totalPages);
      pStart = (pEnd - windowSize + 1).clamp(1, totalPages);
      return List.generate(pEnd - pStart + 1, (i) => pStart + i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing $start-$end of $totalCount staff member${totalCount != 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 13, color: HrStaffColors.textMuted),
        ),
        const Text('Search and filters apply on the server.', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 130,
              height: 34,
              child: DropdownButtonFormField<int>(
                initialValue: pageSize,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: HrStaffColors.line)),
                ),
                items: const [10, 25, 50, 100].map((s) => DropdownMenuItem(value: s, child: Text('$s / page', style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) {
                  if (v != null) onPageSizeChange(v);
                },
              ),
            ),
            Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _pageBtn('Previous', HrStaffColors.darkSlate, page > 1 && !loading ? () => onPageChange(page - 1) : null),
              for (final n in pageButtons())
                _pageBtn('$n', n == page ? HrStaffColors.primary : HrStaffColors.secondaryGrey, !loading ? () => onPageChange(n) : null),
              _pageBtn('Next', HrStaffColors.darkSlate, page < totalPages && !loading ? () => onPageChange(page + 1) : null),
            ]),
            Text('Page $page of $totalPages · $totalCount total', style: const TextStyle(fontSize: 12.5, color: HrStaffColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _pageBtn(String label, Color color, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
        ),
      ),
    );
  }
}
