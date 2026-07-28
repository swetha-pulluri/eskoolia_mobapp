import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
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
}
