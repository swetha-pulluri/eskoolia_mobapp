import 'picked_attachment.dart';

/// Certificate template — mirrors backend `CertificateTemplate` /
/// `/api/v1/admissions/certificate-templates/`. Note the backend's own
/// field name typo, reproduced verbatim in `toJson`/`fromJson`:
/// `pading_left` (not `padding_left` — `models.py:445`).
class CertificateTemplateEntity {
  final int? id;
  final String type; // "School" | "Lms"
  final String title;
  final int? applicableRoleId; // null = All roles
  final String body;
  final int backgroundHeight;
  final int backgroundWidth;
  final int paddingTop;
  final int paddingRight;
  final int paddingBottom;
  final int paddingLeft;
  final String? backgroundUrl;
  /// Transient — a newly-picked file pending upload on save. Not part of
  /// the API's JSON contract; the datasource sends it as multipart
  /// `background_upload` when present.
  final PickedAttachment? backgroundAttachment;

  const CertificateTemplateEntity({
    this.id,
    this.type = 'School',
    required this.title,
    this.applicableRoleId,
    required this.body,
    this.backgroundHeight = 144,
    this.backgroundWidth = 165,
    this.paddingTop = 5,
    this.paddingRight = 5,
    this.paddingBottom = 5,
    this.paddingLeft = 5,
    this.backgroundUrl,
    this.backgroundAttachment,
  });

  factory CertificateTemplateEntity.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) => v == null ? fallback : (double.tryParse(v.toString())?.round() ?? fallback);
    return CertificateTemplateEntity(
      id: json['id'] as int?,
      type: json['type'] as String? ?? 'School',
      title: json['title'] as String? ?? '',
      applicableRoleId: json['applicable_role_id'] as int?,
      body: json['body'] as String? ?? '',
      backgroundHeight: asInt(json['background_height'], 144),
      backgroundWidth: asInt(json['background_width'], 165),
      paddingTop: asInt(json['padding_top'], 5),
      paddingRight: asInt(json['padding_right'], 5),
      paddingBottom: asInt(json['padding_bottom'], 5),
      paddingLeft: asInt(json['pading_left'], 5),
      backgroundUrl: json['background_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'applicable_role_id': applicableRoleId,
        'body': body,
        'background_height': backgroundHeight,
        'background_width': backgroundWidth,
        'padding_top': paddingTop,
        'padding_right': paddingRight,
        'padding_bottom': paddingBottom,
        'pading_left': paddingLeft,
      };
}
