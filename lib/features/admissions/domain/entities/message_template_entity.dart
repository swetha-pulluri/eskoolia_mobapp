/// Marketing message template — mirrors web `AdmissionsMarketing.tsx`'s
/// local `Template` type (a hardcoded `TEMPLATES` array on web, not an API
/// model — no `fromJson`/`toJson` by design).
class MessageTemplateEntity {
  final String id;
  final String name;
  final String category;
  /// "whatsapp" | "email" | "sms"
  final String channel;
  final String useCase;
  final String body;
  final String? subject;
  final List<String> variables;

  const MessageTemplateEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.channel,
    required this.useCase,
    required this.body,
    this.subject,
    this.variables = const [],
  });
}
