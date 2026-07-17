import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Security Panel Widget
/// Exact replica of .security-panel from frontend/app/globals.css
/// 
/// React code:
/// ```tsx
/// <div className="security-panel">
///   <div>
///     <span className="material-symbols-outlined filled">shield_person</span>
///   </div>
///   <div>
///     <p>Secured by eSkoolia</p>
///     <span>Institutional-grade 256-bit AES encryption active.</span>
///   </div>
/// </div>
/// ```
class SecurityPanel extends StatelessWidget {
  const SecurityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.verified_user, // Material Icons equivalent of shield_person
          size: 24,
          color: AppColors.airaTeal,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Secured by eSkoolia',
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ).copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Institutional-grade 256-bit AES encryption active.',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ).copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
