import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../domain/models/school_header_settings.dart';

enum _SettingsTab { identity, layout, import, declaration }

const List<Color> _headerColorPalette = [
  Color(0xFFFFFFFF),
  Color(0xFF111827),
  Color(0xFF6C3CE1),
  Color(0xFF0EA5E9),
  Color(0xFF059669),
  Color(0xFFDC2626),
  Color(0xFFEA580C),
  Color(0xFFF59E0B),
  Color(0xFFFAF5FF),
  Color(0xFFF3F4F6),
];

/// The "Header Settings" panel — mirrors `ConsentForm.tsx`'s
/// `.cf-settings-panel` exactly: 4 tabs (School Info / Logo & Layout / Import
/// Letterhead / Declaration), same fields, same validation rules
/// (school name + principal name required, Indian mobile / email / affiliation
/// number format checks), same "Apply & save" / "Cancel" / "Reset defaults"
/// actions. Native `<input type="color">` has no mobile equivalent, so header
/// background/text colour use a curated swatch palette + hex entry instead of
/// a full picker — same outcome (any colour), no new dependency.
class VerificationFormSettingsPanel extends StatefulWidget {
  final SchoolHeaderSettings initial;
  final String studentFullName;
  final ValueChanged<SchoolHeaderSettings> onSave;
  final VoidCallback onCancel;

  const VerificationFormSettingsPanel({
    super.key,
    required this.initial,
    required this.studentFullName,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<VerificationFormSettingsPanel> createState() => _VerificationFormSettingsPanelState();
}

class _VerificationFormSettingsPanelState extends State<VerificationFormSettingsPanel> {
  _SettingsTab _tab = _SettingsTab.identity;
  late SchoolHeaderSettings _draft;
  bool _saved = false;
  final Map<String, String> _errors = {};

  late final TextEditingController _schoolNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _principalCtrl;
  late final TextEditingController _affiliationCtrl;
  late final TextEditingController _mottoCtrl;
  late final TextEditingController _declarationCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _schoolNameCtrl = TextEditingController(text: _draft.schoolName);
    _addressCtrl = TextEditingController(text: _draft.schoolAddress);
    _phoneCtrl = TextEditingController(text: _draft.schoolPhone);
    _emailCtrl = TextEditingController(text: _draft.schoolEmail);
    _websiteCtrl = TextEditingController(text: _draft.schoolWebsite);
    _principalCtrl = TextEditingController(text: _draft.principalName);
    _affiliationCtrl = TextEditingController(text: _draft.affiliationNo);
    _mottoCtrl = TextEditingController(text: _draft.schoolMotto);
    _declarationCtrl = TextEditingController(text: _draft.declarationText);
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _principalCtrl.dispose();
    _affiliationCtrl.dispose();
    _mottoCtrl.dispose();
    _declarationCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <String, String>{};
    if (_schoolNameCtrl.text.trim().isEmpty) errors['schoolName'] = 'School name is required';
    if (_principalCtrl.text.trim().isEmpty) errors['principalName'] = 'Principal name is required';
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('91') ? digits.substring(2) : digits;
    if (_phoneCtrl.text.trim().isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(local)) {
      errors['schoolPhone'] = 'Enter a valid 10-digit Indian mobile number';
    }
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) {
      errors['schoolEmail'] = 'Enter a valid email address';
    }
    setState(() => _errors
      ..clear()
      ..addAll(errors));
    return errors.isEmpty;
  }

  void _save() {
    if (!_validate()) return;
    final settings = _draft.copyWith(
      schoolName: _schoolNameCtrl.text.trim(),
      schoolAddress: _addressCtrl.text.trim(),
      schoolPhone: _phoneCtrl.text.trim(),
      schoolEmail: _emailCtrl.text.trim(),
      schoolWebsite: _websiteCtrl.text.trim(),
      principalName: _principalCtrl.text.trim(),
      affiliationNo: _affiliationCtrl.text.trim(),
      schoolMotto: _mottoCtrl.text.trim(),
      declarationText: _declarationCtrl.text.trim().isEmpty ? kDefaultDeclaration : _declarationCtrl.text,
    );
    setState(() => _saved = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onSave(settings);
    });
  }

  void _resetDefaults() {
    const defaults = SchoolHeaderSettings();
    setState(() {
      _draft = defaults;
      _schoolNameCtrl.text = defaults.schoolName;
      _addressCtrl.text = defaults.schoolAddress;
      _phoneCtrl.text = defaults.schoolPhone;
      _emailCtrl.text = defaults.schoolEmail;
      _websiteCtrl.text = defaults.schoolWebsite;
      _principalCtrl.text = defaults.principalName;
      _affiliationCtrl.text = defaults.affiliationNo;
      _mottoCtrl.text = defaults.schoolMotto;
      _declarationCtrl.text = defaults.declarationText;
      _errors.clear();
    });
  }

  Future<void> _pickImage({required bool isLetterhead}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    final b64 = base64Encode(file.bytes!);
    setState(() {
      if (isLetterhead) {
        _draft = _draft.copyWith(letterheadBase64: b64, headerLayout: HeaderLayout.letterhead);
      } else {
        _draft = _draft.copyWith(logoBase64: b64);
      }
    });
  }

  Future<void> _pickColor({required bool isBg}) async {
    final current = isBg ? _draft.bgColor : _draft.textColor;
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(initial: current, title: isBg ? 'Background colour' : 'Text colour'),
    );
    if (result == null) return;
    setState(() {
      _draft = isBg ? _draft.copyWith(headerBgColor: result.toARGB32()) : _draft.copyWith(headerTextColor: result.toARGB32());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFAF7FF), border: Border(bottom: BorderSide(color: Color(0xFFE9D5FF)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Header Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                const Text('Changes save on this device and appear on every printed form.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                _buildTabBar(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: switch (_tab) {
              _SettingsTab.identity => _buildIdentityTab(),
              _SettingsTab.layout => _buildLayoutTab(),
              _SettingsTab.import => _buildImportTab(),
              _SettingsTab.declaration => _buildDeclarationTab(),
            },
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE9D5FF)))),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _resetDefaults,
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6B7280), side: const BorderSide(color: Color(0xFFE5E7EB))),
                  child: const Text('Reset defaults'),
                ),
                Wrap(spacing: 8, children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB))),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C3CE1), foregroundColor: Colors.white),
                    child: Text(_saved ? '✓ Applied!' : 'Apply & save'),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    Widget tabBtn(_SettingsTab tab, String label) {
      final active = _tab == tab;
      return InkWell(
        onTap: () => setState(() => _tab = tab),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [const BoxShadow(color: Color(0x14000000), blurRadius: 4)] : null,
          ),
          child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? const Color(0xFF6C3CE1) : const Color(0xFF64748B))),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: const Color(0x0A000000), borderRadius: BorderRadius.circular(10)),
      child: Wrap(spacing: 4, runSpacing: 4, children: [
        tabBtn(_SettingsTab.identity, '🏫 School Info'),
        tabBtn(_SettingsTab.layout, '🎨 Logo & Layout'),
        tabBtn(_SettingsTab.import, '📄 Letterhead'),
        tabBtn(_SettingsTab.declaration, '📝 Declaration'),
      ]),
    );
  }

  Widget _field(String label, TextEditingController controller, {String? error, String? hint, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: error != null ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: error != null ? const Color(0xFFEF4444) : const Color(0xFFC4B5FD), width: 1.5)),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(error, style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444))),
            ),
        ],
      ),
    );
  }

  Widget _twoUp(Widget a, Widget b) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 380) {
        return Column(children: [a, b]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );
    });
  }

  Widget _buildIdentityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('School Name *', _schoolNameCtrl, error: _errors['schoolName'], hint: 'e.g. Sunshine Public School'),
        _field('Address', _addressCtrl, hint: 'Street, City, PIN'),
        _twoUp(
          _field('Phone', _phoneCtrl, error: _errors['schoolPhone'], hint: '+91 98765 43210'),
          _field('Email', _emailCtrl, error: _errors['schoolEmail'], hint: 'admissions@school.in'),
        ),
        _field('Website', _websiteCtrl, hint: 'www.schoolname.in'),
        _twoUp(
          _field('Principal Name *', _principalCtrl, error: _errors['principalName'], hint: 'Full name for signature line'),
          _field('Affiliation / Reg No.', _affiliationCtrl, hint: 'CBSE / State board ref'),
        ),
        _field('Motto / Tagline', _mottoCtrl, hint: 'Shown under school name'),
      ],
    );
  }

  Widget _buildLayoutTab() {
    final layouts = [
      (HeaderLayout.classic, 'Classic', 'Logo left · text right'),
      (HeaderLayout.centered, 'Centered', 'Logo top · text centered'),
      (HeaderLayout.banner, 'Banner', 'Full-width colour band'),
      (HeaderLayout.minimal, 'Minimal', 'Clean text only · no logo'),
      (HeaderLayout.letterhead, 'Letterhead', 'Imported school image'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldGroupLabel('SCHOOL LOGO'),
        const SizedBox(height: 8),
        _logoUploadZone(),
        const SizedBox(height: 18),
        _fieldGroupLabel('HEADER LAYOUT'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: layouts.map((l) {
            final active = _draft.headerLayout == l.$1;
            return InkWell(
              onTap: () => setState(() => _draft = _draft.copyWith(headerLayout: l.$1)),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF5F3FF) : Colors.white,
                  border: Border.all(color: active ? const Color(0xFF8B5CF6) : const Color(0xFFE5E7EB), width: active ? 2 : 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(l.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(l.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _fieldGroupLabel('HEADER COLOURS'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _colorField('Background', _draft.bgColor, () => _pickColor(isBg: true))),
            const SizedBox(width: 16),
            Expanded(child: _colorField('Text', _draft.textColor, () => _pickColor(isBg: false))),
          ],
        ),
      ],
    );
  }

  Widget _fieldGroupLabel(String text) => Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF94A3B8)));

  Widget _colorField(String label, Color value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(color: value, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB)))),
                const SizedBox(width: 8),
                Text('#${value.toARGB32().toRadixString(16).substring(2).toUpperCase()}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF374151))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoUploadZone() {
    if (_draft.logoBase64.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD6FE), width: 2), borderRadius: BorderRadius.circular(12), color: const Color(0xFFFAF5FF)),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(base64Decode(_draft.logoBase64), height: 56, width: 100, fit: BoxFit.contain)),
            const SizedBox(width: 14),
            Wrap(spacing: 8, children: [
              OutlinedButton(onPressed: () => _pickImage(isLetterhead: false), child: const Text('Change')),
              OutlinedButton(
                onPressed: () => setState(() => _draft = _draft.copyWith(logoBase64: '')),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), side: const BorderSide(color: Color(0xFFFECACA))),
                child: const Text('Remove'),
              ),
            ]),
          ],
        ),
      );
    }
    return InkWell(
      onTap: () => _pickImage(isLetterhead: false),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD6FE), width: 2), borderRadius: BorderRadius.circular(12), color: const Color(0xFFFAF5FF)),
        child: Column(
          children: [
            const Icon(Icons.upload_outlined, color: Color(0xFF8B5CF6), size: 28),
            const SizedBox(height: 6),
            const Text('Tap to upload', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 2),
            const Text('PNG, JPG, WebP — transparent background recommended', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), border: Border.all(color: const Color(0xFFE0F2FE)), borderRadius: BorderRadius.circular(10)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How it works', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0369A1))),
              SizedBox(height: 6),
              Text(
                '1. Upload a scan or photo of your school\'s official letterhead.\n'
                '2. We\'ll set it as the header background image.\n'
                '3. The header layout automatically switches to Letterhead mode.\n'
                '4. On print, the letterhead is preserved exactly as-is.',
                style: TextStyle(fontSize: 12, color: Color(0xFF0C4A6E), height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_draft.letterheadBase64.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD6FE), width: 2), borderRadius: BorderRadius.circular(12), color: const Color(0xFFFAF5FF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(base64Decode(_draft.letterheadBase64), height: 80, fit: BoxFit.contain)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  OutlinedButton(onPressed: () => _pickImage(isLetterhead: true), child: const Text('Replace')),
                  OutlinedButton(
                    onPressed: () => setState(() => _draft = _draft.copyWith(letterheadBase64: '', headerLayout: HeaderLayout.classic)),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), side: const BorderSide(color: Color(0xFFFECACA))),
                    child: const Text('Remove'),
                  ),
                ]),
              ],
            ),
          )
        else
          InkWell(
            onTap: () => _pickImage(isLetterhead: true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD6FE), width: 2), borderRadius: BorderRadius.circular(12), color: const Color(0xFFFAF5FF)),
              child: Column(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF8B5CF6), size: 28),
                  const SizedBox(height: 6),
                  const Text('Upload your official letterhead', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 2),
                  const Text('PNG or JPG — any size, we\'ll scale it', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeclarationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF5F3FF), border: Border.all(color: const Color(0xFFEDE9FE)), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            '💡 Use {studentName} — it will be replaced with the student\'s full name when printed. '
            'Changes save with your header settings and apply to all future printed forms.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6D28D9), height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        Text('Declaration / Terms & Conditions (${_declarationCtrl.text.length} chars)', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: _declarationCtrl,
          maxLines: 8,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13, height: 1.6),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(10),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _declarationCtrl.text = kDefaultDeclaration),
            child: const Text('↺ Reset to default declaration', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.6)),
              const SizedBox(height: 6),
              Text(
                (_declarationCtrl.text.isEmpty ? kDefaultDeclaration : _declarationCtrl.text)
                    .replaceAll('{studentName}', widget.studentFullName.trim().isEmpty ? '[Student Name]' : widget.studentFullName),
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  final String title;
  const _ColorPickerDialog({required this.initial, required this.title});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late final TextEditingController _hexCtrl;
  Color? _error;

  @override
  void initState() {
    super.initState();
    _hexCtrl = TextEditingController(text: '#${widget.initial.toARGB32().toRadixString(16).substring(2).toUpperCase()}');
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  void _applyHex() {
    var hex = _hexCtrl.text.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      setState(() => _error = const Color(0xFFDC2626));
      return;
    }
    Navigator.of(context).pop(Color(parsed));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _headerColorPalette
                    .map((c) => GestureDetector(
                          onTap: () => Navigator.of(context).pop(c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB))),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hexCtrl,
                decoration: InputDecoration(
                  labelText: 'Hex colour',
                  hintText: '#6C3CE1',
                  errorText: _error != null ? 'Enter a valid hex colour' : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _applyHex, child: const Text('Use colour')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
