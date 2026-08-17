import 'package:flutter/material.dart';
import '../../domain/entities/department_entity.dart';
import 'hr_theme.dart';

/// Expand/collapse department row — Name, Active/Inactive badge (only
/// `is_active` exists on the real backend, so no 3-state Active/Inactive/
/// Archived), Description, designation count and staff count (both real,
/// client-computed from the designations/staff lists — the backend's
/// `DepartmentSerializer` has no such fields), Edit/Delete. The expanded
/// panel's "Attendance today" tile always reads "--%" — `attendance_pct`
/// doesn't exist on the real backend response, so web's own fallback for
/// this tile is the same static placeholder, never a real number.
class HrDepartmentCard extends StatefulWidget {
  final DepartmentEntity dept;
  final int designationCount;
  final int staffCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HrDepartmentCard({
    super.key,
    required this.dept,
    required this.designationCount,
    required this.staffCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<HrDepartmentCard> createState() => _HrDepartmentCardState();
}

class _HrDepartmentCardState extends State<HrDepartmentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dept = widget.dept;
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E8F0)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: HrColors.brand, width: 4))),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 12),
                  // Matches web's `DeptCard`: name/badge/meta live in their
                  // own `flex-1 min-w-0` column, and "N staff"/Edit/Delete
                  // sit in a SEPARATE, fixed-position column pinned to the
                  // right — never inside the same Wrap as the name. Folding
                  // everything into one Wrap (the previous approach) let a
                  // long department name/description push Edit/Delete to a
                  // different horizontal spot — or even a different line —
                  // on every card, which is what read as misaligned.
                  // `Expanded` (not a plain Row sibling) is what makes both
                  // columns overflow-safe: each gets a fixed share of the
                  // row's width up front, so the right column's own `Wrap`
                  // only ever needs to shrink/wrap *within that share*
                  // rather than the whole Row overflowing regardless of the
                  // Expanded name column (the exact failure a widget test
                  // caught previously with a long department name).
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
                          Text(dept.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: HrColors.ink)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: dept.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              dept.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: dept.isActive ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
                          Text('${widget.designationCount} designations', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: HrColors.brand)),
                          if (dept.description.isNotEmpty) ...[
                            const Text('|', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(dept.description, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (widget.staffCount > 0)
                          Text('${widget.staffCount} staff', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                        TextButton(
                          onPressed: widget.onEdit,
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        ),
                        TextButton(
                          onPressed: widget.onDelete,
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HrColors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9))), color: Color(0xFFFAFAFA)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: _statTile(widget.staffCount > 0 ? '${widget.staffCount}' : '--', 'Assigned staff')),
                  Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
                  Expanded(child: _statTile(widget.designationCount > 0 ? '${widget.designationCount}' : '--', 'Designation levels')),
                  Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
                  // Web's own `DeptCard` shows this same static "--%" — its
                  // `attendance_pct` field doesn't exist on the real backend
                  // response either, so web's fallback is exactly this
                  // placeholder, never a real computed number. Rendering the
                  // identical placeholder here isn't fabricating data — it's
                  // matching what the real deployed page actually displays.
                  Expanded(child: _statTile('--%', 'Attendance today')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: HrColors.ink, height: 1)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      ],
    );
  }
}
