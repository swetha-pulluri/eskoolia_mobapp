import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/attendance_pulse_card.dart';
import '../widgets/attention_banner.dart';
import '../widgets/fees_today_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/manage_pins_modal.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/recents_row.dart';
import '../widgets/section_label.dart';
import '../widgets/module_grid.dart';

// Staggered entrance timing for each Home screen section — small,
// incrementing delays so cards reveal in a gentle sequence top-to-bottom
// instead of all popping in at once.
const _dGreeting = Duration.zero;
const _dAttention = Duration(milliseconds: 60);
const _dPulse = Duration(milliseconds: 110);
const _dQuickAccess = Duration(milliseconds: 170);
const _dRecents = Duration(milliseconds: 220);
const _dAllModules = Duration(milliseconds: 270);

/// Admin Home Screen
/// This is the main landing page after login, equivalent to web frontend's /home route.
/// Displays: Greeting, Quick Access (pinned modules), Recently Visited, All Modules.
/// NOT the Dashboard module - that's a separate KPI page (/dashboard) not yet implemented.
///
/// This page used to render its own inline app-bar (logo, module strip,
/// notification/settings icons) — that was a one-off duplicate of the app's
/// actual global header, which is now provided once for every route by
/// `GlobalAppShell` (see `main.dart`), so it's been removed here.
class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.whenOrNull(authenticated: (user) => user);
    // "Today's Pulse" (attendance) and "Today's Fees" are restricted to the
    // admin portal on web too (`frontend/lib/widgetStore.ts`'s
    // `roles: ['admin']` on both widgets) — a teacher/parent/student portal
    // account never sees them there either.
    final showPulseWidgets = currentUser?.portalType == 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          ref.invalidate(attentionCountProvider);
          ref.invalidate(recentModulesProvider);
          ref.invalidate(attendancePulseProvider);
          ref.invalidate(feesTodayProvider);
          await ref.read(pinsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              const FadeSlideIn(delay: _dGreeting, child: GreetingSection()),

              // "N items need your attention" — its own section/card
              // below the greeting card.
              const FadeSlideIn(delay: _dAttention, child: AttentionBanner()),

              // Attendance, then Fees below it — each its own full-width
              // horizontal card. On web these live in a left rail hidden
              // below 1024px viewport width, so there's no existing mobile
              // layout to copy; placed here (above Quick Access) as the
              // most natural mobile equivalent, same cards/data/behavior.
              if (showPulseWidgets) ...[
                FadeSlideIn(
                  delay: _dPulse,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(title: "Today's Pulse"),
                      AttendancePulseCard(),
                      SizedBox(height: 8),
                      FeesTodayCard(),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ] else
                const SizedBox(height: 6),

              // Quick Access (Pinned Modules)
              FadeSlideIn(
                delay: _dQuickAccess,
                child: QuickAccessGrid(
                  onManagePins: () => showManagePinsModal(context),
                ),
              ),

              const SizedBox(height: 6),

              // Recently Visited
              const FadeSlideIn(delay: _dRecents, child: RecentsRow()),

              const SizedBox(height: 6),

              // All Modules
              const FadeSlideIn(delay: _dAllModules, child: ModuleGrid()),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
