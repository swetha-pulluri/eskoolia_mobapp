/// School Info Model — the public, pre-login branding lookup.
/// Reference: backend/apps/tenancy/views.py::school_info_view
/// (`GET /api/v1/tenancy/school-info/?subdomain=<subdomain>`, AllowAny).
///
/// Deliberately a plain class, not a freezed model like the rest of
/// `features/auth/data/models/` — this is a single-use, 5-field read DTO for
/// a public branding lookup, not part of the login/session data shape those
/// other models represent.
class SchoolInfoModel {
  final String name;
  final String? subdomain;
  final String? logoUrl;
  final String brandColor;
  final String? status;

  const SchoolInfoModel({
    required this.name,
    this.subdomain,
    this.logoUrl,
    this.brandColor = '#0d9488',
    this.status,
  });

  factory SchoolInfoModel.fromJson(Map<String, dynamic> json) {
    return SchoolInfoModel(
      name: json['name'] as String? ?? '',
      subdomain: json['subdomain'] as String?,
      logoUrl: json['logo_url'] as String?,
      brandColor: json['brand_color'] as String? ?? '#0d9488',
      status: json['status'] as String?,
    );
  }
}
