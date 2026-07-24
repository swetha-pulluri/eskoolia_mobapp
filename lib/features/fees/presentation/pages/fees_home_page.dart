import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fees_home_state.dart';
import '../providers/fees_providers.dart';
import '../widgets/fees_audit_trail_card.dart';
import '../widgets/fees_kpi_cards.dart';
import '../widgets/fees_layout.dart';
import '../widgets/fees_live_payment_feed_card.dart';
import '../widgets/fees_module_sub_nav.dart';
import '../widgets/fees_task_queue_card.dart';

/// Fees Home — converted from `frontend/components/fees/FeesPaymentsPanel.tsx`
/// (the real render target of the "Home" tab: `routes.ts` points
/// `/fees` module's Home sub-item at `/fees/payments`, and
/// `app/(dashboard)/fees/payments/page.tsx` renders this panel directly).
///
/// Task Queue and Audit Trail read from a `/fees/home/` endpoint that does
/// not exist on the backend yet (see fees_home_data.dart) — both render
/// empty here exactly as they do in the real, currently-running web app.
class FeesHomePage extends ConsumerWidget {
  const FeesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feesHomeNotifierProvider);
    final notifier = ref.read(feesHomeNotifierProvider.notifier);

    ref.listen<FeesHomeState>(feesHomeNotifierProvider, (previous, next) {
      if (next.toast != null && next.toast != previous?.toast) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.toast!, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(milliseconds: 3500),
          ),
        );
      }
    });

    return FeesLayout(
      activeTab: FeesModuleTab.home,
      child: SafeArea(
        top: false,
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onSimulate: notifier.simulatePayment),
                    const SizedBox(height: 24),
                    FeesKpiCards(summary: state.summary),
                    const SizedBox(height: 24),
                    FeesTaskQueueCard(tasks: state.homeData.tasks, onButtonTap: (_) {}),
                    const SizedBox(height: 16),
                    FeesLivePaymentFeedCard(
                      feed: state.feed,
                      autoRefresh: state.autoRefresh,
                      onToggleAutoRefresh: notifier.toggleAutoRefresh,
                    ),
                    const SizedBox(height: 24),
                    FeesAuditTrailCard(auditTrail: state.homeData.auditTrail),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSimulate;
  const _Header({required this.onSimulate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
              onTap: onSimulate,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    'Simulate Incoming Payment',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
