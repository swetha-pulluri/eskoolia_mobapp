import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/policy_document_entity.dart';

/// Reference: backend/apps/settings/{urls,views}.py
/// (SchoolPolicyDocumentViewSet, SettingsAuditLogViewSet),
/// frontend/components/settings/DocumentsPanel.tsx.
class DocumentsRemoteDataSource {
  final DioClient _dioClient;

  DocumentsRemoteDataSource(this._dioClient);

  static List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) return (data['results'] as List?) ?? const [];
    return const [];
  }

  Future<List<PolicyDocumentEntity>> getDocuments({String? category}) async {
    final response = await _dioClient.get(
      ApiConstants.settingsDocuments,
      queryParameters: {if (category != null && category.isNotEmpty) 'category': category},
    );
    return _asList(response.data).map((e) => PolicyDocumentEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PolicyDocumentEntity> createDocument({
    required String title,
    required String category,
    required PickedAttachment file,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'category': category,
      'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
    });
    final response = await _dioClient.post(ApiConstants.settingsDocuments, data: formData);
    return PolicyDocumentEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PolicyDocumentEntity> updateDocument(int id, {required String title, required String category}) async {
    final response = await _dioClient.patch(
      ApiConstants.settingsDocumentDetail(id),
      data: {'title': title, 'category': category},
    );
    return PolicyDocumentEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDocument(int id) async {
    await _dioClient.delete(ApiConstants.settingsDocumentDetail(id));
  }

  Future<List<int>> downloadFile(String fileUrl) async {
    final response = await _dioClient.get(
      fileUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List).cast<int>();
  }

  Future<List<DocumentAuditEntry>> getAuditLog(int objectId) async {
    final response = await _dioClient.get(
      ApiConstants.settingsAuditLog,
      queryParameters: {'module': 'SchoolPolicyDocument', 'object_id': objectId},
    );
    return _asList(response.data).map((e) => DocumentAuditEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
