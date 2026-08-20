import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/school_tenancy_provider.dart';

/// Mobile equivalent of web's `NewPlanDrawer` (`billing/NewPlanDrawer.tsx`)
/// — real `POST`/`PATCH /api/super-admin/billing/plans/` create/update calls,
/// auto-slugged plan code (unless overridden), and a dynamic features list.
class PlanFormSheet extends ConsumerStatefulWidget {
  const PlanFormSheet({super.key, this.existing});

  /// When provided, the sheet is in EDIT mode; code becomes immutable.
  final SubscriptionPlanEntity? existing;

  @override
  ConsumerState<PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends ConsumerState<PlanFormSheet> {
  late final bool _isEdit = widget.existing != null;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '50');
  String _billingCycle = 'monthly';
  bool _popular = false;
  bool _codeEdited = false;
  bool _submitting = false;
  final List<TextEditingController> _featureControllers = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _codeController.text = existing.code;
      _codeEdited = true;
      _descriptionController.text = existing.description;
      _priceController.text = existing.priceInr == existing.priceInr.roundToDouble()
          ? existing.priceInr.toStringAsFixed(0)
          : existing.priceInr.toString();
      _billingCycle = existing.billingCycle.isEmpty ? 'monthly' : existing.billingCycle;
      _popular = existing.popular;
      _sortOrderController.text = existing.sortOrder.toString();
      _featureControllers.addAll(
        existing.features.isEmpty ? [TextEditingController()] : existing.features.map((f) => TextEditingController(text: f)),
      );
    } else {
      _featureControllers.add(TextEditingController());
    }
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sortOrderController.dispose();
    for (final c in _featureControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNameChanged() {
    if (_codeEdited) return;
    setState(() => _codeController.text = _slugify(_nameController.text));
  }

  /// Matches web's `slugify()` exactly (`NewPlanDrawer.tsx:51-58`).
  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return replaced.length > 64 ? replaced.substring(0, 64) : replaced;
  }

  double get _priceInr => double.tryParse(_priceController.text.trim()) ?? 0;

  List<String> get _cleanFeatures => _featureControllers.map((c) => c.text.trim()).where((f) => f.isNotEmpty).toList();

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _codeController.text.trim().isNotEmpty &&
      _priceInr > 0 &&
      _cleanFeatures.isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final basePayload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price_inr': _priceInr,
        'billing_cycle': _billingCycle,
        'popular': _popular,
        'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
        'features': _cleanFeatures,
        'is_active': true,
      };

      final repository = ref.read(schoolTenancyRepositoryProvider);
      final saved = _isEdit
          ? await repository.updatePlan(widget.existing!.code, basePayload)
          : await repository.createPlan({...basePayload, 'code': _codeController.text.trim()});

      ref.invalidate(plansProvider);
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gstAmount = _priceInr * 0.18;
    final grandTotal = _priceInr + gstAmount;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.sell_outlined, size: 17, color: AppColors.purpleDeep),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_isEdit ? 'Edit ' : 'New ', style: AppTextStyles.sectionTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
                            Text('Subscription plan', style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 17)),
                          ],
                        ),
                        Text(
                          'India-priced · GST 18% under SAC 998313 (Education software)',
                          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHead('1', 'Plan basics'),
                    const SizedBox(height: 12),
                    Text('PLAN NAME', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: _fieldDecoration().copyWith(hintText: 'e.g. Growth'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    Text('CODE', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _codeController,
                      enabled: !_isEdit,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: _fieldDecoration().copyWith(hintText: 'growth'),
                      onChanged: (v) => setState(() {
                        _codeEdited = true;
                        final slug = _slugify(v);
                        if (slug != v) {
                          _codeController.value = TextEditingValue(text: slug, selection: TextSelection.collapsed(offset: slug.length));
                        }
                      }),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isEdit ? 'Code is immutable after creation.' : 'Auto-generated from name; you can override.',
                      style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
                    ),
                    const SizedBox(height: 14),

                    Text('DESCRIPTION', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      decoration: _fieldDecoration().copyWith(hintText: 'One-line tagline shown on the plan card.'),
                    ),
                    const SizedBox(height: 14),

                    Text('BILLING CYCLE', style: _label),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _billingCycle,
                      items: const [
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                      ],
                      onChanged: (v) => setState(() => _billingCycle = v ?? 'monthly'),
                    ),
                    const SizedBox(height: 14),

                    Text('POPULAR?', style: _label),
                    const SizedBox(height: 6),
                    AppDropdown<bool>(
                      value: _popular,
                      items: const [
                        DropdownMenuItem(value: false, child: Text('No')),
                        DropdownMenuItem(value: true, child: Text('Yes')),
                      ],
                      onChanged: (v) => setState(() => _popular = v ?? false),
                    ),
                    const SizedBox(height: 3),
                    Text('Highlights the card with a \'Popular\' badge.', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5)),
                    const SizedBox(height: 14),

                    Text('SORT ORDER', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _fieldDecoration(),
                    ),
                    const SizedBox(height: 3),
                    Text('Lower numbers appear first.', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5)),

                    const SizedBox(height: 16),
                    _sectionHead('2', 'Pricing'),
                    const SizedBox(height: 12),
                    Text('PRICE (₹) · EXCLUDING GST', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _fieldDecoration().copyWith(hintText: '0.00'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GST 18% under SAC 998313 will be applied automatically on invoices that use this plan. '
                      '+ GST 18% = ${formatINR(gstAmount, compact: false)} · Total ${formatINR(grandTotal, compact: false)}',
                      style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, height: 1.4),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionHead('3', 'Features'),
                        TextButton.icon(
                          onPressed: () => setState(() => _featureControllers.add(TextEditingController())),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add feature'),
                        ),
                      ],
                    ),
                    ..._featureControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: _fieldDecoration().copyWith(hintText: 'e.g. Up to 500 students'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: _featureControllers.length == 1
                                  ? null
                                  : () => setState(() {
                                        _featureControllers.removeAt(index).dispose();
                                      }),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
                    _sectionHead('4', 'Preview'),
                    const SizedBox(height: 12),
                    _buildPreview(gstAmount, grandTotal),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: Text(_submitting ? 'Saving…' : (_isEdit ? 'Save changes' : 'Save plan')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Live preview card — matches web's real "Preview" aside exactly
  /// (`NewPlanDrawer.tsx:388-431`): name/code, "Popular" badge, description,
  /// price with billing-cycle suffix, GST + total line, then the features
  /// list with checkmarks — all read live off the same form state.
  Widget _buildPreview(double gstAmount, double grandTotal) {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final description = _descriptionController.text.trim();
    final features = _cleanFeatures;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: _popular ? AppColors.primaryPurple : AppColors.borderPrimary, width: _popular ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Plan name' : name,
                  style: AppTextStyles.boardLabel.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (_popular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 10, color: AppColors.purpleDeep),
                      const SizedBox(width: 3),
                      Text('Popular', style: AppTextStyles.chipLabel(color: AppColors.purpleDeep).copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          Text(code.isEmpty ? 'code' : code, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontFamily: 'monospace')),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: AppTextStyles.boardLabel.copyWith(fontSize: 12)),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatINR(_priceInr, compact: false, fraction: 0),
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 22, fontFamily: 'serif', fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Text('/ ${_billingCycle == 'monthly' ? 'mo' : 'yr'}', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11)),
            ],
          ),
          Text(
            '+ GST 18% = ${formatINR(gstAmount, compact: false)} · Total ${formatINR(grandTotal, compact: false)}',
            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check, size: 12, color: AppColors.primaryPurple),
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(f, style: AppTextStyles.boardLabel.copyWith(fontSize: 12))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle get _label => AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6);

  Widget _sectionHead(String num, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(6)),
          child: Text(num, style: AppTextStyles.chipLabel(color: AppColors.purpleDeep).copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.bgSecondary,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
