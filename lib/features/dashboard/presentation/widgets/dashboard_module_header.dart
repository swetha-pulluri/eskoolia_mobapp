import 'package:flutter/material.dart';
import '../../domain/entities/module_entity.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk2 = Color(0xFF5A607A);
const _subPurple = Color(0xFF6D4AFF);

/// Static header bar for the Dashboard module, shown only on
/// [SchoolOverviewPage] — same visual structure as [ModuleSubNav] elsewhere
/// in the app (module icon + name, a divider, then its section(s)), but
/// hardcoded here: the Dashboard module has exactly one real section,
/// "School Overview" (confirmed against frontend's `lib/routes.ts`, whose
/// `dashboard` entry has `sub: []`, and its single
/// `app/(dashboard)/dashboard/page.tsx`) — so unlike `ModuleSubNav` there is
/// nothing to switch between; "School Overview" is shown already
/// active/current, matching how every other module's sub-nav highlights
/// whichever section is open.
class DashboardModuleHeader extends StatelessWidget {
  const DashboardModuleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final module = Modules.findById('dashboard')!;

    // Mounted as this page's own first sliver, directly below
    // `GlobalAppShell`'s persistent top bar — same reasoning as
    // `ModuleSubNav` needing its own `Material` ancestor for its `InkWell`
    // (not applicable here since there's no tap target, but the
    // `Container`s below remain the sole paint source either way).
    return Container(
      height: 46,
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _navBorder))),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: module.bgColor, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: module.iconAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(module.iconAsset!, fit: BoxFit.contain),
                  )
                : Icon(module.icon, size: 13, color: module.iconColor),
          ),
          const SizedBox(width: 8),
          Text(module.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _navInk2)),
          const SizedBox(width: 12),
          Container(width: 1, height: 20, color: _navBorder),
          Container(
            height: 46,
            padding: const EdgeInsets.fromLTRB(14, 1, 14, 0),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _subPurple, width: 2))),
            alignment: Alignment.center,
            child: const Text(
              'School Overview',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _subPurple),
            ),
          ),
        ],
      ),
    );
  }
}
