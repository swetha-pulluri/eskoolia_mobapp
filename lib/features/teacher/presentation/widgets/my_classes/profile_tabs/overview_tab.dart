import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/student_profile_entity.dart';

/// Mirrors `OverviewTab` in `StudentProfileDrawer.tsx` — always available.
class OverviewTab extends StatelessWidget {
  final StudentOverviewEntity overview;
  const OverviewTab({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final hasGuardian = overview.guardianName.isNotEmpty || overview.guardianPhone.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('PERSONAL INFORMATION'),
        const SizedBox(height: 12),
        _infoRow('Full Name', overview.name),
        _infoRow('Roll No.', overview.rollNo),
        _infoRow('Admission', overview.admissionNo),
        _infoRow('Gender', overview.gender),
        _infoRow('Date of Birth', overview.dateOfBirth),
        _infoRow('Blood Group', overview.bloodGroup),
        _infoRow('Phone', overview.phone),
        _infoRow('Email', overview.email),
        if (hasGuardian) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _sectionTitle('GUARDIAN'),
          const SizedBox(height: 12),
          _infoRow('Name', overview.guardianName),
          _infoRow('Relation', overview.guardianRelation),
          _infoRow('Phone', overview.guardianPhone),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2));

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink2)),
          ),
          Expanded(
            child: Text((value == null || value.isEmpty) ? '—' : value, style: const TextStyle(fontSize: 13, color: AppColors.ink1)),
          ),
        ],
      ),
    );
  }
}
