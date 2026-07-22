import 'picked_attachment.dart';

/// Complaint entry — mirrors backend `ComplaintEntry` /
/// `/api/v1/admissions/complaints/`.
class ComplaintEntity {
  final int? id;
  final String complaintBy;
  final String? complaintTypeId;
  final String? complaintTypeName;
  final String? complaintSourceId;
  final String? complaintSourceName;
  final String? phone;
  final String date;
  final String? actionTaken;
  final String? assigned;
  final String? description;
  final String? fileUrl;
  final String? createdByName;
  final String? createdAt;
  /// Transient — a newly-picked file pending upload on save (not part of
  /// the API's JSON contract), matching Visitor Book's attachment field.
  final PickedAttachment? attachment;

  const ComplaintEntity({
    this.id,
    required this.complaintBy,
    this.complaintTypeId,
    this.complaintTypeName,
    this.complaintSourceId,
    this.complaintSourceName,
    this.phone,
    required this.date,
    this.actionTaken,
    this.assigned,
    this.description,
    this.fileUrl,
    this.createdByName,
    this.createdAt,
    this.attachment,
  });

  factory ComplaintEntity.fromJson(Map<String, dynamic> json) {
    return ComplaintEntity(
      id: json['id'] as int?,
      complaintBy: json['complaint_by'] as String? ?? '',
      complaintTypeId: json['complaint_type']?.toString(),
      complaintTypeName: json['complaint_type_name'] as String?,
      complaintSourceId: json['complaint_source']?.toString(),
      complaintSourceName: json['complaint_source_name'] as String?,
      phone: json['phone'] as String?,
      date: json['date'] as String? ?? '',
      actionTaken: json['action_taken'] as String?,
      assigned: json['assigned'] as String?,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint_by': complaintBy,
      if (complaintTypeId != null && complaintTypeId!.isNotEmpty) 'complaint_type': complaintTypeId,
      if (complaintSourceId != null && complaintSourceId!.isNotEmpty) 'complaint_source': complaintSourceId,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'date': date,
      if (actionTaken != null) 'action_taken': actionTaken,
      if (assigned != null) 'assigned': assigned,
      if (description != null) 'description': description,
    };
  }
}
