import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../student/domain/models/academic_year.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/holiday_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/subject_entry.dart';
import '../providers/academics_providers.dart';
import '../widgets/foundation_widgets.dart';
import 'foundation_steps/academic_year_step.dart';
import 'foundation_steps/classes_step.dart';
import 'foundation_steps/rooms_step.dart';
import 'foundation_steps/sections_step.dart';
import 'foundation_steps/subjects_step.dart';

/// Academics → Foundation & Core Settings — full port of frontend
/// app/(dashboard)/academics/core-setup/page.tsx → FoundationWorkspace.tsx +
/// its panes/ family (AcademicYearPane+HolidayCalendarCard, ClassesPane,
/// SectionsPane, SubjectsPane, RoomsPane). Backend: apps/core (academic
/// years, classes, streams, sections, holidays, class-rooms) + apps/academics
/// (class-subject-entries) — every action below calls one of these real,
/// existing, unmodified Django endpoints.
class AcademicsFoundationPage extends ConsumerStatefulWidget {
  const AcademicsFoundationPage({super.key});

  @override
  ConsumerState<AcademicsFoundationPage> createState() => _AcademicsFoundationPageState();
}

class _AcademicsFoundationPageState extends ConsumerState<AcademicsFoundationPage> {
  int _step = 1;
  bool _loading = true;

  List<AcademicYear> _years = [];
  List<FoundationClass> _classes = [];
  List<StreamDetail> _streams = [];
  List<ClassSubjectEntry> _subjectEntries = [];
  List<String> _globalSubjectNames = [];
  List<FoundationRoom> _rooms = [];
  List<Holiday> _holidays = [];

  ({String tone, String message})? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message, {bool error = false}) {
    _toastTimer?.cancel();
    setState(() => _toast = (tone: error ? 'error' : 'success', message: message));
    _toastTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final repo = ref.read(academicsRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.fetchAcademicYears(),
        repo.fetchClasses(),
        repo.fetchStreams(),
        repo.fetchClassSubjectEntries(),
        repo.fetchGlobalSubjectNames(),
        repo.fetchRooms(),
      ]);
      if (!mounted) return;
      setState(() {
        _years = results[0] as List<AcademicYear>;
        _classes = results[1] as List<FoundationClass>;
        _streams = results[2] as List<StreamDetail>;
        _subjectEntries = results[3] as List<ClassSubjectEntry>;
        _globalSubjectNames = results[4] as List<String>;
        _rooms = results[5] as List<FoundationRoom>;
        _loading = false;
      });
      unawaited(_reloadHolidays());
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _reloadYears() async {
    final years = await ref.read(academicsRepositoryProvider).fetchAcademicYears();
    if (!mounted) return;
    setState(() => _years = years);
  }

  Future<void> _reloadClasses() async {
    final classes = await ref.read(academicsRepositoryProvider).fetchClasses();
    if (!mounted) return;
    setState(() => _classes = classes);
  }

  Future<void> _reloadStreams() async {
    final streams = await ref.read(academicsRepositoryProvider).fetchStreams();
    if (!mounted) return;
    setState(() => _streams = streams);
  }

  Future<void> _reloadSubjectEntries() async {
    final entries = await ref.read(academicsRepositoryProvider).fetchClassSubjectEntries();
    if (!mounted) return;
    setState(() => _subjectEntries = entries);
  }

  Future<void> _reloadRooms() async {
    final rooms = await ref.read(academicsRepositoryProvider).fetchRooms();
    if (!mounted) return;
    setState(() => _rooms = rooms);
  }

  Future<void> _reloadHolidays() async {
    final holidays = await ref.read(academicsRepositoryProvider).fetchHolidays();
    if (!mounted) return;
    setState(() => _holidays = holidays);
  }

  Set<int> get _doneSteps {
    final done = <int>{};
    if (_years.isNotEmpty) done.add(1);
    if (_classes.isNotEmpty) done.add(2);
    if (_classes.any((c) => c.sections.isNotEmpty)) done.add(3);
    if (_subjectEntries.isNotEmpty) done.add(4);
    if (_rooms.isNotEmpty) done.add(5);
    return done;
  }

  static const _wizardSteps = [
    (1, 'Academic Year'),
    (2, 'Classes'),
    (3, 'Sections'),
    (4, 'Subjects'),
    (5, 'Rooms'),
  ];

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
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFF8F8FC), border: Border.all(color: const Color(0xFFDFDFEA)), borderRadius: BorderRadius.circular(16)),
                        child: _loading
                            ? const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
                            : _buildContent(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FoundationToast(toast: _toast),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final done = _doneSteps;
    final currentYear = _years.where((y) => y.isCurrent).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('ACADEMICS SETUP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF6F767E))),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'Foundation ', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1A1D1F))),
              TextSpan(text: '& Core Settings', style: GoogleFonts.playfairDisplay(fontSize: 32, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, color: const Color(0xFF5B4FCF))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Define the core academic structure including academic years, classes, sections, subjects, and rooms.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6F767E)),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text('Current Academic Year:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6F767E))),
                if (_years.isEmpty)
                  const Text('No years yet — create one in Step 1', style: TextStyle(fontSize: 12, color: Color(0xFF9FA6AD), fontStyle: FontStyle.italic))
                else if (currentYear == null)
                  const Text('No year marked current yet', style: TextStyle(fontSize: 12, color: Color(0xFF9FA6AD), fontStyle: FontStyle.italic))
                else
                  InkWell(
                    onTap: () => setState(() => _step = 1),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFF5B4FCF), borderRadius: BorderRadius.circular(999)),
                      child: Text('${currentYear.name} ✓', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Setup progress', style: TextStyle(fontSize: 11, color: Color(0xFF6F767E))),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  height: 6,
                  decoration: BoxDecoration(color: const Color(0xFFE8ECEF), borderRadius: BorderRadius.circular(999)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: done.length / 5,
                    child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5B4FCF), Color(0xFF8B7FE8)]), borderRadius: BorderRadius.circular(999))),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${done.length}/5', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5B4FCF))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildWizardStrip(done),
        const SizedBox(height: 12),
        _buildStep(),
      ],
    );
  }

  Widget _buildWizardStrip(Set<int> done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8ECEF)), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3)]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _wizardSteps.length; i++) ...[
              _stepPill(_wizardSteps[i].$1, _wizardSteps[i].$2, done),
              if (i < _wizardSteps.length - 1) const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('›', style: TextStyle(fontSize: 18, color: Color(0xFFD2D7DC)))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepPill(int n, String label, Set<int> done) {
    final isActive = _step == n;
    final isDone = done.contains(n);
    final Color badgeBg, badgeFg, labelColor;
    if (isActive) {
      badgeBg = const Color(0xFF5B4FCF);
      badgeFg = Colors.white;
      labelColor = const Color(0xFF5B4FCF);
    } else if (isDone) {
      badgeBg = const Color(0xFF22C55E);
      badgeFg = Colors.white;
      labelColor = const Color(0xFF15803D);
    } else {
      badgeBg = const Color(0xFFF0F2F5);
      badgeFg = const Color(0xFF9FA6AD);
      labelColor = const Color(0xFF9FA6AD);
    }
    return InkWell(
      onTap: () => setState(() => _step = n),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFF5F3FF) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle, border: Border.all(color: badgeBg)),
              child: Text(!isActive && isDone ? '✓' : '$n', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeFg)),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return AcademicYearStep(
          years: _years,
          holidays: _holidays,
          onRefreshYears: _reloadYears,
          onRefreshHolidays: _reloadHolidays,
          showToast: _showToast,
          onNext: () => setState(() => _step = 2),
        );
      case 2:
        return ClassesStep(
          classes: _classes,
          streams: _streams,
          onRefreshClasses: _reloadClasses,
          onRefreshStreams: _reloadStreams,
          showToast: _showToast,
          onBack: () => setState(() => _step = 1),
          onNext: () => setState(() => _step = 3),
        );
      case 3:
        return SectionsStep(
          classes: _classes,
          onRefresh: _reloadClasses,
          showToast: _showToast,
          onBack: () => setState(() => _step = 2),
          onNext: () => setState(() => _step = 4),
        );
      case 4:
        return SubjectsStep(
          classes: _classes,
          entries: _subjectEntries,
          globalSubjectNames: _globalSubjectNames,
          onRefresh: _reloadSubjectEntries,
          showToast: _showToast,
          onBack: () => setState(() => _step = 3),
          onComplete: () => setState(() => _step = 5),
        );
      case 5:
        return RoomsStep(
          classes: _classes,
          rooms: _rooms,
          onRefresh: _reloadRooms,
          showToast: _showToast,
          onBack: () => setState(() => _step = 4),
          onNext: () => _showToast('Foundation setup complete!'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
