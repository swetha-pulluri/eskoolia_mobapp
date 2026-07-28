/// GET /api/v1/tenancy/my-school-info/ — populates the Collection screen's
/// receipt/ledger header. Distinct from the public (no-auth) school-info
/// endpoint used elsewhere in the app.
class SchoolHeaderInfo {
  final String name;
  final String address;
  final String email;
  final String logoUrl;

  const SchoolHeaderInfo({
    this.name = 'Eskoolia School',
    this.address = '123 School Lane, City — 000000',
    this.email = 'admissions@eskoolia.in',
    this.logoUrl = '',
  });

  factory SchoolHeaderInfo.fromJson(Map<String, dynamic> json) {
    return SchoolHeaderInfo(
      name: (json['name'] as String?)?.isNotEmpty == true ? json['name'] as String : 'Eskoolia School',
      address: (json['address'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      logoUrl: (json['logo_url'] as String?) ?? '',
    );
  }

  SchoolHeaderInfo copyWith({String? name, String? address, String? email, String? logoUrl}) {
    return SchoolHeaderInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
