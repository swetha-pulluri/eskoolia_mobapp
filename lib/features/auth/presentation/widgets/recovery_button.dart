import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Primary action button for the Forgot/Reset Password screens — the same
/// white pill + brand-blue text as the login screen's "SIGN IN" button,
/// not the old gradient-filled "Atrium" recovery button.
class RecoveryButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final IconData icon;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  const RecoveryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loadingLabel = 'Please wait…',
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || !enabled;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.purpleDeep,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          elevation: 0,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.purpleDeep),
                  ),
                  const SizedBox(width: 10),
                  Text(loadingLabel, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label.toUpperCase(), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18),
                ],
              ),
      ),
    );
  }
}
