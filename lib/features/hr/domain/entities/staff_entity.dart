/// Mirrors the real, currently-running backend `Staff` model /
/// `StaffSerializer` (`apps/hr/models.py`, `apps/hr/serializers.py`,
/// verified read-only). `custom_field` carries `ifsc_code`/`allowance`/
/// `deduction`/`payroll_defaults` as a raw JSON blob — matching the
/// backend's own `JSONField(default=dict)` exactly rather than promoting
/// those to first-class fields the API doesn't have.
class StaffEntity {
  final int id;
  final int schoolId;
  final int? userId;
  final int? roleId;
  final String staffNo;
  final String firstName;
  final String lastName;
  final String fathersName;
  final String mothersName;
  final String? dateOfBirth; // yyyy-MM-dd
  final String email;
  final String officialEmail;
  final String personalEmail;
  final String whatsapp;
  final String phone;
  final String emergencyMobile;
  final String gender; // '', male, female, other
  final String maritalStatus; // '', single, married
  final String drivingLicense;
  final String staffPhoto; // filename/URL as returned by backend
  final String currentAddress;
  final String permanentAddress;
  final String qualification;
  final String experience;
  final String epfNo;
  final String bankAccountName;
  final String bankAccountNo;
  final String bankName;
  final String bankBranch;
  final String bankMobileNo;
  final String facebookUrl;
  final String twitterUrl;
  final String linkedinUrl;
  final String instagramUrl;
  final int casualLeave;
  final int medicalLeave;
  final int maternityLeave;
  final bool showPublic;
  final Map<String, dynamic> customField;
  final int? departmentId;
  final int? designationId;
  final String contractType; // '', permanent, contract
  final String location;
  final String resume;
  final String joiningLetter;
  final String tenthCertificate;
  final String eleventhCertificate;
  final String aadharCard;
  final String drivingLicenseDoc;
  final List<String> otherDocument;
  final String joinDate; // yyyy-MM-dd
  final String basicSalary;
  final String status; // active, inactive, terminated
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StaffEntity({
    this.id = 0,
    this.schoolId = 0,
    this.userId,
    this.roleId,
    this.staffNo = '',
    required this.firstName,
    this.lastName = '',
    this.fathersName = '',
    this.mothersName = '',
    this.dateOfBirth,
    this.email = '',
    this.officialEmail = '',
    this.personalEmail = '',
    this.whatsapp = '',
    this.phone = '',
    this.emergencyMobile = '',
    this.gender = '',
    this.maritalStatus = '',
    this.drivingLicense = '',
    this.staffPhoto = '',
    this.currentAddress = '',
    this.permanentAddress = '',
    this.qualification = '',
    this.experience = '',
    this.epfNo = '',
    this.bankAccountName = '',
    this.bankAccountNo = '',
    this.bankName = '',
    this.bankBranch = '',
    this.bankMobileNo = '',
    this.facebookUrl = '',
    this.twitterUrl = '',
    this.linkedinUrl = '',
    this.instagramUrl = '',
    this.casualLeave = 0,
    this.medicalLeave = 0,
    this.maternityLeave = 0,
    this.showPublic = false,
    this.customField = const {},
    this.departmentId,
    this.designationId,
    this.contractType = '',
    this.location = '',
    this.resume = '',
    this.joiningLetter = '',
    this.tenthCertificate = '',
    this.eleventhCertificate = '',
    this.aadharCard = '',
    this.drivingLicenseDoc = '',
    this.otherDocument = const [],
    required this.joinDate,
    this.basicSalary = '0.00',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  String get ifscCode => customField['ifsc_code'] as String? ?? '';
  String get allowance => customField['allowance'] as String? ?? '0.00';
  String get deduction => customField['deduction'] as String? ?? '0.00';
  String get fullName => '$firstName $lastName'.trim();

  factory StaffEntity.fromJson(Map<String, dynamic> json) {
    List<String> parseOtherDocs(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String && value.isNotEmpty) return [value];
      return const [];
    }

    return StaffEntity(
      id: json['id'] as int? ?? 0,
      schoolId: json['school'] as int? ?? 0,
      userId: json['user'] as int?,
      roleId: json['role'] as int?,
      staffNo: json['staff_no'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fathersName: json['fathers_name'] as String? ?? '',
      mothersName: json['mothers_name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String?,
      email: json['email'] as String? ?? '',
      officialEmail: json['official_email'] as String? ?? '',
      personalEmail: json['personal_email'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      emergencyMobile: json['emergency_mobile'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      maritalStatus: json['marital_status'] as String? ?? '',
      drivingLicense: json['driving_license'] as String? ?? '',
      staffPhoto: json['staff_photo'] as String? ?? '',
      currentAddress: json['current_address'] as String? ?? '',
      permanentAddress: json['permanent_address'] as String? ?? '',
      qualification: json['qualification'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      epfNo: json['epf_no'] as String? ?? '',
      bankAccountName: json['bank_account_name'] as String? ?? '',
      bankAccountNo: json['bank_account_no'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      bankBranch: json['bank_branch'] as String? ?? '',
      bankMobileNo: json['bank_mobile_no'] as String? ?? '',
      facebookUrl: json['facebook_url'] as String? ?? '',
      twitterUrl: json['twitter_url'] as String? ?? '',
      linkedinUrl: json['linkedin_url'] as String? ?? '',
      instagramUrl: json['instagram_url'] as String? ?? '',
      casualLeave: json['casual_leave'] as int? ?? 0,
      medicalLeave: json['medical_leave'] as int? ?? 0,
      maternityLeave: json['maternity_leave'] as int? ?? 0,
      showPublic: json['show_public'] as bool? ?? false,
      customField: (json['custom_field'] as Map?)?.cast<String, dynamic>() ?? const {},
      departmentId: json['department'] as int?,
      designationId: json['designation'] as int?,
      contractType: json['contract_type'] as String? ?? '',
      location: json['location'] as String? ?? '',
      resume: json['resume'] as String? ?? '',
      joiningLetter: json['joining_letter'] as String? ?? '',
      tenthCertificate: json['tenth_certificate'] as String? ?? '',
      eleventhCertificate: json['eleventh_certificate'] as String? ?? '',
      aadharCard: json['aadhar_card'] as String? ?? '',
      drivingLicenseDoc: json['driving_license_doc'] as String? ?? '',
      otherDocument: parseOtherDocs(json['other_document']),
      joinDate: json['join_date'] as String? ?? '',
      basicSalary: json['basic_salary']?.toString() ?? '0.00',
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  /// JSON (no-file) payload — matches web's `submit()` body exactly.
  Map<String, dynamic> toJson() {
    return {
      'staff_no': staffNo,
      'role': roleId,
      'department': departmentId,
      'designation': designationId,
      'first_name': firstName,
      'last_name': lastName,
      'fathers_name': fathersName,
      'mothers_name': mothersName,
      'email': email,
      'official_email': officialEmail,
      'personal_email': personalEmail,
      'whatsapp': whatsapp,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'join_date': joinDate,
      'phone': phone,
      'marital_status': maritalStatus,
      'emergency_mobile': emergencyMobile,
      'driving_license': drivingLicense,
      'staff_photo': staffPhoto,
      'show_public': showPublic,
      'current_address': currentAddress,
      'permanent_address': permanentAddress,
      'qualification': qualification,
      'experience': experience,
      'epf_no': epfNo,
      'basic_salary': basicSalary,
      'contract_type': contractType,
      'location': location,
      'bank_account_name': bankAccountName,
      'bank_account_no': bankAccountNo,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'bank_mobile_no': bankMobileNo,
      'custom_field': customField,
      'facebook_url': facebookUrl,
      'twitter_url': twitterUrl,
      'linkedin_url': linkedinUrl,
      'instagram_url': instagramUrl,
      'resume': resume,
      'joining_letter': joiningLetter,
      'tenth_certificate': tenthCertificate,
      'eleventh_certificate': eleventhCertificate,
      'aadhar_card': aadharCard,
      'driving_license_doc': drivingLicenseDoc,
      'other_document': otherDocument,
      'status': status,
    };
  }
}
