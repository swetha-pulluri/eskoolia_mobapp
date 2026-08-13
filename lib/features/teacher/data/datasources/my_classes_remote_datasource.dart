import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/network/dio_client.dart';
import '../../domain/entities/my_class_entity.dart';
import '../../domain/entities/reset_password_result_entity.dart';
import '../../domain/entities/student_credentials_entity.dart';
import '../../domain/entities/student_list_item_entity.dart';
import '../../domain/entities/student_profile_entity.dart';
import '../../domain/repositories/teacher_api_exception.dart';

/// Calls the real, implemented `apps.teacher_portal` "My Classes" endpoints
/// exactly as the web app does — same base path, same query params.
class MyClassesRemoteDataSource {
  final DioClient _dioClient;

  MyClassesRemoteDataSource(this._dioClient);

  Never _throwApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final rawMessage = data['detail'] ?? data['message'] ?? data['error'];
      if (rawMessage is String) throw TeacherApiException(rawMessage);
      if (rawMessage != null) throw TeacherApiException(rawMessage.toString());
    }
    throw TeacherApiException(e.message ?? 'Something went wrong. Please try again.');
  }

  Future<List<MyClassEntity>> getMyClasses() async {
    try {
      final response = await _dioClient.get(ApiConstants.teacherClasses);
      return (response.data as List).map((e) => MyClassEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get my classes error', e);
      _throwApiException(e);
    }
  }

  Future<List<StudentListItemEntity>> getStudents({required int classId, required int sectionId}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.teacherStudents,
        queryParameters: {'class_id': classId, 'section_id': sectionId},
      );
      return (response.data as List).map((e) => StudentListItemEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      AppLogger.error('Get students error', e);
      _throwApiException(e);
    }
  }

  Future<StudentProfileEntity> getStudentProfile(int studentId) async {
    try {
      final response = await _dioClient.get(ApiConstants.teacherStudentDetail(studentId));
      return StudentProfileEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get student profile error', e);
      _throwApiException(e);
    }
  }

  Future<StudentCredentialsEntity> getStudentCredentials(int studentId) async {
    try {
      final response = await _dioClient.get(ApiConstants.teacherStudentCredentials(studentId));
      return StudentCredentialsEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Get student credentials error', e);
      _throwApiException(e);
    }
  }

  Future<ResetPasswordResultEntity> resetStudentPassword(int studentId, String target) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.teacherStudentResetPassword(studentId),
        data: {'target': target},
      );
      return ResetPasswordResultEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error('Reset student password error', e);
      _throwApiException(e);
    }
  }
}
