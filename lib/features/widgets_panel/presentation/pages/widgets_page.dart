import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/widget_def_entity.dart';
import '../providers/widget_prefs_provider.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk2 = Color(0xFF5A607A);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);

/// Bottom-nav "Widgets" tab — full-page version of the Home-screen widget
/// toggle list that used to live behind the header's popup widget-manager
/// button (now removed in favor of this dedicated tab). Same data source
/// and persistence as before ([widgetPrefsProvider] /
/// [currentPortalRoleProvider] / [widgetsForRole]) — only the presentation
/// (a full page instead of a bottom sheet) changed.
class WidgetsPage extends ConsumerWidget {
  const WidgetsPage({super.key});

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Customize Widgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _navInk1)),
            const SizedBox(height: 4),
            const Text('Choose which widgets appear on your Home screen', style: TextStyle(fontSize: 12.5, color: _navInk3)),
            const SizedBox(height: 20),
            _section(leftLabel, leftWidgets, prefs, ref),
            const SizedBox(height: 20),
            _section(rightLabel, rightWidgets, prefs, ref),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _navBorder),
            const SizedBox(height: 10),
            const Text(
              'Changes take effect immediately on the Home screen',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: _navInk3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<WidgetDefEntity> widgets, Map<String, bool> prefs, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: _navInk3)),
        const SizedBox(height: 8),
        for (final w in widgets) _row(w, prefs[w.id] ?? w.defaultEnabled, ref),
      ],
    );
  }

  Widget _row(WidgetDefEntity w, bool enabled, WidgetRef ref) {
    final showSoon = w.comingSoon || (w.disabled && !w.comingSoon);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _navBorder),
      ),
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
                    Flexible(
                      child: Text(
                        w.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navInk1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                const SizedBox(height: 2),
                Text(w.description, style: const TextStyle(fontSize: 11, color: _navInk2), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: w.disabled ? null : (_) => ref.read(widgetPrefsProvider.notifier).toggle(w.id),
            activeThumbColor: _navPurple,
          ),
        ],
      ),
    );
  }
}
