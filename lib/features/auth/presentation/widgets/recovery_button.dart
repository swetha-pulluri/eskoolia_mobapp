import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Exact replica of frontend/app/globals.css's `.primary-flow-button` /
/// `.editorial-form button` — gradient (--surface-tint → --atrium-indigo),
/// uppercase bold label flush left, icon flush right (`justify-content:
/// space-between`), unlike [AtriumButton]'s centered label+icon.
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
    return Opacity(
      opacity: isDisabled ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.recoveryButtonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      isLoading ? loadingLabel : label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ).copyWith(fontFamily: 'Plus Jakarta Sans'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.white)),
                        )
                      : Icon(icon, color: AppColors.white, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
