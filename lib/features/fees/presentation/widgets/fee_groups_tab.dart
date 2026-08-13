import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../student/domain/models/academic_year.dart';
import '../../../student/domain/models/school_class.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/repositories/fees_config_repository.dart';
import '../providers/fees_config_providers.dart';
import 'fee_class_multi_select.dart';
import 'fee_config_styles.dart';

/// Fee Groups tab — converted from FeeConfigurationPanel.tsx's
/// `renderFeeGroups` (+ its edit side-panel and delete dialog, rendered at
/// the page level in the source but scoped to this tab here).
class FeeGroupsTab extends ConsumerStatefulWidget {
  final int? academicYearId;
  final List<AcademicYear> academicYears;
  final List<SchoolClass> availableClasses;
  final void Function(String message) onToast;

  const FeeGroupsTab({
    super.key,
    required this.academicYearId,
    required this.academicYears,
    required this.availableClasses,
    required this.onToast,
  });

  @override
  ConsumerState<FeeGroupsTab> createState() => _FeeGroupsTabState();
}

class _FeeGroupsTabState extends ConsumerState<FeeGroupsTab> {
  List<FeesGroup> _groups = [];
  bool _isLoading = false;
  bool _isCreateOpen = true;
  bool _isSaving = false;
  int _page = 1;
  static const _pageSize = 5;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<int> _classIds = [];
  String? _classError;
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final groups = await ref.read(feesConfigRepositoryProvider).fetchGroups();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
      if (mounted) widget.onToast('Unable to load fee groups.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _currentYearName {
    final match = widget.academicYears.where((y) => y.id == widget.academicYearId);
    return match.isEmpty ? 'Unknown' : match.first.name;
  }

  Future<void> _handleCreate() async {
    if (widget.academicYearId == null) {
      widget.onToast('Select an academic year first.');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      widget.onToast('Group name is required.');
      return;
    }
    if (_classIds.isEmpty) {
      setState(() => _classError = 'Please select at least one applicable class.');
      widget.onToast('Please select at least one applicable class.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(feesConfigRepositoryProvider).createGroup(
            academicYear: widget.academicYearId!,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            applicableClasses: _classIds,
            isActive: _status == 'Active',
          );
      widget.onToast('Fee group saved.');
      await _load();
      setState(() {
        _nameCtrl.clear();
        _descCtrl.clear();
        _status = 'Active';
        _classIds = [];
        _classError = null;
      });
    } on FeesConfigValidationException catch (e) {
      widget.onToast(e.message);
    } catch (_) {
      widget.onToast('Failed to save fee group.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleToggleActive(FeesGroup group) async {
    try {
      await ref.read(feesConfigRepositoryProvider).updateGroup(group.id, isActive: !group.isActive);
      await _load();
    } catch (_) {
      widget.onToast('Failed to update status.');
    }
  }

  Future<void> _openEdit(FeesGroup group) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EditGroupSheet(group: group, availableClasses: widget.availableClasses),
    );
    if (saved == true) {
      widget.onToast('Fee group updated.');
      await _load();
    }
  }

  Future<void> _openDelete(FeesGroup group) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteGroupDialog(group: group),
    );
    if (deleted == true) {
      widget.onToast('Fee group deleted.');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_groups.length / _pageSize).ceil().clamp(1, 1 << 30);
    final safePage = _page.clamp(1, totalPages);
    final start = (safePage - 1) * _pageSize;
    final visible = _groups.skip(start).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeeConfigSectionHeading(
          title: 'Fee Groups',
          description:
              'Fee Groups organise fee types into logical buckets such as Day Scholar, Transport, or Boarding. They let you apply and report fees by category and student segment.',
        ),
        FeeConfigCard(child: _buildCreateForm()),
        const SizedBox(height: 16),
        _buildTable(visible),
        if (!_isLoading && _groups.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPagination(safePage, totalPages),
        ],
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Create Fee Group', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: feeConfigInk1)),
                  SizedBox(height: 3),
                  Text(
                    'Rows update immediately — each action maps to a feesApi call in production.',
                    style: TextStyle(fontSize: 12.5, color: feeConfigInk3),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _isCreateOpen = !_isCreateOpen),
              icon: AnimatedRotation(
                turns: _isCreateOpen ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more, size: 20, color: feeConfigInk2),
              ),
              style: IconButton.styleFrom(
                side: const BorderSide(color: feeConfigBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        if (_isCreateOpen) ...[
          const SizedBox(height: 12),
          Text('Academic year: $_currentYearName', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          const FeeConfigLabel('GROUP NAME'),
          TextField(controller: _nameCtrl, decoration: feeConfigInputDecoration(hint: 'Day Scholar')),
          const SizedBox(height: 14),
          const FeeConfigLabel('DESCRIPTION'),
          TextField(controller: _descCtrl, decoration: feeConfigInputDecoration(hint: 'Regular day school students')),
          const SizedBox(height: 14),
          const FeeConfigLabel('APPLICABLE CLASSES'),
          FeeClassMultiSelect(
            selectedIds: _classIds,
            availableClasses: widget.availableClasses,
            errorText: _classError,
            onChanged: (ids) => setState(() {
              _classIds = ids;
              _classError = null;
            }),
          ),
          const SizedBox(height: 14),
          const FeeConfigLabel('STATUS'),
          SizedBox(
            width: 200,
            child: FeeConfigSelect<String>(
              value: _status,
              items: const ['Active', 'Inactive'],
              labelOf: (v) => v,
              onChanged: (v) => setState(() => _status = v ?? 'Active'),
            ),
          ),
          const SizedBox(height: 16),
          FeeConfigPrimaryButton(label: _isSaving ? 'Saving...' : 'Add', onPressed: _isSaving ? null : _handleCreate),
        ],
      ],
    );
  }

  /// Column widths shared by the header row and every data row so they
  /// line up — matches web's real 5-column table exactly ("GROUP NAME",
  /// "DESCRIPTION", "CLASSES", "STATUS", "ACTIONS" — see
  /// `FeeConfigurationPanel.tsx`'s `renderFeeGroups`). Wrapped in a
  /// horizontally-scrolling container so the fixed widths never overflow
  /// on a narrow screen.
  static const _colGroupName = 150.0;
  static const _colDescription = 170.0;
  static const _colClasses = 170.0;
  static const _colStatus = 120.0;
  static const _colActions = 110.0;
  // +32 accounts for the 16px horizontal padding on each side of the header/row Containers below.
  static const _tableWidth = _colGroupName + _colDescription + _colClasses + _colStatus + _colActions + 32;

  Widget _buildTable(List<FeesGroup> visible) {
    return Container(
      decoration: feeConfigCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(24), child: Text('Loading fee groups...', style: TextStyle(color: feeConfigInk3)))
              else if (_groups.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('No fee groups yet.', style: TextStyle(color: feeConfigInk3)))
              else
                for (final group in visible) _buildRow(group),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      color: const Color(0xFFF8F8FB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          SizedBox(width: _colGroupName, child: Text('GROUP NAME', style: feeConfigThStyle)),
          SizedBox(width: _colDescription, child: Text('DESCRIPTION', style: feeConfigThStyle)),
          SizedBox(width: _colClasses, child: Text('CLASSES', style: feeConfigThStyle)),
          SizedBox(width: _colStatus, child: Text('STATUS', style: feeConfigThStyle)),
          SizedBox(width: _colActions, child: Text('ACTIONS', style: feeConfigThStyle)),
        ],
      ),
    );
  }

  /// Each fee group shown as one table row, with the fields lined up under
  /// their own column headings above — matches web's real table structure
  /// (`renderFeeGroups`) exactly rather than combining fields together.
  Widget _buildRow(FeesGroup group) {
    final classNames = group.applicableClasses.isEmpty
        ? 'All Classes'
        : group.applicableClasses
            .map((id) => widget.availableClasses.where((c) => c.id == id).map((c) => c.name).firstOrNullOr(null))
            .whereType<String>()
            .join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F1F4)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _colGroupName,
            child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1D2230))),
          ),
          SizedBox(
            width: _colDescription,
            child: Text(group.description.isEmpty ? '—' : group.description, style: const TextStyle(fontSize: 12.5, color: Color(0xFF3B4150))),
          ),
          SizedBox(
            width: _colClasses,
            child: Text(classNames, style: const TextStyle(fontSize: 12, color: Color(0xFF3B4150))),
          ),
          SizedBox(
            width: _colStatus,
            child: Row(
              children: [
                FeeConfigStatusPill(group.isActive ? 'Active' : 'Inactive'),
                const SizedBox(width: 8),
                FeeConfigToggle(value: group.isActive, onChanged: (_) => _handleToggleActive(group)),
              ],
            ),
          ),
          SizedBox(
            width: _colActions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeeConfigOutlineButton(small: true, label: 'Edit', onPressed: () => _openEdit(group)),
                const SizedBox(height: 8),
                FeeConfigDangerButton(small: true, label: 'Delete', onPressed: () => _openDelete(group)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int safePage, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _pageBtn('<', enabled: safePage > 1, onTap: () => setState(() => _page = safePage - 1)),
        for (var p = 1; p <= totalPages; p++) ...[
          const SizedBox(width: 6),
          _pageBtn('$p', selected: p == safePage, onTap: () => setState(() => _page = p)),
        ],
        const SizedBox(width: 6),
        _pageBtn('>', enabled: safePage < totalPages, onTap: () => setState(() => _page = safePage + 1)),
      ],
    );
  }

  Widget _pageBtn(String label, {bool selected = false, bool enabled = true, required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 28,
        constraints: const BoxConstraints(minWidth: 28),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? feeConfigPurple : Colors.white,
          border: Border.all(color: feeConfigBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : feeConfigInk2)),
        ),
      ),
    );
  }
}

extension _FirstOrNullOr<T> on Iterable<T> {
  T? firstOrNullOr(T? fallback) => isEmpty ? fallback : first;
}

class _EditGroupSheet extends ConsumerStatefulWidget {
  final FeesGroup group;
  final List<SchoolClass> availableClasses;
  const _EditGroupSheet({required this.group, required this.availableClasses});

  @override
  ConsumerState<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends ConsumerState<_EditGroupSheet> {
  late final _nameCtrl = TextEditingController(text: widget.group.name);
  late final _descCtrl = TextEditingController(text: widget.group.description);
  late List<int> _classIds = List.of(widget.group.applicableClasses);
  String? _classError;
  late bool _isActive = widget.group.isActive;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (_classIds.isEmpty) {
      setState(() => _classError = 'Please select at least one applicable class.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(feesConfigRepositoryProvider).updateGroup(
            widget.group.id,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            applicableClasses: _classIds,
            isActive: _isActive,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: feeConfigBorder))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Fee Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close, color: feeConfigInk3)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const FeeConfigLabel('GROUP NAME'),
                    TextField(controller: _nameCtrl, decoration: feeConfigInputDecoration()),
                    const SizedBox(height: 15),
                    const FeeConfigLabel('DESCRIPTION'),
                    TextField(controller: _descCtrl, decoration: feeConfigInputDecoration()),
                    const SizedBox(height: 15),
                    const FeeConfigLabel('APPLICABLE CLASSES'),
                    FeeClassMultiSelect(
                      selectedIds: _classIds,
                      availableClasses: widget.availableClasses,
                      errorText: _classError,
                      onChanged: (ids) => setState(() {
                        _classIds = ids;
                        _classError = null;
                      }),
                    ),
                    const SizedBox(height: 15),
                    const FeeConfigLabel('STATUS'),
                    Row(
                      children: [
                        FeeConfigStatusPill(_isActive ? 'Active' : 'Inactive'),
                        const SizedBox(width: 8),
                        FeeConfigToggle(value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: feeConfigBorder))),
                child: Row(
                  children: [
                    Expanded(child: FeeConfigOutlineButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false))),
                    const SizedBox(width: 10),
                    Expanded(child: FeeConfigPrimaryButton(label: _isSaving ? 'Saving...' : 'Save Changes', onPressed: _isSaving ? null : _save)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeleteGroupDialog extends ConsumerStatefulWidget {
  final FeesGroup group;
  const _DeleteGroupDialog({required this.group});

  @override
  ConsumerState<_DeleteGroupDialog> createState() => _DeleteGroupDialogState();
}

class _DeleteGroupDialogState extends ConsumerState<_DeleteGroupDialog> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await ref.read(feesConfigRepositoryProvider).deleteGroup(widget.group.id);
      if (mounted) Navigator.of(context).pop(true);
    } on FeesConfigValidationException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'This fee group could not be deleted. Please try again.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('Delete "${widget.group.name}"?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will permanently remove the fee group. This action cannot be undone.',
            style: TextStyle(fontSize: 13, color: Color(0xFF3B4150), height: 1.5),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFA23631))),
            ),
          ],
        ],
      ),
      actions: [
        FeeConfigOutlineButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
        FeeConfigDangerButton(label: _isDeleting ? 'Deleting...' : 'Delete', onPressed: _isDeleting ? null : _delete),
      ],
    );
  }
}
