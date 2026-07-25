import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/administration_provider.dart';
import '../utils/document_print_helper.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_breadcrumb_header.dart';
import '../widgets/web_button.dart';

/// ID Cards — Generate & Print — converted from web `GenerateIdCardPanel.tsx`.
/// Sub-tab of Documents Studio ("ID Cards" main tab / "Generate & Print" sub-tab).
/// Note: web opens a native browser print popup (`window.open()` +
/// `popup.print()`) built from the same template + recipient data; mobile
/// has no browser popup, so "Print Selected" builds a real PDF from that
/// same data instead and hands it to the native print/share sheet
/// (`document_print_helper.dart`).
class GenerateIdCardScreen extends ConsumerStatefulWidget {
  const GenerateIdCardScreen({super.key});

  @override
  ConsumerState<GenerateIdCardScreen> createState() => _GenerateIdCardScreenState();
}

class _GenerateIdCardScreenState extends ConsumerState<GenerateIdCardScreen> {
  final _gridGapCtrl = TextEditingController(text: '12');
  int? _roleId;
  int? _templateId;
  int? _classId;
  int? _sectionId;
  bool _hasSearched = false;
  Set<int> _selectedIds = {};
  String? _message;
  bool _isError = false;
  bool _printing = false;

  @override
  void dispose() {
    _gridGapCtrl.dispose();
    super.dispose();
  }

  bool _isStudentRole(List<RoleEntity> roles) {
    final role = roles.where((r) => r.id == _roleId).firstOrNull;
    return (role?.name ?? '').trim().toLowerCase() == 'student';
  }

  void _search(List<RoleEntity> roles) {
    if (_roleId == null) {
      setState(() {
        _isError = true;
        _message = 'Please select Role.';
      });
      return;
    }
    if (_templateId == null) {
      setState(() {
        _isError = true;
        _message = 'Please select ID Card Template.';
      });
      return;
    }
    final isStudent = _isStudentRole(roles);
    if (isStudent && _classId == null) {
      setState(() {
        _isError = true;
        _message = 'Please select Class for Student role.';
      });
      return;
    }
    if (isStudent && _sectionId == null) {
      setState(() {
        _isError = true;
        _message = 'Please select Section for Student role.';
      });
      return;
    }
    setState(() {
      _hasSearched = true;
      _selectedIds = {};
      _isError = false;
      _message = null;
    });
  }

  Future<void> _printSelected(List<IdCardTemplateEntity> templates, List<RecipientEntity> recipients, bool isStudent) async {
    if (_templateId == null) {
      setState(() {
        _isError = true;
        _message = 'Please select an ID card template.';
      });
      return;
    }
    if (_selectedIds.isEmpty) {
      setState(() {
        _isError = true;
        _message = 'Please select at least one recipient.';
      });
      return;
    }
    final template = templates.where((t) => t.id == _templateId).firstOrNull;
    if (template == null) {
      setState(() {
        _isError = true;
        _message = 'Please select an ID card template.';
      });
      return;
    }
    final selected = recipients.where((r) => _selectedIds.contains(r.id)).toList();
    setState(() {
      _printing = true;
      _isError = false;
      _message = null;
    });
    try {
      await printIdCards(
        recipients: selected,
        template: template,
        isStudentRole: isStudent,
        gridGapPx: double.tryParse(_gridGapCtrl.text.trim()) ?? 12,
      );
      if (!mounted) return;
      setState(() {
        _isError = false;
        _message = 'Print view opened for selected ID cards.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = 'Unable to generate ID cards: $e';
      });
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final classesAsync = ref.watch(classesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final recipientsAsync = ref.watch(recipientsProvider((roleId: _roleId, classId: _classId, sectionId: _sectionId)));
    final templatesAsync = ref.watch(idCardGenerateTemplatesProvider);

    final roles = rolesAsync.maybeWhen(data: (r) => r, orElse: () => const <RoleEntity>[]);
    final classes = classesAsync.maybeWhen(data: (c) => c, orElse: () => const <ClassEntity>[]);
    final allSections = sectionsAsync.maybeWhen(data: (s) => s, orElse: () => const <SectionEntity>[]);
    final allRecipients = recipientsAsync.maybeWhen(data: (r) => r, orElse: () => const <RecipientEntity>[]);
    final templates = templatesAsync.maybeWhen(data: (t) => t, orElse: () => const <IdCardTemplateEntity>[]);

    final isStudent = _isStudentRole(roles);
    final sections = _classId == null ? allSections : allSections.where((s) => s.classId == _classId).toList();
    final availableTemplates = _roleId == null
        ? templates
        : templates.where((t) => t.applicableRoleIds.isEmpty || t.applicableRoleIds.contains(_roleId)).toList();
    final recipients = _hasSearched ? allRecipients : const <RecipientEntity>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Generate ID Card'),
          AdminSectionCard(
            title: 'Select Criteria',
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1))],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rolesAsync.hasError || classesAsync.hasError || sectionsAsync.hasError || templatesAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdminMessageBanner(
                      error: 'Unable to load setup data: '
                          '${rolesAsync.error ?? classesAsync.error ?? sectionsAsync.error ?? templatesAsync.error}',
                    ),
                  ),
                if (recipientsAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdminMessageBanner(error: 'Unable to load recipients: ${recipientsAsync.error}'),
                  ),
                AdminDropdownField<int>(
                  label: 'Role',
                  value: _roleId,
                  hint: 'Select role *',
                  items: roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                  onChanged: (v) => setState(() {
                    _roleId = v;
                    _templateId = null;
                    if (!isStudent) {
                      _classId = null;
                      _sectionId = null;
                    }
                  }),
                ),
                AdminDropdownField<int>(
                  label: 'ID Card Template',
                  value: _templateId,
                  hint: 'Select ID card *',
                  items: availableTemplates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))).toList(),
                  onChanged: (v) => setState(() => _templateId = v),
                ),
                isStudent
                    ? AdminDropdownField<int>(
                        label: 'Class',
                        value: _classId,
                        hint: 'Select class *',
                        items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() {
                          _classId = v;
                          _sectionId = null;
                        }),
                      )
                    : AdminTextField(label: 'Class', controller: TextEditingController(text: 'All classes'), enabled: false, helper: null),
                isStudent
                    ? AdminDropdownField<int>(
                        label: 'Section',
                        value: _sectionId,
                        hint: 'Select section *',
                        items: sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (v) => setState(() => _sectionId = v),
                      )
                    : AdminTextField(label: 'Section', controller: TextEditingController(text: 'All sections'), enabled: false, helper: null),
                AdminTextField(
                  label: 'Grid Gap (px)',
                  controller: _gridGapCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    WebButton(label: 'Search', onPressed: () => _search(roles)),
                    const SizedBox(width: 8),
                    WebButton(
                      label: _printing ? 'Generating...' : 'Print Selected',
                      color: const Color(0xFF0F766E),
                      disabled: _printing,
                      onPressed: () => _printSelected(availableTemplates, recipients, isStudent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AdminSectionCard(
            title: isStudent ? 'Student List' : 'Recipient List',
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1))],
            trailing: recipients.isEmpty
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: recipients.isNotEmpty && _selectedIds.length == recipients.length,
                        onChanged: (v) => setState(() {
                          _selectedIds = v == true ? recipients.map((r) => r.id).toSet() : {};
                        }),
                      ),
                      const Text('Select all', style: TextStyle(fontSize: 12.5)),
                    ],
                  ),
            child: recipients.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      _hasSearched ? 'No users found.' : 'No recipients loaded. Click Search.',
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  )
                : Column(
                    children: recipients.map((r) {
                      final checked = _selectedIds.contains(r.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: checked,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedIds.add(r.id);
                          } else {
                            _selectedIds.remove(r.id);
                          }
                        }),
                        title: Text(r.label, style: const TextStyle(fontSize: 13)),
                        subtitle: isStudent
                            ? Text(
                                'Admission: ${r.admissionNo ?? '-'} · ${r.className ?? '-'} (${r.sectionName ?? '-'}) · ${r.gender ?? '-'} · DOB ${r.dateOfBirth ?? '-'}',
                                style: const TextStyle(fontSize: 11.5),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!, style: TextStyle(fontSize: 12.5, color: _isError ? const Color(0xFFB45309) : const Color(0xFF0F766E))),
            ),
        ],
      ),
    );
  }
}
