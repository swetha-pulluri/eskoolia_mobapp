import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_stepper_shell.dart';

/// Phone Calls — Communication Hub. Data contract verified against
/// `main`'s real `PhoneCallLogPanel.tsx` (the branch actually served by the
/// running frontend dev server). The stepper nav/card shell (3-step
/// numbered nav) matches `origin/demo`'s redesigned layout, not `main`'s
/// plain panel — a known, disclosed visual difference, out of scope for
/// this pass.
class PhoneCallsScreen extends ConsumerStatefulWidget {
  const PhoneCallsScreen({super.key});

  @override
  ConsumerState<PhoneCallsScreen> createState() => _PhoneCallsScreenState();
}

class _PhoneCallsScreenState extends ConsumerState<PhoneCallsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _filterSearchCtrl = TextEditingController();

  final _addKey = GlobalKey();
  final _filterKey = GlobalKey();
  final _listKey = GlobalKey();

  int _activeTab = 0;
  bool _filterOpen = false;
  String? _filterCallType;
  DateTime? _filterDate;
  List<String> _filterChips = [];
  String _search = '';
  String? _typeFilterValue;
  String? _dateFilterValue;

  DateTime? _date = DateTime.now();
  DateTime? _followUpDate;
  String _callType = 'I';
  int? _editingId;
  String _sortKey = 'date';
  bool? _sortAsc;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _durationCtrl.dispose();
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
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _durationCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _date = DateTime.now();
      _followUpDate = null;
      _callType = 'I';
      _editingId = null;
    });
  }

  void _loadForEdit(PhoneCallEntity c) {
    setState(() {
      _editingId = c.id;
      _nameCtrl.text = c.name;
      _phoneCtrl.text = c.phone;
      _date = DateTime.tryParse(c.date);
      _followUpDate = c.nextFollowUpDate != null ? DateTime.tryParse(c.nextFollowUpDate!) : null;
      _durationCtrl.text = c.callDuration ?? '';
      _descriptionCtrl.text = c.description ?? '';
      _callType = c.callType;
    });
    _scrollToTab(0);
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_date == null) return;
    if (_followUpDate != null && _followUpDate!.isBefore(_date!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up date cannot be before the call date.'), backgroundColor: AppColors.dangerRed),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final call = PhoneCallEntity(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      date: _fmtDate(_date!),
      nextFollowUpDate: _followUpDate != null ? _fmtDate(_followUpDate!) : null,
      callDuration: _durationCtrl.text.trim().isEmpty ? null : _durationCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      callType: _callType,
    );

    final notifier = ref.read(phoneCallListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(call) : await notifier.edit(_editingId!, call);

    if (!mounted) return;
    if (ok) {
      _resetForm();
      _scrollToTab(2);
    }
  }

  void _applyFilters() {
    setState(() {
      _search = _filterSearchCtrl.text.trim();
      _typeFilterValue = _filterCallType;
      _dateFilterValue = _filterDate == null ? null : _fmtDate(_filterDate!);
      _filterChips = [
        if (_search.isNotEmpty) 'Search: $_search',
        if (_filterCallType != null) 'Type: ${_filterCallType == 'I' ? 'Incoming' : 'Outgoing'}',
        if (_filterDate != null) 'Date: ${_fmtDate(_filterDate!)}',
      ];
      _filterOpen = false;
    });
  }

  void _clearFilters() {
    _filterSearchCtrl.clear();
    setState(() {
      _filterCallType = null;
      _filterDate = null;
      _search = '';
      _typeFilterValue = null;
      _dateFilterValue = null;
      _filterChips = [];
    });
  }

  void _removeChip(String chip) {
    if (chip.startsWith('Search:')) _filterSearchCtrl.clear();
    if (chip.startsWith('Type:')) _filterCallType = null;
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
    final state = ref.watch(phoneCallListProvider);
    final isSaving = state.savingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStepperNav(
            activeIndex: _activeTab,
            steps: [
              AdminStep(number: '01', icon: Icons.add, label: _editingId == null ? 'Add Phone Call' : 'Edit Phone Call'),
              const AdminStep(number: '02', icon: Icons.filter_alt_outlined, label: 'Smart Filter'),
              const AdminStep(number: '03', icon: Icons.description_outlined, label: 'Call Logs'),
            ],
            onTap: _scrollToTab,
          ),
          KeyedSubtree(
            key: _addKey,
            child: AdminStepFormCard(
              title: _editingId == null ? 'Log New Phone Call' : 'Edit Phone Call Details',
              subtitle: 'Fields marked with * are mandatory. Keep records of important incoming and outgoing calls.',
              editingBadgeText: _editingId == null ? null : 'Editing Log: ${_nameCtrl.text}',
              isEditing: _editingId != null,
              saving: isSaving,
              onReset: _resetForm,
              onSave: _submit,
              footerHelperText: 'All records are securely saved into the communication log module.',
              fields: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminTextField(
                        label: 'Caller Name',
                        required: true,
                        controller: _nameCtrl,
                        hint: 'Enter name',
                        maxLength: 100,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Name is required.';
                          if (value.length < 2) return 'Name must be at least 2 characters.';
                          if (!RegExp(r"^[A-Za-z0-9\s\-'.,()]+$").hasMatch(value)) return 'Invalid characters in Name.';
                          return null;
                        },
                      ),
                      AdminTextField(
                        label: 'Phone No.',
                        required: true,
                        controller: _phoneCtrl,
                        hint: 'e.g. +919876543210',
                        keyboardType: TextInputType.phone,
                        maxLength: 13,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Phone is required.';
                          if (!RegExp(r'^\+?\d{10,12}$').hasMatch(value)) return 'Phone number must be 10-12 digits.';
                          return null;
                        },
                      ),
                      AdminDropdownField<String>(
                        label: 'Call Type',
                        required: true,
                        value: _callType,
                        hint: 'Select Call Type',
                        items: const [
                          DropdownMenuItem(value: 'I', child: Text('Incoming')),
                          DropdownMenuItem(value: 'O', child: Text('Outgoing')),
                        ],
                        onChanged: (v) => setState(() => _callType = v ?? 'I'),
                      ),
                      AdminDateField(
                        label: 'Date',
                        required: true,
                        value: _date,
                        lastDate: DateTime.now(),
                        onChanged: (d) => setState(() {
                          _date = d;
                          if (_followUpDate != null && d != null && _followUpDate!.isBefore(d)) _followUpDate = d;
                        }),
                      ),
                      AdminDateField(
                        label: 'Follow-up Date',
                        value: _followUpDate,
                        firstDate: _date,
                        lastDate: DateTime.now(),
                        onChanged: (d) => setState(() => _followUpDate = d),
                      ),
                      AdminTextField(
                        label: 'Call Duration',
                        required: true,
                        controller: _durationCtrl,
                        hint: 'HH:MM:SS',
                        maxLength: 8,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Call Duration is required.';
                          if (!RegExp(r'^([0-9]{1,2}):([0-5][0-9]):([0-5][0-9])$').hasMatch(value)) {
                            return 'Enter duration in HH:MM:SS format (e.g., 00:10:00).';
                          }
                          return null;
                        },
                      ),
                      AdminTextField(
                        label: 'Description',
                        controller: _descriptionCtrl,
                        hint: 'Brief summary of the call',
                        maxLines: 3,
                        maxLength: 500,
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
              subtitle: 'Find call logs easily by search, type, or date.',
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
                  label: 'Call Type',
                  value: _filterCallType,
                  hint: 'All Types',
                  items: const [
                    DropdownMenuItem(value: 'I', child: Text('Incoming')),
                    DropdownMenuItem(value: 'O', child: Text('Outgoing')),
                  ],
                  onChanged: (v) => setState(() => _filterCallType = v),
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
                const AdminBrowseHeading(stepNumber: '03', title: 'Browse Call Logs'),
                Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.borderPrimary), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (state.error != null) const AdminMessageBanner(error: 'Unable to load phone call logs.'),
                      AdminDataTable(
                        isLoading: state.isLoading,
                        emptyText: 'No phone call records found matching criteria.',
                        columns: [
                          const AdminColumn('SL', width: 36),
                          AdminColumn('Name', width: 110, onTap: () => _toggleSort('name'), sortArrow: _sortKey == 'name' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Phone', width: 100),
                          const AdminColumn('Type', width: 80),
                          AdminColumn('Date', width: 95, onTap: () => _toggleSort('date'), sortArrow: _sortKey == 'date' ? (_sortAsc == false ? '↓' : '↑') : ''),
                          const AdminColumn('Duration', width: 80),
                          const AdminColumn('Follow-up', width: 90),
                          const AdminColumn('Actions', width: 90),
                        ],
                        rows: _buildRows(state),
                      ),
                      AdminPaginationBar(
                        page: state.page,
                        pageSize: state.pageSize,
                        totalCount: state.totalCount,
                        onPageChange: (p) => ref.read(phoneCallListProvider.notifier).setPage(p),
                        onPageSizeChange: (s) => ref.read(phoneCallListProvider.notifier).setPageSize(s),
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
    final notifier = ref.read(phoneCallListProvider.notifier);
    final visible = notifier.filtered((c, q) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q));

    var filtered = visible;
    if (_typeFilterValue != null) filtered = filtered.where((c) => c.callType == _typeFilterValue).toList();
    if (_dateFilterValue != null) filtered = filtered.where((c) => c.date == _dateFilterValue).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((c) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q)).toList();
    }

    // Only Name/Date are sortable on web — Type has no click handler there.
    final asc = _sortAsc ?? false;
    filtered.sort((a, b) {
      final mult = asc ? 1 : -1;
      return _sortKey == 'name' ? a.name.compareTo(b.name) * mult : a.date.compareTo(b.date) * mult;
    });

    return List.generate(filtered.length, (index) {
      final c = filtered[index];
      return [
        Text('${(state.page - 1) * state.pageSize + index + 1}', style: const TextStyle(fontSize: 12.5)),
        Text(c.name, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        _naText(c.phone),
        Text(c.callType == 'I' ? 'Incoming' : 'Outgoing', style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(c.date, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        _naText(c.callDuration),
        _naText(c.nextFollowUpDate),
        AdminIconActionButtons(
          onEdit: () => _loadForEdit(c),
          isDeleting: state.deletingId == c.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(context, message: 'Are you sure you want to delete this phone call log? This action cannot be undone.');
            if (confirmed && c.id != null) {
              await ref.read(phoneCallListProvider.notifier).remove(c.id!);
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
