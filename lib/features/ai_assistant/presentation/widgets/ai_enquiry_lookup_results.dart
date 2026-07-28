import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../admissions/domain/entities/inquiry_entity.dart';
import 'ai_assistant_colors.dart';

const _pastel = [
  (bg: Color(0xFFEEEAFF), ink: Color(0xFF6D4AFF)),
  (bg: Color(0xFFFEE2E2), ink: Color(0xFFE0463A)),
  (bg: Color(0xFFD1FAE5), ink: Color(0xFF059669)),
  (bg: Color(0xFFFEF3C7), ink: Color(0xFFD97706)),
  (bg: Color(0xFFDBEAFE), ink: Color(0xFF3B82F6)),
  (bg: Color(0xFFFCE7F3), ink: Color(0xFFDB2777)),
];

const _statusConfig = {
  'new': (label: 'New', bg: Color(0xFFDBEAFE), ink: Color(0xFF1D4ED8)),
  'contacted': (label: 'Contacted', bg: Color(0xFFFEF3C7), ink: Color(0xFFD97706)),
  'visited': (label: 'Visited', bg: Color(0xFFEDE9FE), ink: Color(0xFF7C3AED)),
  'applied': (label: 'Applied', bg: Color(0xFFD1FAE5), ink: Color(0xFF059669)),
  'enrolled': (label: 'Enrolled', bg: Color(0xFFDCFCE7), ink: Color(0xFF16A34A)),
  'waitlisted': (label: 'Waitlist', bg: Color(0xFFFEF9C3), ink: Color(0xFFA16207)),
  'cold': (label: 'Cold', bg: Color(0xFFF3F4F6), ink: Color(0xFF6B7280)),
};

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words[0][0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

String _fmtDate(String? date) {
  if (date == null || date.isEmpty) return '—';
  final d = DateTime.tryParse(date);
  if (d == null) return '—';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Mirrors frontend components/aibot/EnquiryLookupResults.tsx. Reuses the
/// app's real [InquiryEntity] (from admissionsRepositoryProvider.getInquiries(),
/// client-side filtered) rather than the frontend's own hardcoded
/// MOCK_ENQUIRIES sample data. Per explicit instruction, both "View" and
/// "Report" navigate to the app's real Admissions Command Center screen
/// instead of rebuilding the frontend's separate EnquiryProfilePopup.
class AiEnquiryLookupResults extends ConsumerWidget {
  final List<InquiryEntity> enquiries;
  final String query;
  final VoidCallback onNavigated;

  const AiEnquiryLookupResults({super.key, required this.enquiries, required this.query, required this.onNavigated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (enquiries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text('No enquiries found for "$query"', style: const TextStyle(fontSize: 12.5, color: aiInk2)),
            const SizedBox(height: 3),
            const Text('Try a parent name, student name or phone number', style: TextStyle(fontSize: 11, color: aiInk3)),
            const SizedBox(height: 8),
            _chip(
              label: 'Open Admissions →',
              onTap: () {
                onNavigated();
                ref.read(appRouterProvider).go('/admissions/command-center');
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
                TextSpan(text: '${enquiries.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' enquir${enquiries.length > 1 ? 'ies' : 'y'} matching "$query"'),
              ],
            ),
          ),
        ),
        for (var i = 0; i < enquiries.length; i++) ...[_enquiryCard(ref, enquiries[i], i), const SizedBox(height: 6)],
        Center(
          child: TextButton(
            onPressed: () {
              onNavigated();
              ref.read(appRouterProvider).go('/admissions/command-center');
            },
            style: TextButton.styleFrom(foregroundColor: aiPurple, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Open full admissions →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _enquiryCard(WidgetRef ref, InquiryEntity e, int i) {
    final p = _pastel[i % _pastel.length];
    final sc = _statusConfig[e.status] ?? _statusConfig['new']!;
    final score = e.leadScore;
    final scoreColor = score >= 75 ? const Color(0xFF16A34A) : (score >= 50 ? const Color(0xFFD97706) : const Color(0xFFDC2626));
    final classApplied = e.classNameResolved?.isNotEmpty == true ? e.classNameResolved! : 'Not specified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(10), color: aiBg0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Text(_initials(e.fullName), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.ink)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  runSpacing: 3,
                  children: [
                    Text(e.fullName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: aiInk1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: sc.bg, borderRadius: BorderRadius.circular(10)),
                      child: Text(sc.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc.ink)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('🎓 $classApplied  ·  👤 ${e.assigned.isNotEmpty ? e.assigned : '—'}', style: const TextStyle(fontSize: 11, color: aiInk2)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 9, color: aiInk3),
                      const SizedBox(width: 3),
                      Text(e.phone, style: const TextStyle(fontSize: 10.5, color: aiInk3)),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today, size: 9, color: aiInk3),
                      const SizedBox(width: 3),
                      Text(_fmtDate(e.queryDate), style: const TextStyle(fontSize: 10.5, color: aiInk3)),
                      const SizedBox(width: 10),
                      Icon(Icons.star, size: 9, color: scoreColor),
                      const SizedBox(width: 3),
                      Text('$score', style: TextStyle(fontSize: 10.5, color: scoreColor, fontWeight: FontWeight.w600)),
                    ],
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
                label: 'View',
                icon: Icons.open_in_new,
                onTap: () {
                  onNavigated();
                  ref.read(appRouterProvider).go('/admissions/command-center');
                },
              ),
              const SizedBox(height: 4),
              _chip(
                label: 'Report',
                emoji: '📋',
                bg: const Color(0xFFD1FAE5),
                color: const Color(0xFF059669),
                onTap: () {
                  onNavigated();
                  ref.read(appRouterProvider).go('/admissions/command-center');
                },
              ),
            ],
          ),
        ],
      ),
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
