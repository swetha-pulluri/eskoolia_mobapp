/// Mirrors frontend lib/aiBotIntent.ts's `Intent` union type exactly.
sealed class AiIntent {
  const AiIntent();
}

class NavigateIntent extends AiIntent {
  final String path;
  final String label;
  const NavigateIntent({required this.path, required this.label});
}

class PhoneLookupIntent extends AiIntent {
  final String phone;
  const PhoneLookupIntent(this.phone);
}

class ReportAbsenceIntent extends AiIntent {
  final String query;
  const ReportAbsenceIntent(this.query);
}

class ReportBusIntent extends AiIntent {
  final String query;
  const ReportBusIntent(this.query);
}

class ReportLunchIntent extends AiIntent {
  final String query;
  const ReportLunchIntent(this.query);
}

class ReportEmergencyIntent extends AiIntent {
  final String query;
  const ReportEmergencyIntent(this.query);
}

class StudentLookupIntent extends AiIntent {
  final String query;
  const StudentLookupIntent(this.query);
}

class EnquiryLookupIntent extends AiIntent {
  final String query;
  const EnquiryLookupIntent(this.query);
}

class ParentQaIntent extends AiIntent {
  final String topic;
  final String raw;
  const ParentQaIntent({required this.topic, required this.raw});
}

class PlannerTaskIntent extends AiIntent {
  final String day;
  final String time;
  final String title;
  final String raw;
  const PlannerTaskIntent({required this.day, required this.time, required this.title, required this.raw});
}

class ComposeMessageIntent extends AiIntent {
  final String topic;
  final String raw;
  const ComposeMessageIntent({required this.topic, required this.raw});
}

class FuzzyPagesIntent extends AiIntent {
  final String query;
  const FuzzyPagesIntent(this.query);
}
