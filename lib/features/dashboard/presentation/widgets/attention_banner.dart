import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../providers/dashboard_provider.dart';

const Color _attentionIconBg = Color(0xFFFEF3C7);
const Color _attentionText = Color(0xFF92400E);

/// Home screen "N items need your attention" callout — its own compact
/// card between the greeting card and "Today's Pulse" (previously an
/// inline line inside `GreetingSection`). Fed by the same
/// [attentionCountProvider] with the same "only show when > 0" rule as
/// before — purely a presentational split, no behavior change.
class AttentionBanner extends ConsumerWidget {
  const AttentionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attentionCount = ref.watch(attentionCountProvider);
    final count = attentionCount.hasValue ? attentionCount.value! : 0;
    final visible = count > 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, alignment: Alignment.topCenter, child: child),
      ),
      child: visible
          ? Padding(
              key: const ValueKey('attention-visible'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: PremiumCard(
                radius: 14,
                // Flat, barely-there edge — matches the neutral border now
                // used on every other Home screen card (was a bold amber
                // brand-colored border).
                color: Colors.white,
                borderColor: AppColors.border.withValues(alpha: 0.8),
                borderWidth: 1,
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: _attentionIconBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.notifications_active_outlined, size: 14, color: _attentionText),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$count ${count == 1 ? 'item' : 'items'} need your attention',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _attentionText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('attention-hidden')),
    );
  }
}
