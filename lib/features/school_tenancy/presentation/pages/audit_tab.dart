import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kpi_card.dart';
import '../../../../core/widgets/action_badge_widget.dart';
import '../../domain/entities/audit_entity.dart';
import '../providers/school_tenancy_provider.dart';
import '../widgets/school_tenancy_layout.dart';

/// Matches web's `normalizeSev` (`audit/page.tsx:19-23`).
String _normalizeSeverity(String s) {
  final v = s.toLowerCase();
  if (v == 'critical' || v == 'error' || v == 'failed') return 'error';
  if (v == 'warning' || v == 'partial') return 'warning';
  return 'info';
}

/// Super Admin Audit Log Page
/// Exact conversion of web frontend audit structure
class SuperAdminAuditPage extends ConsumerStatefulWidget {
  const SuperAdminAuditPage({super.key});

  @override
  ConsumerState<SuperAdminAuditPage> createState() => _SuperAdminAuditPageState();
}

class _SuperAdminAuditPageState extends ConsumerState<SuperAdminAuditPage> {
  String _searchQuery = '';
  String _severityFilter = 'all';

  String _relativeTime(String timestamp) {
    final diff = DateTime.now().difference(DateTime.parse(timestamp));
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(auditProvider);

    if (auditAsync.isLoading && !auditAsync.hasValue) {
      return const SchoolTenancyLayout(
        currentPath: '/super-admin/audit',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (auditAsync.hasError && !auditAsync.hasValue) {
      return SchoolTenancyLayout(
        currentPath: '/super-admin/audit',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load audit log.\n${auditAsync.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageSubtitle,
            ),
          ),
        ),
      );
    }

    final auditState = auditAsync.value!;
    final refreshing = auditAsync.isLoading;

    // Calculate stats — matches web's `kpis` (`audit/page.tsx:190-199`)
    final criticalCount = auditState.events.where((e) => _normalizeSeverity(e.severity) == 'error').length;
    final uniqueActors = auditState.events.map((e) => e.actor).toSet().length;
    final last24h = auditState.events
        .where((e) => DateTime.now().difference(DateTime.parse(e.timestamp)).inHours < 24)
        .length;

    // Apply filters — matches web's `filtered` (`audit/page.tsx:202-224`),
    // including school_name/actor_ip in the search match.
    final searchQuery = _searchQuery.toLowerCase();
    final filteredEvents = auditState.events.where((event) {
      final matchesSearch = searchQuery.isEmpty ||
          event.actor.toLowerCase().contains(searchQuery) ||
          event.action.toLowerCase().contains(searchQuery) ||
          event.detail.toLowerCase().contains(searchQuery) ||
          (event.schoolName?.toLowerCase().contains(searchQuery) ?? false) ||
          event.actorIp.toLowerCase().contains(searchQuery);

      final matchesSeverity = _severityFilter == 'all' ||
          (_severityFilter == 'critical' && _normalizeSeverity(event.severity) == 'error') ||
          (_severityFilter == 'warning' && _normalizeSeverity(event.severity) == 'warning') ||
          (_severityFilter == 'info' && _normalizeSeverity(event.severity) == 'info');

      return matchesSearch && matchesSeverity;
    }).toList();

    return SchoolTenancyLayout(
      currentPath: '/super-admin/audit',
      child: Container(
        color: AppColors.bgSecondary,
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PAGE HEADER
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: [
                        Text('Audit', style: AppTextStyles.pageTitle),
                        Text('Log', style: AppTextStyles.pageTitleAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Immutable record of all platform-level actions',
                      style: AppTextStyles.pageSubtitle,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: refreshing ? null : () => ref.invalidate(auditProvider),
                          icon: refreshing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 14),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.buttonSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CSV export is not yet available on mobile.')),
                          ),
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text('Export CSV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: AppTextStyles.buttonSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // KPI CARDS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  KpiCard(
                    label: 'Total Events',
                    value: '${auditState.events.length}',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF5836E0),
                    trend: 'in loaded window',
                    trendColor: AppColors.textTertiary,
                    footnote: 'All events',
                  ),
                  KpiCard(
                    label: 'Critical / Error',
                    value: '$criticalCount',
                    sparklineData: const [14, 11, 13, 9, 12, 8, 10, 7, 9, 6, 8, 5, 7, 4],
                    sparklineColor: const Color(0xFFE0463A),
                    trend: 'failed actions',
                    trendColor: AppColors.dangerRed,
                    footnote: 'High severity',
                  ),
                  KpiCard(
                    label: 'Unique Actors',
                    value: '$uniqueActors',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0369A1),
                    trend: 'distinct users',
                    trendColor: AppColors.infoBlue,
                    footnote: 'All actors',
                  ),
                  KpiCard(
                    label: 'Last 24 Hours',
                    value: '$last24h',
                    sparklineData: const [4, 7, 5, 9, 6, 11, 8, 10, 9, 13, 10, 12, 11, 14],
                    sparklineColor: const Color(0xFF0E9F6E),
                    trend: 'recent activity',
                    trendColor: AppColors.successGreen,
                    footnote: 'Today',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SEARCH BAR
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search actor, action, school, IP…',
                  hintStyle: AppTextStyles.sectionSubtitle,
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // FILTER BUTTONS
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterButton('All', 'all'),
                  _buildFilterButton('Critical', 'critical'),
                  _buildFilterButton('Warning', 'warning'),
                  _buildFilterButton('Info', 'info'),
                ],
              ),

              const SizedBox(height: 20),

              // EVENTS LIST
              Text(
                'Events (${filteredEvents.length})',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border.all(color: AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: filteredEvents.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.shield_outlined, size: 28, color: AppColors.textTertiary),
                              const SizedBox(height: 10),
                              Text('No events match the current filter', style: AppTextStyles.boardLabel.copyWith(fontSize: 13)),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () => setState(() {
                                  _searchQuery = '';
                                  _severityFilter = 'all';
                                }),
                                child: const Text('Clear all filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderPrimary),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return InkWell(
                      onTap: () => _showEventDetail(context, event),
                      child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action badge and timestamp
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ActionBadge(
                                action: event.action,
                                color: AppColors.primaryPurple,
                              ),
                              const Spacer(),
                              Text(
                                _relativeTime(event.timestamp),
                                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Detail
                          Text(
                            event.detail,
                            style: AppTextStyles.boardLabel.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 8),

                          // Actor and severity
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.actor,
                                  style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace'),
                                ),
                              ),
                              SeverityBadge(severity: event.severity),
                            ],
                          ),

                          // IP Address — matches web's "IP Address" column
                          // (`audit/page.tsx:352`), previously never shown.
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.lan_outlined, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                event.actorIp.isEmpty ? '—' : event.actorIp,
                                style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 11),
                              ),
                            ],
                          ),

                          if (event.schoolName != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.business_outlined, size: 14, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  event.schoolName!,
                                  style: AppTextStyles.sectionSubtitle,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      ),
                    );
                  },
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

  /// Mobile bottom-sheet equivalent of web's Event Detail side panel
  /// (`audit/page.tsx:412-508`) — same content (badges, timestamp, actor,
  /// school, detail, status, error, changed-fields diff), adapted from a
  /// desktop side panel to a bottom sheet for mobile.
  void _showEventDetail(BuildContext context, AuditEventEntity event) {
    final timestamp = DateTime.parse(event.timestamp);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EVENT DETAIL', style: AppTextStyles.sectionSubtitle.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                          Text('#${event.id}', style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 11)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      SeverityBadge(severity: event.severity),
                      ActionBadge(action: event.action, color: AppColors.primaryPurple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailBlock('Timestamp', '${_relativeTime(event.timestamp)}\n${timestamp.toLocal()}'),
                  _detailBlock('Actor', event.actorIp.isEmpty ? event.actor : '${event.actor}\n${event.actorIp}'),
                  if (event.schoolName != null)
                    _detailBlock('School', event.tenantId != null ? '${event.schoolName}\n${event.tenantId}' : event.schoolName!),
                  _detailBlock('Detail', event.detail),
                  const SizedBox(height: 4),
                  Text('STATUS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(event.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _statusColor(event.status).withValues(alpha: 0.3)),
                    ),
                    child: Text(event.status, style: AppTextStyles.chipLabel(color: _statusColor(event.status))),
                  ),
                  if (event.errorMessage != null && event.errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.redSoft,
                        border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ERROR', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.dangerRed)),
                          const SizedBox(height: 4),
                          Text(event.errorMessage!, style: AppTextStyles.boardLabel.copyWith(fontSize: 12, color: AppColors.dangerRed)),
                        ],
                      ),
                    ),
                  ],
                  if (event.affectedFields != null && event.affectedFields!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('CHANGED FIELDS', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    ...event.affectedFields!.map((field) {
                      final before = event.beforeValues?[field];
                      final after = event.afterValues?[field];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          border: Border.all(color: AppColors.borderPrimary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field, style: AppTextStyles.boardLabel.copyWith(fontFamily: 'monospace', fontSize: 12)),
                            if (before != null)
                              Text('$before', style: const TextStyle(color: AppColors.dangerRed, decoration: TextDecoration.lineThrough, fontSize: 12)),
                            if (after != null)
                              Text('$after', style: const TextStyle(color: AppColors.successGreen, fontSize: 12)),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.boardLabel.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return AppColors.successGreen;
      case 'partial':
        return AppColors.warningAmber;
      default:
        return AppColors.dangerRed;
    }
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _severityFilter == value;
    return OutlinedButton(
      onPressed: () => setState(() => _severityFilter = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.purpleTint : AppColors.bgSecondary,
        side: BorderSide(
          color: isSelected ? AppColors.purpleSoft : AppColors.borderPrimary,
        ),
        foregroundColor: isSelected ? AppColors.purpleDeep : AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}
