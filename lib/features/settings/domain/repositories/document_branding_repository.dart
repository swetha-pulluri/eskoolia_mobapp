import '../../../administration/domain/entities/picked_attachment.dart';
import '../entities/document_branding_entity.dart';

/// Reference: backend/apps/settings/{urls,views,serializers}.py
/// (DocumentBrandingSettingsView, DocumentBrandingUploadLetterheadView,
/// DocumentBrandingHeaderImageView, DocumentBrandingPreviewView),
/// frontend/components/settings/DocumentBrandingPanel.tsx. A singleton
/// settings form (one row per school via `get_or_create`), not a CRUD list.
abstract class DocumentBrandingRepository {
  Future<DocumentBrandingEntity> getBranding();

  /// PATCH document-branding/ — accepts every writable field (header +
  /// declarations together, same as the real serializer).
  Future<DocumentBrandingEntity> updateBranding(Map<String, dynamic> payload);

  /// POST document-branding/upload-letterhead/ as multipart/form-data —
  /// field name `file`; server force-sets `header_mode="uploaded"` and
  /// returns the full updated settings object.
  Future<DocumentBrandingEntity> uploadLetterhead(PickedAttachment file, String mimeType);

  /// GET document-branding/header-image/ — raw PNG bytes of the saved
  /// header (used when `header_mode == "uploaded"`).
  Future<List<int>> getHeaderImageBytes();

  /// POST document-branding/preview/ — raw PNG bytes rendered from the
  /// given transient style fields, no DB write (used when
  /// `header_mode == "generated"`, debounced on every style change).
  Future<List<int>> getPreviewBytes(Map<String, dynamic> styleFields);
}
