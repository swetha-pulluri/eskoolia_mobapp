import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/attendance_policy_entity.dart';

const List<String> _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const List<String> _fullNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Read-only 7-square weekly-off preview shown on each policy card — mirrors
/// `WeekStrip` in `AttendanceRulesPanel.tsx` (22×22 squares, filled
/// purple/white when that day is off, outlined grey otherwise).
class AttendanceWeekStrip extends StatelessWidget {
  final AttendancePolicyEntity policy;

  const AttendanceWeekStrip({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    final offs = [
      policy.weeklyOffMon,
      policy.weeklyOffTue,
      policy.weeklyOffWed,
      policy.weeklyOffThu,
      policy.weeklyOffFri,
      policy.weeklyOffSat,
      policy.weeklyOffSun,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 7; i++) ...[
          Tooltip(
            message: '${_fullNames[i]} — ${offs[i] ? 'weekly off' : 'working day'}',
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: offs[i] ? AppColors.purpleAccent : AppColors.bgPrimary,
                border: offs[i] ? null : Border.all(color: AppColors.borderSecondary),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _letters[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: offs[i] ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ),
          ),
          if (i != 6) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
