import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/department_type_entity.dart';
import '../../domain/entities/staff_lite_entity.dart';
import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';
import 'hr_theme.dart';

const _predefinedDeptTypes = ['Academic', 'Administrative', 'Support', 'Transport', 'Finance'];
const _workingDaysOptions = [
  DepartmentEntity.workingDaysMonFri,
  DepartmentEntity.workingDaysMonSat,
  DepartmentEntity.workingDaysAll7,
];
const _statusOptions = [
  (DepartmentEntity.statusActive, 'Active'),
  (DepartmentEntity.statusInactive, 'Inactive'),
  (DepartmentEntity.statusArchived, 'Archived'),
];

/// Add/Edit Department drawer — a literal port of the real, live
/// `InlineDeptForm` (`hr/setup/page.tsx` on the `demo`/`mobile`/`BugFix`
/// branches — verified read-only, migrations `0014`-`0027` on
/// `apps/hr/models.py`). All 9 fields the backend actually persists:
/// Department Name, Short Code, Department Type (+ custom-type popup),
/// Status, Working Days, Department Head, Deputy Head, Department Email,
/// Description.
class HrDepartmentForm extends ConsumerStatefulWidget {
  final DepartmentEntity? initial;
  final String stepLabel;
  final void Function(bool addAnother) onSaved;
  final VoidCallback onCancel;

  const HrDepartmentForm({
    super.key,
    this.initial,
    this.stepLabel = 'STEP 1 OF 2',
    required this.onSaved,
    required this.onCancel,
  });

  @override
  ConsumerState<HrDepartmentForm> createState() => _HrDepartmentFormState();
}

class _HrDepartmentFormState extends ConsumerState<HrDepartmentForm> {
  late final _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
  late final _shortCodeCtrl = TextEditingController(text: widget.initial?.shortCode ?? '');
  late final _emailCtrl = TextEditingController(text: widget.initial?.email ?? '');
  late final _descriptionCtrl = TextEditingController(text: widget.initial?.description ?? '');
  late String _deptType = widget.initial?.deptType.isNotEmpty == true ? widget.initial!.deptType : 'Academic';
  late String _status = widget.initial?.status ?? DepartmentEntity.statusActive;
  late String _workingDays = widget.initial?.workingDays ?? DepartmentEntity.workingDaysMonFri;
  int? _headId;
  int? _deputyHeadId;
  bool _saving = false;
  String? _nameError;
  String? _shortCodeError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _headId = widget.initial?.headId;
    _deputyHeadId = widget.initial?.deputyHeadId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCodeCtrl.dispose();
    _emailCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial?.id != null && widget.initial!.id != 0;

  /// Matches the real `InlineDeptForm`'s own client-side `validate()` exactly
  /// — it does not replicate the backend's name/description regex rules
  /// client-side; those surface as a toast if the server rejects them.
  bool _validate() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Required' : null;
      _shortCodeError = _shortCodeCtrl.text.trim().isEmpty
          ? 'Required'
          : (_shortCodeCtrl.text.length > 6 ? 'Max 6 chars' : null);
      final email = _emailCtrl.text.trim();
      _emailError = email.isNotEmpty && !RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(email)
          ? 'Enter a valid email (e.g. science@school.edu)'
          : null;
    });
    return _nameError == null && _shortCodeError == null && _emailError == null;
  }

  Future<void> _save({bool addAnother = false}) async {
    if (!_validate()) return;
    setState(() => _saving = true);
    final draft = DepartmentEntity(
      id: widget.initial?.id ?? 0,
      name: _nameCtrl.text.trim(),
      shortCode: _shortCodeCtrl.text.trim(),
      deptType: _deptType,
      status: _status,
      workingDays: _workingDays,
      headId: _headId,
      deputyHeadId: _deputyHeadId,
      description: _descriptionCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    try {
      final repo = ref.read(hrRepositoryProvider);
      if (_isEdit) {
        await repo.updateDepartment(widget.initial!.id, draft);
      } else {
        await repo.createDepartment(draft);
      }
      if (!mounted) return;
      showHrToast(context, 'Department saved');
      if (addAnother) {
        setState(() {
          _nameCtrl.clear();
          _shortCodeCtrl.clear();
          _emailCtrl.clear();
          _descriptionCtrl.clear();
          _deptType = 'Academic';
          _status = DepartmentEntity.statusActive;
          _workingDays = DepartmentEntity.workingDaysMonFri;
          _headId = null;
          _deputyHeadId = null;
        });
        widget.onSaved(true);
      } else {
        widget.onSaved(false);
      }
    } catch (e) {
      if (!mounted) return;
      showHrToast(context, e is HrApiException ? e.message : 'Failed to save department', type: 'error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAddTypeDialog(List<DepartmentTypeEntity> allTypes) async {
    final isCustomCurrent = !_predefinedDeptTypes.contains(_deptType);
    final controller = TextEditingController(text: isCustomCurrent ? _deptType : '');
    String? error;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> confirm() async {
            final val = controller.text.trim();
            if (val.isEmpty) {
              setDialogState(() => error = 'Type name is required');
              return;
            }
            if (!RegExp(r'^[A-Za-z &-]+$').hasMatch(val)) {
              setDialogState(() => error = 'Only letters, spaces, & and hyphens allowed');
              return;
            }
            if (allTypes.any((t) => t.name.toLowerCase() == val.toLowerCase())) {
              setDialogState(() => error = '"$val" already exists — select it from the dropdown');
              return;
            }
            setDialogState(() => saving = true);
            try {
              final created = await ref.read(hrRepositoryProvider).createDepartmentType(val);
              if (!mounted) return;
              setState(() => _deptType = created.name);
              ref.invalidate(departmentTypesProvider);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            } catch (e) {
              setDialogState(() {
                saving = false;
                error = e is HrApiException ? e.message : 'Failed to create type';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add Department Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter a custom department type not listed in the dropdown.', style: TextStyle(fontSize: 13, color: HrColors.muted)),
                  const SizedBox(height: 16),
                  HrField(
                    label: 'Type Name',
                    error: error,
                    child: TextField(
                      controller: controller,
                      maxLength: 50,
                      autofocus: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Research & Development', counterText: ''),
                      onSubmitted: (_) => confirm(),
                    ),
                  ),
                  const Text('Letters, spaces, & and hyphens only', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
                onPressed: saving ? null : confirm,
                child: Text(saving ? 'Saving…' : 'Add Type'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(departmentTypesProvider);
    final staffAsync = ref.watch(activeStaffProvider);
    final types = typesAsync.valueOrNull ?? const <DepartmentTypeEntity>[];
    final staffList = staffAsync.valueOrNull?.results ?? const <StaffLiteEntity>[];

    // Defensive: if the department being edited already has a dept_type that
    // hasn't (yet) come back from `/department-types/`, keep it selectable
    // instead of crashing the dropdown — it's real data from the department
    // itself, just not necessarily loaded in this list yet.
    final deptTypeNames = {..._predefinedDeptTypes, ...types.map((t) => t.name), if (_deptType.isNotEmpty) _deptType};

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: HrColors.line), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(widget.stepLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: HrColors.brand)),
                if (!_isEdit) ...[
                  const SizedBox(width: 12),
                  const Text('Independent step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                ],
              ]),
              IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close, size: 16), color: const Color(0xFF94A3B8)),
            ],
          ),
          Text(_isEdit ? 'Edit: ${widget.initial?.name}' : 'Add Departments', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: HrColors.ink)),
          const SizedBox(height: 4),
          const Text("Departments form your school's top-level hierarchy. Add at least one before mapping designations.", style: TextStyle(fontSize: 13, color: HrColors.muted)),
          const SizedBox(height: 20),

          const Text('IDENTITY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final halfWidth = (constraints.maxWidth - 16) / 2;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(
                width: halfWidth,
                child: HrField(
                  label: 'Department Name',
                  required: true,
                  error: _nameError,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Science Department'),
                  ),
                ),
              ),
              SizedBox(
                width: halfWidth,
                child: HrField(
                  label: 'Short Code',
                  required: true,
                  error: _shortCodeError,
                  child: TextField(
                    controller: _shortCodeCtrl,
                    maxLength: 6,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'E.G. SCI', counterText: ''),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (v) {
                      final upper = v.toUpperCase();
                      if (upper != v) {
                        _shortCodeCtrl.value = _shortCodeCtrl.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length));
                      }
                    },
                  ),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final thirdWidth = (constraints.maxWidth - 32) / 3;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(
                width: thirdWidth,
                child: HrField(
                  label: 'Department Type',
                  child: Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: deptTypeNames.contains(_deptType) ? _deptType : null,
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select type…')),
                          for (final name in deptTypeNames) DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(() => _deptType = v ?? _deptType),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: HrColors.brand, side: const BorderSide(color: Color(0xFFE8E8F0))),
                        onPressed: () => _openAddTypeDialog(types),
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(
                width: thirdWidth,
                child: HrField(
                  label: 'Status',
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: [for (final (value, label) in _statusOptions) DropdownMenuItem(value: value, child: Text(label))],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ),
              ),
              SizedBox(
                width: thirdWidth,
                child: HrField(
                  label: 'Working Days',
                  child: DropdownButtonFormField<String>(
                    initialValue: _workingDays,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: [for (final wd in _workingDaysOptions) DropdownMenuItem(value: wd, child: Text(wd, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() => _workingDays = v ?? _workingDays),
                  ),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 20),

          const Text('LEADERSHIP', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final halfWidth = (constraints.maxWidth - 16) / 2;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(
                width: halfWidth,
                child: HrField(
                  label: 'Department Head',
                  child: DropdownButtonFormField<int?>(
                    initialValue: staffList.any((s) => s.id == _headId) ? _headId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Select staff (optional)')),
                      for (final s in staffList) DropdownMenuItem<int?>(value: s.id, child: Text(s.displayName, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _headId = v),
                  ),
                ),
              ),
              SizedBox(
                width: halfWidth,
                child: HrField(
                  label: 'Deputy Head',
                  child: DropdownButtonFormField<int?>(
                    initialValue: staffList.any((s) => s.id == _deputyHeadId) ? _deputyHeadId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Select staff (optional)')),
                      for (final s in staffList) DropdownMenuItem<int?>(value: s.id, child: Text(s.displayName, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _deputyHeadId = v),
                  ),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 20),

          const Text('CONTACT & NOTES', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final halfWidth = (constraints.maxWidth - 16) / 2;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(
                width: halfWidth,
                child: HrField(
                  label: 'Department Email',
                  error: _emailError,
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. science@school.edu'),
                  ),
                ),
              ),
              SizedBox(
                width: halfWidth,
                child: HrField(
                  label: 'Description',
                  child: TextField(
                    controller: _descriptionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Purpose, staff scope, reporting lines, responsibilities'),
                  ),
                ),
              ),
            ]);
          }),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (!_isEdit)
                TextButton(
                  onPressed: _saving ? null : () => _save(addAnother: true),
                  child: const Text('Save & add another', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HrColors.brand)),
                )
              else
                const SizedBox.shrink(),
              Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(onPressed: widget.onCancel, child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B)))),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
                  onPressed: _saving ? null : () => _save(),
                  child: Text(_saving ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Save Department')),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
