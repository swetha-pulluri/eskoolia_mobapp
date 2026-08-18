import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/attendance_calendar_entity.dart';
import '../../domain/entities/child_detail_entity.dart';
import '../../domain/entities/child_fees_entity.dart';
import '../../domain/entities/notice_item_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../../domain/repositories/parent_api_exception.dart';

/// Calls the real, implemented `apps.parent_portal` endpoints.
class ParentRemoteDataSource {
  final DioClient _dioClient;

  ParentRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw ParentApiException(rawMessage);
      if (rawMessage != null) throw ParentApiException(rawMessage.toString());
    }
    throw ParentApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  Future<ParentMeEntity> getMe() async {
    try {
      final response = await _dioClient.get(ApiConstants.parentMe);
      return ParentMeEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get parent me error', e);
      _throwApiException(e);
    }
  }

  Future<ChildDetailEntity> getChildDetail(int childId) async {
    try {
      final response = await _dioClient.get(ApiConstants.parentChildDetail(childId));
      return ChildDetailEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get child detail error', e);
      _throwApiException(e);
    }
  }

  Future<ChildFeesEntity> getChildFees(int childId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.parentFees,
        queryParameters: {'child_id': childId},
      );
      return ChildFeesEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get child fees error', e);
      _throwApiException(e);
    }
  }

  Future<AttendanceCalendarEntity> getAttendanceCalendar(int childId, String month) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.parentAttendance,
        queryParameters: {'child_id': childId, 'month': month},
      );
      return AttendanceCalendarEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get attendance calendar error', e);
      _throwApiException(e);
    }
  }

  Future<List<NoticeItemEntity>> getNotices() async {
    try {
      final response = await _dioClient.get(ApiConstants.parentNotices);
      final list = response.data as List;
      return list.map((e) => NoticeItemEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get parent notices error', e);
      _throwApiException(e);
    }
  }
}
