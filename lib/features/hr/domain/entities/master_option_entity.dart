/// Mirrors the real `/api/v1/master/{languages,religions,countries,
/// employment-types}/` endpoints (verified read-only on `demo`/`BugFix`'s
/// `apps/master/views.py`) — plain `[{"id": int, "name": str}, ...]` lists,
/// backed by fixed constants server-side (no migrations, but a real,
/// working endpoint, not a client-side guess).
class MasterOptionEntity {
  final int id;
  final String name;

  const MasterOptionEntity({required this.id, required this.name});

  factory MasterOptionEntity.fromJson(Map<String, dynamic> json) {
    return MasterOptionEntity(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// `GET /api/v1/core/pincode-lookup/?pincode=` response — real proxy to the
/// Indian Postal PIN code API.
class PincodeLookupResult {
  final String city;
  final String state;
  final String country;

  const PincodeLookupResult({this.city = '', this.state = '', this.country = 'India'});

  factory PincodeLookupResult.fromJson(Map<String, dynamic> json) {
    return PincodeLookupResult(
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
    );
  }
}
