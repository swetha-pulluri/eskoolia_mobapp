// NOTE: Toggling a widget here only persists the on/off preference via
// widgetPrefsProvider. Rendering the ~13 actual left/right rail widget
// cards on the Home screen (frontend's LeftRail/RightRail equivalents) is
// an explicitly deferred, separate future task — this pass only ports the
// management UI + persistence, matching web's WidgetManager.tsx/
// widgetStore.ts, not the rail components themselves.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/widget_def_entity.dart';
import '../providers/widget_prefs_provider.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk2 = Color(0xFF5A607A);
const _navInk3 = Color(0xFF9197AE);

/// Opened from Teacher Portal's header `WidgetManagerButton` — Admin
/// manages the same [widgetPrefsProvider] preferences via its own full-page
/// `WidgetsPage` bottom-nav tab instead of this bottom sheet.
Future<void> showWidgetManagerPanel(BuildContext navContext) {
  return showModalBottomSheet(
    context: navContext,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => const _WidgetManagerPanelContent(),
  );
}

class _WidgetManagerPanelContent extends ConsumerWidget {
  const _WidgetManagerPanelContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentPortalRoleProvider);
    final prefs = ref.watch(widgetPrefsProvider);
    final widgets = widgetsForRole(role);
    final leftWidgets = widgets.where((w) => w.rail == 'left').toList();
    final rightWidgets = widgets.where((w) => w.rail == 'right').toList();

    final String leftLabel;
    final String rightLabel;
    switch (role) {
      case 'teacher':
        leftLabel = 'My Day';
        rightLabel = 'My Tools';
        break;
      case 'parent':
        leftLabel = 'Child Summary';
        rightLabel = 'School Info';
        break;
      default:
        leftLabel = "Today's Pulse";
        rightLabel = 'Admin Cockpit';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 16, color: _navInk1),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Customize Widgets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navInk1)),
                      Text('Widgets only appear on the Home screen', style: TextStyle(fontSize: 11, color: _navInk3)),
                    ],
                  ),
                ),
                InkWell(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, size: 16, color: _navInk3)),
              ],
            ),
          ),
          const Divider(height: 1, color: _navBorder),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _section(leftLabel, leftWidgets, prefs, ref),
                const SizedBox(height: 16),
                _section(rightLabel, rightWidgets, prefs, ref),
              ],
            ),
          ),
          const Divider(height: 1, color: _navBorder),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Changes take effect immediately on the home screen', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: _navInk3)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<WidgetDefEntity> widgets, Map<String, bool> prefs, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: _navInk3)),
        const SizedBox(height: 6),
        for (final w in widgets) _row(w, prefs[w.id] ?? w.defaultEnabled, ref),
      ],
    );
  }

  Widget _row(WidgetDefEntity w, bool enabled, WidgetRef ref) {
    final showSoon = w.comingSoon || (w.disabled && !w.comingSoon);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(w.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(w.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navInk1)),
                    if (showSoon) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFF6D28D9), borderRadius: BorderRadius.circular(999)),
                        child: const Text('Soon', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                Text(w.description, style: const TextStyle(fontSize: 11, color: _navInk2)),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: w.disabled ? null : (_) => ref.read(widgetPrefsProvider.notifier).toggle(w.id),
            activeThumbColor: const Color(0xFF6D4AFF),
          ),
        ],
      ),
    );
  }
}
