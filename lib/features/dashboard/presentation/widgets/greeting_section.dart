import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_provider.dart';

class GreetingSection extends ConsumerWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.whenOrNull(authenticated: (user) => user);
    final attentionCount = ref.watch(attentionCountProvider);
    final academicYearAsync = ref.watch(currentAcademicYearProvider);
    // Matches web's `Greeting.tsx` name derivation exactly: fall back to
    // the username when first/last name are both blank, and only render
    // the ", <name>" suffix at all when there's a non-empty name to show.
    final displayName = currentUser == null
        ? ''
        : (currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.username);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Row
          Row(
            children: [
              Text(
                app_date_utils.DateUtils.getTimeEmoji(),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineMedium,
                    children: [
                      TextSpan(
                        text: 'Good ${app_date_utils.DateUtils.getTimeWord()}',
                      ),
                      if (displayName.isNotEmpty) ...[
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: displayName,
                          style: const TextStyle(
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Date and Attention Count
          Row(
            children: [
              Expanded(
                child: Text(
                  app_date_utils.DateUtils.getFormattedDate(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          
          if (attentionCount.hasValue && attentionCount.value! > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${attentionCount.value} ${attentionCount.value == 1 ? 'item' : 'items'} need your attention',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Academic Year and School Info Chips — real data from
          // /api/v1/core/academic-years/ (isCurrent==true) and the
          // already-fetched /api/v1/auth/me/ response, matching web's
          // `Greeting.tsx`. No hardcoded fallback values: an absent
          // current year or school name renders as "—", not a guess.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              academicYearAsync.when(
                data: (year) => _InfoChip(label: 'ACADEMIC YEAR', value: year?.name ?? '—'),
                loading: () => const _InfoChip(label: 'ACADEMIC YEAR', value: 'Loading…', isLoading: true),
                error: (_, _) => const _InfoChip(label: 'ACADEMIC YEAR', value: 'Unavailable', isError: true),
              ),
              authState.when(
                initial: () => const _InfoChip(label: 'SCHOOL', value: 'Loading…', isLoading: true),
                loading: () => const _InfoChip(label: 'SCHOOL', value: 'Loading…', isLoading: true),
                authenticated: (user) => _InfoChip(label: 'SCHOOL', value: user.schoolName ?? '—'),
                unauthenticated: () => const _InfoChip(label: 'SCHOOL', value: '—'),
                error: (_) => const _InfoChip(label: 'SCHOOL', value: 'Unavailable', isError: true),
              ),
            ],
          ),
        ],
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
    final valueColor = isError ? AppColors.error : (isLoading ? AppColors.ink3 : AppColors.ink1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink1.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ink3,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.ink3),
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
                  fontWeight: FontWeight.w600,
                  fontStyle: (isLoading || isError) ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
