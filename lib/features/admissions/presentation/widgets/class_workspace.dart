import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import 'application_row.dart';
import 'application_detail_panel.dart';
import 'bulk_action_bar.dart';
import 'template_picker.dart';

/// Matches `ClassWorkspace.tsx`'s own `exportCSV()` exactly — same headers,
/// same column order, same quoting. Mobile has no `Blob` + `<a download>`,
/// so this hands the built CSV to the native share/save sheet instead
/// (`Share.shareXFiles`) — the practical mobile equivalent of a browser
/// download.
String _buildInquiriesCsv(List<InquiryEntity> rows) {
  String quote(String v) => '"${v.replaceAll('"', '""')}"';
  final headers = ['Name', 'Phone', 'Email', 'Class', 'Stage', 'Source', 'Assigned', 'Query Date', 'Follow-up'];
  final lines = rows.map((i) => [
        quote(i.fullName),
        quote(i.phone),
        quote(i.email),
        quote(i.classNameResolved ?? ''),
        quote(i.status),
        quote(i.sourceName ?? ''),
        quote(i.assigned),
        quote(i.queryDate ?? ''),
        quote(i.nextFollowUpDate ?? ''),
      ].join(','));
  return [headers.join(','), ...lines].join('\n');
}

Future<void> _exportInquiriesCsv(List<InquiryEntity> rows, String filename) async {
  final csv = _buildInquiriesCsv(rows);
  final bytes = Uint8List.fromList(utf8.encode(csv));
  await Share.shareXFiles([XFile.fromData(bytes, name: filename, mimeType: 'text/csv')]);
}

const int kWorkspacePageSize = 25;

class StageTabSpec {
  final String key;
  final String label;
  const StageTabSpec(this.key, this.label);
}

const List<StageTabSpec> kStageTabs = [
  StageTabSpec('all', 'All'),
  StageTabSpec('new', 'New'),
  StageTabSpec('active', 'In Conversation'),
  StageTabSpec('pending', 'Decision Pending'),
  StageTabSpec('enrolled', 'Enrolled'),
  StageTabSpec('waitlist', 'Waitlist'),
  StageTabSpec('cold', 'Cold / Dropped'),
];

List<InquiryEntity> filterByStage(List<InquiryEntity> inqs, String stage) {
  switch (stage) {
    case 'all':
      return inqs.where((i) => i.activeStatus == 1 || i.status == 'enrolled').toList();
    case 'new':
      return inqs.where((i) => i.status == 'new' && i.activeStatus == 1).toList();
    case 'active':
      return inqs.where((i) => i.status == 'contacted' && i.activeStatus == 1).toList();
    case 'pending':
      return inqs.where((i) => i.status == 'visited' && i.activeStatus == 1).toList();
    case 'enrolled':
      return inqs.where((i) => i.status == 'enrolled').toList();
    case 'waitlist':
      return inqs.where((i) => i.status == 'waitlisted').toList();
    case 'cold':
      return inqs.where((i) => i.status == 'declined' || i.activeStatus == 2).toList();
    default:
      return inqs;
  }
}

/// Class Workspace — section "03" of the Command Center. Converted from web
/// `command-center/ClassWorkspace.tsx`. Stage tabs + search + application
/// table for the currently-selected class (or "All Classes").
class ClassWorkspace extends StatefulWidget {
  final int? selectedClassId;
  final List<SchoolClassEntity> classes;
  final List<InquiryEntity> allInquiries;
  final String today;
  final ValueChanged<InquiryEntity> onOpenLog;
  final ValueChanged<InquiryEntity> onOpenCall;
  final ValueChanged<InquiryEntity> onOpenWA;
  final ValueChanged<InquiryEntity> onEdit;
  final VoidCallback onReload;
  final String? forcedStage;
  final ClassConfigEntity? classConfig;
  final Future<void> Function(int id, String stage) onInlineStageMove;
  final Future<void> Function(List<int> ids, String stage) onBulkMoveStage;
  final Future<void> Function(List<int> ids, String name) onBulkAssign;
  final Future<void> Function(List<int> ids) onBulkDelete;

  const ClassWorkspace({
    super.key,
    required this.selectedClassId,
    required this.classes,
    required this.allInquiries,
    required this.today,
    required this.onOpenLog,
    required this.onOpenCall,
    required this.onOpenWA,
    required this.onEdit,
    required this.onReload,
    required this.onInlineStageMove,
    required this.onBulkMoveStage,
    required this.onBulkAssign,
    required this.onBulkDelete,
    this.forcedStage,
    this.classConfig,
  });

  @override
  State<ClassWorkspace> createState() => _ClassWorkspaceState();
}

class _ClassWorkspaceState extends State<ClassWorkspace> {
  String _activeStage = 'all';
  // Selected but never applied to `_classFiltered` — matches the real web
  // `ClassWorkspace.tsx` exactly, which flags this as a TODO: `ApiInquiry`
  // has no `section` field server-side, so there's nothing to filter by.
  String _selectedSection = 'all';
  String _debouncedSearch = '';
  int _page = 1;
  final Set<int> _selectedIds = {};
  bool _showTemplatePicker = false;
  bool _bulkLoading = false;
  Timer? _searchDebounce;
  OverlayEntry? _bulkBarEntry;

  @override
  void didUpdateWidget(ClassWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forcedStage != null && widget.forcedStage != oldWidget.forcedStage) {
      setState(() {
        _activeStage = widget.forcedStage!;
        _page = 1;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _bulkBarEntry?.remove();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _debouncedSearch = v;
        _page = 1;
      });
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
    _syncBulkBar();
  }

  /// The Bulk Action Bar needs true viewport-fixed positioning (it must
  /// float above the page regardless of scroll offset, matching web's
  /// `position:fixed`) — a plain child in this section's Column can't do
  /// that, so it's inserted into the root Overlay instead and kept in sync
  /// with `_selectedIds` / `_bulkLoading` here.
  void _syncBulkBar() {
    final hasSelection = _selectedIds.isNotEmpty;
    if (hasSelection && _bulkBarEntry == null) {
      _bulkBarEntry = OverlayEntry(
        builder: (context) => BulkActionBar(
          selectedCount: _selectedIds.length,
          isLoading: _bulkLoading,
          onMoveStage: _handleBulkMoveStage,
          onAssign: _handleBulkAssign,
          onDelete: _handleBulkDelete,
          onClear: () {
            setState(() => _selectedIds.clear());
            _syncBulkBar();
          },
        ),
      );
      Overlay.of(context).insert(_bulkBarEntry!);
    } else if (!hasSelection && _bulkBarEntry != null) {
      _bulkBarEntry!.remove();
      _bulkBarEntry = null;
    } else {
      _bulkBarEntry?.markNeedsBuild();
    }
  }

  /// Application Detail Panel needs the same viewport-fixed treatment — it
  /// slides in from the right and dims the whole screen regardless of
  /// where the Class Workspace section sits in the page's scroll offset,
  /// so it's pushed onto the root Navigator instead of embedded inline.
  void _openDetail(InquiryEntity inq) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Application Detail',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) => ApplicationDetailPanel(
        inquiry: inq,
        isOpen: true,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onOpenLog: widget.onOpenLog,
        onOpenCall: widget.onOpenCall,
        onOpenWA: widget.onOpenWA,
        onEdit: (i) {
          Navigator.of(dialogContext).maybePop();
          widget.onEdit(i);
        },
        today: widget.today,
        onReload: widget.onReload,
      ),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved), child: child);
      },
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $msg'),
        backgroundColor: const Color(0xFF111827),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 3500),
      ),
    );
  }

  String get _className {
    if (widget.selectedClassId == null) return 'All Classes';
    final cls = widget.classes.where((c) => c.id == widget.selectedClassId).toList();
    return cls.isEmpty ? 'Unknown' : cls.first.name;
  }

  List<SectionEntity> get _sections {
    final cls = widget.classes.where((c) => c.id == widget.selectedClassId).toList();
    return cls.isEmpty ? const [] : cls.first.sections;
  }

  List<InquiryEntity> get _classFiltered {
    if (widget.selectedClassId == null) return widget.allInquiries;
    return widget.allInquiries.where((i) => i.schoolClass == widget.selectedClassId).toList();
  }

  List<InquiryEntity> get _filtered {
    final base = filterByStage(_classFiltered, _activeStage);
    if (_debouncedSearch.isEmpty) return base;
    final q = _debouncedSearch.toLowerCase();
    return base.where((i) =>
        i.fullName.toLowerCase().contains(q) ||
        i.phone.contains(q) ||
        (i.classNameResolved ?? '').toLowerCase().contains(q)).toList();
  }

  Map<String, int> get _stageCounts {
    final counts = <String, int>{};
    for (final t in kStageTabs) {
      counts[t.key] = filterByStage(_classFiltered, t.key).length;
    }
    return counts;
  }

  Future<void> _handleBulkMoveStage(String stage) async {
    if (_selectedIds.isEmpty) return;
    setState(() => _bulkLoading = true);
    _bulkBarEntry?.markNeedsBuild();
    final ids = _selectedIds.toList();
    try {
      await widget.onBulkMoveStage(ids, stage);
      _showToast('${ids.length} application${ids.length > 1 ? "s" : ""} moved to $stage');
      setState(() => _selectedIds.clear());
      widget.onReload();
    } finally {
      if (mounted) setState(() => _bulkLoading = false);
      _syncBulkBar();
    }
  }

  Future<void> _handleBulkAssign(String name) async {
    if (_selectedIds.isEmpty) return;
    setState(() => _bulkLoading = true);
    _bulkBarEntry?.markNeedsBuild();
    final ids = _selectedIds.toList();
    try {
      await widget.onBulkAssign(ids, name);
      _showToast('${ids.length} application${ids.length > 1 ? "s" : ""} assigned to $name');
      setState(() => _selectedIds.clear());
      widget.onReload();
    } finally {
      if (mounted) setState(() => _bulkLoading = false);
      _syncBulkBar();
    }
  }

  Future<void> _handleBulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected'),
        content: Text('Delete ${ids.length} selected application(s)? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _bulkLoading = true);
    _bulkBarEntry?.markNeedsBuild();
    try {
      await widget.onBulkDelete(ids);
      _showToast('${ids.length} application${ids.length > 1 ? "s" : ""} deleted.');
      setState(() => _selectedIds.clear());
      widget.onReload();
    } finally {
      if (mounted) setState(() => _bulkLoading = false);
      _syncBulkBar();
    }
  }

  Future<void> _handleInlineStageMove(int id, String stage) async {
    await widget.onInlineStageMove(id, stage);
    widget.onReload();
  }

  InquiryEntity? get _firstSelectedInquiry {
    if (_selectedIds.isEmpty) return null;
    final firstId = _selectedIds.first;
    final matches = widget.allInquiries.where((i) => i.id == firstId).toList();
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalPages = (filtered.length / kWorkspacePageSize).ceil().clamp(1, 999999);
    final paginated = filtered.skip((_page - 1) * kWorkspacePageSize).take(kWorkspacePageSize).toList();
    final stageCounts = _stageCounts;
    final sections = _sections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                      child: const Text('03', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    ),
                    const Text('Class Workspace', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    const Text('·', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    Text(_className, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4F46E5))),
                    if (sections.length > 1) _sectionDropdown(sections),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final rows = filtered;
                  final filename = '${_className.replaceAll(RegExp(r'\s+'), '_')}_inquiries.csv';
                  try {
                    await _exportInquiriesCsv(rows, filename);
                  } catch (_) {
                    _showToast('Export failed.');
                    return;
                  }
                  _showToast('Export completed successfully.');
                },
                icon: const Icon(Icons.download_outlined, size: 13),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Conversion funnel bar
        if (widget.classConfig != null && widget.classConfig!.capacity > 0) _funnelBar(widget.classConfig!),

        // Stage tabs
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: kStageTabs.map((t) {
              final isActive = _activeStage == t.key;
              final count = stageCounts[t.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _activeStage = t.key;
                    _page = 1;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.label, style: TextStyle(fontSize: 13, color: isActive ? Colors.white : const Color(0xFF4B5563))),
                        if (count > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? const Color(0xFFC7D2FE) : const Color(0xFF9CA3AF))),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search name or phone…',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, size: 15, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Table
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 10),
                            Text(
                              _debouncedSearch.isNotEmpty ? 'No results match your search.' : 'No inquiries in this stage.',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: ApplicationTableColumns.total,
                          child: Column(
                            children: [
                              _tableHeader(paginated),
                              ...paginated.map((inq) => ApplicationRow(
                                    key: ValueKey(inq.id),
                                    inquiry: inq,
                                    isSelected: _selectedIds.contains(inq.id),
                                    today: widget.today,
                                    onToggleSelect: _toggleSelect,
                                    onOpenDetail: _openDetail,
                                    onOpenLog: widget.onOpenLog,
                                    onOpenCall: widget.onOpenCall,
                                    onOpenWA: widget.onOpenWA,
                                    onInlineStageMove: _handleInlineStageMove,
                                  )),
                            ],
                          ),
                        ),
                      ),
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_page - 1) * kWorkspacePageSize + 1}–${(_page * kWorkspacePageSize).clamp(0, filtered.length)} of ${filtered.length}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _page > 1 ? () => setState(() => _page--) : null,
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB))),
                          child: const Text('← Prev'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _page < totalPages ? () => setState(() => _page++) : null,
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB))),
                          child: const Text('Next →'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Template picker for bulk message (unreachable in current web
        // build too — BulkActionBar's "Send Message" trigger is commented
        // out there; kept here for parity, never actually opened).
        TemplatePicker(
          isOpen: _showTemplatePicker,
          onClose: () => setState(() => _showTemplatePicker = false),
          inquiry: _firstSelectedInquiry,
          onSelect: (templateBody) {
            final ids = _selectedIds.toList();
            setState(() => _bulkLoading = true);
            widget.onBulkMoveStage(ids, 'contacted').then((_) {
              _showToast('Message sent to ${ids.length} famil${ids.length == 1 ? "y" : "ies"}');
              setState(() {
                _selectedIds.clear();
                _showTemplatePicker = false;
                _bulkLoading = false;
              });
              widget.onReload();
            });
          },
        ),
      ],
    );
  }

  Widget _sectionDropdown(List<SectionEntity> sections) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSection,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Sections')),
            ...sections.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
          ],
          onChanged: (v) => setState(() => _selectedSection = v ?? 'all'),
        ),
      ),
    );
  }

  Widget _funnelBar(ClassConfigEntity cfg) {
    final enrolledCount = cfg.enrolledCount;
    final capacity = cfg.capacity;
    final pipelineCount = cfg.pipelineCount;
    final conversionPct = pipelineCount > 0 ? ((enrolledCount / pipelineCount) * 100).round() : 0;
    final fillRatio = capacity > 0 ? (enrolledCount / capacity).clamp(0.0, 1.0) : 0.0;
    final fillColor = fillRatio > 0.9
        ? const Color(0xFFF87171)
        : fillRatio > 0.6
            ? const Color(0xFFFBBF24)
            : const Color(0xFF818CF8);
    final conversionColor = conversionPct >= 50
        ? const Color(0xFF16A34A)
        : conversionPct >= 25
            ? const Color(0xFFD97706)
            : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(12)),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            _funnelStat('$enrolledCount', ' / $capacity seats filled'),
            _divider(),
            _funnelStat('${(capacity - enrolledCount).clamp(0, capacity)}', ' remaining'),
            _divider(),
            Text.rich(TextSpan(children: [
              TextSpan(text: '$pipelineCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
              const TextSpan(text: ' in pipeline', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ])),
            if (pipelineCount > 0) ...[
              _divider(),
              Text.rich(TextSpan(children: [
                TextSpan(text: '$conversionPct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: conversionColor)),
                const TextSpan(text: ' conversion', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ])),
            ],
            SizedBox(
              width: 96,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: fillRatio, backgroundColor: const Color(0xFFE5E7EB), color: fillColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _funnelStat(String value, String suffix) {
    return Text.rich(TextSpan(children: [
      TextSpan(text: value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      TextSpan(text: suffix, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
    ]));
  }

  Widget _divider() => Container(width: 1, height: 12, color: const Color(0xFFE5E7EB));

  Widget _tableHeader(List<InquiryEntity> paginated) {
    final allSelected = paginated.isNotEmpty && paginated.every((i) => _selectedIds.contains(i.id));
    return Container(
      decoration: const BoxDecoration(color: Color(0x99F9FAFB), border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        children: [
          SizedBox(
            width: ApplicationTableColumns.checkbox,
            child: Checkbox(
              value: allSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedIds.addAll(paginated.map((i) => i.id));
                  } else {
                    _selectedIds.clear();
                  }
                });
                _syncBulkBar();
              },
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          _headerCell(ApplicationTableColumns.name, 'Name'),
          _headerCell(ApplicationTableColumns.grade, 'Grade'),
          _headerCell(ApplicationTableColumns.source, 'Source'),
          _headerCell(ApplicationTableColumns.age, 'Age'),
          _headerCell(ApplicationTableColumns.stage, 'Stage'),
          _headerCell(ApplicationTableColumns.followUp, 'Follow-up'),
          _headerCell(ApplicationTableColumns.counsellor, 'Counsellor'),
          _headerCell(ApplicationTableColumns.actions, 'Actions', alignRight: true),
        ],
      ),
    );
  }

  Widget _headerCell(double width, String label, {bool alignRight = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          label,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.3),
        ),
      ),
    );
  }
}
