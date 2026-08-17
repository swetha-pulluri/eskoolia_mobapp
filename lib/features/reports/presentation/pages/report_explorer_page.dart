import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/report_definition_entity.dart';
import '../providers/reports_providers.dart';

/// Generic "Report Explorer" — mirrors web's `ReportExplorer.tsx` exactly:
/// one data-driven filter+table+export engine reused across all 29 report
/// definitions (`report_definition_entity.dart`), auto-deriving table
/// columns from the first result row's keys (Title-Cased) since none of
/// the real definitions specify explicit columns — same as web.
///
/// Per an explicit product decision, this is wired to the REAL backend as
/// it actually is today, including its quirks: several of the 29 titles
/// return identical or misleading data (e.g. "Payroll Report" has no
/// salary fields — it's HR attendance data under a different export name;
/// "Student Dormitory Report" is just the plain student list), the Exam
/// Marks report's `grade` column is always blank (a real backend bug —
/// reads a model attribute that doesn't exist), and the Student Attendance
/// report will surface a server error on any non-empty result (a
/// confirmed backend bug: it reads `item.note` but the model field is
/// `notes`). None of this was invented or fixed here — it's ported as-is.
class ReportExplorerPage extends ConsumerStatefulWidget {
  final ReportDefinitionEntity definition;
  const ReportExplorerPage({super.key, required this.definition});

  @override
  ConsumerState<ReportExplorerPage> createState() => _ReportExplorerPageState();
}

class _ReportExplorerPageState extends ConsumerState<ReportExplorerPage> {
  final Map<String, dynamic> _values = {};
  final Map<String, List<(int, String)>> _optionsCache = {};
  final Set<String> _optionsLoading = {};

  /// One controller per text-type field (e.g. "Keyword") — without this,
  /// the `TextField` is uncontrolled: clearing `_values` on Reset had no
  /// effect on what was actually displayed on screen, since nothing told
  /// the field itself to clear.
  final Map<String, TextEditingController> _textControllers = {};

  bool _loading = false;
  bool _hasSearched = false;
  bool _exporting = false;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];
  int _count = 0;
  int _page = 1;

  static const _pageSize = 20;
  int get _totalPages => (_count / _pageSize).ceil().clamp(1, 999999);

  TextEditingController _controllerFor(String key) => _textControllers.putIfAbsent(key, () => TextEditingController());

  @override
  void initState() {
    super.initState();
    // Matches web's `ReportExplorer.tsx` exactly: it fetches the default,
    // unfiltered page on mount — the user never has to type a keyword or
    // press Search just to see the initial records.
    _search();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _currentFilters() {
    final out = <String, dynamic>{};
    for (final f in widget.definition.filterFields) {
      final v = _values[f.key];
      if (v == null) continue;
      if (v is String && v.isEmpty) continue;
      out[f.key] = v;
    }
    return out;
  }

  Future<void> _search({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    debugPrint('[ReportExplorer] search start: endpoint=${widget.definition.endpoint} filters=${_currentFilters()}');
    try {
      final data = await ref.read(reportsRepositoryProvider).getReportPage(widget.definition.endpoint, page: page, filters: _currentFilters());
      debugPrint('[ReportExplorer] search response: keys=${data.keys.toList()} count=${data['count']} resultsLength=${(data['results'] as List?)?.length}');
      final results = (data['results'] as List? ?? const []).cast<Map<String, dynamic>>();
      debugPrint('[ReportExplorer] search parsed: rows=${results.length} mounted=$mounted');
      if (mounted) {
        setState(() {
          _rows = results;
          _count = data['count'] as int? ?? results.length;
          _page = page;
          _hasSearched = true;
        });
        debugPrint('[ReportExplorer] search state updated: hasSearched=$_hasSearched count=$_count rows=${_rows.length}');
      }
    } catch (e, st) {
      debugPrint('[ReportExplorer] search FAILED: $e\n$st');
      // Guaranteed non-blank — a caught exception whose message happens to
      // stringify to empty previously rendered as an invisible error line,
      // which looked identical to "the button silently did nothing."
      final message = e.toString().trim();
      if (mounted) setState(() => _error = message.isEmpty ? 'Search failed ($e). Please try again.' : message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    for (final c in _textControllers.values) {
      c.clear();
    }
    setState(() {
      _values.clear();
      _error = null;
    });
    // Matches web: Reset clears the filters and reloads the same default,
    // unfiltered page Search would show — it doesn't just blank the table.
    _search(page: 1);
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(reportsRepositoryProvider).exportReport(widget.definition.endpoint, format, _currentFilters());
      final ext = format == 'excel' ? 'xlsx' : format;
      await saveBytesForDownload(bytes: Uint8List.fromList(bytes), filename: '${widget.definition.key.replaceAll('/', '-')}.$ext');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report exported.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _depKey(ReportFilterFieldDef field) => (field.dependsOn ?? const []).map((d) => _values[d]).join('|');

  Future<void> _ensureOptionsLoaded(ReportFilterFieldDef field) async {
    if (field.lookupSource == null) return;
    final cacheKey = '${field.key}::${_depKey(field)}';
    if (_optionsCache.containsKey(cacheKey) || _optionsLoading.contains(cacheKey)) return;
    _optionsLoading.add(cacheKey);
    final repo = ref.read(reportsRepositoryProvider);
    List<(int, String)> options;
    try {
      switch (field.lookupSource!) {
        case LookupSource.classes:
          // Shared, cached provider (`reportsClassOptionsProvider`) instead
          // of a direct repository call — this widget's own `_optionsCache`
          // is wiped every time you navigate to a different report
          // definition (each is a fresh page instance), so without this,
          // Class/Section reloaded from a cold start on every single report
          // page, not just once per session.
          options = await ref.read(reportsClassOptionsProvider.future);
        case LookupSource.sections:
          options = await ref.read(reportsSectionOptionsProvider(_values['class_id'] as int?).future);
        case LookupSource.students:
          options = await repo.getStudentOptions(classId: _values['class_id'] as int?, sectionId: _values['section_id'] as int?);
        case LookupSource.subjects:
          options = await repo.getSubjectOptions();
        case LookupSource.examTypes:
          options = await repo.getExamTypeOptions();
        case LookupSource.departments:
          options = await repo.getDepartmentOptions();
        case LookupSource.designations:
          options = await repo.getDesignationOptions(departmentId: _values['department_id'] as int?);
        case LookupSource.staff:
          options = await repo.getStaffOptions(departmentId: _values['department_id'] as int?, designationId: _values['designation_id'] as int?);
        case LookupSource.routes:
          options = await repo.getRouteOptions();
        case LookupSource.vehicles:
          options = await repo.getVehicleOptions();
        case LookupSource.books:
          options = await repo.getBookOptions();
        case LookupSource.categories:
          options = await repo.getCategoryOptions();
        case LookupSource.suppliers:
          options = await repo.getSupplierOptions();
        case LookupSource.incidents:
          options = await repo.getIncidentOptions();
      }
    } catch (_) {
      options = const [];
    }
    _optionsLoading.remove(cacheKey);
    if (mounted) setState(() => _optionsCache[cacheKey] = options);
  }

  /// Clears any field whose `dependsOn` includes [changedKey] — matches
  /// web's cascading filter reset (e.g. changing Class clears Section and
  /// Student).
  void _clearDependents(String changedKey) {
    for (final f in widget.definition.filterFields) {
      if ((f.dependsOn ?? const []).contains(changedKey)) {
        _values.remove(f.key);
        _clearDependents(f.key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matches web's breadcrumb section exactly (`ReportExplorer.tsx`):
              // title left, "Dashboard / Reports / {title}" right, same row.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(widget.definition.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Dashboard / Reports / ${widget.definition.title}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: "Select Criteria" + the 3 colored export
                    // buttons, same row — matches web's `report-criteria-header`
                    // exactly, including its real button colors
                    // (`.report-btn-csv/-excel/-pdf`, `globals.css`).
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        const Text('Select Criteria', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _exportButton('Export CSV', const Color(0xFF16A34A), () => _export('csv')),
                            _exportButton('Export Excel', const Color(0xFF0891B2), () => _export('excel')),
                            _exportButton('Export PDF', const Color(0xFFDC2626), () => _export('pdf')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Responsive field grid — matches web's Bootstrap grid
                    // exactly (`col-lg-3 col-md-4 col-sm-6 col-12`: 4 columns
                    // ≥992px, 3 ≥768px, 2 ≥576px, else 1 full-width column
                    // per field, which is why every field stacks full-width
                    // on a phone screen). "Actions" (Search/Reset) is the
                    // grid's own last item, not a separate row.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final columns = w >= 992 ? 4 : (w >= 768 ? 3 : (w >= 576 ? 2 : 1));
                        const spacing = 12.0;
                        final fieldWidth = (w - spacing * (columns - 1)) / columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: 14,
                          children: [
                            for (final f in widget.definition.filterFields) SizedBox(width: fieldWidth, child: _filterField(f)),
                            SizedBox(width: fieldWidth, child: _actionsField()),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 12.5))),
              if (_hasSearched) ...[
                Text('Total Records: $_count', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: _rows.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('No data found. Use filters and click Search.', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))),
                        )
                      : _resultsTable(),
                ),
                if (_totalPages > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page $_page of $_totalPages', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      Row(children: [
                        OutlinedButton(onPressed: _loading || _page <= 1 ? null : () => _search(page: _page - 1), child: const Text('Previous')),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _loading || _page >= _totalPages ? null : () => _search(page: _page + 1), child: const Text('Next')),
                      ]),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterField(ReportFilterFieldDef field) {
    Widget input;
    switch (field.type) {
      case ReportFieldType.text:
        input = SizedBox(
          width: double.infinity,
          child: TextField(
            controller: _controllerFor(field.key),
            decoration: InputDecoration(
              isDense: true,
              hintText: field.placeholder,
              filled: true,
              fillColor: AppColors.bgSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2)),
            ),
            onChanged: (v) => _values[field.key] = v,
          ),
        );
      case ReportFieldType.date:
        input = SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => _values[field.key] = _fmtDate(picked));
            },
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(color: AppColors.bgSecondary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _values[field.key] as String? ?? 'Select date',
                    style: TextStyle(fontSize: 12, color: _values[field.key] == null ? AppColors.textTertiary : AppColors.textPrimary),
                  ),
                ),
              ]),
            ),
          ),
        );
      case ReportFieldType.select:
        // Matches web's real default option text exactly: every `<select>`
        // shows `field.placeholder || "Select {label}"` for its empty
        // value — never a generic "All" (web's own static option lists
        // technically also define a `{value:'',label:'All'}` entry, but
        // since the placeholder option is always prepended with the same
        // empty value, it's what actually displays; the "All" entry is a
        // shadowed duplicate, not what a user ever sees).
        final placeholder = field.placeholder ?? 'Select ${field.label}';
        if (field.staticOptions != null) {
          input = SizedBox(
            width: double.infinity,
            child: AppDropdown<String>(
              value: _values[field.key] as String? ?? '',
              items: field.staticOptions!.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$1.isEmpty ? placeholder : o.$2, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _values[field.key] = v),
            ),
          );
        } else {
          _ensureOptionsLoaded(field);
          final options = _optionsCache['${field.key}::${_depKey(field)}'];
          input = SizedBox(
            width: double.infinity,
            child: options == null
                ? const SizedBox(height: 36, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
                : AppDropdown<int?>(
                    value: _values[field.key] as int?,
                    hint: Text(placeholder, style: const TextStyle(fontSize: 12)),
                    items: [
                      DropdownMenuItem(value: null, child: Text(placeholder)),
                      ...options.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() {
                      _values[field.key] = v;
                      _clearDependents(field.key);
                    }),
                  ),
          );
        }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(field.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        input,
      ],
    );
  }

  /// Matches web's `.report-btn-csv/-excel/-pdf` exactly (`globals.css`) —
  /// solid color, white bold text, 8px radius, 36px tall.
  Widget _exportButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: _exporting ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  /// The grid's own last field, labeled "Actions" — matches web's
  /// `report-field-actions` grid cell (Search/Reset side by side) exactly,
  /// rather than a separate row below the field grid.
  Widget _actionsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : () => _search(page: 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_loading ? 'Loading…' : 'Search'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderPrimary),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _titleCase(String key) => key.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  Widget _resultsTable() {
    final columns = _rows.first.keys.toList();
    const colWidth = 140.0;
    final tableWidth = columns.length * colWidth + 32;
    const thStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: AppColors.textTertiary);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(color: AppColors.bgSecondary, border: Border(bottom: BorderSide(color: AppColors.borderPrimary))),
              child: Row(children: [for (final c in columns) SizedBox(width: colWidth, child: Text(_titleCase(c), style: thStyle, overflow: TextOverflow.ellipsis))]),
            ),
            for (var i = 0; i < _rows.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: i == _rows.length - 1 ? BorderSide.none : const BorderSide(color: AppColors.borderPrimary))),
                child: Row(children: [
                  for (final c in columns)
                    SizedBox(
                      width: colWidth,
                      child: Text(
                        _rows[i][c] == null ? '—' : '${_rows[i][c]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
