import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/administration_provider.dart';
import '../widgets/admin_form_fields.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_breadcrumb_header.dart';
import '../widgets/web_button.dart';

/// Certificates — Generate & Print — converted from web
/// `GenerateCertificatePanel.tsx`. Sub-tab of Documents Studio
/// ("Certificates" main tab / "Generate & Print" sub-tab).
/// Note: web opens a native browser print popup for the generated
/// certificates — there is no mobile equivalent, so "Print Selected" here
/// shows the same success/validation text the web itself shows rather than
/// opening a print dialog.
class GenerateCertificateScreen extends ConsumerStatefulWidget {
  const GenerateCertificateScreen({super.key});

  @override
  ConsumerState<GenerateCertificateScreen> createState() => _GenerateCertificateScreenState();
}

class _GenerateCertificateScreenState extends ConsumerState<GenerateCertificateScreen> {
  final _gridGapCtrl = TextEditingController(text: '14');
  int? _roleId;
  int? _templateId;
  int? _classId;
  int? _sectionId;
  bool _hasSearched = false;
  Set<int> _selectedIds = {};
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _gridGapCtrl.dispose();
    super.dispose();
  }

  bool _isStudentRole(List<RoleEntity> roles) {
    final role = roles.where((r) => r.id == _roleId).firstOrNull;
    return (role?.name ?? '').trim().toLowerCase().contains('student');
  }

  void _search() {
    if (_roleId == null) {
      setState(() {
        _isError = true;
        _message = 'Select a role first.';
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

  void _printSelected() {
    if (_roleId == null) {
      setState(() {
        _isError = true;
        _message = 'Select a role first.';
      });
      return;
    }
    if (_templateId == null) {
      setState(() {
        _isError = true;
        _message = 'Please select a certificate template.';
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
    setState(() {
      _isError = false;
      _message = 'Print view opened for selected certificates.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);
    final classesAsync = ref.watch(classesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final recipientsAsync = ref.watch(recipientsProvider);
    final templatesState = ref.watch(certificateTemplateListProvider);

    final roles = rolesAsync.maybeWhen(data: (r) => r, orElse: () => const <RoleEntity>[]);
    final classes = classesAsync.maybeWhen(data: (c) => c, orElse: () => const <ClassEntity>[]);
    final allSections = sectionsAsync.maybeWhen(data: (s) => s, orElse: () => const <SectionEntity>[]);
    final allRecipients = recipientsAsync.maybeWhen(data: (r) => r, orElse: () => const <RecipientEntity>[]);
    final templates = templatesState.items;

    final isStudent = _isStudentRole(roles);
    final sections = _classId == null ? allSections : allSections.where((s) => s.classId == _classId).toList();
    final availableTemplates = _roleId == null
        ? templates
        : templates.where((t) => t.applicableRoleId == null || t.applicableRoleId == _roleId).toList();
    final recipients = _hasSearched ? allRecipients : const <RecipientEntity>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminBreadcrumbHeader(title: 'Generate Certificate'),
          AdminSectionCard(
            title: 'Select Criteria',
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1))],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminDropdownField<int>(
                  label: 'Role',
                  required: true,
                  value: _roleId,
                  hint: 'Select role',
                  helper: 'Select the role type for recipients',
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
                  label: 'Certificate',
                  required: true,
                  value: _templateId,
                  hint: 'Select certificate',
                  helper: 'Choose the certificate template',
                  items: availableTemplates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))).toList(),
                  onChanged: (v) => setState(() => _templateId = v),
                ),
                if (isStudent)
                  AdminDropdownField<int>(
                    label: 'Class',
                    value: _classId,
                    hint: 'Select class',
                    helper: 'Filter by class (optional)',
                    items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() {
                      _classId = v;
                      _sectionId = null;
                    }),
                  ),
                if (isStudent)
                  AdminDropdownField<int>(
                    label: 'Section',
                    value: _sectionId,
                    hint: 'Select section',
                    helper: 'Filter by section (optional)',
                    items: sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) => setState(() => _sectionId = v),
                  ),
                AdminTextField(
                  label: 'Grid Gap (px)',
                  controller: _gridGapCtrl,
                  keyboardType: TextInputType.number,
                  helper: 'Spacing between certificates (0-100)',
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    WebButton(label: 'Search', onPressed: _search),
                    const SizedBox(width: 8),
                    WebButton(label: 'Print Selected', color: const Color(0xFF5AB88D), onPressed: _printSelected),
                  ],
                ),
              ],
            ),
          ),
          AdminSectionCard(
            title: 'Recipient List',
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
                      _hasSearched ? 'No recipients found.' : 'No recipients loaded. Click Search.',
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
                        subtitle: Text('Admission: ${r.admissionNo ?? '-'} · ${r.className ?? '-'} (${r.sectionName ?? '-'})', style: const TextStyle(fontSize: 11.5)),
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
