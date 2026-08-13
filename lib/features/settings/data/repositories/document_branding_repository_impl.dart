import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/repositories/document_branding_repository.dart';
import '../datasources/document_branding_remote_datasource.dart';

class DocumentBrandingRepositoryImpl implements DocumentBrandingRepository {
  final DocumentBrandingRemoteDataSource _dataSource;

  DocumentBrandingRepositoryImpl(this._dataSource);

  @override
  Future<DocumentBrandingEntity> getBranding() => _dataSource.getBranding();

  @override
  Future<DocumentBrandingEntity> updateBranding(Map<String, dynamic> payload) =>
      _dataSource.updateBranding(payload);

  @override
  Future<DocumentBrandingEntity> uploadLetterhead(PickedAttachment file, String mimeType) =>
      _dataSource.uploadLetterhead(file, mimeType);

  @override
  Future<List<int>> getHeaderImageBytes() => _dataSource.getHeaderImageBytes();

  @override
  Future<List<int>> getPreviewBytes(Map<String, dynamic> styleFields) => _dataSource.getPreviewBytes(styleFields);
}
