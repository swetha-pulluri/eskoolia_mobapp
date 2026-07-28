/// Mirrors the real `StaffOnboardDraft` model / serializer (verified
/// read-only on `demo`/`BugFix`'s `apps/hr/models.py`, `views.py`,
/// `serializers.py`) — `GET/POST /api/v1/hr/onboard/drafts/`,
/// `POST .../drafts/save/`, `DELETE .../drafts/{id}/`. `formData` uses the
/// exact same flat key set as the real web's own `form` object, so a draft
/// round-trips through the backend's `JSONField` unchanged.
class OnboardDraftEntity {
  final int id;
  final String draftName;
  final Map<String, dynamic> formData;
  final int currentStep;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OnboardDraftEntity({
    this.id = 0,
    this.draftName = '',
    this.formData = const {},
    this.currentStep = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory OnboardDraftEntity.fromJson(Map<String, dynamic> json) {
    return OnboardDraftEntity(
      id: json['id'] as int? ?? 0,
      draftName: json['draft_name'] as String? ?? '',
      formData: (json['form_data'] as Map?)?.cast<String, dynamic>() ?? const {},
      currentStep: json['current_step'] as int? ?? 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }
}
