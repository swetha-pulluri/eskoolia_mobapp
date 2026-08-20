import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../fees/domain/models/fees_home_data.dart';
import '../../../fees/presentation/providers/fees_providers.dart';
import '../../../fees/presentation/widgets/fees_audit_trail_card.dart';
import '../../../fees/presentation/widgets/fees_kpi_cards.dart';
import '../../../fees/presentation/widgets/fees_layout.dart';
import '../../../fees/presentation/widgets/fees_live_payment_feed_card.dart';
import '../../../fees/presentation/widgets/fees_task_queue_card.dart';

/// The real, live backend (`FeesHomeAPIView._build_tasks`/`_build_audit_trail`
/// in `backend/apps/fees/views.py`) returns CSS colour *names* for
/// `tasks[].color`/`audit_trail[].bg` — "red"/"amber" for tasks, "purple"/
/// "green"/"gray" for audit events — not hex codes. (The Flutter model's own
/// doc comment claiming this endpoint "does not exist yet" is stale — it
/// does, and returns real data.) `FeesTaskQueueCard`/`FeesAuditTrailCard`
/// (shared, unmodified Admin widgets) only parse `#RRGGBB` hex strings via
/// their own `_hex()` helper, so a name like "red" throws
/// `FormatException: red` — a real, confirmed crash Admin's own Fees Home
/// page would also hit on this exact data. Since those shared widget files
/// aren't modified for this task, the fix lives here instead: resolve every
/// known colour name to its hex equivalent before the data ever reaches
/// them, with a safe fallback for anything unrecognized.
const _cssColorToHex = {
  'red': '#EF4444',
  'amber': '#F59E0B',
  'purple': '#8B5CF6',
  'green': '#16A34A',
  'gray': '#9CA3AF',
  'grey': '#9CA3AF',
};

String _resolveHex(String value) {
  if (value.startsWith('#')) return value;
  return _cssColorToHex[value.toLowerCase()] ?? '#6D4AFF';
}

List<FeesTask> _sanitizeTasks(List<FeesTask> tasks) => [
      for (final t in tasks) FeesTask(id: t.id, color: _resolveHex(t.color), title: t.title, desc: t.desc, buttons: t.buttons),
    ];

List<FeesAuditItem> _sanitizeAuditTrail(List<FeesAuditItem> items) => [
      for (final a in items) FeesAuditItem(id: a.id, initials: a.initials, event: a.event, desc: a.desc, date: a.date, bg: _resolveHex(a.bg)),
    ];

/// Teacher Portal — Fees Home.
///
/// No teacher-scoped Fees page/backend exists anywhere in the web app or
/// backend (see the "Teacher Portal — Fees" comment block in
/// `app_router.dart`) — apps.fees has no per-teacher data scoping at all.
/// This page reuses the exact same shared widgets and provider
/// (`feesHomeNotifierProvider`, `FeesKpiCards`, `FeesTaskQueueCard`,
/// `FeesLivePaymentFeedCard`, `FeesAuditTrailCard`) as Admin's
/// `FeesHomePage` — with one deliberate exception: the header button.
///
/// Admin's own `fees_home_page.dart` (`_Header`) shows "Simulate Incoming
/// Payment", which does not exist anywhere in the real web source
/// (`frontend/components/fees/FeesPaymentsPanel.tsx`) — that component has
/// exactly one header button, "Refresh Payment Feed", which re-fetches the
/// live payment list and shows a toast ("Payment feed refreshed from live
/// records."). That's a pre-existing, disclosed deviation in the Admin
/// Flutter port, out of scope to fix here (Admin files are not modified for
/// this task) — but it must not be copied into the Teacher experience,
/// since "Refresh Payment Feed" is explicitly what was asked for and shown
/// in the reference screenshot. This header reproduces the REAL web button
/// instead, using `ref.invalidate(feesHomeNotifierProvider)` — the same
/// provider-refresh pattern used everywhere else in this app (e.g.
/// Timetable's `ref.invalidate(teacherTimetableProvider)`) — which re-runs
/// the notifier's constructor and therefore re-fetches the summary, home
/// dashboard, students, and payment feed in one action.
class TeacherFeesHomePage extends ConsumerWidget {
  const TeacherFeesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feesHomeNotifierProvider);

    return FeesLayout(
      child: SafeArea(
        top: false,
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      // `ref.invalidate` tears down and rebuilds this whole
                      // subtree — including the very InkWell just tapped —
                      // to fetch fresh data. Doing that SYNCHRONOUSLY inside
                      // onTap removes/replaces the pointer-gesture-tracked
                      // widget while its tap gesture is still resolving,
                      // which is exactly what trips Flutter's
                      // `mouse_tracker.dart` assertion. Deferring to a
                      // microtask lets the current gesture finish first.
                      onRefresh: () {
                        final messenger = ScaffoldMessenger.of(context);
                        Future.microtask(() {
                          ref.invalidate(feesHomeNotifierProvider);
                          if (!context.mounted) return;
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment feed refreshed from live records.',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4),
                              ),
                              backgroundColor: Color(0xFF1E293B),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              duration: Duration(milliseconds: 3500),
                            ),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    FeesKpiCards(summary: state.summary),
                    const SizedBox(height: 24),
                    FeesTaskQueueCard(tasks: _sanitizeTasks(state.homeData.tasks), onButtonTap: (_) {}),
                    const SizedBox(height: 16),
                    FeesLivePaymentFeedCard(
                      feed: state.feed,
                      autoRefresh: state.autoRefresh,
                      onToggleAutoRefresh: ref.read(feesHomeNotifierProvider.notifier).toggleAutoRefresh,
                    ),
                    const SizedBox(height: 24),
                    FeesAuditTrailCard(auditTrail: _sanitizeAuditTrail(state.homeData.auditTrail)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // Its own card — same white/gray-bordered style already used by every
    // other section on this page (KPI cards, Task Queue, Live Payment Feed,
    // Audit Trail) and by Admin's own equivalent header — instead of
    // floating text directly on the page background.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECF2)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FEES COMMAND CENTER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Color(0xFF6D4AFF)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Home',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF0F1222), height: 1.1),
              ),
              const SizedBox(height: 8),
              const Text(
                'Daily fee operations, live payment updates, and priority queue for the finance desk.',
                style: TextStyle(fontSize: 14, color: Color(0xFF9197AE), height: 1.5),
              ),
            ],
          ),
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x476D4AFF), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Material(
              color: const Color(0xFF6D4AFF),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onRefresh,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      'Refresh Payment Feed',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
