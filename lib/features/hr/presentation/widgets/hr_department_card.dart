import 'package:flutter/material.dart';
import '../../domain/entities/department_entity.dart';
import 'hr_theme.dart';

/// Expand/collapse department row — Name, Active/Inactive badge (only
/// `is_active` exists on the real backend, so no 3-state Active/Inactive/
/// Archived), Description, designation count and staff count (both real,
/// client-computed from the designations/staff lists — the backend's
/// `DepartmentSerializer` has no such fields), Edit/Delete. No "Attendance
/// today" tile — that field doesn't exist on any backend either, and unlike
/// the counts above there is no equivalent real data to compute it from.
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    // Was: Column(header-info) sitting inside this Expanded,
                    // with "N staff" + Edit + Delete as separate FIXED-width
                    // siblings of this Expanded directly in the outer Row.
                    // Those fixed siblings' combined intrinsic width (badge +
                    // staff text + 2 buttons) alone exceeds the Row's
                    // available width at 320-412dp regardless of what the
                    // Expanded gets, causing a hard `RenderFlex overflowed`
                    // (confirmed via widget test with a long department
                    // name). Folding "N staff"/Edit/Delete into this Wrap —
                    // which is already bounded by the Expanded — lets them
                    // wrap onto their own line instead of overflowing.
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
                        ]),
                        const SizedBox(height: 4),
                        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
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
