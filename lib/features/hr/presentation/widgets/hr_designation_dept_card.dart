import 'package:flutter/material.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/designation_entity.dart';
import 'hr_theme.dart';

/// Expandable department header with its designations listed underneath.
/// No reorder (↑/↓) controls or role-template badge — the real backend has
/// no `sort_order` field and no `designations/reorder/` endpoint.
class HrDesignationDeptCard extends StatefulWidget {
  final DepartmentEntity dept;
  final List<DesignationEntity> deptDesigs;
  final VoidCallback onAddChild;
  final void Function(DesignationEntity) onEdit;
  final void Function(int id) onDelete;

  const HrDesignationDeptCard({
    super.key,
    required this.dept,
    required this.deptDesigs,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<HrDesignationDeptCard> createState() => _HrDesignationDeptCardState();
}

class _HrDesignationDeptCardState extends State<HrDesignationDeptCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final activeCount = widget.deptDesigs.where((d) => d.isActive).length;
    final inactiveCount = widget.deptDesigs.where((d) => !d.isActive).length;

    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E8F0)), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              decoration: const BoxDecoration(border: Border(left: BorderSide(color: HrColors.brand, width: 3))),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Isolated in its own `Expanded` — same reasoning as the
                  // Department card fix: the name+badges `Wrap` only ever
                  // grows/wraps within this column, so it can never push the
                  // "Add"/chevron group (fixed Row siblings right after this
                  // Expanded) out of its consistent, right-aligned position.
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(widget.dept.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: HrColors.ink)),
                        HrBadge(variant: HrBadgeVariant.purple, label: '${widget.deptDesigs.length} designation${widget.deptDesigs.length != 1 ? 's' : ''}'),
                        if (activeCount > 0) HrBadge(variant: HrBadgeVariant.green, label: '$activeCount active'),
                        if (inactiveCount > 0) HrBadge(variant: HrBadgeVariant.grey, label: '$inactiveCount inactive'),
                        if (widget.deptDesigs.isEmpty) const HrBadge(variant: HrBadgeVariant.grey, label: 'no designations'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onAddChild,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: HrColors.brand, borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
              child: widget.deptDesigs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Wrap(alignment: WrapAlignment.center, children: [
                          const Text('No designations yet. ', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                          GestureDetector(
                            onTap: widget.onAddChild,
                            child: const Text('Add the first one', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HrColors.brand)),
                          ),
                        ]),
                      ),
                    )
                  : Column(
                      children: [
                        for (var idx = 0; idx < widget.deptDesigs.length; idx++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: idx < widget.deptDesigs.length - 1 ? const BorderSide(color: Color(0xFFF8F8FC)) : BorderSide.none)),
                            child: Row(
                              children: [
                                Expanded(child: Text(widget.deptDesigs[idx].name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HrColors.ink))),
                                const SizedBox(width: 12),
                                // `Flexible` — the badge + Edit + Delete
                                // cluster's combined natural width can still
                                // slightly exceed what's left after a long
                                // designation name at 320dp even with the
                                // name `Expanded`; this lets the cluster
                                // itself shrink/wrap rather than overflow.
                                Flexible(
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: [
                                      HrBadge(variant: widget.deptDesigs[idx].isActive ? HrBadgeVariant.green : HrBadgeVariant.grey, label: widget.deptDesigs[idx].isActive ? 'Active' : 'Inactive'),
                                      TextButton(
                                        onPressed: () => widget.onEdit(widget.deptDesigs[idx]),
                                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                        child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                      ),
                                      TextButton(
                                        onPressed: () => widget.onDelete(widget.deptDesigs[idx].id),
                                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                        child: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HrColors.red)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
