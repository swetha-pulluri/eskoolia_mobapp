/// Admission inquiry — mirrors backend `AdmissionInquiry` /
/// `/api/v1/admissions/inquiries/` (frontend type `ApiInquiry`).
class InquiryEntity {
  final int id;
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
