import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../providers/widget_prefs_provider.dart';
import 'widget_manager_panel.dart';

const _navInk2 = Color(0xFF5A607A);

/// Header "Widgets" button — badge shows how many widgets are currently
/// enabled for the user's role. Only rendered when on the Home screen,
/// matching web's `{isHome && <WidgetManager/>}`.
class WidgetManagerButton extends ConsumerWidget {
  const WidgetManagerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(enabledWidgetCountProvider);
    // Drops the "Widgets" text label below a narrow-phone width so this
    // button can't push the trailing header cluster (notifications,
    // avatar) into overflow — same collapse strategy as `_SearchTrigger`,
    // just at a lower threshold since this button sits further right and
    // has less room to give before the header runs out of space.
    final showLabel = MediaQuery.sizeOf(context).width >= 420;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: const Color(0xFF6D4AFF), borderRadius: BorderRadius.circular(999)),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );

    return InkWell(
      onTap: () {
        final navContext = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
        if (navContext == null) return;
        showWidgetManagerPanel(navContext);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: showLabel ? 10 : 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, size: 14, color: _navInk2),
            if (showLabel) ...[
              const SizedBox(width: 6),
              const Text('Widgets', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: _navInk2)),
            ],
            const SizedBox(width: 6),
            badge,
          ],
        ),
      ),
    );
  }
}
