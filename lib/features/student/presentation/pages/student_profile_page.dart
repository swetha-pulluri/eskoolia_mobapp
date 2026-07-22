import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/student_data.dart';
import '../providers/student_providers.dart';

/// Student profile view — mobile equivalent of frontend
/// StudentListPanel.tsx's right-side slide-in drawer (`.view-drawer`).
/// Pushed as a full page rather than a side panel (standard mobile
/// adaptation of a desktop drawer — there's no room for a persistent side
/// panel on a phone), with the same Profile / Academic / Attendance / Fees
/// / Achievements tabs.
///
/// The row passed in via [student] is only the List table's abbreviated
/// snapshot (`StudentListSerializer` — no email/address/guardian name). On
/// open this fetches the full `GET /students/students/{id}/` detail exactly
/// like the frontend's own drawer does, then (if a guardian is linked)
/// resolves the guardian's name/phone via a follow-up `GET
/// /students/guardians/{id}/`, since `Student.guardian` is only a raw FK id.
///
/// Scope note: the frontend drawer's attendance ring chart/calendar, club
/// membership widgets, and "AI Performance Review" generator are deep,
/// separate sub-features (analytics + AI text generation) beyond a UI-only
/// pass of the List/Enroll screens — each tab here shows the same
/// information as simple, static summaries instead.
class StudentProfilePage extends ConsumerStatefulWidget {
  final StudentData student;

  const StudentProfilePage({super.key, required this.student});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  StudentData? _detail;
  bool _loadingDetail = true;
  String? _detailError;

  String? _guardianName;
  String? _guardianPhone;

  bool _statusMutating = false;
  bool _didMutate = false;

  StudentData get _s => _detail ?? widget.student;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final repository = ref.read(studentRepositoryProvider);
    try {
      final detail = await repository.fetchStudentDetail(widget.student.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.studentListPageBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.studentListInk,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_didMutate),
          ),
          title: Text(_s.fullName, style: const TextStyle(fontSize: 16)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.studentListBrand,
            unselectedLabelColor: AppColors.studentListMuted,
            indicatorColor: AppColors.studentListBrand,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Profile'),
              Tab(text: 'Academic'),
              Tab(text: 'Attendance'),
              Tab(text: 'Fees'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(
              student: _s,
              loadingDetail: _loadingDetail,
              detailError: _detailError,
              guardianName: _guardianName,
              guardianPhone: _guardianPhone,
              onRetry: () {
                setState(() {
                  _loadingDetail = true;
                  _detailError = null;
                });
                _loadDetail();
              },
            ),
            _AcademicTab(student: _s),
            const _AttendanceTab(),
            const _FeesTab(),
            const _AchievementsTab(),
          ],
        ),
        bottomNavigationBar: _buildFooter(context),
      ),
    );
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
            OutlinedButton.icon(
              onPressed: () => _comingSoon('Messaging parents'),
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
                  backgroundColor: AppColors.studentListBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_statusMutating ? 'Updating…' : 'Activate'),
              ),
            ElevatedButton.icon(
              onPressed: () => _comingSoon('Editing this profile'),
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.studentListBrand,
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

Widget _sectionCard({required String title, required List<Widget> rows}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.studentListLine),
      borderRadius: BorderRadius.circular(12),
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
            color: AppColors.studentPanelDesc,
          ),
        ),
        const SizedBox(height: 10),
        ...rows,
      ],
    ),
  );
}

Widget _infoRow(String label, Widget value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.studentSecondaryText),
          ),
        ),
        Expanded(child: value),
      ],
    ),
  );
}

Widget _infoText(String value) {
  return Text(
    value,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.studentPrimaryText,
    ),
  );
}

/// Mirrors the drawer's status pill: Archived > Docs pending > Active >
/// Inactive — the exact same precedence used by the List table's row status.
(Color, Color, String) _statusVisuals(StudentData student) {
  if (student.isArchived) {
    return (AppColors.studentStatusArchivedBg, AppColors.studentStatusArchivedText, 'Archived');
  }
  if (student.docsPendingCount > 0) {
    return (AppColors.studentStatusPendingBg, AppColors.studentStatusPendingText, 'Docs pending');
  }
  if (student.isActive) {
    return (AppColors.studentStatusActiveBg, AppColors.studentStatusActiveText, 'Active');
  }
  return (AppColors.studentStatusInactiveBg, AppColors.studentStatusInactiveText, 'Inactive');
}

class _ProfileTab extends StatelessWidget {
  final StudentData student;
  final bool loadingDetail;
  final String? detailError;
  final String? guardianName;
  final String? guardianPhone;
  final VoidCallback onRetry;

  const _ProfileTab({
    required this.student,
    required this.loadingDetail,
    required this.detailError,
    required this.guardianName,
    required this.guardianPhone,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final dob = student.dateOfBirth;
    final (statusBg, statusText, statusLabel) = _statusVisuals(student);
    final initials = [
      if (student.firstName.isNotEmpty) student.firstName[0],
      if (student.lastName.isNotEmpty) student.lastName[0],
    ].join().toUpperCase();
    final address = [student.addressLine, student.city, student.district, student.state, student.pincode]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
    final guardianDisplay = guardianName ?? (student.guardianId == null ? 'Not linked' : 'Linked');
    final guardianPhoneDisplay = guardianPhone ?? '—';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.studentAvatarBg,
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.studentAvatarText,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.admissionNo} · ${student.className} · Section ${student.sectionName}',
                    style: const TextStyle(fontSize: 13, color: AppColors.studentSecondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loadingDetail)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (detailError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  detailError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.studentListMuted),
                ),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          )
        else ...[
          _sectionCard(
            title: 'IDENTITY',
            rows: [
              _infoRow('Admission no', _infoText(student.admissionNo.isEmpty ? '—' : student.admissionNo)),
              _infoRow(
                'Date of birth',
                _infoText(dob != null ? DateFormat('dd/MM/yyyy').format(dob) : '—'),
              ),
              _infoRow('Gender', _infoText(student.gender?.label ?? '—')),
              _infoRow(
                'Status',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusText),
                  ),
                ),
              ),
            ],
          ),
          _sectionCard(
            title: 'CONTACT',
            rows: [
              _infoRow('Guardian', _infoText(guardianDisplay)),
              _infoRow('Phone', _infoText(guardianPhoneDisplay)),
              _infoRow('Email', _infoText(student.email?.isNotEmpty == true ? student.email! : '—')),
              _infoRow('Address', _infoText(address.isEmpty ? '—' : address)),
            ],
          ),
        ],
      ],
    );
  }
}

class _AcademicTab extends StatelessWidget {
  final StudentData student;
  const _AcademicTab({required this.student});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'PLACEMENT',
          rows: [
            _infoRow('Class', _infoText(student.className)),
            _infoRow('Section', _infoText(student.sectionName)),
            _infoRow('Enrolled on', _infoText(DateFormat('dd/MM/yyyy').format(student.enrolledAt))),
            _infoRow('Docs pending', _infoText('${student.docsPendingCount}')),
          ],
        ),
      ],
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'THIS MONTH',
          rows: [
            _infoRow('Present', _infoText('18 days')),
            _infoRow('Absent', _infoText('2 days')),
            _infoRow('Late arrival', _infoText('1 day')),
            _infoRow('Attendance rate', _infoText('90%')),
          ],
        ),
      ],
    );
  }
}

class _FeesTab extends StatelessWidget {
  const _FeesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'FEE SUMMARY',
          rows: [
            _infoRow('Fee plan', _infoText('Standard — Grade fee group')),
            _infoRow('Paid', _infoText('₹32,000 of ₹40,000')),
            _infoRow('Next due', _infoText('15 Aug')),
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
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'CLUBS & COMPETITIONS',
          rows: [
            _infoRow('Clubs', _infoText('No memberships on file')),
            _infoRow('Competitions', _infoText('No results on file')),
          ],
        ),
      ],
    );
  }
}
