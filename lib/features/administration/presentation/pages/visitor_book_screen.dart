import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/visitor_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_stepper_shell.dart';

/// Visitor Book — Communication Hub. Data contract (Purpose dropdown,
/// fields, validation) verified directly against `main`'s real
/// `VisitorBookPanel.tsx` — confirmed to be the branch actually served by
/// the running frontend dev server (its process working directory is this
/// checkout's `frontend/` on `main`). Note: the stepper nav/card shell
/// below (3-step numbered nav) was built to match `origin/demo`'s
/// redesigned layout, which is NOT what `main`'s plain single-column panel
/// looks like — that's a known, disclosed visual difference from the
/// literal live page, out of scope for this pass (only data-layer/overflow
/// bugs were fixed here).
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
  final _filterSearchCtrl = TextEditingController();

  final _addKey = GlobalKey();
  final _filterKey = GlobalKey();
  final _listKey = GlobalKey();

  int _activeTab = 0;
  bool _filterOpen = false;
  String? _filterPurposeId;
  DateTime? _filterDate;
  List<String> _filterChips = [];

  String? _purposeId;
  DateTime? _date = DateTime.now();
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  int? _editingId;
  String? _timeError;
  bool? _sortAsc; // null = default (date desc, matches web's initial sortKey="date")
  String _sortKey = 'date';
  String? _formBanner;
  PickedAttachment? _attachment;
  String? _attachmentError;

  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];

  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles(
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

  /// The backend always returns `purpose` (and `purpose_name`) as the
  /// resolved setup **name**, never the numeric id — so the dropdown,
  /// keyed by id, must resolve the real id by matching name (falling back
  /// to id-string equality), the same dual-match web does in `editRow`.
  String? _resolvePurposeId(VisitorEntity v) {
    final options = ref.read(purposeOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    for (final o in options) {
      if (o.id.toString() == v.purposeId || o.name == v.purposeId || o.name == v.purposeName) {
        return o.id.toString();
      }
    }
    return v.purposeId;
  }

  void _loadForEdit(VisitorEntity v) {
    setState(() {
      _editingId = v.id;
      _purposeId = _resolvePurposeId(v);
      _nameCtrl.text = v.name;
      _phoneCtrl.text = v.phone ?? '';
      _personsCtrl.text = v.noOfPerson.toString();
      _date = DateTime.tryParse(v.date);
      _inTime = _parseTime(v.inTime);
      _outTime = _parseTime(v.outTime);
      _attachment = null;
      _attachmentError = null;
    });
    _scrollToTab(0);
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

    final notifier = ref.read(visitorListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(visitor) : await notifier.edit(_editingId!, visitor);

    if (!mounted) return;
    if (ok) {
      _resetForm();
      _scrollToTab(2);
    }
  }

  void _applyFilters() {
    final purposeOptions = ref.read(purposeOptionsProvider).maybeWhen(data: (o) => o, orElse: () => const []);
    final purposeName = _filterPurposeId == null
        ? null
        : purposeOptions.where((o) => o.id.toString() == _filterPurposeId).map((o) => o.name).firstOrNull;
    final chips = <String>[
      if (_filterSearchCtrl.text.trim().isNotEmpty) 'Search: ${_filterSearchCtrl.text.trim()}',
      if (purposeName != null) 'Purpose: $purposeName',
      if (_filterDate != null) 'Date: ${_fmtDate(_filterDate!)}',
    ];
    setState(() {
      _filterChips = chips;
      _filterOpen = false;
    });
    ref.read(visitorFilterProvider.notifier).state = (
      search: _filterSearchCtrl.text.trim(),
      purposeId: _filterPurposeId,
      purposeName: purposeName,
      date: _filterDate == null ? null : _fmtDate(_filterDate!),
    );
  }

  void _clearFilters() {
    _filterSearchCtrl.clear();
    setState(() {
      _filterPurposeId = null;
      _filterDate = null;
      _filterChips = [];
    });
    ref.read(visitorFilterProvider.notifier).state = (search: '', purposeId: null, purposeName: null, date: null);
  }

  void _removeChip(String chip) {
    if (chip.startsWith('Search:')) _filterSearchCtrl.clear();
    if (chip.startsWith('Purpose:')) _filterPurposeId = null;
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
    final state = ref.watch(visitorListProvider);
    final purposeOptions = ref.watch(purposeOptionsProvider);
    final isSaving = state.savingId != null;
    final purposeItems = purposeOptions.maybeWhen(data: (o) => o, orElse: () => const []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStepperNav(
            activeIndex: _activeTab,
            steps: [
              AdminStep(number: '01', icon: Icons.add, label: _editingId == null ? 'Add Visitor' : 'Edit Visitor'),
              const AdminStep(number: '02', icon: Icons.filter_alt_outlined, label: 'Smart Filter'),
              const AdminStep(number: '03', icon: Icons.description_outlined, label: 'Visitor List'),
            ],
            onTap: _scrollToTab,
          ),
          KeyedSubtree(
            key: _addKey,
            child: AdminStepFormCard(
              title: _editingId == null ? 'Register New Visitor' : 'Edit Visitor Details',
              subtitle: 'Fields marked with * are mandatory. Please fill in the visitor information accurately.',
              editingBadgeText: _editingId == null ? null : 'Editing Visitor: ${_nameCtrl.text}',
              banner: _formBanner,
              isEditing: _editingId != null,
              saving: isSaving,
              onReset: _resetForm,
              onSave: _submit,
              footerHelperText: 'All records are securely saved into the visitor log module.',
              fields: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminDropdownField<String>(
                        label: 'Purpose',
                        required: true,
                        value: _purposeId,
                        hint: 'Select Purpose *',
                        items: purposeItems.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name))).toList(),
                        onChanged: (v) => setState(() => _purposeId = v),
                      ),
                      if (purposeOptions.isLoading)
                        const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                      AdminTextField(
                        label: 'Student / Visitor Name',
                        required: true,
                        controller: _nameCtrl,
                        hint: 'Enter name',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Name is required.';
                          if (!RegExp(r"^[A-Za-z\s\-']+$").hasMatch(v.trim())) {
                            return 'Name must contain only letters, spaces, and hyphens';
                          }
                          return null;
                        },
                      ),
                      AdminTextField(
                        label: 'Phone No.',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 13,
                        hint: 'e.g. +919876543210',
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
              subtitle: 'Find visitors easily by search, purpose, or date.',
              open: _filterOpen,
              onToggle: () => setState(() => _filterOpen = !_filterOpen),
              chips: _filterChips,
              onRemoveChip: _removeChip,
              onClearAll: _clearFilters,
              onApply: _applyFilters,
              onClear: _clearFilters,
              fields: [
                AdminTextField(label: 'Search', controller: _filterSearchCtrl, hint: 'Name, Phone, ID...'),
                AdminDropdownField<String>(
                  label: 'Purpose',
                  value: _filterPurposeId,
                  hint: 'Any Purpose',
                  items: purposeItems.map<DropdownMenuItem<String>>((o) => DropdownMenuItem(value: o.id.toString(), child: Text(o.name))).toList(),
                  onChanged: (v) => setState(() => _filterPurposeId = v),
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
                const AdminBrowseHeading(stepNumber: '03', title: 'Browse Visitor List'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.borderPrimary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      AdminDataTable(
                        isLoading: state.isLoading,
                        emptyText: 'No visitor records found matching criteria.',
                        columns: [
                          const AdminColumn('SL', width: 36),
                          AdminColumn('Name', width: 120, onTap: () => _toggleSort('name'), sortArrow: _sortKey == 'name' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Phone', width: 110),
                          const AdminColumn('Purpose', width: 110),
                          AdminColumn('Date', width: 100, onTap: () => _toggleSort('date'), sortArrow: _sortKey == 'date' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Actions', width: 90),
                        ],
                        rows: _buildRows(state),
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(state.error!, style: const TextStyle(color: AppColors.warningAmber, fontSize: 12)),
                        ),
                      AdminPaginationBar(
                        page: state.page,
                        pageSize: state.pageSize,
                        totalCount: state.totalCount,
                        onPageChange: (p) => ref.read(visitorListProvider.notifier).setPage(p),
                        onPageSizeChange: (s) => ref.read(visitorListProvider.notifier).setPageSize(s),
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
    final notifier = ref.read(visitorListProvider.notifier);
    final visible = notifier.filtered((v, q) =>
        v.name.toLowerCase().contains(q) ||
        (v.purposeName ?? '').toLowerCase().contains(q) ||
        (v.phone ?? '').toLowerCase().contains(q));
    // Default sort matches web's `sortKey="date", sortDir="desc"`, always applied.
    final asc = _sortAsc ?? false;
    visible.sort((a, b) {
      final mult = asc ? 1 : -1;
      return _sortKey == 'name' ? a.name.compareTo(b.name) * mult : a.date.compareTo(b.date) * mult;
    });

    return List.generate(visible.length, (index) {
      final v = visible[index];
      return [
        Text('${(state.page - 1) * state.pageSize + index + 1}', style: const TextStyle(fontSize: 12.5)),
        Text(v.name, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        _naText(v.phone),
        _naText(v.purposeName),
        Text(v.date, style: const TextStyle(fontSize: 12.5)),
        AdminIconActionButtons(
          onEdit: () => _loadForEdit(v),
          isDeleting: state.deletingId == v.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
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
    return Text(value, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis);
  }
}
