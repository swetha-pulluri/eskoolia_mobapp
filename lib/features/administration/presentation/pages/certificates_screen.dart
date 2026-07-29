import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_breadcrumb_header.dart';
import '../widgets/web_button.dart';

/// Certificates — Design Template — converted from web `CertificatePanel.tsx`.
/// Sub-tab of Documents Studio ("Certificates" main tab / "Design Template" sub-tab).
class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _heightCtrl = TextEditingController(text: '144');
  final _widthCtrl = TextEditingController(text: '165');
  final _ptCtrl = TextEditingController(text: '5');
  final _prCtrl = TextEditingController(text: '5');
  final _pbCtrl = TextEditingController(text: '5');
  final _plCtrl = TextEditingController(text: '5');
  final _searchCtrl = TextEditingController();

  String _type = 'School';
  int? _roleId;
  int? _editingId;
  String? _backgroundName;
  PickedAttachment? _backgroundAttachment;
  String? _backgroundError;
  String? _existingBackgroundUrl;

  Future<void> _pickBackground() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    setState(() {
      if (file.size > 2 * 1024 * 1024) {
        _backgroundError = 'Background image must be 2MB or smaller.';
        _backgroundName = null;
        _backgroundAttachment = null;
      } else {
        _backgroundError = null;
        _backgroundName = file.name;
        _backgroundAttachment = PickedAttachment(name: file.name, bytes: file.bytes!, size: file.size);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _heightCtrl.dispose();
    _widthCtrl.dispose();
    _ptCtrl.dispose();
    _prCtrl.dispose();
    _pbCtrl.dispose();
    _plCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _bodyCtrl.clear();
    _heightCtrl.text = '144';
    _widthCtrl.text = '165';
    _ptCtrl.text = '5';
    _prCtrl.text = '5';
    _pbCtrl.text = '5';
    _plCtrl.text = '5';
    setState(() {
      _type = 'School';
      _roleId = null;
      _editingId = null;
      _backgroundName = null;
      _backgroundAttachment = null;
      _backgroundError = null;
      _existingBackgroundUrl = null;
    });
  }

  void _loadForEdit(CertificateTemplateEntity e) {
    setState(() {
      _editingId = e.id;
      _type = e.type;
      _roleId = e.applicableRoleId;
      _titleCtrl.text = e.title;
      _bodyCtrl.text = e.body;
      _heightCtrl.text = '${e.backgroundHeight}';
      _widthCtrl.text = '${e.backgroundWidth}';
      _ptCtrl.text = '${e.paddingTop}';
      _prCtrl.text = '${e.paddingRight}';
      _pbCtrl.text = '${e.paddingBottom}';
      _plCtrl.text = '${e.paddingLeft}';
      _backgroundName = null;
      _backgroundAttachment = null;
      _backgroundError = null;
      _existingBackgroundUrl = e.backgroundUrl;
    });
  }

  String? _numberValidator(String? v, int min, int max) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'This field is required.';
    final n = int.tryParse(value);
    if (n == null) return 'Only digits are allowed.';
    if (n < min || n > max) return 'Value must be between $min and $max.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_backgroundError != null) return;

    final entry = CertificateTemplateEntity(
      type: _type,
      title: _titleCtrl.text.trim(),
      applicableRoleId: _roleId,
      body: _bodyCtrl.text.trim(),
      backgroundHeight: int.tryParse(_heightCtrl.text.trim()) ?? 144,
      backgroundWidth: int.tryParse(_widthCtrl.text.trim()) ?? 165,
      paddingTop: int.tryParse(_ptCtrl.text.trim()) ?? 5,
      paddingRight: int.tryParse(_prCtrl.text.trim()) ?? 5,
      paddingBottom: int.tryParse(_pbCtrl.text.trim()) ?? 5,
      paddingLeft: int.tryParse(_plCtrl.text.trim()) ?? 5,
      backgroundAttachment: _backgroundAttachment,
    );

    final notifier = ref.read(certificateTemplateListProvider.notifier);
    final ok = _editingId == null ? await notifier.add(entry) : await notifier.edit(_editingId!, entry);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Record created successfully.' : 'Record updated successfully.')),
      );
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(certificateTemplateListProvider);
    final rolesAsync = ref.watch(certificateRolesProvider);
    final roles = rolesAsync.maybeWhen(data: (r) => r, orElse: () => const <RoleEntity>[]);
    final isSaving = state.savingId != null;

    final previewBody = _bodyCtrl.text
        .replaceAll('[student_name]', 'John Doe')
        .replaceAll('[class]', 'Grade 10')
        .replaceAll('[date]', DateTime.now().toIso8601String().substring(0, 10));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Certificate'),
          AdminSectionCard(
            title: '📜 Create Certificate',
            borderRadius: 12,
            padding: const EdgeInsets.all(14),
            boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 16, offset: Offset(0, 6))],
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rolesAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AdminMessageBanner(error: 'Unable to load roles: ${rolesAsync.error}'),
                    ),
                  AdminDropdownField<String>(
                    label: 'Certificate Type',
                    required: true,
                    value: _type,
                    hint: 'Select type',
                    helper: 'Select where this certificate will be used.',
                    items: const [
                      DropdownMenuItem(value: 'School', child: Text('School')),
                      DropdownMenuItem(value: 'Lms', child: Text('LMS')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'School'),
                  ),
                  AdminDropdownField<int?>(
                    label: 'Applicable Role',
                    required: true,
                    value: _roleId,
                    hint: 'All roles',
                    helper: 'Choose which role can receive this certificate.',
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All roles')),
                      ...roles.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.name))),
                    ],
                    onChanged: (v) => setState(() => _roleId = v),
                  ),
                  AdminTextField(
                    label: 'Certificate Title',
                    required: true,
                    controller: _titleCtrl,
                    hint: 'e.g. Academic Excellence Award',
                    maxLength: 150,
                    helper: 'Enter a meaningful title (3–150 characters).',
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Certificate title is required.';
                      if (value.length < 3) return 'Title must be at least 3 characters.';
                      return null;
                    },
                  ),
                  AdminTextField(
                    label: 'Certificate Body',
                    required: true,
                    controller: _bodyCtrl,
                    hint: 'e.g. This is to certify that [student_name] of class [class] has been awarded...',
                    maxLines: 3,
                    helper: 'Write the certificate text. Use placeholders like [student_name], [class], [date] for dynamic content (min 10 chars).',
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Certificate body is required.';
                      if (value.length < 10) return 'Body must be at least 10 characters.';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('📐 Page Dimensions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AdminTextField(
                          label: 'Height (mm)',
                          required: true,
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          helper: 'Page height in millimeters (50-500).',
                          validator: (v) => _numberValidator(v, 50, 500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdminTextField(
                          label: 'Width (mm)',
                          required: true,
                          controller: _widthCtrl,
                          keyboardType: TextInputType.number,
                          helper: 'Page width in millimeters (50-500).',
                          validator: (v) => _numberValidator(v, 50, 500),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('📏 Padding (mm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  Row(
                    children: [
                      Expanded(child: AdminTextField(label: 'Top', required: true, controller: _ptCtrl, keyboardType: TextInputType.number, validator: (v) => _numberValidator(v, 0, 100))),
                      const SizedBox(width: 8),
                      Expanded(child: AdminTextField(label: 'Right', required: true, controller: _prCtrl, keyboardType: TextInputType.number, validator: (v) => _numberValidator(v, 0, 100))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: AdminTextField(label: 'Bottom', required: true, controller: _pbCtrl, keyboardType: TextInputType.number, validator: (v) => _numberValidator(v, 0, 100))),
                      const SizedBox(width: 8),
                      Expanded(child: AdminTextField(label: 'Left', required: true, controller: _plCtrl, keyboardType: TextInputType.number, validator: (v) => _numberValidator(v, 0, 100))),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('🖼️ Background Image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  AdminFileField(
                    fileName: _backgroundName,
                    errorText: _backgroundError,
                    placeholder: 'Click to upload or drag and drop — PNG, JPG (max 2MB)',
                    onTap: _pickBackground,
                    existingFileUrl: _editingId != null ? _existingBackgroundUrl : null,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: WebButton(
                      label: isSaving ? 'Saving...' : '💾 Save Certificate',
                      onPressed: isSaving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AdminSectionCard(
            title: '🧾 Quick Preview',
            borderRadius: 12,
            padding: const EdgeInsets.all(14),
            boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 16, offset: Offset(0, 6))],
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 150),
              decoration: BoxDecoration(border: Border.all(color: AppColors.borderPrimary, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titleCtrl.text.isEmpty ? 'Certificate Title' : _titleCtrl.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(previewBody.isEmpty ? 'This is to certify that [student_name]...' : previewBody, style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
          ),
          AdminSectionCard(
            title: '📋 Certificate List',
            borderRadius: 12,
            padding: const EdgeInsets.all(14),
            boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 16, offset: Offset(0, 6))],
            trailing: SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Search certificates...', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => ref.read(certificateTemplateListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              children: [
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No certificates found.',
                  columns: const [
                    AdminColumn('Title', width: 140),
                    AdminColumn('Type', width: 80),
                    AdminColumn('Role', width: 110),
                    AdminColumn('Actions', width: 90),
                  ],
                  rows: _buildRows(state, roles),
                ),
                AdminPaginationBar(
                  page: state.page,
                  pageSize: state.pageSize,
                  totalCount: state.totalCount,
                  onPageChange: (p) => ref.read(certificateTemplateListProvider.notifier).setPage(p),
                  onPageSizeChange: (s) => ref.read(certificateTemplateListProvider.notifier).setPageSize(s),
                  pageSizeOptions: const [5, 10, 25, 50],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<List<Widget>> _buildRows(dynamic state, List<RoleEntity> roles) {
    final notifier = ref.read(certificateTemplateListProvider.notifier);
    final visible = notifier.filtered((e, q) => e.title.toLowerCase().contains(q) || e.type.toLowerCase().contains(q));

    return List.generate(visible.length, (index) {
      final e = visible[index];
      final roleName = e.applicableRoleId == null
          ? 'All roles'
          : roles.firstWhere((r) => r.id == e.applicableRoleId, orElse: () => RoleEntity(id: e.applicableRoleId!, name: 'Role ${e.applicableRoleId}')).name;
      return [
        Text(e.title, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
        _badge(e.type, const Color(0xFFDCFCE7), const Color(0xFF166534)),
        _badge(roleName, const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
        AdminIconActionButtons(
          onEdit: () => _loadForEdit(e),
          isDeleting: state.deletingId == e.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
              context,
              message: 'Are you sure to delete this certificate template?',
            );
            if (confirmed && e.id != null) {
              await ref.read(certificateTemplateListProvider.notifier).remove(e.id!);
            }
          },
        ),
      ];
    });
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
