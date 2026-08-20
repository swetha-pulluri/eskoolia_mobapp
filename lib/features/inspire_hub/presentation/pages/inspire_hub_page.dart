import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../student/domain/models/student_group.dart';
import '../../domain/models/competition.dart';
import '../providers/inspire_hub_providers.dart';
import '../widgets/inspire_hub_compose_tab.dart';
import '../widgets/inspire_hub_dashboard_tab.dart';
import '../widgets/inspire_hub_history_tab.dart';
import 'inspire_hub_results_page.dart';

/// InspireHub — competitions, results, and AI-generated student reviews.
/// Reference: frontend/components/competitions/InspireHubModal.jsx (web's
/// tabbed Dashboard/Compose/History canvas). Here, Compose only creates the
/// competition; saving pushes InspireHubResultsPage — a dedicated screen for
/// adding participants, marking results, and finalising — rather than
/// growing the same tab taller, matching how the rest of the app moves
/// between "create" and "detail" screens. See that page's doc comment for
/// what else was trimmed from the reference and why. Competitions/results
/// are stored primarily on-device (see [InspireHubStore]); backend sync is
/// best-effort, matching the reference's own localStorage-first design.
class InspireHubPage extends ConsumerStatefulWidget {
  final List<StudentGroup> houses;
  final List<StudentGroup> clubs;
  final List<GroupStudentRow> students;
  const InspireHubPage({super.key, required this.houses, required this.clubs, required this.students});

  @override
  ConsumerState<InspireHubPage> createState() => _InspireHubPageState();
}

class _InspireHubPageState extends ConsumerState<InspireHubPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  int _refreshKey = 0;

  @override
  void dispose() {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            children: [TextSpan(text: 'Inspire'), TextSpan(text: 'Hub', style: TextStyle(color: Color(0xFF7C3AED)))],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF7C3AED),
          tabs: const [Tab(text: 'Dashboard'), Tab(text: 'Compose'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
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
    );
  }
}
