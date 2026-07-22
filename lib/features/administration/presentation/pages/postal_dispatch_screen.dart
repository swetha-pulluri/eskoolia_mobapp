import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/postal_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_breadcrumb_header.dart';
import '../widgets/web_button.dart';

/// Postal Dispatched — converted from web `PostalDispatchPanel.tsx`.
/// Sub-tab of Postal Management.
class PostalDispatchScreen extends ConsumerStatefulWidget {
  const PostalDispatchScreen({super.key});

  @override
  ConsumerState<PostalDispatchScreen> createState() => _PostalDispatchScreenState();
}

enum _SortKey { toTitle, referenceNo, date }

class _PostalDispatchScreenState extends ConsumerState<PostalDispatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toTitleCtrl = TextEditingController();
  final _referenceNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _fromTitleCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  DateTime? _date = DateTime.now();
  int? _editingId;
  PickedAttachment? _attachment;
  String? _attachmentError;

  static const _allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'xlsx'];

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
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

  _SortKey _sortKey = _SortKey.date;
  bool _sortAsc = false;

  void _toggleSort(_SortKey key) {
    setState(() {
      if (_sortKey == key) {
        _sortAsc = !_sortAsc;
      } else {
        _sortKey = key;
        _sortAsc = true;
      }
    });
  }

  @override
  void dispose() {
    _toTitleCtrl.dispose();
    _referenceNoCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _fromTitleCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _toTitleCtrl.clear();
    _referenceNoCtrl.clear();
    _addressCtrl.clear();
    _noteCtrl.clear();
    _fromTitleCtrl.clear();
    setState(() {
      _date = DateTime.now();
      _editingId = null;
      _attachment = null;
      _attachmentError = null;
    });
  }

  void _loadForEdit(PostalDispatchEntity e) {
    setState(() {
      _editingId = e.id;
      _toTitleCtrl.text = e.toTitle;
      _referenceNoCtrl.text = e.referenceNo;
      _addressCtrl.text = e.address;
      _noteCtrl.text = e.note ?? '';
      _fromTitleCtrl.text = e.fromTitle;
      _date = DateTime.tryParse(e.date);
      _attachment = null;
      _attachmentError = null;
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_date == null) {
      _showFieldError('Dispatch Date is required.');
      return;
    }
    if (_attachmentError != null) {
      _showFieldError(_attachmentError!);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final entry = PostalDispatchEntity(
      toTitle: _toTitleCtrl.text.trim(),
      referenceNo: _referenceNoCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      fromTitle: _fromTitleCtrl.text.trim(),
      date: _fmtDate(_date!),
      attachment: _attachment,
    );

    final notifier = ref.read(postalDispatchListProvider.notifier);
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
    final state = ref.watch(postalDispatchListProvider);
    final isSaving = state.savingId != null;
    final minDate = DateTime.now().subtract(const Duration(days: 365));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Postal Dispatch'),
          AdminSectionCard(
            title: _editingId == null ? 'Add Postal Dispatch' : 'Edit Postal Dispatch',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  AdminTextField(
                    label: 'Reference No',
                    required: true,
                    controller: _referenceNoCtrl,
                    hint: 'e.g. PD-2026-001',
                    maxLength: 20,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Reference No is required.';
                      if (value.length < 3) return 'Reference No must be at least 3 characters.';
                      if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value)) {
                        return 'Reference No must be alphanumeric (letters, numbers, hyphens only).';
                      }
                      return null;
                    },
                  ),
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
                  AdminTextField(
                    label: 'Note',
                    controller: _noteCtrl,
                    hint: 'Optional notes',
                    maxLines: 3,
                    maxLength: 500,
                    counterBuilder: (n) => '$n / 500 characters',
                  ),
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
                  AdminDateField(
                    label: 'Dispatch Date',
                    required: true,
                    value: _date,
                    firstDate: minDate,
                    lastDate: DateTime.now(),
                    onChanged: (d) => setState(() => _date = d),
                  ),
                  AdminFileField(
                    fileName: _attachment?.name,
                    errorText: _attachmentError,
                    onTap: _pickAttachment,
                    helper: 'Accepted formats: PDF, DOC, DOCX, JPG, PNG, XLSX. Max size: 5MB.',
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      WebButton(
                        label: isSaving ? 'Saving...' : (_editingId == null ? 'Save' : 'Update'),
                        onPressed: isSaving ? null : _submit,
                      ),
                      const SizedBox(width: 8),
                      WebButton(label: 'Clear Form', color: const Color(0xFF6B7280), onPressed: _resetForm),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AdminSectionCard(
            title: 'Postal Dispatch List',
            trailing: SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Quick search', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => ref.read(postalDispatchListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              children: [
                if (state.error != null) const AdminMessageBanner(error: 'Unable to load postal dispatch records.'),
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No postal dispatch records found.',
                  columns: [
                    AdminColumn('To Title', width: 110, onTap: () => _toggleSort(_SortKey.toTitle), sortArrow: _sortKey == _SortKey.toTitle ? (_sortAsc ? '▲' : '▼') : ''),
                    AdminColumn('Reference No', width: 110, onTap: () => _toggleSort(_SortKey.referenceNo), sortArrow: _sortKey == _SortKey.referenceNo ? (_sortAsc ? '▲' : '▼') : ''),
                    const AdminColumn('Address', width: 140),
                    const AdminColumn('From Title', width: 110),
                    const AdminColumn('Note', width: 100),
                    AdminColumn('Date', width: 100, onTap: () => _toggleSort(_SortKey.date), sortArrow: _sortKey == _SortKey.date ? (_sortAsc ? '▲' : '▼') : ''),
                    const AdminColumn('Actions', width: 90),
                  ],
                  rows: _buildRows(state),
                ),
                AdminPaginationBar(
                  page: state.page,
                  pageSize: state.pageSize,
                  totalCount: state.totalCount,
                  onPageChange: (p) => ref.read(postalDispatchListProvider.notifier).setPage(p),
                  onPageSizeChange: (s) => ref.read(postalDispatchListProvider.notifier).setPageSize(s),
                  pageSizeOptions: const [10, 25, 50],
                  pageSizeSuffix: ' / page',
                  showPageNumbers: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<List<Widget>> _buildRows(dynamic state) {
    final notifier = ref.read(postalDispatchListProvider.notifier);
    final visible = notifier.filtered((e, q) =>
        e.toTitle.toLowerCase().contains(q) ||
        e.referenceNo.toLowerCase().contains(q) ||
        e.address.toLowerCase().contains(q) ||
        e.fromTitle.toLowerCase().contains(q) ||
        (e.note ?? '').toLowerCase().contains(q));

    visible.sort((a, b) {
      final mult = _sortAsc ? 1 : -1;
      switch (_sortKey) {
        case _SortKey.toTitle:
          return a.toTitle.compareTo(b.toTitle) * mult;
        case _SortKey.referenceNo:
          return a.referenceNo.compareTo(b.referenceNo) * mult;
        case _SortKey.date:
          return a.date.compareTo(b.date) * mult;
      }
    });

    return List.generate(visible.length, (index) {
      final e = visible[index];
      return [
        Text(e.toTitle, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(e.referenceNo, style: const TextStyle(fontSize: 12.5)),
        Text(e.address, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(e.fromTitle, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(e.note?.isNotEmpty == true ? e.note! : '-', style: const TextStyle(fontSize: 12.5)),
        Text(e.date.isNotEmpty ? e.date : '-', style: const TextStyle(fontSize: 12.5)),
        AdminRowActions(
          onEdit: () => _loadForEdit(e),
          isDeleting: state.deletingId == e.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
              context,
              message: 'Are you sure you want to delete this postal dispatch record? This action cannot be undone.',
            );
            if (confirmed && e.id != null) {
              await ref.read(postalDispatchListProvider.notifier).remove(e.id!);
            }
          },
        ),
      ];
    });
  }
}
