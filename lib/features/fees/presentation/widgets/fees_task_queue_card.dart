import 'package:flutter/material.dart';
import '../../domain/models/fees_home_data.dart';

/// Mirrors FeesPaymentsPanel.tsx's "Task Queue" card. `tasks` comes from the
/// (currently non-existent) `/fees/home/` endpoint — see
/// fees_home_data.dart's doc comment — so this renders empty on the real
/// backend today, same as the web app.
class FeesTaskQueueCard extends StatelessWidget {
  final List<FeesTask> tasks;
  final void Function(FeesTaskButton button) onButtonTap;

  const FeesTaskQueueCard({super.key, required this.tasks, required this.onButtonTap});

  static Color _hex(String hex) => Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Task Queue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F1222))),
          const SizedBox(height: 4),
          const Text(
            'Auto-generated actions from dues, cheques, and year-end checks.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9197AE), height: 1.5),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _taskRow(tasks[i]),
          ],
        ],
      ),
    );
  }

  Widget _taskRow(FeesTask task) {
    final color = _hex(task.color);
    // Same fix as fees_kpi_cards.dart's `_card` — a coloured left accent
    // can't be a `Border` side when the container also has a
    // `borderRadius` (Flutter requires uniform border colours whenever a
    // radius is set), so it's a clipped strip instead.
    final radius = BorderRadius.circular(10);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFECECF2)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(task.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F1222), height: 1.4)),
                          const SizedBox(height: 5),
                          Text(task.desc, style: const TextStyle(fontSize: 12.5, color: Color(0xFF9197AE), height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final btn in task.buttons) _taskButton(btn)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskButton(FeesTaskButton btn) {
    final primary = btn.variant == 'primary';
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: () => onButtonTap(btn),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: primary ? const Color(0xFF6D4AFF) : Colors.white,
          side: BorderSide(color: primary ? const Color(0xFF6D4AFF) : const Color(0xFFECECF2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          btn.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
            color: primary ? Colors.white : const Color(0xFF0F1222),
          ),
        ),
      ),
    );
  }
}
