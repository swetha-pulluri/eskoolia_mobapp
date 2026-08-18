/// Mirrors `ChildDetailView`'s real response
/// (`GET /api/v1/parent/children/<id>/`) — one child's full profile:
/// attendance summary (last 90 days), recent exam marks, behaviour points,
/// and (as of the onboarding-profile addition) the full set of
/// admission-wizard-captured data web's `/parent/profile` ("My Profile")
/// page displays. See web's `lib/api/parent.ts`'s `ChildDetail`/
/// `ChildOnboardingProfile`.
class ChildDetailEntity {
  final int id;
  final String name;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? admissionNo;
  final String? rollNo;
  final String className;
  final String sectionName;
  final String? photoUrl;
  final String? gender;
  final String? customGender;
  final String? dateOfBirth;
  final String? bloodGroup;
  final AttendanceSummaryEntity attendance;
  final List<ExamMarkEntity> recentMarks;
  final int behaviourPoints;
  final ChildContactEntity contact;
  final ChildAddressEntity address;
  final ChildBackgroundEntity background;
  final ChildAdmissionEntity admission;
  final ChildIdentityDocumentsEntity identityDocuments;
  final ChildPhysicalEntity physical;
  final ChildMedicalEntity medical;
  final List<ChildGuardianEntity> guardians;

  const ChildDetailEntity({
    required this.id,
    required this.name,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.admissionNo,
    this.rollNo,
    required this.className,
    required this.sectionName,
    this.photoUrl,
    this.gender,
    this.customGender,
    this.dateOfBirth,
    this.bloodGroup,
    required this.attendance,
    this.recentMarks = const [],
    this.behaviourPoints = 0,
    this.contact = const ChildContactEntity(),
    this.address = const ChildAddressEntity(),
    this.background = const ChildBackgroundEntity(),
    this.admission = const ChildAdmissionEntity(),
    this.identityDocuments = const ChildIdentityDocumentsEntity(),
    this.physical = const ChildPhysicalEntity(),
    this.medical = const ChildMedicalEntity(),
    this.guardians = const [],
  });

  factory ChildDetailEntity.fromJson(Map<String, dynamic> json) => ChildDetailEntity(
        id: json['id'] as int,
        name: (json['name'] as String?) ?? '',
        firstName: (json['first_name'] as String?) ?? '',
        middleName: json['middle_name'] as String?,
        lastName: (json['last_name'] as String?) ?? '',
        admissionNo: json['admission_no'] as String?,
        rollNo: json['roll_no'] as String?,
        className: (json['class_name'] as String?) ?? '',
        sectionName: (json['section_name'] as String?) ?? '',
        photoUrl: json['photo_url'] as String?,
        gender: json['gender'] as String?,
        customGender: json['custom_gender'] as String?,
        dateOfBirth: json['date_of_birth'] as String?,
        bloodGroup: json['blood_group'] as String?,
        attendance: json['attendance'] != null
            ? AttendanceSummaryEntity.fromJson(json['attendance'] as Map<String, dynamic>)
            : const AttendanceSummaryEntity(present: 0, late: 0, absent: 0, halfDay: 0, total: 0, pct: null),
        recentMarks: ((json['recent_marks'] as List?) ?? const [])
            .map((e) => ExamMarkEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        behaviourPoints: json['behaviour_points'] as int? ?? 0,
        contact: json['contact'] != null ? ChildContactEntity.fromJson(json['contact'] as Map<String, dynamic>) : const ChildContactEntity(),
        address: json['address'] != null ? ChildAddressEntity.fromJson(json['address'] as Map<String, dynamic>) : const ChildAddressEntity(),
        background: json['background'] != null ? ChildBackgroundEntity.fromJson(json['background'] as Map<String, dynamic>) : const ChildBackgroundEntity(),
        admission: json['admission'] != null ? ChildAdmissionEntity.fromJson(json['admission'] as Map<String, dynamic>) : const ChildAdmissionEntity(),
        identityDocuments: json['identity_documents'] != null
            ? ChildIdentityDocumentsEntity.fromJson(json['identity_documents'] as Map<String, dynamic>)
            : const ChildIdentityDocumentsEntity(),
        physical: json['physical'] != null ? ChildPhysicalEntity.fromJson(json['physical'] as Map<String, dynamic>) : const ChildPhysicalEntity(),
        medical: json['medical'] != null ? ChildMedicalEntity.fromJson(json['medical'] as Map<String, dynamic>) : const ChildMedicalEntity(),
        guardians: ((json['guardians'] as List?) ?? const [])
            .map((e) => ChildGuardianEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

List<String> _stringList(dynamic value) => value is List ? value.map((e) => e.toString()).toList() : const [];

class ChildContactEntity {
  final String? phone;
  final String? email;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const ChildContactEntity({this.phone, this.email, this.emergencyContactName, this.emergencyContactPhone});

  factory ChildContactEntity.fromJson(Map<String, dynamic> json) => ChildContactEntity(
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        emergencyContactName: json['emergency_contact_name'] as String?,
        emergencyContactPhone: json['emergency_contact_phone'] as String?,
      );
}

class ChildAddressEntity {
  final String? addressLine;
  final String? landmark;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;

  const ChildAddressEntity({this.addressLine, this.landmark, this.city, this.district, this.state, this.pincode});

  factory ChildAddressEntity.fromJson(Map<String, dynamic> json) => ChildAddressEntity(
        addressLine: json['address_line'] as String?,
        landmark: json['landmark'] as String?,
        city: json['city'] as String?,
        district: json['district'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
      );
}

class ChildBackgroundEntity {
  final String? motherTongue;
  final String? otherMotherTongue;
  final String? religion;
  final String? nationality;
  final String? otherNationality;

  const ChildBackgroundEntity({this.motherTongue, this.otherMotherTongue, this.religion, this.nationality, this.otherNationality});

  factory ChildBackgroundEntity.fromJson(Map<String, dynamic> json) => ChildBackgroundEntity(
        motherTongue: json['mother_tongue'] as String?,
        otherMotherTongue: json['other_mother_tongue'] as String?,
        religion: json['religion'] as String?,
        nationality: json['nationality'] as String?,
        otherNationality: json['other_nationality'] as String?,
      );
}

class ChildAdmissionEntity {
  final String? admissionType;
  final String? previousSchoolName;
  final String? rteCertificateNo;
  final String? stream;
  final List<String> transportModes;
  final String? transportCustom;

  const ChildAdmissionEntity({
    this.admissionType,
    this.previousSchoolName,
    this.rteCertificateNo,
    this.stream,
    this.transportModes = const [],
    this.transportCustom,
  });

  factory ChildAdmissionEntity.fromJson(Map<String, dynamic> json) => ChildAdmissionEntity(
        admissionType: json['admission_type'] as String?,
        previousSchoolName: json['previous_school_name'] as String?,
        rteCertificateNo: json['rte_certificate_no'] as String?,
        stream: json['stream'] as String?,
        transportModes: _stringList(json['transport_modes']),
        transportCustom: json['transport_custom'] as String?,
      );
}

class ChildIdentityDocumentsEntity {
  final String? apaarId;
  final String? aadhaarNo;
  final String? pen;
  final String? digilockerMobile;
  final String? abcId;

  const ChildIdentityDocumentsEntity({this.apaarId, this.aadhaarNo, this.pen, this.digilockerMobile, this.abcId});

  factory ChildIdentityDocumentsEntity.fromJson(Map<String, dynamic> json) => ChildIdentityDocumentsEntity(
        apaarId: json['apaar_id'] as String?,
        aadhaarNo: json['aadhaar_no'] as String?,
        pen: json['pen'] as String?,
        digilockerMobile: json['digilocker_mobile'] as String?,
        abcId: json['abc_id'] as String?,
      );
}

class ChildPhysicalEntity {
  final double? heightCm;
  final double? weightKg;
  final String? eyeColour;
  final String? hairColour;
  final String? complexion;
  final String? build;
  final List<String> identityMarks;

  const ChildPhysicalEntity({
    this.heightCm,
    this.weightKg,
    this.eyeColour,
    this.hairColour,
    this.complexion,
    this.build,
    this.identityMarks = const [],
  });

  factory ChildPhysicalEntity.fromJson(Map<String, dynamic> json) => ChildPhysicalEntity(
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        eyeColour: json['eye_colour'] as String?,
        hairColour: json['hair_colour'] as String?,
        complexion: json['complexion'] as String?,
        build: json['build'] as String?,
        identityMarks: _stringList(json['identity_marks']),
      );
}

class ChildMedicalEntity {
  final String? vision;
  final List<String> medicalConditions;
  final List<String> allergies;
  final String? currentMedications;
  final String? treatingDoctor;
  final List<String> vaccinations;
  final String? medicalNotes;
  final bool isPwd;
  final List<String> disabilityTypes;
  final double? disabilityPercent;
  final List<String> disabilityAccommodations;
  final String? disabilityNotes;

  const ChildMedicalEntity({
    this.vision,
    this.medicalConditions = const [],
    this.allergies = const [],
    this.currentMedications,
    this.treatingDoctor,
    this.vaccinations = const [],
    this.medicalNotes,
    this.isPwd = false,
    this.disabilityTypes = const [],
    this.disabilityPercent,
    this.disabilityAccommodations = const [],
    this.disabilityNotes,
  });

  factory ChildMedicalEntity.fromJson(Map<String, dynamic> json) => ChildMedicalEntity(
        vision: json['vision'] as String?,
        medicalConditions: _stringList(json['medical_conditions']),
        allergies: _stringList(json['allergies']),
        currentMedications: json['current_medications'] as String?,
        treatingDoctor: json['treating_doctor'] as String?,
        vaccinations: _stringList(json['vaccinations']),
        medicalNotes: json['medical_notes'] as String?,
        isPwd: json['is_pwd'] as bool? ?? false,
        disabilityTypes: _stringList(json['disability_types']),
        disabilityPercent: (json['disability_percent'] as num?)?.toDouble(),
        disabilityAccommodations: _stringList(json['disability_accommodations']),
        disabilityNotes: json['disability_notes'] as String?,
      );
}

class ChildGuardianEntity {
  final int id;
  final String fullName;
  final String relation;
  final String? phone;
  final String? email;
  final String? occupation;
  final bool isPrimary;

  const ChildGuardianEntity({
    required this.id,
    required this.fullName,
    required this.relation,
    this.phone,
    this.email,
    this.occupation,
    this.isPrimary = false,
  });

  factory ChildGuardianEntity.fromJson(Map<String, dynamic> json) => ChildGuardianEntity(
        id: json['id'] as int,
        fullName: (json['full_name'] as String?) ?? '',
        relation: (json['relation'] as String?) ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        occupation: json['occupation'] as String?,
        isPrimary: json['is_primary'] as bool? ?? false,
      );
}

class AttendanceSummaryEntity {
  final int present;
  final int late;
  final int absent;
  final int halfDay;
  final int total;
  final double? pct;

  const AttendanceSummaryEntity({
    required this.present,
    required this.late,
    required this.absent,
    required this.halfDay,
    required this.total,
    this.pct,
  });

  factory AttendanceSummaryEntity.fromJson(Map<String, dynamic> json) => AttendanceSummaryEntity(
        present: json['present'] as int? ?? 0,
        late: json['late'] as int? ?? 0,
        absent: json['absent'] as int? ?? 0,
        halfDay: json['half_day'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        pct: (json['pct'] as num?)?.toDouble(),
      );
}

class ExamMarkEntity {
  final String subject;
  final String examName;
  final String term;
  final double obtained;
  final double fullMarks;
  final double passMarks;
  final bool absent;
  final String? examDate;

  const ExamMarkEntity({
    required this.subject,
    required this.examName,
    required this.term,
    required this.obtained,
    required this.fullMarks,
    required this.passMarks,
    required this.absent,
    this.examDate,
  });

  factory ExamMarkEntity.fromJson(Map<String, dynamic> json) => ExamMarkEntity(
        subject: (json['subject'] as String?) ?? '',
        examName: (json['exam_name'] as String?) ?? '',
        term: (json['term'] as String?) ?? '',
        obtained: (json['obtained'] as num?)?.toDouble() ?? 0.0,
        fullMarks: (json['full_marks'] as num?)?.toDouble() ?? 100.0,
        passMarks: (json['pass_marks'] as num?)?.toDouble() ?? 33.0,
        absent: json['absent'] as bool? ?? false,
        examDate: json['exam_date'] as String?,
      );
}
