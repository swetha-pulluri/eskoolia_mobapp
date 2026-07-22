import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/dashboard_dto.dart';
import '../models/school_dto.dart';

/// School Tenancy Remote Data Source
class SchoolTenancyRemoteDataSource {
  final DioClient _dioClient;

  SchoolTenancyRemoteDataSource(this._dioClient);

  /// Get Dashboard Data
  Future<DashboardDto> getDashboard() async {
    try {
      final response = await _dioClient.get('/api/super-admin/dashboard/');
      return DashboardDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get dashboard error', e);
      rethrow;
    }
  }

  /// Get Schools with pagination and filters
  Future<PaginatedSchoolsDto> getSchools({
    int? page,
    int? pageSize,
    String? search,
    String? status,
    String? board,
    String? plan,
    String? region,
    String? state,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (board != null && board.isNotEmpty) queryParams['board'] = board;
      if (plan != null && plan.isNotEmpty) queryParams['plan'] = plan;
      if (region != null && region.isNotEmpty) queryParams['region'] = region;
      if (state != null && state.isNotEmpty) queryParams['state'] = state;

      final response = await _dioClient.get(
        '/api/super-admin/schools/',
        queryParameters: queryParams,
      );
      
      return PaginatedSchoolsDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get schools error', e);
      rethrow;
    }
  }

  /// Get single school by tenant ID
  Future<SchoolDto> getSchool(String tenantId) async {
    try {
      final response = await _dioClient.get('/api/super-admin/schools/$tenantId/');
      return SchoolDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Get school error', e);
      rethrow;
    }
  }
}
