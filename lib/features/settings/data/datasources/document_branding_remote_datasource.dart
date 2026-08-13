import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../data/network/dio_client.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/document_branding_entity.dart';

/// Reference: backend/apps/settings/{urls,views}.py
/// (DocumentBrandingSettingsView, DocumentBrandingUploadLetterheadView,
/// DocumentBrandingHeaderImageView, DocumentBrandingPreviewView),
/// frontend/components/settings/DocumentBrandingPanel.tsx.
class DocumentBrandingRemoteDataSource {
  final DioClient _dioClient;

  DocumentBrandingRemoteDataSource(this._dioClient);

  Future<DocumentBrandingEntity> getBranding() async {
    final response = await _dioClient.get(ApiConstants.settingsDocumentBranding);
    return DocumentBrandingEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DocumentBrandingEntity> updateBranding(Map<String, dynamic> payload) async {
    final response = await _dioClient.patch(ApiConstants.settingsDocumentBranding, data: payload);
    return DocumentBrandingEntity.fromJson(response.data as Map<String, dynamic>);
  }

  /// Field name is `file` — confirmed from
  /// `DocumentBrandingUploadLetterheadView.post()`.
  Future<DocumentBrandingEntity> uploadLetterhead(PickedAttachment file, String mimeType) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes,
        filename: file.name,
        contentType: MediaType.parse(mimeType),
      ),
    });
    final response = await _dioClient.post(ApiConstants.settingsDocumentBrandingUploadLetterhead, data: formData);
    return DocumentBrandingEntity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<int>> getHeaderImageBytes() async {
    final response = await _dioClient.get(
      ApiConstants.settingsDocumentBrandingHeaderImage,
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List).cast<int>();
  }

  Future<List<int>> getPreviewBytes(Map<String, dynamic> styleFields) async {
    final response = await _dioClient.post(
      ApiConstants.settingsDocumentBrandingPreview,
      data: styleFields,
      options: Options(responseType: ResponseType.bytes),
    );
    return (response.data as List).cast<int>();
  }
}
