import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/academic_year.dart';
import '../../domain/models/student_attendance_record.dart';
import '../../domain/models/student_data.dart';
import '../providers/student_providers.dart';

/// Student profile view — mobile equivalent of frontend
/// StudentListPanel.tsx's right-side slide-in drawer (`.view-drawer`).
/// Pushed as a full page rather than a side panel (standard mobile
/// adaptation of a desktop drawer — there's no room for a persistent side
/// panel on a phone). Header/tabs/rows are built from the drawer's own CSS
/// (`.drawer-head`, `.drawer-tabs`/`.tab`, `.drawer-section`/`.drawer-row`)
/// rather than Material defaults, since none of Material's stock widgets
/// (AppBar+TabBar, Card) reproduce this exact look.
///
/// The row passed in via [student] is only the List table's abbreviated
/// snapshot (`StudentListSerializer` — no email/address/guardian name). On
/// open this fetches the full `GET /students/students/{id}/` detail exactly
/// like the frontend's own drawer does, then (if a guardian is linked)
/// resolves the guardian's name/phone via a follow-up `GET
/// /students/guardians/{id}/` (Student.guardian is only a raw FK id), and
/// resolves the academic year's display name from `GET
/// /core/academic-years/` (the backend has no `academic_year_name` field —
/// the frontend itself falls back to a hardcoded "2026–27" for the same
/// reason; we use the same fallback only if resolution fails).
///
/// Scope note: the frontend drawer's attendance ring chart/calendar, club
/// membership widgets, and "AI Performance Review" generator are deep,
/// separate sub-features (analytics + AI text generation) beyond a UI-only
/// pass of the List/Enroll screens — each tab here shows the same
/// information as simple, static summaries instead, styled with the same
/// section/row treatment as Profile/Academic for visual consistency.
class StudentProfilePage extends ConsumerStatefulWidget {
  final StudentData student;

  const StudentProfilePage({super.key, required this.student});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

const List<String> _kTabLabels = ['Profile', 'Academic', 'Attendance', 'Fees', 'Achievements'];

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  StudentData? _detail;
  bool _loadingDetail = true;
  String? _detailError;

  String? _guardianName;
  String? _guardianPhone;
  String? _academicYearName;

  bool _statusMutating = false;
  bool _didMutate = false;
  int _activeTab = 0;

  StudentData get _s => _detail ?? widget.student;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final repository = ref.read(studentRepositoryProvider);
    try {
      final results = await Future.wait([
        repository.fetchStudentDetail(widget.student.id),
        repository.fetchAcademicYears(),
      ]);
      if (!mounted) return;
      final detail = results[0] as StudentData;
      final years = results[1] as List<AcademicYear>;
      final matches = years.where((y) => y.id == detail.academicYearId);
      setState(() {
        _detail = detail;
        _academicYearName = matches.isEmpty ? null : matches.first.name;
        _loadingDetail = false;
      });
      final guardianId = detail.guardianId;
      if (guardianId != null) {
        final guardian = await repository.fetchGuardianDetail(guardianId);
        if (!mounted) return;
        if (guardian != null) {
          setState(() {
            _guardianName = guardian.$1.isNotEmpty ? guardian.$1 : null;
            _guardianPhone = guardian.$2.isNotEmpty ? guardian.$2 : null;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detailError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _toggleStatus() async {
    setState(() => _statusMutating = true);
    final nextActive = !_s.isActive;
    try {
      await ref.read(studentRepositoryProvider).setStudentsStatus([_s.id], isActive: nextActive);
      if (!mounted) return;
      setState(() {
        _detail = _s.copyWith(
          status: nextActive ? StudentStatus.active : StudentStatus.inactive,
        );
        _statusMutating = false;
        _didMutate = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nextActive ? 'Student activated.' : 'Student deactivated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMutating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openEditProfile() async {
    final saved = await context.push<bool>('/students/enroll', extra: _s);
    if (saved == true) {
      _didMutate = true;
      setState(() {
        _loadingDetail = true;
        _detailError = null;
      });
      _loadDetail();
    }
  }

  /// Mirrors `fullName(viewStudent).slice(0, 2).toUpperCase()` exactly —
  /// the first two characters of the full name string, not one initial per
  /// name part.
  String _initials(String fullName) {
    if (fullName.isEmpty) return 'ST';
    return fullName.substring(0, fullName.length < 2 ? fullName.length : 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabsRow(),
            Expanded(child: _buildActiveTabBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  /// Mirrors `.drawer-head` — avatar + name + subtitle on the left, a
  /// bordered "X" close button on the right.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFECEEF6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFECE8FF), shape: BoxShape.circle),
            child: Text(
              _initials(_s.fullName),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4F39F6)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _s.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    letterSpacing: -0.2,
                    color: const Color(0xFF1A1D33),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_s.admissionNo.isEmpty ? '-' : _s.admissionNo} · ${_s.className.isEmpty ? '-' : _s.className} · ${_s.sectionName.isEmpty ? '-' : _s.sectionName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF70728A)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildCloseButton(),
        ],
      ),
    );
  }

  /// Mirrors `.drawer-close` — a literal "X" glyph in a bordered square,
  /// not a Material back-arrow icon button.
  Widget _buildCloseButton() {
    return InkWell(
      onTap: () => Navigator.of(context).pop(_didMutate),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          border: Border.all(color: const Color(0xFFDFE2F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('X', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF42455D))),
      ),
    );
  }

  /// Mirrors `.drawer-tabs`/`.tab`/`.tab.active` — 5 equal-width bordered
  /// buttons (a CSS grid in the reference, `repeat(5, 1fr)`), not a Material
  /// TabBar with an underline indicator.
  Widget _buildTabsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFECEEF6))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _kTabLabels.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _buildTabButton(i)),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(int index) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFFF8F9FF),
          border: Border.all(color: isActive ? const Color(0xFFD3D7EF) : const Color(0xFFE1E4F2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _kTabLabels[index],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? const Color(0xFF1A1E37) : const Color(0xFF666B84),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabBody() {
    if (_loadingDetail) {
      return const _DrawerNote(text: 'Loading student profile...');
    }
    if (_detailError != null) {
      return _DrawerNote(
        text: _detailError!,
        isError: true,
        onRetry: () {
          setState(() {
            _loadingDetail = true;
            _detailError = null;
          });
          _loadDetail();
        },
      );
    }
    switch (_activeTab) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildAcademicTab();
      case 2:
        return _AttendanceTab(studentId: _s.id);
      case 3:
        return const _FeesTab();
      default:
        return const _AchievementsTab();
    }
  }

  Widget _buildProfileTab() {
    final (statusBg, statusText, statusLabel) = _statusVisuals(_s);
    final address = [_s.addressLine, _s.city, _s.district, _s.state, _s.pincode]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
    final guardianDisplay = _guardianName ?? (_s.guardianId == null ? 'Not linked' : 'Linked');
    final guardianPhoneDisplay = _guardianPhone ?? '-';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        _DrawerSection(
          title: 'IDENTITY',
          rows: [
            _DrawerRow(label: 'Admission no', value: _plainValue(_s.admissionNo.isEmpty ? '-' : _s.admissionNo)),
            _DrawerRow(
              label: 'Date of birth',
              value: _plainValue(_s.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(_s.dateOfBirth!) : '-'),
            ),
            _DrawerRow(label: 'Gender', value: _plainValue(_s.gender?.label ?? '-')),
            _DrawerRow(
              label: 'Status',
              value: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusText)),
              ),
            ),
          ],
        ),
        _DrawerSection(
          title: 'CONTACT',
          rows: [
            _DrawerRow(label: 'Guardian', value: _plainValue(guardianDisplay)),
            _DrawerRow(label: 'Phone', value: _plainValue(guardianPhoneDisplay)),
            _DrawerRow(label: 'Email', value: _plainValue(_s.email?.isNotEmpty == true ? _s.email! : '-')),
            _DrawerRow(label: 'Address', value: _plainValue(address.isEmpty ? '-' : address)),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        _DrawerSection(
          title: 'ACADEMIC',
          rows: [
            _DrawerRow(
              label: 'Class & Section',
              value: _plainValue(
                '${_s.className.isEmpty ? '-' : _s.className} / ${_s.sectionName.isEmpty ? '-' : _s.sectionName}',
              ),
            ),
            _DrawerRow(label: 'Roll no', value: _plainValue(_s.rollNo?.isNotEmpty == true ? _s.rollNo! : '-')),
            // Backend has no `academic_year_name` field — same "2026–27"
            // fallback the frontend itself uses when unresolved.
            _DrawerRow(label: 'Academic year', value: _plainValue(_academicYearName ?? '2026–27')),
            // No `admission_type` field on the real backend Student model —
            // mirrors the frontend's own hardcoded "New admission" fallback.
            const _DrawerRow(label: 'Admission type', value: _PlainValue('New admission')),
          ],
        ),
      ],
    );
  }

  Widget _plainValue(String text) => _PlainValue(text);

  /// Mirrors the drawer's status pill: Archived > Docs pending > Active >
  /// Inactive — the same precedence used by the List table's row status.
  (Color, Color, String) _statusVisuals(StudentData student) {
    if (student.isArchived) {
      return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C), 'Archived');
    }
    if (student.docsPendingCount > 0) {
      return (const Color(0xFFFFF7E8), const Color(0xFFA16207), 'Docs pending');
    }
    if (student.isActive) {
      return (const Color(0xFFECFDF3), const Color(0xFF047857), 'Active');
    }
    return (const Color(0xFFF3F4F6), const Color(0xFF4B5563), 'Inactive');
  }

  /// Mirrors `.drawer-footer` — Message parent / Deactivate|Activate / Edit
  /// profile, right-aligned with a top divider.
  Widget _buildFooter(BuildContext context) {
    final isActive = _s.isActive;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFECEEF6))),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            // Permanently disabled — mirrors the reference frontend's own
            // `.drawer-footer` button, which is `disabled` with a "Message
            // parent (coming soon)" tooltip, not a working feature.
            Tooltip(
              message: 'Message parent (coming soon)',
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                label: const Text('Message parent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF575B76),
                  side: const BorderSide(color: Color(0xFFD8DAEA)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (isActive)
              OutlinedButton(
                onPressed: _statusMutating ? null : _toggleStatus,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF575B76),
                  side: const BorderSide(color: Color(0xFFD8DAEA)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_statusMutating ? 'Updating…' : 'Deactivate'),
              )
            else
              ElevatedButton(
                onPressed: _statusMutating ? null : _toggleStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F39F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_statusMutating ? 'Updating…' : 'Activate'),
              ),
            ElevatedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F39F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(120, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors `.drawer-note`/`.drawer-error` — plain text, no spinner/card,
/// exactly like the frontend's loading/error states.
class _DrawerNote extends StatelessWidget {
  final String text;
  final bool isError;
  final VoidCallback? onRetry;

  const _DrawerNote({required this.text, this.isError = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 13, color: isError ? const Color(0xFFB91C1C) : const Color(0xFF1A1D33)),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// Mirrors `.drawer-section` — a top divider + 12px padding-top + 10px
/// margin-top before the section title, applied to every section
/// (including the first), not a bordered/rounded "card" box.
class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _DrawerSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFECEEF6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF747896),
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

/// Mirrors `.drawer-row` — a 110px label column + value column, 8px
/// vertical padding, a **dashed** bottom divider (`border-bottom: 1px
/// dashed #eceef6` — Flutter has no dashed-border primitive, so it's drawn
/// as evenly-spaced short segments below the row instead).
class _DrawerRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _DrawerRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF6F7289))),
              ),
              const SizedBox(width: 10),
              Expanded(child: value),
            ],
          ),
        ),
        const _DashedDivider(),
      ],
    );
  }
}

class _PlainValue extends StatelessWidget {
  final String text;
  const _PlainValue(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2237)),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor().clamp(0, 1000);
        return SizedBox(
          height: 1,
          width: double.infinity,
          child: Row(
            children: List.generate(
              count,
              (_) => const Padding(
                padding: EdgeInsets.only(right: dashSpace),
                child: SizedBox(width: dashWidth, height: 1, child: ColoredBox(color: Color(0xFFECEEF6))),
              ),
            ),
          ),
        );
      },
    );
  }
}

const List<String> _kAttMonthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const Set<String> _kIncidentStatuses = {
  'absent', 'late', 'late_arrival', 'early_pickup', 'early_departure', 'medical', 'permission',
};

const Map<String, (Color bg, Color color, Color dot)> _kAttStatusStyle = {
  'present': (Color(0xFFF0FDF4), Color(0xFF16A34A), Color(0xFF22C55E)),
  'absent': (Color(0xFFFEF2F2), Color(0xFFDC2626), Color(0xFFEF4444)),
  'late': (Color(0xFFFFFBEB), Color(0xFFD97706), Color(0xFFF59E0B)),
  'late_arrival': (Color(0xFFFFFBEB), Color(0xFFD97706), Color(0xFFF59E0B)),
  'early_pickup': (Color(0xFFF0F9FF), Color(0xFF0284C7), Color(0xFF38BDF8)),
  'early_departure': (Color(0xFFF0F9FF), Color(0xFF0284C7), Color(0xFF38BDF8)),
  'medical': (Color(0xFFFDF4FF), Color(0xFF9333EA), Color(0xFFC084FC)),
  'permission': (Color(0xFFF0F9FF), Color(0xFF0369A1), Color(0xFF38BDF8)),
};

class _MonthStat {
  final String label;
  final int year;
  final int month; // 1-12
  final int pct; // -1 = no data, -2 = future, else 0-100
  final int total;
  const _MonthStat({
    required this.label,
    required this.year,
    required this.month,
    required this.pct,
    required this.total,
  });
}

/// Mirrors the frontend drawer's Attendance tab exactly in substance (same
/// endpoint, same academic-year Jun–May scoping, same 3 accordions) with a
/// mobile-appropriate visual simplification: one `CircularProgressIndicator`
/// ring in place of the reference's hand-drawn SVG ring, matching color
/// thresholds and every number.
class _AttendanceTab extends ConsumerStatefulWidget {
  final int studentId;
  const _AttendanceTab({required this.studentId});

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  late int _acYearStart;
  bool _loading = true;
  String? _error;
  List<StudentAttendanceRecord> _records = [];

  bool _openOverall = true;
  bool _openCalendar = false;
  bool _openIncidents = false;

  late int _viewYear;
  late int _viewMonth; // 1-12

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _acYearStart = now.month >= 6 ? now.year : now.year - 1;
    _viewYear = now.year;
    _viewMonth = now.month;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await ref.read(studentRepositoryProvider).fetchStudentAttendance(
            widget.studentId,
            from: DateTime(_acYearStart, 6, 1),
            to: DateTime(_acYearStart + 1, 5, 31),
          );
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load attendance for this student.';
      });
    }
  }

  void _changeAcademicYear(int delta) {
    final now = DateTime.now();
    final currentAcStart = now.month >= 6 ? now.year : now.year - 1;
    final next = _acYearStart + delta;
    if (next > currentAcStart) return;
    setState(() => _acYearStart = next);
    _load();
  }

  String get _acYearLabel => '$_acYearStart-${(_acYearStart + 1).toString().substring(2)}';

  List<_MonthStat> _academicYearMonthData() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final mo0 = (5 + i) % 12; // 0-indexed, 5=Jun
      final month = mo0 + 1;
      final year = month >= 6 ? _acYearStart : _acYearStart + 1;
      final recs = _records.where((r) => r.date.year == year && r.date.month == month).toList();
      final present = recs.where((r) => r.status == 'present').length;
      final isFuture = year > now.year || (year == now.year && month > now.month);
      final pct = recs.isNotEmpty ? (present / recs.length * 100).round() : (isFuture ? -2 : -1);
      return _MonthStat(label: _kAttMonthNames[mo0], year: year, month: month, pct: pct, total: recs.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _DrawerNote(text: 'Loading attendance data…');
    }
    if (_error != null) {
      return _DrawerNote(text: _error!, isError: true, onRetry: _load);
    }

    final total = _records.length;
    final present = _records.where((r) => r.status == 'present').length;
    final absent = _records.where((r) => r.status == 'absent').length;
    final late = _records.where((r) => r.status == 'late' || r.status == 'late_arrival').length;
    final pct = total > 0 ? (present / total * 100).round() : 0;
    final monthData = _academicYearMonthData();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _yearNavButton(icon: Icons.chevron_left, onTap: () => _changeAcademicYear(-1)),
            const SizedBox(width: 8),
            Text(_acYearLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            const SizedBox(width: 8),
            _yearNavButton(
              icon: Icons.chevron_right,
              onTap: () {
                final now = DateTime.now();
                final currentAcStart = now.month >= 6 ? now.year : now.year - 1;
                if (_acYearStart < currentAcStart) _changeAcademicYear(1);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        _accordion(
          title: 'Overview & Trends',
          badge: total > 0 ? '$pct%' : null,
          isOpen: _openOverall,
          onToggle: () => setState(() {
            _openOverall = !_openOverall;
            _openCalendar = false;
            _openIncidents = false;
          }),
          child: _buildOverviewBody(total, present, absent, late, pct, monthData),
        ),
        const SizedBox(height: 10),
        _accordion(
          title: 'Monthly Calendar',
          badge: '${_kAttMonthNames[_viewMonth - 1]} $_viewYear',
          isOpen: _openCalendar,
          onToggle: () => setState(() {
            _openCalendar = !_openCalendar;
            _openOverall = false;
            _openIncidents = false;
          }),
          child: _buildCalendarBody(),
        ),
        const SizedBox(height: 10),
        _accordion(
          title: 'Leave & Incident Log',
          badge: _incidentCount() > 0 ? '${_incidentCount()}' : null,
          isOpen: _openIncidents,
          onToggle: () => setState(() {
            _openIncidents = !_openIncidents;
            _openOverall = false;
            _openCalendar = false;
          }),
          child: _buildIncidentsBody(),
        ),
      ],
    );
  }

  Widget _yearNavButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(icon, size: 16, color: const Color(0xFF374151)),
      ),
    );
  }

  Widget _accordion({
    required String title,
    required String? badge,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFFF5F3FF) : const Color(0xFFF8F9FF),
              border: Border.all(color: isOpen ? const Color(0xFFC4B5FD) : const Color(0xFFECEEF6)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOpen ? const Color(0xFF4F39F6) : const Color(0xFF374151),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: isOpen ? const Color(0xFFEDE9FE) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isOpen ? const Color(0xFF5B21B6) : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isOpen ? const Color(0xFF4F39F6) : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC4B5FD)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: child,
          ),
      ],
    );
  }

  Widget _buildOverviewBody(
    int total,
    int present,
    int absent,
    int late,
    int pct,
    List<_MonthStat> monthData,
  ) {
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text('📅', style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text('No attendance records found', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF6B7280))),
            SizedBox(height: 4),
            Text(
              'Records will appear once attendance is marked in the system.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }
    final ringColor = pct >= 90 ? const Color(0xFF16A34A) : pct >= 75 ? const Color(0xFFD97706) : const Color(0xFFDC2626);
    final recordedMonths = monthData.where((m) => m.total > 0).toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            border: Border.all(color: const Color(0xFFE0E4F2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OVERALL ATTENDANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.4)),
                        const SizedBox(height: 2),
                        Text('$pct%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ringColor, height: 1)),
                        const SizedBox(height: 3),
                        Text('$total school days recorded', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: pct / 100,
                          strokeWidth: 5,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation(ringColor),
                        ),
                        Text('$pct%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: ringColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _attStatCard('Present', present, const Color(0xFF16A34A), const Color(0xFFF0FDF4))),
                  const SizedBox(width: 6),
                  Expanded(child: _attStatCard('Absent', absent, const Color(0xFFDC2626), const Color(0xFFFEF2F2))),
                  const SizedBox(width: 6),
                  Expanded(child: _attStatCard('Late', late, const Color(0xFFD97706), const Color(0xFFFFFBEB))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            border: Border.all(color: const Color(0xFFECEEF6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACADEMIC YEAR $_acYearLabel',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF747896), letterSpacing: 0.4),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthData.map((m) {
                    final barColor = m.pct == -2
                        ? const Color(0xFFF3F4F6)
                        : m.pct == -1
                            ? const Color(0xFFE5E7EB)
                            : m.pct >= 90
                                ? const Color(0xFF22C55E)
                                : m.pct >= 75
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444);
                    final isActive = m.year == _viewYear && m.month == _viewMonth;
                    final barHeight = m.pct >= 0 ? (4.0 + m.pct * 0.42).clamp(4.0, 45.0) : 4.0;
                    return Expanded(
                      child: InkWell(
                        onTap: m.pct == -2
                            ? null
                            : () => setState(() {
                                  _viewYear = m.year;
                                  _viewMonth = m.month;
                                  _openCalendar = true;
                                  _openOverall = false;
                                  _openIncidents = false;
                                }),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 12,
                              child: Text(
                                m.pct >= 0 ? '${m.pct}%' : '',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isActive ? const Color(0xFF4F39F6) : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                            Container(
                              height: barHeight,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                border: isActive ? Border.all(color: const Color(0xFF4F39F6), width: 1.5) : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive ? const Color(0xFF4F39F6) : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        if (recordedMonths.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              border: Border.all(color: const Color(0xFFECEEF6)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFECEEF6)))),
                  child: const Text(
                    'MONTH-WISE SUMMARY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF747896), letterSpacing: 0.4),
                  ),
                ),
                for (final m in recordedMonths) _monthSummaryRow(m),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _monthSummaryRow(_MonthStat m) {
    final pctColor = m.pct < 0 ? const Color(0xFF9CA3AF) : m.pct >= 90 ? const Color(0xFF16A34A) : m.pct >= 75 ? const Color(0xFFD97706) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text('${m.label} ${m.year}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)),
              child: m.pct >= 0
                  ? FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (m.pct / 100).clamp(0.0, 1.0),
                      child: Container(decoration: BoxDecoration(color: pctColor, borderRadius: BorderRadius.circular(3))),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              m.pct >= 0 ? '${m.pct}%' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pctColor),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text('${m.total}d', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }

  Widget _attStatCard(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildCalendarBody() {
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday; // Mon=1..Sun=7
    final startOffset = firstWeekday - 1;
    final attMap = <String, String>{
      for (final r in _records) r.dateKey: r.status,
    };
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final canGoNext = DateTime(_viewYear, _viewMonth + 1, 1).isBefore(today) ||
        DateTime(_viewYear, _viewMonth + 1, 1).isAtSameMomentAs(today);
    final monthRecs = _records.where((r) => r.date.year == _viewYear && r.date.month == _viewMonth).toList();
    final mPresent = monthRecs.where((r) => r.status == 'present').length;
    final mAbsent = monthRecs.where((r) => r.status == 'absent').length;
    final mLate = monthRecs.where((r) => r.status == 'late' || r.status == 'late_arrival').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => setState(() {
                if (_viewMonth == 1) {
                  _viewMonth = 12;
                  _viewYear--;
                } else {
                  _viewMonth--;
                }
              }),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_left, color: Color(0xFF4F39F6)),
              ),
            ),
            Expanded(
              child: Text(
                '${_kAttMonthNames[_viewMonth - 1]} $_viewYear',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1D33)),
              ),
            ),
            InkWell(
              onTap: !canGoNext
                  ? null
                  : () => setState(() {
                        if (_viewMonth == 12) {
                          _viewMonth = 1;
                          _viewYear++;
                        } else {
                          _viewMonth++;
                        }
                      }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, color: canGoNext ? const Color(0xFF4F39F6) : const Color(0xFFD1D5DB)),
              ),
            ),
          ],
        ),
        if (monthRecs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _attStatCard('Present', mPresent, const Color(0xFF16A34A), const Color(0xFFF0FDF4))),
              const SizedBox(width: 6),
              Expanded(child: _attStatCard('Absent', mAbsent, const Color(0xFFDC2626), const Color(0xFFFEF2F2))),
              const SizedBox(width: 6),
              Expanded(child: _attStatCard('Late', mLate, const Color(0xFFD97706), const Color(0xFFFFFBEB))),
            ],
          ),
        ],
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (var i = 0; i < startOffset; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++) _calendarDayCell(day, attMap, today),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: const [
            _LegendDot(color: Color(0xFF22C55E), label: 'Present'),
            _LegendDot(color: Color(0xFFEF4444), label: 'Absent'),
            _LegendDot(color: Color(0xFFF59E0B), label: 'Late'),
            _LegendDot(color: Color(0xFF9CA3AF), label: 'No data'),
          ],
        ),
      ],
    );
  }

  Widget _calendarDayCell(int day, Map<String, String> attMap, DateTime today) {
    final date = DateTime(_viewYear, _viewMonth, day);
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isFuture = date.isAfter(today);
    final status = attMap[dateKey];
    final style = status != null ? _kAttStatusStyle[status] : null;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF4F39F6) : style?.$1 ?? (isFuture ? Colors.transparent : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(5),
        border: isToday ? null : Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 10,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          color: isToday ? Colors.white : style?.$2 ?? (isFuture ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  int _incidentCount() => _incidentMonths().fold(0, (sum, e) => sum + e.$2.length);

  List<(_MonthStat, List<StudentAttendanceRecord>)> _incidentMonths() {
    final monthData = _academicYearMonthData();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <(_MonthStat, List<StudentAttendanceRecord>)>[];
    for (final m in monthData) {
      final monthStart = DateTime(m.year, m.month, 1);
      if (monthStart.isAfter(today)) continue;
      final incidents = _records
          .where((r) => r.date.year == m.year && r.date.month == m.month && _kIncidentStatuses.contains(r.status))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (incidents.isNotEmpty) result.add((m, incidents));
    }
    result.sort((a, b) => (b.$1.year * 100 + b.$1.month).compareTo(a.$1.year * 100 + a.$1.month));
    return result;
  }

  Widget _buildIncidentsBody() {
    final months = _incidentMonths();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Absences, late arrivals, early pick-ups, medical & permission records for the current academic year.",
          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 10),
        if (months.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text('🌟', style: TextStyle(fontSize: 28)),
                SizedBox(height: 6),
                Text('Perfect record this year!', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF16A34A), fontSize: 13)),
                SizedBox(height: 4),
                Text(
                  'No absences or incidents recorded for the academic year.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          )
        else
          for (final entry in months) ...[
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${entry.$1.label} ${entry.$1.year} · ${entry.$2.length} record${entry.$2.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.3),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
              ],
            ),
            const SizedBox(height: 6),
            for (final rec in entry.$2) _incidentRow(rec),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _incidentRow(StudentAttendanceRecord rec) {
    final style = _kAttStatusStyle[rec.status] ?? (const Color(0xFFF3F4F6), const Color(0xFF6B7280), const Color(0xFF9CA3AF));
    final icon = rec.status == 'absent'
        ? '❌'
        : rec.status.contains('early')
            ? '🔔'
            : rec.status == 'medical'
                ? '🏥'
                : rec.status == 'permission'
                    ? '📋'
                    : '⏰';
    final label = rec.status.replaceAll('_', ' ');
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: style.$1,
        border: Border.all(color: style.$3.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.isEmpty ? '-' : '${label[0].toUpperCase()}${label.substring(1)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: style.$2),
                ),
                if (rec.remarks != null && rec.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(rec.remarks!, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ],
            ),
          ),
          Text(
            DateFormat('dd MMM').format(rec.date),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
      ],
    );
  }
}

class _FeesTab extends StatelessWidget {
  const _FeesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: const [
        _DrawerSection(
          title: 'FEE SUMMARY',
          rows: [
            _DrawerRow(label: 'Fee plan', value: _PlainValue('Standard — Grade fee group')),
            _DrawerRow(label: 'Paid', value: _PlainValue('₹32,000 of ₹40,000')),
            _DrawerRow(label: 'Next due', value: _PlainValue('15 Aug')),
          ],
        ),
      ],
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: const [
        _DrawerSection(
          title: 'CLUBS & COMPETITIONS',
          rows: [
            _DrawerRow(label: 'Clubs', value: _PlainValue('No memberships on file')),
            _DrawerRow(label: 'Competitions', value: _PlainValue('No results on file')),
          ],
        ),
      ],
    );
  }
}
