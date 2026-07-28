/// Blocking "Next" validators, ported from the real web's `goNext()` +
/// per-step `validatorRef`s (`hr/onboard/page.tsx` on `demo`/`BugFix`).
/// Returns a list of human-readable blocking messages — empty means the
/// step may advance. Step 9 (Documents) is validated separately by the page
/// itself since it needs the live uploaded-documents list, not the form map.
library;

final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
final _phone10Regex = RegExp(r'^\d{10}$');
final _pinRegex = RegExp(r'^\d{5,6}$');
final _aadhaarRegex = RegExp(r'^\d{12}$');
final _panRegex = RegExp(r'^[A-Z]{5}\d{4}[A-Z]$');
final _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

String _s(Map<String, dynamic> form, String key) => (form[key] as String? ?? '').trim();

DateTime? _date(Map<String, dynamic> form, String key) {
  final raw = form[key] as String?;
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<String> validateOnboardStep(int step, Map<String, dynamic> form) {
  switch (step) {
    case 1:
      return _validateStep1(form);
    case 2:
      return _validateStep2(form);
    case 3:
      return _validateStep3(form);
    case 4:
      return _validateStep4(form);
    case 5:
      return _validateStep5(form);
    case 6:
      return _validateStep6(form);
    case 7:
      return _validateStep7(form);
    case 8:
      return _validateStep8(form);
    default:
      return const [];
  }
}

List<String> _validateStep1(Map<String, dynamic> form) {
  final errors = <String>[];
  if (_s(form, 'status') == 'inactive') errors.add('Status cannot be Inactive for a new staff member.');
  if (_s(form, 'first_name').isEmpty) errors.add('First Name is required.');
  if (_s(form, 'last_name').isEmpty) errors.add('Last Name is required.');
  final dob = _date(form, 'date_of_birth');
  if (dob == null) {
    errors.add('Date of Birth is required.');
  } else {
    final now = DateTime.now();
    final age = now.difference(dob).inDays / 365.25;
    if (dob.isAfter(now)) errors.add('Date of Birth cannot be in the future.');
    if (age < 18) errors.add('Staff must be at least 18 years old.');
    if (age > 70) errors.add('Date of Birth is out of the allowed range.');
  }
  if (_s(form, 'gender').isEmpty) errors.add('Gender is required.');
  if (_s(form, 'nationality').isEmpty) errors.add('Nationality is required.');
  return errors;
}

List<String> _validateStep2(Map<String, dynamic> form) {
  final errors = <String>[];
  if (_s(form, 'department').isEmpty) errors.add('Department is required.');
  if (_s(form, 'designation').isEmpty) errors.add('Designation is required.');
  if (_s(form, 'role').isEmpty) errors.add('Role / Access is required.');
  if (_s(form, 'employment_type').isEmpty && _s(form, 'employment_type_other').isEmpty) errors.add('Employment Type is required.');
  final joining = _date(form, 'joining_date');
  final dob = _date(form, 'date_of_birth');
  if (joining == null) {
    errors.add('Joining Date is required.');
  } else {
    if (joining.isAfter(DateTime.now())) errors.add('Joining Date cannot be in the future.');
    if (dob != null) {
      if (!joining.isAfter(dob)) errors.add('Joining Date must be after Date of Birth.');
      final ageAtJoining = joining.difference(dob).inDays / 365.25;
      if (ageAtJoining < 18) errors.add('Staff must be at least 18 years old at joining.');
    }
  }
  return errors;
}

List<String> _validateStep3(Map<String, dynamic> form) {
  final errors = <String>[];
  if (!_phone10Regex.hasMatch(_s(form, 'mobile'))) errors.add('A valid 10-digit Mobile number is required.');
  final personalEmail = _s(form, 'personal_email');
  if (personalEmail.isEmpty || !_emailRegex.hasMatch(personalEmail)) errors.add('A valid Personal Email is required.');
  final officialEmail = _s(form, 'official_email');
  if (officialEmail.isNotEmpty && !_emailRegex.hasMatch(officialEmail)) errors.add('Official Email is not a valid email address.');
  if (_s(form, 'preferred_communication').isEmpty) errors.add('Preferred Communication is required.');
  if (_s(form, 'current_address').isEmpty) errors.add('Address Line 1 is required.');
  if (_s(form, 'city').isEmpty) errors.add('City is required.');
  if (_s(form, 'state').isEmpty) errors.add('State is required.');
  if (!_pinRegex.hasMatch(_s(form, 'current_pin'))) errors.add('A valid 5-6 digit PIN Code is required.');
  return errors;
}

List<String> _validateStep4(Map<String, dynamic> form) {
  final errors = <String>[];
  if (_s(form, 'marital_status') == 'Married' && _s(form, 'spouse_parent_name').isEmpty) {
    errors.add('Spouse Name is required when Marital Status is Married.');
  }
  final emergencyContacts = (form['emergency_contacts'] as List?) ?? const [];
  final row0 = emergencyContacts.isNotEmpty ? emergencyContacts.first as Map? : null;
  final name0 = (row0?['name'] as String? ?? _s(form, 'emergency_name'));
  final relation0 = (row0?['relationship'] as String? ?? _s(form, 'emergency_relation'));
  final mobile0 = (row0?['mobile'] as String? ?? _s(form, 'emergency_phone'));
  if (name0.trim().isEmpty) errors.add('At least one Emergency Contact name is required.');
  if (relation0.trim().isEmpty) errors.add('The first Emergency Contact\'s relationship is required.');
  if (!_phone10Regex.hasMatch(mobile0.trim())) errors.add('The first Emergency Contact needs a valid 10-digit mobile number.');
  final nominees = (form['nominees'] as List?) ?? const [];
  if (nominees.isNotEmpty) {
    final totalShare = nominees.fold<double>(0, (sum, n) => sum + (double.tryParse((n as Map)['share']?.toString() ?? '0') ?? 0));
    if ((totalShare - 100).abs() > 0.01) errors.add('Nominee shares must add up to 100%.');
  }
  return errors;
}

List<String> _validateStep5(Map<String, dynamic> form) {
  final errors = <String>[];
  if (!_aadhaarRegex.hasMatch(_s(form, 'nin'))) errors.add('A valid 12-digit Aadhaar Number is required.');
  if (!_panRegex.hasMatch(_s(form, 'pan'))) errors.add('A valid PAN Number is required.');
  final ifsc = _s(form, 'ifsc_code');
  if (!_ifscRegex.hasMatch(ifsc)) errors.add('A valid IFSC Code is required.');
  if (_s(form, 'bank_account_no').isEmpty) errors.add('Account Number is required.');
  if (_s(form, 'bank_name').isEmpty) errors.add('Bank Name is required.');
  if (_s(form, 'bank_account_name').isEmpty) errors.add('Account Holder Name is required.');
  return errors;
}

List<String> _validateStep6(Map<String, dynamic> form) {
  final errors = <String>[];
  final rows = (form['previous_employment'] as List?) ?? const [];
  final joining = _date(form, 'joining_date');
  final dob = _date(form, 'date_of_birth');
  for (final raw in rows) {
    final row = raw as Map;
    final employer = (row['employer'] as String? ?? '').trim();
    if (employer.isEmpty) continue;
    final from = row['from_date'] != null ? DateTime.tryParse(row['from_date'].toString()) : null;
    final to = row['to_date'] != null ? DateTime.tryParse(row['to_date'].toString()) : null;
    if (from == null || to == null) {
      errors.add('Previous employment at "$employer" needs both From and To dates.');
      continue;
    }
    if (from.isAfter(DateTime.now()) || to.isAfter(DateTime.now())) {
      errors.add('Previous employment dates at "$employer" cannot be in the future.');
    }
    if (dob != null && from.difference(dob).inDays / 365.25 < 18) {
      errors.add('Previous employment at "$employer" cannot start before age 18.');
    }
    if (joining != null && (from.isAfter(joining) || to.isAfter(joining))) {
      errors.add('Previous employment at "$employer" must end before the new Joining Date.');
    }
    if (to.isBefore(from)) errors.add('Previous employment at "$employer": To date must be after From date.');
  }
  return errors;
}

List<String> _validateStep7(Map<String, dynamic> form) {
  final errors = <String>[];
  final disabilityStatus = _s(form, 'disability_status');
  if (disabilityStatus.isNotEmpty && disabilityStatus != 'None') {
    if (_s(form, 'disability_cert_no').isEmpty) errors.add('Disability Certificate Number is required.');
    if (_s(form, 'disability_pct').isEmpty) errors.add('Disability Percentage is required.');
    if (_s(form, 'disability_authority').isEmpty) errors.add('Disability Certifying Authority is required.');
  }
  return errors;
}

List<String> _validateStep8(Map<String, dynamic> form) {
  final errors = <String>[];
  final basic = double.tryParse(_s(form, 'basic_salary_input'));
  if (basic == null || basic < 1 || basic > 999999) errors.add('Basic Salary is required (1 - 999,999).');
  return errors;
}
