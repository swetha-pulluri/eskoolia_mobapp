/// Mirrors the real `StaffOnboardDocument` model / serializer (verified
/// read-only on `demo`/`BugFix`'s `apps/hr/models.py`, `views.py`) —
/// `POST /api/v1/hr/onboard/documents/upload/`,
/// `GET .../documents/`, `DELETE .../documents/{id}/`,
/// `GET .../documents/{id}/preview/`.
class OnboardDocumentEntity {
  final int id;
  final String docKey;
  final String docLabel;
  final String fileName;
  final int fileSize;
  final String contentType;
  final String status;
  final DateTime? createdAt;

  const OnboardDocumentEntity({
    this.id = 0,
    required this.docKey,
    this.docLabel = '',
    this.fileName = '',
    this.fileSize = 0,
    this.contentType = '',
    this.status = '',
    this.createdAt,
  });

  factory OnboardDocumentEntity.fromJson(Map<String, dynamic> json) {
    return OnboardDocumentEntity(
      id: json['id'] as int? ?? 0,
      docKey: json['doc_key'] as String? ?? '',
      docLabel: json['doc_label'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
