/// Certificate template — mirrors backend `CertificateTemplate` /
/// `/api/v1/admissions/certificate-templates/`.
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
  });
}
