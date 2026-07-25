import 'picked_attachment.dart';
import 'role_entity.dart';

/// ID Card template — mirrors backend `IdCardTemplate` /
/// `/api/v1/admissions/id-card-templates/`. Web's 4 upload labels map to
/// these backend fields non-obviously (`IdCardPanel.tsx`): "Background
/// Image (Front)" → `background_upload`/`background_img`, "Background
/// Image (Back)" → `profile_upload`/`profile_image`, "Logo" →
/// `logo_upload`/`logo`, "Signature" → `signature_upload`/`signature`.
class IdCardTemplateEntity {
  final int? id;
  final String title;
  final String pageLayoutStyle; // "horizontal" | "vertical"
  final List<int> applicableRoleIds; // empty = All roles
  final String? backgroundUrl;
  final String? profileUrl;
  final String? logoUrl;
  final String? signatureUrl;
  /// Physical card size in mm — read-only server fields (no web UI ever
  /// sets these; `GenerateIdCardPanel.tsx`'s `mm(selectedTemplate.pl_width,
  /// ...)` reads them with a layout-style-dependent fallback when absent).
  final int? plWidth;
  final int? plHeight;
  /// Transient — newly-picked files pending upload on save. Not part of
  /// the API's JSON contract; the datasource sends them as multipart
  /// `background_upload`/`profile_upload`/`logo_upload`/`signature_upload`
  /// when present.
  final PickedAttachment? backgroundAttachment;
  final PickedAttachment? profileAttachment;
  final PickedAttachment? logoAttachment;
  final PickedAttachment? signatureAttachment;

  const IdCardTemplateEntity({
    this.id,
    required this.title,
    this.pageLayoutStyle = 'horizontal',
    this.applicableRoleIds = const [],
    this.backgroundUrl,
    this.profileUrl,
    this.logoUrl,
    this.signatureUrl,
    this.plWidth,
    this.plHeight,
    this.backgroundAttachment,
    this.profileAttachment,
    this.logoAttachment,
    this.signatureAttachment,
  });

  factory IdCardTemplateEntity.fromJson(Map<String, dynamic> json) {
    return IdCardTemplateEntity(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      pageLayoutStyle: json['page_layout_style'] as String? ?? 'horizontal',
      applicableRoleIds: (json['applicable_role_ids'] as List? ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e != 0)
          .toList(),
      backgroundUrl: json['background_url'] as String?,
      profileUrl: json['profile_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      plWidth: int.tryParse(json['pl_width']?.toString() ?? ''),
      plHeight: int.tryParse(json['pl_height']?.toString() ?? ''),
    );
  }

  bool get hasAnyAttachment =>
      backgroundAttachment != null || profileAttachment != null || logoAttachment != null || signatureAttachment != null;

  Map<String, dynamic> toJson() => {
        'title': title,
        'page_layout_style': pageLayoutStyle,
        'applicable_role_ids': applicableRoleIds,
      };
}

/// Class — from `/api/v1/admissions/id-card-templates/generate-setup/`.
class ClassEntity {
  final int id;
  final String name;
  const ClassEntity({required this.id, required this.name});

  factory ClassEntity.fromJson(Map<String, dynamic> json) {
    return ClassEntity(id: json['id'] as int, name: json['name'] as String? ?? '');
  }
}

/// Section — scoped to a class, from the same generate-setup endpoint.
class SectionEntity {
  final int id;
  final int classId;
  final String name;
  const SectionEntity({required this.id, required this.classId, required this.name});

  factory SectionEntity.fromJson(Map<String, dynamic> json) {
    return SectionEntity(
      id: json['id'] as int,
      classId: json['school_class'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// Recipient row (student or other role) for the Generate & Print screens.
class RecipientEntity {
  final int id;
  final String label;
  final String? admissionNo;
  final String? rollNo;
  final String? className;
  final String? sectionName;
  final String? gender;
  final String? dateOfBirth;

  const RecipientEntity({
    required this.id,
    required this.label,
    this.admissionNo,
    this.rollNo,
    this.className,
    this.sectionName,
    this.gender,
    this.dateOfBirth,
  });

  factory RecipientEntity.fromJson(Map<String, dynamic> json) {
    return RecipientEntity(
      id: json['id'] as int,
      label: json['label'] as String? ?? '',
      admissionNo: json['admission_no'] as String?,
      rollNo: json['roll_no'] as String?,
      className: json['className'] as String?,
      sectionName: json['sectionName'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
    );
  }
}

/// `GET .../generate-setup/` response — shared shape for both ID Card and
/// Certificate template viewsets (identical `roles`/`classes`/`sections`
/// derivation). `templates` is kept as raw JSON here since ID Card and
/// Certificate templates parse to different entity types — each caller
/// maps it with the right `fromJson`. The real `GenerateIdCardPanel.tsx`/
/// `GenerateCertificatePanel.tsx` populate their Template dropdown from
/// exactly this embedded, unpaginated list (every template for the school),
/// NOT from the separate paginated `/id-card-templates/`/
/// `/certificate-templates/` list endpoints (which default to 10/page and
/// would silently truncate for any school with more templates than that).
class DocumentGenerateSetup {
  final List<RoleEntity> roles;
  final List<ClassEntity> classes;
  final List<SectionEntity> sections;
  final List<dynamic> templates;

  const DocumentGenerateSetup({required this.roles, required this.classes, required this.sections, this.templates = const []});

  factory DocumentGenerateSetup.fromJson(Map<String, dynamic> json) {
    return DocumentGenerateSetup(
      roles: (json['roles'] as List? ?? const []).map((e) => RoleEntity.fromJson(e as Map<String, dynamic>)).toList(),
      classes: (json['classes'] as List? ?? const []).map((e) => ClassEntity.fromJson(e as Map<String, dynamic>)).toList(),
      sections: (json['sections'] as List? ?? const []).map((e) => SectionEntity.fromJson(e as Map<String, dynamic>)).toList(),
      templates: json['templates'] as List? ?? const [],
    );
  }
}

/// `GET .../recipients/` response.
class RecipientsResult {
  final bool isStudentRole;
  final List<RecipientEntity> recipients;

  const RecipientsResult({required this.isStudentRole, required this.recipients});

  factory RecipientsResult.fromJson(Map<String, dynamic> json) {
    final rows = (json['results'] as List?) ?? (json['recipients'] as List?) ?? const [];
    return RecipientsResult(
      isStudentRole: json['is_student_role'] as bool? ?? false,
      recipients: rows.map((e) => RecipientEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
