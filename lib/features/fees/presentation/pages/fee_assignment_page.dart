import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../student/domain/models/academic_year.dart';
import '../../../student/domain/models/school_class.dart';
import '../../domain/models/assignment_student.dart';
import '../../domain/models/fee_assignment.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fee_schedule.dart';
import '../../domain/models/fee_type.dart';
import '../providers/fees_assignment_providers.dart';
import '../providers/fees_config_providers.dart';
import '../utils/fee_assignment_format.dart';
import '../widgets/fa_assign_edit_dialog.dart';
import '../widgets/fa_bulk_assign_dialog.dart';
import '../widgets/fa_change_plan_dialog.dart';
import '../widgets/fa_info_dialog.dart';
import '../widgets/fee_assignment_styles.dart';
import '../widgets/fee_schedule_table.dart' show FeeRow;
import '../widgets/fees_layout.dart';

class _Override {
  final String group;
  final double annual;
  final String? concession;
  const _Override({required this.group, required this.annual, this.concession});
}

class FaRosterStudent {
  final String id;
  final String name;
  final String admNo;
  final String category; // fee group name, or "Unassigned" / "Assigned"
  final bool planAgreed;
  const FaRosterStudent({required this.id, required this.name, required this.admNo, required this.category, required this.planAgreed});
}

class FaClassRoster {
  final String id;
  final String name;
  final List<FaRosterStudent> students;
  const FaClassRoster({required this.id, required this.name, required this.students});
}

const _concessions = ['None', 'Staff Ward 50%', 'Merit 25%', 'Need-Based Full', 'Sibling 10%'];

/// Fee Assignment — converted from
/// `frontend/components/fees/FeesAssignmentPanel.tsx` (the "Fee Assignment"
/// tab of the Fees module, `/fees/fee-assignment`).
///
/// Reuses [feesConfigRepositoryProvider] for fee groups/types/schedules/
/// academic years (same live data as the Fee Configuration screen) and
/// [feesAssignmentRepositoryProvider] for what's new here: the student
/// roster (with class info) and fee-assignment CRUD.
class FeeAssignmentPage extends ConsumerStatefulWidget {
  const FeeAssignmentPage({super.key});

  @override
  ConsumerState<FeeAssignmentPage> createState() => _FeeAssignmentPageState();
}

class _FeeAssignmentPageState extends ConsumerState<FeeAssignmentPage> {
  bool _loading = true;
  List<AssignmentStudent> _students = [];
  List<SchoolClass> _classes = [];
  List<FeeAssignment> _assignments = [];
  List<FeesGroup> _groups = [];
  List<FeeSchedule> _schedules = [];
  List<FeesType> _feeTypes = [];
  List<AcademicYear> _years = [];

  final _searchCtrl = TextEditingController();
  int? _yearFilter;
  String _classFilter = 'all';
  String _groupFilter = 'all';
  String _tab = 'all'; // all | unassigned | assigned
  final Set<String> _expanded = {};
  final Set<String> _selected = {};
  String? _toast;
  final Map<String, _Override> _overrides = {};

  @override
  void initState() {
    super.initState();
    _loadYears();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    setState(() => _toast = message);
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && _toast == message) setState(() => _toast = null);
    });
  }

  Future<void> _loadYears() async {
    setState(() => _loading = true);
    try {
      final years = await ref.read(feesConfigRepositoryProvider).fetchAcademicYears();
      if (!mounted) return;
      final current = years.where((y) => y.isCurrent).firstOrNull ?? years.firstOrNull;
      setState(() {
        _years = years;
        _yearFilter = current?.id;
      });
      if (_yearFilter != null) await _loadForYear(_yearFilter);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadForYear(int? yearId) async {
    setState(() => _loading = true);
    final configRepo = ref.read(feesConfigRepositoryProvider);
    final assignmentRepo = ref.read(feesAssignmentRepositoryProvider);
    try {
      final results = await Future.wait([
        assignmentRepo.fetchStudents(academicYear: yearId).catchError((_) => <AssignmentStudent>[]),
        configRepo.fetchClasses().catchError((_) => <SchoolClass>[]),
        assignmentRepo.fetchAssignments(academicYear: yearId).catchError((_) => <FeeAssignment>[]),
        configRepo.fetchGroups().catchError((_) => <FeesGroup>[]),
        configRepo.fetchSchedules(page: 1, pageSize: 1000).then((r) => r.rows).catchError((_) => <FeeSchedule>[]),
        configRepo.fetchTypes(page: 1, pageSize: 500).then((r) => r.rows).catchError((_) => <FeesType>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _students = results[0] as List<AssignmentStudent>;
        _classes = results[1] as List<SchoolClass>;
        _assignments = results[2] as List<FeeAssignment>;
        _groups = results[3] as List<FeesGroup>;
        _schedules = results[4] as List<FeeSchedule>;
        _feeTypes = results[5] as List<FeesType>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshAssignments() async {
    final fresh = await ref.read(feesAssignmentRepositoryProvider).fetchAssignments(academicYear: _yearFilter);
    if (mounted) setState(() => _assignments = fresh);
  }

  // ── Derived data (mirrors the source's useMemo blocks) ──────────────────

  Map<String, List<FeeRow>> get _feeSchedulesByGroup {
    final feeTypeNameById = {for (final t in _feeTypes) t.id.toString(): t.name};
    final map = <String, List<FeeRow>>{};
    for (final g in _groups) {
      final gScheds = _schedules.where((s) => s.feeGroup?.toString() == g.id.toString());
      map[g.name] = gScheds
          .map((s) => FeeRow(
                type: s.feeTypeName ?? feeTypeNameById[s.feeType.toString()] ?? 'Fee Type #${s.feeType}',
                schedule: s.collectionFrequency.isEmpty ? 'Term-wise' : s.collectionFrequency,
                annual: double.tryParse(s.amount) ?? 0,
              ))
          .toList();
    }
    return map;
  }

  Map<String, double?> get _annualFeeByGroup {
    final schedules = _feeSchedulesByGroup;
    final map = <String, double?>{'Unassigned': null};
    for (final g in _groups) {
      map[g.name] = (schedules[g.name] ?? const []).fold<double>(0, (s, r) => s + r.annual);
    }
    return map;
  }

  List<FeeAssignment> get _latestAssignments {
    final latest = <String, FeeAssignment>{};
    for (final a in _assignments) {
      final key = '${a.student}-${a.feesType}';
      final existing = latest[key];
      if (existing == null || a.id > existing.id) latest[key] = a;
    }
    return latest.values.toList();
  }

  Map<String, double> get _studentConcessionPct {
    final map = <String, double>{};
    for (final a in _latestAssignments) {
      final sid = a.student.toString();
      if (map.containsKey(sid)) continue;
      final concAmt = double.tryParse(a.concessionAmount) ?? 0;
      final amt = double.tryParse(a.amount) ?? 0;
      if (concAmt > 0 && amt > 0) map[sid] = concAmt / amt;
    }
    return map;
  }

  Map<String, double> get _studentNetAnnual {
    final map = <String, double>{};
    for (final a in _latestAssignments) {
      final sid = a.student.toString();
      final net = (double.tryParse(a.amount) ?? 0) - (double.tryParse(a.discountAmount) ?? 0) - (double.tryParse(a.concessionAmount) ?? 0);
      map[sid] = (map[sid] ?? 0) + net;
    }
    return map;
  }

  List<FaClassRoster> get _classData {
    final classMap = <String, FaClassRoster>{};
    for (final c in _classes) {
      classMap[c.id.toString()] = FaClassRoster(id: c.id.toString(), name: c.name, students: []);
    }
    for (final st in _students) {
      final clsId = st.currentClassId?.toString() ?? 'unassigned';
      classMap.putIfAbsent(clsId, () => FaClassRoster(id: clsId, name: st.currentClassName ?? 'Unassigned', students: []));

      final stAsgns = _assignments.where((a) => a.student.toString() == st.id.toString()).toList();
      final isAssigned = stAsgns.isNotEmpty;
      var cat = 'Unassigned';
      if (isAssigned) {
        final asgn = stAsgns.first;
        final sched = _schedules.where((s) => s.feeType.toString() == asgn.feesType.toString()).firstOrNull;
        if (sched != null) {
          final grp = _groups.where((g) => g.id.toString() == sched.feeGroup?.toString()).firstOrNull;
          cat = grp?.name ?? 'Assigned';
        } else {
          cat = 'Assigned';
        }
      }

      classMap[clsId]!.students.add(FaRosterStudent(
            id: st.id.toString(),
            name: st.fullName,
            admNo: st.admissionNo.isEmpty ? 'ID-${st.id}' : st.admissionNo,
            category: cat,
            planAgreed: isAssigned,
          ));
    }
    return classMap.values.where((c) => c.students.isNotEmpty).toList();
  }

  int get _totalStudents => _classData.fold(0, (s, c) => s + c.students.length);

  String _effectiveCat(FaRosterStudent st) => _overrides[st.id]?.group ?? st.category;
  bool _isAssigned(FaRosterStudent st) => _overrides.containsKey(st.id) || st.category != 'Unassigned';

  ({int assigned, int unassigned, int total}) get _stats {
    var asgn = 0;
    for (final cls in _classData) {
      for (final st in cls.students) {
        if (_isAssigned(st)) asgn++;
      }
    }
    final total = _totalStudents;
    return (assigned: asgn, unassigned: total - asgn, total: total);
  }

  List<FaClassRoster> get _filteredClasses {
    final q = _searchCtrl.text.toLowerCase();
    return _classData
        .where((cls) => _classFilter == 'all' || cls.id == _classFilter)
        .map((cls) => FaClassRoster(
              id: cls.id,
              name: cls.name,
              students: cls.students.where((st) {
                final eCat = _effectiveCat(st);
                final asgnd = _isAssigned(st);
                final mSearch = q.isEmpty || st.name.toLowerCase().contains(q) || st.admNo.toLowerCase().contains(q);
                final mTab = _tab == 'all' || (_tab == 'unassigned' ? !asgnd : asgnd);
                final mGroup = _groupFilter == 'all' || eCat == _groupFilter;
                return mSearch && mTab && mGroup;
              }).toList(),
            ))
        .where((cls) => cls.students.isNotEmpty)
        .toList();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _openAssignModal(FaRosterStudent st, String clsName, {required bool isEdit}) async {
    if (_yearFilter == null) {
      _showToast('Please select an academic year before saving.');
      return;
    }
    final initialGroup = isEdit ? _effectiveCat(st) : (_groups.firstOrNull?.name ?? '');
    String initialConcession = 'None';
    if (isEdit) {
      final ov = _overrides[st.id];
      if (ov?.concession != null) {
        initialConcession = ov!.concession!;
      } else {
        final stAsgns = _assignments.where((a) => a.student.toString() == st.id).toList();
        final latestPerType = <String, FeeAssignment>{};
        for (final a in stAsgns) {
          final k = a.feesType.toString();
          final existing = latestPerType[k];
          if (existing == null || a.id > existing.id) latestPerType[k] = a;
        }
        for (final a in latestPerType.values) {
          final concAmt = double.tryParse(a.concessionAmount) ?? 0;
          final amt = double.tryParse(a.amount) ?? 0;
          if (concAmt > 0 && amt > 0) {
            final pct = concAmt / amt;
            final matched = _concessions.where((c) => (parseConcessionPctFromLabel(c) - pct).abs() < 0.01 && c != 'None').firstOrNull;
            if (matched != null) {
              initialConcession = matched;
              break;
            }
          }
        }
      }
    }

    final result = await FaAssignEditDialog.show(
      context,
      studentName: st.name,
      studentAdmNo: st.admNo,
      className: clsName,
      isEdit: isEdit,
      initialGroup: initialGroup,
      initialConcession: initialConcession,
      groups: _groups,
      feeSchedules: _feeSchedulesByGroup,
      concessions: _concessions,
      schedules: _schedules,
      studentId: int.parse(st.id),
      academicYearId: _yearFilter!,
      existingAssignments: _assignments,
    );
    if (result == null) return;
    await _refreshAssignments();
    setState(() => _overrides[st.id] = _Override(group: result.group, annual: result.netAnnual, concession: result.concession));
    _showToast('${isEdit ? "Assignment updated" : "Fees assigned"} for ${st.name} — ${result.group}.');
  }

  Future<void> _openChangePlan(FaRosterStudent st) async {
    final plan = await FaChangePlanDialog.show(context, studentName: st.name);
    if (plan != null) _showToast('Payment plan switched to ${plan.label} for ${st.name}.');
  }

  Future<void> _openBulkModal(String clsId, String clsName) async {
    if (_yearFilter == null) {
      _showToast('Please select an academic year before bulk assigning.');
      return;
    }
    final result = await FaBulkAssignDialog.show(
      context,
      initialClassId: clsId,
      classData: _classData,
      groups: _groups,
      selectedStudentIds: _selected,
      feeSchedules: _feeSchedulesByGroup,
      schedules: _schedules,
      assignments: _assignments,
      academicYearId: _yearFilter!,
      isAssignedFn: _isAssigned,
    );
    if (result == null) return;
    await _refreshAssignments();
    setState(() {
      for (final sid in result.assignedStudentIds) {
        _overrides[sid] = _Override(group: result.group, annual: result.annualTotal);
      }
      _selected.clear();
    });
    if (result.errors.isNotEmpty) {
      _showToast('Bulk assign: ${result.successCount} succeeded, ${result.errors.length} failed — ${result.errors.first}');
    } else if (result.assignedStudentIds.isEmpty) {
      _showToast(_selected.isNotEmpty ? 'All selected students are already assigned.' : 'All students in ${clsId == 'all' ? 'all classes' : 'this class'} are already assigned.');
    } else {
      _showToast('Bulk assigned ${result.assignedStudentIds.length} student(s) to ${result.group}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final filtered = _filteredClasses;

    return FeesLayout(
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStatsBar(stats),
                  Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFCD34D), Color(0xFFFEF3C7)]))),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  _buildTabs(stats),
                  const SizedBox(height: 8),
                  for (final cls in filtered) ...[_buildClassCard(cls), const SizedBox(height: 12)],
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          _loading ? 'Loading students...' : (_students.isEmpty ? 'No students found. Please check if you have access to this school or if students have been enrolled.' : 'No students match the current filters.'),
                          style: const TextStyle(color: faInk3, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_toast != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 28, offset: Offset(0, 8))]),
                    child: Text(_toast!, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Its own card — same white/gray-bordered style already used by the
    // stats bar / filters block, the class cards below, and the equivalent
    // headers on Fees Home and Fee Configuration — instead of floating text
    // directly on the page background.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: faBorder),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('STUDENT FEE MAPPING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: faPurple)),
              SizedBox(height: 6),
              Text('Fee Assignment', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: faInk1, height: 1.1)),
              SizedBox(height: 8),
              Text('Assign fee structures to students class by class, with concession and override support.', style: TextStyle(fontSize: 14, color: faInk3)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => FaInfoDialog.show(context),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: faBorder, width: 1.5)),
                  child: const Text('i', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: faPurple)),
                ),
              ),
              const SizedBox(width: 10),
              FaPrimaryButton(label: '+ Bulk Assign', onPressed: () => _openBulkModal('all', 'All Classes')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(({int assigned, int unassigned, int total}) stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(color: Colors.white, border: Border.fromBorderSide(BorderSide(color: faBorder)), borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13.5, color: faInk2),
              children: [
                TextSpan(text: '${stats.assigned}', style: const TextStyle(fontWeight: FontWeight.w700, color: faInk1)),
                const TextSpan(text: ' assigned · '),
                TextSpan(text: '${stats.unassigned}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                const TextSpan(text: ' unassigned · '),
                TextSpan(text: '${stats.total}', style: const TextStyle(fontWeight: FontWeight.w700, color: faInk1)),
                const TextSpan(text: ' total students'),
              ],
            ),
          ),
          FaOutlineButton(small: true, label: 'Assign all unassigned →', color: faPurple, borderColor: const Color(0xFFC4B5FD), onPressed: () => _openBulkModal('all', 'All Classes')),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: faBorder), right: BorderSide(color: faBorder), bottom: BorderSide(color: faBorder)), borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        children: [
          SizedBox(
            width: 260,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('SEARCH', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: faInk3)),
              const SizedBox(height: 7),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Name or admission number...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: faBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: faBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: faPurple)),
                ),
              ),
            ]),
          ),
          SizedBox(width: 140, child: _dropdownFilter('YEAR', _yearFilter, [for (final y in _years) y.id], (id) => _years.where((y) => y.id == id).firstOrNull?.name ?? 'Select year', (v) {
                setState(() => _yearFilter = v);
                _loadForYear(v);
              })),
          SizedBox(width: 160, child: _dropdownFilter('CLASS', _classFilter, ['all', for (final c in _classData) c.id], (id) => id == 'all' ? 'All Classes' : _classData.firstWhere((c) => c.id == id).name.replaceFirst('Class ', ''), (v) => setState(() => _classFilter = v ?? 'all'))),
          SizedBox(width: 170, child: _dropdownFilter('FEE GROUP', _groupFilter, ['all', for (final g in _groups) g.name], (name) => name == 'all' ? 'All Groups' : name, (v) => setState(() => _groupFilter = v ?? 'all'))),
        ],
      ),
    );
  }

  Widget _dropdownFilter<T>(String label, T value, List<T> items, String Function(T) labelOf, ValueChanged<T?> onChanged) {
    final safeItems = items.contains(value) ? items : [value, ...items];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: faInk3)),
        const SizedBox(height: 7),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: faBorder), borderRadius: BorderRadius.circular(9)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF8B8EA8)),
              style: const TextStyle(fontSize: 13.5, color: faInk1),
              items: [for (final i in safeItems) DropdownMenuItem(value: i, child: Text(labelOf(i), overflow: TextOverflow.ellipsis))],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(({int assigned, int unassigned, int total}) stats) {
    final tabs = [
      ('all', 'All ${stats.total}'),
      ('unassigned', 'Unassigned ${stats.unassigned}'),
      ('assigned', 'Assigned ${stats.assigned}'),
    ];
    // A plain `Row` here overflowed on narrow phones once the counts grew to
    // 2-3 digits — every other row on this page (header, stats bar, filters,
    // class-card header) already had to switch to `Wrap` for the same
    // reason. `Wrap` would drop pills to a second line instead, which reads
    // oddly for a tab strip, so this uses the same horizontal-scroll
    // convention already used for Fee Configuration's own tab-pill row.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in tabs) ...[
            _tabPill(t.$1, t.$2),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _tabPill(String key, String label) {
    final isActive = _tab == key;
    return InkWell(
      onTap: () => setState(() => _tab = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? faPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: faBorder),
          boxShadow: isActive ? const [BoxShadow(color: Color(0x386D4AFF), blurRadius: 8, offset: Offset(0, 2))] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : faInk2)),
      ),
    );
  }

  Widget _buildClassCard(FaClassRoster cls) {
    final origCls = _classData.firstWhere((c) => c.id == cls.id);
    final totalCls = origCls.students.length;
    final asgndCls = origCls.students.where(_isAssigned).length;
    final isExpanded = _expanded.contains(cls.id);
    final allSel = cls.students.isNotEmpty && cls.students.every((s) => _selected.contains(s.id));

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: faBorder), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            // `Row` (not `Wrap`) with an `Expanded` name column reliably
            // overflowed at phone widths: the accent bar + "Bulk Assign"
            // button + "N shown" toggle's combined natural width alone
            // (independent of how long the class name is) can exceed a
            // narrow phone's available width — `Expanded` only shrinks the
            // name column, it can't make its non-flex siblings any
            // narrower. The roster table below already got a phone-width
            // fix (see `_rosterTable`'s comment); this header row needed
            // the same attention. `Wrap` lets the button/toggle cluster
            // drop to its own line instead, matching the page's own header
            // (`_buildHeader`) and stats bar, which already use `Wrap` for
            // exactly this reason.
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 4, height: 44, decoration: BoxDecoration(color: faPurple, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cls.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: faInk1), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text(
                            '$totalCls students · $asgndCls assigned · ${totalCls - asgndCls} unassigned',
                            style: const TextStyle(fontSize: 12.5, color: faInk3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                FaOutlineButton(small: true, label: 'Bulk Assign', onPressed: () => _openBulkModal(cls.id, cls.name)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => isExpanded ? _expanded.remove(cls.id) : _expanded.add(cls.id)),
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(border: Border.all(color: faBorder), borderRadius: BorderRadius.circular(7)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${cls.students.length} shown', style: const TextStyle(fontSize: 12.5, color: faInk2)),
                        const SizedBox(width: 8),
                        AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more, size: 16, color: faInk2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) _rosterTable(cls, allSel),
        ],
      ),
    );
  }

  // Six columns (checkbox + student + 4 data columns + actions) don't fit a
  // phone width as a flexible Row without cramming/overlapping text (found
  // via a populated-data browser check — the source's own <table> just
  // relies on desktop width). Matches the same fixed-column +
  // horizontal-scroll convention already used for wide tables elsewhere in
  // this app (e.g. academics/.../staff_workload_tab.dart) rather than
  // dropping or shrinking any column.
  static const _colCheck = 44.0;
  static const _colStudent = 220.0;
  static const _colSchedules = 170.0;
  static const _colAnnual = 110.0;
  static const _colPlan = 150.0;
  static const _colActions = 260.0;
  // Header/row Containers each add 16px of horizontal padding per side (32px
  // total) around their column Row — the outer SizedBox must include that or
  // every row overflows by exactly that 32px.
  static const _rowHorizontalPadding = 32.0;
  static const _tableWidth = _colCheck + _colStudent + _colSchedules + _colAnnual + _colPlan + _colActions + _rowHorizontalPadding;

  Widget _rosterTable(FaClassRoster cls, bool allSel) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: faBorder))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFFF8F8FB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    SizedBox(width: _colCheck, child: Checkbox(value: allSel, onChanged: (_) => _toggleSelectAll(cls.students, allSel))),
                    const SizedBox(width: _colStudent, child: Text('STUDENT', style: faThStyle)),
                    SizedBox(width: _colSchedules, child: const Row(children: [Text('PAYMENT SCHEDULES', style: faThStyle), FaInfoDot()])),
                    SizedBox(width: _colAnnual, child: const Row(children: [Text('ANNUAL TOTAL', style: faThStyle), FaInfoDot()])),
                    SizedBox(width: _colPlan, child: const Row(children: [Text('AGREED PLAN', style: faThStyle), FaInfoDot()])),
                    const SizedBox(width: _colActions, child: Text('ACTIONS', style: faThStyle)),
                  ],
                ),
              ),
              for (var i = 0; i < cls.students.length; i++) _studentRow(cls.students[i], cls.name, i < cls.students.length - 1),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelectAll(List<FaRosterStudent> students, bool all) {
    setState(() {
      for (final s in students) {
        if (all) {
          _selected.remove(s.id);
        } else {
          _selected.add(s.id);
        }
      }
    });
  }

  Widget _studentRow(FaRosterStudent st, String clsName, bool hasDivider) {
    final ov = _overrides[st.id];
    final asgnd = _isAssigned(st);
    final eCat = _effectiveCat(st);
    double? annual;
    if (!asgnd) {
      annual = _annualFeeByGroup[st.category];
    } else if (ov != null) {
      annual = ov.annual;
    } else {
      final schedRows = _feeSchedulesByGroup[eCat] ?? const [];
      if (schedRows.isNotEmpty) {
        final pct = _studentConcessionPct[st.id] ?? 0;
        annual = schedRows.fold<double>(0, (s, r) => s + r.annual * (1 - pct));
      } else {
        annual = _studentNetAnnual[st.id] ?? _annualFeeByGroup[st.category];
      }
    }
    final isSel = _selected.contains(st.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSel ? const Color(0xFFF5F3FF) : Colors.white,
        border: Border(bottom: hasDivider ? const BorderSide(color: faBorder) : BorderSide.none),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _colCheck, child: Checkbox(value: isSel, onChanged: (_) => setState(() => isSel ? _selected.remove(st.id) : _selected.add(st.id)))),
          SizedBox(
            width: _colStudent,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: avatarBg(st.name)),
                  child: Text(initials(st.name), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(st.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: faInk1), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${st.admNo} · ', style: const TextStyle(fontSize: 12, color: faInk3)),
                          TextSpan(text: eCat, style: TextStyle(fontSize: 12, color: !asgnd ? const Color(0xFFF59E0B) : faInk2)),
                        ]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _colSchedules,
            child: !asgnd
                ? const Text('—', style: TextStyle(color: faInk3, fontSize: 15))
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF0F0F8), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0E0F0))),
                      child: const Text('Group schedule', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: faInk1)),
                    ),
                  ),
          ),
          SizedBox(
            width: _colAnnual,
            child: Text(
              annual != null ? fmtRs(annual) : '—',
              style: TextStyle(fontSize: 13.5, fontWeight: annual != null ? FontWeight.w600 : FontWeight.w400, color: annual != null ? faInk1 : faInk3),
            ),
          ),
          SizedBox(
            width: _colPlan,
            child: Align(
              alignment: Alignment.centerLeft,
              child: (st.planAgreed || ov != null)
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF86EFAC))),
                      child: const Text('✓ Plan Agreed', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                      child: const Text('No plan yet', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                    ),
            ),
          ),
          SizedBox(
            width: _colActions,
            child: !asgnd
                ? Align(alignment: Alignment.centerLeft, child: FaPrimaryButton(small: true, label: 'Assign →', onPressed: () => _openAssignModal(st, clsName, isEdit: false)))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FaOutlineButton(small: true, label: 'Edit Assignment', onPressed: () => _openAssignModal(st, clsName, isEdit: true)),
                      FaOutlineButton(small: true, label: 'Change Plan', onPressed: () => _openChangePlan(st)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors `parseConcessionPct` for matching a stored ratio back to one of
/// the fixed [_concessions] labels (used only by `_openAssignModal`'s
/// inferred-concession lookup — the shared parser lives in
/// fee_schedule_table.dart for the live modal itself).
double parseConcessionPctFromLabel(String c) {
  final m = RegExp(r'(\d+(\.\d+)?)\s*%').firstMatch(c);
  if (m != null) return double.parse(m.group(1)!) / 100;
  if (RegExp('full', caseSensitive: false).hasMatch(c)) return 1;
  return 0;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
