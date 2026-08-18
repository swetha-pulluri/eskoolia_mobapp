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
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
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
          const SizedBox(height: 8),
          // Content-driven 3-column layout — a `Wrap` sized only by a fixed
          // tile *width* — instead of a fixed row-height `GridView`. Two
          // rounds of tuning `childAspectRatio`/`mainAxisExtent` each failed
          // on a different device width (clipped content on a narrow phone,
          // then a visible empty gap under the heading on a wide one),
          // because the emoji+label content's real height doesn't scale
          // with screen width the way a uniform row height must. Each
          // button's height here is just whatever its own content needs.
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final tileWidth = (constraints.maxWidth - spacing * 2) / 3;
              return Wrap(
                spacing: spacing,
                runSpacing: 8,
                children: [
                  for (final template in broadcastTemplates)
                    SizedBox(width: tileWidth, child: _templateButton(context, template)),
                ],
              );
            },
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
        // `topCenter`, not `center` — same reasoning as
        // `TeacherQuickAccessTile`: the fixed `mainAxisExtent` cell is
        // slightly taller than the content needs as a clipping buffer;
        // centering put half that buffer above the emoji, reading as a gap
        // under the "Quick Broadcast" heading for row 1.
        alignment: Alignment.topCenter,
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
