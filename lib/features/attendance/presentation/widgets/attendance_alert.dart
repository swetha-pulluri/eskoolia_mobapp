import 'package:flutter/material.dart';

/// Attendance Alert — converted from web
/// `attendance/student/components/AttendanceAlert.tsx`.
class AttendanceAlert extends StatelessWidget {
  final int count;
  const AttendanceAlert({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFFFF4E5), border: Border.all(color: const Color(0xFFF5A623)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF5A623)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count student${count > 1 ? "s are" : " is"} at risk of missing RTE attendance threshold.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8B5E08), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
