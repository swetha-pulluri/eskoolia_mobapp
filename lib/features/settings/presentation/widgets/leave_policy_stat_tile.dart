import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum LeaveStatTone { purple, blue, amber, rose }

class _Tone {
  final Color bg;
  final Color fg;
  const _Tone(this.bg, this.fg);
}

/// Tone → color mapping — reuses this app's existing shared palette
/// (`AppColors`, already established by School Info) rather than
/// introducing a second, slightly different set of soft/tint hexes just
/// for this screen.
const Map<LeaveStatTone, _Tone> _tones = {
  LeaveStatTone.purple: _Tone(AppColors.purpleTint, AppColors.purpleAccent),
  LeaveStatTone.blue: _Tone(AppColors.blueSoft, AppColors.infoBlue),
  LeaveStatTone.amber: _Tone(AppColors.amberSoft, AppColors.warningAmber),
  LeaveStatTone.rose: _Tone(AppColors.redSoft, AppColors.dangerRed),
};

/// A single stat tile — mirrors `LeavePolicyPanel.tsx`'s `StatTile`: a
/// 26px tone-colored icon chip, an uppercase 9.5px label, and a bold 12.5px
/// value line.
class LeaveStatTile extends StatelessWidget {
  final IconData icon;
  final LeaveStatTone tone;
  final String label;
  final String value;

  const LeaveStatTile({super.key, required this.icon, required this.tone, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = _tones[tone]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        // A soft wash of the tile's own tone instead of one flat neutral
        // gray for every tile — makes the 4-tile grid read as color-coded
        // categories at a glance rather than 4 identical boxes.
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
