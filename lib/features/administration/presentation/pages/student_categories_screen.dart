import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/student_category_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';

/// Student Categories — converted from web `StudentCategoryManagerPanel.tsx`
/// (surfaced under System Config, reusing the Students module's own
/// screen on web). Sub-tab of System Config.
///
/// Scoped for this pass: core CRUD (name/code/status/description), search,
/// status filter, delete confirmation. NOT yet ported: AI description
/// suggestion, bulk select/activate/deactivate/delete, CSV export, the
/// "Agentic Summary" popover and the read-only profile drawer — these are
/// real web features but a larger follow-up; flagged rather than faked.
class StudentCategoriesScreen extends ConsumerStatefulWidget {
  const StudentCategoriesScreen({super.key});

  @override
  ConsumerState<StudentCategoriesScreen> createState() => _StudentCategoriesScreenState();
}

class _StudentCategoriesScreenState extends ConsumerState<StudentCategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _status = 'active';
  int? _editingId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descriptionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _codeCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _status = 'active';
      _editingId = null;
    });
  }

  void _loadForEdit(StudentCategoryEntity c) {
    setState(() {
      _editingId = c.id;
      _nameCtrl.text = c.name;
      _codeCtrl.text = c.code ?? '';
      _descriptionCtrl.text = c.description ?? '';
      _status = c.status;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final category = StudentCategoryEntity(
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      status: _status,
    );

    final notifier = ref.read(studentCategoryListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(category) : await notifier.edit(_editingId!, category);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Record created successfully.' : 'Record updated successfully.')),
      );
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentCategoryListProvider);
    final isSaving = state.savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionCard(
            title: _editingId == null ? 'New Category' : 'Edit Category',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(
                    label: 'Category name',
                    required: true,
                    controller: _nameCtrl,
                    maxLength: 100,
                    helper: 'Letters, numbers and spaces.',
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Category name is required';
                      if (value.length < 2) return 'Category name must be at least 2 characters';
                      if (!RegExp(r'^[A-Za-z0-9\s]+$').hasMatch(value)) return 'Use letters, numbers, and spaces only';
                      return null;
                    },
                  ),
                  AdminTextField(
                    label: 'Short code',
                    controller: _codeCtrl,
                    maxLength: 30,
                    helper: 'Used in reports.',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(width: 12),
                        Switch(
                          value: _status == 'active',
                          onChanged: (v) => setState(() => _status = v ? 'active' : 'inactive'),
                          activeTrackColor: AppColors.successGreen,
                        ),
                        Icon(
                          _status == 'active' ? Icons.check_circle : Icons.cancel,
                          size: 15,
                          color: _status == 'active' ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _status == 'active' ? 'Active' : 'Inactive',
                          style: TextStyle(fontSize: 12.5, color: _status == 'active' ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                  AdminTextField(
                    label: 'Description',
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    helper: 'Visible on admission forms.',
                    counterBuilder: (n) => '$n/500',
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                        child: Text(isSaving ? 'Saving...' : 'Save changes'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _resetForm, child: const Text('Cancel')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AdminSectionCard(
            title: 'Student Categories',
            trailing: SizedBox(
              width: 160,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Search categories or codes...', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => ref.read(studentCategoryListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip('All', ''),
                    _filterChip('Active', 'active'),
                    _filterChip('Inactive', 'inactive'),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.error != null) const AdminMessageBanner(error: 'Unable to load categories.'),
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No categories found.',
                  columns: const [
                    AdminColumn('Category', width: 130),
                    AdminColumn('Code', width: 80),
                    AdminColumn('Students', width: 80),
                    AdminColumn('Status', width: 90),
                    AdminColumn('Description', width: 150),
                    AdminColumn('Actions', width: 70),
                  ],
                  rows: _buildRows(state),
                ),
                AdminPaginationBar(
                  page: state.page,
                  pageSize: state.pageSize,
                  totalCount: state.totalCount,
                  onPageChange: (p) => ref.read(studentCategoryListProvider.notifier).setPage(p),
                  onPageSizeChange: (s) => ref.read(studentCategoryListProvider.notifier).setPageSize(s),
                  pageSizeOptions: const [10, 25],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = ref.watch(studentCategoryStatusFilterProvider) == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => ref.read(studentCategoryStatusFilterProvider.notifier).state = value,
      selectedColor: AppColors.purpleSoft,
      labelStyle: TextStyle(color: selected ? AppColors.primaryPurple : AppColors.textSecondary),
    );
  }

  List<List<Widget>> _buildRows(dynamic state) {
    final notifier = ref.read(studentCategoryListProvider.notifier);
    final visible = notifier.filtered((c, q) => c.name.toLowerCase().contains(q) || (c.code ?? '').toLowerCase().contains(q));

    return List.generate(visible.length, (index) {
      final c = visible[index];
      return [
        Text(c.name, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(c.code?.isNotEmpty == true ? c.code! : '-', style: const TextStyle(fontSize: 12.5)),
        Text('${c.studentsCount ?? 0}', style: const TextStyle(fontSize: 12.5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.isActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
            border: Border.all(color: c.isActive ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            c.isActive ? 'Active' : 'Inactive',
            style: TextStyle(fontSize: 11, color: c.isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B)),
          ),
        ),
        Text(c.description?.isNotEmpty == true ? c.description! : 'No description',
            style: TextStyle(fontSize: 12.5, fontStyle: c.description?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic, color: c.description?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textTertiary),
            overflow: TextOverflow.ellipsis),
        AdminRowActions(
          onEdit: () => _loadForEdit(c),
          isDeleting: state.deletingId == c.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
              context,
              title: 'Delete Category?',
              message: 'Are you sure you want to permanently delete "${c.name}"? This action cannot be undone.',
              confirmLabel: 'Delete Permanently',
            );
            if (confirmed && c.id != null) {
              await ref.read(studentCategoryListProvider.notifier).remove(c.id!);
            }
          },
        ),
      ];
    });
  }
}
