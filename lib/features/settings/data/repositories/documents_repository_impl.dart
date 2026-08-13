import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/policy_document_entity.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsRemoteDataSource _dataSource;

  DocumentsRepositoryImpl(this._dataSource);

  @override
  Future<List<PolicyDocumentEntity>> getDocuments({String? category}) => _dataSource.getDocuments(category: category);

  @override
  Future<PolicyDocumentEntity> createDocument({
    required String title,
    required String category,
    required PickedAttachment file,
  }) =>
      _dataSource.createDocument(title: title, category: category, file: file);

  @override
  Future<PolicyDocumentEntity> updateDocument(int id, {required String title, required String category}) =>
      _dataSource.updateDocument(id, title: title, category: category);

  @override
  Future<void> deleteDocument(int id) => _dataSource.deleteDocument(id);

  @override
  Future<List<int>> downloadFile(String fileUrl) => _dataSource.downloadFile(fileUrl);

  @override
  Future<List<DocumentAuditEntry>> getAuditLog(int objectId) => _dataSource.getAuditLog(objectId);
}
