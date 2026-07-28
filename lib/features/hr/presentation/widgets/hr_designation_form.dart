import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/designation_entity.dart';
import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';
import 'hr_theme.dart';

/// Add/Edit Designation form — Department, Name, Active only, matching the
/// ACTUAL currently-running backend's `DesignationSerializer` exactly
/// (verified read-only: `fields = ["id","school","department","name",
/// "is_active","created_at","updated_at"]`). No Short Code/Role
/// Template/Employment Type/Reports To/Grade Level/Sort Order/reorder —
/// none of those exist on this backend.
class HrDesignationForm extends ConsumerStatefulWidget {
  final DesignationEntity? initial;
  final int? defaultDeptId;
  final List<DepartmentEntity> departments;
  final void Function(bool addAnother) onSaved;
  final VoidCallback? onCancel;
  final String stepLabel;

  const HrDesignationForm({
    super.key,
    this.initial,
    this.defaultDeptId,
    required this.departments,
    required this.onSaved,
    this.onCancel,
    this.stepLabel = 'STEP 2 OF 2',
  });

  @override
  ConsumerState<HrDesignationForm> createState() => _HrDesignationFormState();
}

class _HrDesignationFormState extends ConsumerState<HrDesignationForm> {
  late final _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
  int? _departmentId;
  late bool _isActive = widget.initial?.isActive ?? true;
  bool _saving = false;
  String? _departmentError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _departmentId = widget.initial?.departmentId ?? widget.defaultDeptId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial?.id != null && widget.initial!.id != 0;

  /// Matches `DesignationSerializer.validate_name` exactly.
  String? _validateName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Designation name is required.';
    if (value.length < 3 || value.length > 50) return 'Designation name length must be between 3 and 50 characters.';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) return 'Designation name can contain only letters and spaces.';
    return null;
  }

  void _applyServerError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('department')) {
      setState(() => _departmentError = message);
      return;
    }
    if (lower.contains('designation') || lower.contains('name')) {
      setState(() => _nameError = message);
      return;
    }
    showHrToast(context, message, type: 'error');
  }

  Future<void> _save({bool addAnother = false}) async {
    setState(() {
      _departmentError = _departmentId == null ? 'Department is required.' : null;
      _nameError = _validateName(_nameCtrl.text);
    });
    if (_departmentError != null || _nameError != null) return;

    setState(() => _saving = true);
    final base = widget.initial;
    final draft = DesignationEntity(
      id: base?.id ?? 0,
      departmentId: _departmentId!,
      name: _nameCtrl.text.trim(),
      isActive: _isActive,
    );
    try {
      final repo = ref.read(hrRepositoryProvider);
      if (_isEdit) {
        await repo.updateDesignation(base!.id, draft);
      } else {
        await repo.createDesignation(draft);
      }
      if (!mounted) return;
      showHrToast(context, _isEdit ? 'Designation updated' : 'Designation saved');
      widget.onSaved(addAnother);
      if (addAnother) {
        setState(() {
          _nameCtrl.clear();
          _isActive = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _applyServerError(e is HrApiException ? e.message : 'Failed to save designation');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: HrColors.line), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.stepLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(_isEdit ? 'Edit Designation' : 'Add Designation', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: HrColors.ink)),
          const SizedBox(height: 4),
          const Text('Define roles within each department.', style: TextStyle(fontSize: 13, color: HrColors.muted)),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: HrField(
                label: 'Department',
                required: true,
                error: _departmentError,
                child: DropdownButtonFormField<int>(
                  initialValue: widget.departments.any((d) => d.id == _departmentId) ? _departmentId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Select department...'),
                  items: [for (final d in widget.departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() {
                    _departmentId = v;
                    _departmentError = null;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HrField(
                label: 'Designation Name',
                required: true,
                error: _nameError,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Senior Teacher'),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Checkbox(value: _isActive, onChanged: (v) => setState(() => _isActive = v ?? true)),
            const Text('Active'),
          ]),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _saving ? null : () => _save(addAnother: true),
                child: const Text('Save & add another', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HrColors.brand)),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.onCancel != null) ...[
                  OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                ],
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
                  onPressed: _saving ? null : () => _save(),
                  child: Text(_saving ? 'Saving...' : (_isEdit ? 'Update' : 'Save')),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
