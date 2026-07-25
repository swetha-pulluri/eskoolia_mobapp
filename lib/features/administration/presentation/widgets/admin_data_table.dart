import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'web_button.dart';

class AdminColumn {
  final String label;
  final double width;
  /// If set, the header becomes tappable (e.g. sortable columns on
  /// Visitor Book / Phone Call Log) and shows the given arrow suffix.
  final VoidCallback? onTap;
  final String sortArrow;
  const AdminColumn(this.label, {this.width = 120, this.onTap, this.sortArrow = ''});
}

/// Shared horizontally-scrollable data table for Administration lists —
/// real columns matching the web tables (not cards), per the team's
/// established lesson: adapt the width for mobile, don't restructure the
/// table into cards.
class AdminDataTable extends StatelessWidget {
  final List<AdminColumn> columns;
  final List<List<Widget>> rows;
  final bool isLoading;
  final String emptyText;
  final String loadingText;
  /// Zebra-stripe odd rows with `#f8fafc` (Phone Call Log). Off by default
  /// to match panels (Visitor Book, Complaints, Postal) that don't stripe.
  final bool zebraStripe;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyText = 'No records found.',
    this.loadingText = 'Loading records...',
    this.zebraStripe = false,
  });

  double get _totalWidth => columns.fold(0, (sum, c) => sum + c.width);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _totalWidth,
            child: Column(
              children: [
                _headerRow(),
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(loadingText, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
                    ),
                  )
                else if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(emptyText, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
                    ),
                  )
                else
                  ...List.generate(rows.length, (i) => _dataRow(rows[i], i)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerRow() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgTertiary,
        border: Border(bottom: BorderSide(color: AppColors.borderPrimary)),
      ),
      child: Row(
        children: columns.map((c) {
          final label = c.sortArrow.isEmpty ? c.label : '${c.label} ${c.sortArrow}';
          final text = Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          );
          return SizedBox(
            width: c.width,
            child: c.onTap != null
                ? InkWell(
                    onTap: c.onTap,
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: text),
                  )
                : Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: text),
          );
        }).toList(),
      ),
    );
  }

  Widget _dataRow(List<Widget> cells, int index) {
    return Container(
      decoration: BoxDecoration(
        color: zebraStripe && index.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(columns.length, (i) {
          return SizedBox(
            width: columns[i].width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: cells[i],
            ),
          );
        }),
      ),
    );
  }
}

/// Shared pagination footer — matches the web panels' pagination style.
/// Two variants exist on web:
///  - "Showing page X of Y (Z total records)" + Previous/Next (Visitor
///    Book, Admin Setup) — pass [summaryStyle] = PaginationSummaryStyle.pageOfTotal.
///  - "Showing A-B of C records" + Previous/Next (Complaints, Postal) —
///    pass PaginationSummaryStyle.rangeOfTotal (default).
/// Phone Call Log additionally shows numbered page buttons — pass
/// [showPageNumbers] = true.
enum PaginationSummaryStyle { rangeOfTotal, pageOfTotal }

class AdminPaginationBar extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChange;
  final ValueChanged<int> onPageSizeChange;
  final List<int> pageSizeOptions;
  final PaginationSummaryStyle summaryStyle;
  final bool showPageNumbers;
  final Color previousColor;
  final Color nextColor;
  /// Appended to each page-size option's label — web shows plain numbers
  /// ("10") on Visitor Book/Complaint/Admin Setup but "10 / page" on Phone
  /// Call Log/Postal Receive/Postal Dispatch.
  final String pageSizeSuffix;
  /// The redesigned "numbered stepper" screens (Visitor Book, Complaints,
  /// Phone Calls, Postal Receive/Dispatch) all use bare `‹`/`›` chevron
  /// buttons instead of "Previous"/"Next" labels, a "Page size:" label
  /// (with colon), and show no page-number text at all between the
  /// chevrons. Set true to switch to that variant.
  final bool chevronStyle;

  const AdminPaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChange,
    required this.onPageSizeChange,
    this.pageSizeOptions = const [10, 20, 30, 50],
    this.summaryStyle = PaginationSummaryStyle.rangeOfTotal,
    this.showPageNumbers = false,
    this.previousColor = const Color(0xFF64748B),
    this.nextColor = const Color(0xFF64748B),
    this.pageSizeSuffix = '',
    this.chevronStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);
    final start = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
    final end = totalCount == 0 ? 0 : (start + pageSize - 1).clamp(0, totalCount);
    final summaryText = summaryStyle == PaginationSummaryStyle.pageOfTotal
        ? 'Showing page $page of $totalPages ($totalCount total records)'
        : 'Showing $start-$end of $totalCount records';

    if (chevronStyle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(summaryText, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Page size:', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                const SizedBox(width: 6),
                DropdownButton<int>(
                  value: pageSize,
                  underline: const SizedBox(),
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  items: pageSizeOptions.map((s) => DropdownMenuItem(value: s, child: Text('$s'))).toList(),
                  onChanged: (v) {
                    if (v != null) onPageSizeChange(v);
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: page > 1 ? () => onPageChange(page - 1) : null,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: page < totalPages ? () => onPageChange(page + 1) : null,
                  icon: const Icon(Icons.chevron_right, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(summaryText, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Page size', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: pageSize,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                items: pageSizeOptions.map((s) => DropdownMenuItem(value: s, child: Text('$s$pageSizeSuffix'))).toList(),
                onChanged: (v) {
                  if (v != null) onPageSizeChange(v);
                },
              ),
            ],
          ),
          WebButton(label: 'Previous', color: previousColor, onPressed: page > 1 ? () => onPageChange(page - 1) : null),
          if (showPageNumbers)
            ...(() {
              final from = (page - 2).clamp(1, totalPages);
              final to = (page + 2).clamp(1, totalPages);
              return [
                for (var n = from; n <= to; n++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: WebButton(
                      label: '$n',
                      color: n == page ? AppColors.primaryPurple : const Color(0xFF94A3B8),
                      onPressed: () => onPageChange(n),
                    ),
                  ),
              ];
            })()
          else
            Text('Page $page of $totalPages', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          WebButton(label: 'Next', color: nextColor, onPressed: page < totalPages ? () => onPageChange(page + 1) : null),
        ],
      ),
    );
  }
}
