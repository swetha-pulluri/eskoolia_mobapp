import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_stepper_shell.dart';

/// Postal Received — converted from the real, currently-shipped web
/// source `PostalReceivePanel.tsx` (`origin/demo`/`origin/mobile`
/// branches). 3-step numbered nav: 01 Add/Edit Postal Receive, 02 Smart
/// Filter, 03 Postal Receive List.
class PostalReceiveScreen extends ConsumerStatefulWidget {
  const PostalReceiveScreen({super.key});

  @override
  ConsumerState<PostalReceiveScreen> createState() => _PostalReceiveScreenState();
}

class _PostalReceiveScreenState extends ConsumerState<PostalReceiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromTitleCtrl = TextEditingController();
  final _referenceNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _toTitleCtrl = TextEditingController();
  final _filterSearchCtrl = TextEditingController();

  final _addKey = GlobalKey();
  final _filterKey = GlobalKey();
  final _listKey = GlobalKey();

  int _activeTab = 0;
  bool _filterOpen = false;
  DateTime? _filterDate;
  List<String> _filterChips = [];
  String _search = '';
  String? _dateFilterValue;

  DateTime? _date = DateTime.now();
  int? _editingId;
  String _sortKey = 'date';
  bool? _sortAsc;
  PickedAttachment? _attachment;
  String? _attachmentError;

  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: _allowedExtensions, withData: true);
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    setState(() {
      if (file.size > 5 * 1024 * 1024) {
        _attachmentError = 'File size exceeds 5MB limit.';
        _attachment = null;
      } else {
        _attachmentError = null;
        _attachment = PickedAttachment(name: file.name, bytes: file.bytes!, size: file.size);
      }
    });
  }

  @override
  void dispose() {
    _fromTitleCtrl.dispose();
    _referenceNoCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _toTitleCtrl.dispose();
    _filterSearchCtrl.dispose();
    super.dispose();
  }

  void _scrollToTab(int index) {
    setState(() => _activeTab = index);
    if (index == 1) setState(() => _filterOpen = true);
    final key = index == 0 ? _addKey : (index == 1 ? _filterKey : _listKey);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _fromTitleCtrl.clear();
    _referenceNoCtrl.clear();
    _addressCtrl.clear();
    _noteCtrl.clear();
    _toTitleCtrl.clear();
    setState(() {
      _date = DateTime.now();
      _editingId = null;
      _attachment = null;
      _attachmentError = null;
    });
  }

  void _loadForEdit(PostalReceiveEntity e) {
    setState(() {
      _editingId = e.id;
      _fromTitleCtrl.text = e.fromTitle;
      _referenceNoCtrl.text = e.referenceNo;
      _addressCtrl.text = e.address;
      _noteCtrl.text = e.note ?? '';
      _toTitleCtrl.text = e.toTitle;
      _date = DateTime.tryParse(e.date);
      _attachment = null;
      _attachmentError = null;
    });
    _scrollToTab(0);
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_date == null || _attachmentError != null || !_formKey.currentState!.validate()) return;

    final entry = PostalReceiveEntity(
      fromTitle: _fromTitleCtrl.text.trim(),
      referenceNo: _referenceNoCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      toTitle: _toTitleCtrl.text.trim(),
      date: _fmtDate(_date!),
      attachment: _attachment,
    );

    final notifier = ref.read(postalReceiveListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(entry) : await notifier.edit(_editingId!, entry);

    if (!mounted) return;
    if (ok) {
      _resetForm();
      _scrollToTab(2);
    }
  }

  void _applyFilters() {
    setState(() {
      _search = _filterSearchCtrl.text.trim();
      _dateFilterValue = _filterDate == null ? null : _fmtDate(_filterDate!);
      _filterChips = [
        if (_search.isNotEmpty) 'Search: $_search',
        if (_filterDate != null) 'Date: ${_fmtDate(_filterDate!)}',
      ];
      _filterOpen = false;
    });
  }

  void _clearFilters() {
    _filterSearchCtrl.clear();
    setState(() {
      _filterDate = null;
      _search = '';
      _dateFilterValue = null;
      _filterChips = [];
    });
  }

  void _removeChip(String chip) {
    if (chip.startsWith('Search:')) _filterSearchCtrl.clear();
    if (chip.startsWith('Date:')) _filterDate = null;
    _applyFilters();
  }

  void _toggleSort(String key) {
    setState(() {
      if (_sortKey == key) {
        _sortAsc = _sortAsc == true ? false : true;
      } else {
        _sortKey = key;
        _sortAsc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postalReceiveListProvider);
    final isSaving = state.savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStepperNav(
            activeIndex: _activeTab,
            steps: [
              AdminStep(number: '01', icon: Icons.add, label: _editingId == null ? 'Add Postal Receive' : 'Edit Postal Receive'),
              const AdminStep(number: '02', icon: Icons.filter_alt_outlined, label: 'Smart Filter'),
              const AdminStep(number: '03', icon: Icons.description_outlined, label: 'Postal Receive List'),
            ],
            onTap: _scrollToTab,
          ),
          KeyedSubtree(
            key: _addKey,
            child: AdminStepFormCard(
              title: _editingId == null ? 'Register New Postal Receive' : 'Edit Postal Receive Details',
              subtitle: 'Fields marked with * are mandatory. Record details of received posts securely.',
              editingBadgeText: _editingId == null ? null : 'Editing Record: ${_referenceNoCtrl.text}',
              isEditing: _editingId != null,
              saving: isSaving,
              onReset: _resetForm,
              onSave: _submit,
              footerHelperText: 'All records are securely saved into the postal tracking module.',
              fields: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminTextField(
                        label: 'From Title',
                        required: true,
                        controller: _fromTitleCtrl,
                        hint: 'e.g. Main Office',
                        maxLength: 100,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'From Title is required.';
                          if (value.length < 3) return 'From Title must be at least 3 characters.';
                          return null;
                        },
                      ),
                      AdminTextField(
                        label: 'Reference No',
                        required: true,
                        controller: _referenceNoCtrl,
                        hint: 'e.g. PR-2026-001',
                        maxLength: 20,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Reference No is required.';
                          if (value.length < 3) return 'Reference No must be at least 3 characters.';
                          if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value)) return 'Reference No can only contain letters, numbers, and hyphens.';
                          return null;
                        },
                      ),
                      AdminTextField(
                        label: 'To Title',
                        required: true,
                        controller: _toTitleCtrl,
                        hint: 'e.g. Recipient Name',
                        maxLength: 100,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'To Title is required.';
                          if (value.length < 3) return 'To Title must be at least 3 characters.';
                          return null;
                        },
                      ),
                      AdminDateField(label: 'Date', required: true, value: _date, lastDate: DateTime.now(), onChanged: (d) => setState(() => _date = d)),
                      AdminTextField(
                        label: 'Address',
                        required: true,
                        controller: _addressCtrl,
                        hint: 'e.g. 123 Main Street, City',
                        maxLength: 255,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Address is required.';
                          if (value.length < 5) return 'Address must be at least 5 characters.';
                          return null;
                        },
                      ),
                      AdminTextField(label: 'Note', controller: _noteCtrl, hint: 'Optional notes', maxLines: 3, maxLength: 500),
                      AdminFileField(label: 'Attachment', fileName: _attachment?.name, errorText: _attachmentError, onTap: _pickAttachment),
                    ],
                  ),
                ),
              ],
            ),
          ),
          KeyedSubtree(
            key: _filterKey,
            child: AdminSmartFilterSection(
              stepNumber: '02',
              subtitle: 'Find received postal records easily by search or date.',
              open: _filterOpen,
              onToggle: () => setState(() => _filterOpen = !_filterOpen),
              chips: _filterChips,
              onRemoveChip: _removeChip,
              onClearAll: _clearFilters,
              onApply: _applyFilters,
              onClear: _clearFilters,
              fields: [
                AdminTextField(label: 'Search', controller: _filterSearchCtrl, hint: 'Title, Reference No...'),
                AdminDateField(label: 'Date', value: _filterDate, onChanged: (d) => setState(() => _filterDate = d)),
              ],
            ),
          ),
          KeyedSubtree(
            key: _listKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminBrowseHeading(stepNumber: '03', title: 'Browse Postal Receive'),
                Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (state.error != null) const AdminMessageBanner(error: 'Unable to load postal receive records.'),
                      AdminDataTable(
                        isLoading: state.isLoading,
                        emptyText: 'No postal receive records found matching criteria.',
                        columns: [
                          const AdminColumn('SL', width: 36),
                          AdminColumn('From Title', width: 110, onTap: () => _toggleSort('from_title'), sortArrow: _sortKey == 'from_title' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          AdminColumn('Reference No', width: 110, onTap: () => _toggleSort('reference_no'), sortArrow: _sortKey == 'reference_no' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Address', width: 140),
                          AdminColumn('To Title', width: 110, onTap: () => _toggleSort('to_title'), sortArrow: _sortKey == 'to_title' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          AdminColumn('Date', width: 95, onTap: () => _toggleSort('date'), sortArrow: _sortKey == 'date' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Actions', width: 90),
                        ],
                        rows: _buildRows(state),
                      ),
                      AdminPaginationBar(
                        page: state.page,
                        pageSize: state.pageSize,
                        totalCount: state.totalCount,
                        onPageChange: (p) => ref.read(postalReceiveListProvider.notifier).setPage(p),
                        onPageSizeChange: (s) => ref.read(postalReceiveListProvider.notifier).setPageSize(s),
                        pageSizeOptions: const [5, 10, 20, 30, 40, 50],
                        summaryStyle: PaginationSummaryStyle.pageOfTotal,
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

  List<List<Widget>> _buildRows(dynamic state) {
    final notifier = ref.read(postalReceiveListProvider.notifier);
    final visible = notifier.filtered((e, q) =>
        e.fromTitle.toLowerCase().contains(q) || e.referenceNo.toLowerCase().contains(q) || e.toTitle.toLowerCase().contains(q) || e.address.toLowerCase().contains(q));

    var filtered = visible;
    if (_dateFilterValue != null) filtered = filtered.where((e) => e.date == _dateFilterValue).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((e) => e.fromTitle.toLowerCase().contains(q) || e.referenceNo.toLowerCase().contains(q) || e.toTitle.toLowerCase().contains(q)).toList();
    }

    final asc = _sortAsc ?? false;
    filtered.sort((a, b) {
      final mult = asc ? 1 : -1;
      switch (_sortKey) {
        case 'from_title':
          return a.fromTitle.compareTo(b.fromTitle) * mult;
        case 'reference_no':
          return a.referenceNo.compareTo(b.referenceNo) * mult;
        case 'to_title':
          return a.toTitle.compareTo(b.toTitle) * mult;
        default:
          return a.date.compareTo(b.date) * mult;
      }
    });

    return List.generate(filtered.length, (index) {
      final e = filtered[index];
      return [
        Text('${(state.page - 1) * state.pageSize + index + 1}', style: const TextStyle(fontSize: 12.5)),
        Text(e.fromTitle, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        _naText(e.referenceNo),
        Text(e.address, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        _naText(e.toTitle),
        Text(e.date.isNotEmpty ? e.date : '—', style: const TextStyle(fontSize: 12.5)),
        AdminIconActionButtons(
          onEdit: () => _loadForEdit(e),
          isDeleting: state.deletingId == e.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(context, message: 'Are you sure you want to delete this postal receive record? This action cannot be undone.');
            if (confirmed && e.id != null) {
              await ref.read(postalReceiveListProvider.notifier).remove(e.id!);
            }
          },
        ),
      ];
    });
  }

  Widget _naText(String value) {
    if (value.trim().isEmpty || value.trim() == '-') {
      return const Text('N/A', style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.textTertiary));
    }
    return Text(value, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis);
  }
}
