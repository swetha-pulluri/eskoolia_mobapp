/// Student Data Model
/// Source: frontend/components/students/StudentListPanel.tsx — StudentRow /
/// StudentDetail types. Backend: apps/students — StudentSerializer /
/// StudentListSerializer (GET/POST/PUT /api/v1/students/students/).
///
/// `status` is the student's real lifecycle status (active/inactive/
/// transferred/dropped); `isArchived`/`docsPendingCount`/`enrolledAt` back
/// the List screen's *filter* categories (Archived, Docs pending, New this
/// month), which the frontend derives rather than storing as a single enum
/// — kept as separate fields here for the same reason. `docsPendingCount`
/// maps from the backend's boolean `is_disabled` (1 if disabled, else 0) —
/// the backend has no true per-document pending count, only this one flag.
///
/// `isSpeciallyAbled`/`hasAllergy`/`onMedication` have **no backing field on
/// the real Student model** — the reference frontend reads them via loose,
/// defensive casts that are always `undefined` against the real API too, so
/// its "Special needs"/"Has allergy"/"On medication" filters are already
/// permanently inert against real data. `fromJson` always sets these false,
/// matching that real (if underwhelming) behavior rather than inventing data.
enum StudentGender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other');

  const StudentGender(this.value, this.label);
  final String value;
  final String label;
}

enum StudentStatus {
  active('active', 'Active'),
  inactive('inactive', 'Inactive'),
  transferred('transferred', 'Transferred'),
  dropped('dropped', 'Dropped');

  const StudentStatus(this.value, this.label);
  final String value;
  final String label;
}

class StudentData {
  final int id;
  final String admissionNo;
  final String? rollNo;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final StudentGender? gender;
  final String? phone;
  final String? email;

  final int classId;
  final String className;
  final int sectionId;
  final String sectionName;

  final int? academicYearId;
  final int? categoryId;

  final int? guardianId;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelation;

  final String? addressLine;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;

  final StudentStatus status;
  final bool isArchived;
  final int docsPendingCount;
  final DateTime enrolledAt;

  final bool isSpeciallyAbled;
  final bool hasAllergy;
  final bool onMedication;

  const StudentData({
    required this.id,
    required this.admissionNo,
    this.rollNo,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    this.academicYearId,
    this.categoryId,
    this.guardianId,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelation,
    this.addressLine,
    this.city,
    this.district,
    this.state,
    this.pincode,
    required this.status,
    this.isArchived = false,
    this.docsPendingCount = 0,
    required this.enrolledAt,
    this.isSpeciallyAbled = false,
    this.hasAllergy = false,
    this.onMedication = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isActive => status == StudentStatus.active && !isArchived;

  bool isNewThisMonth(DateTime now) =>
      enrolledAt.year == now.year && enrolledAt.month == now.month;

  int? get ageYears {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  factory StudentData.fromJson(Map<String, dynamic> json) {
    StudentStatus parseStatus(String? value) {
      return StudentStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => StudentStatus.active,
      );
    }

    StudentGender? parseGender(String? value) {
      if (value == null) return null;
      for (final g in StudentGender.values) {
        if (g.value == value) return g;
      }
      return null;
    }

    DateTime? parseDate(String? value) => value == null ? null : DateTime.tryParse(value);

    final isDisabled = json['is_disabled'] as bool? ?? false;

    return StudentData(
      id: json['id'] as int,
      admissionNo: (json['admission_no'] as String?) ?? '',
      rollNo: json['roll_no'] as String?,
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      dateOfBirth: parseDate(json['date_of_birth'] as String?),
      gender: parseGender(json['gender'] as String?),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      classId: (json['current_class'] as int?) ?? 0,
      className: (json['current_class_name'] as String?) ?? '',
      sectionId: (json['current_section'] as int?) ?? 0,
      sectionName: (json['current_section_name'] as String?) ?? '',
      academicYearId: json['academic_year'] as int?,
      categoryId: json['category'] as int?,
      guardianId: json['guardian'] as int?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      status: parseStatus(json['status'] as String?),
      isArchived: json['is_deleted'] as bool? ?? false,
      docsPendingCount: isDisabled ? 1 : 0,
      enrolledAt: parseDate(json['created_at'] as String?) ?? DateTime.now(),
      // No real backing field — see class doc comment.
      isSpeciallyAbled: false,
      hasAllergy: false,
      onMedication: false,
    );
  }

  /// Builds the create/update request body — field names match
  /// `StudentSerializer` (`apps/students/serializers.py`). `guardian` (the
  /// resolved Guardian FK id) is threaded in separately by the repository,
  /// since resolving it requires its own POST /guardians/ call first.
  Map<String, dynamic> toRequestJson({int? guardianId}) {
    return {
      'admission_no': admissionNo,
      if (rollNo != null && rollNo!.isNotEmpty) 'roll_no': rollNo,
      'first_name': firstName,
      'last_name': lastName,
      if (dateOfBirth != null)
        'date_of_birth':
            '${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}',
      if (gender != null) 'gender': gender!.value,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      'current_class': classId,
      'current_section': sectionId,
      if (academicYearId != null) 'academic_year': academicYearId,
      if (categoryId != null) 'category': categoryId,
      if (guardianId != null) 'guardian': guardianId,
      'status': status.value,
      'is_active': status == StudentStatus.active,
      'is_disabled': status != StudentStatus.active,
    };
  }

  StudentData copyWith({
    StudentStatus? status,
    bool? isArchived,
  }) {
    return StudentData(
      id: id,
      admissionNo: admissionNo,
      rollNo: rollNo,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phone: phone,
      email: email,
      classId: classId,
      className: className,
      sectionId: sectionId,
      sectionName: sectionName,
      academicYearId: academicYearId,
      categoryId: categoryId,
      guardianId: guardianId,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      guardianRelation: guardianRelation,
      addressLine: addressLine,
      city: city,
      district: district,
      state: state,
      pincode: pincode,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      docsPendingCount: docsPendingCount,
      enrolledAt: enrolledAt,
      isSpeciallyAbled: isSpeciallyAbled,
      hasAllergy: hasAllergy,
      onMedication: onMedication,
    );
  }
}
