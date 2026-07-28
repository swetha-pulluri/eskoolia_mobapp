import 'package:flutter/material.dart';
import '../../domain/models/school_header_settings.dart';
import '../utils/enrollment_pdf.dart';
import 'verification_form_document.dart';

/// Mirrors `ConsentForm.tsx`'s `ACCENT_COLORS` swatch palette exactly.
const List<Color> kAccentColorPalette = [
  Color(0xFF6C3CE1),
  Color(0xFF0EA5E9),
  Color(0xFF059669),
  Color(0xFFDC2626),
  Color(0xFFEA580C),
  Color(0xFF7C3AED),
  Color(0xFF0F172A),
];

class VerificationFormTip {
  final IconData icon;
  final String title;
  final String body;
  final Color tintBg;
  final Color tintBorder;
  final VoidCallback? action;
  final String? actionLabel;
  const VerificationFormTip({
    required this.icon,
    required this.title,
    required this.body,
    required this.tintBg,
    required this.tintBorder,
    this.action,
    this.actionLabel,
  });
}

/// The "AI Layout Assistant" panel — mirrors `ConsentForm.tsx`'s
/// `.cf-ai-panel` exactly: a completeness score ring, 3 layout presets, an
/// accent-colour swatch row, a section-visibility toggle grid, and
/// data-driven smart tips.
class VerificationFormAiPanel extends StatelessWidget {
  final EnrollmentPdfData data;
  final SchoolHeaderSettings header;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;
  final Set<String> hiddenSections;
  final ValueChanged<String> onToggleSection;
  final VoidCallback onShowAll;
  final VoidCallback onHideAll;
  final ValueChanged<String> onApplyPreset;
  final VoidCallback onOpenHeaderSettings;

  const VerificationFormAiPanel({
    super.key,
    required this.data,
    required this.header,
    required this.accentColor,
    required this.onAccentColorChanged,
    required this.hiddenSections,
    required this.onToggleSection,
    required this.onShowAll,
    required this.onHideAll,
    required this.onApplyPreset,
    required this.onOpenHeaderSettings,
  });

  List<VerificationFormTip> _buildTips() {
    const defaults = SchoolHeaderSettings();
    final tips = <VerificationFormTip>[];
    Color infoBg = const Color(0xFFF0F9FF), infoBorder = const Color(0xFFE0F2FE);
    Color warnBg = const Color(0xFFFFFBEB), warnBorder = const Color(0xFFFEF3C7);

    if (header.logoBase64.isEmpty) {
      tips.add(VerificationFormTip(
        icon: Icons.image_outlined,
        title: 'Add a school logo',
        body: 'Upload your logo. It appears at the top of every printed form.',
        tintBg: infoBg,
        tintBorder: infoBorder,
        action: onOpenHeaderSettings,
        actionLabel: 'Upload logo',
      ));
    }
    if (header.schoolName == defaults.schoolName) {
      tips.add(VerificationFormTip(
        icon: Icons.school_outlined,
        title: 'Update school name',
        body: 'Still showing the default "Eskoolia School". Set your real school name in header settings.',
        tintBg: warnBg,
        tintBorder: warnBorder,
        action: onOpenHeaderSettings,
        actionLabel: 'Open settings',
      ));
    }
    if (header.principalName.trim().isEmpty || header.principalName == defaults.principalName) {
      tips.add(VerificationFormTip(
        icon: Icons.edit_outlined,
        title: "Set principal's name",
        body: 'The signature line reads "Principal". Add the full name for a polished, official document.',
        tintBg: infoBg,
        tintBorder: infoBorder,
        action: onOpenHeaderSettings,
        actionLabel: 'Open settings',
      ));
    }
    if (data.photoUrl == null || data.photoUrl!.isEmpty) {
      tips.add(VerificationFormTip(
        icon: Icons.camera_alt_outlined,
        title: 'No student photo',
        body: 'A photo in Section 1 helps verify identity. Upload one in the Identity step of the enrollment form.',
        tintBg: warnBg,
        tintBorder: warnBorder,
      ));
    }
    if (data.firstName.trim().isEmpty || data.lastName.trim().isEmpty) {
      tips.add(VerificationFormTip(
        icon: Icons.person_outline,
        title: 'Student name incomplete',
        body: 'First or last name is missing. Go back to Identity step to fill it in.',
        tintBg: warnBg,
        tintBorder: warnBorder,
      ));
    }
    if (data.admissionNo.trim().isEmpty) {
      tips.add(VerificationFormTip(
        icon: Icons.numbers_outlined,
        title: 'No admission number',
        body: 'Admission number is required for official records. It should be auto-generated in Step 1.',
        tintBg: warnBg,
        tintBorder: warnBorder,
      ));
    }
    if (data.guardians.isEmpty) {
      tips.add(VerificationFormTip(
        icon: Icons.family_restroom_outlined,
        title: 'No guardian details',
        body: 'At least one guardian is required. Fill in the Guardians step of the enrollment form.',
        tintBg: warnBg,
        tintBorder: warnBorder,
      ));
    }
    if (data.emergencyContact.trim().isEmpty) {
      tips.add(VerificationFormTip(
        icon: Icons.emergency_outlined,
        title: 'Emergency contact missing',
        body: 'An emergency contact is important for safety. Fill it in the Medical step.',
        tintBg: infoBg,
        tintBorder: infoBorder,
      ));
    }
    if (hiddenSections.isNotEmpty) {
      tips.add(VerificationFormTip(
        icon: Icons.visibility_off_outlined,
        title: '${hiddenSections.length} section(s) hidden',
        body: "Some sections are hidden and won't appear in print. Use section toggles to adjust.",
        tintBg: infoBg,
        tintBorder: infoBorder,
        action: onShowAll,
        actionLabel: 'Show all',
      ));
    }
    return tips;
  }

  int _completenessPercent() {
    const defaults = SchoolHeaderSettings();
    final fullName = [data.firstName, data.lastName].where((s) => s.trim().isNotEmpty).join(' ');
    final checks = [
      header.logoBase64.isNotEmpty,
      header.schoolName != defaults.schoolName,
      header.principalName.trim().isNotEmpty && header.principalName != defaults.principalName,
      data.photoUrl != null && data.photoUrl!.isNotEmpty,
      fullName.trim().isNotEmpty,
      data.admissionNo.trim().isNotEmpty,
      data.dob.trim().isNotEmpty,
      data.className.trim().isNotEmpty,
      data.phone.trim().isNotEmpty,
      data.guardians.isNotEmpty,
      data.emergencyContact.trim().isNotEmpty,
    ];
    return ((checks.where((c) => c).length / checks.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _completenessPercent();
    final tone = pct >= 80
        ? const Color(0xFF059669)
        : pct >= 50
            ? const Color(0xFFD97706)
            : const Color(0xFF8B5CF6);
    final tips = _buildTips();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF5FF),
        border: Border(bottom: BorderSide(color: Color(0xFFE9D5FF))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        const Text('AI Layout Assistant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text('Real-time suggestions to make your form official and complete.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation(tone),
                      ),
                    ),
                    Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tone)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionLabel('LAYOUT PRESET'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetCard('official', '🏛️', 'Official', 'All 10 sections'),
              _presetCard('minimal', '✦', 'Minimal', 'Core 5 sections only'),
              _presetCard('detailed', '📋', 'Detailed', 'All sections + full data'),
            ],
          ),
          const SizedBox(height: 16),

          _sectionLabel('ACCENT COLOUR'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: kAccentColorPalette.map((c) {
              final active = c.toARGB32() == accentColor.toARGB32();
              return GestureDetector(
                onTap: () => onAccentColorChanged(c),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: active ? Border.all(color: Colors.white, width: 2.5) : null,
                    boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 0, spreadRadius: 2)] : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _sectionLabel('SECTION VISIBILITY'),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 420 ? 2 : 1;
            final itemWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: kVerificationSections.map((s) {
                final visible = !hiddenSections.contains(s.$1);
                return SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () => onToggleSection(s.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: visible,
                              onChanged: (_) => onToggleSection(s.$1),
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF8B5CF6),
                              inactiveTrackColor: const Color(0xFFE5E7EB),
                              inactiveThumbColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(child: Text(s.$2, style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              children: [
                _linkButton('Show all', onShowAll),
                _linkButton('Hide all', onHideAll),
              ],
            ),
          ),

          if (tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel('SMART SUGGESTIONS (${tips.length})'),
            const SizedBox(height: 8),
            Column(children: tips.map(_tipCard).toList()),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), border: Border.all(color: const Color(0xFFDCFCE7)), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Everything looks great! This form is ready to print or save as PDF.', style: TextStyle(fontSize: 13, color: Color(0xFF166534), fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
      );

  Widget _presetCard(String id, String icon, String label, String desc) {
    return SizedBox(
      width: 104,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onApplyPreset(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkButton(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(7)),
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6C3CE1), fontWeight: FontWeight.w500)),
        ),
      );

  Widget _tipCard(VerificationFormTip tip) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: tip.tintBg, border: Border.all(color: tip.tintBorder), borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tip.icon, size: 18, color: const Color(0xFF475569)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(tip.body, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
                ],
              ),
            ),
            if (tip.action != null && tip.actionLabel != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: tip.action,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0x126C3CE1), border: Border.all(color: const Color(0x266C3CE1)), borderRadius: BorderRadius.circular(6)),
                  child: Text(tip.actionLabel!, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF6C3CE1))),
                ),
              ),
            ],
          ],
        ),
      );
}
