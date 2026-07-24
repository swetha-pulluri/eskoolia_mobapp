import 'package:flutter/material.dart';
import '../../domain/models/fees_feed_item.dart';

/// Mirrors FeesPaymentsPanel.tsx's "Live Payment Feed" card: a scrollable
/// (max-height 380) list of payments with an "Auto-refresh" toggle, avatar
/// initials, amount/method/time line, and a Verified/Posted status tag. A
/// newly-simulated item briefly highlights green (`isNew`), fading back to
/// white — CSS `background 0.5s ease` reproduced with an `AnimatedContainer`.
class FeesLivePaymentFeedCard extends StatelessWidget {
  final List<FeesFeedItem> feed;
  final bool autoRefresh;
  final VoidCallback onToggleAutoRefresh;

  const FeesLivePaymentFeedCard({
    super.key,
    required this.feed,
    required this.autoRefresh,
    required this.onToggleAutoRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Live Payment Feed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F1222))),
                    SizedBox(height: 4),
                    Text(
                      'Simulated webhook updates from app, bank transfer, and wallet payments.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9197AE), height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _autoRefreshButton(),
            ],
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: SingleChildScrollView(
              child: Column(
                children: [for (var i = 0; i < feed.length; i++) ...[if (i > 0) const SizedBox(height: 10), _feedRow(feed[i])]],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoRefreshButton() {
    return InkWell(
      onTap: onToggleAutoRefresh,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: autoRefresh ? const Color(0xFFDCFCE7) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: autoRefresh ? const Color(0xFF86EFAC) : const Color(0xFFECECF2)),
        ),
        child: Text(
          autoRefresh ? '● Auto-\nrefresh' : 'Auto-\nrefresh',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: autoRefresh ? const Color(0xFF15803D) : const Color(0xFF5A607A),
          ),
        ),
      ),
    );
  }

  Widget _feedRow(FeesFeedItem item) {
    return AnimatedContainer(
      key: ValueKey(item.id),
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: item.isNew ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECECF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: item.bg, shape: BoxShape.circle),
            child: Text(item.initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F1222)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Rs. ${item.amount} via ${item.method} · ${item.time}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF9197AE)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            item.status,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: item.status == 'Verified' ? const Color(0xFF16A34A) : const Color(0xFF9197AE),
            ),
          ),
        ],
      ),
    );
  }
}
