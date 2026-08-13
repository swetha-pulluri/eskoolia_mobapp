/// `GET /api/v1/hr/staff/me/` — the same backend `apps.hr` `StaffSerializer`
/// response the web app's Settings > Staff Profile panel
/// (`StaffProfilePanel.tsx`) renders for a non-admin user (teachers never
/// have `human_resource.staff.view`, so they only ever hit this self-scoped
/// action, never the staff picker/detail-by-id branch of that component).
/// Field set matches that component's `StaffProfile` TypeScript interface
/// exactly — every field it declares is rendered somewhere in its JSX.
class TeacherProfileEntity {
  final int id;
  final String fullName;
  final String staffNo;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String emergencyMobile;
  final String gender;
  final String? dateOfBirth;
  final String maritalStatus;
  final String bloodGroup;
  final String nationality;
  final String status;
  final String? departmentName;
  final String? designationName;
  final String? roleName;
  final String contractType;
  final String? joinDate;
  final String qualification;
  final String experience;
  final String currentAddress;
  final String permanentAddress;
  final String city;
  final String state;
  final String epfNo;
  final String bankAccountName;
  final String bankAccountNo;
  final String bankName;
  final String bankBranch;
  final String basicSalary;

  const TeacherProfileEntity({
    this.id = 0,
    this.fullName = '',
    this.staffNo = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.emergencyMobile = '',
    this.gender = '',
    this.dateOfBirth,
    this.maritalStatus = '',
    this.bloodGroup = '',
    this.nationality = '',
    this.status = '',
    this.departmentName,
    this.designationName,
    this.roleName,
    this.contractType = '',
    this.joinDate,
    this.qualification = '',
    this.experience = '',
    this.currentAddress = '',
    this.permanentAddress = '',
    this.city = '',
    this.state = '',
    this.epfNo = '',
    this.bankAccountName = '',
    this.bankAccountNo = '',
    this.bankName = '',
    this.bankBranch = '',
    this.basicSalary = '',
  });

  /// Matches web's `profile.full_name || \`${first_name} ${last_name}\`` fallback.
  String get displayName => fullName.trim().isNotEmpty ? fullName.trim() : '$firstName $lastName'.trim();

  /// Matches web's avatar initials logic exactly — first letter of each
  /// word in the display name, up to 2, uppercased.
  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  /// Matches web's `[city, state].filter(Boolean).join(", ")`.
  String get cityState => [city, state].where((s) => s.trim().isNotEmpty).join(', ');

  factory TeacherProfileEntity.fromJson(Map<String, dynamic> json) {
    String s(String key) => json[key] as String? ?? '';
    return TeacherProfileEntity(
      id: json['id'] as int? ?? 0,
      fullName: s('full_name'),
      staffNo: s('staff_no'),
      firstName: s('first_name'),
      lastName: s('last_name'),
      email: s('email'),
      phone: s('phone'),
      emergencyMobile: s('emergency_mobile'),
      gender: s('gender'),
      dateOfBirth: json['date_of_birth'] as String?,
      maritalStatus: s('marital_status'),
      bloodGroup: s('blood_group'),
      nationality: s('nationality'),
      status: s('status'),
      departmentName: json['department_name'] as String?,
      designationName: json['designation_name'] as String?,
      roleName: json['role_name'] as String?,
      contractType: s('contract_type'),
      joinDate: json['join_date'] as String?,
      qualification: s('qualification'),
      experience: s('experience'),
      currentAddress: s('current_address'),
      permanentAddress: s('permanent_address'),
      city: s('city'),
      state: s('state'),
      epfNo: s('epf_no'),
      bankAccountName: s('bank_account_name'),
      bankAccountNo: s('bank_account_no'),
      bankName: s('bank_name'),
      bankBranch: s('bank_branch'),
      basicSalary: json['basic_salary']?.toString() ?? '',
    );
  }
}
