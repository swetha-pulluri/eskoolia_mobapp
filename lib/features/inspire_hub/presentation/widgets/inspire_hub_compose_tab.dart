import 'package:flutter/material.dart';

import '../../../student/domain/models/student_group.dart';
import 'inspire_hub_competition_form.dart';

/// Compose tab — step one only: fill in the competition's details and save.
/// On success InspireHubPage pushes InspireHubResultsPage (a dedicated
/// screen, not more of this tab) to add participants, mark positions, and
/// generate reviews — matching how the rest of the app moves from a
/// "create" form to its own detail screen rather than growing the same
/// page taller.
class InspireHubComposeTab extends StatelessWidget {
  final List<StudentGroup> houses;
  final List<GroupStudentRow> allStudents;
  final Future<void> Function(Map<String, dynamic> formValues) onSubmit;

  const InspireHubComposeTab({
    super.key,
    required this.houses,
    required this.allStudents,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        CompetitionFormCard(editing: null, houses: houses, allStudents: allStudents, onSubmit: onSubmit),
        const SizedBox(height: 16),
        const _EmptyHero(),
      ],
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const [
          Text('✨', style: TextStyle(fontSize: 28)),
          SizedBox(height: 8),
          Text('Begin a new competition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          SizedBox(height: 4),
          Text(
            "Fill in the details and save — you'll move straight to adding participants and marking results. Past events live in the History tab.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
