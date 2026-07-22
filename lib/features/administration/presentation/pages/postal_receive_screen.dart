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

/// Postal Received — converted from web `PostalReceivePanel.tsx`.
/// Sub-tab of Postal Management.
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
  final _searchCtrl = TextEditingController();

  DateTime? _date = DateTime.now();
  int? _editingId;
  PickedAttachment? _attachment;
  String? _attachmentError;

  static const _allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

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

  @override
  void dispose() {
    _fromTitleCtrl.dispose();
    _referenceNoCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _toTitleCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_date == null) {
      _showFieldError('Date is required.');
      return;
    }
    if (_attachmentError != null) {
      _showFieldError(_attachmentError!);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

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
    final state = ref.watch(postalReceiveListProvider);
    final isSaving = state.savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Postal Receive'),
          AdminSectionCard(
            title: _editingId == null ? 'Add Postal Receive' : 'Edit Postal Receive',
            child: Form(
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
                      if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value)) {
                        return 'Reference No can only contain letters, numbers, and hyphens.';
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
                  AdminDateField(
                    label: 'Date',
                    required: true,
                    value: _date,
                    lastDate: DateTime.now(),
                    onChanged: (d) => setState(() => _date = d),
                  ),
                  AdminFileField(
                    fileName: _attachment?.name,
                    errorText: _attachmentError,
                    onTap: _pickAttachment,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      WebButton(
                        label: isSaving ? 'Saving...' : (_editingId == null ? 'Save' : 'Update'),
                        onPressed: isSaving ? null : _submit,
                      ),
                      if (_editingId != null) ...[
                        const SizedBox(width: 8),
                        WebButton(label: 'Cancel', color: const Color(0xFF6B7280), onPressed: _resetForm),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          AdminSectionCard(
            title: 'Postal Receive List',
            trailing: SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Quick search', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => ref.read(postalReceiveListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              children: [
                if (state.error != null) const AdminMessageBanner(error: 'Unable to load postal receive records.'),
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No postal receive records found.',
                  columns: const [
                    AdminColumn('From Title', width: 110),
                    AdminColumn('Reference No', width: 110),
                    AdminColumn('Address', width: 140),
                    AdminColumn('To Title', width: 110),
                    AdminColumn('Note', width: 100),
                    AdminColumn('Date', width: 100),
                    AdminColumn('Actions', width: 90),
                  ],
                  rows: _buildRows(state),
                ),
                AdminPaginationBar(
                  page: state.page,
                  pageSize: state.pageSize,
                  totalCount: state.totalCount,
                  onPageChange: (p) => ref.read(postalReceiveListProvider.notifier).setPage(p),
                  onPageSizeChange: (s) => ref.read(postalReceiveListProvider.notifier).setPageSize(s),
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
    final notifier = ref.read(postalReceiveListProvider.notifier);
    final visible = notifier.filtered((e, q) =>
        e.fromTitle.toLowerCase().contains(q) ||
        e.referenceNo.toLowerCase().contains(q) ||
        e.address.toLowerCase().contains(q) ||
        e.toTitle.toLowerCase().contains(q) ||
        (e.note ?? '').toLowerCase().contains(q));

    return List.generate(visible.length, (index) {
      final e = visible[index];
      return [
        Text(e.fromTitle, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(e.referenceNo, style: const TextStyle(fontSize: 12.5)),
        Text(e.address, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(e.toTitle, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(e.note?.isNotEmpty == true ? e.note! : '—', style: const TextStyle(fontSize: 12.5)),
        Text(e.date.isNotEmpty ? e.date : '—', style: const TextStyle(fontSize: 12.5)),
        AdminRowActions(
          onEdit: () => _loadForEdit(e),
          isDeleting: state.deletingId == e.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
              context,
              message: 'Are you sure you want to delete this postal record? This action cannot be undone.',
            );
            if (confirmed && e.id != null) {
              await ref.read(postalReceiveListProvider.notifier).remove(e.id!);
            }
          },
        ),
      ];
    });
  }
}
