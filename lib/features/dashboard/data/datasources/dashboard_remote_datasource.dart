import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/attendance_pulse_entity.dart';
import '../../domain/entities/fees_today_entity.dart';
import '../../domain/models/kpi_data.dart';

/// Dashboard Remote Data Source
class DashboardRemoteDataSource {
  final DioClient _dioClient;

  DashboardRemoteDataSource(this._dioClient);

  Future<KpiData> getKpis() async {
    final response = await _dioClient.get(ApiConstants.dashboardKpis);
    return KpiData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> getAttentionCount() async {
    try {
      final response = await _dioClient.get(ApiConstants.attentionCountEndpoint);
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } catch (e) {
      // TEMP DEBUG: surface the swallowed error while diagnosing the
      // post-login dashboard load issue — remove once resolved.
      AppLogger.error('[TEMP DEBUG] Get attention count error (endpoint: ${ApiConstants.attentionCountEndpoint})', e);
      return 0; // Return 0 on error
    }
  }

  // NOTE: Recently Visited API endpoint does not exist in backend
  // Web frontend uses localStorage only. No backend API call needed.

  Future<AttendancePulseEntity> getAttendancePulse() async {
    // This endpoint has been observed timing out past the app-wide 30s
    // receive timeout on a slow backend response (a server-side performance
    // issue, not a client bug) — a longer timeout just for this call gives
    // a genuinely-slow-but-eventually-successful response a chance to land,
    // without loosening the 30s timeout every other endpoint still relies on.
    final response = await _dioClient.get(
      ApiConstants.attendanceDashboardToday,
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    return AttendancePulseEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FeesTodayEntity> getFeesToday() async {
    final response = await _dioClient.get(ApiConstants.feesTodaySummary);
    return FeesTodayEntity.fromJson(response.data as Map<String, dynamic>);
  }
}
