import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);
const _navPurpleDeep = Color(0xFF4F35CC);

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0]).join().toUpperCase();
}

/// Header child picker pill — Flutter port of web's `ChildSwitcher` in
/// `(parent-portal)/layout.tsx`: avatar + first name + class/roll, opening a
/// bottom sheet to switch when the guardian has more than one child (a
/// mobile-idiomatic stand-in for web's hover dropdown).
class ChildSwitcher extends ConsumerWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(parentMeProvider).valueOrNull;
    final selected = ref.watch(selectedChildProvider);
    if (me == null || selected == null) return const SizedBox.shrink();

    final hasMultiple = me.children.length > 1;

    return InkWell(
      onTap: hasMultiple ? () => _openSheet(context, ref, me.children, selected.id) : null,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 34,
        padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
        decoration: BoxDecoration(color: const Color(0xFFF4F4F8), borderRadius: BorderRadius.circular(99), border: Border.all(color: _navBorder)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(child: selected, radius: 13),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected.name.split(' ').first,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _navInk1, height: 1.1),
                ),
                Text(
                  [selected.classSectionLabel, if ((selected.rollNo ?? '').isNotEmpty) 'Roll ${selected.rollNo}'].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: _navInk3, letterSpacing: 0.3, height: 1.1),
                ),
              ],
            ),
            if (hasMultiple) ...[
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 14, color: _navInk3),
            ],
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, List<ChildSummaryEntity> children, int selectedId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Text('SWITCH CHILD', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _navInk3, letterSpacing: 0.6)),
                  ],
                ),
              ),
              for (final c in children)
                ListTile(
                  onTap: () {
                    ref.read(selectedChildIdProvider.notifier).select(c.id);
                    Navigator.of(sheetContext).pop();
                  },
                  leading: _Avatar(child: c, radius: 16, highlighted: c.id == selectedId),
                  title: Text(c.name, style: TextStyle(fontSize: 13.5, fontWeight: c.id == selectedId ? FontWeight.w700 : FontWeight.w400, color: _navInk1)),
                  subtitle: Text(c.classSectionLabel, style: const TextStyle(fontSize: 11.5, color: _navInk3)),
                  trailing: c.id == selectedId ? const Icon(Icons.check, size: 16, color: _navPurple) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ChildSummaryEntity child;
  final double radius;
  final bool highlighted;

  const _Avatar({required this.child, required this.radius, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    if (child.photoUrl != null && child.photoUrl!.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(child.photoUrl!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: highlighted ? _navPurple : _navPurpleDeep,
      child: Text(
        _initials(child.name),
        style: TextStyle(color: Colors.white, fontSize: radius * 0.75, fontWeight: FontWeight.w700),
      ),
    );
  }
}
