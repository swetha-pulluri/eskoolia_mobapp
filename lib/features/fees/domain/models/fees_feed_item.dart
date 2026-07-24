import 'package:flutter/material.dart';

/// Live Payment Feed row — mirrors `FeedItem` in FeesPaymentsPanel.tsx.
/// Populated either from a real fetched [FeesPayment] (status forced to
/// "Posted", matching the web component's `fetchFeed` mapping) or from the
/// client-only "Simulate Incoming Payment" pool.
class FeesFeedItem {
  final String id;
  final String initials;
  final String name;
  final String amount; // already formatted, e.g. "12,345"
  final String method;
  final String time;
  final String status; // 'Verified' | 'Posted'
  final Color bg;
  final bool isNew;

  const FeesFeedItem({
    required this.id,
    required this.initials,
    required this.name,
    required this.amount,
    required this.method,
    required this.time,
    required this.status,
    required this.bg,
    this.isNew = false,
  });

  FeesFeedItem copyWith({bool? isNew}) {
    return FeesFeedItem(
      id: id,
      initials: initials,
      name: name,
      amount: amount,
      method: method,
      time: time,
      status: status,
      bg: bg,
      isNew: isNew ?? this.isNew,
    );
  }
}
