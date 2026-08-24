import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/concession_rule.dart';
import '../../domain/repositories/fees_config_repository.dart';
import '../providers/fees_config_providers.dart';
import 'fee_config_styles.dart';

/// Concession Rules tab — converted from FeeConfigurationPanel.tsx's
/// `renderConcessionRules`. No pagination in the source (fetched with
/// `page_size: 100` and shown in full).
class ConcessionRulesTab extends ConsumerStatefulWidget {
  final void Function(String message) onToast;
  const ConcessionRulesTab({super.key, required this.onToast});

  @override
  ConsumerState<ConcessionRulesTab> createState() => _ConcessionRulesTabState();
}

class _ConcessionRulesTabState extends ConsumerState<ConcessionRulesTab> {
  List<ConcessionRule> _rows = [];
  bool _isLoading = false;
  bool _isSaving = false;
  int? _deletingId;
  int? _editingId;

  final _nameCtrl = TextEditingController();
  final _appliesToCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _appliesToCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final rows = await ref.read(feesConfigRepositoryProvider).fetchConcessionRules();
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) widget.onToast('Unable to load concession rules.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEdit(ConcessionRule rule) {
    setState(() {
      _editingId = rule.id;
      _nameCtrl.text = rule.name;
      _appliesToCtrl.text = rule.appliesTo;
      _discountCtrl.text = rule.discountPercentage;
      _status = rule.status == 'Inactive' ? 'Inactive' : 'Active';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _nameCtrl.clear();
      _appliesToCtrl.clear();
      _discountCtrl.clear();
      _status = 'Active';
    });
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty) {
      widget.onToast('Rule name is required.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(feesConfigRepositoryProvider);
      if (_editingId != null) {
        await repo.updateConcessionRule(
          _editingId!,
          name: _nameCtrl.text.trim(),
          appliesTo: _appliesToCtrl.text.trim(),
          discountPercentage: _discountCtrl.text.isEmpty ? '0' : _discountCtrl.text,
          status: _status,
        );
        widget.onToast('Concession rule updated.');
      } else {
        await repo.createConcessionRule(
          name: _nameCtrl.text.trim(),
          appliesTo: _appliesToCtrl.text.trim(),
          discountPercentage: _discountCtrl.text.isEmpty ? '0' : _discountCtrl.text,
          status: _status,
        );
        widget.onToast('Concession rule added.');
      }
      _cancelEdit();
      await _load();
    } on FeesConfigValidationException catch (e) {
      widget.onToast(e.fieldErrors.values.firstOrNull ?? e.message);
    } catch (_) {
      widget.onToast('Failed to save concession rule.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete(ConcessionRule rule) async {
    setState(() => _deletingId = rule.id);
    try {
      await ref.read(feesConfigRepositoryProvider).deleteConcessionRule(rule.id);
      widget.onToast('Concession rule deleted.');
      await _load();
    } catch (_) {
      widget.onToast('Failed to delete concession rule.');
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeeConfigCard(child: _buildForm()),
        const SizedBox(height: 16),
        _buildTable(),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_editingId != null ? 'Edit Concession Rule' : 'Create Concession Rule',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: feeConfigInk1)),
        const SizedBox(height: 3),
        const Text('Rows update immediately — each action maps to a feesApi call in production.', style: TextStyle(fontSize: 12.5, color: feeConfigInk3)),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FeeConfigLabel('RULE NAME'),
                TextField(controller: _nameCtrl, decoration: feeConfigInputDecoration(hint: 'Staff Ward 50%')),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FeeConfigLabel('APPLIES TO'),
                TextField(controller: _appliesToCtrl, decoration: feeConfigInputDecoration(hint: 'Tuition Fee')),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FeeConfigLabel('DISCOUNT %'),
                TextField(controller: _discountCtrl, keyboardType: TextInputType.number, decoration: feeConfigInputDecoration(hint: '50')),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FeeConfigLabel('STATUS'),
                FeeConfigSelect<String>(value: _status, items: const ['Active', 'Inactive'], labelOf: (v) => v, onChanged: (v) => setState(() => _status = v ?? 'Active')),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            FeeConfigPrimaryButton(label: _isSaving ? 'Saving...' : (_editingId != null ? 'Save Changes' : 'Add'), onPressed: _isSaving ? null : _handleSave),
            if (_editingId != null) ...[
              const SizedBox(width: 10),
              FeeConfigOutlineButton(label: 'Cancel', onPressed: _isSaving ? null : _cancelEdit),
            ],
          ],
        ),
      ],
    );
  }

  /// Column widths shared by the header row and every data row — matches
  /// web's real 5-column table exactly ("NAME", "SCOPE", "DISCOUNT",
  /// "STATUS", "ACTIONS" — see `FeeConfigurationPanel.tsx`'s
  /// `renderConcessionRules`). Wrapped in a horizontally-scrolling
  /// container so the fixed widths never overflow on a narrow screen.
  static const _colName = 150.0;
  static const _colScope = 140.0;
  static const _colDiscount = 64.0;
  static const _colStatus = 84.0;
  static const _colActions = 100.0;
  // Explicit gap between columns — column widths are sized to their content
  // now (not padded out to create a gutter), so the gap has to be its own
  // spacer or the columns would butt up against each other.
  static const _colGap = 12.0;
  // +32 accounts for the 16px horizontal padding on each side of the header/row Containers below.
  static const _tableWidth = _colName + _colScope + _colDiscount + _colStatus + _colActions + _colGap * 4 + 32;

  Widget _buildTable() {
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
                const Padding(padding: EdgeInsets.all(24), child: Text('Loading concession rules...', style: TextStyle(color: feeConfigInk2)))
              else if (_rows.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('No concession rules yet.', style: TextStyle(color: feeConfigInk2)))
              else
                for (var i = 0; i < _rows.length; i++) _buildRow(_rows[i], isLast: i == _rows.length - 1),
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
          SizedBox(width: _colName, child: Text('NAME', style: feeConfigThStyle)),
          SizedBox(width: _colGap),
          SizedBox(width: _colScope, child: Text('SCOPE', style: feeConfigThStyle)),
          SizedBox(width: _colGap),
          SizedBox(width: _colDiscount, child: Text('DISCOUNT', style: feeConfigThStyle)),
          SizedBox(width: _colGap),
          SizedBox(width: _colStatus, child: Text('STATUS', style: feeConfigThStyle)),
          SizedBox(width: _colGap),
          SizedBox(width: _colActions, child: Text('ACTIONS', style: feeConfigThStyle)),
        ],
      ),
    );
  }

  /// Each rule shown as one table row, fields lined up under their own
  /// column headings above — matches web's real table structure
  /// (`renderConcessionRules`) exactly rather than combining fields.
  Widget _buildRow(ConcessionRule rule, {required bool isLast}) {
    final deleting = _deletingId == rule.id;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : const BorderSide(color: feeConfigBorder))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: _colName, child: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: feeConfigInk1))),
          const SizedBox(width: _colGap),
          SizedBox(width: _colScope, child: Text(rule.appliesTo.isEmpty ? '—' : rule.appliesTo, style: feeConfigTdMuted)),
          const SizedBox(width: _colGap),
          SizedBox(width: _colDiscount, child: Text('${rule.discountPercentage}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: feeConfigInk1))),
          const SizedBox(width: _colGap),
          SizedBox(width: _colStatus, child: FeeConfigStatusPill(rule.status == 'Inactive' ? 'Inactive' : 'Active')),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _colActions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeeConfigOutlineButton(small: true, label: 'Edit', onPressed: () => _startEdit(rule)),
                const SizedBox(height: 8),
                FeeConfigDangerButton(small: true, label: deleting ? 'Deleting...' : 'Delete', onPressed: deleting ? null : () => _handleDelete(rule)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
