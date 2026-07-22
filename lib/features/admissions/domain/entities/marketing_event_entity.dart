/// Marketing event row — mirrors web `AdmissionsMarketing.tsx`'s hardcoded
/// demo events list inside the "Events Manager" card (no backend model).
class MarketingEventEntity {
  final String name;
  final String date;
  final String time;
  final int rsvp;
  final int capacity;

  const MarketingEventEntity({
    required this.name,
    required this.date,
    required this.time,
    required this.rsvp,
    required this.capacity,
  });
}
