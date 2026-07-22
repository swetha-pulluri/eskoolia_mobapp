/// Marketing campaign — mirrors web `AdmissionsMarketing.tsx`'s local
/// `Campaign` type. On web this is 100% client-side mock state (no backend
/// model/API — verified by reading the full component source), so this
/// entity intentionally has no `fromJson`/`toJson`.
class CampaignEntity {
  final String id;
  final String name;
  /// "draft" | "scheduled" | "active" | "sent"
  final String status;
  final String channel;
  final String audience;
  final int sentCount;
  final int? deliveredPct;
  final int? replies;
  final String? scheduledFor;
  final String? sentAt;

  const CampaignEntity({
    required this.id,
    required this.name,
    required this.status,
    required this.channel,
    required this.audience,
    this.sentCount = 0,
    this.deliveredPct,
    this.replies,
    this.scheduledFor,
    this.sentAt,
  });

  CampaignEntity copyWith({String? name, String? status, String? scheduledFor}) {
    return CampaignEntity(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      channel: channel,
      audience: audience,
      sentCount: sentCount,
      deliveredPct: deliveredPct,
      replies: replies,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt,
    );
  }
}
