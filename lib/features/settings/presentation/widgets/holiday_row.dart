import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/holiday_entity.dart';

final _dateFormat = DateFormat('d MMM y');

/// Mirrors `HolidaysPanel.tsx`'s `formatRange()` — a single date, or a
/// "start → end" range when the holiday spans multiple days. Dates are
/// reformatted from ISO to `d MMM y` for readability (the web shows the raw
/// ISO string as-is; this screen already reformats dates for the wizard's
/// date-picker fields, so the list rows stay consistent with that).
String formatHolidayRange(String date, String? endDate) {
  String fmt(String iso) {
    final parsed = DateTime.tryParse(iso);
    return parsed != null ? _dateFormat.format(parsed) : iso;
  }

  if (endDate != null && endDate.isNotEmpty && endDate != date) {
    return '${fmt(date)} → ${fmt(endDate)}';
  }
  return fmt(date);
}

/// A "Icon" + name + date-range row with an "Exclude/Include for staff"
/// toggle — mirrors the School-wide holidays section's row markup.
class SchoolWideHolidayRow extends StatelessWidget {
  final HolidayEntity holiday;
  final bool excluded;
  final bool busy;
  final VoidCallback onToggle;

  const SchoolWideHolidayRow({
    super.key,
    required this.holiday,
    required this.excluded,
    required this.busy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: excluded ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 2,
                children: [
                  Text(holiday.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(formatHolidayRange(holiday.date, holiday.endDate), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (excluded)
                    const Text('Excluded for staff', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dangerRed)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ToggleButton(excluded: excluded, busy: busy, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool excluded;
  final bool busy;
  final VoidCallback onTap;

  const _ToggleButton({required this.excluded, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = excluded ? AppColors.successGreen : AppColors.dangerRed;
    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            border: Border.all(color: AppColors.borderSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(excluded ? Icons.check_circle : Icons.shield_outlined, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                busy ? '…' : (excluded ? 'Include for staff' : 'Exclude for staff'),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A staff-only holiday card — accent bar + name + "Restricted" badge +
/// date range + Edit/Delete — mirrors the Staff-only holidays section's
/// card markup.
class StaffOnlyHolidayCard extends StatelessWidget {
  final HolidayEntity holiday;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StaffOnlyHolidayCard({
    super.key,
    required this.holiday,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Positioned(left: 0, top: 0, bottom: 0, width: 3, child: ColoredBox(color: AppColors.purpleAccent)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.event_note_outlined, size: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 7,
                        runSpacing: 4,
                        children: [
                          Text(holiday.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          if (holiday.isOptional)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(999)),
                              child: const Text('Restricted', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.warningAmber)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(formatHolidayRange(holiday.date, holiday.endDate), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    _IconButton(icon: Icons.edit_outlined, color: AppColors.purpleAccent, onTap: onEdit),
                    const SizedBox(width: 6),
                    _IconButton(icon: Icons.delete_outline, color: AppColors.dangerRed, disabled: busy, onTap: onDelete),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.color, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
