import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/widgets/premium_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_provider.dart';

/// Home screen greeting card — a compact mobile card holding just the
/// greeting, current date, and the Academic Year/School pills. A white
/// card with a subtle purple-tinted border/edge (not a solid colored
/// fill) so it stays visually distinct from the page background without
/// resorting to a bold color wash. The "N items need your attention"
/// callout lives in its own section (see `attention_banner.dart`) below
/// this card, and "Today's Pulse"/Quick Access/Recently Visited/All
/// Modules remain their own sections further down `AdminHomePage` — each
/// concern on the home screen is its own card. Entrance animation
/// (fade/slide) is applied by the caller via `FadeSlideIn`, not this
/// widget itself.
class GreetingSection extends ConsumerWidget {
  /// Both default to Admin's original purple-tinted look — every existing
  /// Admin call site (`dashboard_page.dart`, no args) is unaffected. Teacher
  /// Home passes plain/neutral values instead, to match the plain-white
  /// card style the rest of its sections (Attendance/Today's Schedule/Quick
  /// Access) already use.
  final Color? borderColor;
  final Color? nameColor;

  const GreetingSection({super.key, this.borderColor, this.nameColor});

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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: PremiumCard(
        radius: 20,
        color: Colors.white,
<<<<<<< Updated upstream
        borderColor: borderColor ?? AppColors.brandPurple.withValues(alpha: 0.55),
=======
        // Flat, barely-there edge — matches the Stitch reference's plain
        // white cards (no bold brand-colored border).
        borderColor: AppColors.border.withValues(alpha: 0.8),
        borderWidth: 1,
>>>>>>> Stashed changes
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "— WELCOME BACK" eyebrow, matching the Stitch reference.
            Row(
              children: [
                Container(width: 14, height: 2, color: AppColors.brandPurple),
                const SizedBox(width: 6),
                Text(
                  'WELCOME BACK',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.brandPurple.withValues(alpha: 0.85), letterSpacing: 1.1),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Greeting Row
            Row(
              children: [
                _AnimatedGreetingEmoji(emoji: app_date_utils.DateUtils.getTimeEmoji()),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ink1),
                      children: [
                        TextSpan(
                          text: 'Good ${app_date_utils.DateUtils.getTimeWord()}',
                        ),
                        if (displayName.isNotEmpty)
<<<<<<< Updated upstream
                          TextSpan(text: ', $displayName', style: TextStyle(color: nameColor ?? AppColors.brandPurple)),
=======
                          TextSpan(text: ', $displayName!', style: const TextStyle(color: AppColors.brandPurple)),
>>>>>>> Stashed changes
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
            ),

            const SizedBox(height: 12),

            // Academic Year and School Info pills — real data from
            // /api/v1/core/academic-years/ (isCurrent==true) and the
            // already-fetched /api/v1/auth/me/ response, matching web's
            // `Greeting.tsx`. No hardcoded fallback values: an absent
            // current year or school name renders as "—", not a guess.
            // Stacked label-over-value pill, side by side, matching the
            // Stitch reference (was a single-line "label: value" pill).
            Row(
              children: [
                Expanded(
                  child: academicYearAsync.when(
                    data: (year) => _InfoChip(label: 'Academic Year', value: year?.name ?? '—'),
                    loading: () => const _InfoChip(label: 'Academic Year', value: 'Loading…', isLoading: true),
                    error: (_, _) => const _InfoChip(label: 'Academic Year', value: 'Unavailable', isError: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: authState.when(
                    initial: () => const _InfoChip(label: 'School', value: 'Loading…', isLoading: true),
                    loading: () => const _InfoChip(label: 'School', value: 'Loading…', isLoading: true),
                    authenticated: (user) => _InfoChip(label: 'School', value: user.schoolName ?? '—'),
                    unauthenticated: () => const _InfoChip(label: 'School', value: '—'),
                    error: (_) => const _InfoChip(label: 'School', value: 'Unavailable', isError: true),
                  ),
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

/// Plays a one-shot "pop in with a little settle" on first build — a bouncy
/// scale-up paired with a small rotation that unwinds to 0, so the time-of-day
/// emoji (☀️/🌤️/🌙) feels alive instead of just appearing as static text.
class _AnimatedGreetingEmoji extends StatelessWidget {
  final String emoji;

  const _AnimatedGreetingEmoji({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(emoji),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: (1 - value) * 0.5,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
    // Only the error state keeps its own red text so a failed fetch still
    // stands out.
    final valueColor = isError ? AppColors.error : AppColors.purpleDeep;

    // Capsule pill — small gray label beside the bold value (both
    // vertically centered), not stacked — matching the Stitch reference's
    // Academic Year/School pills exactly.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink3,
                letterSpacing: 0.1,
                fontSize: 11,
                height: 1.15,
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 6),
          if (isLoading) ...[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.purpleDeep),
            ),
            const SizedBox(width: 6),
          ],
          if (isError) ...[
            Icon(Icons.error_outline, size: 12, color: AppColors.error),
            const SizedBox(width: 4),
          ],
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontStyle: (isLoading || isError) ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
