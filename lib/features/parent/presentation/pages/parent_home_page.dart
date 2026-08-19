import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/widgets/premium_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../widgets_panel/presentation/providers/widget_prefs_provider.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';
import '../widgets/parent_attendance_widget.dart';
import '../widgets/parent_fees_widget.dart';
import '../widgets/parent_module_grid.dart';
import '../widgets/parent_notices_widget.dart';
import '../widgets/parent_quick_access_grid.dart';
import '../widgets/parent_results_widget.dart';

/// Parent Home Screen — the Parent Portal's landing page after login
/// (`/parent/home`, equivalent to web's `(parent-portal)/parent/home`).
/// Single-column mobile-first composition — same simplification
/// `TeacherHomePage`/`AdminHomePage` already make over web's 3-column
/// desktop grid (web's left/right rail widgets are stacked below the
/// module grids here instead of running alongside them). "Recently
/// Visited" is omitted, matching `TeacherHomePage`'s own precedent for
/// portal home screens (no localStorage-recents infrastructure ported).
class ParentHomePage extends ConsumerWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(widgetPrefsProvider);
    final notifier = ref.read(widgetPrefsProvider.notifier);
    bool isEnabled(String id) => notifier.isEnabled(id);

    // Mirrors web's `home/page.tsx` (via `ParentChildProvider`), which gates
    // the whole page on `fetchParentMe()` succeeding.
    final meAsync = ref.watch(parentMeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentMeProvider);
          ref.invalidate(childDetailProvider);
          ref.invalidate(childFeesProvider);
          ref.invalidate(parentNoticesProvider);
        },
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PortalLoadError(error: error, onRetry: () => ref.invalidate(parentMeProvider)),
          data: (me) => _ParentHomeContent(me: me, isEnabled: isEnabled),
        ),
      ),
    );
  }
}

class _PortalLoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _PortalLoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 32, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text('Could not load your portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                  const SizedBox(height: 6),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentHomeContent extends ConsumerWidget {
  final ParentMeEntity me;
  final bool Function(String id) isEnabled;
  const _ParentHomeContent({required this.me, required this.isEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedChildProvider);
    final childDetailAsync = ref.watch(childDetailProvider);
    final childFeesAsync = ref.watch(childFeesProvider);
    final noticesAsync = ref.watch(parentNoticesProvider);

    final childName = selected?.name.split(' ').first;
    final childDetail = childDetailAsync.valueOrNull;
    final childDetailLoading = childDetailAsync.isLoading;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ParentGreetingCard(me: me, selected: selected),
          const ParentQuickAccessGrid(),
          const ParentModuleGrid(),
          const SizedBox(height: 4),
          if (isEnabled('parent-attendance')) ParentAttendanceWidget(childName: childName, detail: childDetail, loading: childDetailLoading),
          if (isEnabled('parent-results')) ParentResultsWidget(childName: childName, detail: childDetail, loading: childDetailLoading),
          if (isEnabled('parent-notices')) ParentNoticesWidget(notices: noticesAsync.valueOrNull ?? const [], loading: noticesAsync.isLoading),
          if (isEnabled('parent-fees')) ParentFeesWidget(fees: childFeesAsync.valueOrNull, loading: childFeesAsync.isLoading),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Greeting card — mirrors web's `ParentCenter` header exactly: "Good
/// {time}, {firstName}'s family", today's date + children-enrolled count,
/// and Academic Year/School/Child meta chips.
class _ParentGreetingCard extends ConsumerWidget {
  final ParentMeEntity me;
  final ChildSummaryEntity? selected;
  const _ParentGreetingCard({required this.me, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicYearAsync = ref.watch(currentAcademicYearProvider);
    final authState = ref.watch(authNotifierProvider);
    final schoolName = authState.maybeWhen(authenticated: (u) => u.schoolName, orElse: () => null);

    final firstName = me.name.isNotEmpty ? me.name.split(' ').first : '…';
    final childLabel = selected == null
        ? null
        : [
            selected!.name,
            selected!.classSectionLabel,
            if ((selected!.rollNo ?? '').isNotEmpty) 'Roll ${selected!.rollNo}',
          ].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: PremiumCard(
          radius: 24,
          color: Colors.white,
          borderWidth: 0,
          child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                maxLines: 2,
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ink1),
                  children: [
                    TextSpan(text: '${app_date_utils.DateUtils.getTimeEmoji()} Good ${app_date_utils.DateUtils.getTimeWord()}, '),
                    TextSpan(text: "$firstName's family", style: const TextStyle(color: AppColors.brandPurple, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${app_date_utils.DateUtils.getFormattedDate()} · ${me.childrenCount} ${me.childrenCount == 1 ? 'child' : 'children'} enrolled',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  academicYearAsync.when(
                    data: (year) => _InfoChip(label: 'Academic Year', value: year?.name ?? '—'),
                    loading: () => const _InfoChip(label: 'Academic Year', value: 'Loading…', isLoading: true),
                    error: (_, _) => const _InfoChip(label: 'Academic Year', value: 'Unavailable', isError: true),
                  ),
                  _InfoChip(label: 'School', value: schoolName ?? '—'),
                ],
              ),
              // Child info shown on its own full-width line (not a capsule
              // pill like Academic Year/School) so the full name + class +
              // roll number is always visible, never clipped by a fixed
              // pill width/ellipsis.
              if (childLabel != null) ...[
                const SizedBox(height: 8),
                _ChildInfoLine(value: childLabel),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// Full-width "Child" info line — icon + label + the child's full
/// name/class-section/roll value, wrapping across as many lines as needed
/// so nothing is ever clipped (unlike the fixed-width Academic Year/School
/// pills above it, which are always short single-word values).
class _ChildInfoLine extends StatelessWidget {
  final String value;
  const _ChildInfoLine({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_outline, size: 14, color: AppColors.purpleDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.purpleDeep, fontWeight: FontWeight.w700),
            ),
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

  const _InfoChip({required this.label, required this.value, this.isLoading = false, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final valueColor = isError ? AppColors.error : AppColors.purpleDeep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.ink3, letterSpacing: 0.6)),
          const SizedBox(width: 8),
          if (isLoading) ...[
            const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.purpleDeep)),
            const SizedBox(width: 6),
          ],
          if (isError) ...[
            Icon(Icons.error_outline, size: 12, color: AppColors.error),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                    fontStyle: (isLoading || isError) ? FontStyle.italic : FontStyle.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
