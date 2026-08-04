import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_provider.dart';

class GreetingSection extends ConsumerWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authNotifierProvider).whenOrNull(
          authenticated: (user) => user,
        );
    final attentionCount = ref.watch(attentionCountProvider);
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
          
          // Academic Year and School Info Chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                label: 'ACADEMIC YEAR',
                value: AppConstants.defaultAcademicYear,
              ),
              _InfoChip(
                label: 'SCHOOL',
                value: AppConstants.defaultSchoolName,
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

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
