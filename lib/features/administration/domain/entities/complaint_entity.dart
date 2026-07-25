import 'picked_attachment.dart';

/// Complaint entry — mirrors backend `ComplaintEntry` /
/// `/api/v1/admissions/complaints/` as it is implemented by the
/// currently-deployed `main` branch code: `complaint_type`/
/// `complaint_source` are write-only `CharField`s resolved server-side
/// (`ComplaintEntrySerializer._resolve_setup_name`) against
/// `AdminSetupEntry` rows of `type="2"`/`type="3"`, then exposed for
/// display as `complaint_type_name`/`complaint_source_name`.
/// `complaintTypeId`/`complaintSourceId` hold the selected `AdminSetupEntry`
/// id as a string (matching `ComplaintPanel.tsx`'s own `String(row.id)`
/// dropdown value) purely so they bind directly to
/// `AdminDropdownField<String>`, not because the wire format is a string.
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
      assigned: json['assigned_to_name'] as String?,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  /// `complaint_type`/`complaint_source` are write-only `CharField`s on the
  /// real (`main`) `ComplaintEntrySerializer`, resolved against
  /// `AdminSetupEntry` when the value is numeric — sent as the selected
  /// entry's id (matching `ComplaintPanel.tsx`'s own
  /// `formData.append("complaint_type", complaintType.trim())` where
  /// `complaintType` is the dropdown's `String(row.id)` value). `assigned`
  /// IS sent — confirmed directly against `ComplaintPanel.tsx`
  /// (`formData.append("assigned", assigned.trim())`), unlike an earlier,
  /// incorrect assumption based on `origin/demo`'s web, which is not the
  /// branch actually deployed here.
  Map<String, dynamic> toJson() {
    return {
      'complaint_by': complaintBy,
      if (complaintTypeId != null && complaintTypeId!.isNotEmpty) 'complaint_type': complaintTypeId,
      if (complaintSourceId != null && complaintSourceId!.isNotEmpty) 'complaint_source': complaintSourceId,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'date': date,
      if (actionTaken != null) 'action_taken': actionTaken,
      'assigned': assigned ?? '',
      if (description != null) 'description': description,
    };
  }
}
