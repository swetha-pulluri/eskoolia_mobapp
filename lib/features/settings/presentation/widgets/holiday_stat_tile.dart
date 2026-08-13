import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum HolidayStatTone { purple, blue, amber, rose }

class _Tone {
  final Color bg;
  final Color fg;
  const _Tone(this.bg, this.fg);
}

const Map<HolidayStatTone, _Tone> _tones = {
  HolidayStatTone.purple: _Tone(AppColors.purpleTint, AppColors.purpleAccent),
  HolidayStatTone.blue: _Tone(AppColors.blueSoft, AppColors.infoBlue),
  HolidayStatTone.amber: _Tone(AppColors.amberSoft, AppColors.warningAmber),
  HolidayStatTone.rose: _Tone(AppColors.redSoft, AppColors.dangerRed),
};

/// A single stat tile — mirrors `HolidaysPanel.tsx`'s `StatTile`, same shape
/// already used by Leave Policy's review step (kept as a separate,
/// Holiday-scoped copy so each Settings sub-feature stays self-contained).
class HolidayStatTile extends StatelessWidget {
  final IconData icon;
  final HolidayStatTone tone;
  final String label;
  final String value;

  const HolidayStatTile({super.key, required this.icon, required this.tone, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = _tones[tone]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        // A soft wash of the tile's own tone instead of one flat neutral
        // gray — same treatment as Leave Policy's stat tiles, so the two
        // review-step grids read consistently across Settings.
        color: Color.alphaBlend(t.bg.withValues(alpha: 0.45), AppColors.bgPrimary),
        border: Border.all(color: t.fg.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 13, color: t.fg),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
