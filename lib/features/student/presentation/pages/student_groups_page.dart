import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/student_group.dart';
import '../providers/student_providers.dart';
import '../widgets/student_group_widgets.dart';
import '../widgets/subject_assignment_widgets.dart' show ResponsiveGrid;

/// Student Group (Houses & Clubs) — full pixel-for-pixel port of frontend
/// app/(dashboard)/student-groups/StudentGroupPage.tsx +
/// styles/student-groups.css. Every endpoint this screen calls
/// (stats/students/assign/bulk-assign/club-toggle/club-assign/sortwell-
/// preview/sortwell + group CRUD) is a real, tenant-scoped Django endpoint
/// on `StudentGroupViewSet` — confirmed by reading `apps/students/views.py`
/// directly, not the Next.js-only proxy layer.
///
/// Disclosed, deliberate omission: the "Open InspireHub" header button is
/// visually reproduced (gradient pill + sparkle icon) but does not open a
/// working InspireHub — that's a whole separate competitions/gamification
/// subsystem (`components/competitions/InspireHubModal.tsx`) unrelated to
/// group/house/club management, out of scope for this screen; tapping it
/// shows a short "coming soon" toast instead of fabricating that feature.
class StudentGroupsPage extends ConsumerStatefulWidget {
  const StudentGroupsPage({super.key});

  @override
  ConsumerState<StudentGroupsPage> createState() => _StudentGroupsPageState();
}

class FilterState {
  final Set<String> cls;
  final Set<String> sec;
  final Set<String> house;
  final Set<String> club;
  final String status;
  const FilterState({this.cls = const {}, this.sec = const {}, this.house = const {}, this.club = const {}, this.status = ''});

  FilterState copyWith({Set<String>? cls, Set<String>? sec, Set<String>? house, Set<String>? club, String? status}) {
    return FilterState(cls: cls ?? this.cls, sec: sec ?? this.sec, house: house ?? this.house, club: club ?? this.club, status: status ?? this.status);
  }

  bool get isEmpty => cls.isEmpty && sec.isEmpty && house.isEmpty && club.isEmpty && status.isEmpty;
  int get count => cls.length + sec.length + house.length + club.length + (status.isNotEmpty ? 1 : 0);

  bool sameAs(FilterState other) {
    return cls.length == other.cls.length &&
        cls.containsAll(other.cls) &&
        sec.length == other.sec.length &&
        sec.containsAll(other.sec) &&
        house.length == other.house.length &&
        house.containsAll(other.house) &&
        club.length == other.club.length &&
        club.containsAll(other.club) &&
        status == other.status;
  }
}

class _FilterChip {
  final String kind; // 'search' | 'cls' | 'sec' | 'house' | 'club' | 'status'
  final String label;
  final String value;
  const _FilterChip(this.kind, this.label, this.value);
}

class _StudentGroupsPageState extends ConsumerState<StudentGroupsPage> {
  List<StudentGroup> _groups = [];
  List<GroupStudentRow> _students = [];
  StudentGroupStats? _stats;
  bool _loading = true;
  bool _studentsLoading = true;
  String? _error;

  FilterState _sf = const FilterState();
  FilterState _pendingSf = const FilterState();
  String _quickSearch = '';
  bool _filterOpen = false;
  final _searchController = TextEditingController();

  final Set<int> _openAccs = {};
  final Set<String> _openClassRows = {};
  final Map<int, Set<int>> _sel = {};

  bool _aiDismissed = false;
  StudentGroup? _clubModalTarget;

  int? _savingSid;
  int? _bulkSavingGroupId;

  String _toastMsg = '';
  bool _toastOn = false;
  Timer? _toastTimer;

  final _houseListKey = GlobalKey();
  final _clubListKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _toastTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<StudentGroup> get _houses => _groups.where((g) => g.isHouse).toList();
  List<StudentGroup> get _clubs => _groups.where((g) => g.isClub).toList();

  List<String> get _availableSections {
    final set = <String>{};
    for (final s in _students) {
      if (s.sectionName.isNotEmpty && s.sectionName != '-') set.add(s.sectionName);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(studentGroupRepositoryProvider);
      final results = await Future.wait([repo.fetchGroups(), repo.fetchStats()]);
      if (!mounted) return;
      setState(() {
        _groups = results[0] as List<StudentGroup>;
        _stats = results[1] as StudentGroupStats;
        _loading = false;
      });
      final rows = await repo.fetchStudents();
      if (!mounted) return;
      setState(() {
        _students = rows;
        _studentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _reloadGroups() async {
    final repo = ref.read(studentGroupRepositoryProvider);
    final results = await Future.wait([repo.fetchGroups(), repo.fetchStats()]);
    if (!mounted) return;
    setState(() {
      _groups = results[0] as List<StudentGroup>;
      _stats = results[1] as StudentGroupStats;
    });
  }

  Future<void> _reloadStudents() async {
    final rows = await ref.read(studentGroupRepositoryProvider).fetchStudents();
    if (!mounted) return;
    setState(() => _students = rows);
  }

  void _showToast(String msg) {
    _toastTimer?.cancel();
    setState(() {
      _toastMsg = msg;
      _toastOn = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() => _toastOn = false);
    });
  }

  List<GroupStudentRow> get _filtered {
    final groupById = {for (final g in _groups) g.id: g};
    final query = _quickSearch.trim().toLowerCase();
    return _students.where((s) {
      final group = s.currentGroupId != null ? groupById[s.currentGroupId] : null;
      final studentClubs = _clubs.where((c) => s.clubIds.contains(c.id)).toList();
      if (query.isNotEmpty) {
        final clubNames = studentClubs.map((c) => c.name).join(' ');
        final haystack = [s.name, s.admissionNo, s.className, s.sectionName, group?.name ?? '', clubNames].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (_sf.cls.isNotEmpty && !_sf.cls.contains(s.className)) return false;
      if (_sf.sec.isNotEmpty && !_sf.sec.contains(s.sectionName)) return false;
      if (_sf.status.toLowerCase() == 'assigned' && s.currentGroupId == null && s.clubIds.isEmpty) return false;
      if (_sf.status.toLowerCase() == 'unassigned' && (s.currentGroupId != null || s.clubIds.isNotEmpty)) return false;
      if (_sf.house.isNotEmpty) {
        if (group == null || !_houses.any((h) => h.id == group.id && _sf.house.contains(h.name))) return false;
      }
      if (_sf.club.isNotEmpty) {
        if (!studentClubs.any((c) => _sf.club.contains(c.name))) return false;
      }
      return true;
    }).toList();
  }

  List<_FilterChip> get _chips {
    final list = <_FilterChip>[];
    if (_quickSearch.trim().isNotEmpty) list.add(_FilterChip('search', 'Search: ${_quickSearch.trim()}', _quickSearch.trim()));
    for (final v in _sf.cls) {
      list.add(_FilterChip('cls', v, v));
    }
    for (final v in _sf.sec) {
      list.add(_FilterChip('sec', v, v));
    }
    for (final v in _sf.house) {
      list.add(_FilterChip('house', v, v));
    }
    for (final v in _sf.club) {
      list.add(_FilterChip('club', v, v));
    }
    if (_sf.status.isNotEmpty) list.add(_FilterChip('status', 'Status: ${_sf.status}', _sf.status));
    return list;
  }

  bool get _hasFilterChanges => !_sf.sameAs(_pendingSf);

  void _applyFilters() {
    setState(() {
      _sf = _pendingSf;
      _filterOpen = false;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _sf = const FilterState();
      _pendingSf = const FilterState();
      _quickSearch = '';
      _searchController.clear();
    });
  }

  void _togglePendingCls(String v) => setState(() => _pendingSf = _pendingSf.copyWith(cls: _toggled(_pendingSf.cls, v)));
  void _togglePendingSec(String v) => setState(() => _pendingSf = _pendingSf.copyWith(sec: _toggled(_pendingSf.sec, v)));
  void _togglePendingHouse(String v) => setState(() => _pendingSf = _pendingSf.copyWith(house: _toggled(_pendingSf.house, v)));
  void _togglePendingClub(String v) => setState(() => _pendingSf = _pendingSf.copyWith(club: _toggled(_pendingSf.club, v)));
  void _togglePendingStatus(String v) => setState(() => _pendingSf = _pendingSf.copyWith(status: _pendingSf.status == v ? '' : v));

  Set<String> _toggled(Set<String> set, String v) {
    final n = Set<String>.from(set);
    if (n.contains(v)) {
      n.remove(v);
    } else {
      n.add(v);
    }
    return n;
  }

  void _removeChip(_FilterChip c) {
    setState(() {
      switch (c.kind) {
        case 'search':
          _quickSearch = '';
          _searchController.clear();
          break;
        case 'status':
          _sf = _sf.copyWith(status: '');
          _pendingSf = _pendingSf.copyWith(status: '');
          break;
        case 'cls':
          _sf = _sf.copyWith(cls: _toggled(_sf.cls, c.value));
          _pendingSf = _pendingSf.copyWith(cls: _toggled(_pendingSf.cls, c.value));
          break;
        case 'sec':
          _sf = _sf.copyWith(sec: _toggled(_sf.sec, c.value));
          _pendingSf = _pendingSf.copyWith(sec: _toggled(_pendingSf.sec, c.value));
          break;
        case 'house':
          _sf = _sf.copyWith(house: _toggled(_sf.house, c.value));
          _pendingSf = _pendingSf.copyWith(house: _toggled(_pendingSf.house, c.value));
          break;
        case 'club':
          _sf = _sf.copyWith(club: _toggled(_sf.club, c.value));
          _pendingSf = _pendingSf.copyWith(club: _toggled(_pendingSf.club, c.value));
          break;
      }
    });
  }

  void _toggleAcc(int id) => setState(() => _openAccs.contains(id) ? _openAccs.remove(id) : _openAccs.add(id));
  void _toggleClassRow(String key) => setState(() => _openClassRows.contains(key) ? _openClassRows.remove(key) : _openClassRows.add(key));

  void _toggleRowSel(int groupId, int studentId, bool checked) {
    setState(() {
      final n = Set<int>.from(_sel[groupId] ?? {});
      if (checked) {
        n.add(studentId);
      } else {
        n.remove(studentId);
      }
      _sel[groupId] = n;
    });
  }

  void _toggleClsSel(int groupId, String cls, bool checked) {
    final group = _groups.where((g) => g.id == groupId).firstOrNull;
    final ids = group?.isClub == true
        ? _students.where((s) => s.clubIds.contains(groupId) && s.className == cls).map((s) => s.id)
        : _students.where((s) => s.currentGroupId == groupId && s.className == cls).map((s) => s.id);
    setState(() {
      final n = Set<int>.from(_sel[groupId] ?? {});
      for (final id in ids) {
        if (checked) {
          n.add(id);
        } else {
          n.remove(id);
        }
      }
      _sel[groupId] = n;
    });
  }

  void _clearSel(int groupId) => setState(() => _sel[groupId] = {});

  Future<void> _assignOne(int studentId, int? groupId) async {
    final grp = groupId != null ? _groups.where((g) => g.id == groupId).firstOrNull : null;
    final isClub = grp?.isClub == true;
    setState(() => _savingSid = studentId);
    final student = _students.where((s) => s.id == studentId).firstOrNull;

    if (isClub && groupId != null) {
      final alreadyMember = student?.clubIds.contains(groupId) ?? false;
      setState(() {
        _students = _students.map((s) {
          if (s.id != studentId) return s;
          final newClubIds = alreadyMember ? (s.clubIds.where((id) => id != groupId).toList()) : ([...s.clubIds, groupId]);
          return s.copyWith(clubIds: newClubIds);
        }).toList();
      });
      try {
        final clubIds = await ref.read(studentGroupRepositoryProvider).toggleClubMembership(studentId, groupId);
        if (!mounted) return;
        setState(() {
          _students = _students.map((s) => s.id == studentId ? s.copyWith(clubIds: clubIds) : s).toList();
        });
        await _reloadGroups();
        _showToast(!alreadyMember ? '${student?.name} joined ${grp!.emoji} ${grp.name}' : '${student?.name} left ${grp!.emoji} ${grp.name}');
      } catch (e) {
        await _reloadStudents();
        _showToast('Save failed - please try again');
      } finally {
        if (mounted) setState(() => _savingSid = null);
      }
    } else {
      setState(() {
        _students = _students.map((s) => s.id == studentId ? s.copyWith(currentGroupId: groupId, clearGroup: groupId == null) : s).toList();
      });
      try {
        await ref.read(studentGroupRepositoryProvider).assignHouse(studentId, groupId);
        if (!mounted) return;
        await _reloadGroups();
        _showToast(grp != null ? '${student?.name} -> ${grp.emoji} ${grp.name}' : '${student?.name} unassigned');
      } catch (e) {
        await _reloadStudents();
        _showToast('Save failed - please try again');
      } finally {
        if (mounted) setState(() => _savingSid = null);
      }
    }
  }

  Future<void> _bulkClubAdd(List<int> studentIds, int clubId) async {
    final grp = _groups.where((g) => g.id == clubId).firstOrNull;
    if (grp == null) return;
    setState(() {
      _students = _students.map((s) {
        if (studentIds.contains(s.id) && !s.clubIds.contains(clubId)) return s.copyWith(clubIds: [...s.clubIds, clubId]);
        return s;
      }).toList();
    });
    try {
      final repo = ref.read(studentGroupRepositoryProvider);
      await Future.wait(studentIds.map((sid) => repo.addToClub(sid, clubId)));
      await _reloadStudents();
      await _reloadGroups();
      _showToast('${studentIds.length} student${studentIds.length != 1 ? 's' : ''} added to ${grp.emoji} ${grp.name}');
    } catch (e) {
      await _reloadStudents();
      _showToast('Some adds failed — please retry');
    }
  }

  Future<void> _doBulkAssign(int groupId, int targetGroupId) async {
    final ids = (_sel[groupId] ?? {}).toList();
    if (ids.isEmpty) return;
    setState(() => _bulkSavingGroupId = groupId);
    try {
      await ref.read(studentGroupRepositoryProvider).bulkAssignHouse(ids, targetGroupId);
      final g = _groups.where((x) => x.id == targetGroupId).firstOrNull;
      _clearSel(groupId);
      await Future.wait([_reloadGroups(), _reloadStudents()]);
      _showToast('${ids.length} students -> ${g?.emoji} ${g?.name}');
    } finally {
      if (mounted) setState(() => _bulkSavingGroupId = null);
    }
  }

  Future<void> _applyAiSuggestion() async {
    final unassigned = _students.where((s) => s.currentGroupId == null).toList();
    if (unassigned.isEmpty) {
      _showToast('All students already assigned');
      return;
    }
    final repo = ref.read(studentGroupRepositoryProvider);
    final houses = _houses;
    await Future.wait(houses.asMap().entries.map((entry) {
      final i = entry.key;
      final slice = <int>[];
      for (var idx = 0; idx < unassigned.length; idx++) {
        if (idx % houses.length == i) slice.add(unassigned[idx].id);
      }
      if (slice.isEmpty) return Future.value();
      return repo.bulkAssignHouse(slice, entry.value.id);
    }));
    await Future.wait([_reloadGroups(), _reloadStudents()]);
    setState(() => _aiDismissed = true);
    _showToast('${unassigned.length} students assigned via AI suggestion');
  }

  /// Called by [_GroupEditorDialog]'s Save button — throws on failure so the
  /// dialog can show an inline error instead of closing.
  Future<void> _saveGroup({required StudentGroup? editTarget, required String name, required String type, required String emoji, required String description, required int capacity}) async {
    if (name.trim().isEmpty) throw Exception('Group name required');
    final repo = ref.read(studentGroupRepositoryProvider);
    if (editTarget != null) {
      await repo.updateGroup(editTarget.id, name: name, emoji: emoji, description: description, capacity: capacity);
      await _reloadGroups();
      _showToast('$name updated');
    } else {
      final list = type == 'HOUSE' ? _houses : _clubs;
      final ci = list.length % 4;
      await repo.createGroup(
        name: name,
        type: type,
        emoji: emoji,
        description: description,
        capacity: capacity,
        color: type == 'HOUSE' ? kHouseColors[ci] : kClubColors[ci],
        bgColor: type == 'HOUSE' ? kHouseBgs[ci] : kClubBgs[ci],
      );
      await _reloadGroups();
      _showToast('$name created');
    }
  }

  /// Called by [_AddClubDialog]'s Create button — throws on failure.
  Future<void> _saveClub({required String name, required String emoji, required String description, required int capacity}) async {
    if (name.trim().isEmpty) throw Exception('Club name required');
    final ci = _clubs.length % 4;
    await ref.read(studentGroupRepositoryProvider).createGroup(
          name: name,
          type: 'CLUB',
          emoji: emoji,
          description: description,
          capacity: capacity,
          color: kClubColors[ci],
          bgColor: kClubBgs[ci],
        );
    await _reloadGroups();
    _showToast('$emoji $name club created');
  }

  Future<void> _openGroupEditor({StudentGroup? existing, required String type}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _GroupEditorDialog(
        editTarget: existing,
        initialType: type,
        onSave: (name, t, emoji, description, capacity) => _saveGroup(editTarget: existing, name: name, type: t, emoji: emoji, description: description, capacity: capacity),
      ),
    );
  }

  Future<void> _openAddClubDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AddClubDialog(onSave: (name, emoji, description, capacity) => _saveClub(name: name, emoji: emoji, description: description, capacity: capacity)),
    );
  }

  Future<void> _openSortwellDialog() async {
    final result = await showDialog<SortwellResult>(
      context: context,
      builder: (context) => _SortwellDialog(houseCount: _houses.length),
    );
    if (result != null) {
      await Future.wait([_reloadGroups(), _reloadStudents()]);
      _showToast('${result.assigned} students sorted across ${_houses.length} houses');
    }
  }

  Future<void> _deleteGroup(StudentGroup g) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this group?'),
        content: const Text('All student assignments will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(studentGroupRepositoryProvider).deleteGroup(g.id);
    await Future.wait([_reloadGroups(), _reloadStudents()]);
    _showToast('Group deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAll,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: const Color(0xFFF8F8FC), border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(16)),
                        child: _loading
                            ? const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator()))
                            : _error != null
                                ? Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(children: [
                                      Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                                      const SizedBox(height: 8),
                                      OutlinedButton(onPressed: _loadAll, child: const Text('Retry')),
                                    ]),
                                  )
                                : _buildContent(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_clubModalTarget != null)
            _ClubMembersDrawer(
              club: _clubModalTarget!,
              allStudents: _students,
              onAssignOne: _assignOne,
              onBulkAdd: _bulkClubAdd,
              savingSid: _savingSid,
              onClose: () => setState(() => _clubModalTarget = null),
            ),
          GroupToastOverlay(message: _toastMsg, visible: _toastOn),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        ResponsiveGrid(
          baseCols: 5,
          breakpoints: {900: 2},
          gap: 12,
          children: [
            GroupStatCard(eyebrow: 'Students', value: '${_stats?.totalStudents ?? '-'}', label: 'Total Students', barColor: const Color(0xFF6C5CE7)),
            GroupStatCard(eyebrow: 'Assigned', value: '${_stats?.assigned ?? '-'}', label: 'Assigned Students', barColor: const Color(0xFF00B894)),
            GroupStatCard(eyebrow: 'Waiting', value: '${_stats?.unassigned ?? '-'}', label: 'Unassigned Students', barColor: const Color(0xFFE67E22)),
            GroupStatCard(eyebrow: 'House', value: '${_stats?.houseCount ?? '-'}', label: 'School Houses', barColor: const Color(0xFF8B7BD9)),
            GroupStatCard(eyebrow: 'Club', value: '${_stats?.clubCount ?? '-'}', label: 'School Clubs', barColor: const Color(0xFFFF8D5B)),
          ],
        ),
        const SizedBox(height: 20),
        _sectionHead('School Houses', const Color(0xFF00B894), '${_houses.length} House${_houses.length != 1 ? 's' : ''}'),
        const SizedBox(height: 12),
        ResponsiveGrid(baseCols: 4, breakpoints: {1200: 2}, gap: 11, children: [
          for (final h in _houses)
            HouseCard(
              group: h,
              onEdit: () => _openGroupEditor(existing: h, type: 'HOUSE'),
              onDelete: () => _deleteGroup(h),
            ),
        ]),
        const SizedBox(height: 20),
        _sectionHead('School Clubs', const Color(0xFF6C5CE7), '${_clubs.length} Club${_clubs.length != 1 ? 's' : ''}'),
        const SizedBox(height: 12),
        ResponsiveGrid(baseCols: 4, breakpoints: {1200: 2}, gap: 11, children: [
          for (final c in _clubs)
            ClubCard(
              group: c,
              onEdit: () => _openGroupEditor(existing: c, type: 'CLUB'),
              onDelete: () => _deleteGroup(c),
            ),
          NewClubGhostCard(onTap: _openAddClubDialog),
        ]),
        const SizedBox(height: 20),
        _buildFilterShell(),
        if (_chips.isNotEmpty || _quickSearch.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildResultsPanel(),
        ],
        const SizedBox(height: 12),
        _divider('House - Student List'),
        const SizedBox(height: 16),
        Container(
          key: _houseListKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 7), decoration: const BoxDecoration(color: Color(0xFF00B894), shape: BoxShape.circle)),
                  const Text('School Houses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
                  const SizedBox(width: 4),
                  const Expanded(child: Text('- filtered results shown immediately after selection', style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8)), overflow: TextOverflow.ellipsis)),
                  if (_studentsLoading) ...[
                    const SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 1.5)),
                    const SizedBox(width: 5),
                    const Text('Loading students…', style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              for (var hi = 0; hi < _houses.length; hi++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GroupAccordion(
                    key: ValueKey('house-${_houses[hi].id}'),
                    group: _houses[hi],
                    students: _filtered,
                    allGroups: _groups,
                    isOpen: _openAccs.contains(_houses[hi].id),
                    onToggle: () => _toggleAcc(_houses[hi].id),
                    openClassRows: _openClassRows,
                    onToggleClassRow: _toggleClassRow,
                    selected: _sel[_houses[hi].id] ?? const {},
                    onToggleRow: (sid, chk) => _toggleRowSel(_houses[hi].id, sid, chk),
                    onToggleCls: (cls, chk) => _toggleClsSel(_houses[hi].id, cls, chk),
                    onClearSel: () => _clearSel(_houses[hi].id),
                    onBulkAssign: (tgt) => _doBulkAssign(_houses[hi].id, tgt),
                    onAssignOne: _assignOne,
                    bulkSaving: _bulkSavingGroupId == _houses[hi].id,
                    savingSid: _savingSid,
                    showAI: hi == 0 && !_aiDismissed && (_stats?.unassigned ?? 0) > 0,
                    onAIApply: _applyAiSuggestion,
                    onAIDismiss: () => setState(() => _aiDismissed = true),
                    onOpenClubModal: (g) => setState(() => _clubModalTarget = g),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _divider('Club - Student List'),
        const SizedBox(height: 16),
        Container(
          key: _clubListKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 7), decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle)),
                  const Text('School Clubs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
                  const SizedBox(width: 4),
                  const Expanded(child: Text('- keep filtering and jump straight into matching club members', style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8)), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 10),
              for (final c in _clubs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GroupAccordion(
                    key: ValueKey('club-${c.id}'),
                    group: c,
                    students: _filtered,
                    allGroups: _groups,
                    isOpen: _openAccs.contains(c.id),
                    onToggle: () => _toggleAcc(c.id),
                    openClassRows: _openClassRows,
                    onToggleClassRow: _toggleClassRow,
                    selected: _sel[c.id] ?? const {},
                    onToggleRow: (sid, chk) => _toggleRowSel(c.id, sid, chk),
                    onToggleCls: (cls, chk) => _toggleClsSel(c.id, cls, chk),
                    onClearSel: () => _clearSel(c.id),
                    onBulkAssign: (tgt) => _doBulkAssign(c.id, tgt),
                    onAssignOne: _assignOne,
                    bulkSaving: _bulkSavingGroupId == c.id,
                    savingSid: _savingSid,
                    showAI: false,
                    onAIApply: () {},
                    onAIDismiss: () {},
                    onOpenClubModal: (g) => setState(() => _clubModalTarget = g),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('STUDENT INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: Color(0xFF00B894))),
            const SizedBox(height: 3),
            RichText(
              text: TextSpan(
                style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: const Color(0xFF0F172A)),
                children: [
                  const TextSpan(text: 'Student '),
                  TextSpan(text: 'Group', style: GoogleFonts.playfairDisplay(fontSize: 28, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: const Color(0xFF6C3CE1))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Manage ${_stats?.totalStudents ?? '-'} students across houses & clubs - assign in bulk, class by class',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8)),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 9,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _openSortwellDialog,
              icon: const Icon(Icons.donut_small_outlined, size: 15, color: Color(0xFF1A2744)),
              label: const Text('Sortwell', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2744))),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFD0D8EC)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            ElevatedButton.icon(
              onPressed: () => _openGroupEditor(type: 'HOUSE'),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Add Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B894), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            InkWell(
              onTap: () => _showToast('InspireHub is coming soon'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFFDA22FF)]), borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Open InspireHub', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHead(String title, Color dotColor, String count) {
    return Row(
      children: [
        Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 7), decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2744)))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFF0F2F8), border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(20)),
          child: Text(count, style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8), fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _divider(String label) {
    return Row(
      children: [
        const Expanded(child: SizedBox(height: 1, child: ColoredBox(color: Color(0xFFE2E6F0)))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Color(0xFF8FA3C8))),
        ),
        const Expanded(child: SizedBox(height: 1, child: ColoredBox(color: Color(0xFFE2E6F0)))),
      ],
    );
  }

  // ── Smart Filter shell ──────────────────────────────────────────────
  Widget _buildFilterShell() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF9FBFF)]),
        border: Border.all(color: const Color(0xFFE2E6F0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x141A2744), blurRadius: 18, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B894), Color(0xFF8FD3FF)]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 260),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFD0D8EC)), borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 16, color: Color(0xFF8FA3C8)),
                            const SizedBox(width: 9),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => setState(() => _quickSearch = v),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1A2744)),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Search student, admission no, class, section, house or club',
                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF8FA3C8)),
                                ),
                              ),
                            ),
                            if (_quickSearch.isNotEmpty)
                              InkWell(
                                onTap: () => setState(() {
                                  _quickSearch = '';
                                  _searchController.clear();
                                }),
                                child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 14, color: Color(0xFF8FA3C8))),
                              ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _filterOpen = !_filterOpen),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _filterOpen ? const Color(0xFFF0EEFF) : Colors.white,
                          border: Border.all(color: _filterOpen ? const Color(0xFF6C5CE7) : const Color(0xFFD0D8EC)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.filter_alt_outlined, size: 14, color: _filterOpen ? const Color(0xFF6C5CE7) : const Color(0xFF4A5A7A)),
                          const SizedBox(width: 5),
                          Text('Filters', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _filterOpen ? const Color(0xFF6C5CE7) : const Color(0xFF4A5A7A))),
                          if (_pendingSf.count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle),
                              child: Text('${_pendingSf.count}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ],
                          if (_hasFilterChanges) ...[
                            const SizedBox(width: 5),
                            Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFE67E22), shape: BoxShape.circle)),
                          ],
                          const SizedBox(width: 5),
                          Icon(_filterOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 14, color: const Color(0xFF8FA3C8)),
                        ]),
                      ),
                    ),
                    if (_chips.isNotEmpty || _hasFilterChanges)
                      TextButton(
                        onPressed: _clearAllFilters,
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF8FA3C8), padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: const Text('Reset all', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    OutlinedButton(
                      onPressed: () => Scrollable.ensureVisible(_houseListKey.currentContext ?? context, duration: const Duration(milliseconds: 300)),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A5A7A), side: const BorderSide(color: Color(0xFFD0D8EC)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text('Houses ↓', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    OutlinedButton(
                      onPressed: () => Scrollable.ensureVisible(_clubListKey.currentContext ?? context, duration: const Duration(milliseconds: 300)),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A5A7A), side: const BorderSide(color: Color(0xFFD0D8EC)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      child: const Text('Clubs ↓', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (_chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final c in _chips)
                        Container(
                          padding: const EdgeInsets.fromLTRB(11, 5, 5, 5),
                          decoration: BoxDecoration(color: const Color(0xFF1A2744), borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(c.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 7),
                            InkWell(
                              onTap: () => _removeChip(c),
                              child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ],
                if (_filterOpen) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0x248FA3C8)),
                  const SizedBox(height: 14),
                  _filterGroup('Class', kGroupClasses, _pendingSf.cls, _togglePendingCls, allLabel: 'All', onClearAll: () => setState(() => _pendingSf = _pendingSf.copyWith(cls: {}))),
                  const SizedBox(height: 12),
                  ResponsiveGrid(baseCols: 2, gap: 14, children: [
                    _filterGroup('Section', _availableSections, _pendingSf.sec, _togglePendingSec, allLabel: 'All', onClearAll: () => setState(() => _pendingSf = _pendingSf.copyWith(sec: {}))),
                    _filterStatusGroup(),
                  ]),
                  const SizedBox(height: 12),
                  ResponsiveGrid(baseCols: 2, gap: 14, children: [
                    _filterGroup('House', _houses.map((h) => h.name).toList(), _pendingSf.house, _togglePendingHouse, allLabel: 'Any', onClearAll: () => setState(() => _pendingSf = _pendingSf.copyWith(house: {})), emojiByName: {for (final h in _houses) h.name: h.emoji}),
                    _filterGroup('Club', _clubs.map((c) => c.name).toList(), _pendingSf.club, _togglePendingClub, allLabel: 'Any', onClearAll: () => setState(() => _pendingSf = _pendingSf.copyWith(club: {})), emojiByName: {for (final c in _clubs) c.name: c.emoji}),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasFilterChanges ? const Color(0xFF6C5CE7) : const Color(0xFFD0D8EC),
                        foregroundColor: _hasFilterChanges ? Colors.white : const Color(0xFF4A5A7A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      ),
                      child: Text(_hasFilterChanges ? '✓ Apply Filter' : '✓ Applied', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    if (_hasFilterChanges) ...[
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _pendingSf = _sf;
                          _filterOpen = false;
                        }),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8FA3C8), side: const BorderSide(color: Color(0xFFE2E6F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterGroup(String label, List<String> options, Set<String> selected, void Function(String) onToggle, {required String allLabel, required VoidCallback onClearAll, Map<String, String>? emojiByName}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          GroupPill(label: allLabel, active: selected.isEmpty, onTap: onClearAll),
          for (final opt in options) GroupPill(label: emojiByName != null ? '${emojiByName[opt] ?? ''} $opt' : opt, active: selected.contains(opt), onTap: () => onToggle(opt)),
        ]),
      ],
    );
  }

  Widget _filterStatusGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          GroupPill(label: 'All', active: _pendingSf.status.isEmpty, onTap: () => setState(() => _pendingSf = _pendingSf.copyWith(status: ''))),
          for (final s in ['Assigned', 'Unassigned']) GroupPill(label: s, active: _pendingSf.status == s, onTap: () => _togglePendingStatus(s)),
        ]),
      ],
    );
  }

  Widget _buildResultsPanel() {
    final rows = _filtered;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(color: Color(0xFFF9FBFF), border: Border(bottom: BorderSide(color: Color(0xFFE2E6F0)))),
            child: Row(children: [
              Text('${rows.length} student${rows.length != 1 ? 's' : ''} found', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A2744))),
              const SizedBox(width: 8),
              const Text('matching applied filters', style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
            ]),
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Row(children: [
                Text('🔍', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(child: Text('No students match the selected filters. Try adjusting your search or filters above.', style: TextStyle(fontSize: 13, color: Color(0xFF8FA3C8)))),
              ]),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rows.length,
                itemBuilder: (context, i) => _resultRow(rows[i], i == rows.length - 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(GroupStudentRow s, bool isLast) {
    final group = s.currentGroupId != null ? _groups.where((g) => g.id == s.currentGroupId).firstOrNull : null;
    final studentClubs = _clubs.where((c) => s.clubIds.contains(c.id)).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE2E6F0)))),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: avatarColorFor(s.id), shape: BoxShape.circle),
            child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2744)), overflow: TextOverflow.ellipsis),
                Text('${s.admissionNo} · ${s.className}${s.sectionName.isNotEmpty && s.sectionName != '-' ? ' · Sec ${s.sectionName}' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            runSpacing: 4,
            children: [
              if (group != null && group.isClub == false)
                _tag(group.name, hexColor(group.bgColor), hexColor(group.color)),
              for (final c in studentClubs) _tag(c.name, hexColor(c.bgColor), hexColor(c.color)),
              if (group == null && studentClubs.isEmpty) _tag('Unassigned', const Color(0xFFF0F2F8), const Color(0xFF8FA3C8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// Mirrors the `Accordion` component — shared by both houses and clubs.
/// For houses: shows only current members. For clubs: shows ALL students
/// (so the admin can add/remove), with per-class chip strips instead of a
/// full editable table.
class _GroupAccordion extends StatefulWidget {
  final StudentGroup group;
  final List<GroupStudentRow> students;
  final List<StudentGroup> allGroups;
  final bool isOpen;
  final VoidCallback onToggle;
  final Set<String> openClassRows;
  final void Function(String key) onToggleClassRow;
  final Set<int> selected;
  final void Function(int sid, bool checked) onToggleRow;
  final void Function(String cls, bool checked) onToggleCls;
  final VoidCallback onClearSel;
  final void Function(int targetGroupId) onBulkAssign;
  final Future<void> Function(int sid, int? gid) onAssignOne;
  final bool bulkSaving;
  final int? savingSid;
  final bool showAI;
  final VoidCallback onAIApply;
  final VoidCallback onAIDismiss;
  final void Function(StudentGroup g) onOpenClubModal;

  const _GroupAccordion({
    super.key,
    required this.group,
    required this.students,
    required this.allGroups,
    required this.isOpen,
    required this.onToggle,
    required this.openClassRows,
    required this.onToggleClassRow,
    required this.selected,
    required this.onToggleRow,
    required this.onToggleCls,
    required this.onClearSel,
    required this.onBulkAssign,
    required this.onAssignOne,
    required this.bulkSaving,
    required this.savingSid,
    required this.showAI,
    required this.onAIApply,
    required this.onAIDismiss,
    required this.onOpenClubModal,
  });

  @override
  State<_GroupAccordion> createState() => _GroupAccordionState();
}

class _GroupAccordionState extends State<_GroupAccordion> {
  int? _bulkTarget;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final isClub = g.isClub;
    final houseMembers = widget.students.where((s) => s.currentGroupId == g.id).toList();
    final memberIds = widget.students.where((s) => s.clubIds.contains(g.id)).map((s) => s.id).toSet();
    final displayStudents = isClub ? widget.students : houseMembers;
    final pct = g.capacity > 0 ? (g.studentsCount / g.capacity * 100).clamp(0, 100).round() : 0;
    final hasSel = widget.selected.isNotEmpty;
    final houseOptions = widget.allGroups.where((x) => x.isHouse).toList();
    final memberCount = memberIds.length;
    final color = hexColor(g.color);
    final bg = hexColor(g.bgColor);

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showAI) _aiBar(),
          if (!isClub && hasSel) _inlineBulkBar(houseOptions),
          InkWell(
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(width: 4, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 12),
                  Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Text(g.emoji, style: const TextStyle(fontSize: 15))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(g.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2744)), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        if (isClub)
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(text: '$memberCount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                              const TextSpan(text: ' members', style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
                              TextSpan(text: '  · capacity ${g.capacity}', style: const TextStyle(fontSize: 11, color: Color(0xFFB5C4D8))),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Row(children: [
                            // Fixed at a smaller width (was 100) so it plus the
                            // spacing below can never alone exceed the space
                            // this row gets on narrow phones.
                            SizedBox(
                              width: 50,
                              height: 5,
                              child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct / 100, backgroundColor: const Color(0xFFF0F2F8), valueColor: AlwaysStoppedAnimation(color))),
                            ),
                            const SizedBox(width: 6),
                            // Single Flexible + Text.rich (not separate Text
                            // widgets) so the whole tail ellipsizes instead of
                            // overflowing when width runs out.
                            Flexible(
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: '$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pct >= 90 ? const Color(0xFF00B894) : pct >= 60 ? const Color(0xFFE67E22) : const Color(0xFFE74C3C))),
                                  TextSpan(text: '  ${g.studentsCount} students', style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
                                ]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Flexible so this decorative trailing content wraps/
                  // shrinks instead of squeezing the Expanded name column
                  // to zero (and overflowing) at narrower window widths.
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: isClub
                          ? (memberCount == 0
                              ? const Text('No members yet', style: TextStyle(fontSize: 10, color: Color(0xFFB5C4D8), fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                                  child: Text('$memberCount / ${g.capacity} members', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), overflow: TextOverflow.ellipsis),
                                ))
                          // Mirrors the reference's own hardcoded, non-data-driven
                          // decorative class chips shown next to each house header.
                          : Wrap(spacing: 5, runSpacing: 4, alignment: WrapAlignment.end, children: const [
                              _StaticChip('Nursery'),
                              _StaticChip('Grade 5'),
                              _StaticChip('Grade 10'),
                              _StaticChip('+10'),
                            ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(turns: widget.isOpen ? 0.5 : 0, duration: const Duration(milliseconds: 250), child: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF8FA3C8))),
                ],
              ),
            ),
          ),
          if (widget.isOpen)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E6F0)))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isClub) _clubMembersStrip(g, color, bg, memberCount),
                  for (var ci = 0; ci < kGroupClasses.length; ci++) _classRow(g, kGroupClasses[ci], ci, isClub, displayStudents, memberIds, color),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _aiBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF6C5CE7).withValues(alpha: 0.07), const Color(0xFF00B894).withValues(alpha: 0.04)]), border: const Border(bottom: BorderSide(color: Color(0x2E6C5CE7)))),
      child: Row(
        children: [
          const Text('AI', style: TextStyle(fontSize: 14, color: Color(0xFF6C5CE7), fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'AI suggestion - ', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A2744))),
                TextSpan(text: 'Unassigned students detected. Click Apply to auto-balance across all houses.'),
              ]),
              style: TextStyle(fontSize: 12, color: Color(0xFF4A5A7A), height: 1.4),
            ),
          ),
          TextButton.icon(
            onPressed: widget.onAIApply,
            icon: const Icon(Icons.check, size: 14, color: Colors.white),
            label: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          ),
          IconButton(onPressed: widget.onAIDismiss, icon: const Icon(Icons.close, size: 16, color: Color(0xFF8FA3C8)), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }

  Widget _inlineBulkBar(List<StudentGroup> houseOptions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(color: Color(0x0F00B894), border: Border(bottom: BorderSide(color: Color(0x3300B894)))),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(color: const Color(0x2100B894), border: Border.all(color: const Color(0x4D00B894)), borderRadius: BorderRadius.circular(20)),
            child: Text('${widget.selected.length} selected', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00B894))),
          ),
          const Text('-> Move to:', style: TextStyle(fontSize: 12, color: Color(0xFF4A5A7A))),
          Container(
            constraints: const BoxConstraints(minWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(6)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _bulkTarget,
                isDense: true,
                hint: const Text('Choose group...', style: TextStyle(fontSize: 11.5)),
                items: [for (final h in houseOptions) DropdownMenuItem(value: h.id, child: Text('${h.emoji} ${h.name}', style: const TextStyle(fontSize: 11.5)))],
                onChanged: (v) => setState(() => _bulkTarget = v),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: (_bulkTarget == null || widget.bulkSaving) ? null : () => widget.onBulkAssign(_bulkTarget!),
            icon: widget.bulkSaving ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 13, color: Colors.white),
            label: Text(widget.bulkSaving ? '' : 'Apply', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B894), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          ),
          OutlinedButton.icon(
            onPressed: widget.onClearSel,
            icon: const Icon(Icons.close, size: 12, color: Color(0xFF8FA3C8)),
            label: const Text('Clear', style: TextStyle(fontSize: 11.5, color: Color(0xFF8FA3C8))),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE2E6F0)), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          ),
        ],
      ),
    );
  }

  Widget _clubMembersStrip(StudentGroup g, Color color, Color bg, int memberCount) {
    final members = widget.students.where((s) => s.clubIds.contains(g.id)).take(12).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFFF8F9FC), border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: memberCount == 0
                ? const Text('No members yet — click Manage to add students', style: TextStyle(fontSize: 12, color: Color(0xFFB5C4D8), fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in members) _memberChip(s, g, color, bg),
                      if (memberCount > 12) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(12)), child: Text('+${memberCount - 12} more', style: const TextStyle(fontSize: 11, color: Color(0xFF4A5A7A)))),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => widget.onOpenClubModal(g),
            icon: Icon(Icons.add, size: 12, color: color),
            label: Text('Manage Members', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            style: OutlinedButton.styleFrom(backgroundColor: bg, side: BorderSide(color: color, width: 1.5), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }

  Widget _memberChip(GroupStudentRow s, StudentGroup g, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(color: bg, border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Text(initialsOf(s.name), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
        const SizedBox(width: 4),
        Text(s.name.split(' ').first, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 4),
        InkWell(onTap: () => widget.onAssignOne(s.id, g.id), child: Icon(Icons.close, size: 11, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _classRow(StudentGroup g, String cls, int index, bool isClub, List<GroupStudentRow> displayStudents, Set<int> memberIds, Color color) {
    final ss = displayStudents.where((s) => s.className == cls).toList();
    final crKey = '${g.id}-$cls';
    final crOpen = widget.openClassRows.contains(crKey);
    final empty = ss.isEmpty;
    final secs = {for (final s in ss) s.sectionName}.toList()..sort();
    final clsMembers = isClub ? ss.where((s) => memberIds.contains(s.id)).length : ss.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: empty ? null : () => widget.onToggleClassRow(crKey),
          child: Opacity(
            opacity: empty ? 0.55 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(color: Color(0xFFFAFBFD), border: Border(bottom: BorderSide(color: Color(0xFFE2E6F0)))),
              child: Row(
                children: [
                  SizedBox(width: 22, child: Text('${index + 1}'.padLeft(2, '0'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB5C4D8)))),
                  Text(cls, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Wrap(spacing: 5, runSpacing: 4, children: [
                      _badge('${ss.length} student${ss.length != 1 ? 's' : ''}', const Color(0xFFE8F4FD), const Color(0xFF2980B9)),
                      if (isClub && clsMembers > 0) _badge('$clsMembers in club', hexColor(g.bgColor), color) else if (!isClub) for (final s in secs) _badge('Sec $s', const Color(0xFFF0F2F8), const Color(0xFF8FA3C8)),
                    ]),
                  ),
                  const Spacer(),
                  if (!empty && !isClub) SizedBox(width: 70, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: 1, backgroundColor: const Color(0xFFE2E6F0), valueColor: AlwaysStoppedAnimation(color)))),
                  if (!empty && isClub && clsMembers > 0) SizedBox(width: 70, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: clsMembers / ss.length, backgroundColor: const Color(0xFFE2E6F0), valueColor: AlwaysStoppedAnimation(color)))),
                  const SizedBox(width: 8),
                  if (empty)
                    const Padding(padding: EdgeInsets.only(right: 4), child: Text('No students', style: TextStyle(fontSize: 10, color: Color(0xFFB5C4D8), fontStyle: FontStyle.italic)))
                  else
                    AnimatedRotation(turns: crOpen ? 0.25 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.chevron_right, size: 16, color: Color(0xFFB5C4D8))),
                ],
              ),
            ),
          ),
        ),
        if (!empty && crOpen) (isClub ? _classClubMembers(ss, g, color, memberIds) : _classStudentTable(ss, g, cls)),
      ],
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _classClubMembers(List<GroupStudentRow> ss, StudentGroup g, Color color, Set<int> memberIds) {
    final members = ss.where((s) => memberIds.contains(s.id)).toList();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E6F0)))),
      child: members.isEmpty
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('No members in this class — use Manage Members to add', style: TextStyle(fontSize: 12, color: Color(0xFFB5C4D8), fontStyle: FontStyle.italic)))
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in members)
                  Container(
                    padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
                    decoration: BoxDecoration(color: hexColor(g.bgColor), border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Text(initialsOf(s.name), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                      const SizedBox(width: 4),
                      Text(s.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                      const SizedBox(width: 4),
                      Text('· Sec ${s.sectionName}', style: const TextStyle(fontSize: 10, color: Color(0xFF8FA3C8))),
                      const SizedBox(width: 4),
                      widget.savingSid == s.id
                          ? const SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.5))
                          : InkWell(onTap: () => widget.onAssignOne(s.id, g.id), child: Icon(Icons.close, size: 11, color: color.withValues(alpha: 0.7))),
                    ]),
                  ),
              ],
            ),
    );
  }

  Widget _classStudentTable(List<GroupStudentRow> ss, StudentGroup g, String cls) {
    final allSelected = ss.isNotEmpty && ss.every((s) => widget.selected.contains(s.id));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: const Color(0xFFF6F8FB),
              child: Row(children: [
                SizedBox(width: 32, child: Checkbox(value: allSelected, onChanged: (v) => widget.onToggleCls(cls, v ?? false), visualDensity: VisualDensity.compact, activeColor: const Color(0xFF00B894))),
                const SizedBox(width: 150, child: Text('STUDENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF8FA3C8)))),
                const SizedBox(width: 90, child: Text('ADM NO.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF8FA3C8)))),
                const SizedBox(width: 60, child: Text('SEC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF8FA3C8)))),
                const SizedBox(width: 170, child: Text('ASSIGN GROUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF8FA3C8)))),
                const SizedBox(width: 100, child: Text('AI HINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF8FA3C8)))),
              ]),
            ),
            for (final s in ss) _studentTableRow(s, g),
          ],
        ),
      ),
    );
  }

  Widget _studentTableRow(GroupStudentRow s, StudentGroup g) {
    final selected = widget.selected.contains(s.id);
    final houseOptions = widget.allGroups.where((x) => x.isHouse).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: selected ? const Color(0x0A00B894) : null, border: const Border(bottom: BorderSide(color: Color(0xFFE2E6F0)))),
      child: Row(
        children: [
          SizedBox(width: 32, child: Checkbox(value: selected, onChanged: (v) => widget.onToggleRow(s.id, v ?? false), visualDensity: VisualDensity.compact, activeColor: const Color(0xFF00B894))),
          SizedBox(
            width: 150,
            child: Row(children: [
              Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: avatarColorFor(s.id), shape: BoxShape.circle), child: Text(initialsOf(s.name), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1A2744)), overflow: TextOverflow.ellipsis),
                    Text(s.admissionNo, style: const TextStyle(fontSize: 10.5, color: Color(0xFF8FA3C8))),
                  ],
                ),
              ),
            ]),
          ),
          SizedBox(width: 90, child: Text(s.admissionNo, style: const TextStyle(fontSize: 11, color: Color(0xFF4A5A7A)), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE8F4FD), borderRadius: BorderRadius.circular(20)), child: Text('Sec ${s.sectionName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2980B9))))),
          SizedBox(
            width: 170,
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(color: s.currentGroupId != null ? const Color(0xFFE6F9F5) : const Color(0xFFF0F2F8), border: Border.all(color: s.currentGroupId != null ? const Color(0x7300B894) : const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(6)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: s.currentGroupId,
                      isDense: true,
                      isExpanded: true,
                      hint: const Text('- Unassigned', style: TextStyle(fontSize: 11)),
                      style: TextStyle(fontSize: 11.5, color: s.currentGroupId != null ? const Color(0xFF00B894) : const Color(0xFF1A2744), fontWeight: s.currentGroupId != null ? FontWeight.w600 : FontWeight.w400),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('- Unassigned')),
                        for (final h in houseOptions) DropdownMenuItem(value: h.id, child: Text('${h.emoji} ${h.name}', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: widget.savingSid == s.id ? null : (v) => widget.onAssignOne(s.id, v),
                    ),
                  ),
                ),
              ),
              if (widget.savingSid == s.id) const Padding(padding: EdgeInsets.only(left: 5), child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))),
            ]),
          ),
          const SizedBox(width: 100, child: Text('-', style: TextStyle(fontSize: 10, color: Color(0xFFB5C4D8)))),
        ],
      ),
    );
  }
}

class _StaticChip extends StatelessWidget {
  final String label;
  const _StaticChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFF0F2F8), border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4A5A7A))),
    );
  }
}

/// Mirrors `ClubMembersModal` — a right-side drawer for bulk add/remove of
/// club members. Rendered as an in-tree Stack overlay (not a Navigator
/// route) so it stays reactively in sync with the page's live student/
/// saving state, matching the reference's own always-mounted-in-tree
/// conditional render.
class _ClubMembersDrawer extends StatefulWidget {
  final StudentGroup club;
  final List<GroupStudentRow> allStudents;
  final Future<void> Function(int sid, int? gid) onAssignOne;
  final Future<void> Function(List<int> sids, int gid) onBulkAdd;
  final int? savingSid;
  final VoidCallback onClose;

  const _ClubMembersDrawer({
    required this.club,
    required this.allStudents,
    required this.onAssignOne,
    required this.onBulkAdd,
    required this.savingSid,
    required this.onClose,
  });

  @override
  State<_ClubMembersDrawer> createState() => _ClubMembersDrawerState();
}

class _ClubMembersDrawerState extends State<_ClubMembersDrawer> {
  final _searchController = TextEditingController();
  String _search = '';
  String _clsFilter = 'ALL';
  final Set<int> _pending = {};
  bool _adding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final color = hexColor(club.color);
    final bg = hexColor(club.bgColor);
    final memberIds = widget.allStudents.where((s) => s.clubIds.contains(club.id)).map((s) => s.id).toSet();
    final members = widget.allStudents.where((s) => memberIds.contains(s.id)).toList();
    final nonMembers = widget.allStudents.where((s) => !memberIds.contains(s.id)).toList();

    final classIndexByName = <String, int>{};
    for (final s in widget.allStudents) {
      classIndexByName.putIfAbsent(s.className, () => s.classIndex);
    }
    final classes = ({for (final s in widget.allStudents) s.className}.toList())
      ..sort((a, b) => (classIndexByName[a] ?? 99).compareTo(classIndexByName[b] ?? 99));

    final query = _search.trim().toLowerCase();
    final filtered = nonMembers.where((s) {
      final matchCls = _clsFilter == 'ALL' || s.className == _clsFilter;
      final matchQ = query.isEmpty || s.name.toLowerCase().contains(query) || s.admissionNo.toLowerCase().contains(query);
      return matchCls && matchQ;
    }).toList();

    final byClass = <String, List<GroupStudentRow>>{};
    for (final s in filtered) {
      byClass.putIfAbsent(s.className, () => []).add(s);
    }

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(onTap: widget.onClose, child: Container(color: Colors.black.withValues(alpha: 0.35))),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width < 680 ? MediaQuery.of(context).size.width : 680,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 32, offset: Offset(-4, 0))]),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                    child: Row(children: [
                      Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Text(club.emoji, style: const TextStyle(fontSize: 20))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(club.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
                            Text('${members.length} / ${club.capacity} members · Use search or class tabs to find students', style: const TextStyle(fontSize: 12, color: Color(0xFF4A5A7A)), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Color(0xFF4A5A7A))),
                    ]),
                  ),
                  if (members.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: const BoxDecoration(color: Color(0xFFFAFBFE), border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('CURRENT MEMBERS (${members.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4A5A7A), letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              for (final s in members)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(4, 3, 7, 3),
                                  decoration: BoxDecoration(color: bg, border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(11)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Container(width: 16, height: 16, alignment: Alignment.center, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Text(initialsOf(s.name), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white))),
                                    const SizedBox(width: 4),
                                    Text(s.name.split(' ').first, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                                    Text(' · ${s.className} ${s.sectionName}', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
                                    const SizedBox(width: 4),
                                    widget.savingSid == s.id
                                        ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5))
                                        : InkWell(onTap: () => widget.onAssignOne(s.id, club.id), child: Icon(Icons.close, size: 10, color: color.withValues(alpha: 0.7))),
                                  ]),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search by name or admission no…',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8FA3C8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDEE), width: 1.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDEE), width: 1.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            _classTab('All Classes', nonMembers.length, _clsFilter == 'ALL', () => setState(() => _clsFilter = 'ALL'), color),
                            for (final c in classes) _classTab(c, nonMembers.where((s) => s.className == c).length, _clsFilter == c, () => setState(() => _clsFilter = c), color),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _search.isNotEmpty || _clsFilter != 'ALL' ? 'No students match your filter.' : 'All students are already members!',
                                style: const TextStyle(fontSize: 13, color: Color(0xFFB5C4D8)),
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              for (final entry in byClass.entries) _classGroup(entry.key, entry.value, color),
                            ],
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
                    child: Row(
                      children: [
                        if (_pending.isNotEmpty) ...[
                          Expanded(child: Text('${_pending.length} student${_pending.length != 1 ? 's' : ''} selected', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2744)))),
                          TextButton(onPressed: () => setState(() => _pending.clear()), child: const Text('Clear', style: TextStyle(fontSize: 12, color: Color(0xFF4A5A7A)))),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: _adding
                                ? null
                                : () async {
                                    setState(() => _adding = true);
                                    final ids = _pending.toList();
                                    setState(() => _pending.clear());
                                    await widget.onBulkAdd(ids, club.id);
                                    if (mounted) setState(() => _adding = false);
                                  },
                            icon: _adding ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add, size: 13, color: Colors.white),
                            label: Text(_adding ? 'Adding…' : 'Add ${_pending.length} to ${club.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ] else
                          const Expanded(child: Text('Select students above to add them to this club, or use the ✕ buttons to remove existing members.', style: TextStyle(fontSize: 12, color: Color(0xFFB5C4D8)))),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: widget.onClose,
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A5A7A), side: const BorderSide(color: Color(0xFFDDDDEE)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                          child: const Text('Done', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classTab(String label, int count, bool active, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: active ? color : const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(12)),
          child: Text('$label ($count)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF4A5A7A))),
        ),
      ),
    );
  }

  Widget _classGroup(String cls, List<GroupStudentRow> ss, Color color) {
    final allSelected = ss.isNotEmpty && ss.every((s) => _pending.contains(s.id));
    final selCount = ss.where((s) => _pending.contains(s.id)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          color: const Color(0xFFF5F6FA),
          child: Row(children: [
            Checkbox(
              value: allSelected,
              visualDensity: VisualDensity.compact,
              activeColor: color,
              onChanged: (v) => setState(() {
                for (final s in ss) {
                  if (v ?? false) {
                    _pending.add(s.id);
                  } else {
                    _pending.remove(s.id);
                  }
                }
              }),
            ),
            Text(cls, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
            const SizedBox(width: 6),
            Text('— ${ss.length} student${ss.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF4A5A7A))),
            const Spacer(),
            if (selCount > 0) Text('$selCount selected', style: TextStyle(fontSize: 11, color: color)),
          ]),
        ),
        for (final s in ss) _memberCandidateRow(s, color),
      ],
    );
  }

  Widget _memberCandidateRow(GroupStudentRow s, Color color) {
    final selected = _pending.contains(s.id);
    return InkWell(
      onTap: () => setState(() => selected ? _pending.remove(s.id) : _pending.add(s.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(color: selected ? color.withValues(alpha: 0.08) : null, border: const Border(bottom: BorderSide(color: Color(0xFFF3F3F3)))),
        child: Row(children: [
          Checkbox(value: selected, visualDensity: VisualDensity.compact, activeColor: color, onChanged: (v) => setState(() => (v ?? false) ? _pending.add(s.id) : _pending.remove(s.id))),
          Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? color : avatarColorFor(s.id), shape: BoxShape.circle), child: Text(initialsOf(s.name), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2744)), overflow: TextOverflow.ellipsis),
                Text('${s.admissionNo} · ${s.className} Sec ${s.sectionName}', style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
              ],
            ),
          ),
          if (s.clubIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(8)),
              child: Text('+${s.clubIds.length} club${s.clubIds.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 10, color: Color(0xFF4A5A7A))),
            ),
        ]),
      ),
    );
  }
}

/// Shared "mhd" modal header — a title/subtitle row + close button.
Widget _modalHeader(BuildContext context, String title, String subtitle, VoidCallback onClose) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 17, 20, 13),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E6F0)))),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
            ],
          ),
        ),
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF0F2F8), border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.close, size: 14, color: Color(0xFF8FA3C8)),
          ),
        ),
      ],
    ),
  );
}

/// Shared "mfoot" modal footer — Cancel + primary action button.
Widget _modalFooter({required VoidCallback? onCancel, required VoidCallback? onApply, required String applyLabel, bool loading = false, IconData? applyIcon}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 13, 20, 17),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E6F0)))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4A5A7A), side: BorderSide.none, backgroundColor: const Color(0xFFF0F2F8), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        // Flexible so long dynamic labels (e.g. "Sortwell - Divide N
        // Students") shrink/ellipsize instead of overflowing the footer Row.
        Flexible(
          child: ElevatedButton.icon(
            onPressed: onApply,
            icon: loading
                ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(applyIcon ?? Icons.check, size: 14, color: Colors.white),
            label: Text(applyLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis, maxLines: 1),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B894), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ],
    ),
  );
}

Widget _fieldLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF8FA3C8))),
    );

/// Mirrors `SWModal` — Sortwell method/scope picker with a live preview.
class _SortwellDialog extends ConsumerStatefulWidget {
  final int houseCount;
  const _SortwellDialog({required this.houseCount});

  @override
  ConsumerState<_SortwellDialog> createState() => _SortwellDialogState();
}

class _SortwellDialogState extends ConsumerState<_SortwellDialog> {
  String _method = 'random';
  String _scope = 'unassigned';
  List<SortwellPreviewItem> _preview = [];
  bool _previewLoading = true;
  bool _applying = false;

  static const _methodLabels = [('random', 'Random shuffle'), ('alpha', 'Alphabetical'), ('classwise', 'Class-wise rotation'), ('gender', 'Gender-balanced')];
  static const _methodDesc = {
    'random': 'Students randomly shuffled before distribution.',
    'alpha': 'Students sorted A-Z by name, then distributed in order.',
    'classwise': 'Each class distributed round-robin - equal class representation per house.',
    'gender': 'Students interleaved by gender for even distribution across all houses.',
  };

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() => _previewLoading = true);
    try {
      final preview = await ref.read(studentGroupRepositoryProvider).fetchSortwellPreview(_scope);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _previewLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final result = await ref.read(studentGroupRepositoryProvider).runSortwell(method: _method, scope: _scope);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _preview.fold<int>(0, (a, p) => a + p.count);
    final base = _preview.isNotEmpty ? total ~/ _preview.length : 0;
    final rem = _preview.isNotEmpty ? total % _preview.length : 0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modalHeader(context, 'Sortwell - Divide School into Houses', 'Distribute all enrolled students equally across the houses in one click', () => Navigator.of(context).pop()),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _fieldLabel('Distribution method'),
                    Wrap(spacing: 7, runSpacing: 7, children: [
                      for (final m in _methodLabels)
                        _pillChoice(m.$2, _method == m.$1, () {
                          setState(() => _method = m.$1);
                        }),
                    ]),
                    const SizedBox(height: 13),
                    _fieldLabel('Scope'),
                    Wrap(spacing: 7, runSpacing: 7, children: [
                      _pillChoice('Unassigned only', _scope == 'unassigned', () {
                        setState(() => _scope = 'unassigned');
                        _loadPreview();
                      }),
                      _pillChoice('Reassign entire school', _scope == 'all', () {
                        setState(() => _scope = 'all');
                        _loadPreview();
                      }),
                    ]),
                    if (_scope == 'all')
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(color: const Color(0xFFFEF9E7), border: Border.all(color: const Color(0xFFF6D55C)), borderRadius: BorderRadius.circular(8)),
                        child: const Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Warning: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: 'Reassign entire school will clear all existing house assignments and redistribute everyone from scratch.'),
                          ]),
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF7A5C00)),
                        ),
                      ),
                    if (_previewLoading)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()))
                    else if (_preview.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ResponsiveGrid(baseCols: 2, gap: 10, children: [for (final p in _preview) _previewCard(p)]),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: '$total student${total != 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
                                const TextSpan(text: ' → '),
                                TextSpan(text: '${_preview.length} houses', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A2744))),
                                TextSpan(text: '. Each house gets ~$base students${rem > 0 ? ' ($rem house${rem > 1 ? 's' : ''} get +1)' : ' (perfectly even)'}.'),
                              ]),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF4A5A7A), height: 1.6),
                            ),
                            const SizedBox(height: 4),
                            Text(_methodDesc[_method] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8), fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _modalFooter(
              onCancel: _applying ? null : () => Navigator.of(context).pop(),
              onApply: _applying ? null : _apply,
              applyLabel: _applying ? 'Working...' : 'Sortwell - Divide $total Students',
              loading: _applying,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillChoice(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(color: active ? const Color(0xFFE6F9F5) : const Color(0xFFF0F2F8), border: Border.all(color: active ? const Color(0xFF00B894) : const Color(0xFFE2E6F0), width: 1.5), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? const Color(0xFF00B894) : const Color(0xFF4A5A7A))),
      ),
    );
  }

  Widget _previewCard(SortwellPreviewItem p) {
    final color = hexColor(p.color);
    final bg = hexColor(p.bgColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5), color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)), child: Text(p.emoji, style: const TextStyle(fontSize: 16))),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.groupName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2744)), overflow: TextOverflow.ellipsis),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('${p.count}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(width: 4),
                const Text('students', style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Mirrors `AGModal` — create/edit a group (House, Club, or Custom).
class _GroupEditorDialog extends StatefulWidget {
  final StudentGroup? editTarget;
  final String initialType;
  final Future<void> Function(String name, String type, String emoji, String description, int capacity) onSave;
  const _GroupEditorDialog({required this.editTarget, required this.initialType, required this.onSave});

  @override
  State<_GroupEditorDialog> createState() => _GroupEditorDialogState();
}

class _GroupEditorDialogState extends State<_GroupEditorDialog> {
  late final _nameController = TextEditingController(text: widget.editTarget?.name ?? '');
  late final _emojiController = TextEditingController(text: widget.editTarget?.emoji ?? suggestEmojiFromName(widget.editTarget?.name ?? '', widget.editTarget?.type ?? widget.initialType));
  late final _descController = TextEditingController(text: widget.editTarget?.description ?? '');
  late final _capController = TextEditingController(text: '${widget.editTarget?.capacity ?? 40}');
  late String _type = widget.editTarget?.type ?? widget.initialType;
  bool _emojiTouched = false;
  bool _saving = false;
  String? _error;

  bool get isEditMode => widget.editTarget != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _descController.dispose();
    _capController.dispose();
    super.dispose();
  }

  void _onNameChanged(String v) {
    setState(() {});
    if (!_emojiTouched) {
      final unchangedEditName = widget.editTarget != null && v.trim() == (widget.editTarget?.name ?? '').trim();
      if (!unchangedEditName) _emojiController.text = suggestEmojiFromName(v, _type);
    }
  }

  Future<void> _changeType(String next) async {
    if (next == _type) return;
    final hasData = _nameController.text.trim().isNotEmpty || _descController.text.trim().isNotEmpty || _emojiTouched;
    if (hasData) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('You have entered data for this type. Changing group type may require updating emoji/description. Do you want to continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continue')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _type = next);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_nameController.text.trim(), _type, _emojiController.text.trim().isEmpty ? '📌' : _emojiController.text.trim(), _descController.text, int.tryParse(_capController.text) ?? 40);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final emojiSuggestions = _type == 'CLUB' ? kClubEmojiSuggestions : kGroupEmojiSuggestions;
    final canGenerate = _nameController.text.trim().isNotEmpty;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modalHeader(context, isEditMode ? 'Edit Group' : 'Add Student Group', 'Fill details to ${isEditMode ? 'update the' : 'create a new'} group', () => Navigator.of(context).pop()),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _fieldLabel('Group Name *'),
                    _textField(_nameController, 'e.g. Tagore House, Science Club...', onChanged: _onNameChanged),
                    const SizedBox(height: 13),
                    _fieldLabel('Group Type'),
                    Wrap(spacing: 7, children: [
                      for (final t in ['HOUSE', 'CLUB', 'CUSTOM']) _typePill(t, _type == t, () => _changeType(t)),
                    ]),
                    const SizedBox(height: 13),
                    Row(children: [
                      Expanded(child: _fieldLabel('Description')),
                      TextButton(
                        onPressed: canGenerate ? () => setState(() => _descController.text = generateDescriptionFromName(_nameController.text, _type)) : null,
                        style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0EEFF), foregroundColor: const Color(0xFF6C5CE7), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                        child: const Text('AI Help', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    _textField(_descController, 'First line: slogan\nNext lines: purpose, activities, mentor or focus...', maxLines: 3),
                    const Padding(padding: EdgeInsets.only(top: 6), child: Text('Use the first line as the slogan. The AI Help button drafts both lines from the group name.', style: TextStyle(fontSize: 10.5, color: Color(0xFF8FA3C8), height: 1.4))),
                    const SizedBox(height: 13),
                    ResponsiveGrid(baseCols: 2, gap: 11, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        _fieldLabel('Emoji'),
                        _textField(_emojiController, '📌', onChanged: (_) => setState(() => _emojiTouched = true)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final em in emojiSuggestions)
                            InkWell(
                              onTap: () => setState(() {
                                _emojiTouched = true;
                                _emojiController.text = em;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _emojiController.text == em ? const Color(0xFFE6F9F5) : const Color(0xFFF0F2F8),
                                  border: Border.all(color: _emojiController.text == em ? const Color(0xFF00B894) : const Color(0xFFE2E6F0), width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(em, style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                        ]),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        _fieldLabel('Capacity'),
                        _textField(_capController, '40', keyboardType: TextInputType.number),
                      ]),
                    ]),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            _modalFooter(
              onCancel: _saving ? null : () => Navigator.of(context).pop(),
              onApply: _saving ? null : _save,
              applyLabel: isEditMode ? 'Save Changes' : 'Create Group',
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typePill(String t, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: active ? const Color(0xFFE6F9F5) : const Color(0xFFF0F2F8), border: Border.all(color: active ? const Color(0xFF00B894) : const Color(0xFFE2E6F0), width: 1.5), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? const Color(0xFF00B894) : const Color(0xFF4A5A7A))),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A2744)),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8)),
        filled: true,
        fillColor: const Color(0xFFF0F2F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00B894))),
      ),
    );
  }
}

/// Mirrors `ACModal` — create a new Club (type is fixed, no picker).
class _AddClubDialog extends StatefulWidget {
  final Future<void> Function(String name, String emoji, String description, int capacity) onSave;
  const _AddClubDialog({required this.onSave});

  @override
  State<_AddClubDialog> createState() => _AddClubDialogState();
}

class _AddClubDialogState extends State<_AddClubDialog> {
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🎭');
  final _descController = TextEditingController();
  final _capController = TextEditingController(text: '30');
  bool _emojiTouched = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _descController.dispose();
    _capController.dispose();
    super.dispose();
  }

  void _onNameChanged(String v) {
    setState(() {});
    if (!_emojiTouched) _emojiController.text = suggestEmojiFromName(v, 'CLUB');
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_nameController.text.trim(), _emojiController.text.trim().isEmpty ? '🎭' : _emojiController.text.trim(), _descController.text, int.tryParse(_capController.text) ?? 30);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate = _nameController.text.trim().isNotEmpty;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modalHeader(context, 'Add New Club', 'Create a new school club and start adding members', () => Navigator.of(context).pop()),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _fieldLabel('Club Name *'),
                    _textField(_nameController, 'e.g. Chess Club, Drama Club...', onChanged: _onNameChanged),
                    const SizedBox(height: 13),
                    Row(children: [
                      Expanded(child: _fieldLabel('Description')),
                      TextButton(
                        onPressed: canGenerate ? () => setState(() => _descController.text = generateDescriptionFromName(_nameController.text, 'CLUB')) : null,
                        style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0EEFF), foregroundColor: const Color(0xFF6C5CE7), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                        child: const Text('AI Help', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    _textField(_descController, 'First line: slogan\nNext lines: club purpose, activities, events or mentor...', maxLines: 3),
                    const Padding(padding: EdgeInsets.only(top: 6), child: Text('Use the first line as the slogan. The AI Help button drafts both lines from the club name.', style: TextStyle(fontSize: 10.5, color: Color(0xFF8FA3C8), height: 1.4))),
                    const SizedBox(height: 13),
                    ResponsiveGrid(baseCols: 2, gap: 11, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        _fieldLabel('Emoji'),
                        _textField(_emojiController, '🎭', onChanged: (_) => setState(() => _emojiTouched = true)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final em in kClubEmojiSuggestions)
                            InkWell(
                              onTap: () => setState(() {
                                _emojiTouched = true;
                                _emojiController.text = em;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _emojiController.text == em ? const Color(0xFFE6F9F5) : const Color(0xFFF0F2F8),
                                  border: Border.all(color: _emojiController.text == em ? const Color(0xFF00B894) : const Color(0xFFE2E6F0), width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(em, style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                        ]),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        _fieldLabel('Max Capacity'),
                        _textField(_capController, '30', keyboardType: TextInputType.number),
                      ]),
                    ]),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            _modalFooter(
              onCancel: _saving ? null : () => Navigator.of(context).pop(),
              onApply: _saving ? null : _save,
              applyLabel: 'Create Club',
              applyIcon: Icons.add,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A2744)),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8)),
        filled: true,
        fillColor: const Color(0xFFF0F2F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00B894))),
      ),
    );
  }
}
