/// Admission inquiry — mirrors backend `AdmissionInquiry` /
/// `/api/v1/admissions/inquiries/` (frontend type `ApiInquiry`).
class InquiryEntity {
  final int id;
  /// Owning school id (`AdmissionInquirySerializer`'s read-only `school`
  /// field). Used to client-side re-scope results for accounts where
  /// `AdmissionInquiryViewSet.get_queryset()` skips school filtering
  /// (`is_superuser` bypass merges every school's inquiries together).
  final int? schoolId;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String description;
  final String? queryDate;
  final String? followUpDate;
  final String? nextFollowUpDate;
  final String assigned;
  final int? reference;
  final String? referenceName;
  final int? source;
  final String? sourceName;
  final int? schoolClass;
  final String? classNameResolved;
  final int noOfChild;
  final int activeStatus;
  /// "new" | "contacted" | "visited" | "enrolled" | "declined"
  final String status;
  final String note;
  final String childName;
  final String hasSiblingEnrolled;
  final String siblingName;
  final int leadScore;
  /// "not_requested" | "requested" | "partial" | "complete"
  final String documentsStatus;
  final String? lastContactedAt;

  const InquiryEntity({
    required this.id,
    this.schoolId,
    required this.fullName,
    required this.phone,
    this.email = '',
    this.address = '',
    this.description = '',
    this.queryDate,
    this.followUpDate,
    this.nextFollowUpDate,
    this.assigned = '',
    this.reference,
    this.referenceName,
    this.source,
    this.sourceName,
    this.schoolClass,
    this.classNameResolved,
    this.noOfChild = 1,
    this.activeStatus = 1,
    this.status = 'new',
    this.note = '',
    this.childName = '',
    this.hasSiblingEnrolled = '',
    this.siblingName = '',
    this.leadScore = 0,
    this.documentsStatus = 'not_requested',
    this.lastContactedAt,
  });

  /// Mirrors backend `AdmissionInquirySerializer`'s real output fields
  /// (`serializers.py:184-233`) — `reference_name`/`source_name`/
  /// `class_name_resolved` are server-computed display names, distinct
  /// from the writable `reference`/`source`/`school_class` FK ids.
  factory InquiryEntity.fromJson(Map<String, dynamic> json) {
    return InquiryEntity(
      id: json['id'] as int,
      schoolId: json['school'] as int?,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      queryDate: json['query_date'] as String?,
      followUpDate: json['follow_up_date'] as String?,
      nextFollowUpDate: json['next_follow_up_date'] as String?,
      assigned: json['assigned'] as String? ?? '',
      reference: json['reference'] as int?,
      referenceName: json['reference_name'] as String?,
      source: json['source'] as int?,
      sourceName: json['source_name'] as String?,
      schoolClass: json['school_class'] as int?,
      classNameResolved: (json['class_name_resolved'] as String?) ?? (json['class_name'] as String?),
      noOfChild: json['no_of_child'] as int? ?? 1,
      activeStatus: json['active_status'] as int? ?? 1,
      status: json['status'] as String? ?? 'new',
      note: json['note'] as String? ?? '',
      childName: json['child_name'] as String? ?? '',
      hasSiblingEnrolled: json['has_sibling_enrolled']?.toString() ?? '',
      siblingName: json['sibling_name'] as String? ?? '',
      leadScore: json['lead_score'] as int? ?? 0,
      documentsStatus: json['documents_status'] as String? ?? 'not_requested',
      lastContactedAt: json['last_contacted_at'] as String?,
    );
  }

  /// Write payload matching `AdmissionInquirySerializer`'s writable fields.
  /// `full_name`/`phone` regex + duplicate-guard validation, and the
  /// date-order checks, are enforced server-side (`serializers.py:240-363`)
  /// — this just shapes the wire format, matching `AdmissionsCommandCenter.tsx`'s
  /// own create/update payload fields.
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      if (email.isNotEmpty) 'email': email,
      if (address.isNotEmpty) 'address': address,
      if (description.isNotEmpty) 'description': description,
      if (queryDate != null) 'query_date': queryDate,
      if (followUpDate != null) 'follow_up_date': followUpDate,
      if (nextFollowUpDate != null) 'next_follow_up_date': nextFollowUpDate,
      'assigned': assigned,
      if (reference != null) 'reference': reference,
      if (source != null) 'source': source,
      if (schoolClass != null) 'school_class': schoolClass,
      'no_of_child': noOfChild,
      'active_status': activeStatus,
      'status': status,
      'note': note,
      'documents_status': documentsStatus,
    };
  }

  InquiryEntity copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? description,
    String? queryDate,
    String? followUpDate,
    String? nextFollowUpDate,
    String? assigned,
    int? reference,
    String? referenceName,
    int? source,
    String? sourceName,
    int? schoolClass,
    String? classNameResolved,
    int? noOfChild,
    int? activeStatus,
    String? status,
    String? note,
    String? childName,
    String? hasSiblingEnrolled,
    String? siblingName,
    String? documentsStatus,
  }) {
    return InquiryEntity(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address,
      description: description ?? this.description,
      queryDate: queryDate ?? this.queryDate,
      followUpDate: followUpDate ?? this.followUpDate,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      assigned: assigned ?? this.assigned,
      reference: reference ?? this.reference,
      referenceName: referenceName ?? this.referenceName,
      source: source ?? this.source,
      sourceName: sourceName ?? this.sourceName,
      schoolClass: schoolClass ?? this.schoolClass,
      classNameResolved: classNameResolved ?? this.classNameResolved,
      noOfChild: noOfChild ?? this.noOfChild,
      activeStatus: activeStatus ?? this.activeStatus,
      status: status ?? this.status,
      note: note ?? this.note,
      childName: childName ?? this.childName,
      hasSiblingEnrolled: hasSiblingEnrolled ?? this.hasSiblingEnrolled,
      siblingName: siblingName ?? this.siblingName,
      leadScore: leadScore,
      documentsStatus: documentsStatus ?? this.documentsStatus,
      lastContactedAt: lastContactedAt,
    );
  }
}
