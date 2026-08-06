import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/local/shared_prefs.dart';
import '../../domain/models/subject_assignment.dart';
import '../providers/student_providers.dart';
import '../widgets/subject_assignment_widgets.dart';

/// Multi Subject Assignment — full pixel-for-pixel port of frontend
/// components/students/StudentMultiClassPanel.tsx +
/// StudentMultiClassPanel.module.css.
///
/// Naming note (disclosed, confirmed against the real frontend/backend): the
/// frontend's route folder is named "multi-class" but the actual rendered
/// page is titled "Multi Subject Assignment" and manages optional
/// per-student subjects (2nd/3rd language, sport, art) — not literal
/// multiple homeroom class membership. A genuine "multiple classes per
/// student" model exists server-side (`StudentMultiClassRecord`) but no
/// frontend screen consumes it, so this ports the real, routed page.
///
/// Known reference-frontend quirks ported verbatim (not "fixed" here,
/// since the mandate is to reproduce the frontend exactly):
///  - Section 01's own "Save & assign to student" button does NOT call the
///    upsert-optional API in the reference either (`StudentMultiClassPanel.tsx`
///    `btnSave` handler only clears a localStorage placeholder and calls
///    `router.push("/students/list")`) — it has no real student id to save
///    against. Only the Browse & Edit → row editor has a real student id and
///    actually calls the backend (`upsert-optional`).
///  - The Smart Filter (section 02) search box and all six dropdowns are not
///    wired to any filtering logic in the reference frontend either — it's a
///    static facade there too (no `onChange`/state, "Apply" just closes the
///    panel). No existing Django endpoint supports this search/class/section/
///    language/sport/art combination query either (`class-section-tree` and
///    `section-students` take no search or subject filters, and
///    `StudentViewSet` has no `SearchFilter`), so per this project's
///    reuse-only-existing-backend policy this stays a facade, matching
///    the reference exactly.
///  - The class/section "done"/"pending" pill counts and the Sports/Arts/
///    Clubs activity ticker are derived only from each section's initial
///    page-1 snapshot (`class-section-tree`), not from later-paginated or
///    locally-edited rows — exactly like the reference's `classList` state.
///  - The AI-suggestion banner calls a real Next.js API route
///    (`/api/ai-subject-suggest`) that proxies to Anthropic's API and falls
///    back to a hardcoded suggestion when no API key is configured, so it
///    does render successfully in the reference app — it does NOT 404. It
///    has no Django backend equivalent, so this port omits the banner rather
///    than fabricate a Django-backed AI endpoint that doesn't exist.
class StudentSubjectAssignmentPage extends ConsumerStatefulWidget {
  const StudentSubjectAssignmentPage({super.key});

  @override
  ConsumerState<StudentSubjectAssignmentPage> createState() => _StudentSubjectAssignmentPageState();
}

enum _Tab { assign, filter, browse }

const List<String> kMandatoryDefault = ['English', 'Maths', 'Science', 'Social', 'Computers', 'PT', 'Art & Craft'];

const Map<String, String> kClassSubLabels = {
  'Nursery': 'Pre-Nursery / Nursery', 'LKG': 'Lower Kindergarten', 'UKG': 'Upper Kindergarten',
  'Class 1': 'Primary', 'Class 2': 'Primary', 'Class 3': 'Primary', 'Class 4': 'Primary', 'Class 5': 'Primary',
  'Class 6': 'Middle School', 'Class 7': 'Middle School', 'Class 8': 'Middle School',
  'Class 9': 'Secondary', 'Class 10': 'Secondary', 'Class 11': 'Senior Secondary', 'Class 12': 'Senior Secondary',
};

const List<Color> kAvatarColors = [
  Color(0xFF6C4CF1), Color(0xFF1EB980), Color(0xFFF5A623), Color(0xFF2C56A1),
  Color(0xFFA0264A), Color(0xFF5638D4), Color(0xFF915A1A), Color(0xFFE5534B),
];

/// Mirrors `getMandatoryForClass` — regex-matched against the *raw* class
/// label string exactly as the reference does (Nursery/LKG/UKG match
/// regardless of format; the "Class N" regexes only match if the backend's
/// class name literally reads "Class N", which — per `apps/core/models.py`
/// `Class.class_names` — it does not (classes are named "Grade N"), so
/// numbered grades fall through to [kMandatoryDefault] there too, same as
/// in the live reference deployment).
List<String> getMandatoryForClass(String label) {
  if (RegExp(r'Nursery|LKG|UKG', caseSensitive: false).hasMatch(label)) {
    return ['General Studies', 'Drawing & Crafts', 'Stories & Rhymes', 'Play & Motor Skills', 'Music', 'PT & Games'];
  }
  if (RegExp(r'Class [1-5]$', caseSensitive: false).hasMatch(label)) {
    return ['English', 'Maths', 'Science', 'Social Studies', 'EVS', 'PT & Games', 'Art & Craft'];
  }
  if (RegExp(r'Class [6-8]$', caseSensitive: false).hasMatch(label)) {
    return ['English', 'Maths', 'Science', 'Social Studies', 'Computers', 'PT & Games', 'Art & Craft'];
  }
  if (RegExp(r'Class 9|Class 10', caseSensitive: false).hasMatch(label)) {
    return ['English', 'Maths', 'Physics', 'Chemistry', 'Biology', 'Social Science', 'Computer Science'];
  }
  if (RegExp(r'Class 11|Class 12', caseSensitive: false).hasMatch(label)) {
    return ['English', 'Mathematics', 'Physics', 'Chemistry', 'Computer Science', 'PT'];
  }
  return kMandatoryDefault;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final letters = parts.map((p) => p[0]).join();
  return letters.substring(0, letters.length < 2 ? letters.length : 2).toUpperCase();
}

Color _avatarBg(String name) {
  if (name.isEmpty) return kAvatarColors[0];
  return kAvatarColors[name.codeUnitAt(0) % kAvatarColors.length];
}

/// A thin horizontal dashed rule — mirrors `border-top: 1px dashed`.
class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, this.color = const Color(0xFFE8E3D8)});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const dashWidth = 4.0, dashGap = 3.0;
      final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
      return Flex(
        direction: Axis.horizontal,
        children: List.generate(count, (_) => const SizedBox(width: dashWidth, height: 1))
            .map((box) => Container(width: dashWidth, height: 1, margin: const EdgeInsets.only(right: dashGap), color: color))
            .toList(),
      );
    });
  }
}

class _StudentSubjectAssignmentPageState extends ConsumerState<StudentSubjectAssignmentPage> {
  SubjectAssignmentStats? _stats;
  List<AssignmentClassNode> _classes = [];
  bool _loading = true;
  String? _error;

  final _scrollController = ScrollController();
  final _assignKey = GlobalKey();
  final _filterKey = GlobalKey();
  final _browseKey = GlobalKey();
  _Tab _activeTab = _Tab.assign;
  bool _filterOpen = false;

  // Enrolled-student autopopulate (mirrors reading `eskoolia_last_enrolled_student`).
  String _enrolledName = '';
  String _enrolledAdmissionNo = '';
  String _enrolledRollNo = '';
  String _enrolledClassName = '';
  String _enrolledSectionName = '';
  String _enrolledAcademicYear = '';

  // Section 01 — mandatory subjects (locally renameable, matches reference).
  final List<String> _mandatory = List.of(kMandatoryDefault);
  int? _editMandIdx;
  final _editMandCtrl = TextEditingController();

  // Section 01 — shared, editable option-card definitions (also used inside
  // the Browse & Edit row editor dialog — same top-level state as reference).
  CardDef _l2Card = const CardDef(title: '2nd Language', options: ['Hindi', 'Telugu']);
  CardDef _l3Card = const CardDef(title: '3rd Language', options: ['Hindi', 'Telugu', 'French']);
  CardDef _spCard = const CardDef(title: 'Sports', options: ['Football', 'Cricket', 'Basketball', 'Badminton']);
  CardDef _arCard = const CardDef(title: 'Arts', options: ['Music', 'Dance', 'Instruments', 'FM Radio', 'NGC Club']);

  String _lang2 = '';
  String _lang3 = '';
  List<String> _sports = [];
  List<String> _arts = [];

  @override
  void initState() {
    super.initState();
    _loadEnrolled();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editMandCtrl.dispose();
    super.dispose();
  }

  void _loadEnrolled() {
    final raw = SharedPrefs().getJson('eskoolia_last_enrolled_student');
    if (raw == null) return;
    setState(() {
      _enrolledName = (raw['name'] as String?) ?? '';
      _enrolledAdmissionNo = (raw['admissionNo'] as String?) ?? '';
      _enrolledRollNo = (raw['rollNo'] as String?) ?? '';
      _enrolledClassName = (raw['className'] as String?) ?? '';
      _enrolledSectionName = (raw['sectionName'] as String?) ?? '';
      _enrolledAcademicYear = (raw['academicYear'] as String?) ?? '';
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(subjectAssignmentRepositoryProvider);
      final results = await Future.wait([repo.fetchStats(), repo.fetchClassSectionTree()]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as SubjectAssignmentStats;
        _classes = results[1] as List<AssignmentClassNode>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _refreshStats() async {
    try {
      final stats = await ref.read(subjectAssignmentRepositoryProvider).fetchStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {}
  }

  void _scrollToTab(_Tab tab) {
    setState(() {
      _activeTab = tab;
      if (tab == _Tab.filter) _filterOpen = true;
    });
    final key = switch (tab) {
      _Tab.assign => _assignKey,
      _Tab.filter => _filterKey,
      _Tab.browse => _browseKey,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0);
    });
  }

  void _updateCard(String id, CardDef def) {
    setState(() {
      switch (id) {
        case 'l2':
          _l2Card = def;
          break;
        case 'l3':
          _l3Card = def;
          break;
        case 'sp':
          _spCard = def;
          break;
        case 'ar':
          _arCard = def;
          break;
      }
    });
  }

  void _commitMandatory(int idx) {
    final v = _editMandCtrl.text.trim();
    setState(() {
      if (v.isNotEmpty) _mandatory[idx] = v;
      _editMandIdx = null;
    });
  }

  void _onStudentSaved(int studentId, AssignmentStudentRow updated) {
    setState(() {
      _classes = _classes.map((cls) {
        final newSections = cls.sections.map((sec) {
          final idx = sec.students.indexWhere((s) => s.id == studentId);
          if (idx == -1) return sec;
          final newStudents = List<AssignmentStudentRow>.from(sec.students);
          newStudents[idx] = updated;
          return sec.copyWithStudents(newStudents);
        }).toList();
        return cls.copyWithSections(newSections);
      }).toList();
    });
    _refreshStats();
  }

  Future<void> _openEditor(AssignmentClassNode cls, AssignmentStudentRow student) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => _SubjectEditorDialog(
        cls: cls,
        student: student,
        l2Card: _l2Card,
        l3Card: _l3Card,
        spCard: _spCard,
        arCard: _arCard,
        onCardChange: _updateCard,
        onSaved: _onStudentSaved,
      ),
    );
  }

  // ── Activity ticker (Sports/Arts/Clubs) — derived from currently loaded
  // page-1 snapshots only, exactly like the reference's `classList` state.
  List<AssignmentStudentRow> get _allLoadedStudents => _classes.expand((c) => c.sections.expand((s) => s.students)).toList();

  int _countSubject(String name) {
    return _allLoadedStudents.where((st) {
      final list = st.optionalSubjects.isNotEmpty
          ? st.optionalSubjects
          : [st.sport, st.art, st.lang2, st.lang3].where((x) => x.isNotEmpty).toList();
      return list.any((s) => s.toLowerCase() == name.toLowerCase());
    }).length;
  }

  ({String name, int count, Color color, double fill}) _mkRow(String name, Color color) {
    final count = _countSubject(name);
    final total = _allLoadedStudents.isEmpty ? 1 : _allLoadedStudents.length;
    return (name: name, count: count, color: color, fill: (count / total * 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF8F8FC), border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildActionNav(),
                              const SizedBox(height: 12),
                              if (_loading)
                                const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
                              else if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(children: [
                                    Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                                    const SizedBox(height: 8),
                                    OutlinedButton(onPressed: _load, child: const Text('Retry')),
                                  ]),
                                )
                              else ...[
                                _buildAssignCard(),
                                const SizedBox(height: 16),
                                _buildFilterCard(),
                                const SizedBox(height: 16),
                                _buildBrowseSection(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: breadcrumb, title + KPI block, activity ticker ──────────
  Widget _buildHeader() {
    final sportsRow = [_mkRow('Football', const Color(0xFFF05A28)), _mkRow('Cricket', const Color(0xFF12A670)), _mkRow('Badminton', const Color(0xFFD94F7E)), _mkRow('Basketball', const Color(0xFF7C4DF5))];
    final artsRow = [_mkRow('Music', const Color(0xFF4C6EF5)), _mkRow('Dance', const Color(0xFFE8890C)), _mkRow('Instruments', const Color(0xFF0EA0C0))];
    final clubsRow = [_mkRow('NGC Club', const Color(0xFFB5376E)), _mkRow('FM Radio', const Color(0xFF2AAB72))];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: const [
              Text('Dashboard', style: TextStyle(fontSize: 11, color: Color(0xFFC4BEDD))),
              Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.chevron_right, size: 11, color: Color(0xFFC4BEDD))),
              Text('Student Information', style: TextStyle(fontSize: 11, color: Color(0xFFC4BEDD))),
              Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.chevron_right, size: 11, color: Color(0xFFC4BEDD))),
              Text('Multi Subject Assignment', style: TextStyle(fontSize: 11, color: Color(0xFF6C4CF1), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 14,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: const Color(0xFF0F172A)),
                      children: [
                        const TextSpan(text: 'Multi Subject '),
                        TextSpan(text: 'Assignment', style: GoogleFonts.playfairDisplay(fontSize: 28, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: const Color(0xFF6C3CE1))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: const [
                      SizedBox(width: 3, height: 3, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFC4BEDD), shape: BoxShape.circle))),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text('One-time setup per student — locked until a change is requested', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFC4BEDD))),
                      ),
                    ]),
                  ),
                ],
              ),
              _buildKpiBlock(),
            ],
          ),
          const SizedBox(height: 16),
          const DashedLine(),
          _tickerRow('SPORTS', Icons.emoji_events_outlined, sportsRow),
          const DashedLine(color: Color(0xFFF0ECE3)),
          _tickerRow('ARTS', Icons.palette_outlined, artsRow),
          const DashedLine(color: Color(0xFFF0ECE3)),
          _tickerRow('CLUBS', Icons.groups_outlined, clubsRow),
        ],
      ),
    );
  }

  Widget _buildKpiBlock() {
    final tiles = [
      ('ENROLLED', _stats?.enrolled, const Color(0xFF19162C)),
      ('ASSIGNED', _stats?.assigned, const Color(0xFF1EB980)),
      ('PARTIAL', _stats?.partial, const Color(0xFFF5A623)),
      ('PENDING', _stats?.pending, const Color(0xFFE5534B)),
    ];
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(12), color: const Color(0xFFF8F7F4)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tiles.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: i == 0 ? null : const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFE8E3D8)))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tiles[i].$2?.toString() ?? '—',
                    style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w600, height: 1.1, color: tiles[i].$3),
                  ),
                  const SizedBox(height: 3),
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: tiles[i].$3, shape: BoxShape.circle)),
                  const SizedBox(height: 3),
                  Text(tiles[i].$1, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFFC4BEDD))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tickerRow(String label, IconData icon, List<({String name, int count, Color color, double fill})> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 10, color: const Color(0xFFC4BEDD)),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFC4BEDD))),
              ]),
            ),
          ),
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFF0ECE3)))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 44,
                  height: 3,
                  decoration: BoxDecoration(color: const Color(0xFFF0ECE3), borderRadius: BorderRadius.circular(999)),
                  clipBehavior: Clip.antiAlias,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (item.fill / 100).clamp(0, 1),
                    child: DecoratedBox(decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(999))),
                  ),
                ),
                const SizedBox(width: 8),
                Text(item.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF48436A))),
                const SizedBox(width: 8),
                Text('${item.count}', style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w700, color: item.color)),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Action Nav (01/02/03) ─────────────────────────────────────────
  Widget _buildActionNav() {
    final tabs = [
      (_Tab.assign, '01', 'Assign subjects', Icons.add),
      (_Tab.filter, '02', 'Smart filter', Icons.filter_alt_outlined),
      (_Tab.browse, '03', 'Browse & edit', Icons.description_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(11)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in tabs) ...[
              _navTabButton(t.$1, t.$2, t.$3, t.$4),
              const SizedBox(width: 2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navTabButton(_Tab tab, String step, String label, IconData icon) {
    final active = _activeTab == tab;
    return InkWell(
      onTap: () => _scrollToTab(tab),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(color: active ? const Color(0xFF19162C) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(step, style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w600, color: (active ? Colors.white : const Color(0xFF48436A)).withValues(alpha: 0.55))),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: active ? Colors.white : const Color(0xFF48436A)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF48436A))),
        ]),
      ),
    );
  }

  // ── Section 01: Assign subjects ──────────────────────────────────
  Widget _buildAssignCard() {
    return Container(
      key: _assignKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Assign subjects to enrolled student', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF19162C))),
                  SizedBox(height: 3),
                  SizedBox(
                    width: 420,
                    child: Text('Details auto-populate from enrollment. Pick optional subjects — AI suggests based on class & peer patterns.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF908AAC))),
                  ),
                ],
              ),
              if (_enrolledName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEEF9F3), border: Border.all(color: const Color(0xFFCFEEDE)), borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.link, size: 12, color: Color(0xFF0A7A4A)),
                    const SizedBox(width: 5),
                    Text('From enrollment: $_enrolledName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0A7A4A))),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            baseCols: 6,
            breakpoints: {1100: 3, 700: 2},
            children: [
              _roField('Student Name', _enrolledName.isEmpty ? '—' : _enrolledName, false),
              _roField('Admission No.', _enrolledAdmissionNo.isEmpty ? '—' : _enrolledAdmissionNo, true),
              _roField('Roll No.', _enrolledRollNo.isEmpty ? '—' : _enrolledRollNo, true),
              _roField('Class', _enrolledClassName.isEmpty ? '—' : _enrolledClassName, false),
              _roField('Section', _enrolledSectionName.isEmpty ? '—' : _enrolledSectionName, false),
              _roField('Academic Year', _enrolledAcademicYear.isEmpty ? '2026-27' : _enrolledAcademicYear, false),
            ],
          ),
          const SizedBox(height: 14),
          _buildMandatoryCard(),
          const SizedBox(height: 9),
          ResponsiveGrid(
            baseCols: 4,
            breakpoints: {900: 2},
            children: [
              ModuleOptionCard(
                cardDef: _l2Card,
                icon: Icons.language,
                chipLabel: 'pick 1',
                chipBg: const Color(0xFFECEFFF),
                chipText: const Color(0xFF2C3AA1),
                chipBorder: const Color(0xFFD3D8FF),
                multi: false,
                value: _lang2,
                onChange: (v) => setState(() {
                  _lang2 = v as String;
                  if (_lang3 == v) _lang3 = '';
                }),
                onCardChange: (d) => _updateCard('l2', d),
              ),
              ModuleOptionCard(
                cardDef: _l3Card,
                icon: Icons.language,
                chipLabel: 'pick 1',
                chipBg: const Color(0xFFECEFFF),
                chipText: const Color(0xFF2C3AA1),
                chipBorder: const Color(0xFFD3D8FF),
                multi: false,
                value: _lang3,
                disabledOptions: _lang2.isEmpty ? const [] : [_lang2],
                onChange: (v) => setState(() => _lang3 = v as String),
                onCardChange: (d) => _updateCard('l3', d),
              ),
              ModuleOptionCard(
                cardDef: _spCard,
                icon: Icons.emoji_events_outlined,
                chipLabel: '1+ pick',
                chipBg: const Color(0xFFFFEEF2),
                chipText: const Color(0xFFA0264A),
                chipBorder: const Color(0xFFFFCFDC),
                multi: true,
                value: _sports,
                onChange: (v) => setState(() => _sports = v as List<String>),
                onCardChange: (d) => _updateCard('sp', d),
              ),
              ModuleOptionCard(
                cardDef: _arCard,
                icon: Icons.palette_outlined,
                chipLabel: '1+ pick',
                chipBg: const Color(0xFFF1ECFF),
                chipText: const Color(0xFF5231B5),
                chipBorder: const Color(0xFFDDD0FF),
                multi: true,
                value: _arts,
                onChange: (v) => setState(() => _arts = v as List<String>),
                onCardChange: (d) => _updateCard('ar', d),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const DashedLine(),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              PreviewBadges(lang2: _lang2, lang3: _lang3, sports: _sports, arts: _arts),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _lang2 = '';
                      _lang3 = '';
                      _sports = [];
                      _arts = [];
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF19162C),
                      side: const BorderSide(color: Color(0xFFE8E3D8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await SharedPrefs().remove('eskoolia_last_enrolled_student');
                      if (mounted) context.go('/students');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C4CF1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      elevation: 0,
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Save & assign to student', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roField(String label, String value, bool mono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Color(0xFF48436A))),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: const Color(0xFFF9F7F0), border: Border.all(color: const Color(0xFFF0ECE3)), borderRadius: BorderRadius.circular(10)),
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: mono
                ? GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF48436A))
                : const TextStyle(fontSize: 13, color: Color(0xFF48436A)),
          ),
        ),
      ],
    );
  }

  Widget _buildMandatoryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCFEEDE)),
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF3FBF7), Colors.white]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MandatorySubjectsHeader(count: _mandatory.length),
          const SizedBox(height: 11),
          ResponsiveGrid(
            baseCols: 7,
            breakpoints: {900: 4},
            gap: 7,
            children: [
              for (var i = 0; i < _mandatory.length; i++) _mandatoryItem(i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mandatoryItem(int idx) {
    final editing = _editMandIdx == idx;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: const Color(0xFF1EB980), border: Border.all(color: const Color(0xFF1EB980)), borderRadius: BorderRadius.circular(5)),
          child: const Icon(Icons.check, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 6),
        if (editing)
          Flexible(
            child: Focus(
              onFocusChange: (has) {
                if (!has) _commitMandatory(idx);
              },
              child: TextField(
                controller: _editMandCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF19162C)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1EB980), width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1EB980), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF1EB980), width: 1.5)),
                ),
                onSubmitted: (_) => _commitMandatory(idx),
              ),
            ),
          )
        else
          Flexible(
            child: Text(_mandatory[idx], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1EB980)), overflow: TextOverflow.ellipsis),
          ),
        InkWell(
          onTap: () => setState(() {
            _editMandIdx = idx;
            _editMandCtrl.text = _mandatory[idx];
          }),
          borderRadius: BorderRadius.circular(4),
          child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.edit_outlined, size: 11, color: Color(0xFFC4BEDD))),
        ),
      ],
    );
  }

  // ── Section 02: Smart filter ──────────────────────────────────────
  Widget _buildFilterCard() {
    return Container(
      key: _filterKey,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(13)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _filterOpen = !_filterOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                gradient: _filterOpen ? const LinearGradient(colors: [Color(0xFFF7F3FF), Colors.white]) : null,
                border: _filterOpen ? const Border(bottom: BorderSide(color: Color(0xFFF0ECE3))) : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFEFEAFF), borderRadius: BorderRadius.circular(4)),
                    child: Text('02', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF6C4CF1))),
                  ),
                  const SizedBox(width: 11),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: const Color(0xFFEFEAFF), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF6C4CF1)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Smart filters', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF19162C))),
                        Text('Find students across any combination of class · section · language · sport · art.', style: TextStyle(fontSize: 11, color: Color(0xFF908AAC))),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _filterOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFC4BEDD)),
                  ),
                ],
              ),
            ),
          ),
          if (_filterOpen)
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveGrid(
                    baseCols: 7,
                    breakpoints: {1200: 4, 720: 2},
                    gap: 10,
                    children: [
                      _filterField('Search', child: _filterTextInput('Search students...')),
                      _filterField('Class', child: _filterDropdown(['Nursery', 'LKG', 'UKG', for (var i = 1; i <= 10; i++) 'Grade $i'])),
                      _filterField('Section', child: _filterDropdown(['All sections', 'A', 'B', 'C'])),
                      _filterField('2nd Language', child: _filterDropdown(['Any 2nd lang', 'Hindi', 'Telugu'])),
                      _filterField('3rd Language', child: _filterDropdown(['Any 3rd lang', 'Hindi', 'Telugu', 'French'])),
                      _filterField('Sport', child: _filterDropdown(['Any sport', 'Football', 'Cricket', 'Basketball', 'Badminton'])),
                      _filterField('Art', child: _filterDropdown(['Any art', 'Music', 'Dance', 'Instruments', 'FM Radio', 'NGC Club'])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      const SizedBox.shrink(),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF48436A),
                            side: const BorderSide(color: Color(0xFFE8E3D8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          ),
                          child: const Text('Save preset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => _filterOpen = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C4CF1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          ),
                          child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterField(String label, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: Color(0xFF6F7287))),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _filterTextInput(String hint) {
    return TextField(
      style: const TextStyle(fontSize: 13, color: Color(0xFF19162C)),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF908AAC)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8E3D8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8E3D8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6C4CF1))),
      ),
    );
  }

  Widget _filterDropdown(List<String> options) {
    return DropdownButtonFormField<String>(
      initialValue: options.first,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF908AAC)),
      style: const TextStyle(fontSize: 13, color: Color(0xFF19162C)),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8E3D8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8E3D8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6C4CF1))),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (_) {},
    );
  }

  // ── Section 03: Browse & edit ─────────────────────────────────────
  Widget _buildBrowseSection() {
    return Container(
      key: _browseKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEFEAFF), borderRadius: BorderRadius.circular(4)),
                child: Text('03', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF6C4CF1))),
              ),
              const SizedBox(width: 8),
              const Text('Browse & edit by class', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF19162C))),
              const SizedBox(width: 6),
              const Expanded(child: Text('— click any class, then a section to expand.', style: TextStyle(fontSize: 11.5, color: Color(0xFF908AAC)), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 10),
          _buildLegendCard(),
          const SizedBox(height: 10),
          if (_classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No classes found in the database.', style: TextStyle(fontSize: 12, color: Color(0xFFC4BEDD)))),
            )
          else
            for (var i = 0; i < _classes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ClassAccordion(
                  key: ValueKey(_classes[i].id),
                  cls: _classes[i],
                  defaultOpen: i == 0,
                  onEdit: _openEditor,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    final legend = [
      ('MAN', const Color(0xFF1E9B6B), 'Mandatory'),
      ('L2', const Color(0xFF2C56A1), '2nd Language'),
      ('L3', const Color(0xFF915A1A), '3rd Language'),
      ('SP', const Color(0xFFA0264A), 'Sport'),
      ('AR', const Color(0xFF5231B5), 'Art'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(10)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          for (final item in legend)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: item.$2, borderRadius: BorderRadius.circular(2)),
                child: Text(item.$1, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 5),
              Text(item.$3, style: const TextStyle(fontSize: 10.5, color: Color(0xFF48436A))),
            ]),
          const Text('Hover a badge for full name', style: TextStyle(fontSize: 10, color: Color(0xFFC4BEDD))),
        ],
      ),
    );
  }
}

/// Mirrors `ClassAcc` — a per-class accordion with its own local open/
/// active-section/page/pageCache state (kept via [ValueKey] so it survives
/// parent rebuilds exactly like the reference's component-local `useState`).
class _ClassAccordion extends ConsumerStatefulWidget {
  final AssignmentClassNode cls;
  final bool defaultOpen;
  final void Function(AssignmentClassNode cls, AssignmentStudentRow student) onEdit;

  const _ClassAccordion({super.key, required this.cls, required this.defaultOpen, required this.onEdit});

  @override
  ConsumerState<_ClassAccordion> createState() => _ClassAccordionState();
}

class _ClassAccordionState extends ConsumerState<_ClassAccordion> {
  late bool _open = widget.defaultOpen;
  int _activeSecIdx = 0;
  int _page = 1;
  final Map<int, Map<int, List<AssignmentStudentRow>>> _pageCache = {};
  bool _pageLoading = false;

  int _sectionTotal(AssignmentSectionNode sec) => sec.studentTotal;

  Future<void> _fetchPage(AssignmentSectionNode sec, int page, int pageSize) async {
    if (_pageCache[sec.id]?[page] != null) return;
    setState(() => _pageLoading = true);
    try {
      final result = await ref.read(subjectAssignmentRepositoryProvider).fetchSectionStudents(
            classId: widget.cls.id,
            sectionId: sec.id,
            page: page,
            pageSize: pageSize,
          );
      if (!mounted) return;
      setState(() {
        _pageCache.putIfAbsent(sec.id, () => {})[page] = result.students;
        _pageLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _pageLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.cls;
    final allTotal = cls.sections.fold<int>(0, (acc, sec) => acc + _sectionTotal(sec));
    final loadedAll = cls.sections.expand((sec) => sec.students).toList();
    final done = loadedAll.where((s) => s.status == 'done').length;
    final pct = allTotal > 0 ? (done / allTotal * 100) : 0.0;
    final subLabel = kClassSubLabels[cls.label] ?? 'Grade';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _classHead(cls, allTotal, done, pct, subLabel),
          if (_open) _sectionBody(cls),
        ],
      ),
    );
  }

  Widget _classHead(AssignmentClassNode cls, int allTotal, int done, double pct, String subLabel) {
    return Container(
      decoration: BoxDecoration(
        color: _open ? const Color(0xFFF8F6FF) : Colors.white,
        border: Border(left: BorderSide(color: _open ? const Color(0xFF4729F4) : Colors.transparent, width: 4)),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _open = !_open;
          _activeSecIdx = 0;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedRotation(
                turns: _open ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA0AE)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cls.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14)), overflow: TextOverflow.ellipsis),
                    Text(subLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA0AE)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _pill('$allTotal students'),
                    _pill('${cls.sections.length} sections', bg: const Color(0xFFF1F1F5), fg: const Color(0xFF6B6B7B)),
                    if (done > 0) _pill('$done done', bg: const Color(0xFFE4F6ED), fg: const Color(0xFF0A8C5A)),
                    if ((allTotal - done) > 0) _pill('${allTotal - done} pending', bg: const Color(0xFFFDF1DC), fg: const Color(0xFFB4721B)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RingProgress(pct: pct, size: 34),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, {Color bg = const Color(0xFFFAFAFD), Color fg = const Color(0xFF3A3A4A)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _sectionBody(AssignmentClassNode cls) {
    if (cls.sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Center(child: Text('No sections configured.', style: TextStyle(fontSize: 12, color: Color(0xFFC4BEDD)))),
      );
    }
    final activeSec = cls.sections[_activeSecIdx.clamp(0, cls.sections.length - 1)];
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTabs(cls),
          _studentTable(cls, activeSec),
        ],
      ),
    );
  }

  Widget _sectionTabs(AssignmentClassNode cls) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF1F1F5)))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < cls.sections.length; i++) _sectionTabButton(cls.sections[i], i),
          ],
        ),
      ),
    );
  }

  Widget _sectionTabButton(AssignmentSectionNode sec, int i) {
    final secCount = _sectionTotal(sec);
    final sdone = sec.students.where((s) => s.status == 'done').length;
    final isActive = _activeSecIdx == i;
    final isComplete = secCount > 0 && sdone == secCount;
    final isPartial = secCount > 0 && sdone > 0 && sdone < secCount;
    Color badgeBg = const Color(0xFFF1F1F5), badgeFg = const Color(0xFF9CA0AE);
    if (isComplete) {
      badgeBg = const Color(0xFFE4F6ED);
      badgeFg = const Color(0xFF0A8C5A);
    } else if (isPartial) {
      badgeBg = const Color(0xFFFDF1DC);
      badgeFg = const Color(0xFFB4721B);
    } else if (isActive) {
      badgeBg = const Color(0xFFEEEBFF);
      badgeFg = const Color(0xFF4729F4);
    }
    return InkWell(
      onTap: () => setState(() {
        _activeSecIdx = i;
        _page = 1;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF4729F4) : Colors.transparent, width: 2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Section ${sec.letter}', style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? const Color(0xFF4729F4) : const Color(0xFF9CA0AE))),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
            child: Text('$secCount', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: badgeFg)),
          ),
        ]),
      ),
    );
  }

  Widget _studentTable(AssignmentClassNode cls, AssignmentSectionNode activeSec) {
    final pageSize = activeSec.studentPageSize;
    final totalRows = _sectionTotal(activeSec);
    final totalPages = totalRows <= 0 ? 1 : ((totalRows + pageSize - 1) ~/ pageSize).clamp(1, 1 << 30);
    final safePage = _page.clamp(1, totalPages);
    final startIdx = (safePage - 1) * pageSize;
    if (safePage != 1 && _pageCache[activeSec.id]?[safePage] == null && !_pageLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPage(activeSec, safePage, pageSize));
    }
    final cachedPage = _pageCache[activeSec.id]?[safePage];
    final visibleStudents = cachedPage ?? (safePage == 1 ? activeSec.students : const <AssignmentStudentRow>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tableHeadRow(),
                if (_pageLoading && visibleStudents.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('Loading…', style: TextStyle(fontSize: 12, color: Color(0xFFC4BEDD)))))
                else
                  for (final st in visibleStudents) _studentRow(cls, st),
                if (totalRows == 0 && !_pageLoading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No students in this section.', style: TextStyle(fontSize: 12, color: Color(0xFFC4BEDD))))),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0ECE3)))),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                totalRows == 0
                    ? '0 students in Section ${activeSec.letter}'
                    : '${startIdx + 1}–${(startIdx + pageSize).clamp(0, totalRows)} of $totalRows students in Section ${activeSec.letter}',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFFC4BEDD)),
              ),
              if (totalPages > 1) _pager(safePage, totalPages),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableHeadRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: const Color(0xFFF5F1E5),
      child: Row(
        children: const [
          SizedBox(width: 22),
          SizedBox(width: 11),
          SizedBox(width: 190, child: Text('STUDENT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFC4BEDD)))),
          SizedBox(width: 11),
          SizedBox(width: 110, child: Text('ADMISSION', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFC4BEDD)))),
          SizedBox(width: 11),
          SizedBox(width: 46, child: Text('ROLL', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFC4BEDD)))),
          SizedBox(width: 11),
          SizedBox(width: 260, child: Text('OPTIONAL SUBJECTS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFC4BEDD)))),
          SizedBox(width: 130),
        ],
      ),
    );
  }

  Widget _studentRow(AssignmentClassNode cls, AssignmentStudentRow st) {
    final mandCount = getMandatoryForClass(cls.label).length;
    final (statusColor, statusBg, statusBorder, statusLabel) = switch (st.status) {
      'done' => (const Color(0xFF0A7A4A), const Color(0xFFEEF9F3), const Color(0xFFCFEEDE), 'Done'),
      'partial' => (const Color(0xFF9A5C10), const Color(0xFFFFF7E6), const Color(0xFFFDD598), 'Partial'),
      _ => (const Color(0xFFB3261E), const Color(0xFFFFF5F5), const Color(0xFFFFD0CC), 'Empty'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0ECE3)))),
      child: Row(
        children: [
          const SizedBox(width: 22),
          const SizedBox(width: 11),
          SizedBox(
            width: 190,
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _avatarBg(st.name), borderRadius: BorderRadius.circular(7)),
                child: Text(_initials(st.name), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(st.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF19162C)), overflow: TextOverflow.ellipsis)),
            ]),
          ),
          const SizedBox(width: 11),
          SizedBox(width: 110, child: Text(st.admissionNo, style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF48436A)), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 11),
          SizedBox(width: 46, child: Text(st.rollNo, style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF48436A)))),
          const SizedBox(width: 11),
          SizedBox(
            width: 260,
            child: Wrap(spacing: 4, runSpacing: 4, children: [
              SubBadge(tag: 'MAN', value: '+$mandCount', tagColor: const Color(0xFF1E9B6B), dim: true),
              if (st.lang2.isNotEmpty) SubBadge(tag: 'L2', value: st.lang2, tagColor: const Color(0xFF2C56A1)),
              if (st.lang3.isNotEmpty) SubBadge(tag: 'L3', value: st.lang3, tagColor: const Color(0xFF915A1A)),
              if (st.sport.isNotEmpty) SubBadge(tag: 'SP', value: st.sport, tagColor: const Color(0xFFA0264A)),
              if (st.art.isNotEmpty) SubBadge(tag: 'AR', value: st.art, tagColor: const Color(0xFF5231B5)),
            ]),
          ),
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, border: Border.all(color: statusBorder), borderRadius: BorderRadius.circular(999)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => widget.onEdit(cls, st),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: st.status == 'empty' ? const Color(0xFF6C4CF1) : const Color(0xFFE8E3D8)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      st.status == 'empty' ? Icons.auto_awesome : Icons.edit_outlined,
                      size: 15,
                      color: st.status == 'empty' ? const Color(0xFF6C4CF1) : const Color(0xFF48436A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pager(int safePage, int totalPages) {
    final pages = buildPageList(safePage, totalPages);
    return Wrap(
      spacing: 3,
      children: [
        _pagerBtn('‹', enabled: safePage > 1, onTap: () => setState(() => _page = (safePage - 1).clamp(1, totalPages))),
        for (final p in pages)
          p == '…'
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('…', style: TextStyle(fontSize: 10.5, color: Color(0xFFC4BEDD))))
              : _pagerBtn('$p', active: p == safePage, onTap: () => setState(() => _page = p as int)),
        _pagerBtn('›', enabled: safePage < totalPages, onTap: () => setState(() => _page = (safePage + 1).clamp(1, totalPages))),
      ],
    );
  }

  Widget _pagerBtn(String label, {bool active = false, bool enabled = true, required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(5),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6C4CF1) : Colors.white,
            border: Border.all(color: active ? const Color(0xFF6C4CF1) : const Color(0xFFE6E6EC)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF3A3A4A))),
        ),
      ),
    );
  }
}

/// Mirrors `EditModal` — the per-student subject editor reached from the
/// Browse & Edit table's edit button. This is the only place in the whole
/// screen with a real student id, so it's the only place that actually
/// calls the backend (`upsert-optional`).
class _SubjectEditorDialog extends ConsumerStatefulWidget {
  final AssignmentClassNode cls;
  final AssignmentStudentRow student;
  final CardDef l2Card, l3Card, spCard, arCard;
  final void Function(String id, CardDef def) onCardChange;
  final void Function(int studentId, AssignmentStudentRow updated) onSaved;

  const _SubjectEditorDialog({
    required this.cls,
    required this.student,
    required this.l2Card,
    required this.l3Card,
    required this.spCard,
    required this.arCard,
    required this.onCardChange,
    required this.onSaved,
  });

  @override
  ConsumerState<_SubjectEditorDialog> createState() => _SubjectEditorDialogState();
}

class _SubjectEditorDialogState extends ConsumerState<_SubjectEditorDialog> {
  late String _lang2 = widget.student.lang2;
  late String _lang3 = widget.student.lang3;
  late List<String> _sports = widget.student.sport.isEmpty ? [] : [widget.student.sport];
  late List<String> _arts = widget.student.art.isEmpty ? [] : [widget.student.art];
  late CardDef _l2 = widget.l2Card;
  late CardDef _l3 = widget.l3Card;
  late CardDef _sp = widget.spCard;
  late CardDef _ar = widget.arCard;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final names = [
        if (_lang2.isNotEmpty) _lang2,
        if (_lang3.isNotEmpty) _lang3,
        ..._sports,
        ..._arts,
      ];
      await ref.read(subjectAssignmentRepositoryProvider).upsertOptionalSubjects(widget.student.id, names);
      if (!mounted) return;
      final optCount = [_lang2, _lang3, _sports.isNotEmpty ? _sports.first : '', _arts.isNotEmpty ? _arts.first : ''].where((s) => s.isNotEmpty).length;
      final status = optCount >= 4 ? 'done' : (optCount > 0 ? 'partial' : 'empty');
      widget.onSaved(
        widget.student.id,
        widget.student.copyWith(lang2: _lang2, lang3: _lang3, sport: _sports.isNotEmpty ? _sports.first : '', art: _arts.isNotEmpty ? _arts.first : '', status: status),
      );
      Navigator.of(context).pop(true);
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
    final mandatory = getMandatoryForClass(widget.cls.label);
    final ready = _lang2.isNotEmpty && _lang3.isNotEmpty && _sports.isNotEmpty && _arts.isNotEmpty;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFF7F3FF), Colors.white]),
                border: Border(bottom: BorderSide(color: Color(0xFFE8E3D8))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _avatarBg(widget.student.name), borderRadius: BorderRadius.circular(11)),
                    child: Text(_initials(widget.student.name), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.cls.label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF6C4CF1))),
                        Text(widget.student.name, style: GoogleFonts.instrumentSerif(fontSize: 22, color: const Color(0xFF19162C), height: 1.2)),
                        Text(widget.student.admissionNo, style: const TextStyle(fontSize: 11, color: Color(0xFF908AAC))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCFEEDE)),
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFFF3FBF7), Colors.white]),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MandatorySubjectsHeader(count: mandatory.length),
                          const SizedBox(height: 11),
                          ResponsiveGrid(
                            baseCols: 7,
                            breakpoints: {900: 4},
                            gap: 7,
                            children: [
                              for (final sub in mandatory)
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(color: const Color(0xFF1EB980), borderRadius: BorderRadius.circular(5)),
                                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1EB980)), overflow: TextOverflow.ellipsis)),
                                ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    ResponsiveGrid(
                      baseCols: 2,
                      children: [
                        ModuleOptionCard(
                          cardDef: _l2,
                          icon: Icons.language,
                          chipLabel: 'pick 1',
                          chipBg: const Color(0xFFECEFFF),
                          chipText: const Color(0xFF2C3AA1),
                          chipBorder: const Color(0xFFD3D8FF),
                          multi: false,
                          value: _lang2,
                          onChange: (v) => setState(() {
                            _lang2 = v as String;
                            if (_lang3 == v) _lang3 = '';
                          }),
                          onCardChange: (d) {
                            setState(() => _l2 = d);
                            widget.onCardChange('l2', d);
                          },
                        ),
                        ModuleOptionCard(
                          cardDef: _l3,
                          icon: Icons.language,
                          chipLabel: 'pick 1',
                          chipBg: const Color(0xFFECEFFF),
                          chipText: const Color(0xFF2C3AA1),
                          chipBorder: const Color(0xFFD3D8FF),
                          multi: false,
                          value: _lang3,
                          disabledOptions: _lang2.isEmpty ? const [] : [_lang2],
                          onChange: (v) => setState(() => _lang3 = v as String),
                          onCardChange: (d) {
                            setState(() => _l3 = d);
                            widget.onCardChange('l3', d);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ResponsiveGrid(
                      baseCols: 2,
                      children: [
                        ModuleOptionCard(
                          cardDef: _sp,
                          icon: Icons.emoji_events_outlined,
                          chipLabel: '1+ pick',
                          chipBg: const Color(0xFFFFEEF2),
                          chipText: const Color(0xFFA0264A),
                          chipBorder: const Color(0xFFFFCFDC),
                          multi: true,
                          value: _sports,
                          onChange: (v) => setState(() => _sports = v as List<String>),
                          onCardChange: (d) {
                            setState(() => _sp = d);
                            widget.onCardChange('sp', d);
                          },
                        ),
                        ModuleOptionCard(
                          cardDef: _ar,
                          icon: Icons.palette_outlined,
                          chipLabel: '1+ pick',
                          chipBg: const Color(0xFFF1ECFF),
                          chipText: const Color(0xFF5231B5),
                          chipBorder: const Color(0xFFDDD0FF),
                          multi: true,
                          value: _arts,
                          onChange: (v) => setState(() => _arts = v as List<String>),
                          onCardChange: (d) {
                            setState(() => _ar = d);
                            widget.onCardChange('ar', d);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF9F7F0), border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('WILL BE ASSIGNED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFC4BEDD))),
                              if (ready) const Text('Ready', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1EB980))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          PreviewBadges(lang2: _lang2, lang3: _lang3, sports: _sports, arts: _arts),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFFFF3F3), border: Border.all(color: const Color(0xFFF5CACA)), borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFE5534B))),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                border: Border(top: BorderSide(color: Color(0xFFE8E3D8))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              // `Wrap` rather than a bare `Row` — the two action buttons
              // never overflow on any realistic phone width, but this keeps
              // the whole screen's "no RenderFlex overflow anywhere"
              // guarantee airtight rather than relying on it.
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF19162C),
                      side: const BorderSide(color: Color(0xFFE8E3D8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C4CF1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check, size: 14, color: Colors.white), SizedBox(width: 6), Text('Save & assign')]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
