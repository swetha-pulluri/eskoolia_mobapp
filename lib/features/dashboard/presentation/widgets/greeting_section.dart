import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/widgets/premium_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_provider.dart';

/// Home screen greeting card — a compact mobile card holding just the
/// greeting, current date, and the Academic Year/School pills, on a solid
/// deep-purple brand background (white text) so it reads as a bold "hero"
/// card, visually distinct from the plain-white cards below it. The "N items need your
/// attention" callout lives in its own section (see `attention_banner.dart`)
/// below this card, and "Today's Pulse"/Quick Access/Recently Visited/All
/// Modules remain their own sections further down `AdminHomePage` — each
/// concern on the home screen is its own card. Entrance animation
/// (fade/slide) is applied by the caller via `FadeSlideIn`, not this
/// widget itself.
class GreetingSection extends ConsumerWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.whenOrNull(authenticated: (user) => user);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);
    // Matches web's `Greeting.tsx` name derivation exactly: fall back to
    // the username when first/last name are both blank, and only render
    // the ", <name>" suffix at all when there's a non-empty name to show.
    final displayName = currentUser == null
        ? ''
        : (currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.username);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: PremiumCard(
        radius: 16,
        // Solid deep-purple brand color (not a soft tint) with white text,
        // matching the reference design — reads as a clear, bold "hero"
        // card rather than a pastel-tinted one.
        color: AppColors.purpleDeep,
        borderColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Row
            Row(
              children: [
                Text(
                  app_date_utils.DateUtils.getTimeEmoji(),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'Good ${app_date_utils.DateUtils.getTimeWord()}',
                        ),
                        if (displayName.isNotEmpty) TextSpan(text: ', $displayName'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Current date
            Text(
              app_date_utils.DateUtils.getFormattedDate(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
            ),

            const SizedBox(height: 10),

            // Academic Year and School Info Chips — real data from
            // /api/v1/core/academic-years/ (isCurrent==true) and the
            // already-fetched /api/v1/auth/me/ response, matching web's
            // `Greeting.tsx`. No hardcoded fallback values: an absent
            // current year or school name renders as "—", not a guess.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                academicYearAsync.when(
                  data: (year) => _InfoChip(label: 'Academic Year', value: year?.name ?? '—'),
                  loading: () => const _InfoChip(label: 'Academic Year', value: 'Loading…', isLoading: true),
                  error: (_, _) => const _InfoChip(label: 'Academic Year', value: 'Unavailable', isError: true),
                ),
                authState.when(
                  initial: () => const _InfoChip(label: 'School', value: 'Loading…', isLoading: true),
                  loading: () => const _InfoChip(label: 'School', value: 'Loading…', isLoading: true),
                  authenticated: (user) => _InfoChip(label: 'School', value: user.schoolName ?? '—'),
                  unauthenticated: () => const _InfoChip(label: 'School', value: '—'),
                  error: (_) => const _InfoChip(label: 'School', value: 'Unavailable', isError: true),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final bool isError;

  const _InfoChip({
    required this.label,
    required this.value,
    this.isLoading = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    // White throughout (label, value, spinner) to read cleanly against the
    // card's solid deep-purple background — only the error state keeps its
    // own red icon/text so a failed fetch still stands out.
    final valueColor = isError ? AppColors.error : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading) ...[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
            ),
            const SizedBox(width: 6),
          ],
          if (isError) ...[
            Icon(Icons.error_outline, size: 12, color: AppColors.error),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontStyle: (isLoading || isError) ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
