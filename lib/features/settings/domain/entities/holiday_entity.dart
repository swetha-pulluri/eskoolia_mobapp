/// Settings → Holiday Calendar: one row from the shared `Holiday` model
/// (backend/apps/core/models.py::Holiday) — the same rows Academics >
/// Foundation's own Holiday Calendar screen edits, filtered here by
/// `audience`. Reference: backend/apps/core/serializers.py::HolidaySerializer,
/// frontend/components/settings/HolidaysPanel.tsx (`interface Holiday`).
class HolidayEntity {
  final int id;
  final String name;
  final String date;
  final String? endDate;
  final String holidayType;
  final String audience; // "all" | "staff_only"
  final bool isOptional;

  const HolidayEntity({
    required this.id,
    required this.name,
    required this.date,
    required this.endDate,
    required this.holidayType,
    required this.audience,
    required this.isOptional,
  });

  factory HolidayEntity.fromJson(Map<String, dynamic> json) {
    return HolidayEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      endDate: json['end_date'] as String?,
      holidayType: json['holiday_type'] as String? ?? 'other',
      audience: json['audience'] as String? ?? 'all',
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }
}

/// One `StaffHolidayExclusion` row — a school-wide holiday marked as not
/// applicable to staff. Reference:
/// backend/apps/settings/serializers.py::StaffHolidayExclusionSerializer.
class HolidayExclusionEntity {
  final int id;
  final int holidayId;
  final String holidayName;
  final String holidayDate;

  const HolidayExclusionEntity({
    required this.id,
    required this.holidayId,
    required this.holidayName,
    required this.holidayDate,
  });

  factory HolidayExclusionEntity.fromJson(Map<String, dynamic> json) {
    return HolidayExclusionEntity(
      id: json['id'] as int,
      holidayId: json['holiday'] as int,
      holidayName: json['holiday_name'] as String? ?? '',
      holidayDate: json['holiday_date'] as String? ?? '',
    );
  }
}
