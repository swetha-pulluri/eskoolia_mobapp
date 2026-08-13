import '../../../administration/domain/entities/picked_attachment.dart';
import '../entities/policy_document_entity.dart';

/// Reference: backend/apps/settings/{urls,views,serializers}.py
/// (SchoolPolicyDocumentViewSet — multipart create, JSON-only edit, soft
/// delete), frontend/components/settings/DocumentsPanel.tsx.
abstract class DocumentsRepository {
  /// GET documents/?category=... (omit for "All").
  Future<List<PolicyDocumentEntity>> getDocuments({String? category});

  /// POST documents/ as multipart/form-data — the only way to attach a
  /// file; there is no way to replace a file on an existing document.
  Future<PolicyDocumentEntity> createDocument({
    required String title,
    required String category,
    required PickedAttachment file,
  });

  /// PATCH documents/{id}/ as JSON — title/category only, the file field is
  /// never sent (matches the real backend, which has no `file` write path
  /// on update).
  Future<PolicyDocumentEntity> updateDocument(int id, {required String title, required String category});

  Future<void> deleteDocument(int id);

  /// Fetches the raw file bytes from its (authenticated-media-proxy-served)
  /// URL — used for the "View" action, since a bare link would carry no
  /// bearer token.
  Future<List<int>> downloadFile(String fileUrl);

  Future<List<DocumentAuditEntry>> getAuditLog(int objectId);
}
