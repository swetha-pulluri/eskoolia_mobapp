import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';

const Color _brandPurple = Color(0xFF6D4AFF);

/// Inline sibling switcher — shared by every Parent page that shows one
/// child's data at a time (My Children, Attendance Calendar, …). Mirrors
/// web's own repeated inline "child tabs" block (identical on both
/// `parent/children/page.tsx` and `parent/attendance/page.tsx`) as one
/// widget instead of copy-pasting it per page. Only rendered by callers
/// when there's more than one child, matching web's `children.length > 1` guard.
class SiblingTabs extends ConsumerWidget {
  final List<ChildSummaryEntity> children;
  final int? selectedId;
  const SiblingTabs({super.key, required this.children, required this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = children[i];
          final isSelected = c.id == selectedId;
          final initials = c.name.split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
          return InkWell(
            onTap: () => ref.read(selectedChildIdProvider.notifier).select(c.id),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? _brandPurple : AppColors.border, width: 1.4),
                color: isSelected ? const Color(0xFFEEEAFF) : Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: (c.photoUrl != null && c.photoUrl!.isNotEmpty) ? NetworkImage(c.photoUrl!) : null,
                    backgroundColor: isSelected ? _brandPurple : const Color(0xFFEEEAFF),
                    child: (c.photoUrl == null || c.photoUrl!.isEmpty)
                        ? Text(initials, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : _brandPurple))
                        : null,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    c.name.split(' ').first,
                    style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? _brandPurple : AppColors.ink2),
                  ),
                  if (c.className.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Text(c.className, style: TextStyle(fontSize: 11, color: (isSelected ? _brandPurple : AppColors.ink2).withValues(alpha: 0.7))),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
