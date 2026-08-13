import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/student_profile_entity.dart';
import '../providers/my_classes_providers.dart';
import '../widgets/my_classes/load_error_card.dart';
import '../widgets/my_classes/profile_tabs/academic_tab.dart';
import '../widgets/my_classes/profile_tabs/attendance_tab.dart';
import '../widgets/my_classes/profile_tabs/behaviour_tab.dart';
import '../widgets/my_classes/profile_tabs/credentials_tab.dart';
import '../widgets/my_classes/profile_tabs/overview_tab.dart';
import '../widgets/my_classes/profile_tabs/placeholder_tab.dart';

class _ProfileTabDef {
  final String key;
  final IconData icon;
  final String label;
  const _ProfileTabDef(this.key, this.icon, this.label);
}

/// Fixed tab order — matches web's `ALL_TABS`. Which of these actually
/// render is server-driven via `sections_available`.
const List<_ProfileTabDef> _allTabs = [
  _ProfileTabDef('overview', Icons.person_outline, 'Overview'),
  _ProfileTabDef('academic', Icons.menu_book_outlined, 'Academic'),
  _ProfileTabDef('attendance', Icons.calendar_today_outlined, 'Attendance'),
  _ProfileTabDef('behaviour', Icons.shield_outlined, 'Behaviour'),
  _ProfileTabDef('homework', Icons.menu_book_outlined, 'Homework'),
  _ProfileTabDef('communication', Icons.forum_outlined, 'Communication'),
  _ProfileTabDef('credentials', Icons.key_outlined, 'Credentials'),
  _ProfileTabDef('notes', Icons.sticky_note_2_outlined, 'Notes'),
];

/// "Student Profile" — on web this is a client-state-only slide-in drawer
/// (`StudentProfileDrawer.tsx`) with no URL/id param at all. Ported here as
/// a real pushed, deep-linkable page (`/teacher/classes/students/:id`),
/// matching this codebase's existing convention for content-heavy
/// multi-tab detail screens (`StudentProfilePage`) rather than a modal.
class TeacherStudentProfilePage extends ConsumerStatefulWidget {
  final int studentId;
  const TeacherStudentProfilePage({super.key, required this.studentId});

  @override
  ConsumerState<TeacherStudentProfilePage> createState() => _TeacherStudentProfilePageState();
}

class _TeacherStudentProfilePageState extends ConsumerState<TeacherStudentProfilePage> {
  String? _activeTab;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((p) => p[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(studentProfileProvider(widget.studentId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => Column(children: [_header(null), const Expanded(child: Center(child: CircularProgressIndicator()))]),
          error: (error, _) => Column(
            children: [
              _header(null),
              Expanded(
                child: LoadErrorCard(
                  title: 'Could not load profile',
                  message: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => ref.invalidate(studentProfileProvider(widget.studentId)),
                  iconSize: 28,
                ),
              ),
            ],
          ),
          data: (profile) {
            final availableTabs = _allTabs.where((t) => profile.sectionsAvailable.contains(t.key)).toList();
            final tabs = availableTabs.isEmpty ? [_allTabs.first] : availableTabs;
            _activeTab ??= tabs.first.key;
            if (!tabs.any((t) => t.key == _activeTab)) _activeTab = tabs.first.key;

            return Column(
              children: [
                _header(profile.overview),
                _tabsRow(tabs),
                Expanded(child: _tabBody(profile)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(StudentOverviewEntity? overview) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(color: AppColors.bg2, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft,
              shape: BoxShape.circle,
              image: overview?.photoUrl != null ? DecorationImage(image: NetworkImage(overview!.photoUrl!), fit: BoxFit.cover) : null,
            ),
            child: overview?.photoUrl == null
                ? Text(_initials(overview?.name ?? ''), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brandPurple))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: overview == null
                ? const Text('Student Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink1))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(overview.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                      const SizedBox(height: 3),
                      Text(
                        [
                          overview.className,
                          if (overview.sectionName.isNotEmpty) '– ${overview.sectionName}',
                          if (overview.rollNo.isNotEmpty) '· Roll ${overview.rollNo}',
                        ].join(' '),
                        style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (overview.gender.isNotEmpty)
                            _chip(overview.gender, const Color(0xFFF5F5FB), AppColors.ink2),
                          if (overview.bloodGroup.isNotEmpty)
                            _chip(overview.bloodGroup, const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
                        ],
                      ),
                    ],
                  ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close, size: 16, color: AppColors.ink2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _tabsRow(List<_ProfileTabDef> tabs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Wrap(
        spacing: 4,
        children: [
          for (final t in tabs)
            InkWell(
              onTap: () => setState(() => _activeTab = t.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _activeTab == t.key ? AppColors.brandPurple : Colors.transparent, width: 2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 13, color: _activeTab == t.key ? AppColors.brandPurple : AppColors.ink2),
                    const SizedBox(width: 5),
                    Text(
                      t.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _activeTab == t.key ? AppColors.brandPurple : AppColors.ink2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabBody(StudentProfileEntity profile) {
    switch (_activeTab) {
      case 'academic':
        return AcademicTab(marks: profile.academicMarks);
      case 'attendance':
        return AttendanceTab(records: profile.attendanceRecords, summary: profile.attendanceSummary);
      case 'behaviour':
        return BehaviourTab(records: profile.behaviourRecords, totalPoints: profile.behaviourTotalPoints);
      case 'homework':
        return const PlaceholderTab(icon: Icons.menu_book_outlined, label: 'Homework', subtext: 'Coming in Sprint 6');
      case 'communication':
        return const PlaceholderTab(icon: Icons.forum_outlined, label: 'Communication', subtext: 'Coming in Sprint 7');
      case 'credentials':
        return CredentialsTab(studentId: widget.studentId);
      case 'notes':
        return const PlaceholderTab(icon: Icons.sticky_note_2_outlined, label: 'Teacher Notes', subtext: 'Coming in a future sprint');
      default:
        return OverviewTab(overview: profile.overview);
    }
  }
}
