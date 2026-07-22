import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Exact port of the web panels' shared `buttonStyle(color)` helper:
/// height 36, borderRadius 8, filled background, white 13px text.
/// Used for Save/Update/Cancel, Edit/Delete (Visitor Book, Phone Calls,
/// Postal), and Previous/Next everywhere — this one primitive really is
/// shared across the web panels (only the color argument changes).
class WebButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool disabled;

  const WebButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primaryPurple,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressed == null;
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
