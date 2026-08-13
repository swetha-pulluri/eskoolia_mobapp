import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../administration/domain/entities/paginated_result.dart';
import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../student/presentation/widgets/student_pager_footer.dart';
import '../../domain/entities/settings_audit_log_entity.dart';
import '../providers/settings_audit_log_provider.dart';

/// Mirrors JS `new Date(...).toLocaleString()` in its default (en-US)
/// browser form — "M/D/YYYY, h:mm:ss AM/PM" — the closest fixed pattern to
/// an inherently locale-dependent call (`AuditLogPanel.tsx:106`).
final _rowDateFormat = DateFormat('M/d/y, h:mm:ss a');

const _kColumnHeaders = ['When', 'Actor', 'Action', 'Object', 'IP'];

/// Settings → Audit Log — a 1:1 port of `frontend/components/settings/
/// AuditLogPanel.tsx`: a school-scoped, filterable, paginated read-only feed
/// over every `SettingsAuditLog` row (Leave Policy, Holidays, SMTP,
/// Documents, Attendance Rules, ...), backed by the same
/// `/api/v1/settings/audit-log/` endpoint the other Settings sub-panels
/// already use for their own narrower per-item "view history" widgets —
/// called here with no `module`/`object_id` filter, so it returns every row.
///
/// The results list is a real `<table>` port (When/Actor/Action/Object/IP
/// columns, `AuditLogPanel.tsx:93-114`) via a Flutter [Table] — not a
/// stacked-card adaptation — using [IntrinsicColumnWidth] on every column to
/// mirror the browser's default `table-layout:auto` (columns auto-size to
/// content, table stretches to fill the available width when content is
/// narrower than it), wrapped in a horizontal [SingleChildScrollView] so
/// content wider than the screen scrolls instead of wrapping/truncating —
/// the mobile equivalent of the web table's own unconstrained overflow.
/// [TableBorder.horizontalInside] + `bottom` reproduce the web's per-`<tr>`
/// `borderBottom` (a line under the header, under every row, and under the
/// last row too). There is deliberately no action-type color-coding, no
/// expandable diff view, and no export/refresh button — none of those exist
/// in the real web panel either (confirmed against its full source); only
/// the filters, "Filter"/"Clear" buttons, and numbered pagination it
/// actually has.
class SettingsAuditLogPage extends ConsumerStatefulWidget {
  const SettingsAuditLogPage({super.key});

  @override
  ConsumerState<SettingsAuditLogPage> createState() => _SettingsAuditLogPageState();
}

class _SettingsAuditLogPageState extends ConsumerState<SettingsAuditLogPage> {
  final _moduleController = TextEditingController();
  final _actionController = TextEditingController();
  final _actorController = TextEditingController();
  String? _dateFrom;
  String? _dateTo;

  @override
  void dispose() {
    _moduleController.dispose();
    _actionController.dispose();
    _actorController.dispose();
    super.dispose();
  }

  // Web only refetches when "Filter" is clicked, never on keystroke/date-pick
  // — matched exactly by keeping these as local, uncommitted draft values
  // until `_applyFilters` pushes them into the watched provider.
  void _applyFilters() {
    ref.read(settingsAuditFiltersProvider.notifier).state = SettingsAuditFilters(
      page: 1,
      module: _moduleController.text.trim().isEmpty ? null : _moduleController.text.trim(),
      action: _actionController.text.trim().isEmpty ? null : _actionController.text.trim(),
      actor: _actorController.text.trim().isEmpty ? null : _actorController.text.trim(),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  void _clearFilters() {
    _moduleController.clear();
    _actionController.clear();
    _actorController.clear();
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    ref.read(settingsAuditFiltersProvider.notifier).state = const SettingsAuditFilters();
  }

  void _setPage(int page) {
    final current = ref.read(settingsAuditFiltersProvider);
    ref.read(settingsAuditFiltersProvider.notifier).state = current.copyWith(page: page);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      if (isFrom) {
        _dateFrom = iso;
      } else {
        _dateTo = iso;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(settingsAuditFiltersProvider);
    final logAsync = ref.watch(settingsAuditLogProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(settingsAuditLogProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                border: Border.all(color: AppColors.borderPrimary),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x0A0F1222), blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _filters(filters),
                  const SizedBox(height: 16),
                  logAsync.when(
                    data: (page) => _resultsSection(page, filters),
                    loading: () => _loading(),
                    error: (e, _) => _errorText(adminErrorMessage(e)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Audit ', style: AppTextStyles.pageTitle),
            Text('Log', style: AppTextStyles.pageTitleAccent),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Every change made through the Settings module — leave policy, holidays, SMTP, documents, '
          'attendance rules.',
          style: AppTextStyles.pageSubtitle,
        ),
      ],
    );
  }

  Widget _filters(SettingsAuditFilters filters) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _textFilter(_moduleController, 'Module (e.g. LeaveType)'),
        _textFilter(_actionController, 'Action contains…'),
        _textFilter(_actorController, 'Actor username'),
        _dateFilter('From', _dateFrom, () => _pickDate(isFrom: true)),
        _dateFilter('To', _dateTo, () => _pickDate(isFrom: false)),
        ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        OutlinedButton(
          onPressed: _clearFilters,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderPrimary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Clear', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _textFilter(TextEditingController controller, String hint) {
    return SizedBox(
      width: 168,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderPrimary)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderPrimary)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.purpleAccent, width: 1.5)),
        ),
      ),
    );
  }

  Widget _dateFilter(String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value ?? label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: value == null ? AppColors.textTertiary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)),
          SizedBox(width: 10),
          Text('Loading…', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _errorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.dangerRed)),
    );
  }

  Widget _resultsSection(PaginatedResult<SettingsAuditLogEntity> page, SettingsAuditFilters filters) {
    final entries = page.results;
    final totalCount = page.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _auditTable(entries),
        // `AuditLogPanel.tsx:115` — rendered *below* the (still-visible,
        // header-only) table, not instead of it.
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No matching audit entries.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
        const SizedBox(height: 16),
        StudentPagerFooter(
          page: filters.page,
          pageSize: kSettingsAuditPageSize,
          totalCount: totalCount,
          onPageChanged: _setPage,
        ),
      ],
    );
  }

  /// Port of `<table>` (`AuditLogPanel.tsx:93-114`) — see the class doc
  /// comment for the column-width/border/scroll approach.
  Widget _auditTable(List<SettingsAuditLogEntity> entries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder(
                horizontalInside: BorderSide(color: AppColors.borderPrimary),
                bottom: BorderSide(color: AppColors.borderPrimary),
              ),
              children: [
                TableRow(children: [for (final header in _kColumnHeaders) _headerCell(header)]),
                for (final entry in entries) _dataRow(entry),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _dataRow(SettingsAuditLogEntity entry) {
    final parsed = DateTime.tryParse(entry.createdAt);
    final when = parsed == null ? entry.createdAt : _rowDateFormat.format(parsed.toLocal());
    final objectId = entry.objectId.isNotEmpty ? ' #${entry.objectId}' : '';
    final object = '${entry.objectType}$objectId';
    final ip = entry.ipAddress ?? '—';
    return TableRow(
      children: [
        _dataCell(when, AppColors.textSecondary),
        _dataCell(entry.actorName, AppColors.textPrimary),
        _dataCell(entry.action, AppColors.textPrimary),
        _dataCell(object, AppColors.textSecondary),
        _dataCell(ip, AppColors.textSecondary),
      ],
    );
  }

  TableCell _headerCell(String text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ),
    );
  }

  TableCell _dataCell(String text, Color color) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(text, style: TextStyle(fontSize: 13, color: color)),
      ),
    );
  }
}
