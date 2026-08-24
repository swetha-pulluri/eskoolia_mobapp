import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../student/domain/models/student_group.dart';
import '../../domain/models/competition.dart';
import '../providers/inspire_hub_providers.dart';
import '../widgets/inspire_hub_compose_tab.dart';
import '../widgets/inspire_hub_dashboard_tab.dart';
import '../widgets/inspire_hub_history_tab.dart';
import 'inspire_hub_results_page.dart';

const _kTabDefs = <(String key, String label, IconData icon, List<Color> gradient)>[
  ('dashboard', 'Dashboard', Icons.dashboard_rounded, [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
  ('compose', 'Compose', Icons.edit_rounded, [Color(0xFFD946EF), Color(0xFFF43F5E)]),
  ('history', 'History', Icons.history_rounded, [Color(0xFFF59E0B), Color(0xFFF97316)]),
];

/// InspireHub — competitions, results, and AI-generated student reviews.
/// Reference: frontend/components/competitions/InspireHubModal.jsx (web's
/// tabbed Dashboard/Compose/History canvas) — this shell reproduces its
/// header (sparkle mark + title + subtitle + close), gradient tab pills, and
/// the persistent bottom progress footer. Here, Compose only creates the
/// competition; saving pushes InspireHubResultsPage — a dedicated screen for
/// adding participants, marking results, and finalising — rather than
/// growing the same tab taller, matching how the rest of the app moves
/// between "create" and "detail" screens (see that page's doc comment for
/// what else was trimmed from the reference and why). Because that page
/// owns the in-progress competition, this shell's own footer always shows
/// the same "nothing composed yet" 0% state web shows on a fresh open —
/// real progress lives on the results page once a competition exists.
/// Competitions/results are stored primarily on-device (see
/// [InspireHubStore]); backend sync is best-effort, matching the
/// reference's own localStorage-first design.
class InspireHubPage extends ConsumerStatefulWidget {
  final List<StudentGroup> houses;
  final List<StudentGroup> clubs;
  final List<GroupStudentRow> students;
  const InspireHubPage({super.key, required this.houses, required this.clubs, required this.students});

  @override
  ConsumerState<InspireHubPage> createState() => _InspireHubPageState();
}

class _InspireHubPageState extends ConsumerState<InspireHubPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this)..addListener(_onTabChanged);
  int _refreshKey = 0;

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openResultsPage(Competition competition) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InspireHubResultsPage(competition: competition, houses: widget.houses, clubs: widget.clubs, allStudents: widget.students),
      ),
    );
    if (!mounted) return;
    setState(() => _refreshKey++);
    _tabController.animateTo(0);
  }

  Future<void> _onSubmitNewCompetition(Map<String, dynamic> values) async {
    final level = CompetitionLevel.fromValue(values['level'] as String);
    final compType = CompetitionType.fromValue(values['comp_type'] as String);
    final repo = ref.read(competitionsRepositoryProvider);
    final store = ref.read(inspireHubStoreProvider);

    int? backendId;
    try {
      final res = await repo.createCompetition({
        'name': values['name'],
        'date': values['date'],
        'level': level.backendValue,
        'comp_type': compType.value,
        'location': values['location'],
        'opponent': values['opponent'],
        'notes': values['notes'],
      });
      backendId = res['id'] as int?;
    } catch (_) {
      // Graceful local fallback — the teacher keeps working offline.
      backendId = null;
    }
    final now = DateTime.now().toIso8601String();
    final draft = Competition(
      id: backendId != null ? 'srv-$backendId' : 'local-${DateTime.now().microsecondsSinceEpoch}',
      backendId: backendId,
      isLocal: backendId == null,
      name: values['name'] as String,
      date: values['date'] as String,
      level: level,
      compType: compType,
      sportType: values['sport_type'] as String? ?? '',
      location: values['location'] as String,
      opponent: values['opponent'] as String,
      notes: values['notes'] as String,
      houseAId: values['house_a_id'] as int?,
      houseBId: values['house_b_id'] as int?,
      classes: List<String>.from(values['classes'] as List),
      className: values['class_name'] as String,
      sections: List<String>.from(values['sections'] as List),
      status: 'draft',
      createdAt: now,
      updatedAt: now,
    );
    final saved = await store.saveDraft(draft);
    if (!mounted) return;
    await _openResultsPage(saved);
  }

  void _startNew() => _tabController.animateTo(1);

  void _loadFromHistory(Competition c) => _openResultsPage(c);

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(inspireHubStoreProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabPills(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  InspireHubDashboardTab(key: ValueKey('dashboard-$_refreshKey'), store: store, houses: widget.houses, clubs: widget.clubs),
                  InspireHubComposeTab(houses: widget.houses, allStudents: widget.students, onSubmit: _onSubmitNewCompetition),
                  InspireHubHistoryTab(
                    key: ValueKey('history-$_refreshKey'),
                    store: store,
                    refreshKey: _refreshKey,
                    onEdit: _loadFromHistory,
                    onNew: _startNew,
                    onChanged: () => setState(() => _refreshKey++),
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFECECF2)))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
                    children: const [TextSpan(text: 'Inspire'), TextSpan(text: 'Hub', style: TextStyle(color: Color(0xFF4F46E5)))],
                  ),
                ),
                const Text('Competitions · AI reviews · Insights', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF334155)),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPills() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFECECF2)))),
      child: Row(
        children: [
          for (var i = 0; i < _kTabDefs.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _TabPill(def: _kTabDefs[i], active: _tabController.index == i, onTap: () => _tabController.animateTo(i))),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              SizedBox(width: 6),
              Text('0%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(value: 0, minHeight: 5, backgroundColor: Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation(Color(0xFF0F172A))),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _StageDot(label: 'Competition saved'),
              _StageDot(label: 'Participants added'),
              _StageDot(label: 'Positions marked'),
              _StageDot(label: 'AI reviews'),
              _StageDot(label: 'Finalised'),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final (String key, String label, IconData icon, List<Color> gradient) def;
  final bool active;
  final VoidCallback onTap;
  const _TabPill({required this.def, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(colors: def.$4) : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(def.$3, size: 15, color: active ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(def.$2, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF475569))),
          ],
        ),
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  final String label;
  const _StageDot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }
}
