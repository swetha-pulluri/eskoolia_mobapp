import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/late_fee_rule.dart';
import '../../domain/repositories/fees_config_repository.dart';
import '../providers/fees_config_providers.dart';
import 'fee_config_styles.dart';

/// Late Fee Rules tab — converted from FeeConfigurationPanel.tsx's
/// `renderLateFeeRules`. `penaltyRule` is free text (e.g. "Rs. 50 daily") —
/// there is no structured penalty-method/calculator UI in the real
/// component (that only exists in this tab's dead, never-rendered
/// `HELP_CONTENT` copy).
class LateFeeRulesTab extends ConsumerStatefulWidget {
  final void Function(String message) onToast;
  const LateFeeRulesTab({super.key, required this.onToast});

  @override
  ConsumerState<LateFeeRulesTab> createState() => _LateFeeRulesTabState();
}

class _LateFeeRulesTabState extends ConsumerState<LateFeeRulesTab> {
  List<LateFeeRule> _rows = [];
  bool _isLoading = false;
  bool _isSaving = false;
  int? _deletingId;
  int? _editingId;

  final _nameCtrl = TextEditingController();
  final _graceCtrl = TextEditingController();
  final _penaltyCtrl = TextEditingController();
  final _capCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _graceCtrl.dispose();
    _penaltyCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final rows = await ref.read(feesConfigRepositoryProvider).fetchLateFeeRules();
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) widget.onToast('Unable to load late fee rules.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEdit(LateFeeRule rule) {
    setState(() {
      _editingId = rule.id;
      _nameCtrl.text = rule.name;
      _graceCtrl.text = rule.gracePeriodDays == 0 ? '' : rule.gracePeriodDays.toString();
      _penaltyCtrl.text = rule.penaltyRule;
      _capCtrl.text = rule.capAmount ?? '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _nameCtrl.clear();
      _graceCtrl.clear();
      _penaltyCtrl.clear();
      _capCtrl.clear();
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
      final capText = _capCtrl.text.trim();
      if (_editingId != null) {
        await repo.updateLateFeeRule(
          _editingId!,
          name: _nameCtrl.text.trim(),
          gracePeriodDays: int.tryParse(_graceCtrl.text) ?? 0,
          penaltyRule: _penaltyCtrl.text.trim(),
          capAmount: capText.isEmpty ? null : capText,
        );
        widget.onToast('Late fee rule updated.');
      } else {
        await repo.createLateFeeRule(
          name: _nameCtrl.text.trim(),
          gracePeriodDays: int.tryParse(_graceCtrl.text) ?? 0,
          penaltyRule: _penaltyCtrl.text.trim(),
          capAmount: capText.isEmpty ? null : capText,
        );
        widget.onToast('Late fee rule added.');
      }
      _cancelEdit();
      await _load();
    } on FeesConfigValidationException catch (e) {
      widget.onToast(e.fieldErrors.values.firstOrNull ?? e.message);
    } catch (_) {
      widget.onToast('Failed to save late fee rule.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete(LateFeeRule rule) async {
    setState(() => _deletingId = rule.id);
    try {
      await ref.read(feesConfigRepositoryProvider).deleteLateFeeRule(rule.id);
      widget.onToast('Late fee rule deleted.');
      await _load();
    } catch (_) {
      widget.onToast('Failed to delete late fee rule.');
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
        Text(_editingId != null ? 'Edit Late Fee Rule' : 'Create Late Fee Rule',
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
                TextField(controller: _nameCtrl, decoration: feeConfigInputDecoration(hint: 'Tuition late rule')),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FeeConfigLabel('GRACE PERIOD (DAYS)'),
                TextField(controller: _graceCtrl, keyboardType: TextInputType.number, decoration: feeConfigInputDecoration(hint: '7')),
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
                const FeeConfigLabel('PENALTY'),
                TextField(controller: _penaltyCtrl, decoration: feeConfigInputDecoration(hint: 'Rs. 50 daily')),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FeeConfigLabel('CAP AMOUNT'),
                TextField(controller: _capCtrl, keyboardType: TextInputType.number, decoration: feeConfigInputDecoration(hint: '1500')),
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

  Widget _buildTable() {
    return Container(
      decoration: feeConfigCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF8F8FB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('NAME / GRACE', style: feeConfigThStyle)),
                Expanded(flex: 3, child: Text('PENALTY / CAP', style: feeConfigThStyle)),
                Expanded(flex: 2, child: Text('ACTIONS', style: feeConfigThStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(24), child: Text('Loading late fee rules...', style: TextStyle(color: feeConfigInk2)))
          else if (_rows.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No late fee rules yet.', style: TextStyle(color: feeConfigInk2)))
          else
            for (final rule in _rows) _buildRow(rule),
        ],
      ),
    );
  }

  Widget _buildRow(LateFeeRule rule) {
    final deleting = _deletingId == rule.id;
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
                Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: feeConfigInk1)),
                Text('${rule.gracePeriodDays} days', style: feeConfigTdMuted),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.penaltyRule.isEmpty ? '—' : rule.penaltyRule, style: feeConfigTdMuted),
                Text(rule.capAmount ?? '—', style: feeConfigTdMuted),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
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
