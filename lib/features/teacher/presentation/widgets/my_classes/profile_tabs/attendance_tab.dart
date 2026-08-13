import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/student_profile_entity.dart';

const Map<String, (Color, Color)> _statusStyle = {
  'P': (Color(0xFFF0FDF4), Color(0xFF15803D)),
  'A': (Color(0xFFFEF2F2), Color(0xFFB91C1C)),
  'L': (Color(0xFFFFFBEB), Color(0xFFB45309)),
  'F': (Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
  'H': (Color(0xFFF5F5FB), AppColors.ink2),
};

/// Mirrors `AttendanceTab` in `StudentProfileDrawer.tsx` — summary strip +
/// "Last 90 Days" list, read-only (the permission gates web mentions in
/// its header comment for this tab are not actually implemented there
/// either — see plan notes).
class AttendanceTab extends StatelessWidget {
  final List<AttendanceRecordEntity>? records;
  final AttendanceSummaryEntity? summary;
  const AttendanceTab({super.key, required this.records, required this.summary});

  @override
  Widget build(BuildContext context) {
    final rows = records ?? const [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (summary != null) ...[
          Row(
            children: [
              Expanded(child: _statTile('Present', summary!.present.toString(), const Color(0xFF15803D))),
              const SizedBox(width: 8),
              Expanded(child: _statTile('Absent', summary!.absent.toString(), const Color(0xFFB91C1C))),
              const SizedBox(width: 8),
              Expanded(child: _statTile('Late', summary!.late.toString(), const Color(0xFFB45309))),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  '% Attend',
                  summary!.attendancePct != null ? '${summary!.attendancePct!.toStringAsFixed(0)}%' : '—',
                  AppColors.ink1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const Text('LAST 90 DAYS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No attendance records in the last 90 days.', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
            ),
          )
        else
          for (final r in rows) _recordRow(r),
      ],
    );
  }

  Widget _statTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppColors.ink3)),
        ],
      ),
    );
  }

  Widget _recordRow(AttendanceRecordEntity r) {
    final (bg, fg) = _statusStyle[r.status] ?? (const Color(0xFFF5F5FB), AppColors.ink2);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(r.date, style: const TextStyle(fontSize: 12, color: AppColors.ink2))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(r.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
          ),
          if (r.notes.isNotEmpty) ...[
            const SizedBox(width: 10),
            Expanded(child: Text(r.notes, style: const TextStyle(fontSize: 11, color: AppColors.ink3))),
          ],
        ],
      ),
    );
  }
}
