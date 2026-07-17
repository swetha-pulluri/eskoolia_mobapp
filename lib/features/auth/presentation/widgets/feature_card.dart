import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Feature Card Widget
/// Exact replica of .feature-card from frontend/app/globals.css
///
/// React equivalent:
/// ```tsx
/// <FeatureCard icon="school" title="Academics" note="Curriculum & Grading" tone="teal" />
/// ```
class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String note;
  final FeatureCardTone tone;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.note,
    required this.tone,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForTone(widget.tone);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          10,
        ), // padding: 10px 14px
        decoration: BoxDecoration(
          color: AppColors.glassFeatureCard, // rgba(255,255,255,0.6)
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? colors.borderColor
                : AppColors.white.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppColors.atriumIndigo.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _isHovered ? 18 : 1,
              offset: _isHovered ? const Offset(0, 18) : const Offset(0, 1),
            ),
          ],
        ),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: Row(
          children: [
            // Feature Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isHovered ? colors.iconColor : colors.iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                size: 22,
                color: _isHovered ? AppColors.white : colors.iconColor,
              ),
            ),
            const SizedBox(width: 10),
            // Feature Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.84, // 0.06em * 14px = 0.84px
                      height: 1.0,
                    ).copyWith(fontFamily: 'Plus Jakarta Sans'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.note,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ).copyWith(fontFamily: 'Plus Jakarta Sans'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _FeatureCardColors _getColorsForTone(FeatureCardTone tone) {
    switch (tone) {
      case FeatureCardTone.teal:
        return _FeatureCardColors(
          iconBackground: AppColors.tealAccent,
          iconColor: AppColors.airaTeal,
          borderColor: AppColors.airaTeal.withOpacity(0.3),
        );
      case FeatureCardTone.saffron:
        return _FeatureCardColors(
          iconBackground: AppColors.saffronAccent,
          iconColor: AppColors.saffron,
          borderColor: AppColors.saffron.withOpacity(0.3),
        );
      case FeatureCardTone.marigold:
        return _FeatureCardColors(
          iconBackground: AppColors.marigoldAccent,
          iconColor: AppColors.marigold,
          borderColor: AppColors.marigold.withOpacity(0.3),
        );
      case FeatureCardTone.indigo:
        return _FeatureCardColors(
          iconBackground: AppColors.indigoAccent,
          iconColor: AppColors.atriumIndigo,
          borderColor: AppColors.atriumIndigo.withOpacity(0.3),
        );
    }
  }
}

class _FeatureCardColors {
  final Color iconBackground;
  final Color iconColor;
  final Color borderColor;

  _FeatureCardColors({
    required this.iconBackground,
    required this.iconColor,
    required this.borderColor,
  });
}

enum FeatureCardTone { teal, saffron, marigold, indigo }
