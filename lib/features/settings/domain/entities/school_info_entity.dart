/// Settings → School Info: the single school-tenant profile record.
/// Reference: backend/apps/settings/serializers.py::SchoolInfoSerializer,
/// frontend/components/settings/SchoolInfoPanel.tsx (`interface SchoolInfo`).
///
/// Latitude/longitude are kept as `String?` (not `double?`) because the
/// backend serializes DecimalField as a string (e.g. "17.385044") and the
/// web's own TS interface does the same — round-tripping through a decimal
/// string avoids float rounding drift on repeated PATCHes.
class SchoolInfoEntity {
  final int schoolId;
  final String schoolName;
  final String schoolCode;
  final String board;
  final String schoolType;
  final String mediumOfInstruction;
  final int? yearEstablished;
  final String motto;
  final String? principalName;
  final String? principalEmail;
  final String? principalPhone;
  final String schoolPhone;
  final String schoolEmail;
  final String website;
  final String? campusAddress;
  final String city;
  final String state;
  final String region;
  final String? pinCode;
  final String country;
  final String? latitude;
  final String? longitude;
  final int? geofenceRadiusMeters;
  final String? affiliationNumber;
  final String udiseCode;
  final String gstin;
  final String pan;
  final String logoUrl;
  final String brandColor;

  const SchoolInfoEntity({
    required this.schoolId,
    required this.schoolName,
    required this.schoolCode,
    required this.board,
    required this.schoolType,
    required this.mediumOfInstruction,
    required this.yearEstablished,
    required this.motto,
    required this.principalName,
    required this.principalEmail,
    required this.principalPhone,
    required this.schoolPhone,
    required this.schoolEmail,
    required this.website,
    required this.campusAddress,
    required this.city,
    required this.state,
    required this.region,
    required this.pinCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    required this.affiliationNumber,
    required this.udiseCode,
    required this.gstin,
    required this.pan,
    required this.logoUrl,
    required this.brandColor,
  });

  factory SchoolInfoEntity.fromJson(Map<String, dynamic> json) {
    return SchoolInfoEntity(
      schoolId: json['school_id'] as int,
      schoolName: json['school_name'] as String? ?? '',
      schoolCode: json['school_code'] as String? ?? '',
      board: json['board'] as String? ?? '',
      schoolType: json['school_type'] as String? ?? '',
      mediumOfInstruction: json['medium_of_instruction'] as String? ?? '',
      yearEstablished: json['year_established'] as int?,
      motto: json['motto'] as String? ?? '',
      principalName: json['principal_name'] as String?,
      principalEmail: json['principal_email'] as String?,
      principalPhone: json['principal_phone'] as String?,
      schoolPhone: json['school_phone'] as String? ?? '',
      schoolEmail: json['school_email'] as String? ?? '',
      website: json['website'] as String? ?? '',
      campusAddress: json['campus_address'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      region: json['region'] as String? ?? '',
      pinCode: json['pin_code'] as String?,
      country: json['country'] as String? ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      geofenceRadiusMeters: json['geofence_radius_meters'] as int?,
      affiliationNumber: json['affiliation_number'] as String?,
      udiseCode: json['udise_code'] as String? ?? '',
      gstin: json['gstin'] as String? ?? '',
      pan: json['pan'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      brandColor: json['brand_color'] as String? ?? '',
    );
  }

  /// Raw per-field map (editable fields only) used to seed the wizard's
  /// draft `form` state — mirrors the web's `setForm(data)` after a load.
  Map<String, dynamic> toFormMap() {
    return {
      'board': board,
      'school_type': schoolType,
      'medium_of_instruction': mediumOfInstruction,
      'year_established': yearEstablished,
      'motto': motto,
      'principal_name': principalName,
      'principal_email': principalEmail,
      'principal_phone': principalPhone,
      'school_phone': schoolPhone,
      'school_email': schoolEmail,
      'website': website,
      'campus_address': campusAddress,
      'city': city,
      'state': state,
      'region': region,
      'pin_code': pinCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'affiliation_number': affiliationNumber,
      'udise_code': udiseCode,
      'gstin': gstin,
      'pan': pan,
      'logo_url': logoUrl,
      'brand_color': brandColor,
    };
  }
}
