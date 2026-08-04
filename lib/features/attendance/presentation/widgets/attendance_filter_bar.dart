import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entities.dart';

const List<String> kAcademicYears = ['2026-27', '2025-26', '2024-25', '2023-24'];
const List<Map<String, String>> kLevels = [
  {'value': 'all', 'label': 'All'},
  {'value': 'primary', 'label': 'Primary'},
  {'value': 'middle', 'label': 'Middle'},
  {'value': 'secondary', 'label': 'Secondary'},
];

/// Attendance Filter Bar — converted from web
/// `attendance/student/components/AttendanceFilterBar.tsx`.
class AttendanceFilterBar extends StatelessWidget {
  final String academicYear;
  final LevelFilter levelFilter;
  final ValueChanged<String> onYearChange;
  final ValueChanged<LevelFilter> onLevelChange;

  const AttendanceFilterBar({super.key, required this.academicYear, required this.levelFilter, required this.onYearChange, required this.onLevelChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // Flattened directly into the outer `Wrap` (not grouped into a
          // `mainAxisSize.min` Row) so the label and the dropdown can each
          // land on their own line on a narrow phone — the combined Row's
          // intrinsic width (label + `DropdownButton`'s own generous item
          // padding) genuinely exceeded 320-360dp screens.
          const Text('Academic Year', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B6B80))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8), color: Colors.white),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: academicYear,
                isDense: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                items: kAcademicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) {
                  if (v != null) onYearChange(v);
                },
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            children: kLevels.map((l) {
              final isActive = levelFilter == l['value'];
              return GestureDetector(
                onTap: () => onLevelChange(l['value']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF4729F4) : Colors.white,
                    border: isActive ? null : Border.all(color: const Color(0xFFE6E6EC)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(l['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFF6B6B80))),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
