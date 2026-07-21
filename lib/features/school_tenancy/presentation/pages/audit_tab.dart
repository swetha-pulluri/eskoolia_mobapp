import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/icon_stat_card.dart';
import '../../../../core/widgets/action_badge_widget.dart';
import '../../domain/entities/audit_entity.dart' show AuditEventEntity;
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Super Admin Audit Log page.
/// Converts the web `/super-admin/audit` page — eyebrow header, icon KPI
/// row, toolbar (search + severity filter + action filter + date range),
/// and the TIME / ACTOR / ACTION / DETAIL / IP ADDRESS / SEVERITY event
/// table — directly into a real, horizontally-scrollable table on mobile.
/// The table itself is NOT restructured into cards: only its width is
/// adapted (the row scrolls sideways, same as the desktop table would on a
/// narrow viewport). The desktop's permanent side detail panel becomes a
/// tap-through bottom sheet, since a fixed side panel cannot fit next to a
/// table on phone width.
class SuperAdminAuditPage extends ConsumerStatefulWidget {
  const SuperAdminAuditPage({super.key});

  @override
  ConsumerState<SuperAdminAuditPage> createState() => _SuperAdminAuditPageState();
}

class _SuperAdminAuditPageState extends ConsumerState<SuperAdminAuditPage> {
  String _search = '';
  String _sevFilter = '__all__'; // __all__ | info | warning | critical
  String _actionFilter = '__all__';
  bool _showActionOptions = false;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Column widths (dp) — mirrors the web table's fixed pixel column widths
  // (w-[90px] Time, w-[150px] Actor, w-[160px] Action, flex-1 Detail,
  // w-[110px] IP Address, w-[72px] Severity), scaled slightly for touch.
  static const double _colDot = 8;
  static const double _colTime = 88;
  static const double _colActor = 130;
  static const double _colAction = 150;
  static const double _colDetail = 220;
  static const double _colIp = 100;
  static const double _colSeverity = 92;
  static const double _colGap = 10;

  static const List<Map<String, String>> _actionOptions = [
    {'value': '__all__', 'label': 'All actions'},
    {'value': 'auth.login', 'label': 'auth.login'},
    {'value': 'auth.impersonate', 'label': 'auth.impersonate'},
    {'value': 'school.provision', 'label': 'school.provision'},
    {'value': 'school.archive', 'label': 'school.archive'},
    {'value': 'plan.upgrade', 'label': 'plan.upgrade'},
    {'value': 'plan.downgrade', 'label': 'plan.downgrade'},
    {'value': 'invoice.generated', 'label': 'invoice.generated'},
    {'value': 'invoice.overdue', 'label': 'invoice.overdue'},
    {'value': 'api_key.rotate', 'label': 'api_key.rotate'},
    {'value': 'policy.updated', 'label': 'policy.updated'},
    {'value': 'backup.complete', 'label': 'backup.complete'},
    {'value': 'migration.complete', 'label': 'migration.complete'},
    {'value': 'migration.rollback', 'label': 'migration.rollback'},
  ];

  String _normalizeSev(String s) {
    final v = s.toLowerCase();
    if (v == 'critical' || v == 'error' || v == 'failed') return 'error';
    if (v == 'warning' || v == 'partial') return 'warning';
    return 'info';
  }

  String _relTime(String iso) {
    final m = DateTime.now().difference(DateTime.parse(iso)).inMinutes;
    if (m < 1) return 'just now';
    if (m < 60) return '${m}m ago';
    final h = m ~/ 60;
    if (h < 24) return '${h}h ago';
    return '${h ~/ 24}d ago';
  }

  /// Table timestamp — matches the web `fmtTs()` exactly: 2-digit day,
  /// short month name, numeric year (e.g. "17 Jul 2026") + 24h time.
  ({String date, String time}) _fmtTs(String iso) {
    final d = DateTime.parse(iso).toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final date = '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    return (date: date, time: time);
  }

  /// dd-mm-yyyy — used only by the From/To date-range filter fields.
  String _fmtDdMmYyyy(DateTime? d) {
    if (d == null) return 'dd-mm-yyyy';
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditProvider);
    final events = auditState.events;

    final criticalCount = events.where((e) => _normalizeSev(e.severity) == 'error').length;
    final uniqueActors = events.map((e) => e.actor).toSet().length;
    final last24h = events.where((e) => DateTime.now().difference(DateTime.parse(e.timestamp)).inHours < 24).length;

    final filtered = events.where((e) {
      if (_search.trim().isNotEmpty) {
        final q = _search.toLowerCase();
        final matches = e.actor.toLowerCase().contains(q) ||
            e.action.toLowerCase().contains(q) ||
            e.detail.toLowerCase().contains(q) ||
            (e.schoolName?.toLowerCase().contains(q) ?? false) ||
            e.actorIp.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (_actionFilter != '__all__' && e.action != _actionFilter) return false;
      if (_sevFilter != '__all__' && _normalizeSev(e.severity) != _sevFilter) return false;
      final ts = DateTime.parse(e.timestamp).toLocal();
      if (_fromDate != null) {
        final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (ts.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (ts.isAfter(to)) return false;
      }
      return true;
    }).toList();

    return SchoolTenancyLayout(
      currentPath: '/super-admin/audit',
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER — eyebrow + plain bold title (web audit/policies pattern)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Super Admin',
                              style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 12, fontWeight: FontWeight.w300)),
                          Text(' · Audit',
                              style: AppTextStyles.kpiLabel.copyWith(fontSize: 11, letterSpacing: 1.5)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Audit Log',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Immutable record of all platform-level actions', style: AppTextStyles.pageSubtitle),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.amberSoft,
                              border: Border.all(color: AppColors.amberBorder),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('Demo data', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh, size: 13),
                            label: const Text('Refresh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.borderPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                              minimumSize: Size.zero,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export CSV — not yet wired to a live API.')),
                              );
                            },
                            icon: const Icon(Icons.download, size: 13),
                            label: const Text('Export CSV'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.borderPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // KPI ROW (icon-led cards, no sparkline — matches web audit KpiCard).
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: IconStatCard(
                          label: 'Total Events',
                          value: '${events.length}',
                          sub: 'in loaded window',
                          icon: Icons.bolt,
                          iconBg: const Color(0xFFF5F3FF),
                          iconColor: const Color(0xFF9333EA),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: IconStatCard(
                          label: 'Critical / Error',
                          value: '$criticalCount',
                          sub: 'failed actions',
                          icon: Icons.cancel,
                          iconBg: const Color(0xFFFEF2F2),
                          iconColor: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: IconStatCard(
                          label: 'Unique Actors',
                          value: '$uniqueActors',
                          sub: 'distinct users',
                          icon: Icons.people_alt,
                          iconBg: const Color(0xFFF0F9FF),
                          iconColor: const Color(0xFF0EA5E9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: IconStatCard(
                          label: 'Last 24 Hours',
                          value: '$last24h',
                          sub: 'recent activity',
                          icon: Icons.access_time,
                          iconBg: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── LOG PANEL (toolbar + table) ─────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    border: Border.all(color: AppColors.borderPrimary),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toolbar
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.borderPrimary)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              onChanged: (v) => setState(() => _search = v),
                              decoration: InputDecoration(
                                hintText: 'Search actor, action, school, IP…',
                                hintStyle: AppTextStyles.sectionSubtitle.copyWith(fontSize: 12),
                                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textTertiary),
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.bgSecondary,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _filterBtn('All', _sevFilter == '__all__', () => setState(() => _sevFilter = '__all__')),
                                _filterBtn('Info', _sevFilter == 'info', () => setState(() => _sevFilter = 'info')),
                                _filterBtn('Warning', _sevFilter == 'warning', () => setState(() => _sevFilter = 'warning')),
                                _filterBtn('Critical', _sevFilter == 'error', () => setState(() => _sevFilter = 'error')),
                                _actionFilterBtn(),
                              ],
                            ),
                            if (_showActionOptions) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _actionOptions.map((opt) {
                                  final active = _actionFilter == opt['value'];
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _actionFilter = opt['value']!;
                                      _showActionOptions = false;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: active ? AppColors.purpleTint : AppColors.bgSecondary,
                                        border: Border.all(color: active ? AppColors.purpleSoft : AppColors.borderPrimary),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(opt['label']!,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.purpleDeep : AppColors.textSecondary)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text('DATE RANGE', style: AppTextStyles.kpiLabel.copyWith(fontSize: 9.5)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(child: _dateField('From', _fromDate, () => _pickDate(isFrom: true))),
                                const SizedBox(width: 8),
                                Expanded(child: _dateField('To', _toDate, () => _pickDate(isFrom: false))),
                                if (_fromDate != null || _toDate != null) ...[
                                  const SizedBox(width: 6),
                                  IconButton(
                                    onPressed: () => setState(() {
                                      _fromDate = null;
                                      _toDate = null;
                                    }),
                                    icon: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                                    tooltip: 'Clear date range',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${filtered.length} event${filtered.length == 1 ? '' : 's'}',
                                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table (header + rows share one horizontal scroll so columns stay aligned)
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.shield_outlined, size: 30, color: AppColors.textTertiary),
                                const SizedBox(height: 8),
                                Text('No events match the current filter', style: AppTextStyles.boardLabel.copyWith(fontSize: 12.5)),
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _search = '';
                                    _sevFilter = '__all__';
                                    _actionFilter = '__all__';
                                    _fromDate = null;
                                    _toDate = null;
                                  }),
                                  child: const Text('Clear all filters', style: TextStyle(fontSize: 12, color: AppColors.purpleDeep)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            children: [
                              _tableHeaderRow(),
                              for (final e in filtered) _tableDataRow(context, e),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.purpleTint : AppColors.bgSecondary,
          border: Border.all(color: active ? AppColors.purpleSoft : AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: active ? AppColors.purpleDeep : AppColors.textSecondary)),
      ),
    );
  }

  Widget _actionFilterBtn() {
    final active = _showActionOptions || _actionFilter != '__all__';
    return GestureDetector(
      onTap: () => setState(() => _showActionOptions = !_showActionOptions),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.purpleTint : AppColors.bgSecondary,
          border: Border.all(color: active ? AppColors.purpleSoft : AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined, size: 12, color: active ? AppColors.purpleDeep : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(_actionFilter != '__all__' ? _actionFilter : 'Action',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: active ? AppColors.purpleDeep : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$label: ${_fmtDdMmYyyy(value)}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: value != null ? 'monospace' : null,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                  color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderRow() {
    TextStyle headStyle = const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4);
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _colDot),
          const SizedBox(width: _colGap),
          SizedBox(width: _colTime, child: Text('TIME', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colActor, child: Text('ACTOR', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colAction, child: Text('ACTION', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colDetail, child: Text('DETAIL', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colIp, child: Text('IP ADDRESS', style: headStyle)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colSeverity, child: Text('SEVERITY', style: headStyle)),
        ],
      ),
    );
  }

  Widget _tableDataRow(BuildContext context, AuditEventEntity e) {
    final ts = _fmtTs(e.timestamp);
    final sevKey = _normalizeSev(e.severity);
    const dotColors = {'info': Color(0xFF38BDF8), 'warning': Color(0xFFFBBF24), 'error': Color(0xFFF87171)};

    return InkWell(
      onTap: () => _showDetail(context, e),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderPrimary)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(width: _colDot, height: _colDot, decoration: BoxDecoration(color: dotColors[sevKey], shape: BoxShape.circle)),
            ),
            const SizedBox(width: _colGap),
            SizedBox(
              width: _colTime,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ts.time, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(ts.date, style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: _colGap),
            SizedBox(
              width: _colActor,
              child: Text(e.actor,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const SizedBox(width: _colGap),
            SizedBox(width: _colAction, child: ActionBadge(action: e.action)),
            const SizedBox(width: _colGap),
            SizedBox(
              width: _colDetail,
              child: Text(e.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3)),
            ),
            const SizedBox(width: _colGap),
            SizedBox(
              width: _colIp,
              child: Text(e.actorIp, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textTertiary)),
            ),
            const SizedBox(width: _colGap),
            SizedBox(width: _colSeverity, child: SeverityBadge(severity: e.severity)),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, AuditEventEntity e) {
    final ts = _fmtTs(e.timestamp);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.borderSecondary, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EVENT DETAIL', style: AppTextStyles.kpiLabel),
                        Text('#${e.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [SeverityBadge(severity: e.severity), ActionBadge(action: e.action)]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bgSecondary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Timestamp', style: AppTextStyles.sectionSubtitle),
                        Text(_relTime(e.timestamp), style: AppTextStyles.boardLabel.copyWith(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${ts.date} ${ts.time}', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _detailSection('Actor', e.actor, sub: e.actorIp),
              if (e.schoolName != null) ...[
                const SizedBox(height: 14),
                _detailSection('School', e.schoolName!, sub: e.tenantId),
              ],
              const SizedBox(height: 14),
              _detailSection('Detail', e.detail),
              const SizedBox(height: 14),
              Text('STATUS', style: AppTextStyles.kpiLabel),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: e.status == 'success' ? AppColors.greenSoft : e.status == 'partial' ? AppColors.amberSoft : AppColors.redSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(e.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: e.status == 'success' ? const Color(0xFF0A6638) : e.status == 'partial' ? const Color(0xFF92400E) : AppColors.dangerRed)),
              ),
              if (e.errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.redSoft, border: Border.all(color: AppColors.redBorder), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ERROR', style: AppTextStyles.kpiLabel.copyWith(color: AppColors.dangerRed)),
                      const SizedBox(height: 4),
                      Text(e.errorMessage!, style: TextStyle(fontSize: 12, color: AppColors.dangerRed, height: 1.4)),
                    ],
                  ),
                ),
              ],
              if (e.affectedFields != null && e.affectedFields!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('CHANGED FIELDS', style: AppTextStyles.kpiLabel),
                const SizedBox(height: 6),
                ...e.affectedFields!.map((f) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.bgSecondary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f, style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          if (e.beforeValues?[f] != null)
                            Text('${e.beforeValues![f]}', style: const TextStyle(fontSize: 11, color: AppColors.dangerRed, decoration: TextDecoration.lineThrough)),
                          if (e.afterValues?[f] != null)
                            Text('${e.afterValues![f]}', style: const TextStyle(fontSize: 11, color: Color(0xFF0A6638))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String label, String value, {String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.kpiLabel),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textTertiary)),
        ],
      ],
    );
  }
}
