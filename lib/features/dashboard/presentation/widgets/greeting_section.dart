import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/widgets/premium_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_provider.dart';

/// Home screen greeting card — a compact mobile card holding just the
/// greeting, current date, and the Academic Year/School pills. A plain
/// white card with a neutral border (not a solid colored fill or a
/// brand-purple edge) so it stays visually distinct from the page
/// background without resorting to a bold color wash. The "N items need
/// your attention" callout lives in its own section (see
/// `attention_banner.dart`) below this card, and "Today's Pulse"/Quick
/// Access/Recently Visited/All Modules remain their own sections further
/// down `AdminHomePage` — each concern on the home screen is its own card.
/// Entrance animation (fade/slide) is applied by the caller via
/// `FadeSlideIn`, not this widget itself.
class GreetingSection extends ConsumerWidget {
  /// Both default to a plain/neutral look; every existing call site
  /// (`dashboard_page.dart`, no args) is unaffected. [nameColor] still
  /// defaults to brand purple to highlight the user's name in the
  /// greeting text; [borderColor] defaults to a neutral border shared with
  /// the rest of the home screen's cards.
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
        // Flat, barely-there edge — matches the Stitch reference's plain
        // white cards (no bold brand-colored border). Teacher Home overrides
        // via `borderColor` to its own equally-plain card border.
        borderColor: borderColor ?? AppColors.border.withValues(alpha: 0.8),
        borderWidth: 1,

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Row — `crossAxisAlignment.start` (not the Row
            // default of center) so the emoji stays pinned to the first
            // line when a long name wraps the text to a second line
            // instead of drifting to the vertical middle of both lines.
            // No `maxLines`/`overflow` on the text itself — a long real
            // name (e.g. "Sowmya Reddy") was getting cut off with an
            // ellipsis on narrower Android phones; wrapping to a second
            // line instead always shows the full name.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnimatedGreetingEmoji(emoji: app_date_utils.DateUtils.getTimeEmoji()),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ink1),
                      children: [
                        TextSpan(
                          text: 'Good ${app_date_utils.DateUtils.getTimeWord()}',
                        ),
                        if (displayName.isNotEmpty)
                          TextSpan(text: ', $displayName', style: TextStyle(color: nameColor ?? AppColors.brandPurple)),
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
      // `fontFamilyFallback` forces these specific platform color-emoji
      // fonts ahead of whatever custom font this `Text` would otherwise
      // inherit from the ambient theme — without it, ☀️/🌤️ were rendering
      // as plain monochrome glyphs instead of full-color emoji, since the
      // inherited font is checked for glyph coverage before any fallback.
      child: Text(
        emoji,
        style: const TextStyle(
          fontSize: 20,
          fontFamilyFallback: ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji'],
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
    // Only the error state keeps its own red text so a failed fetch still
    // stands out.
    final valueColor = isError ? AppColors.error : AppColors.purpleDeep;

    // Label stacked above the value (not side by side) — a long real value
    // (e.g. a school name like "Sunrise Public School") was getting cut off
    // with an ellipsis when it had to share a row with the label, since
    // splitting the pill's width between the two left too little room for
    // the value. Stacking gives the value the pill's full width to wrap
    // into instead, so it always shows completely on any phone width.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ink3,
              letterSpacing: 0.1,
              fontSize: 11,
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
        ],
      ),
    );
  }
}
