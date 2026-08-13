/// A single "Week Ahead" planner entry — local-only, matching web's own
/// `WeekAhead.tsx` (its calendar-overlay backend calls
/// `/api/calendar/week-ahead/`/`/api/exams/readiness/` don't exist
/// server-side even on web; the widget is genuinely just a
/// localStorage-backed day planner there). Persisted here via
/// `SharedPrefs`, not a fabricated backend integration.
class WeekPlannerEntry {
  final String id;
  final String date; // 'yyyy-MM-dd'
  final String text;

  const WeekPlannerEntry({required this.id, required this.date, required this.text});

  factory WeekPlannerEntry.fromJson(Map<String, dynamic> json) => WeekPlannerEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        text: json['text'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'date': date, 'text': text};
}
