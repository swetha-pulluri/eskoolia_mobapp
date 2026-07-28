import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../student/domain/models/student_data.dart';
import '../../../student/presentation/pages/student_profile_page.dart';
import 'ai_assistant_colors.dart';

const _pastel = [
  (bg: Color(0xFFEEEAFF), ink: Color(0xFF6D4AFF)),
  (bg: Color(0xFFFEE2E2), ink: Color(0xFFE0463A)),
  (bg: Color(0xFFD1FAE5), ink: Color(0xFF059669)),
  (bg: Color(0xFFFEF3C7), ink: Color(0xFFD97706)),
  (bg: Color(0xFFDBEAFE), ink: Color(0xFF3B82F6)),
  (bg: Color(0xFFFCE7F3), ink: Color(0xFFDB2777)),
];

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  return words.take(2).map((w) => w[0]).join().toUpperCase();
}

/// Mirrors frontend components/aibot/StudentLookupResults.tsx — same
/// layout/spacing/colors. Reuses Flutter's real [StudentData] model
/// (rather than a separate duplicate result shape) and, per explicit
/// instruction, "View Profile"/"Report" navigates to the app's own real,
/// already-built [StudentProfilePage] instead of rebuilding web's separate
/// 8-tab popup.
class AiStudentLookupResults extends ConsumerWidget {
  final List<StudentData> students;
  final String query;
  final VoidCallback onNavigated;

  const AiStudentLookupResults({super.key, required this.students, required this.query, required this.onNavigated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 24, color: aiInk3),
            const SizedBox(height: 6),
            Text('No students found for "$query"', style: const TextStyle(fontSize: 12.5, color: aiInk2)),
            const SizedBox(height: 3),
            const Text('Try a different name or admission number', style: TextStyle(fontSize: 11, color: aiInk3)),
            const SizedBox(height: 8),
            _chip(
              label: 'Search in full student list →',
              onTap: () {
                onNavigated();
                ref.read(appRouterProvider).go('/students');
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 11.5, color: aiInk2),
              children: [
                const TextSpan(text: 'Found '),
                TextSpan(text: '${students.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' student${students.length > 1 ? 's' : ''} matching "$query"'),
              ],
            ),
          ),
        ),
        for (var i = 0; i < students.length; i++) ...[_studentCard(ref, students[i], i), const SizedBox(height: 6)],
        Center(
          child: TextButton(
            onPressed: () {
              onNavigated();
              ref.read(appRouterProvider).go('/students');
            },
            style: TextButton.styleFrom(foregroundColor: aiPurple, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Open full student list →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _studentCard(WidgetRef ref, StudentData s, int i) {
    final p = _pastel[i % _pastel.length];
    final name = '${s.firstName} ${s.lastName}'.trim();
    final admNo = s.admissionNo.isEmpty ? '—' : s.admissionNo;
    final roll = (s.rollNo?.isNotEmpty ?? false) ? s.rollNo! : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(10), color: aiBg0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (s.photoUrl != null && s.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(s.photoUrl!, width: 38, height: 38, fit: BoxFit.cover, errorBuilder: (_, _, _) => _initialsAvatar(p, name)),
            )
          else
            _initialsAvatar(p, name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: aiInk1), overflow: TextOverflow.ellipsis),
                if (s.className.isNotEmpty || s.sectionName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text('🎓 ${s.className}${s.sectionName.isNotEmpty ? ' ${s.sectionName}' : ''}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: aiInk2)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    '${roll != '—' ? 'Roll $roll' : ''}${roll != '—' && admNo != '—' ? ' · ' : ''}Adm $admNo',
                    style: const TextStyle(fontSize: 11, color: aiInk3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _chip(
                label: 'List',
                icon: Icons.open_in_new,
                onTap: () {
                  onNavigated();
                  ref.read(appRouterProvider).go('/students');
                },
              ),
              const SizedBox(height: 4),
              _chip(
                label: 'Report',
                emoji: '📄',
                bg: const Color(0xFFD1FAE5),
                color: const Color(0xFF059669),
                onTap: () {
                  onNavigated();
                  // `AiStudentLookupResults` is mounted inside the AI
                  // assistant overlay, which sits *outside* the routed
                  // Navigator (siblings via `MaterialApp.router`'s
                  // `builder:`) — so `Navigator.of(context)` from here has
                  // no Navigator ancestor to find. Push through the
                  // GoRouter's own root navigator key instead.
                  final navState = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentState;
                  navState?.push<bool>(MaterialPageRoute(builder: (_) => StudentProfilePage(student: s)));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(({Color bg, Color ink}) p, String name) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(_initials(name), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
    );
  }

  Widget _chip({required String label, VoidCallback? onTap, IconData? icon, String? emoji, Color? bg, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg ?? aiPurpleSoft, borderRadius: BorderRadius.circular(7)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 9, color: color ?? aiPurple), const SizedBox(width: 4)],
            if (emoji != null) ...[Text(emoji, style: const TextStyle(fontSize: 10)), const SizedBox(width: 4)],
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color ?? aiPurple)),
          ],
        ),
      ),
    );
  }
}
