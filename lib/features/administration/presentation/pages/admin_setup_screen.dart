import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/admin_setup_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_stepper_shell.dart';

/// Admin Setup — converted from the real, currently-shipped web source
/// `AdminSetupPanel.tsx`. Only a 2-step numbered nav (no Smart Filter step,
/// unlike the other stepper screens): 01 Add/Edit Admin Setup, 02 Admin
/// Setup List. Client-side validation was relaxed on this redesign (no more
/// min-length/meaningless-text/letter-start checks — just "Type selected" +
/// "Name not empty"). Each category accordion has its own real per-category
/// pagination (Previous/Next + page-size select), matching web's own
/// `loadTypePage`/independent-per-type pager exactly — confirmed directly
/// against the live `AdminSetupPanel.tsx` source (default page size 5,
/// selectable 5/10/25/50).
class AdminSetupScreen extends ConsumerStatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  ConsumerState<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends ConsumerState<AdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  final _addKey = GlobalKey();
  final _listKey = GlobalKey();
  int _activeTab = 0;

  String? _type;
  int? _editingId;
  String? _formBanner;
  // Web's own accordions are plain `<details>` with no `open` attribute —
  // all 4 categories start collapsed, with no persisted expand state.
  final Set<String> _expanded = {};

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

  void _scrollToTab(int index) {
    setState(() => _activeTab = index);
    final key = index == 0 ? _addKey : _listKey;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx != null)
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _type = null;
      _editingId = null;
      _formBanner = null;
    });
  }

  void _loadForEdit(AdminSetupEntity e) {
    setState(() {
      _editingId = e.id;
      _type = e.type;
      _nameCtrl.text = e.name;
      _descriptionCtrl.text = e.description ?? '';
      _formBanner = null;
    });
    _scrollToTab(0);
  }

  Future<void> _submit() async {
    if (_type == null) {
      setState(() => _formBanner = 'Please select a type.');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _formBanner = 'Name is required.');
      return;
    }

    final entry = AdminSetupEntity(
      type: _type!,
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
    );

    final notifier = ref.read(adminSetupListProvider(_type!).notifier);
    final ok = _editingId == null
        ? await notifier.add(entry)
        : await notifier.edit(_editingId!, entry);

    if (!mounted) return;
    if (ok) {
      _resetForm();
      _scrollToTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        _type != null &&
        ref.watch(adminSetupListProvider(_type!)).savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStepperNav(
            activeIndex: _activeTab,
            steps: [
              AdminStep(
                number: '01',
                icon: Icons.add,
                label: _editingId == null
                    ? 'Add Admin Setup'
                    : 'Edit Admin Setup',
              ),
              const AdminStep(
                number: '02',
                icon: Icons.description_outlined,
                label: 'Admin Setup List',
              ),
            ],
            onTap: _scrollToTab,
          ),
          KeyedSubtree(
            key: _addKey,
            child: AdminStepFormCard(
              title: _editingId == null
                  ? 'Register New Admin Setup'
                  : 'Edit Admin Setup',
              subtitle:
                  'Fields marked with * are mandatory. Add purpose, complaint types, or references.',
              editingBadgeText: _editingId == null
                  ? null
                  : 'Editing: ${_nameCtrl.text}',
              banner: _formBanner,
              isEditing: _editingId != null,
              saving: isSaving,
              onReset: _resetForm,
              onSave: _submit,
              footerHelperText:
                  'This configuration will be available in corresponding sub-modules.',
              fields: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminDropdownField<String>(
                        label: 'Type',
                        required: true,
                        value: _type,
                        hint: 'Select Type',
                        items: AdminSetupEntity.typeLabels.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      AdminTextField(
                        label: 'Name',
                        required: true,
                        controller: _nameCtrl,
                        hint: 'e.g. Broken Furniture',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required.'
                            : null,
                      ),
                      AdminTextField(
                        label: 'Description',
                        controller: _descriptionCtrl,
                        hint: 'Optional description',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          KeyedSubtree(
            key: _listKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminBrowseHeading(
                  stepNumber: '02',
                  title: 'Browse Admin Setups',
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.borderPrimary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: AdminSetupEntity.typeLabels.entries
                        .map((entry) => _typeAccordion(entry.key, entry.value))
                        .toList(),
                  ),
                ),
              ],
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

    // A `Border` with non-uniform side colors (the left accent strip vs. the
    // other 3 sides' neutral color) combined with `borderRadius` throws
    // "A borderRadius can only be given on borders with uniform colors" —
    // an unconditional crash (not assert-gated), reproduced via widget test.
    // Fixed by keeping the Container's own border uniform and painting the
    // accent strip as a separate `Positioned` overlay instead (same pattern
    // used for Attendance/Admissions row indicators elsewhere in this app).
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: accent),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(
                    () => isOpen ? _expanded.remove(type) : _expanded.add(type),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.totalCount} items',
                            style: TextStyle(fontSize: 11, color: accent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isOpen ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: state.isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(),
                          )
                        : state.error != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: AdminMessageBanner(error: state.error),
                          )
                        : Column(
                            children: [
                              if (state.items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'No entries yet.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: state.items
                                      .map<Widget>((e) => _itemRow(type, e))
                                      .toList(),
                                ),
                              AdminPaginationBar(
                                page: state.page,
                                pageSize: state.pageSize,
                                totalCount: state.totalCount,
                                onPageChange: (p) => ref
                                    .read(adminSetupListProvider(type).notifier)
                                    .setPage(p),
                                onPageSizeChange: (s) => ref
                                    .read(adminSetupListProvider(type).notifier)
                                    .setPageSize(s),
                                pageSizeOptions: const [5, 10, 25, 50],
                                summaryStyle:
                                    PaginationSummaryStyle.pageOfTotal,
                                chevronStyle: true,
                              ),
                            ],
                          ),
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
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  e.description?.isNotEmpty == true
                      ? e.description!
                      : 'No description',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.primaryPurple,
            ),
            onPressed: () => _loadForEdit(e),
            tooltip: 'Edit',
          ),
          state.deletingId == e.id
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.dangerRed,
                  ),
                  tooltip: 'Delete',
                  onPressed: () async {
                    final confirmed = await showAdminConfirmDialog(
                      context,
                      message: 'Are you sure to delete this admin setup entry?',
                    );
                    if (confirmed && e.id != null) {
                      await ref
                          .read(adminSetupListProvider(type).notifier)
                          .remove(e.id!);
                    }
                  },
                ),
        ],
      ),
    );
  }
}
