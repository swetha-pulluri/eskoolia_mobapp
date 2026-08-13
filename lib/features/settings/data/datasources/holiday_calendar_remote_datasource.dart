import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/holiday_entity.dart';

/// Reference: backend/apps/core/views.py::HolidayViewSet,
/// backend/apps/settings/views.py (StaffHolidayCalendarView,
/// StaffHolidayExclusionViewSet), frontend/components/settings/HolidaysPanel.tsx.
class HolidayCalendarRemoteDataSource {
  final DioClient _dioClient;

  HolidayCalendarRemoteDataSource(this._dioClient);

  /// List responses may be a bare array or DRF's `{count,results}` shape.
  static List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) return (data['results'] as List?) ?? const [];
    return const [];
  }

  Future<List<HolidayEntity>> getStaffCalendar() async {
    final response = await _dioClient.get(ApiConstants.settingsStaffHolidayCalendar);
    return _asList(response.data).map((e) => HolidayEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<HolidayEntity>> getAllHolidays() async {
    final response = await _dioClient.get(ApiConstants.coreHolidays, queryParameters: {'page_size': 200});
    return _asList(response.data).map((e) => HolidayEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<HolidayExclusionEntity>> getExclusions() async {
    final response = await _dioClient.get(ApiConstants.settingsStaffHolidayExclusions);
    return _asList(response.data).map((e) => HolidayExclusionEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<HolidayEntity> createHoliday(Map<String, dynamic> payload) async {
    final response = await _dioClient.post(ApiConstants.coreHolidays, data: payload);
    return HolidayEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HolidayEntity> updateHoliday(int id, Map<String, dynamic> payload) async {
    final response = await _dioClient.patch('${ApiConstants.coreHolidays}$id/', data: payload);
    return HolidayEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteHoliday(int id) async {
    await _dioClient.delete('${ApiConstants.coreHolidays}$id/');
  }

  Future<void> createExclusion(int holidayId) async {
    await _dioClient.post(ApiConstants.settingsStaffHolidayExclusions, data: {'holiday': holidayId});
  }

  Future<void> deleteExclusion(int exclusionId) async {
    await _dioClient.delete(ApiConstants.settingsStaffHolidayExclusionDetail(exclusionId));
  }
}
