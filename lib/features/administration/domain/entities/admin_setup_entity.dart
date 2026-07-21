/// Admin Setup lookup entry — mirrors backend `AdminSetupEntry` /
/// `/api/v1/admissions/admin-setups/`.
///
/// `type`: "1" = Purpose, "2" = Complaint Type, "3" = Source, "4" = Reference.
class AdminSetupEntity {
  final int? id;
  final String type;
  final String? typeName;
  final String name;
  final String? description;
  final String? createdByName;
  final String? createdAt;

  const AdminSetupEntity({
    this.id,
    required this.type,
    this.typeName,
    required this.name,
    this.description,
    this.createdByName,
    this.createdAt,
  });

  factory AdminSetupEntity.fromJson(Map<String, dynamic> json) {
    return AdminSetupEntity(
      id: json['id'] as int?,
      type: json['type']?.toString() ?? '1',
      typeName: json['type_name'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  static const Map<String, String> typeLabels = {
    '1': 'Purpose',
    '2': 'Complaint Type',
    '3': 'Source',
    '4': 'Reference',
  };
}
