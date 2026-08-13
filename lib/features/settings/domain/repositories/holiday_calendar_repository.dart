import '../entities/holiday_entity.dart';

/// Settings → Holiday Calendar — backed by the shared `/api/v1/core/holidays/`
/// endpoint plus the Settings-only exclusion and aggregation sub-resources.
abstract class HolidayCalendarRepository {
  Future<List<HolidayEntity>> getStaffCalendar();

  Future<List<HolidayEntity>> getAllHolidays();

  Future<List<HolidayExclusionEntity>> getExclusions();

  Future<HolidayEntity> createHoliday(Map<String, dynamic> payload);

  Future<HolidayEntity> updateHoliday(int id, Map<String, dynamic> payload);

  Future<void> deleteHoliday(int id);

  Future<void> createExclusion(int holidayId);

  Future<void> deleteExclusion(int exclusionId);
}
