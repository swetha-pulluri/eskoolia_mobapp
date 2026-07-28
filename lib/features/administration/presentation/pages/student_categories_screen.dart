import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/student_category_entity.dart';
import '../providers/administration_provider.dart';
import '../providers/administration_list_state.dart' show adminErrorMessage;
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/web_button.dart';

/// Student Categories — converted from web `StudentCategoryManagerPanel.tsx`
/// (surfaced under System Config, reusing the Students module's own screen
/// on web). Sub-tab of System Config.
///
/// The web drawer/popover interactions (slide-in form panel, status profile
/// panel, "Agentic Summary" popover) are adapted to mobile bottom sheets —
/// the same interaction pattern (tap to open an overlay panel), just the
/// mobile-appropriate overlay shape instead of a desktop side drawer.
class StudentCategoriesScreen extends ConsumerStatefulWidget {
  const StudentCategoriesScreen({super.key});

  @override
  ConsumerState<StudentCategoriesScreen> createState() => _StudentCategoriesScreenState();
}

class _StudentCategoriesScreenState extends ConsumerState<StudentCategoriesScreen> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _generateDescriptionSuggestion(StudentCategoryEntity c) {
    final name = c.name.trim().isEmpty ? 'this category' : c.name.trim().toLowerCase();
    final count = c.studentsCount ?? 0;
    final usage = count > 0
        ? 'It currently groups $count enrolled student${count == 1 ? '' : 's'}.'
        : 'It can be used to group students consistently across the school workflow.';
    final codeLine = (c.code?.isNotEmpty ?? false) ? ' Code: ${c.code}.' : '';
    return 'Category for $name used in admissions, fees, and reporting.$codeLine $usage';
  }

  String _formatRelativeDate(DateTime at) {
    final mins = DateTime.now().difference(at).inMinutes;
    if (mins < 1) return 'Just now';
    if (mins < 60) return '$mins mins ago';
    final hours = mins ~/ 60;
    if (hours < 24) return '$hours hour${hours == 1 ? '' : 's'} ago';
    final days = hours ~/ 24;
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  Future<void> _openForm({StudentCategoryEntity? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final codeCtrl = TextEditingController(text: editing?.code ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    var status = editing?.status ?? 'active';
    final formKey = GlobalKey<FormState>();
    var dismissedSuggestion = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final suggestion = editing != null ? _generateDescriptionSuggestion(editing) : '';
            final showSuggestion = editing != null && descCtrl.text.trim().isEmpty && !dismissedSuggestion;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w500, height: 0.92, color: const Color(0xFF111827)),
                            children: [
                              TextSpan(text: editing == null ? 'New ' : 'Edit '),
                              TextSpan(text: 'category', style: GoogleFonts.playfairDisplay(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: const Color(0xFF5B3DF5))),
                            ],
                          ),
                        ),
                        const Text('Create a classification tag', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                        const SizedBox(height: 12),
                        AdminTextField(
                          label: 'Category name',
                          required: true,
                          controller: nameCtrl,
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
                          controller: codeCtrl,
                          maxLength: 30,
                          helper: 'Used in reports.',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Row(
                                children: [
                                  Switch(
                                    value: status == 'active',
                                    onChanged: (v) => setSheetState(() => status = v ? 'active' : 'inactive'),
                                    activeTrackColor: AppColors.successGreen,
                                  ),
                                  Icon(status == 'active' ? Icons.check_circle : Icons.cancel, size: 15, color: status == 'active' ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                                  const SizedBox(width: 4),
                                  Text(status == 'active' ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12.5, color: status == 'active' ? const Color(0xFF15803D) : const Color(0xFFB91C1C))),
                                ],
                              ),
                              const Text('Toggle category availability for admissions and reports.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        AdminTextField(
                          label: 'Description',
                          controller: descCtrl,
                          maxLines: 3,
                          maxLength: 500,
                          helper: 'Visible on admission forms.',
                          counterBuilder: (n) => '$n/500',
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        if (showSuggestion)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF3EEFF), border: Border.all(color: const Color(0xFFDDD6FE)), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('AI', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Smart suggested description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(suggestion, style: const TextStyle(fontSize: 12.5)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => setSheetState(() {
                                        descCtrl.text = suggestion;
                                      }),
                                      child: const Text('Apply suggestion', style: TextStyle(fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: () => setSheetState(() => dismissedSuggestion = true),
                                      child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (editing != null)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _confirmDelete(editing);
                                },
                                style: TextButton.styleFrom(foregroundColor: AppColors.dangerRed),
                                child: const Text('Delete'),
                              ),
                            const Spacer(),
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                            const SizedBox(width: 8),
                            WebButton(
                              label: 'Save changes',
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                final category = StudentCategoryEntity(
                                  name: nameCtrl.text.trim(),
                                  code: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                  status: status,
                                );
                                final notifier = ref.read(studentCategoryListProvider.notifier);
                                final ok = editing == null ? await notifier.add(category) : await notifier.edit(editing.id!, category);
                                if (ok && context.mounted) Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Mirrors `DeleteCategoryModal.tsx`'s "safe-delete" confirmation. Unlike
  /// web, this does NOT pre-branch on `c.studentsCount` — the real
  /// `/api/v1/students/categories/{id}/` list/CRUD endpoints never
  /// annotate `students_count` (`StudentCategoryViewSet.get_queryset`
  /// only annotates it for the separate `attention` filter branch), so the
  /// field is always missing/null from real data and a client pre-check
  /// would silently skip web's "Cannot Delete Category" flow even for
  /// categories that do have students. Instead: always attempt the delete,
  /// and if the backend rejects it (`destroy()` returns 400 "Cannot delete
  /// category as it is assigned to students"), show the conflict dialog
  /// with the Deactivate escape hatch as a reactive follow-up.
  Future<void> _confirmDelete(StudentCategoryEntity c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Delete Category?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                children: [
                  const TextSpan(text: 'Are you sure you want to permanently delete '),
                  TextSpan(text: '"${c.name}"', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('This action cannot be undone. The category will be permanently removed from the system.', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || c.id == null) return;

    final notifier = ref.read(studentCategoryListProvider.notifier);
    final ok = await notifier.remove(c.id!);
    if (ok || !mounted) return;

    final message = ref.read(studentCategoryListProvider).error ?? '';
    if (!message.toLowerCase().contains('assigned to students')) return;

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Cannot Delete Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            const Text('Please reassign students first or deactivate this category instead.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            onPressed: () => Navigator.of(context).pop('deactivate'),
            child: const Text('Deactivate Category'),
          ),
        ],
      ),
    );
    if (action == 'deactivate') {
      await ref.read(studentCategoryListProvider.notifier).edit(c.id!, c.copyWith(status: 'inactive'));
      ref.invalidate(studentCategorySummaryProvider);
    }
  }

  Future<void> _confirmStatusChange(StudentCategoryEntity c, String nextStatus) async {
    final willDeactivate = nextStatus == 'inactive';
    final confirmed = await showAdminConfirmDialog(
      context,
      title: willDeactivate ? 'Confirm Deactivation' : 'Confirm Activation',
      message: willDeactivate ? 'Are you sure you want to deactivate this category?' : 'Are you sure you want to activate this category?',
      confirmLabel: willDeactivate ? 'Deactivate' : 'Activate',
    );
    if (confirmed && c.id != null) {
      await ref.read(studentCategoryListProvider.notifier).edit(c.id!, c.copyWith(status: nextStatus));
      ref.invalidate(studentCategorySummaryProvider);
    }
  }

  void _openStatusDrawer(StudentCategoryEntity c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c.name, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w500, height: 1.0, color: const Color(0xFF111827)))),
                      _statusPill(c.isActive),
                    ],
                  ),
                  const Text('Category profile', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                  const SizedBox(height: 12),
                  const Text('Overview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  _drawerRow('Code', c.code ?? '-'),
                  _drawerRow('Students', '${c.studentsCount ?? 0}'),
                  _drawerRow('Status', c.isActive ? 'Active' : 'Inactive'),
                  _drawerRow('Created on', c.createdAt ?? '-'),
                  _drawerRow('Updated by', c.updatedBy ?? 'Admin'),
                  const SizedBox(height: 10),
                  const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(c.description?.isNotEmpty == true ? c.description! : 'No description added yet.', style: const TextStyle(fontSize: 12.5)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openForm(editing: c);
                          },
                          child: const Text('Edit profile'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: WebButton(
                          label: c.isActive ? 'Deactivate' : 'Activate',
                          color: c.isActive ? AppColors.dangerRed : AppColors.primaryPurple,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _confirmStatusChange(c, c.isActive ? 'inactive' : 'active');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openViewSummary(StudentCategoryEntity c, List<StudentCategoryEntity> all) {
    final total = all.fold<int>(0, (sum, x) => sum + (x.studentsCount ?? 0));
    final share = total == 0 ? '0.0%' : '${((c.studentsCount ?? 0) / total * 100).toStringAsFixed(1)}%';
    final ordered = List.of(all)..sort((a, b) => (b.studentsCount ?? 0).compareTo(a.studentsCount ?? 0));
    final rank = ordered.indexWhere((x) => x.id == c.id) + 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agentic Summary', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w500, height: 1.1, color: const Color(0xFF111827))),
                    const Text('Quick operational insights', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    const SizedBox(height: 10),
                    _drawerRow('Category', c.name),
                    _drawerRow('Students enrolled', '${c.studentsCount ?? 0}'),
                    _drawerRow('Share of total', share),
                    _drawerRow('Rank by size', '#$rank of ${all.length}'),
                    _drawerRow('Used in modules', 'Admissions, Fees, Reports'),
                    const Divider(height: 20),
                    Text(
                      (c.studentsCount ?? 0) > 50 ? 'High usage. Avoid renaming as it impacts reports.' : 'Moderate usage. You can edit safely with review.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drawerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusPill(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        border: Border.all(color: active ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: active ? const Color(0xFF0F766E) : const Color(0xFF64748B))),
    );
  }

  Future<void> _bulkStatus(String nextStatus) async {
    if (_selectedIds.isEmpty) return;
    final n = _selectedIds.length;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: nextStatus == 'active' ? 'Confirm Activation' : 'Confirm Deactivation',
      message: 'Are you sure you want to ${nextStatus == 'active' ? 'activate' : 'deactivate'} $n selected categor${n == 1 ? 'y' : 'ies'}?',
      confirmLabel: nextStatus == 'active' ? 'Activate' : 'Deactivate',
    );
    if (!confirmed) return;
    final repository = ref.read(administrationRepositoryProvider);
    try {
      await repository.bulkUpdateStudentCategoryStatus(_selectedIds.toList(), nextStatus);
      ref.invalidate(studentCategoryListProvider);
      ref.invalidate(studentCategorySummaryProvider);
      setState(() => _selectedIds.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final n = _selectedIds.length;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete $n selected categories?',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    final repository = ref.read(administrationRepositoryProvider);
    try {
      // `bulk-delete` blocks the whole batch (400) if any selected
      // category is assigned to students — matches backend semantics.
      await repository.bulkDeleteStudentCategories(_selectedIds.toList());
      ref.invalidate(studentCategoryListProvider);
      ref.invalidate(studentCategorySummaryProvider);
      setState(() => _selectedIds.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentCategoryListProvider);
    final summaryAsync = ref.watch(studentCategorySummaryProvider);
    final summary = summaryAsync.maybeWhen(
      data: (s) => s,
      orElse: () => const StudentCategorySummary(totalCount: 0, activeCount: 0, inactiveCount: 0, attentionCount: 0, topTotalStudents: 0, topCategories: []),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15, color: const Color(0xFF0F172A)),
                        children: [
                          const TextSpan(text: 'Student '),
                          TextSpan(text: 'Categories', style: GoogleFonts.playfairDisplay(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: const Color(0xFF6C3CE1))),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Classification tags used across admissions, fee rules, and reporting.', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WebButton(label: '+ New Category', onPressed: () => _openForm()),
          const SizedBox(height: 16),
          _summaryCards(summary),
          const SizedBox(height: 16),
          AdminSectionCard(
            title: 'Categories',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(hintText: 'Search categories or codes...', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                    onChanged: (v) => ref.read(studentCategoryListProvider.notifier).setSearch(v),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('All', '', summary.totalCount),
                    _filterChip('Active', 'active', summary.activeCount),
                    _filterChip('Inactive', 'inactive', summary.inactiveCount),
                    _filterChip('AI flagged', 'attention', summary.attentionCount, icon: Icons.auto_awesome),
                    WebButton(label: 'Export', color: const Color(0xFF64748B), onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export completed successfully.')));
                    }),
                  ],
                ),
                if (_selectedIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text('${_selectedIds.length} selected', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        WebButton(label: 'Activate', onPressed: () => _bulkStatus('active')),
                        WebButton(label: 'Deactivate', color: const Color(0xFF6B7280), onPressed: () => _bulkStatus('inactive')),
                        WebButton(label: 'Delete', color: AppColors.dangerRed, onPressed: _bulkDelete),
                        TextButton(onPressed: () => setState(() => _selectedIds.clear()), child: const Text('Clear')),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                if (state.error != null) const AdminMessageBanner(error: 'Unable to load categories.'),
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No categories found.',
                  columns: const [
                    AdminColumn('', width: 36),
                    AdminColumn('Category', width: 120),
                    AdminColumn('Code', width: 70),
                    AdminColumn('Students', width: 70),
                    AdminColumn('Status', width: 90),
                    AdminColumn('Description', width: 140),
                    AdminColumn('Actions', width: 110),
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

  Widget _summaryCards(StudentCategorySummary summary) {
    final topMax = summary.topCategories.isEmpty ? 1 : summary.topCategories.map((c) => c.studentsCount).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        _summaryCard(
          label: 'Total Categories',
          icon: Icons.grid_view_outlined,
          value: '${summary.totalCount}',
          meta: '${summary.activeCount} active · ${summary.attentionCount} needs attention',
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Students by Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.4)),
                  Icon(Icons.bar_chart, size: 16, color: AppColors.primaryPurple),
                ],
              ),
              const SizedBox(height: 10),
              summary.topCategories.isEmpty
                  ? const Text('No data', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
                  : SizedBox(
                      height: 38,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: summary.topCategories.asMap().entries.map((entry) {
                          final ratio = topMax > 0 ? entry.value.studentsCount / topMax : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: FractionallySizedBox(
                                heightFactor: ratio.clamp(0.08, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: entry.key == 0 ? AppColors.primaryPurple : const Color(0xFFD9DDFF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
              const SizedBox(height: 8),
              Text(
                summary.topCategories.isEmpty
                    ? 'Top total: ${summary.topTotalStudents} students'
                    : 'Top: ${summary.topCategories.first.name} · ${summary.topCategories.first.studentsCount} students',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Recent Activity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.4)),
                  Icon(Icons.schedule, size: 16, color: AppColors.primaryPurple),
                ],
              ),
              const SizedBox(height: 8),
              if (summary.recentActivity.isEmpty)
                const Text('No recent updates', style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary))
              else
                ...summary.recentActivity.take(3).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                          children: [
                            TextSpan(text: item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ' ${item.action} · ${_formatRelativeDate(item.at)}', style: const TextStyle(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({required String label, required IconData icon, required String value, required String meta}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.4)),
              Icon(icon, size: 16, color: AppColors.primaryPurple),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.playfairDisplay(fontSize: 40, fontWeight: FontWeight.w500, letterSpacing: 0.2, height: 1.0, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count, {IconData? icon}) {
    final selected = ref.watch(studentCategoryStatusFilterProvider) == value;
    return ChoiceChip(
      avatar: icon != null ? Icon(icon, size: 14, color: selected ? AppColors.primaryPurple : AppColors.textSecondary) : null,
      label: Text('$label $count', style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => ref.read(studentCategoryStatusFilterProvider.notifier).state = value,
      selectedColor: AppColors.purpleSoft,
      labelStyle: TextStyle(color: selected ? AppColors.primaryPurple : AppColors.textSecondary),
    );
  }

  List<List<Widget>> _buildRows(dynamic state) {
    final notifier = ref.read(studentCategoryListProvider.notifier);
    final visible = notifier.filtered((c, q) => c.name.toLowerCase().contains(q) || (c.code ?? '').toLowerCase().contains(q));
    final all = List<StudentCategoryEntity>.from(state.items as List);

    return List.generate(visible.length, (index) {
      final c = visible[index];
      return [
        Checkbox(
          value: _selectedIds.contains(c.id),
          onChanged: (v) => setState(() {
            if (v == true) {
              _selectedIds.add(c.id!);
            } else {
              _selectedIds.remove(c.id);
            }
          }),
        ),
        Text(c.name, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(c.code?.isNotEmpty == true ? c.code! : '-', style: const TextStyle(fontSize: 12.5)),
        Text('${c.studentsCount ?? 0}', style: const TextStyle(fontSize: 12.5)),
        InkWell(onTap: () => _openStatusDrawer(c), child: _statusPill(c.isActive)),
        Text(c.description?.isNotEmpty == true ? c.description! : 'No description',
            style: TextStyle(fontSize: 12.5, fontStyle: c.description?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic, color: c.description?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textTertiary),
            overflow: TextOverflow.ellipsis),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.visibility_outlined, size: 17), tooltip: 'View', onPressed: () => _openViewSummary(c, all), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 17), tooltip: 'Edit', onPressed: () => _openForm(editing: c), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
            IconButton(icon: const Icon(Icons.delete_outline, size: 17), tooltip: 'Delete', onPressed: () => _confirmDelete(c), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
          ],
        ),
      ];
    });
  }
}
