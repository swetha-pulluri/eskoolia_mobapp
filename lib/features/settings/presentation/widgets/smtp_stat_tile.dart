import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum SmtpStatTone { purple, blue, amber, rose }

class _Tone {
  final Color bg;
  final Color fg;
  const _Tone(this.bg, this.fg);
}

const Map<SmtpStatTone, _Tone> _tones = {
  SmtpStatTone.purple: _Tone(AppColors.purpleTint, AppColors.purpleAccent),
  SmtpStatTone.blue: _Tone(AppColors.blueSoft, AppColors.infoBlue),
  SmtpStatTone.amber: _Tone(AppColors.amberSoft, AppColors.warningAmber),
  SmtpStatTone.rose: _Tone(AppColors.redSoft, AppColors.dangerRed),
};

/// A single stat tile — mirrors `SmtpSettingsPanel.tsx`'s `StatTile`, same
/// shape already used by Leave Policy/Holiday Calendar (kept as a separate,
/// SMTP-scoped copy so each Settings sub-feature stays self-contained).
class SmtpStatTile extends StatelessWidget {
  final IconData icon;
  final SmtpStatTone tone;
  final String label;
  final String value;

  const SmtpStatTile({super.key, required this.icon, required this.tone, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = _tones[tone]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
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
