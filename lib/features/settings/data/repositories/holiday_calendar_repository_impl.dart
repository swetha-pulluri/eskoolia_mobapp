import '../../domain/entities/holiday_entity.dart';
import '../../domain/repositories/holiday_calendar_repository.dart';
import '../datasources/holiday_calendar_remote_datasource.dart';

class HolidayCalendarRepositoryImpl implements HolidayCalendarRepository {
  final HolidayCalendarRemoteDataSource _remoteDataSource;

  HolidayCalendarRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<HolidayEntity>> getStaffCalendar() => _remoteDataSource.getStaffCalendar();

  @override
  Future<List<HolidayEntity>> getAllHolidays() => _remoteDataSource.getAllHolidays();

  @override
  Future<List<HolidayExclusionEntity>> getExclusions() => _remoteDataSource.getExclusions();

  @override
  Future<HolidayEntity> createHoliday(Map<String, dynamic> payload) => _remoteDataSource.createHoliday(payload);

  @override
  Future<HolidayEntity> updateHoliday(int id, Map<String, dynamic> payload) =>
      _remoteDataSource.updateHoliday(id, payload);

  @override
  Future<void> deleteHoliday(int id) => _remoteDataSource.deleteHoliday(id);

  @override
  Future<void> createExclusion(int holidayId) => _remoteDataSource.createExclusion(holidayId);

  @override
  Future<void> deleteExclusion(int exclusionId) => _remoteDataSource.deleteExclusion(exclusionId);
}
