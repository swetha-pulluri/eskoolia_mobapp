import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fee_type.dart';
import '../../domain/repositories/fees_config_repository.dart';
import '../providers/fees_config_providers.dart';
import 'fee_config_styles.dart';

const _kFeeTaxableOptions = ['Yes', 'No'];
const _kFeeStructureOptions = ['Monthly', 'Term-wise', 'Quarterly', 'Half-Yearly', 'Yearly', 'Custom / One-time'];
final _kGlCodeRegex = RegExp(r'^[0-9]{4}-[A-Z0-9]+$');
const _kGlCodeSuggestions = [
  (label: 'Tuition Fee', code: '4001-TUITION'),
  (label: 'Development Fee', code: '4002-DEVFEE'),
  (label: 'Examination Fee', code: '4003-EXAM'),
  (label: 'Transport Fee', code: '4004-TRANS'),
  (label: 'Library Fee', code: '4005-LIBRARY'),
  (label: 'Computer Fee', code: '4006-COMPUTER'),
  (label: 'Sports Fee', code: '4007-SPORTS'),
  (label: 'Activity Fee', code: '4008-ACTIVITY'),
];

String _normalizeFeeTypeName(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String? _suggestedCodeForName(String name) {
  final normalized = _normalizeFeeTypeName(name);
  if (normalized.isEmpty) return null;
  for (final option in _kGlCodeSuggestions) {
    final optionName = _normalizeFeeTypeName(option.label);
    if (normalized.contains(optionName.replaceAll('fee', '')) || optionName.contains(normalized)) {
      return option.code;
    }
  }
  return null;
}

/// Mirrors `validateGlCodeClient` — checked only against whatever page of
/// [existingTypes] is currently loaded (same limitation as the source,
/// which validates against its own paginated `feeTypes` state, not an
/// exhaustive server-wide list; the real uniqueness check runs server-side
/// regardless).
String _validateGlCode(String raw, List<FeesType> existingTypes, {int? currentId}) {
  final value = raw.trim().toUpperCase();
  if (value.isEmpty) return 'GL Code is required.';
  if (!_kGlCodeRegex.hasMatch(value)) return 'Invalid GL Code format. Use XXXX-CODE (e.g., 4001-TUITION).';

  final duplicateCode = existingTypes.any((t) => t.glCode.toUpperCase() == value && t.id != currentId);
  if (duplicateCode) return 'A Fee Type with this GL Code already exists.';

  final accountNumber = value.split('-').first;
  final duplicateAccount = existingTypes.any((t) => t.id != currentId && t.glCode.toUpperCase().startsWith('$accountNumber-'));
  if (duplicateAccount) return 'Account number $accountNumber is already used by another Fee Type. Use a unique account number.';

  return '';
}

/// Fee Types tab — converted from FeeConfigurationPanel.tsx's
/// `renderFeeTypes` + its Edit/Delete modals.
class FeeTypesTab extends ConsumerStatefulWidget {
  final int? academicYearId;
  final void Function(String message) onToast;

  const FeeTypesTab({super.key, required this.academicYearId, required this.onToast});

  @override
  ConsumerState<FeeTypesTab> createState() => _FeeTypesTabState();
}

class _FeeTypesTabState extends ConsumerState<FeeTypesTab> {
  List<FeesType> _rows = [];
  List<FeesGroup> _feeGroups = [];
  bool _isLoading = false;
  bool _isSaving = false;
  int _page = 1;
  static const _pageSize = 10;
  int _totalCount = 0;
  int get _totalPages => (_totalCount / _pageSize).ceil().clamp(1, 1 << 30);

  final _searchCtrl = TextEditingController();
  String _statusFilter = '';

  int? _groupId;
  final _nameCtrl = TextEditingController();
  final _glCodeCtrl = TextEditingController();
  String _taxable = 'No';
  String _structure = 'Term-wise';
  String _status = 'Active';
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _load();
    ref.read(feesConfigRepositoryProvider).fetchGroups().then((groups) {
      if (mounted) setState(() => _feeGroups = groups);
    }).catchError((_) {});
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _glCodeCtrl.dispose();
    super.dispose();
  }

  DateTime? _debounceAt;
  void _onSearchChanged() {
    _debounceAt = DateTime.now();
    final requestedAt = _debounceAt;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (requestedAt == _debounceAt && mounted) {
        setState(() => _page = 1);
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(feesConfigRepositoryProvider).fetchTypes(
            page: _page,
            pageSize: _pageSize,
            search: _searchCtrl.text.trim(),
            status: _statusFilter,
          );
      if (mounted) {
        setState(() {
          _rows = result.rows;
          _totalCount = result.count;
        });
      }
    } catch (_) {
      if (mounted) widget.onToast('Unable to load fee types.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreate() async {
    if (widget.academicYearId == null) {
      widget.onToast('Select an academic year first.');
      return;
    }
    final glError = _validateGlCode(_glCodeCtrl.text, _rows);
    setState(() {
      _errors.clear();
      if (glError.isNotEmpty) _errors['gl_code'] = glError;
    });
    if (_errors.isNotEmpty) {
      widget.onToast('Please fix validation errors before submitting.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(feesConfigRepositoryProvider).createType(
            academicYear: widget.academicYearId!,
            feesGroup: _groupId,
            name: _nameCtrl.text,
            glCode: _glCodeCtrl.text,
            taxable: _taxable,
            defaultStructure: _structure,
            status: _status,
          );
      widget.onToast('Fee type created successfully.');
      setState(() {
        _groupId = null;
        _nameCtrl.clear();
        _glCodeCtrl.clear();
        _taxable = 'No';
        _structure = 'Term-wise';
        _status = 'Active';
      });
      await _load();
    } on FeesConfigValidationException catch (e) {
      setState(() => _errors.addAll(e.fieldErrors));
      widget.onToast(e.fieldErrors['name'] ?? e.message);
    } catch (_) {
      widget.onToast('Failed to create fee type.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openEdit(FeesType row) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditTypeDialog(row: row, existingTypes: _rows),
    );
    if (saved == true) {
      widget.onToast('Fee type updated successfully.');
      await _load();
    }
  }

  Future<void> _openDelete(FeesType row) async {
    final deleted = await showDialog<bool>(context: context, builder: (_) => _DeleteTypeDialog(row: row));
    if (deleted == true) {
      widget.onToast('Fee type deleted successfully.');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeeConfigCard(child: _buildCreateForm()),
        const SizedBox(height: 16),
        _buildTable(),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create Fee Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: feeConfigInk1)),
        const SizedBox(height: 3),
        const Text(
          'Create fee types with GL code, taxation, structure, and status.',
          style: TextStyle(fontSize: 12.5, color: feeConfigInk3),
        ),
        const SizedBox(height: 18),
        const FeeConfigLabel('FEE GROUP'),
        FeeConfigSelect<int?>(
          value: _groupId,
          hint: 'Select fee group',
          items: [null, for (final g in _feeGroups) g.id],
          labelOf: (id) => id == null ? 'Select fee group' : _feeGroups.firstWhere((g) => g.id == id).name,
          onChanged: (v) => setState(() => _groupId = v),
        ),
        const SizedBox(height: 14),
        const FeeConfigLabel('FEE TYPE NAME'),
        TextField(
          controller: _nameCtrl,
          decoration: feeConfigInputDecoration(hint: 'Tuition Fee'),
          onChanged: (v) {
            if (_glCodeCtrl.text.trim().isEmpty) {
              final suggested = _suggestedCodeForName(v);
              if (suggested != null) setState(() => _glCodeCtrl.text = suggested);
            }
          },
        ),
        FeeConfigFieldError(_errors['name']),
        const SizedBox(height: 14),
        const FeeConfigLabel('GL CODE'),
        TextField(
          controller: _glCodeCtrl,
          decoration: feeConfigInputDecoration(hint: '4001-TUITION', hasError: _errors.containsKey('gl_code')),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) {
            final upper = v.toUpperCase();
            if (upper != v) {
              _glCodeCtrl.value = _glCodeCtrl.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length));
            }
            if (_errors.containsKey('gl_code')) {
              setState(() => _errors['gl_code'] = _validateGlCode(upper, _rows));
            }
          },
        ),
        const Padding(padding: EdgeInsets.only(top: 6), child: Text('Format: 4001-TUITION', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5))),
        FeeConfigFieldError(_errors['gl_code']),
        const SizedBox(height: 14),
        const FeeConfigLabel('TAXABLE'),
        FeeConfigSelect<String>(value: _taxable, items: _kFeeTaxableOptions, labelOf: (v) => v, onChanged: (v) => setState(() => _taxable = v ?? 'No')),
        const SizedBox(height: 14),
        const FeeConfigLabel('DEFAULT STRUCTURE'),
        FeeConfigSelect<String>(value: _structure, items: _kFeeStructureOptions, labelOf: (v) => v, onChanged: (v) => setState(() => _structure = v ?? 'Term-wise')),
        const SizedBox(height: 14),
        const FeeConfigLabel('STATUS'),
        FeeConfigSelect<String>(value: _status, items: const ['Active', 'Inactive'], labelOf: (v) => v, onChanged: (v) => setState(() => _status = v ?? 'Active')),
        FeeConfigFieldError(_errors['general']),
        const SizedBox(height: 16),
        FeeConfigPrimaryButton(label: _isSaving ? 'Saving...' : 'Add', onPressed: _isSaving ? null : _handleCreate),
      ],
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: feeConfigCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(controller: _searchCtrl, decoration: feeConfigInputDecoration(hint: 'Search by fee type name or GL code')),
                const SizedBox(height: 10),
                FeeConfigSelect<String>(
                  value: _statusFilter,
                  items: const ['', 'active', 'inactive'],
                  labelOf: (v) => v == '' ? 'All Status' : (v == 'active' ? 'Active' : 'Inactive'),
                  onChanged: (v) {
                    setState(() {
                      _statusFilter = v ?? '';
                      _page = 1;
                    });
                    _load();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: feeConfigBorder),
          Container(
            color: const Color(0xFFF8F8FB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('NAME / GL CODE', style: feeConfigThStyle)),
                Expanded(flex: 2, child: Text('TAXABLE / STRUCTURE', style: feeConfigThStyle)),
                Expanded(flex: 2, child: Text('STATUS', style: feeConfigThStyle)),
                Expanded(flex: 2, child: Text('ACTIONS', style: feeConfigThStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(24), child: Text('Loading fee types...', style: TextStyle(color: feeConfigInk2)))
          else if (_rows.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No fee types found.', style: TextStyle(color: feeConfigInk2)))
          else
            for (final row in _rows) _buildRow(row),
          if (!_isLoading && _totalCount > 0) ...[
            const Divider(height: 1, color: feeConfigBorder),
            Padding(padding: const EdgeInsets.all(12), child: _buildPagination()),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(FeesType row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: feeConfigBorder))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: feeConfigInk1)),
                const SizedBox(height: 2),
                Text(row.glCode, style: feeConfigTdMuted),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taxable: ${row.taxable}', style: feeConfigTdMuted),
                Text(row.defaultStructure, style: feeConfigTdMuted),
              ],
            ),
          ),
          Expanded(flex: 2, child: FeeConfigStatusPill(row.status)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FeeConfigOutlineButton(small: true, label: 'Edit', onPressed: () => _openEdit(row)),
                const SizedBox(height: 8),
                FeeConfigDangerButton(small: true, label: 'Delete', onPressed: () => _openDelete(row)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final start = (_page - 2).clamp(1, 1 << 30);
    final end = (start + 4).clamp(1, _totalPages);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _pageBtn('Prev', enabled: _page > 1, onTap: () {
          setState(() => _page = (_page - 1).clamp(1, _totalPages));
          _load();
        }),
        for (var p = start; p <= end; p++) ...[
          const SizedBox(width: 6),
          _pageBtn('$p', selected: p == _page, onTap: () {
            setState(() => _page = p);
            _load();
          }),
        ],
        const SizedBox(width: 6),
        _pageBtn('Next', enabled: _page < _totalPages, onTap: () {
          setState(() => _page = (_page + 1).clamp(1, _totalPages));
          _load();
        }),
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
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

class _EditTypeDialog extends ConsumerStatefulWidget {
  final FeesType row;
  final List<FeesType> existingTypes;
  const _EditTypeDialog({required this.row, required this.existingTypes});

  @override
  ConsumerState<_EditTypeDialog> createState() => _EditTypeDialogState();
}

class _EditTypeDialogState extends ConsumerState<_EditTypeDialog> {
  late final _nameCtrl = TextEditingController(text: widget.row.name);
  late final _glCodeCtrl = TextEditingController(text: widget.row.glCode);
  late String _taxable = widget.row.taxable;
  late String _structure = widget.row.defaultStructure;
  late String _status = widget.row.status;
  final Map<String, String> _errors = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _glCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final glError = _validateGlCode(_glCodeCtrl.text, widget.existingTypes, currentId: widget.row.id);
    setState(() {
      _errors.clear();
      if (glError.isNotEmpty) _errors['gl_code'] = glError;
    });
    if (_errors.isNotEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(feesConfigRepositoryProvider).updateType(
            widget.row.id,
            feesGroup: widget.row.feesGroup,
            name: _nameCtrl.text,
            glCode: _glCodeCtrl.text,
            taxable: _taxable,
            defaultStructure: _structure,
            status: _status,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on FeesConfigValidationException catch (e) {
      setState(() => _errors.addAll(e.fieldErrors));
    } catch (_) {
      // leave dialog open, no toast plumbing at this layer
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Edit Fee Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FeeConfigLabel('FEE TYPE NAME'),
              TextField(
                controller: _nameCtrl,
                decoration: feeConfigInputDecoration(),
                onChanged: (v) {
                  if (_glCodeCtrl.text.trim().isEmpty) {
                    final suggested = _suggestedCodeForName(v);
                    if (suggested != null) setState(() => _glCodeCtrl.text = suggested);
                  }
                },
              ),
              FeeConfigFieldError(_errors['name']),
              const SizedBox(height: 14),
              const FeeConfigLabel('GL CODE'),
              TextField(
                controller: _glCodeCtrl,
                decoration: feeConfigInputDecoration(hasError: _errors.containsKey('gl_code')),
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) {
                  final upper = v.toUpperCase();
                  if (upper != v) {
                    _glCodeCtrl.value = _glCodeCtrl.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length));
                  }
                  if (_errors.containsKey('gl_code')) {
                    setState(() => _errors['gl_code'] = _validateGlCode(upper, widget.existingTypes, currentId: widget.row.id));
                  }
                },
              ),
              const Padding(padding: EdgeInsets.only(top: 6), child: Text('Format: 4001-TUITION', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5))),
              FeeConfigFieldError(_errors['gl_code']),
              const SizedBox(height: 14),
              const FeeConfigLabel('TAXABLE'),
              FeeConfigSelect<String>(value: _taxable, items: _kFeeTaxableOptions, labelOf: (v) => v, onChanged: (v) => setState(() => _taxable = v ?? 'No')),
              const SizedBox(height: 14),
              const FeeConfigLabel('DEFAULT STRUCTURE'),
              FeeConfigSelect<String>(value: _structure, items: _kFeeStructureOptions, labelOf: (v) => v, onChanged: (v) => setState(() => _structure = v ?? 'Term-wise')),
              const SizedBox(height: 14),
              const FeeConfigLabel('STATUS'),
              Row(
                children: [
                  FeeConfigStatusPill(_status),
                  const SizedBox(width: 10),
                  FeeConfigToggle(value: _status == 'Active', onChanged: (v) => setState(() => _status = v ? 'Active' : 'Inactive')),
                ],
              ),
              FeeConfigFieldError(_errors['general']),
            ],
          ),
        ),
      ),
      actions: [
        FeeConfigOutlineButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
        FeeConfigPrimaryButton(label: _isSaving ? 'Saving...' : 'Save Changes', onPressed: _isSaving ? null : _save),
      ],
    );
  }
}

class _DeleteTypeDialog extends ConsumerStatefulWidget {
  final FeesType row;
  const _DeleteTypeDialog({required this.row});

  @override
  ConsumerState<_DeleteTypeDialog> createState() => _DeleteTypeDialogState();
}

class _DeleteTypeDialogState extends ConsumerState<_DeleteTypeDialog> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await ref.read(feesConfigRepositoryProvider).deleteType(widget.row.id);
      if (mounted) Navigator.of(context).pop(true);
    } on FeesConfigValidationException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'This fee type could not be deleted.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Delete Fee Type?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This action cannot be undone.', style: TextStyle(fontSize: 13, color: Color(0xFF3B4150), height: 1.5)),
          if (_error != null) ...[
            const SizedBox(height: 10),
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
