import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../providers/document_branding_provider.dart';
import '../providers/document_branding_state.dart';
import '../widgets/document_branding_color_field.dart';
import '../widgets/document_branding_declarations.dart';
import '../widgets/document_branding_letterhead_field.dart';
import '../widgets/document_branding_preview.dart';
import '../widgets/document_branding_segmented.dart';
import '../widgets/document_branding_style_cards.dart';

/// Settings → Document Branding — a 1:1 port of
/// `frontend/components/settings/DocumentBrandingPanel.tsx`: a singleton
/// settings form (Header / Declarations tabs) + a live preview pane, unlike
/// every other Settings screen's card-list-plus-wizard shape.
class DocumentBrandingPage extends ConsumerWidget {
  const DocumentBrandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentBrandingNotifierProvider);
    final notifier = ref.read(documentBrandingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.load,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                border: Border.all(color: AppColors.borderPrimary),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x0A0F1222), blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(state, notifier),
                  if (state.error != null) _banner(state.error!, AppColors.dangerRed, AppColors.redSoft, Icons.warning_amber_rounded),
                  if (state.success != null) _banner(state.success!, AppColors.successGreen, AppColors.greenSoft, Icons.check_circle),
                  if (state.loading) _loading(),
                  if (!state.loading) ...[
                    const SizedBox(height: 14),
                    _tabStrip(state, notifier),
                    const SizedBox(height: 14),
                    if (state.activeTab == 0) _headerTab(state, notifier) else _declarationsTab(state, notifier),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(DocumentBrandingState state, DocumentBrandingNotifier notifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Document ', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Branding', style: TextStyle(fontSize: 25, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: AppColors.purpleAccent)),
                ],
              ),
              SizedBox(height: 6),
              Text('Header applied to every PDF in the ERP', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
        ),
        if (!state.loading)
          ElevatedButton(
            onPressed: state.saving ? null : notifier.submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: state.saving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text('Saving…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 15),
                      SizedBox(width: 6),
                      Text('Save changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _banner(String message, Color fg, Color bg, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)),
            SizedBox(width: 10),
            Text('Loading…', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _tabStrip(DocumentBrandingState state, DocumentBrandingNotifier notifier) {
    return Row(
      children: [
        _tab(label: 'Header', icon: Icons.dashboard_customize_outlined, index: 0, state: state, notifier: notifier),
        const SizedBox(width: 8),
        _tab(label: 'Declarations', icon: Icons.description_outlined, index: 1, state: state, notifier: notifier),
      ],
    );
  }

  Widget _tab({
    required String label,
    required IconData icon,
    required int index,
    required DocumentBrandingState state,
    required DocumentBrandingNotifier notifier,
  }) {
    final selected = state.activeTab == index;
    return InkWell(
      onTap: () => notifier.setActiveTab(index),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleTint : AppColors.bgSecondary,
          border: Border.all(color: selected ? AppColors.purpleSoft : AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.purpleAccent : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? AppColors.purpleAccent : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _headerTab(DocumentBrandingState state, DocumentBrandingNotifier notifier) {
    final draft = state.draft;
    final mode = (draft['header_mode'] as String?) ?? 'generated';
    final isGenerated = mode == 'generated';
    final showLogo = (draft['show_logo'] as bool?) ?? true;
    final showDivider = (draft['show_divider'] as bool?) ?? true;
    final showWatermark = (draft['show_watermark'] as bool?) ?? false;
    final settings = state.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Header source'),
        const SizedBox(height: 8),
        DocumentBrandingModeCard(
          label: 'Built from school info',
          subtitle: 'Generated from your school\'s name, address, and style choices below.',
          selected: isGenerated,
          onTap: () => notifier.setDraftField('header_mode', 'generated'),
        ),
        const SizedBox(height: 8),
        DocumentBrandingModeCard(
          label: 'Uploaded letterhead',
          subtitle: settings?.letterheadFileName?.isNotEmpty == true ? '"${settings!.letterheadFileName}"' : 'Upload a file below',
          selected: !isGenerated,
          disabled: settings?.letterheadFileName == null || settings!.letterheadFileName!.isEmpty,
          onTap: () => notifier.setDraftField('header_mode', 'uploaded'),
        ),
        const SizedBox(height: 10),
        DocumentBrandingLetterheadField(
          existingFileName: settings?.letterheadFileName,
          uploading: state.uploading,
          onPicked: (file, mime) => notifier.uploadLetterhead(file, mime),
        ),
        if (isGenerated) ...[
          const SizedBox(height: 10),
          Opacity(
            opacity: state.hasSchoolLogo ? 1 : 0.65,
            child: _toggleRow(
              icon: Icons.image_outlined,
              label: 'Include logo',
              value: showLogo,
              onChanged: state.hasSchoolLogo ? (v) => notifier.setDraftField('show_logo', v) : null,
            ),
          ),
          if (!state.hasSchoolLogo) ...[
            const SizedBox(height: 4),
            const Text('Add a logo under School Info → Branding to enable this', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: 14),
          _sectionLabel('Style'),
          const SizedBox(height: 6),
          _pairedRow(documentBrandingHeaderStyles, (style) {
            return DocumentBrandingStyleCard(
              value: style.value,
              label: style.label,
              hint: style.hint,
              selected: (draft['header_style'] as String?) == style.value,
              onTap: () => notifier.setDraftField('header_style', style.value),
            );
          }),
          const SizedBox(height: 14),
          _sectionLabel('Layout'),
          const SizedBox(height: 6),
          DocumentBrandingSegmented(
            label: 'Size',
            value: (draft['header_size'] as String?) ?? 'standard',
            options: documentBrandingHeaderSizes,
            onChanged: (v) => notifier.setDraftField('header_size', v),
          ),
          const SizedBox(height: 10),
          DocumentBrandingSegmented(
            label: 'Logo',
            value: (draft['logo_position'] as String?) ?? 'center',
            options: documentBrandingLogoPositions,
            onChanged: (v) => notifier.setDraftField('logo_position', v),
          ),
        ],
        const SizedBox(height: 14),
        _sectionLabel('Colors'),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DocumentBrandingColorField(
                label: 'Text color',
                value: (draft['header_text_color'] as String?) ?? '#1A1A2E',
                onChanged: (v) => notifier.setDraftField('header_text_color', v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DocumentBrandingColorField(
                label: 'Accent / dividers',
                value: (draft['accent_color'] as String?) ?? '#1A1A2E',
                onChanged: (v) => notifier.setDraftField('accent_color', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sectionLabel('Decorations'),
        const SizedBox(height: 6),
        _toggleRow(
          icon: Icons.horizontal_rule,
          label: 'Bottom divider',
          value: showDivider,
          onChanged: (v) => notifier.setDraftField('show_divider', v),
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < documentBrandingDividerStyles.length; i++) ...[
                Expanded(
                  child: DocumentBrandingDividerSwatch(
                    value: documentBrandingDividerStyles[i].key,
                    label: documentBrandingDividerStyles[i].value,
                    selected: (draft['divider_style'] as String?) == documentBrandingDividerStyles[i].key,
                    onTap: () => notifier.setDraftField('divider_style', documentBrandingDividerStyles[i].key),
                  ),
                ),
                if (i != documentBrandingDividerStyles.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
        const SizedBox(height: 8),
        _toggleRow(
          icon: Icons.gradient_outlined,
          label: 'Diagonal watermark',
          value: showWatermark,
          onChanged: (v) => notifier.setDraftField('show_watermark', v),
        ),
        if (showWatermark) ...[
          const SizedBox(height: 8),
          TextField(
            maxLength: 80,
            onChanged: (v) => notifier.setDraftField('watermark_text', v),
            controller: TextEditingController(text: (draft['watermark_text'] as String?) ?? ''),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Defaults to school name when blank',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSecondary)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSecondary)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.purpleAccent)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DocumentBrandingPreview(state: state, onToggleBw: notifier.toggleBw),
      ],
    );
  }

  /// Lays out [items] two-per-row using `Expanded` siblings rather than a
  /// `GridView` with a fixed `childAspectRatio` — each card sizes to its
  /// own natural (intrinsic) height instead of being forced into a shared
  /// fixed cell height, so a longer style (e.g. "Letterpress") can never
  /// overflow the box a shorter one would fit fine.
  Widget _pairedRow<T>(List<T> items, Widget Function(T item) builder) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final hasSecond = i + 1 < items.length;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: builder(items[i])),
          const SizedBox(width: 8),
          Expanded(child: hasSecond ? builder(items[i + 1]) : const SizedBox.shrink()),
        ],
      ));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 8));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _declarationsTab(DocumentBrandingState state, DocumentBrandingNotifier notifier) {
    return DocumentBrandingDeclarations(
      draft: state.draft,
      selectedKey: state.selectedDeclarationKey,
      saving: state.saving,
      onSelect: notifier.selectDeclaration,
      onChanged: notifier.setDraftField,
      onSave: notifier.submit,
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  Widget _toggleRow({required IconData icon, required String label, required bool value, required ValueChanged<bool>? onChanged}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
            Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.purpleAccent),
          ],
        ),
      ),
    );
  }
}
