import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The two "Header source" mode cards — mirrors `DocumentBrandingPanel.tsx`'s
/// `header_mode` radio-style cards ("Built from school info" vs. upload).
class DocumentBrandingModeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const DocumentBrandingModeCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.purpleTint : AppColors.bgPrimary,
            border: Border.all(color: selected ? AppColors.purpleAccent : AppColors.borderSecondary),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 17,
                color: selected ? AppColors.purpleAccent : AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the 6 header-style selectable cards — mirrors
/// `DocumentBrandingPanel.tsx`'s style cards (mini layout diagram + label +
/// hint). The diagram is a simplified schematic recreation (small
/// boxes/lines standing in for logo/text), matching the web's own
/// hand-drawn-diagram intent rather than a pixel-accurate reproduction of
/// SVG art the web itself doesn't expose as ported-able assets.
class DocumentBrandingStyleCard extends StatelessWidget {
  final String value;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const DocumentBrandingStyleCard({
    super.key,
    required this.value,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleTint : AppColors.bgPrimary,
          border: Border.all(color: selected ? AppColors.purpleAccent : AppColors.borderSecondary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderStyleDiagram(style: value),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected) const Icon(Icons.check_circle, size: 14, color: AppColors.purpleAccent),
              ],
            ),
            const SizedBox(height: 2),
            Text(hint, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

/// A small schematic recreation of each header layout — sized purely from
/// its own content (no fixed/stretched height) so a longer stack like
/// `letterpress`'s 4 rows can never overflow the box it sits in, matching
/// whatever height the tallest variant actually needs instead of a
/// guessed fixed number.
class _HeaderStyleDiagram extends StatelessWidget {
  final String style;

  const _HeaderStyleDiagram({required this.style});

  Widget _dot() => Container(width: 11, height: 11, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(3)));

  Widget _line({double width = double.infinity, double height = 2.5}) =>
      Container(width: width, height: height, color: AppColors.borderSecondary);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(6)),
      child: switch (style) {
        'modern' => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _dot(),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_line(width: 40), const SizedBox(height: 3), _line(width: 26, height: 2)],
                ),
              ),
            ],
          ),
        'minimal' => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [_dot(), const SizedBox(width: 6), Expanded(child: _line())],
          ),
        'executive' => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _dot(),
              const SizedBox(width: 6),
              Container(width: 1, height: 16, color: AppColors.borderSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_line(width: 44), const SizedBox(height: 3), _line(width: 30, height: 2)],
                ),
              ),
            ],
          ),
        'letterpress' => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _line(height: 2),
              const SizedBox(height: 3),
              _dot(),
              const SizedBox(height: 3),
              _line(width: 36, height: 2),
              const SizedBox(height: 3),
              _line(height: 2),
            ],
          ),
        'banner' => Container(
            decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            alignment: Alignment.centerLeft,
            child: Container(width: 40, height: 3, color: Colors.white),
          ),
        _ => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [_dot(), const SizedBox(height: 3), _line(width: 36, height: 2), const SizedBox(height: 3), _line(width: 24, height: 2)],
          ),
      },
    );
  }
}

/// One of the 5 divider-style swatches — mirrors `DividerPreview` in
/// `DocumentBrandingPanel.tsx` (none/solid/double/dashed/thick_rule).
class DocumentBrandingDividerSwatch extends StatelessWidget {
  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DocumentBrandingDividerSwatch({
    super.key,
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleTint : AppColors.bgPrimary,
          border: Border.all(color: selected ? AppColors.purpleAccent : AppColors.borderSecondary),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12, child: Center(child: _divider())),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? AppColors.purpleAccent : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    switch (value) {
      case 'none':
        return const SizedBox.shrink();
      case 'double':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: double.infinity, height: 1, color: AppColors.textSecondary),
            const SizedBox(height: 3),
            Container(width: double.infinity, height: 1, color: AppColors.textSecondary),
          ],
        );
      case 'dashed':
        return Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(height: 2, color: AppColors.textSecondary),
              ),
            ),
          ),
        );
      case 'thick_rule':
        return Container(width: double.infinity, height: 3, color: AppColors.textSecondary);
      case 'solid':
      default:
        return Container(width: double.infinity, height: 1, color: AppColors.textSecondary);
    }
  }
}
