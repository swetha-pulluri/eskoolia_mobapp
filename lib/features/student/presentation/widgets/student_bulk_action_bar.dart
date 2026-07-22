import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bulk action bar shown when rows are checked — mirrors frontend
/// StudentListPanel.tsx's bulk-action bar: Activate / Deactivate /
/// Message parents (disabled) / Export selected / Archive / Clear.
class StudentBulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onExportSelected;
  final VoidCallback onArchive;
  final VoidCallback onClear;

  const StudentBulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onActivate,
    required this.onDeactivate,
    required this.onExportSelected,
    required this.onArchive,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.studentTagPurpleBg,
        border: Border(bottom: BorderSide(color: AppColors.studentListLine)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              '$selectedCount selected',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.studentTagPurpleText,
              ),
            ),
            const SizedBox(width: 12),
            _ActionChip(label: 'Activate', onTap: onActivate),
            const SizedBox(width: 6),
            _ActionChip(label: 'Deactivate', onTap: onDeactivate),
            const SizedBox(width: 6),
            _ActionChip(label: 'Message parents', onTap: null),
            const SizedBox(width: 6),
            _ActionChip(label: 'Export selected', onTap: onExportSelected),
            const SizedBox(width: 6),
            _ActionChip(label: 'Archive', onTap: onArchive, isDanger: true),
            const SizedBox(width: 6),
            _ActionChip(label: 'Clear', onTap: onClear),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isDanger;

  const _ActionChip({required this.label, required this.onTap, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isDanger ? const Color(0xFFFCA5A5) : AppColors.studentListLine,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDanger ? const Color(0xFFDC2626) : AppColors.studentListInk,
            ),
          ),
        ),
      ),
    );
  }
}
