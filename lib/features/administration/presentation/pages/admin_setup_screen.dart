import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_breadcrumb_header.dart';

/// Admin Setup — converted from web `AdminSetupPanel.tsx`. Manages the 4
/// lookup "types" (Purpose / Complaint Type / Source / Reference) used as
/// dropdown options in Visitor Book / Complaints. Sub-tab of System Config.
class AdminSetupScreen extends ConsumerStatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  ConsumerState<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends ConsumerState<AdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _type;
  int? _editingId;
  final Set<String> _expanded = {'1'};

  static const _typeAccent = {
    '1': Color(0xFF7C83DB),
    '2': Color(0xFFE8849A),
    '3': Color(0xFF5AB88D),
    '4': Color(0xFFD4A54A),
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _type = null;
      _editingId = null;
    });
  }

  void _loadForEdit(AdminSetupEntity e) {
    setState(() {
      _editingId = e.id;
      _type = e.type;
      _nameCtrl.text = e.name;
      _descriptionCtrl.text = e.description ?? '';
    });
  }

  bool _isMeaningless(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;
    if (RegExp(r'^(.)\1*$').hasMatch(v)) return true;
    final letters = v.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 2) return true;
    return false;
  }

  Future<void> _submit() async {
    if (_type == null) {
      _showFieldError('Please select a type.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final entry = AdminSetupEntity(
      type: _type!,
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
    );

    final notifier = ref.read(adminSetupListProvider(_type!).notifier);
    final ok = _editingId == null ? await notifier.add(entry) : await notifier.edit(_editingId!, entry);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Record created successfully.' : 'Record updated successfully.')),
      );
      _resetForm();
    }
  }

  void _showFieldError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.dangerRed));
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = _type != null && ref.watch(adminSetupListProvider(_type!)).savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Admin Setup'),
          AdminSectionCard(
            title: _editingId == null ? 'Add Admin Setup' : 'Edit Admin Setup',
            borderRadius: 14,
            padding: const EdgeInsets.all(24),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
              BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
            ],
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminDropdownField<String>(
                    label: 'Type',
                    required: true,
                    value: _type,
                    hint: '-- Select a type --',
                    helper: 'Select the category type for this admin setup entry.',
                    items: AdminSetupEntity.typeLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v),
                  ),
                  AdminTextField(
                    label: 'Name',
                    required: true,
                    controller: _nameCtrl,
                    maxLength: 100,
                    helper: 'Enter a meaningful name (3-100 characters). Must start with a letter.',
                    counterBuilder: (n) => '$n / 100',
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Name is required.';
                      if (value.length < 3) return 'Name must be at least 3 characters.';
                      if (!RegExp(r'^[A-Za-z]').hasMatch(value)) return 'Name must start with a letter.';
                      if (_isMeaningless(value)) return 'Enter a meaningful name. Avoid repeated or random characters.';
                      return null;
                    },
                  ),
                  AdminTextField(
                    label: 'Description',
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    helper: 'Optional: Brief description (5-500 chars). Avoid meaningless text.',
                    counterBuilder: (n) => '$n / 500',
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (value.length < 5) return 'Description must be at least 5 characters.';
                      return null;
                    },
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                        child: Text(isSaving ? 'Saving...' : (_editingId == null ? 'Save' : 'Update')),
                      ),
                      if (_editingId != null) ...[
                        const SizedBox(width: 8),
                        TextButton(onPressed: _resetForm, child: const Text('Cancel')),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          AdminSectionCard(
            title: 'Admin Setup List',
            borderRadius: 14,
            padding: const EdgeInsets.all(24),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
              BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
            ],
            child: Column(
              children: AdminSetupEntity.typeLabels.entries.map((entry) => _typeAccordion(entry.key, entry.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeAccordion(String type, String label) {
    final state = ref.watch(adminSetupListProvider(type));
    final isOpen = _expanded.contains(type);
    final accent = _typeAccent[type]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 4), top: const BorderSide(color: AppColors.borderPrimary), right: const BorderSide(color: AppColors.borderPrimary), bottom: const BorderSide(color: AppColors.borderPrimary)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => isOpen ? _expanded.remove(type) : _expanded.add(type)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: accent))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text('${state.totalCount} items', style: TextStyle(fontSize: 11, color: accent)),
                  ),
                  const SizedBox(width: 8),
                  Icon(isOpen ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: state.isLoading
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator())
                  : state.items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text('No entries yet.', style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.textTertiary)),
                        )
                      : Column(
                          children: [
                            ...state.items.map((e) => _itemRow(type, e)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Page ${state.page} of ${state.totalPages}', style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: state.page > 1 ? () => ref.read(adminSetupListProvider(type).notifier).setPage(state.page - 1) : null,
                                      child: const Text('Previous', style: TextStyle(fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: state.page < state.totalPages ? () => ref.read(adminSetupListProvider(type).notifier).setPage(state.page + 1) : null,
                                      child: const Text('Next', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
        ],
      ),
    );
  }

  Widget _itemRow(String type, AdminSetupEntity e) {
    final state = ref.watch(adminSetupListProvider(type));
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(e.description?.isNotEmpty == true ? e.description! : 'No description', style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryPurple),
            onPressed: () => _loadForEdit(e),
            tooltip: 'Edit',
          ),
          state.deletingId == e.id
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.dangerRed),
                  tooltip: 'Delete',
                  onPressed: () async {
                    final confirmed = await showAdminConfirmDialog(
                      context,
                      message: 'Are you sure to delete this admin setup entry?',
                    );
                    if (confirmed && e.id != null) {
                      await ref.read(adminSetupListProvider(type).notifier).remove(e.id!);
                    }
                  },
                ),
        ],
      ),
    );
  }
}
