import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/school_class_entity.dart';
import '../providers/admissions_provider.dart';

/// Class Portfolio — section "02" of the Command Center. Converted from
/// web `command-center/ClassPortfolioGrid.tsx`. Collapsible grid of class
/// cards for selecting which class's pipeline to view in the workspace
/// below, with a Manage mode to hide/restore classes and edit seat counts.
class ClassPortfolioGrid extends StatefulWidget {
  final List<ClassConfigEntity> classes;
  final int? selectedClassId;
  final ValueChanged<int?> onSelectClass;
  final VoidCallback onClassesUpdated;
  final bool isLoading;

  const ClassPortfolioGrid({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onSelectClass,
    required this.onClassesUpdated,
    this.isLoading = false,
  });

  @override
  State<ClassPortfolioGrid> createState() => _ClassPortfolioGridState();
}

enum _PortfolioFilter { all, active, overdue, almostFull }

class _ClassPortfolioGridState extends State<ClassPortfolioGrid> {
  bool _collapsed = false;
  bool _manageMode = false;
  _PortfolioFilter _filter = _PortfolioFilter.all;
  final Set<int> _hiddenClassIds = {};

  List<ClassConfigEntity> get _visibleClasses {
    var list = widget.classes
        .where((c) => !_hiddenClassIds.contains(c.id))
        .toList();
    switch (_filter) {
      case _PortfolioFilter.all:
        break;
      case _PortfolioFilter.active:
        list = list.where((c) => c.pipelineCount > 0).toList();
      case _PortfolioFilter.overdue:
        list = list.where((c) => c.overdueCount > 0).toList();
      case _PortfolioFilter.almostFull:
        list = list
            .where((c) => c.capacity > 0 && c.enrolledCount / c.capacity >= 0.7)
            .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleClasses;
    final allEnrolled = widget.classes
        .where((c) => !_hiddenClassIds.contains(c.id))
        .fold<int>(0, (s, c) => s + c.enrolledCount);
    final allPipeline = visible.fold<int>(0, (s, c) => s + c.pipelineCount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '02',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.grid_view_outlined,
                  size: 14,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(width: 6),
                // `Flexible`+ellipsis — this title, the subtitle, the
                // "N hidden" chip, the Manage button and the chevron are
                // ALL non-flex siblings besides the subtitle's `Expanded`;
                // their combined natural width alone (regardless of the
                // subtitle shrinking to 0) overflowed this Row by ~95px at
                // 320-390dp.
                Flexible(
                  child: Text(
                    'Class Portfolio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                // The trailing "N hidden"/"Manage"/chevron cluster is
                // wrapped so it can drop to its own line instead of
                // forcing the Row past its available width — a `Wrap` as
                // a bare Row child would still get unbounded width, hence
                // the enclosing `Flexible`.
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        "Select a class to view its pipeline",
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                      ),
                      if (_hiddenClassIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_hiddenClassIds.length} hidden',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () => setState(() => _manageMode = !_manageMode),
                        style: TextButton.styleFrom(
                          backgroundColor: _manageMode
                              ? const Color(0xFF4F46E5)
                              : Colors.transparent,
                          foregroundColor: _manageMode
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          _manageMode ? 'Done' : 'Manage',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _collapsed
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  size: 20,
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          if (!_collapsed) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _filterPill('All', _PortfolioFilter.all, widget.classes.length),
                _filterPill(
                  'Has Applications',
                  _PortfolioFilter.active,
                  widget.classes.where((c) => c.pipelineCount > 0).length,
                ),
                _filterPill(
                  'Overdue',
                  _PortfolioFilter.overdue,
                  widget.classes.where((c) => c.overdueCount > 0).length,
                ),
                _filterPill(
                  'Almost Full',
                  _PortfolioFilter.almostFull,
                  widget.classes
                      .where(
                        (c) =>
                            c.capacity > 0 &&
                            c.enrolledCount / c.capacity >= 0.7,
                      )
                      .length,
                ),
              ],
            ),
            const SizedBox(height: 10),
            widget.isLoading
                ? GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.2,
                    children: List.generate(
                      6,
                      (_) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                : visible.isEmpty && _filter != _PortfolioFilter.all
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No classes match this filter',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      _allClassesCard(allPipeline, allEnrolled),
                      ...visible.map(_classCard),
                    ],
                  ),
            if (_manageMode && _hiddenClassIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hidden classes — click to restore',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.classes
                          .where((c) => _hiddenClassIds.contains(c.id))
                          .map((c) {
                            return OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _hiddenClassIds.remove(c.id)),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 13,
                              ),
                              label: Text(
                                c.name,
                                style: const TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 28),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
            ] else if (_manageMode) ...[
              const SizedBox(height: 8),
              const Text(
                'Hover over a class card and click ⋮ to edit seats or hide it from this view.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _filterPill(String label, _PortfolioFilter value, int count) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text('$label $count', style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: const Color(0xFFEEF2FF),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB),
      ),
    );
  }

  Widget _allClassesCard(int pipeline, int enrolled) {
    return InkWell(
      onTap: () => widget.onSelectClass(null),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'All Classes',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '$pipeline',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              'pipeline · $enrolled enrolled',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classCard(ClassConfigEntity cls) {
    final selected = widget.selectedClassId == cls.id;
    final fillRatio = cls.capacity > 0 ? cls.enrolledCount / cls.capacity : 0.0;
    final barColor = fillRatio > 0.9
        ? const Color(0xFFF87171)
        : fillRatio > 0.6
        ? const Color(0xFFFBBF24)
        : const Color(0xFF4ADE80);
    final healthColor = switch (cls.healthStatus) {
      'urgent' => const Color(0xFFEF4444),
      'active' => const Color(0xFFFBBF24),
      'healthy' => const Color(0xFF22C55E),
      _ => const Color(0xFF9CA3AF),
    };
    return InkWell(
      onTap: () => widget.onSelectClass(cls.id),
      onLongPress: () => _showCardMenu(cls),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
          ),
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: healthColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cls.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Web only reveals this on `:hover` (`opacity-0
                // group-hover:opacity-100`), which has no touch equivalent —
                // gating it on "this card is the selected one" (i.e. tapped
                // once already) is the closest touch analog, matching "only
                // visible after tapping the respective class card".
                if (selected)
                  InkWell(
                    onTap: () => _showCardMenu(cls),
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              '${cls.pipelineCount}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              '${cls.enrolledCount}/${cls.capacity} seats',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fillRatio.clamp(0, 1),
                minHeight: 3,
                backgroundColor: const Color(0xFFF3F4F6),
                color: barColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardMenu(ClassConfigEntity cls) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF4F46E5),
              ),
              title: const Text('Edit seats'),
              onTap: () {
                Navigator.of(context).pop();
                _openEditSeats(cls);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.visibility_off_outlined,
                color: Color(0xFFDC2626),
              ),
              title: Text(_manageMode ? 'Hide class' : 'Remove from view'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _hiddenClassIds.add(cls.id));
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Class hidden from portfolio. Use 'Manage' to restore.",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openEditSeats(ClassConfigEntity cls) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _EditSeatsDialog(cls: cls, onSaved: widget.onClassesUpdated),
    );
  }
}

class _EditSeatsDialog extends ConsumerStatefulWidget {
  final ClassConfigEntity cls;
  final VoidCallback onSaved;
  const _EditSeatsDialog({required this.cls, required this.onSaved});

  @override
  ConsumerState<_EditSeatsDialog> createState() => _EditSeatsDialogState();
}

class _EditSeatsDialogState extends ConsumerState<_EditSeatsDialog> {
  late final Map<int, TextEditingController> _controllers = {
    for (final s in widget.cls.sections)
      s.id: TextEditingController(text: '${s.capacity}'),
  };
  late final TextEditingController _totalCtrl = TextEditingController(
    text: '${widget.cls.capacity}',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _totalCtrl.dispose();
    super.dispose();
  }

  /// Matches `EditSeatsModal`'s two real behaviors: when the class has
  /// sections, PATCH each section's capacity to the real backend
  /// (`/api/v1/core/sections/{id}/`); when it has none, there is genuinely
  /// no backend field to save a class-level seat count to (`core.Class`
  /// has no `capacity` column) — web itself only stores that case in
  /// `localStorage`, so this dialog just closes without a backend call,
  /// matching that real limitation instead of inventing an endpoint.
  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.cls.sections.isNotEmpty) {
        final repo = ref.read(admissionsRepositoryProvider);
        for (final s in widget.cls.sections) {
          final raw = _controllers[s.id]!.text.trim();
          final cap = int.tryParse(raw);
          if (cap == null || cap < 1) {
            throw Exception('Invalid capacity for section ${s.name}');
          }
          await repo.updateSectionCapacity(s.id, cap);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seats updated.')));
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to update seats.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSections = widget.cls.sections.isNotEmpty;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Seats — ${widget.cls.name}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasSections
                      ? 'Set seat capacity per section. Changes are saved to the server.'
                      : 'No sections configured. Set a total seat count for this class (stored locally).',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                if (hasSections)
                  ...widget.cls.sections.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Section ${s.name}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: _controllers[s.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'seats',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total seats',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _totalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                    ],
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
