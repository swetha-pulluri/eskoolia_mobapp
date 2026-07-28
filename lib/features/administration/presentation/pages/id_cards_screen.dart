import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/picked_attachment.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_breadcrumb_header.dart';
import '../widgets/web_button.dart';

/// ID Cards — Design Template — converted from web `IdCardPanel.tsx`.
/// Sub-tab of Documents Studio ("ID Cards" main tab / "Design Template" sub-tab).
class IdCardsScreen extends ConsumerStatefulWidget {
  const IdCardsScreen({super.key});

  @override
  ConsumerState<IdCardsScreen> createState() => _IdCardsScreenState();
}

class _IdCardsScreenState extends ConsumerState<IdCardsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formSectionKey = GlobalKey();
  final _titleCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _layout = 'horizontal';
  List<int> _selectedRoleIds = [];
  bool _applyToAllRoles = false;
  int? _editingId;
  String? _bgFrontName;
  String? _bgBackName;
  String? _logoName;
  String? _signatureName;
  PickedAttachment? _bgFrontAttachment;
  PickedAttachment? _bgBackAttachment;
  PickedAttachment? _logoAttachment;
  PickedAttachment? _signatureAttachment;
  String? _existingBgFrontUrl;
  String? _existingBgBackUrl;
  String? _existingLogoUrl;
  String? _existingSignatureUrl;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<PickedAttachment?> _pickImage({
    int maxBytes = 2 * 1024 * 1024,
    List<String> extensions = const ['png', 'jpg', 'jpeg'],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return null;
    if (file.size > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File must be ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)}MB or smaller.',
            ),
          ),
        );
      }
      return null;
    }
    return PickedAttachment(
      name: file.name,
      bytes: file.bytes!,
      size: file.size,
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    setState(() {
      _layout = 'horizontal';
      _selectedRoleIds = [];
      _applyToAllRoles = false;
      _editingId = null;
      _bgFrontName = null;
      _bgBackName = null;
      _logoName = null;
      _signatureName = null;
      _bgFrontAttachment = null;
      _bgBackAttachment = null;
      _logoAttachment = null;
      _signatureAttachment = null;
      _existingBgFrontUrl = null;
      _existingBgBackUrl = null;
      _existingLogoUrl = null;
      _existingSignatureUrl = null;
    });
  }

  void _loadForEdit(IdCardTemplateEntity e) {
    setState(() {
      _editingId = e.id;
      _titleCtrl.text = e.title;
      _layout = e.pageLayoutStyle;
      _selectedRoleIds = List.of(e.applicableRoleIds);
      _applyToAllRoles = e.applicableRoleIds.isEmpty;
      _bgFrontName = null;
      _bgBackName = null;
      _logoName = null;
      _signatureName = null;
      _bgFrontAttachment = null;
      _bgBackAttachment = null;
      _logoAttachment = null;
      _signatureAttachment = null;
      _existingBgFrontUrl = e.backgroundUrl;
      _existingBgBackUrl = e.profileUrl;
      _existingLogoUrl = e.logoUrl;
      _existingSignatureUrl = e.signatureUrl;
    });
    // The form card sits above the list in this screen's single scrolling
    // column, so without this the state updates invisibly off-screen while
    // editing from a row further down the list — looking like "Edit does
    // nothing".
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      final ctx = _formSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _openRolesPicker(List<RoleEntity> roles) async {
    var applyAll = _applyToAllRoles;
    var selected = List.of(_selectedRoleIds);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Applicable Roles',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'All roles',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Use this template for every role in the school',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          value: applyAll,
                          onChanged: (v) => setSheetState(() {
                            applyAll = v ?? false;
                            if (applyAll) selected = [];
                          }),
                        ),
                        const Divider(height: 1),
                        ...roles.map(
                          (role) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              role.name,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            value: selected.contains(role.id),
                            onChanged: (v) => setSheetState(() {
                              applyAll = false;
                              if (v == true) {
                                if (!selected.contains(role.id)) {
                                  selected.add(role.id);
                                }
                              } else {
                                selected.remove(role.id);
                              }
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        WebButton(
                          label: 'Done',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    setState(() {
      _applyToAllRoles = applyAll;
      _selectedRoleIds = selected;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = IdCardTemplateEntity(
      title: _titleCtrl.text.trim(),
      pageLayoutStyle: _layout,
      applicableRoleIds: _applyToAllRoles ? [] : _selectedRoleIds,
      backgroundAttachment: _bgFrontAttachment,
      profileAttachment: _bgBackAttachment,
      logoAttachment: _logoAttachment,
      signatureAttachment: _signatureAttachment,
    );

    final notifier = ref.read(idCardTemplateListProvider.notifier);
    final ok = _editingId == null
        ? await notifier.add(entry)
        : await notifier.edit(_editingId!, entry);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingId == null
                ? 'ID card saved successfully.'
                : 'ID card updated successfully.',
          ),
        ),
      );
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(idCardTemplateListProvider);
    final rolesAsync = ref.watch(idCardDesignRolesProvider);
    final roles = rolesAsync.maybeWhen(
      data: (r) => r,
      orElse: () => const <RoleEntity>[],
    );
    final isSaving = state.savingId != null;

    final selectedNames = _applyToAllRoles
        ? const <String>[]
        : _selectedRoleIds
              .map(
                (id) => roles
                    .firstWhere(
                      (r) => r.id == id,
                      orElse: () => const RoleEntity(id: 0, name: ''),
                    )
                    .name,
              )
              .where((n) => n.isNotEmpty)
              .toList();
    final rolesDisplayText = _applyToAllRoles
        ? 'All roles'
        : selectedNames.isEmpty
        ? 'Select applicable roles'
        : selectedNames.length == 1
        ? selectedNames.first
        : '${selectedNames.first} + ${selectedNames.length - 1} more';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'ID Card'),
          KeyedSubtree(
            key: _formSectionKey,
            child: AdminSectionCard(
              title: _editingId == null ? 'Create ID Card' : 'Edit ID Card',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminTextField(
                      label: 'ID Card Title',
                      required: true,
                      controller: _titleCtrl,
                      hint: 'e.g. Student ID Card 2025',
                      maxLength: 100,
                      helper:
                          'Enter a meaningful title (3-100 characters, letters, numbers and spaces).\nExample: Teacher ID Card, Student ID Card, etc.',
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'ID Card title is required.';
                        if (value.length < 3) {
                          return 'Title must be at least 3 characters.';
                        }
                        return null;
                      },
                    ),
                    AdminDropdownField<String>(
                      label: 'Layout',
                      required: true,
                      value: _layout,
                      hint: 'Select layout',
                      helper:
                          'Choose the card orientation: Horizontal (landscape) or Vertical (portrait).',
                      items: const [
                        DropdownMenuItem(
                          value: 'horizontal',
                          child: Text('Horizontal'),
                        ),
                        DropdownMenuItem(
                          value: 'vertical',
                          child: Text('Vertical'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _layout = v ?? 'horizontal'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Applicable Roles',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          rolesAsync.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: LinearProgressIndicator(),
                                )
                              : rolesAsync.hasError
                              ? Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.redSoft,
                                    border: Border.all(
                                      color: AppColors.dangerRed,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Unable to load roles: ${rolesAsync.error}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.dangerRed,
                                    ),
                                  ),
                                )
                              : roles.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    border: Border.all(
                                      color: const Color(0xFFFBBF24),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Warning: No roles available. Please configure roles in the system settings first.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: () => _openRolesPicker(roles),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      suffixIcon: const Icon(
                                        Icons.expand_more,
                                        size: 18,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.borderPrimary,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.borderPrimary,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      rolesDisplayText,
                                      style: const TextStyle(fontSize: 13.5),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pick specific roles or choose All roles to apply this ID card to everyone.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdminFileField(
                      fileName: _bgFrontName,
                      placeholder:
                          'Background Image (Front) — PNG, JPG (max 2MB)',
                      existingFileUrl: _editingId != null
                          ? _existingBgFrontUrl
                          : null,
                      previewExistingAsImage: true,
                      previewBytes: _bgFrontAttachment == null
                          ? null
                          : Uint8List.fromList(_bgFrontAttachment!.bytes),
                      onTap: () async {
                        final picked = await _pickImage();
                        if (picked != null) {
                          setState(() {
                            _bgFrontName = picked.name;
                            _bgFrontAttachment = picked;
                          });
                        }
                      },
                    ),
                    AdminFileField(
                      fileName: _bgBackName,
                      placeholder:
                          'Background Image (Back) — PNG, JPG (max 2MB)',
                      existingFileUrl: _editingId != null
                          ? _existingBgBackUrl
                          : null,
                      previewExistingAsImage: true,
                      previewBytes: _bgBackAttachment == null
                          ? null
                          : Uint8List.fromList(_bgBackAttachment!.bytes),
                      onTap: () async {
                        final picked = await _pickImage();
                        if (picked != null) {
                          setState(() {
                            _bgBackName = picked.name;
                            _bgBackAttachment = picked;
                          });
                        }
                      },
                    ),
                    AdminFileField(
                      fileName: _logoName,
                      placeholder: 'School Logo — PNG, JPG, SVG (max 1MB)',
                      existingFileUrl: _editingId != null
                          ? _existingLogoUrl
                          : null,
                      previewExistingAsImage: true,
                      previewBytes: _logoAttachment == null
                          ? null
                          : Uint8List.fromList(_logoAttachment!.bytes),
                      onTap: () async {
                        final picked = await _pickImage(
                          maxBytes: 1024 * 1024,
                          extensions: const ['png', 'jpg', 'jpeg', 'svg'],
                        );
                        if (picked != null) {
                          setState(() {
                            _logoName = picked.name;
                            _logoAttachment = picked;
                          });
                        }
                      },
                    ),
                    AdminFileField(
                      fileName: _signatureName,
                      placeholder: 'Signature Image — PNG, JPG (max 1MB)',
                      existingFileUrl: _editingId != null
                          ? _existingSignatureUrl
                          : null,
                      previewExistingAsImage: true,
                      previewBytes: _signatureAttachment == null
                          ? null
                          : Uint8List.fromList(_signatureAttachment!.bytes),
                      onTap: () async {
                        final picked = await _pickImage(maxBytes: 1024 * 1024);
                        if (picked != null) {
                          setState(() {
                            _signatureName = picked.name;
                            _signatureAttachment = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        WebButton(
                          label: isSaving
                              ? 'Saving...'
                              : (_editingId == null ? 'Save' : 'Update'),
                          onPressed: isSaving ? null : _submit,
                        ),
                        if (_editingId != null) ...[
                          const SizedBox(width: 8),
                          WebButton(
                            label: 'Cancel',
                            color: const Color(0xFF6B7280),
                            onPressed: _resetForm,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AdminSectionCard(
            title: 'ID Card List',
            trailing: SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Quick search',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
                onChanged: (v) =>
                    ref.read(idCardTemplateListProvider.notifier).setSearch(v),
              ),
            ),
            child: Column(
              children: [
                AdminDataTable(
                  isLoading: state.isLoading,
                  emptyText: 'No ID cards found.',
                  columns: const [
                    AdminColumn('Title', width: 140),
                    AdminColumn('Layout', width: 90),
                    AdminColumn('Roles', width: 160),
                    AdminColumn('Actions', width: 90),
                  ],
                  rows: _buildRows(state, roles),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<List<Widget>> _buildRows(dynamic state, List<RoleEntity> roles) {
    final notifier = ref.read(idCardTemplateListProvider.notifier);
    final visible = notifier.filtered(
      (e, q) =>
          e.title.toLowerCase().contains(q) || e.pageLayoutStyle.contains(q),
    );

    return List.generate(visible.length, (index) {
      final e = visible[index];
      final roleBadges = e.applicableRoleIds.isEmpty
          ? [_roleBadge('All Roles', muted: true)]
          : e.applicableRoleIds
                .map(
                  (id) => _roleBadge(
                    roles
                        .firstWhere(
                          (r) => r.id == id,
                          orElse: () => RoleEntity(id: id, name: 'Role $id'),
                        )
                        .name,
                  ),
                )
                .toList();
      return [
        Text(
          e.title,
          style: const TextStyle(fontSize: 12.5),
          overflow: TextOverflow.ellipsis,
        ),
        Text(e.pageLayoutStyle, style: const TextStyle(fontSize: 12.5)),
        Wrap(spacing: 4, runSpacing: 4, children: roleBadges),
        AdminRowActions(
          onEdit: () => _loadForEdit(e),
          isDeleting: state.deletingId == e.id,
          onDelete: () async {
            final confirmed = await showAdminConfirmDialog(
              context,
              message: 'Are you sure to delete this ID card template?',
            );
            if (confirmed && e.id != null) {
              await ref.read(idCardTemplateListProvider.notifier).remove(e.id!);
            }
          },
        ),
      ];
    });
  }

  Widget _roleBadge(String label, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF3F4F6) : const Color(0xFFEDF2FF),
        border: Border.all(
          color: muted ? const Color(0xFFE5E7EB) : const Color(0xFFC7D2FE),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: muted ? const Color(0xFF6B7280) : const Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}
