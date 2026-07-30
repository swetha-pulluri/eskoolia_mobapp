import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/school_entity.dart';
import '../providers/school_tenancy_provider.dart';

/// Real, verbatim label maps from web's
/// `/super-admin/schools/[tenantId]/page.tsx` — used to show a human name
/// for the raw codes the backend stores, exactly matching web's own
/// `BOARD_LABELS`/`STATE_LABELS`/`REGION_LABELS` (including which codes
/// each one covers; anything outside these falls back to the raw value,
/// same as web's `LABELS[code] ?? code`).
const _kBoardLabels = {
  'CBSE': 'CBSE',
  'ICSE': 'ICSE',
  'SSC_TG': 'SSC TG',
  'SSC_AP': 'SSC AP',
  'OTHER': 'Other',
};
const _kStateLabels = {
  '36': 'Telangana',
  '37': 'Andhra Pradesh',
  '29': 'Karnataka',
  '33': 'Tamil Nadu',
  '27': 'Maharashtra',
  '07': 'Delhi',
  '09': 'Uttar Pradesh',
  '06': 'Haryana',
  '08': 'Rajasthan',
  '19': 'West Bengal',
  '21': 'Odisha',
  '32': 'Kerala',
  '24': 'Gujarat',
};
const _kRegionLabels = {
  'ap-south-1': 'Asia Pacific — Mumbai',
  'ap-southeast-1': 'Asia Pacific — Singapore',
  'us-east-1': 'US East — N. Virginia',
  'eu-west-1': 'Europe — Ireland',
};

String _schoolInitials(String name) {
  final words = name.split(' ').where((w) => w.isNotEmpty).take(2);
  return words.map((w) => w[0]).join().toUpperCase();
}

/// School detail screen — mirrors web's `/super-admin/schools/[tenantId]`
/// page field-for-field (`SectionCard`/`InfoRow` layout, action set, and
/// label maps), backed by the same `getSchool()` the Edit form already
/// uses. Reached by tapping a school card/name or its "Open" action on the
/// Schools list (`schools_tab.dart`).
class SchoolDetailPage extends ConsumerStatefulWidget {
  final String tenantId;

  const SchoolDetailPage({super.key, required this.tenantId});

  @override
  ConsumerState<SchoolDetailPage> createState() => _SchoolDetailPageState();
}

class _SchoolDetailPageState extends ConsumerState<SchoolDetailPage> {
  bool _busy = false;

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleStatusChange(SchoolEntity school, String newStatus) async {
    setState(() => _busy = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      await repository.updateSchoolStatus(school.tenantId, newStatus);
      ref.invalidate(schoolDetailProvider(widget.tenantId));
      ref.invalidate(schoolsProvider);
      ref.invalidate(schoolsGlobalStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newStatus == 'active' ? '${school.name} reactivated.' : '${school.name} suspended.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleResetPassword(SchoolEntity school) async {
    setState(() => _busy = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final result = await repository.resetSchoolAdminPassword(school.tenantId);
      if (mounted) await _showCredentialsDialog(school, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCredentialsDialog(SchoolEntity school, ResetAdminPasswordResultEntity result) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Admin Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(school.name, style: AppTextStyles.sectionSubtitle),
            const SizedBox(height: 8),
            const Text('Shown once only. Copy these now — they will not be shown again.',
                style: TextStyle(fontSize: 11.5, color: AppColors.warningAmber)),
            const SizedBox(height: 12),
            Text('Username: ${result.adminUsername}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 4),
            Text('Password: ${result.adminPassword}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${result.adminUsername}\n${result.adminPassword}'));
              Navigator.pop(context);
            },
            child: const Text('Copy & close'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Navigates to the dedicated Edit School screen — mirrors web's own
  /// separate `/super-admin/schools/{tenantId}/edit` route/page, which has
  /// its own distinct 5-section field set, not the 9-section "Add a new
  /// school" wizard.
  void _openEdit(SchoolEntity school) => context.go('/super-admin/schools/${school.tenantId}/edit');

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(schoolDetailProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: schoolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load school.\n$error', textAlign: TextAlign.center, style: AppTextStyles.pageSubtitle),
          ),
        ),
        data: (school) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/super-admin/schools'),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('Back to Schools'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary, padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 12),
                _header(school),
                const SizedBox(height: 18),
                _section('Identity & Plan', [
                  _row('School name', school.name),
                  _row('Short code', school.shortCode),
                  _row('Subdomain URL', school.subdomainUrl.isNotEmpty ? '${school.subdomainUrl}.eskoolia.com' : null),
                  _row('Plan', school.plan.isNotEmpty ? _capitalize(school.plan) : null),
                  _row('Status', school.status.isNotEmpty ? _capitalize(school.status) : null),
                  _row('Seats', school.seats),
                  _rowBool('API access', school.apiAccess),
                  _row('SSO method', school.ssoMethod),
                ]),
                _section('Academic & Geography', [
                  _row('Board', school.board == null ? null : (_kBoardLabels[school.board] ?? school.board)),
                  _row('State', school.state == null ? null : (_kStateLabels[school.state] ?? school.state)),
                  _row('Region', school.region == null ? null : _capitalize(school.region!)),
                  _row('UDISE code', school.udiseCode),
                ]),
                _section('GST & Legal', [
                  _row('GSTIN', school.gstin),
                  _row('PAN', school.pan),
                ]),
                _section('Infrastructure', [
                  _row('Shard region', _kRegionLabels[school.shardRegion] ?? school.shardRegion),
                  _row('Storage region', _kRegionLabels[school.storageRegion] ?? school.storageRegion),
                  _row('Backup retention', '${school.backupRetention} days'),
                  _row('Provisioned at', _formatDate(school.provisionedAt)),
                ]),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go('/super-admin/schools'),
                      child: const Text('← Back to Schools'),
                    ),
                    if (school.status != 'archived')
                      ElevatedButton.icon(
                        onPressed: _busy ? null : () => _openEdit(school),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit School'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(SchoolEntity school) {
    final isSuspended = school.status == 'suspended';
    final isArchived = school.status == 'archived';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 16,
        runSpacing: 12,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.getAvatarGradient(school.tenantId),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _schoolInitials(school.name),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(school.name, style: AppTextStyles.pageTitle.copyWith(fontSize: 18)),
                    _statusBadge(school.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  school.subdomainUrl.isNotEmpty
                      ? '${school.tenantId} · ${school.subdomainUrl}.eskoolia.com'
                      : school.tenantId,
                  style: AppTextStyles.sectionSubtitle.copyWith(fontFamily: 'monospace', fontSize: 11.5),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isSuspended)
                _actionButton('Reactivate', Icons.restart_alt, _busy ? null : () => _handleStatusChange(school, 'active'), primary: true)
              else if (!isArchived)
                _actionButton('Suspend', Icons.pause_circle_outline, _busy ? null : () async {
                  if (await _confirm('Suspend school', 'Suspend ${school.name}? Their admin console access will be blocked.')) {
                    await _handleStatusChange(school, 'suspended');
                  }
                }),
              if (!isArchived)
                _actionButton('Reset Admin Password', Icons.key_outlined, _busy ? null : () => _handleResetPassword(school)),
              if (!isArchived)
                _actionButton('Edit School', Icons.edit_outlined, _busy ? null : () => _openEdit(school), primary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    const config = {
      'active': (Color(0xFF0D7A55), Color(0xFFDCFCE7)),
      'trial': (Color(0xFFB45309), Color(0xFFFEF3C7)),
      'suspended': (Color(0xFFDC2626), Color(0xFFFEE2E2)),
      'onboarding': (Color(0xFF0369A1), Color(0xFFDBEAFE)),
      'archived': (Color(0xFF6B7280), Color(0xFFF3F4F6)),
    };
    final (dot, bg) = config[status] ?? (const Color(0xFF6B7280), const Color(0xFFF3F4F6));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(_capitalize(status), style: TextStyle(color: dot, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.bgSecondary,
              child: Text(
                title.toUpperCase(),
                style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: rows),
            ),
          ],
        ),
      ),
    );
  }

  /// Matches web's `InfoRow` exactly: `null`/empty → em-dash, otherwise the
  /// raw value stringified as-is (so `0` genuinely shows `"0"`, not a dash).
  Widget _row(String label, Object? value) {
    final display = (value == null || value == '') ? '—' : value.toString();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600))),
          Expanded(child: Text(display, style: AppTextStyles.boardLabel.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _rowBool(String label, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 0.5))),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600))),
          Text(
            value ? 'Enabled' : 'Disabled',
            style: TextStyle(fontSize: 13, fontWeight: value ? FontWeight.w600 : FontWeight.w400, color: value ? AppColors.successGreen : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback? onPressed, {bool primary = false}) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.borderPrimary)),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour12:$minute $period';
  }
}
