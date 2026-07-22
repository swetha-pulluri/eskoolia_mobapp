import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_breadcrumb_header.dart';
import '../widgets/web_button.dart';

/// Complaints — converted from web `ComplaintPanel.tsx`.
/// Sub-tab of Communication Hub.
class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintByCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _actionTakenCtrl = TextEditingController();
  final _assignedCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String? _complaintTypeId;
  String? _complaintSourceId;
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
    _complaintByCtrl.dispose();
    _phoneCtrl.dispose();
    _actionTakenCtrl.dispose();
    _assignedCtrl.dispose();
    _descriptionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _complaintByCtrl.clear();
    _phoneCtrl.clear();
    _actionTakenCtrl.clear();
    _assignedCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _complaintTypeId = null;
      _complaintSourceId = null;
      _date = DateTime.now();
      _editingId = null;
      _attachment = null;
      _attachmentError = null;
    });
  }

  void _loadForEdit(ComplaintEntity c) {
    setState(() {
      _editingId = c.id;
      _complaintByCtrl.text = c.complaintBy;
      _complaintTypeId = c.complaintTypeId;
      _complaintSourceId = c.complaintSourceId;
      _phoneCtrl.text = c.phone ?? '';
      _date = DateTime.tryParse(c.date);
      _actionTakenCtrl.text = c.actionTaken ?? '';
      _assignedCtrl.text = c.assigned ?? '';
      _descriptionCtrl.text = c.description ?? '';
      _attachment = null;
      _attachmentError = null;
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _handleDateChange(DateTime picked) async {
    final daysOld = DateTime.now().difference(picked).inDays;
    if (daysOld > 7) {
      final keep = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complaint Date Warning'),
          content: const Text('This date is more than 7 days old. Are you sure?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No, let me change it')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, keep this date')),
          ],
        ),
      );
      if (keep != true) return;
    }
    setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_complaintTypeId == null) {
      _showFieldError('Please select a complaint type.');
      return;
    }
    if (_complaintSourceId == null) {
      _showFieldError('Please select a complaint source.');
      return;
    }
    if (_date == null) {
      _showFieldError('Please select a date.');
      return;
    }
    if (_attachmentError != null) {
      _showFieldError(_attachmentError!);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final complaint = ComplaintEntity(
      complaintBy: _complaintByCtrl.text.trim(),
      complaintTypeId: _complaintTypeId,
      complaintSourceId: _complaintSourceId,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      date: _fmtDate(_date!),
      actionTaken: _actionTakenCtrl.text.trim().isEmpty ? null : _actionTakenCtrl.text.trim(),
      assigned: _assignedCtrl.text.trim().isEmpty ? null : _assignedCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      attachment: _attachment,
    );

    final notifier = ref.read(complaintListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(complaint) : await notifier.edit(_editingId!, complaint);

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
    final state = ref.watch(complaintListProvider);
    final typeOptions = ref.watch(complaintTypeOptionsProvider);
    final sourceOptions = ref.watch(complaintSourceOptionsProvider);
    final isSaving = state.savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Complaint'),
          AdminSectionCard(
            title: _editingId == null ? 'Add Complaint' : 'Edit Complaint',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(
                    label: 'Complaint By',
                    required: true,
                    controller: _complaintByCtrl,
                    hint: 'e.g. Parent of Rahul',
                    maxLength: 100,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Complaint By is required.';
                      if (value.length < 2) return 'Minimum 2 characters required.';
                      if (!RegExp(r"^[A-Za-z\s\-']+$").hasMatch(value)) {
                        return 'Only letters, spaces, hyphens, apostrophes allowed.';
                      }
                      return null;
                    },
                  ),
                  // Always render the <select>, even if the fetch failed —
                  // matches web (an empty-options select, not a vanished
                  // field); otherwise these required fields become
                  // permanently unfillable whenever admin-setups 401s/500s.
                  AdminDropdownField<String>(
                    label: 'Complaint Type',
                    required: true,
                    value: _complaintTypeId,
                    hint: 'Select Complaint Type',
                    items: typeOptions
                        .maybeWhen(data: (options) => options, orElse: () => const [])
                        .map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _complaintTypeId = v),
                  ),
                  if (typeOptions.isLoading)
                    const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                  if (typeOptions.hasError)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Unable to load complaint types.', style: TextStyle(color: AppColors.dangerRed, fontSize: 12)),
                    ),
                  AdminDropdownField<String>(
                    label: 'Complaint Source',
                    required: true,
                    value: _complaintSourceId,
                    hint: 'Select Complaint Source',
                    items: sourceOptions
                        .maybeWhen(data: (options) => options, orElse: () => const [])
                        .map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _complaintSourceId = v),
                  ),
                  if (sourceOptions.isLoading)
                    const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                  if (sourceOptions.hasError)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Unable to load complaint sources.', style: TextStyle(color: AppColors.dangerRed, fontSize: 12)),
                    ),
                  AdminTextField(
                    label: 'Phone',
                    controller: _phoneCtrl,
                    hint: 'e.g. 9876543210',
                    keyboardType: TextInputType.phone,
                    maxLength: 12,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (!RegExp(r'^\d+$').hasMatch(value)) return 'Only digits (0-9) are allowed.';
                      if (value.length < 10) return 'Phone must be at least 10 digits.';
                      if (value.length > 12) return 'Phone must not exceed 12 digits.';
                      return null;
                    },
                  ),
                  AdminDateField(
                    label: 'Date',
                    required: true,
                    value: _date,
                    lastDate: DateTime.now(),
                    onChanged: (d) {
                      if (d != null) _handleDateChange(d);
                    },
                  ),
                  AdminTextField(label: 'Action Taken', controller: _actionTakenCtrl, hint: 'e.g. Called parent for discussion', maxLength: 500),
                  AdminTextField(label: 'Assigned', controller: _assignedCtrl, hint: 'e.g. Mr. Sharma', maxLength: 100),
                  AdminTextField(
                    label: 'Description',
                    controller: _descriptionCtrl,
                    hint: 'e.g. Parent reported broken fence near playground',
                    maxLines: 3,
                    maxLength: 2000,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (value.length < 10) return 'Description must be at least 10 characters.';
                      return null;
                    },
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
            title: 'Complaint List',
            trailing: SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Quick search', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => ref.read(complaintListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              children: [
                if (state.error != null) const AdminMessageBanner(error: 'Unable to load complaints.'),
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No complaints found.',
                  columns: const [
                    AdminColumn('SL', width: 40),
                    AdminColumn('Complaint By', width: 130),
                    AdminColumn('Type', width: 140),
                    AdminColumn('Source', width: 110),
                    AdminColumn('Phone', width: 100),
                    AdminColumn('Date', width: 100),
                    AdminColumn('Actions', width: 80),
                  ],
                  rows: _buildRows(state),
                ),
                AdminPaginationBar(
                  page: state.page,
                  pageSize: state.pageSize,
                  totalCount: state.totalCount,
                  onPageChange: (p) => ref.read(complaintListProvider.notifier).setPage(p),
                  onPageSizeChange: (s) => ref.read(complaintListProvider.notifier).setPageSize(s),
                  pageSizeOptions: const [10, 25, 50],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<List<Widget>> _buildRows(dynamic state) {
    final notifier = ref.read(complaintListProvider.notifier);
    final visible = notifier.filtered((c, q) =>
        c.complaintBy.toLowerCase().contains(q) ||
        (c.complaintTypeName ?? '').toLowerCase().contains(q) ||
        (c.complaintSourceName ?? '').toLowerCase().contains(q) ||
        (c.phone ?? '').toLowerCase().contains(q));

    return List.generate(visible.length, (index) {
      final c = visible[index];
      return [
        Text('${(state.page - 1) * state.pageSize + index + 1}', style: const TextStyle(fontSize: 12.5)),
        Text(c.complaintBy, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        AdminBadge.complaintType(c.complaintTypeName),
        AdminBadge.source(c.complaintSourceName),
        Text(c.phone ?? '-', style: const TextStyle(fontSize: 12.5)),
        Text(c.date, style: const TextStyle(fontSize: 12.5)),
        AdminIconActionButtons(
          onEdit: () => _loadForEdit(c),
          isDeleting: state.deletingId == c.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
              context,
              message: 'Are you sure you want to delete this complaint? This action cannot be undone.',
              confirmLabel: 'Yes, Delete',
            );
            if (confirmed && c.id != null) {
              await ref.read(complaintListProvider.notifier).remove(c.id!);
            }
          },
        ),
      ];
    });
  }
}
