import 'package:flutter/material.dart';
import '../../../student/domain/models/student_group.dart';
import '../../../student/presentation/widgets/student_group_widgets.dart' show hexColor;
import '../../domain/inspire_hub_store.dart';

const _kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Dashboard tab — analytics across every finalised event stored on this
/// device. Mirrors web's DashboardPanel.jsx: KPI tiles, best-in-category
/// cards, house leaderboard, monthly activity, recent wins.
class InspireHubDashboardTab extends StatefulWidget {
  final InspireHubStore store;
  final List<StudentGroup> houses;
  final List<StudentGroup> clubs;
  const InspireHubDashboardTab({super.key, required this.store, required this.houses, required this.clubs});

  @override
  State<InspireHubDashboardTab> createState() => _InspireHubDashboardTabState();
}

class _InspireHubDashboardTabState extends State<InspireHubDashboardTab> {
  late int _year = DateTime.now().year;

  StudentGroup? _house(LeaderboardEntry h) {
    for (final x in widget.houses) {
      if (x.id == h.id || x.name == h.name) return x;
    }
    return null;
  }

  StudentGroup? _club(LeaderboardEntry g) {
    for (final x in widget.clubs) {
      if (x.id == g.id || x.name == g.name) return x;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final agg = widget.store.aggregates(year: _year);
    final totalHousePoints = agg.houses.fold<int>(0, (s, h) => s + h.points).clamp(1, 1 << 30);
    final goldCount = agg.events.fold<int>(
      0,
      (s, c) => s + c.results.where((r) => r.position == '1st').length,
    );
    var peakIdx = 0;
    for (var i = 1; i < agg.monthly.length; i++) {
      if (agg.monthly[i] > agg.monthly[peakIdx]) peakIdx = i;
    }
    final bestHouse = agg.houses.isNotEmpty ? agg.houses.first : null;
    final bestStudent = agg.students.isNotEmpty ? agg.students.first : null;
    final bestGroup = agg.groups.isNotEmpty ? agg.groups.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OVERVIEW',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'A snapshot of school spirit',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${agg.eventCount} finalised · ${agg.participantCount} participations · ${agg.reviewCount} AI reviews',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            _YearPicker(year: _year, onChange: (y) => setState(() => _year = y)),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _Kpi(label: 'Events', value: '${agg.eventCount}', hint: 'finalised this year', color: const Color(0xFF6366F1)),
            _Kpi(label: 'Participations', value: '${agg.participantCount}', hint: 'across all events', color: const Color(0xFFF43F5E)),
            _Kpi(label: 'Gold Medals', value: '$goldCount', hint: '1st place finishes', color: const Color(0xFFF59E0B)),
            _Kpi(label: 'AI Reviews', value: '${agg.reviewCount}', hint: 'generated & saved', color: const Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _BestCard(
                title: 'Best House',
                name: bestHouse != null ? '${_house(bestHouse)?.emoji ?? '🏛'} ${bestHouse.name}' : '—',
                subtitle: bestHouse != null ? '${bestHouse.points} pts · ${bestHouse.wins} gold' : 'No data yet',
                color: bestHouse != null ? hexColor(_house(bestHouse)?.color ?? '#7C3AED') : const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BestCard(
                title: 'Top Student',
                name: bestStudent?.name ?? '—',
                subtitle: bestStudent != null
                    ? '${bestStudent.points} pts${bestStudent.className != null && bestStudent.className!.isNotEmpty ? ' · ${bestStudent.className}' : ''}'
                    : 'No data yet',
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BestCard(
          title: 'Top Group / Club',
          name: bestGroup != null ? '${_club(bestGroup)?.emoji ?? '🎯'} ${bestGroup.name}' : '—',
          subtitle: bestGroup != null ? '${bestGroup.points} pts · ${bestGroup.wins} wins' : 'No data yet',
          color: const Color(0xFF10B981),
          full: true,
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'House Leaderboard',
          subtitle: 'cumulative points across all events',
          child: agg.houses.isEmpty
              ? const _EmptyState(text: 'No house points yet — finalise events to see the leaderboard.')
              : Column(
                  children: [
                    for (var i = 0; i < agg.houses.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _HouseRow(rank: i + 1, entry: agg.houses[i], color: hexColor(_house(agg.houses[i])?.color ?? '#7C3AED'), emoji: _house(agg.houses[i])?.emoji ?? '🏛', pct: (agg.houses[i].points / totalHousePoints * 100).clamp(4, 100)),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Activity Pulse',
          subtitle: 'events held per month · $_year',
          child: Column(
            children: [
              _MonthlyBars(data: agg.monthly, peakIdx: peakIdx),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Peak: ${_kMonths[peakIdx]} · ${agg.monthly[peakIdx]} event${agg.monthly[peakIdx] == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'Recent Wins',
          subtitle: 'latest podium finishes across the school',
          child: agg.recent.isEmpty
              ? const _EmptyState(text: 'No podium finishes yet — finalise an event to populate recent wins.')
              : Column(
                  children: [
                    for (var i = 0; i < agg.recent.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      _RecentWinRow(win: agg.recent[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _YearPicker extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChange;
  const _YearPicker({required this.year, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final cur = DateTime.now().year;
    final years = [cur - 2, cur - 1, cur];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final y in years)
            GestureDetector(
              onTap: () => onChange(y),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: y == year ? const Color(0xFF0F172A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$y',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: y == year ? Colors.white : const Color(0xFF475569)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color color;
  const _Kpi({required this.label, required this.value, required this.hint, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          ),
          Text(hint, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _BestCard extends StatelessWidget {
  final String title;
  final String name;
  final String subtitle;
  final Color color;
  final bool full;
  const _BestCard({required this.title, required this.name, required this.subtitle, required this.color, this.full = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, width: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Panel({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HouseRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final Color color;
  final String emoji;
  final double pct;
  const _HouseRow({required this.rank, required this.entry, required this.color, required this.emoji, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 18, child: Text('$rank', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('$emoji ${entry.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                  Text('${entry.points} pts · ${entry.wins}🥇', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation(color)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  final List<int> data;
  final int peakIdx;
  const _MonthlyBars({required this.data, required this.peakIdx});

  @override
  Widget build(BuildContext context) {
    final max = data.fold<int>(1, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < data.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: (data[i] / max * 52).clamp(3, 52).toDouble(),
                      decoration: BoxDecoration(
                        color: data[i] == 0
                            ? const Color(0xFFF1F5F9)
                            : (i == peakIdx ? const Color(0xFFA855F7) : const Color(0xFFC7D2FE)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_kMonths[i][0], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: i == peakIdx ? const Color(0xFFA855F7) : const Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentWinRow extends StatelessWidget {
  final RecentWin win;
  const _RecentWinRow({required this.win});

  String get _medal => win.position == '1st' ? '🥇' : win.position == '2nd' ? '🥈' : '🥉';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(_medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(win.student, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                Text('${win.event}${win.className.isNotEmpty ? ' · ${win.className}' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ),
    );
  }
}
