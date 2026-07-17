import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Gateway Badge Widget
/// Exact replica of .gateway-badge from frontend/app/globals.css
/// 
/// React code:
/// ```tsx
/// <div className="gateway-badge">
///   <span className="material-symbols-outlined filled">verified</span>
///   <span>Official Digital Gateway</span>
/// </div>
/// ```
class GatewayBadge extends StatelessWidget {
  const GatewayBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.8), // rgba(255,255,255,0.8)
        border: Border.all(
          color: AppColors.airaTeal.withOpacity(0.2), // rgba(13,148,136,0.2)
          width: 1,
        ),
        borderRadius: BorderRadius.circular(999), // pill shape
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified, // Material Icons equivalent of verified
            size: 20,
            color: AppColors.saffron,
          ),
          const SizedBox(width: 12),
          Text(
            'Official Digital Gateway',
            style: const TextStyle(
              color: AppColors.airaTeal,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.16, // 0.18em * 12px = 2.16px
              height: 16 / 12, // line-height: 16px / font-size: 12px
            ).copyWith(
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}
