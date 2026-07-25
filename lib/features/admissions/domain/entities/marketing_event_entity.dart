/// Marketing event row — mirrors web `AdmissionsMarketing.tsx`'s hardcoded
/// demo events list inside the "Events Manager" card (no backend model).
/// `id` isn't part of web's demo data (a plain array with no key beyond
/// array index) — added here only so the Flutter list can be mutated
/// (new events created, RSVP counts edited) without relying on array index.
class MarketingEventEntity {
  final String id;
  final String name;
  final String date;
  final String time;
  final int rsvp;
  final int capacity;

  const MarketingEventEntity({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.rsvp,
    required this.capacity,
  });

  MarketingEventEntity copyWith({int? rsvp}) {
    return MarketingEventEntity(
      id: id,
      name: name,
      date: date,
      time: time,
      rsvp: rsvp ?? this.rsvp,
      capacity: capacity,
    );
  }
}
