import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'quick_broadcast_compose_sheet.dart';

/// "Quick Broadcast" — 2×3 grid of preset buttons, each opening the real
/// compose sheet (`quick_broadcast_compose_sheet.dart`) pre-filled with the
/// matching template, posting to the real, implemented broadcast endpoint.
class QuickBroadcastCard extends StatelessWidget {
  const QuickBroadcastCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bg1, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, size: 16, color: AppColors.ink1),
              SizedBox(width: 6),
              Text('Quick Broadcast', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink1)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: [
              for (final template in broadcastTemplates) _templateButton(context, template),
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateButton(BuildContext context, BroadcastTemplate template) {
    return InkWell(
      onTap: () => showBroadcastComposeSheet(context, template),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(template.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              template.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink2),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
