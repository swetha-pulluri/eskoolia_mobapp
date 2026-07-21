import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/web_button.dart';

/// Visitor Book — converted from web `VisitorBookPanel.tsx`.
/// Sub-tab of Communication Hub.
class VisitorBookScreen extends ConsumerStatefulWidget {
  const VisitorBookScreen({super.key});

  @override
  ConsumerState<VisitorBookScreen> createState() => _VisitorBookScreenState();
}

class _VisitorBookScreenState extends ConsumerState<VisitorBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _personsCtrl = TextEditingController(text: '1');
  final _searchCtrl = TextEditingController();

  String? _purposeId;
  DateTime? _date = DateTime.now();
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  int? _editingId;
  String? _timeError;
  bool? _sortAsc; // null = no explicit sort yet (natural API order), matches web default
  String? _formBanner;
  String? _success;
  PickedAttachment? _attachment;
  String? _attachmentError;

  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];

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
        _attachmentError = 'Attachment must be 5MB or smaller.';
        _attachment = null;
      } else {
        _attachmentError = null;
        _attachment = PickedAttachment(name: file.name, bytes: file.bytes!, size: file.size);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _personsCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _personsCtrl.text = '1';
    setState(() {
      _purposeId = null;
      _date = DateTime.now();
      _inTime = null;
      _outTime = null;
      _editingId = null;
      _timeError = null;
      _formBanner = null;
      _attachment = null;
      _attachmentError = null;
    });
  }

  void _loadForEdit(VisitorEntity v) {
    setState(() {
      _editingId = v.id;
      _purposeId = v.purposeId;
      _nameCtrl.text = v.name;
      _phoneCtrl.text = v.phone ?? '';
      _personsCtrl.text = v.noOfPerson.toString();
      _date = DateTime.tryParse(v.date);
      _inTime = _parseTime(v.inTime);
      _outTime = _parseTime(v.outTime);
      _attachment = null;
      _attachmentError = null;
    });
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    setState(() {
      _timeError = null;
      _formBanner = null;
    });
    if (_purposeId == null ||
        _date == null ||
        _inTime == null ||
        _outTime == null ||
        _attachmentError != null ||
        !_formKey.currentState!.validate()) {
      setState(() => _formBanner = 'Please fix the errors below before submitting.');
      return;
    }

    final inMinutes = _inTime!.hour * 60 + _inTime!.minute;
    final outMinutes = _outTime!.hour * 60 + _outTime!.minute;
    if (outMinutes <= inMinutes) {
      setState(() {
        _timeError = 'Out time must be after in time.';
        _formBanner = 'Please fix the errors below before submitting.';
      });
      return;
    }

    final visitor = VisitorEntity(
      purposeId: _purposeId,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      noOfPerson: int.tryParse(_personsCtrl.text.trim()) ?? 1,
      date: _fmtDate(_date!),
      inTime: _fmtTime(_inTime!),
      outTime: _fmtTime(_outTime!),
      attachment: _attachment,
    );

    final wasEditing = _editingId != null;
    final notifier = ref.read(visitorListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(visitor) : await notifier.edit(_editingId!, visitor);

    if (!mounted) return;
    if (ok) {
      setState(() => _success = wasEditing ? 'Record updated successfully.' : 'Record created successfully.');
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitorListProvider);
    final purposeOptions = ref.watch(purposeOptionsProvider);
    final isSaving = state.savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionCard(
            title: _editingId == null ? 'Add Visitor' : 'Edit Visitor',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('Fields marked with * are mandatory.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ),
                  if (_formBanner != null) AdminMessageBanner(error: _formBanner),
                  // The Purpose <select> is always present on web, even if
                  // the admin-setups fetch fails (it just renders with no
                  // options) — the dropdown must never disappear entirely,
                  // or the (required) field becomes impossible to fill in.
                  AdminDropdownField<String>(
                    label: 'Purpose',
                    required: true,
                    value: _purposeId,
                    hint: 'Select Purpose *',
                    items: purposeOptions
                            .maybeWhen(data: (options) => options, orElse: () => const [])
                            .map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name)))
                            .toList(),
                    onChanged: (v) => setState(() => _purposeId = v),
                  ),
                  if (purposeOptions.isLoading)
                    const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                  if (purposeOptions.hasError)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Unable to load purpose options.', style: TextStyle(color: AppColors.dangerRed, fontSize: 12)),
                    ),
                  AdminTextField(
                    label: 'Name',
                    required: true,
                    controller: _nameCtrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required.';
                      if (!RegExp(r"^[A-Za-z\s\-']+$").hasMatch(v.trim())) {
                        return 'Name must contain only letters, spaces, and hyphens';
                      }
                      return null;
                    },
                  ),
                  AdminTextField(
                    label: 'Phone',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 13,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!RegExp(r'^\+?\d{10,12}$').hasMatch(v.trim())) return 'Phone number must be 10-12 digits';
                      return null;
                    },
                  ),
                  AdminTextField(
                    label: 'Number of Persons',
                    required: true,
                    controller: _personsCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1 || n > 99) return 'Enter a valid number of persons';
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
                  Row(
                    children: [
                      Expanded(
                        child: AdminTimeField(
                          label: 'In Time',
                          required: true,
                          value: _inTime,
                          errorText: _timeError,
                          onChanged: (t) => setState(() {
                            _inTime = t;
                            _timeError = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdminTimeField(
                          label: 'Out Time',
                          required: true,
                          value: _outTime,
                          onChanged: (t) => setState(() {
                            _outTime = t;
                            _timeError = null;
                          }),
                        ),
                      ),
                    ],
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
            title: 'Visitor List',
            trailing: SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Quick search', isDense: true),
                onChanged: (v) => ref.read(visitorListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              children: [
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No visitor records found.',
                  columns: [
                    const AdminColumn('SL', width: 40),
                    AdminColumn(
                      'Name',
                      width: 120,
                      onTap: () => setState(() => _sortAsc = _sortAsc == true ? false : true),
                    ),
                    const AdminColumn('Phone', width: 110),
                    const AdminColumn('Purpose', width: 110),
                    const AdminColumn('Date', width: 100),
                    const AdminColumn('Actions', width: 90),
                  ],
                  rows: _buildRows(state),
                ),
                AdminPaginationBar(
                  page: state.page,
                  pageSize: state.pageSize,
                  totalCount: state.totalCount,
                  onPageChange: (p) => ref.read(visitorListProvider.notifier).setPage(p),
                  onPageSizeChange: (s) => ref.read(visitorListProvider.notifier).setPageSize(s),
                  pageSizeOptions: const [5, 10, 20, 30, 40, 50],
                  summaryStyle: PaginationSummaryStyle.pageOfTotal,
                  previousColor: const Color(0xFF64748B),
                  nextColor: const Color(0xFF0F766E),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(state.error!, style: const TextStyle(color: AppColors.warningAmber, fontSize: 12)),
                  ),
                if (!state.isLoading && _success != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_success!, style: const TextStyle(color: Color(0xFF0F766E), fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<List<Widget>> _buildRows(dynamic state) {
    final notifier = ref.read(visitorListProvider.notifier);
    final visible = notifier.filtered((v, q) =>
        v.name.toLowerCase().contains(q) ||
        (v.purposeName ?? '').toLowerCase().contains(q) ||
        (v.phone ?? '').toLowerCase().contains(q));
    // Web only sorts by Name once the header is clicked; before that it
    // keeps whatever order the API returned (no forced default sort).
    if (_sortAsc != null) {
      visible.sort((a, b) => _sortAsc! ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    }

    return List.generate(visible.length, (index) {
      final v = visible[index];
      return [
        Text('${(state.page - 1) * state.pageSize + index + 1}', style: const TextStyle(fontSize: 12.5)),
        Text(v.name, style: const TextStyle(fontSize: 12.5)),
        _naText(v.phone),
        _naText(v.purposeName),
        Text(v.date, style: const TextStyle(fontSize: 12.5)),
        AdminRowActions(
          onEdit: () => _loadForEdit(v),
          isDeleting: state.deletingId == v.id,
          onDelete: () async {
            final confirmed = await showVisitorBookDeleteDialog(
              context,
              message: 'Are you sure you want to delete this visitor record? This action cannot be undone.',
            );
            if (confirmed && v.id != null) {
              await ref.read(visitorListProvider.notifier).remove(v.id!);
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
    return Text(value, style: const TextStyle(fontSize: 12.5));
  }
}
