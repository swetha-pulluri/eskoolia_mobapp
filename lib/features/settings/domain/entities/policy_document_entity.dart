/// Settings → Documents ("Policy Documents"): one `SchoolPolicyDocument`
/// record. Reference: backend/apps/settings/models.py::SchoolPolicyDocument,
/// backend/apps/settings/serializers.py::SchoolPolicyDocumentSerializer,
/// frontend/components/settings/DocumentsPanel.tsx (`interface
/// PolicyDocument`).
///
/// Category is a fixed 4-value enum on both frontend and backend — not a
/// manageable list — so it's kept as a plain string here rather than a
/// dedicated model class, matching every other Settings select field.
class PolicyDocumentEntity {
  final int id;
  final String title;
  final String category;
  final String file;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String uploadedAt;

  const PolicyDocumentEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.file,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory PolicyDocumentEntity.fromJson(Map<String, dynamic> json) {
    return PolicyDocumentEntity(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      file: json['file'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      uploadedAt: json['uploaded_at'] as String? ?? '',
    );
  }
}

/// Mirrors `CATEGORY_LABELS` in `DocumentsPanel.tsx` exactly — same 4
/// hard-coded values on both frontend and backend
/// (`SchoolPolicyDocument.CATEGORY_CHOICES`).
const List<MapEntry<String, String>> policyDocumentCategories = [
  MapEntry('code_of_conduct', 'Code of Conduct'),
  MapEntry('rulebook', 'Rule Book'),
  MapEntry('norms', 'School Norms'),
  MapEntry('other', 'Other'),
];

String policyDocumentCategoryLabel(String value) {
  for (final entry in policyDocumentCategories) {
    if (entry.key == value) return entry.value;
  }
  return value;
}

/// Reverse of the backend's `SchoolPolicyDocument.MIME_TO_TYPE` map — used
/// only to give the OS share sheet a MIME type when handing off a
/// downloaded document's bytes (see `DocumentsNotifier.viewDocument`).
const Map<String, String> _fileTypeToMime = {
  'PDF': 'application/pdf',
  'DOC': 'application/msword',
  'DOCX': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'XLS': 'application/vnd.ms-excel',
  'XLSX': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'PPT': 'application/vnd.ms-powerpoint',
  'PPTX': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'JPG': 'image/jpeg',
  'PNG': 'image/png',
  'TXT': 'text/plain',
  'CSV': 'text/csv',
};

String? policyDocumentMimeType(String fileType) => _fileTypeToMime[fileType.toUpperCase()];

/// One `SettingsAuditLog` row for a policy document — mirrors the web's
/// `interface AuditEntry` (id, actor_name, action, created_at only). Kept
/// as its own copy per the established per-feature self-contained
/// convention. Note: the backend only logs `document.upload` and
/// `document.delete` — edits (title/category) are never audit-logged
/// (confirmed no `perform_update` override on the real viewset), so
/// "update" entries will never appear here; that's a real backend gap; not
/// something to invent client-side.
class DocumentAuditEntry {
  final int id;
  final String actorName;
  final String action;
  final DateTime? createdAt;

  const DocumentAuditEntry({
    required this.id,
    required this.actorName,
    required this.action,
    required this.createdAt,
  });

  factory DocumentAuditEntry.fromJson(Map<String, dynamic> json) {
    return DocumentAuditEntry(
      id: json['id'] as int,
      actorName: json['actor_name'] as String? ?? 'System',
      action: json['action'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
