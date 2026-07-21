import 'picked_attachment.dart';

/// Visitor Book entry — mirrors backend `VisitorBookEntry` /
/// `/api/v1/admissions/visitors/`.
class VisitorEntity {
  final int? id;
  final String? purposeId;
  final String? purposeName;
  final String name;
  final String? phone;
  final int noOfPerson;
  final String date;
  final String inTime;
  final String outTime;
  final String? fileUrl;
  final String? createdByName;
  final String? createdAt;
  /// Transient — a newly-picked file pending upload on save. Not part of
  /// the API's JSON contract (`toJson`); the datasource sends it as
  /// multipart `file_upload` instead when present.
  final PickedAttachment? attachment;

  const VisitorEntity({
    this.id,
    this.purposeId,
    this.purposeName,
    required this.name,
    this.phone,
    required this.noOfPerson,
    required this.date,
    required this.inTime,
    required this.outTime,
    this.fileUrl,
    this.createdByName,
    this.createdAt,
    this.attachment,
  });

  factory VisitorEntity.fromJson(Map<String, dynamic> json) {
    return VisitorEntity(
      id: json['id'] as int?,
      purposeId: json['purpose']?.toString(),
      purposeName: json['purpose_name'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      noOfPerson: int.tryParse(json['no_of_person']?.toString() ?? '') ?? 1,
      date: json['date'] as String? ?? '',
      inTime: json['in_time'] as String? ?? '',
      outTime: json['out_time'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (purposeId != null && purposeId!.isNotEmpty) 'purpose': purposeId,
      'name': name,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'no_of_person': noOfPerson,
      'date': date,
      'in_time': inTime,
      'out_time': outTime,
    };
  }
}
