import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/week_planner_entry.dart';
import '../providers/week_planner_provider.dart';

String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "Week Ahead" — a local-only day planner (see `week_planner_entry.dart`'s
/// doc comment for why: web's own calendar-overlay backend doesn't exist).
/// Mon–Sun day strip (today highlighted) + "Open Planner" (full-week list)
/// + a "Plan your day…" input that adds an entry for today.
class WeekAheadCard extends ConsumerStatefulWidget {
  const WeekAheadCard({super.key});

  @override
  ConsumerState<WeekAheadCard> createState() => _WeekAheadCardState();
}

class _WeekAheadCardState extends ConsumerState<WeekAheadCard> {
  final TextEditingController _controller = TextEditingController();
  late DateTime _selectedDay = DateTime.now();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> get _weekDays {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(weekPlannerProvider);
    final todayIso = _isoDate(DateTime.now());
    final todayCount = entries.where((e) => e.date == todayIso).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bg1, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_outlined, size: 16, color: AppColors.ink1),
              const SizedBox(width: 6),
              const Expanded(child: Text('Week Ahead', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink1))),
              TextButton(
                onPressed: () => _openPlanner(context),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                child: const Text('Open Planner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final day in _weekDays) _dayCell(day),
            ],
          ),
          const SizedBox(height: 10),
          Text('TODAY · $todayCount TASK${todayCount == 1 ? '' : 'S'}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.ink3)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Plan your day…',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.bg2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: _addToday,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _addToday(_controller.text),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.brandPurple, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Matches web's own `WeekAhead.tsx`: its "Plan your day…" row and day
  // cells never add anything by themselves — every one of them only opens
  // `PlannerModal` UNCONDITIONALLY (no text-empty guard blocks that open —
  // there's no text field on web's home-card row at all). Confirmed via
  // debug logging that this card's `+` WAS being tapped correctly, but with
  // an empty `_controller.text` (nothing typed first) it hit an early
  // `if (text.trim().isEmpty) return;` that skipped everything — including
  // opening the planner — which is exactly why it read as "no response at
  // all". Now the planner always opens on tap, exactly like web; a real
  // entry is added first only when there's actually text to add.
  Future<void> _addToday(String text) async {
    if (text.trim().isNotEmpty) {
      await ref.read(weekPlannerProvider.notifier).addEntry(date: _isoDate(DateTime.now()), text: text);
      _controller.clear();
    }
    if (!mounted) return;
    _openPlanner(context);
  }

  Widget _dayCell(DateTime day) {
    final isToday = _isoDate(day) == _isoDate(DateTime.now());
    final isSelected = _isoDate(day) == _isoDate(_selectedDay);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedDay = day),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purpleSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(labels[day.weekday - 1], style: const TextStyle(fontSize: 10, color: AppColors.ink3)),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.brandPurple : AppColors.ink1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PlannerSheet(weekDays: _weekDays),
    );
  }
}

class _PlannerSheet extends ConsumerWidget {
  final List<DateTime> weekDays;
  const _PlannerSheet({required this.weekDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weekPlannerProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('This Week', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                for (final day in weekDays) ..._daySection(ref, day, entries),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _daySection(WidgetRef ref, DateTime day, List<WeekPlannerEntry> entries) {
    final iso = _isoDate(day);
    final dayEntries = entries.where((e) => e.date == iso).toList();
    return [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text('${_weekdayName(day.weekday)}, ${day.day}/${day.month}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink2)),
      ),
      if (dayEntries.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('No tasks planned', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
        )
      else
        for (final entry in dayEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: Text(entry.text, style: const TextStyle(fontSize: 13, color: AppColors.ink1))),
                InkWell(
                  onTap: () => ref.read(weekPlannerProvider.notifier).removeEntry(entry.id),
                  child: const Icon(Icons.close, size: 14, color: AppColors.ink3),
                ),
              ],
            ),
          ),
    ];
  }

  String _weekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }
}
