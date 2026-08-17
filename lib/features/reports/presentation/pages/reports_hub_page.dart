import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_definition_entity.dart';

class _ModuleMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _ModuleMeta(this.label, this.icon, this.color);
}

/// Matches web's `MODULE_META` map (`app/(dashboard)/reports/page.tsx`)
/// exactly — label/icon/color per module key (the report key's first
/// "/"-segment).
const _kModuleMeta = <String, _ModuleMeta>{
  'students': _ModuleMeta('Student Reports', Icons.people_outline, Color(0xFF3B82F6)),
  'fees': _ModuleMeta('Fees Reports', Icons.payments_outlined, Color(0xFF10B981)),
  'accounts': _ModuleMeta('Accounts Reports', Icons.account_balance_outlined, Color(0xFFF59E0B)),
  'academics': _ModuleMeta('Academics Reports', Icons.school_outlined, Color(0xFF8B5CF6)),
  'academic': _ModuleMeta('Academic Reports', Icons.school_outlined, Color(0xFF8B5CF6)),
  'examination': _ModuleMeta('Examination Reports', Icons.assignment_outlined, Color(0xFFEC4899)),
  'hr': _ModuleMeta('HR Reports', Icons.work_outline, Color(0xFFEF4444)),
  'library': _ModuleMeta('Library Reports', Icons.menu_book_outlined, Color(0xFF06B6D4)),
  'transport': _ModuleMeta('Transport Reports', Icons.directions_bus_outlined, Color(0xFF6366F1)),
  'dormitory': _ModuleMeta('Dormitory Reports', Icons.apartment_outlined, Color(0xFF0EA5E9)),
  'inventory': _ModuleMeta('Inventory Reports', Icons.inventory_2_outlined, Color(0xFF84CC16)),
  'behaviour': _ModuleMeta('Behaviour Reports', Icons.warning_amber_outlined, Color(0xFFDC2626)),
};

/// Reports Hub — mirrors web's `app/(dashboard)/reports/page.tsx` exactly:
/// what actually renders when the Reports module icon itself is tapped
/// (as opposed to one of its 13 sub-nav items). Derived directly from
/// `kReportDefinitions` (the single source of truth also used by the
/// Explorer engine) rather than a separately maintained title list, so the
/// two can never drift apart. Modules sorted alphabetically by key,
/// matching web's `Object.keys(groups).sort()` exactly.
class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  Map<String, List<ReportDefinitionEntity>> _groupedByModule() {
    final groups = <String, List<ReportDefinitionEntity>>{};
    for (final def in kReportDefinitions.values) {
      final module = def.key.split('/').first;
      (groups[module] ??= []).add(def);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedByModule();
    final moduleKeys = groups.keys.toList()..sort();
    final totalReports = kReportDefinitions.length;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('$totalReports reports across ${moduleKeys.length} modules', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 20.0;
                  // Matches web's `repeat(auto-fill, minmax(300px, 1fr))` —
                  // as many 300px+ columns as fit, minimum 1.
                  final columns = (constraints.maxWidth / 300).floor().clamp(1, 4);
                  final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final moduleKey in moduleKeys)
                        SizedBox(width: cardWidth, child: _groupCard(context, moduleKey, groups[moduleKey]!)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupCard(BuildContext context, String moduleKey, List<ReportDefinitionEntity> defs) {
    final meta = _kModuleMeta[moduleKey] ?? _ModuleMeta('${moduleKey[0].toUpperCase()}${moduleKey.substring(1)} Reports', Icons.bar_chart_outlined, const Color(0xFF6B7280));
    return Container(
      decoration: BoxDecoration(color: AppColors.bgPrimary, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderPrimary))),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: meta.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
                  child: Icon(meta.icon, size: 16, color: meta.color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(meta.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < defs.length; i++)
                  InkWell(
                    onTap: () => context.push('/reports/${defs[i].key}'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(border: Border(bottom: i == defs.length - 1 ? BorderSide.none : const BorderSide(color: AppColors.borderPrimary))),
                      child: Text(defs[i].title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
