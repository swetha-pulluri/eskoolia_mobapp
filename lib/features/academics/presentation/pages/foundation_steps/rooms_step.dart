import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/class_entity.dart';
import '../../../domain/entities/room_entity.dart';
import '../../../domain/entities/section_entity.dart';
import '../../providers/academics_providers.dart';
import '../../widgets/foundation_widgets.dart';

String? _validateRoomNo(String raw) {
  final v = raw.trim().toUpperCase();
  if (v.isEmpty) return null;
  if (v.length > 10) return 'Room number must be 10 characters or less.';
  if (!RegExp(r'^[A-Z0-9][A-Z0-9\- ]{0,9}$').hasMatch(v)) return 'Room number can use letters, numbers, spaces and hyphens only.';
  final stripped = v.replaceAll(RegExp(r'[-\s]'), '');
  if (stripped.length >= 2 && RegExp(r'^(.)\1+$').hasMatch(stripped)) {
    return "Please don't use the same character repeated — enter a real room number like 101 or A-12.";
  }
  return null;
}

/// Step 5 — port of RoomsPane.tsx.
class RoomsStep extends ConsumerStatefulWidget {
  final List<FoundationClass> classes;
  final List<FoundationRoom> rooms;
  final Future<void> Function() onRefresh;
  final void Function(String message, {bool error}) showToast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const RoomsStep({super.key, required this.classes, required this.rooms, required this.onRefresh, required this.showToast, required this.onBack, required this.onNext});

  @override
  ConsumerState<RoomsStep> createState() => _RoomsStepState();
}

class _RoomsStepState extends ConsumerState<RoomsStep> {
  final _roomNoController = TextEditingController();
  final _floorController = TextEditingController();
  String _capacity = '35';
  int? _classId;
  int? _sectionId;

  int? _editingId;
  bool _saving = false;
  String _error = '';
  int? _deletingId;
  int? _togglingId;
  FoundationRoom? _pendingDelete;
  int _page = 0;
  static const _perPage = 5;
  final GlobalKey _deleteConfirmKey = GlobalKey();

  void _scrollToDeleteConfirm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _deleteConfirmKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.1);
      }
    });
  }

  @override
  void dispose() {
    _roomNoController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  List<FoundationClass> get _availableClasses => widget.classes.where((c) => c.sections.isNotEmpty).toList();
  List<FoundationSection> get _filteredSections => _classId == null ? const [] : (widget.classes.where((c) => c.id == _classId).firstOrNull?.sections ?? const []);

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _roomNoController.clear();
      _floorController.clear();
      _capacity = '35';
      _classId = null;
      _sectionId = null;
      _error = '';
    });
  }

  void _openEdit(FoundationRoom r) {
    int? classId;
    if (r.sectionId != null) {
      for (final c in widget.classes) {
        if (c.sections.any((s) => s.id == r.sectionId)) {
          classId = c.id;
          break;
        }
      }
    }
    setState(() {
      _editingId = r.id;
      _roomNoController.text = r.roomNo;
      _floorController.text = r.floor;
      _capacity = '${r.capacity}';
      _classId = classId;
      _sectionId = r.sectionId;
      _error = '';
    });
  }

  Future<void> _save() async {
    final roomNo = _roomNoController.text.trim().toUpperCase();
    if (roomNo.isEmpty) {
      setState(() => _error = 'Room number is required.');
      return;
    }
    final roomErr = _validateRoomNo(roomNo);
    if (roomErr != null) {
      setState(() => _error = roomErr);
      return;
    }
    final capacity = int.tryParse(_capacity);
    if (capacity == null || capacity <= 0) {
      setState(() => _error = 'Capacity must be a positive number.');
      return;
    }
    if (capacity > 200) {
      setState(() => _error = 'Capacity must not exceed 200.');
      return;
    }
    if (_floorController.text.trim().length > 64) {
      setState(() => _error = 'Floor / Block must be 64 characters or less.');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final repo = ref.read(academicsRepositoryProvider);
      if (_editingId != null) {
        await repo.updateRoom(_editingId!, roomNo: roomNo, floor: _floorController.text.trim(), capacity: capacity, sectionId: _sectionId);
        widget.showToast('Room "$roomNo" updated.');
      } else {
        await repo.createRoom(roomNo: roomNo, floor: _floorController.text.trim(), capacity: capacity, sectionId: _sectionId);
        widget.showToast('Room "$roomNo" added.');
      }
      _cancelEdit();
      await widget.onRefresh();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (RegExp(r'already exists', caseSensitive: false).hasMatch(msg)) await widget.onRefresh();
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final r = _pendingDelete;
    if (r == null) return;
    setState(() => _deletingId = r.id);
    try {
      await ref.read(academicsRepositoryProvider).deleteRoom(r.id);
      widget.showToast('Room "${r.roomNo}" removed.');
      setState(() => _pendingDelete = null);
      await widget.onRefresh();
    } catch (e) {
      final msg = e.toString();
      if (RegExp(r'\b404\b|not.?found', caseSensitive: false).hasMatch(msg)) {
        widget.showToast('This room no longer exists. Refreshing the list…', error: true);
        setState(() => _pendingDelete = null);
        await widget.onRefresh();
      } else {
        widget.showToast(msg.replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _toggleActive(FoundationRoom r) async {
    setState(() => _togglingId = r.id);
    try {
      await ref.read(academicsRepositoryProvider).toggleRoomActive(r.id, !r.activeStatus);
      widget.showToast(!r.activeStatus ? 'Room activated.' : 'Room deactivated.');
      await widget.onRefresh();
    } catch (e) {
      widget.showToast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _togglingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canComplete = widget.rooms.isNotEmpty;
    final activeCount = widget.rooms.where((r) => r.activeStatus).length;
    final inactiveCount = widget.rooms.length - activeCount;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FoundationCard(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(999)), child: const Text('FINAL STEP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5B4FCF)))),
                  const Text('Set Up Classrooms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                  const Text('Add physical rooms to finish onboarding.', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
                  if (widget.rooms.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check, size: 13, color: Color(0xFF22C55E)), const SizedBox(width: 4), Text('${widget.rooms.length} room${widget.rooms.length != 1 ? 's' : ''} added', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)))]),
                  ElevatedButton(
                    onPressed: canComplete ? widget.onNext : null,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFE8ECEF), disabledForegroundColor: const Color(0xFF9FA6AD), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                    child: const Text('Complete Setup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final form = _buildForm();
              final table = _buildTable(activeCount, inactiveCount);
              if (wide) return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: form), const SizedBox(width: 16), Expanded(child: table)]));
              return Column(children: [form, const SizedBox(height: 10), table]);
            }),
          ],
        ),
        if (_pendingDelete != null)
          FoundationConfirmDeleteDialog(
            key: _deleteConfirmKey,
            title: 'Delete Room',
            message: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Are you sure you want to delete room '),
              TextSpan(text: '"${_pendingDelete!.roomNo}"', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '? This room will no longer be available for class assignments.'),
            ])),
            loading: _deletingId == _pendingDelete!.id,
            onConfirm: _confirmDelete,
            onCancel: () => setState(() => _pendingDelete = null),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_editingId != null ? 'Edit Room' : 'Add Classroom', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
          Text(_editingId != null ? 'Editing "${_roomNoController.text}"' : 'Enter room details, then click Add Room.', style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
          const SizedBox(height: 6),
          foundationFieldLabel('Room Number', required: true),
          TextField(controller: _roomNoController, maxLength: 10, onSubmitted: (_) => _save(), decoration: foundationFieldDecoration(hint: 'e.g. 101, A-02, LAB1').copyWith(counterText: '')),
          const Text('Letters, numbers, hyphens — saved as UPPERCASE. Max 10 chars.', style: TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
          const SizedBox(height: 6),
          Text.rich(TextSpan(style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6F767E)), children: const [TextSpan(text: 'Floor / Block')])),
          const SizedBox(height: 3),
          TextField(controller: _floorController, maxLength: 64, onSubmitted: (_) => _save(), decoration: foundationFieldDecoration(hint: 'e.g. Ground, First, Block A').copyWith(counterText: '')),
          const SizedBox(height: 6),
          foundationFieldLabel('Capacity', required: true),
          TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _capacity)..selection = TextSelection.collapsed(offset: _capacity.length),
            onChanged: (v) => _capacity = v,
            onSubmitted: (_) => _save(),
            decoration: foundationFieldDecoration(),
          ),
          const Text('Max 200 students per room.', style: TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
          const SizedBox(height: 6),
          foundationFieldLabel('Assign to Section'),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _classId,
                isExpanded: true,
                decoration: foundationFieldDecoration(hint: 'Select Class'),
                items: _availableClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() {
                  _classId = v;
                  _sectionId = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _sectionId,
                isExpanded: true,
                decoration: foundationFieldDecoration(hint: _classId == null ? 'Select class first' : 'Select Section'),
                items: _filteredSections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: _classId == null ? null : (v) => setState(() => _sectionId = v),
              ),
            ),
          ]),
          Text(_availableClasses.isEmpty ? 'No sections found. Add sections in Step 3 first.' : 'Optional — pick a class, then a section.', style: TextStyle(fontSize: 10, color: _availableClasses.isEmpty ? const Color(0xFFF59E0B) : const Color(0xFF9FA6AD))),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), border: Border.all(color: const Color(0xFFFCA5A5)), borderRadius: BorderRadius.circular(8)), child: Text(_error, style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)))),
          ],
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: widget.onBack, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: const Text('Back', style: TextStyle(fontSize: 12))),
            if (_editingId != null) OutlinedButton(onPressed: _cancelEdit, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F767E), side: const BorderSide(color: Color(0xFFE8ECEF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: const Text('Cancel', style: TextStyle(fontSize: 12))),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
              child: Text(_saving ? (_editingId != null ? 'Saving...' : 'Adding...') : (_editingId != null ? 'Save Changes' : '+ Add Room'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          if (!_saving && widget.rooms.isEmpty && _editingId == null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFEEF0FF), border: Border.all(color: const Color(0xFFC7C2F0)), borderRadius: BorderRadius.circular(9)),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 13, color: Color(0xFF5B4FCF)),
                const SizedBox(width: 8),
                const Expanded(child: Text.rich(TextSpan(style: TextStyle(fontSize: 11, color: Color(0xFF5B4FCF)), children: [TextSpan(text: 'Add at least one room to enable '), TextSpan(text: 'Complete Setup', style: TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: '.')]))),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildTable(int activeCount, int inactiveCount) {
    final totalPages = (widget.rooms.length / _perPage).ceil();
    final safePage = totalPages > 0 ? _page.clamp(0, totalPages - 1) : 0;
    final pageRooms = widget.rooms.skip(safePage * _perPage).take(_perPage).toList();

    return FoundationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Expanded(child: Text('Room Assignments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)))),
            if (widget.rooms.isNotEmpty) Text('$activeCount active${inactiveCount > 0 ? ' · $inactiveCount inactive' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
          ]),
          const SizedBox(height: 6),
          if (widget.rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(children: [
                  Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFFF0F2F5), shape: BoxShape.circle), child: const Icon(Icons.chair_outlined, color: Color(0xFF9FA6AD))),
                  const SizedBox(height: 6),
                  const Text('No rooms yet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6F767E))),
                  const Text('Rooms appear here as you add them.', style: TextStyle(fontSize: 11, color: Color(0xFF9FA6AD))),
                ]),
              ),
            )
          else ...[
            for (final r in pageRooms) _roomRow(r),
            if (totalPages > 1) ...[
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${safePage * _perPage + 1}–${safePage * _perPage + pageRooms.length} of ${widget.rooms.length}', style: const TextStyle(fontSize: 10, color: Color(0xFF9FA6AD))),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(onPressed: safePage == 0 ? null : () => setState(() => _page = safePage - 1), icon: const Icon(Icons.chevron_left, size: 18), visualDensity: VisualDensity.compact),
                  Text('${safePage + 1} / $totalPages', style: const TextStyle(fontSize: 10, color: Color(0xFF6F767E))),
                  IconButton(onPressed: safePage >= totalPages - 1 ? null : () => setState(() => _page = safePage + 1), icon: const Icon(Icons.chevron_right, size: 18), visualDensity: VisualDensity.compact),
                ]),
              ]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _roomRow(FoundationRoom r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF4F4F4)))),
      child: Opacity(
        opacity: r.activeStatus ? 1 : 0.6,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(r.roomNo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D1F), decoration: r.activeStatus ? null : TextDecoration.lineThrough)),
              if (!r.activeStatus) Padding(padding: const EdgeInsets.only(left: 6), child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)), child: const Text('INACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))))),
            ]),
            Text(r.floor.isEmpty ? '—' : r.floor, style: const TextStyle(fontSize: 12, color: Color(0xFF6F767E))),
            Text('Cap ${r.capacity}', style: const TextStyle(fontSize: 12, color: Color(0xFF6F767E))),
            Text(r.sectionLabel.isEmpty ? '—' : r.sectionLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF6F767E))),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(onPressed: _editingId == r.id ? null : () => _openEdit(r), icon: const Icon(Icons.edit_outlined, size: 14), color: const Color(0xFF6F767E), tooltip: 'Edit', visualDensity: VisualDensity.compact),
              IconButton(
                onPressed: _togglingId == r.id ? null : () => _toggleActive(r),
                icon: _togglingId == r.id ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(r.activeStatus ? Icons.remove : Icons.add, size: 14),
                color: r.activeStatus ? const Color(0xFF6F767E) : const Color(0xFF22C55E),
                tooltip: r.activeStatus ? 'Deactivate' : 'Activate',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: _deletingId == r.id
                    ? null
                    : () {
                        setState(() => _pendingDelete = r);
                        _scrollToDeleteConfirm();
                      },
                icon: _deletingId == r.id ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.close, size: 14),
                color: const Color(0xFF9FA6AD),
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
