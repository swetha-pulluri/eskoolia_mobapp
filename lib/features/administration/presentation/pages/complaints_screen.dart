import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_stepper_shell.dart';

/// Complaints — converted from `origin/demo`'s `ComplaintPanel.tsx`. 3-step
/// numbered nav: 01 Add/Edit Complaint, 02 Smart Filter, 03 Complaints
/// List. Complaint Type/Source dropdowns come from
/// `/api/v1/admissions/admin-setups/?type=2` (Complaint Type) and
/// `?type=3` (Source) — confirmed by enumerating the currently-deployed
/// backend's actual registered routes: `/complaint-types/`/
/// `/complaint-sources/` (a dedicated FK-table design that exists only on
/// `origin/demo`) are NOT registered here, so those endpoints always 404.
/// `main`'s `ComplaintEntrySerializer` (what is actually running) resolves
/// `complaint_type`/`complaint_source` via `AdminSetupEntry` lookups
/// instead, matching Purpose's own `type=1` pattern.
///
/// Browse/Save currently return HTTP 500 regardless of what this screen
/// sends: the live `public.complaint_entries` table is missing the
/// `assigned` column that `main`'s `ComplaintEntry` model still declares
/// (confirmed directly — `SELECT` and `INSERT` both reference a column
/// that does not exist, `psycopg2.errors.UndefinedColumn`, reproduced via
/// `force_authenticate` against the real view). This is a backend
/// model/migration defect, out of scope for this app to fix.
class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintByCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _assignedCtrl = TextEditingController();
  final _actionTakenCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _filterSearchCtrl = TextEditingController();

  final _addKey = GlobalKey();
  final _filterKey = GlobalKey();
  final _listKey = GlobalKey();

  int _activeTab = 0;
  bool _filterOpen = false;
  String? _filterTypeId;
  String? _filterSourceId;
  DateTime? _filterDate;
  List<String> _filterChips = [];
  String _search = '';
  String? _typeFilterValue;
  String? _sourceFilterValue;
  String? _dateFilterValue;

  String? _complaintTypeId;
  String? _complaintSourceId;
  DateTime? _date = DateTime.now();
  int? _editingId;
  String _sortKey = 'date';
  bool? _sortAsc;
  PickedAttachment? _attachment;
  String? _attachmentError;
  String? _formBanner;

  static const _allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: _allowedExtensions, withData: true);
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
    _assignedCtrl.dispose();
    _actionTakenCtrl.dispose();
    _descriptionCtrl.dispose();
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
    _complaintByCtrl.clear();
    _phoneCtrl.clear();
    _assignedCtrl.clear();
    _actionTakenCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _complaintTypeId = null;
      _complaintSourceId = null;
      _date = DateTime.now();
      _editingId = null;
      _attachment = null;
      _attachmentError = null;
      _formBanner = null;
    });
  }

  String? _resolveId(List<dynamic> options, String? rawId, String? rawName) {
    for (final o in options) {
      if (o.id.toString() == rawId || o.name == rawId || o.name == rawName) return o.id.toString();
    }
    return rawId;
  }

  void _loadForEdit(ComplaintEntity c) {
    final typeOptions = ref.read(complaintTypeOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    final sourceOptions = ref.read(complaintSourceOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    setState(() {
      _editingId = c.id;
      _complaintByCtrl.text = c.complaintBy;
      _complaintTypeId = _resolveId(typeOptions, c.complaintTypeId, c.complaintTypeName);
      _complaintSourceId = _resolveId(sourceOptions, c.complaintSourceId, c.complaintSourceName);
      _phoneCtrl.text = c.phone ?? '';
      _date = DateTime.tryParse(c.date);
      _actionTakenCtrl.text = c.actionTaken ?? '';
      _assignedCtrl.text = c.assigned ?? '';
      _descriptionCtrl.text = c.description ?? '';
      _attachment = null;
      _attachmentError = null;
      _formBanner = null;
    });
    _scrollToTab(0);
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    setState(() => _formBanner = null);
    final formValid = _formKey.currentState!.validate();
    if (_complaintTypeId == null || _complaintSourceId == null || _date == null || _attachmentError != null || !formValid) {
      setState(() => _formBanner = 'Please fix the errors below before submitting.');
      return;
    }

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
      _resetForm();
      _scrollToTab(2);
    }
  }

  void _applyFilters() {
    final typeOptions = ref.read(complaintTypeOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    final sourceOptions = ref.read(complaintSourceOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    final typeName = _filterTypeId == null ? null : typeOptions.where((o) => o.id.toString() == _filterTypeId).map((o) => o.name).firstOrNull;
    final sourceName = _filterSourceId == null ? null : sourceOptions.where((o) => o.id.toString() == _filterSourceId).map((o) => o.name).firstOrNull;
    setState(() {
      _search = _filterSearchCtrl.text.trim();
      _typeFilterValue = _filterTypeId;
      _sourceFilterValue = _filterSourceId;
      _dateFilterValue = _filterDate == null ? null : _fmtDate(_filterDate!);
      _filterChips = [
        if (_search.isNotEmpty) 'Search: $_search',
        if (typeName != null) 'Type: $typeName',
        if (sourceName != null) 'Source: $sourceName',
        if (_filterDate != null) 'Date: ${_fmtDate(_filterDate!)}',
      ];
      _filterOpen = false;
    });
  }

  void _clearFilters() {
    _filterSearchCtrl.clear();
    setState(() {
      _filterTypeId = null;
      _filterSourceId = null;
      _filterDate = null;
      _search = '';
      _typeFilterValue = null;
      _sourceFilterValue = null;
      _dateFilterValue = null;
      _filterChips = [];
    });
  }

  void _removeChip(String chip) {
    if (chip.startsWith('Search:')) _filterSearchCtrl.clear();
    if (chip.startsWith('Type:')) _filterTypeId = null;
    if (chip.startsWith('Source:')) _filterSourceId = null;
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
    final state = ref.watch(complaintListProvider);
    final typeOptions = ref.watch(complaintTypeOptionsProvider);
    final sourceOptions = ref.watch(complaintSourceOptionsProvider);
    final typeItems = typeOptions.maybeWhen(data: (o) => o, orElse: () => const []);
    final sourceItems = sourceOptions.maybeWhen(data: (o) => o, orElse: () => const []);
    final isSaving = state.savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStepperNav(
            activeIndex: _activeTab,
            steps: [
              AdminStep(number: '01', icon: Icons.add, label: _editingId == null ? 'Add Complaint' : 'Edit Complaint'),
              const AdminStep(number: '02', icon: Icons.filter_alt_outlined, label: 'Smart Filter'),
              const AdminStep(number: '03', icon: Icons.description_outlined, label: 'Complaints List'),
            ],
            onTap: _scrollToTab,
          ),
          KeyedSubtree(
            key: _addKey,
            child: AdminStepFormCard(
              title: _editingId == null ? 'Register New Complaint' : 'Edit Complaint Details',
              subtitle: 'Fields marked with * are mandatory. Please provide accurate details for resolution tracking.',
              editingBadgeText: _editingId == null ? null : 'Editing Complaint By: ${_complaintByCtrl.text}',
              banner: _formBanner,
              isEditing: _editingId != null,
              saving: isSaving,
              onReset: _resetForm,
              onSave: _submit,
              footerHelperText: 'All records are securely saved into the complaint tracking module.',
              fields: [
                Form(
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
                          if (!RegExp(r"^[A-Za-z\s\-']+$").hasMatch(value)) return 'Only letters, spaces, hyphens, apostrophes allowed.';
                          return null;
                        },
                      ),
                      AdminDropdownField<String>(
                        label: 'Complaint Type',
                        required: true,
                        value: _complaintTypeId,
                        hint: 'Select Type',
                        items: typeItems.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name))).toList(),
                        onChanged: (v) => setState(() => _complaintTypeId = v),
                      ),
                      AdminDropdownField<String>(
                        label: 'Complaint Source',
                        required: true,
                        value: _complaintSourceId,
                        hint: 'Select Source',
                        items: sourceItems.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name))).toList(),
                        onChanged: (v) => setState(() => _complaintSourceId = v),
                      ),
                      AdminTextField(
                        label: 'Phone No.',
                        controller: _phoneCtrl,
                        hint: 'e.g. 9876543210',
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return null;
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) return 'Please enter a valid 10-digit mobile number.';
                          return null;
                        },
                      ),
                      AdminDateField(label: 'Date', required: true, value: _date, lastDate: DateTime.now(), onChanged: (d) => setState(() => _date = d)),
                      AdminTextField(label: 'Assigned To', controller: _assignedCtrl, hint: 'e.g. Mr. Sharma', maxLength: 100),
                      AdminTextField(label: 'Action Taken', controller: _actionTakenCtrl, hint: 'e.g. Called parent for discussion', maxLength: 500),
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
              subtitle: 'Find complaints easily by search, type, source, or date.',
              open: _filterOpen,
              onToggle: () => setState(() => _filterOpen = !_filterOpen),
              chips: _filterChips,
              onRemoveChip: _removeChip,
              onClearAll: _clearFilters,
              onApply: _applyFilters,
              onClear: _clearFilters,
              fields: [
                AdminTextField(label: 'Search', controller: _filterSearchCtrl, hint: 'Name, Phone...'),
                AdminDropdownField<String>(
                  label: 'Complaint Type',
                  value: _filterTypeId,
                  hint: 'All Types',
                  items: typeItems.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name))).toList(),
                  onChanged: (v) => setState(() => _filterTypeId = v),
                ),
                AdminDropdownField<String>(
                  label: 'Complaint Source',
                  value: _filterSourceId,
                  hint: 'All Sources',
                  items: sourceItems.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name))).toList(),
                  onChanged: (v) => setState(() => _filterSourceId = v),
                ),
                AdminDateField(label: 'Date', value: _filterDate, onChanged: (d) => setState(() => _filterDate = d)),
              ],
            ),
          ),
          KeyedSubtree(
            key: _listKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminBrowseHeading(stepNumber: '03', title: 'Browse Complaints'),
                Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (state.error != null) AdminMessageBanner(error: state.error),
                      AdminDataTable(
                        isLoading: state.isLoading,
                        emptyText: 'No complaints found matching criteria.',
                        columns: [
                          const AdminColumn('SL', width: 36),
                          AdminColumn('Complaint By', width: 130, onTap: () => _toggleSort('complaint_by'), sortArrow: _sortKey == 'complaint_by' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Phone', width: 100),
                          AdminColumn('Type', width: 90, onTap: () => _toggleSort('complaint_type'), sortArrow: _sortKey == 'complaint_type' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          AdminColumn('Source', width: 90, onTap: () => _toggleSort('complaint_source'), sortArrow: _sortKey == 'complaint_source' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          AdminColumn('Date', width: 100, onTap: () => _toggleSort('date'), sortArrow: _sortKey == 'date' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Actions', width: 90),
                        ],
                        rows: _buildRows(state),
                      ),
                      AdminPaginationBar(
                        page: state.page,
                        pageSize: state.pageSize,
                        totalCount: state.totalCount,
                        onPageChange: (p) => ref.read(complaintListProvider.notifier).setPage(p),
                        onPageSizeChange: (s) => ref.read(complaintListProvider.notifier).setPageSize(s),
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
    final notifier = ref.read(complaintListProvider.notifier);
    final visible = notifier.filtered((c, q) =>
        c.complaintBy.toLowerCase().contains(q) || (c.phone ?? '').toLowerCase().contains(q) || (c.complaintTypeName ?? '').toLowerCase().contains(q) || (c.complaintSourceName ?? '').toLowerCase().contains(q));

    // The deployed backend always returns `complaint_type`/`complaint_source`
    // resolved to the setup's NAME (never the id) — so the Smart Filter's
    // selected dropdown id must be resolved to that same name before
    // comparing against a saved complaint's value.
    final typeOptions = ref.read(complaintTypeOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    final sourceOptions = ref.read(complaintSourceOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    final typeFilterName = _typeFilterValue == null ? null : typeOptions.where((o) => o.id.toString() == _typeFilterValue).map((o) => o.name).firstOrNull;
    final sourceFilterName = _sourceFilterValue == null ? null : sourceOptions.where((o) => o.id.toString() == _sourceFilterValue).map((o) => o.name).firstOrNull;

    // Web's own Smart Filter (Type/Source/Date) applies on top of the free-text search.
    var filtered = visible;
    if (typeFilterName != null) filtered = filtered.where((c) => c.complaintTypeName == typeFilterName || c.complaintTypeId == typeFilterName).toList();
    if (sourceFilterName != null) filtered = filtered.where((c) => c.complaintSourceName == sourceFilterName || c.complaintSourceId == sourceFilterName).toList();
    if (_dateFilterValue != null) filtered = filtered.where((c) => c.date == _dateFilterValue).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((c) => c.complaintBy.toLowerCase().contains(q) || (c.phone ?? '').toLowerCase().contains(q)).toList();
    }

    final asc = _sortAsc ?? false;
    filtered.sort((a, b) {
      final mult = asc ? 1 : -1;
      switch (_sortKey) {
        case 'complaint_by':
          return a.complaintBy.compareTo(b.complaintBy) * mult;
        case 'complaint_type':
          return (a.complaintTypeName ?? '').compareTo(b.complaintTypeName ?? '') * mult;
        case 'complaint_source':
          return (a.complaintSourceName ?? '').compareTo(b.complaintSourceName ?? '') * mult;
        default:
          return a.date.compareTo(b.date) * mult;
      }
    });

    return List.generate(filtered.length, (index) {
      final c = filtered[index];
      return [
        Text('${(state.page - 1) * state.pageSize + index + 1}', style: const TextStyle(fontSize: 12.5)),
        Text(c.complaintBy, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        _naText(c.phone),
        _naText(c.complaintTypeName ?? c.complaintTypeId),
        _naText(c.complaintSourceName ?? c.complaintSourceId),
        Text(c.date, style: const TextStyle(fontSize: 12.5)),
        AdminIconActionButtons(
          onEdit: () => _loadForEdit(c),
          isDeleting: state.deletingId == c.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(context, message: 'Are you sure you want to delete this complaint record? This action cannot be undone.');
            if (confirmed && c.id != null) {
              await ref.read(complaintListProvider.notifier).remove(c.id!);
            }
          },
        ),
      ];
    });
  }

  Widget _naText(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '-') {
      return const Text('N/A', style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.textTertiary));
    }
    return Text(value, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis);
  }
}
