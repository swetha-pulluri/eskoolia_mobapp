/// School Info — read-only school profile shown on the Settings module's
/// "School Info" screen.
///
/// Backed by `GET /api/v1/tenancy/my-school-info/`
/// (`backend/apps/tenancy/views.py::my_school_info_view`), which is
/// authenticated + school-scoped but GET-only — the backend has no
/// PATCH/PUT endpoint for this data, so this screen is display-only,
/// matching the web app (which also never built a persisted edit form for
/// this endpoint; its only "edit" is a local, non-persisting override
/// inside the Fees receipt header).
class SchoolInfoEntity {
  final String name;
  final String address;
  final String email;
  final String phone;
  final String logoUrl;

  const SchoolInfoEntity({
    this.name = '',
    this.address = '',
    this.email = '',
    this.phone = '',
    this.logoUrl = '',
  });

  factory SchoolInfoEntity.fromJson(Map<String, dynamic> json) {
    return SchoolInfoEntity(
      name: (json['name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      logoUrl: (json['logo_url'] as String?) ?? '',
    );
  }
}
