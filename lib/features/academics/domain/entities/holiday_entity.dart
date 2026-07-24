/// Holiday — Source: components/academics/foundation/panes/HolidayCalendarCard.tsx.
/// Backend: apps/core — HolidayViewSet / HolidaySerializer,
/// GET/POST/PATCH/DELETE /api/v1/core/holidays/, plus the custom
/// `copy-from-year/` action.
class Holiday {
  final int id;
  final int? academicYearId;
  final String name;
  final String date;
  final String? endDate;
  final String holidayType; // public | national | religious | school | other
  final String description;
  final bool activeStatus;

  const Holiday({
    required this.id,
    this.academicYearId,
    required this.name,
    required this.date,
    this.endDate,
    required this.holidayType,
    this.description = '',
    this.activeStatus = true,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] as int,
      academicYearId: json['academic_year'] as int?,
      name: (json['name'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      endDate: json['end_date'] as String?,
      holidayType: (json['holiday_type'] as String?) ?? 'public',
      description: (json['description'] as String?) ?? '',
      activeStatus: json['active_status'] as bool? ?? true,
    );
  }
}

/// Mirrors HolidayCalendarCard.tsx's `TYPE_OPTIONS`/`TYPE_BADGE`.
const List<(String value, String label)> holidayTypeOptions = [
  ('public', 'Public Holiday'),
  ('national', 'National'),
  ('religious', 'Religious / Festival'),
  ('school', 'School Event'),
  ('other', 'Other'),
];
