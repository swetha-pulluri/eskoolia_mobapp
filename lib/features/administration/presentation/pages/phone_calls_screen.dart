import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/phone_call_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_breadcrumb_header.dart';
import '../widgets/web_button.dart';

/// Phone Calls — converted from web `PhoneCallLogPanel.tsx`.
/// Sub-tab of Communication Hub.
class PhoneCallsScreen extends ConsumerStatefulWidget {
  const PhoneCallsScreen({super.key});

  @override
  ConsumerState<PhoneCallsScreen> createState() => _PhoneCallsScreenState();
}

enum _SortKey { name, phone, date, nextFollowUpDate, callDuration, callType }

class _PhoneCallsScreenState extends ConsumerState<PhoneCallsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate;
  String _callType = 'I';
  int? _editingId;

  _SortKey _sortKey = _SortKey.date;
  bool _sortAsc = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _durationCtrl.dispose();
    _descriptionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _durationCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _fromDate = DateTime.now();
      _toDate = null;
      _callType = 'I';
      _editingId = null;
    });
  }

  void _loadForEdit(PhoneCallEntity c) {
    setState(() {
      _editingId = c.id;
      _nameCtrl.text = c.name;
      _phoneCtrl.text = c.phone;
      _fromDate = DateTime.tryParse(c.date);
      _toDate = c.nextFollowUpDate != null ? DateTime.tryParse(c.nextFollowUpDate!) : null;
      _durationCtrl.text = c.callDuration ?? '';
      _descriptionCtrl.text = c.description ?? '';
      _callType = c.callType;
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

  Future<void> _submit() async {
    if (_fromDate == null) {
      _showFieldError('From Date is required.');
      return;
    }
    if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
      _showFieldError('To Date cannot be before From Date.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final call = PhoneCallEntity(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      date: _fmtDate(_fromDate!),
      nextFollowUpDate: _toDate != null ? _fmtDate(_toDate!) : null,
      callDuration: _durationCtrl.text.trim().isEmpty ? null : _durationCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      callType: _callType,
    );

    final notifier = ref.read(phoneCallListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(call) : await notifier.edit(_editingId!, call);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Phone call log added successfully.' : 'Phone call log updated successfully.')),
      );
      _resetForm();
    }
  }

  void _showFieldError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.dangerRed));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneCallListProvider);
    final isSaving = state.savingId != null;
    final arrow = _sortAsc ? '▲' : '▼';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Phone Call Log'),
          AdminSectionCard(
            title: _editingId == null ? 'Add Phone Call' : 'Edit Phone Call',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminTextField(
                    label: 'Name',
                    required: true,
                    controller: _nameCtrl,
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
                    label: 'Phone',
                    required: true,
                    controller: _phoneCtrl,
                    hint: 'e.g. 9876543210 or +919876543210',
                    keyboardType: TextInputType.phone,
                    maxLength: 13,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Phone is required.';
                      if (!RegExp(r'^\+?\d{10,12}$').hasMatch(value)) return 'Phone number must be 10-12 digits.';
                      return null;
                    },
                  ),
                  AdminDateField(
                    label: 'From Date',
                    required: true,
                    value: _fromDate,
                    lastDate: DateTime.now(),
                    onChanged: (d) => setState(() {
                      _fromDate = d;
                      if (_toDate != null && d != null && _toDate!.isBefore(d)) _toDate = d;
                    }),
                  ),
                  AdminDateField(
                    label: 'To Date',
                    value: _toDate,
                    firstDate: _fromDate,
                    lastDate: DateTime.now(),
                    onChanged: (d) => setState(() => _toDate = d),
                  ),
                  AdminTextField(
                    label: 'Call Duration (HH:MM:SS)',
                    controller: _durationCtrl,
                    hint: 'HH:MM:SS',
                    maxLength: 8,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (!RegExp(r'^([0-9]{1,2}):([0-5][0-9]):([0-5][0-9])$').hasMatch(value)) {
                        return 'Enter duration in HH:MM:SS format (e.g., 00:10:00).';
                      }
                      return null;
                    },
                  ),
                  AdminTextField(
                    label: 'Description',
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    counterBuilder: (n) => '$n / 500 characters',
                  ),
                  AdminRadioGroup<String>(
                    label: 'Call Type',
                    value: _callType,
                    options: const [('I', 'Incoming'), ('O', 'Outgoing')],
                    onChanged: (v) => setState(() => _callType = v ?? 'I'),
                  ),
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
            title: 'Phone Call List',
            trailing: SizedBox(
              width: 160,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Quick search', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => ref.read(phoneCallListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              children: [
                if (state.error != null) const AdminMessageBanner(error: 'Unable to load phone call logs.'),
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No phone calls found.',
                  zebraStripe: true,
                  columns: [
                    AdminColumn('Name', width: 110, onTap: () => _toggleSort(_SortKey.name), sortArrow: _sortKey == _SortKey.name ? arrow : ''),
                    AdminColumn('Phone', width: 100, onTap: () => _toggleSort(_SortKey.phone), sortArrow: _sortKey == _SortKey.phone ? arrow : ''),
                    AdminColumn('From', width: 90, onTap: () => _toggleSort(_SortKey.date), sortArrow: _sortKey == _SortKey.date ? arrow : ''),
                    AdminColumn('To', width: 90, onTap: () => _toggleSort(_SortKey.nextFollowUpDate), sortArrow: _sortKey == _SortKey.nextFollowUpDate ? arrow : ''),
                    AdminColumn('Duration', width: 80, onTap: () => _toggleSort(_SortKey.callDuration), sortArrow: _sortKey == _SortKey.callDuration ? arrow : ''),
                    const AdminColumn('Description', width: 100),
                    AdminColumn('Type', width: 80, onTap: () => _toggleSort(_SortKey.callType), sortArrow: _sortKey == _SortKey.callType ? arrow : ''),
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
                  pageSizeOptions: const [10, 25, 50],
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
    final notifier = ref.read(phoneCallListProvider.notifier);
    final visible = notifier.filtered((c, q) =>
        c.name.toLowerCase().contains(q) ||
        c.phone.toLowerCase().contains(q) ||
        (c.description ?? '').toLowerCase().contains(q));

    visible.sort((a, b) {
      final mult = _sortAsc ? 1 : -1;
      switch (_sortKey) {
        case _SortKey.name:
          return a.name.compareTo(b.name) * mult;
        case _SortKey.phone:
          return a.phone.compareTo(b.phone) * mult;
        case _SortKey.date:
          return a.date.compareTo(b.date) * mult;
        case _SortKey.nextFollowUpDate:
          return (a.nextFollowUpDate ?? '').compareTo(b.nextFollowUpDate ?? '') * mult;
        case _SortKey.callDuration:
          return (a.callDuration ?? '').compareTo(b.callDuration ?? '') * mult;
        case _SortKey.callType:
          return a.callType.compareTo(b.callType) * mult;
      }
    });

    return List.generate(visible.length, (index) {
      final c = visible[index];
      return [
        Text(c.name, style: const TextStyle(fontSize: 12.5)),
        Text(c.phone, style: const TextStyle(fontSize: 12.5)),
        Text(c.date, style: const TextStyle(fontSize: 12.5)),
        Text(c.nextFollowUpDate ?? '-', style: const TextStyle(fontSize: 12.5)),
        Text(c.callDuration ?? '-', style: const TextStyle(fontSize: 12.5)),
        Text(c.description ?? '-', style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        Text(c.callType == 'I' ? 'Incoming' : 'Outgoing', style: const TextStyle(fontSize: 12.5)),
        AdminRowActions(
          onEdit: () => _loadForEdit(c),
          isDeleting: state.deletingId == c.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
              context,
              message: 'Are you sure you want to delete this phone call log? This action cannot be undone.',
              confirmLabel: 'Delete',
            );
            if (confirmed && c.id != null) {
              await ref.read(phoneCallListProvider.notifier).remove(c.id!);
            }
          },
        ),
      ];
    });
  }
}
