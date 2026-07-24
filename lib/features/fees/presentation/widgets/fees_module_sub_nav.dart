import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mirrors frontend `components/nav/ModuleSubNav.tsx` for the Fees module
/// specifically (`MODULES.find(m => m.id === 'fees').sub` in
/// `lib/routes.ts`): a fixed module-label chip (icon + "Fees", using the
/// module's own `bg`/`ic` tokens `#ECFEFF`/`#0E7490`) followed by
/// horizontally-scrollable underline tabs in the shared purple accent
/// (`--pu` `#6D4AFF`) — none of Fees' tabs are in `COMING_SOON_PATHS`, so
/// none carry a "Soon" badge, unlike Academics'.
enum FeesModuleTab { home, configuration, assignment, collection, duesReminders, yearEnd }

class FeesModuleSubNav extends StatelessWidget {
  final FeesModuleTab active;

  const FeesModuleSubNav({super.key, required this.active});

  static const _tabs = [
    (FeesModuleTab.home, 'Home', Icons.grid_view_outlined, '/fees/payments'),
    (FeesModuleTab.configuration, 'Fee Configuration', Icons.settings_outlined, '/fees/configuration'),
    (FeesModuleTab.assignment, 'Fee Assignment', Icons.assignment_outlined, '/fees/fee-assignment'),
    (FeesModuleTab.collection, 'Collection', Icons.credit_card_outlined, '/fees/collection'),
    (FeesModuleTab.duesReminders, 'Dues & Reminders', Icons.error_outline, '/fees/dues-reminders'),
    (FeesModuleTab.yearEnd, 'Year-End', Icons.calendar_month_outlined, '/fees/year-end'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECECF2))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 8, right: 12),
            margin: const EdgeInsets.only(right: 7),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFECECF2))),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFECFEFF), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.payment_outlined, size: 11, color: Color(0xFF0E7490)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Fees',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5A607A)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [for (final tab in _tabs) _tabButton(context, tab.$1, tab.$2, tab.$3, tab.$4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(BuildContext context, FeesModuleTab tab, String label, IconData icon, String path) {
    final isActive = tab == active;
    return InkWell(
      onTap: isActive ? null : () => context.go(path),
      child: Container(
        height: 46,
        padding: const EdgeInsets.fromLTRB(14, 1, 14, 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? const Color(0xFF6D4AFF) : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? const Color(0xFF6D4AFF) : const Color(0xFF5A607A)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF6D4AFF) : const Color(0xFF5A607A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
