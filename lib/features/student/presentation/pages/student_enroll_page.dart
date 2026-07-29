import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/enrollment_draft_store.dart';
import '../../domain/models/academic_year.dart';
import '../../domain/models/enrollment_draft.dart';
import '../../domain/models/guardian_draft.dart';
import '../../domain/models/school_class.dart';
import '../../domain/models/student_data.dart';
import '../providers/student_providers.dart';
import '../utils/camera_capture_helper.dart';
import '../utils/enrollment_pdf.dart';
import '../utils/photo_compress_helper.dart';
import '../widgets/enroll_form_fields.dart';
import '../widgets/student_ai_assist_dialog.dart';
import '../widgets/student_draft_saved_dialog.dart';
import '../widgets/student_drafts_dialog.dart';
import '../widgets/student_enroll_checklist_dialog.dart';
import 'student_verification_form_page.dart';

class _NavItem {
  final String id;
  final String label;
  final String description;
  final EnrollBadge? badge;
  final bool startsGroup;
  const _NavItem(this.id, this.label, this.description, {this.badge, this.startsGroup = false});
}

const List<_NavItem> _navItems = [
  _NavItem('identity', 'Student identity', 'Basic profile, DOB, photo'),
  _NavItem('academic', 'Academic placement', 'Class, section, year'),
  _NavItem('contact', 'Contact & address', 'Phone, email, location'),
  _NavItem('guardians', 'Family & guardians', 'Parent/guardian details'),
  _NavItem('apaar', 'Government identity', 'Government identity', badge: EnrollBadge.goi),
  _NavItem('documents', 'Documents', 'Consent and student records'),
  _NavItem('medical', 'Medical & emergency', 'Health, vaccinations', badge: EnrollBadge.newBadge, startsGroup: true),
  _NavItem('speciallyAbled', 'Specially abled', 'PwD accommodations', badge: EnrollBadge.newBadge),
  _NavItem('identityMarks', 'Identity marks', 'Physical identifiers', badge: EnrollBadge.sensitive),
  _NavItem('fees', 'Fee plan', 'Assign fees & concessions'),
  _NavItem('review', 'Review', 'Confirm & enroll'),
];

/// Mirrors StudentAddPanel.tsx's `MOTHER_TONGUES` array exactly (verbatim
/// order), plus its trailing "Other" free-text reveal.
const List<String> kMotherTongueOptions = [
  'Hindi', 'English', 'Bengali', 'Telugu', 'Marathi', 'Tamil', 'Urdu', 'Gujarati', 'Kannada', 'Malayalam',
  'Odia', 'Punjabi', 'Assamese', 'Maithili', 'Sanskrit', 'Konkani', 'Nepali', 'Sindhi', 'Dogri', 'Manipuri',
  'Bodo', 'Santali', 'Kashmiri', 'Other',
];

/// Mirrors StudentAddPanel.tsx's religion `<select>` exactly — "Prefer not
/// to say" is the default value (not a blank placeholder).
const List<String> kReligionOptions = [
  'Prefer not to say', 'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other',
];

/// Mirrors StudentAddPanel.tsx's nationality `<select>` exactly.
const List<String> kNationalityOptions = ['Indian', 'Nepali', 'Bhutanese', 'Other'];

/// Mirrors StudentAddPanel.tsx's admission-type `<select>` exactly (4
/// options, not the generic "New/Transfer/Readmission" 3-option guess).
const List<String> kAdmissionTypeOptions = ['New admission', 'Transfer', 'Re-admission', 'RTE Quota'];

/// Student Enroll Page — mirrors frontend components/students/
/// StudentAddPanel.tsx: hero header + KPI, scan-to-prefill banner, an
/// 11-section form (left-nav on desktop), and a sticky footer with a
/// progress bar and the primary "Enroll student →" action.
///
/// Mobile adaptation (disclosed): the frontend's 280px sticky left sidebar
/// is desktop-only real estate. Its data/interactions (numbered steps,
/// locked-until-reached, active highlight, descriptions, group badges) are
/// preserved but reflowed into a horizontally-scrollable step strip at the
/// top — the standard mobile equivalent of a step sidebar — rather than
/// stacking 11 nav rows above the content on every section.
///
/// Scope note: the hero action bar's Drafts / AI Assist / PDF / "What I'll
/// need" buttons are fully wired — see `_saveDraftSnapshot`,
/// `StudentAiAssistDialog`, `StudentVerificationFormPage`, and
/// `StudentEnrollChecklistDialog`. OCR "Scan & fill" and the consent form's
/// secondary flows (upload-signed-copy, blank-form email/WhatsApp/
/// digital-fill) remain a disclosed "coming soon" — see
/// `enrollment_pdf.dart`'s doc comment for the scope line drawn there.
class StudentEnrollPage extends ConsumerStatefulWidget {
  final StudentData? editingStudent;

  const StudentEnrollPage({super.key, this.editingStudent});

  @override
  ConsumerState<StudentEnrollPage> createState() => _StudentEnrollPageState();
}

class _StudentEnrollPageState extends ConsumerState<StudentEnrollPage> {
  int _activeIndex = 0;
  int _maxReachedIndex = 0;
  bool _saving = false;
  String? _error;
  bool _loadingLookups = true;
  int? _currentEnrolledCount;
  bool _scanBannerDismissed = false;

  // Drafts — mirrors StudentAddPanel.tsx's `students:add:drafts:v2`
  // localStorage-only persistence (see EnrollmentDraftStore).
  final _draftStore = EnrollmentDraftStore();
  String? _currentDraftId;
  bool _draftSaving = false;

  List<AcademicYear> _academicYears = [];
  List<SchoolClass> _classes = [];
  List<StudentCategory> _categories = [];

  // Identity
  final _admissionNoController = TextEditingController();
  bool _admissionNoLocked = true;
  bool _isActive = true;
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  StudentGender? _gender;
  String? _bloodGroup;
  String? _motherTongue;
  final _motherTongueOtherController = TextEditingController();
  String? _religion = 'Prefer not to say';
  final _religionOtherController = TextEditingController();
  String? _nationality = 'Indian';
  final _nationalityOtherController = TextEditingController();
  String? _dobError;

  // Academic
  int? _academicYearId;
  int? _classId;
  int? _sectionId;
  int? _categoryId;
  String _admissionType = 'New admission';
  final _previousSchoolNameController = TextEditingController();
  final _rteCertificateController = TextEditingController();

  // Contact
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _landmarkController = TextEditingController();
  final List<String> _transportModes = [];
  final _customTransportController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Guardians
  final List<GuardianDraft> _guardians = [
    GuardianDraft(clientId: '1', isPrimary: true),
  ];

  // Government identity
  final _apaarIdController = TextEditingController();
  final _aadhaarController = TextEditingController();
  bool _aadhaarVisible = false;
  final _penUdiseController = TextEditingController();
  final _digilockerMobileController = TextEditingController();
  final _abcIdController = TextEditingController();

  // Photo
  String? _photoUrl;
  Uint8List? _photoPreviewBytes;
  bool _photoUploading = false;
  String? _photoError;

  bool get _hasPhoto => _photoUrl != null || _photoPreviewBytes != null;

  // Documents — upload is only wired to the backend once a real student id
  // exists (edit mode); a brand-new enrollment has no id yet (the frontend's
  // own upload flow relies on a server-assigned draft id this pass doesn't
  // reproduce), so document upload during new enrollment stays a disclosed
  // "coming soon" and `_documentsUploaded` stays a local-only toggle there.
  final Map<String, bool> _documentsUploaded = {
    'birth_certificate': false,
    'aadhaar': false,
    'caste_certificate': false,
    'disability_certificate': false,
    'medical_info': false,
    'transfer_certificate': false,
  };
  final Map<String, bool> _documentsUploading = {};
  bool _consentChecked = false;

  // Medical
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  // Specially abled
  bool _isPwD = false;
  final _pwdNotesController = TextEditingController();

  // Identity marks
  final _identityMark1Controller = TextEditingController();
  final _identityMark2Controller = TextEditingController();
  final _birthmarkController = TextEditingController();

  // Fees
  String? _feeGroup;
  String? _concession;

  // Review
  bool _reviewConfirmed = false;

  bool get isEditMode => widget.editingStudent != null;

  @override
  void initState() {
    super.initState();
    _loadLookups();
    final editing = widget.editingStudent;
    if (editing != null) {
      _admissionNoController.text = editing.admissionNo;
      _firstNameController.text = editing.firstName;
      _lastNameController.text = editing.lastName;
      final dob = editing.dateOfBirth;
      if (dob != null) {
        _dobController.text =
            '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
      }
      _gender = editing.gender;
      _isActive = editing.isActive;
      _phoneController.text = editing.phone ?? '';
      _emailController.text = editing.email ?? '';
      _addressController.text = editing.addressLine ?? '';
      _cityController.text = editing.city ?? '';
      _districtController.text = editing.district ?? '';
      _stateController.text = editing.state ?? '';
      _pincodeController.text = editing.pincode ?? '';
      _classId = editing.classId;
      _sectionId = editing.sectionId;
      _academicYearId = editing.academicYearId;
      _categoryId = editing.categoryId;
      _photoUrl = editing.photoUrl;
      if ((editing.guardianName ?? '').isNotEmpty) {
        _guardians[0].fullName = editing.guardianName!;
        _guardians[0].phone = editing.guardianPhone ?? '';
        _guardians[0].relation =
            editing.guardianRelation?.trim().isNotEmpty == true ? editing.guardianRelation! : 'Father';
      }
      _maxReachedIndex = _navItems.length - 1;
    }
  }

  Future<void> _loadLookups() async {
    final repo = ref.read(studentRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.fetchAcademicYears(),
        repo.fetchClasses(),
        repo.fetchCategories(),
        repo.fetchNextAdmissionNo(),
      ]);
      if (!mounted) return;
      setState(() {
        _academicYears = results[0] as List<AcademicYear>;
        _classes = results[1] as List<SchoolClass>;
        _categories = results[2] as List<StudentCategory>;
        if (!isEditMode) {
          _admissionNoController.text = results[3] as String;
        }
        _academicYearId ??= _academicYears.where((y) => y.isCurrent).firstOrNull?.id;
        _loadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLookups = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    try {
      final stats = await repo.fetchStats();
      if (!mounted) return;
      setState(() => _currentEnrolledCount = stats.totalCount);
    } catch (_) {
      // Non-critical KPI text — leave it at its "…"/default state rather
      // than blocking the form with an error for a secondary display value.
    }
  }

  @override
  void dispose() {
    _admissionNoController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _motherTongueOtherController.dispose();
    _religionOtherController.dispose();
    _nationalityOtherController.dispose();
    _previousSchoolNameController.dispose();
    _rteCertificateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    _customTransportController.dispose();
    _apaarIdController.dispose();
    _aadhaarController.dispose();
    _penUdiseController.dispose();
    _digilockerMobileController.dispose();
    _abcIdController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _emergencyContactController.dispose();
    _pwdNotesController.dispose();
    _identityMark1Controller.dispose();
    _identityMark2Controller.dispose();
    _birthmarkController.dispose();
    super.dispose();
  }

  double get _progress => (_maxReachedIndex + 1) / _navItems.length;

  void _goToIndex(int index) {
    if (index > _maxReachedIndex + 1) return; // locked
    setState(() => _activeIndex = index);
  }

  void _next() {
    setState(() {
      if (_activeIndex < _navItems.length - 1) {
        _activeIndex++;
        if (_activeIndex > _maxReachedIndex) _maxReachedIndex = _activeIndex;
      }
    });
  }

  void _prev() {
    setState(() {
      if (_activeIndex > 0) _activeIndex--;
    });
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  /// Resolves a "Select ... / Other" dropdown + its free-text reveal down to
  /// the single effective string StudentAddPanel.tsx would submit.
  String get _motherTongueEffective => _motherTongue == 'Other' ? _motherTongueOtherController.text.trim() : (_motherTongue ?? '');
  String get _religionEffective => _religion == 'Other' ? _religionOtherController.text.trim() : (_religion ?? 'Prefer not to say');
  String get _nationalityEffective => _nationality == 'Other' ? _nationalityOtherController.text.trim() : (_nationality ?? '');

  // ══════════════════════════════════════════════════════════════════════
  // HERO ACTION BAR — Drafts / AI Assist / PDF / What I'll need
  // ══════════════════════════════════════════════════════════════════════

  String get _schoolName {
    final authState = ref.read(authNotifierProvider);
    final name = authState.maybeWhen(authenticated: (user) => user.schoolName, orElse: () => null);
    return (name == null || name.trim().isEmpty) ? 'Eskoolia School' : name;
  }

  Map<String, dynamic> _buildDraftSnapshotData() {
    return {
      'admissionNo': _admissionNoController.text.trim(),
      'admissionNoLocked': _admissionNoLocked,
      'isActive': _isActive,
      'firstName': _firstNameController.text.trim(),
      'middleName': _middleNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'dob': _dobController.text.trim(),
      'gender': _gender?.name,
      'bloodGroup': _bloodGroup,
      'motherTongue': _motherTongue,
      'motherTongueOther': _motherTongueOtherController.text.trim(),
      'religion': _religion,
      'religionOther': _religionOtherController.text.trim(),
      'nationality': _nationality,
      'nationalityOther': _nationalityOtherController.text.trim(),
      'academicYearId': _academicYearId,
      'classId': _classId,
      'sectionId': _sectionId,
      'categoryId': _categoryId,
      'admissionType': _admissionType,
      'previousSchoolName': _previousSchoolNameController.text.trim(),
      'rteCertificateNo': _rteCertificateController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'transportModes': _transportModes,
      'guardians': _guardians
          .map((g) => {
                'clientId': g.clientId,
                'isPrimary': g.isPrimary,
                'fullName': g.fullName,
                'relation': g.relation,
                'phone': g.phone,
                'email': g.email,
                'occupation': g.occupation,
              })
          .toList(),
      'apaarId': _apaarIdController.text.trim(),
      'aadhaar': _aadhaarController.text.trim(),
      'penUdise': _penUdiseController.text.trim(),
      'digilockerMobile': _digilockerMobileController.text.trim(),
      'abcId': _abcIdController.text.trim(),
      'photoUrl': _photoUrl,
      'documentsUploaded': _documentsUploaded,
      'consentChecked': _consentChecked,
      'allergies': _allergiesController.text.trim(),
      'medications': _medicationsController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim(),
      'isPwD': _isPwD,
      'pwdNotes': _pwdNotesController.text.trim(),
      'identityMark1': _identityMark1Controller.text.trim(),
      'identityMark2': _identityMark2Controller.text.trim(),
      'birthmark': _birthmarkController.text.trim(),
      'feeGroup': _feeGroup,
      'concession': _concession,
      'reviewConfirmed': _reviewConfirmed,
    };
  }

  /// Mirrors `saveDraftSnapshot()`: upserts the current form state into the
  /// multi-draft list, keyed by admission no. so repeat saves of the same
  /// in-progress enrollment replace the same entry rather than duplicating.
  Future<void> _saveDraftSnapshot() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    _currentDraftId ??= 'draft-${DateTime.now().millisecondsSinceEpoch}';
    final label = '${firstName.isEmpty ? 'Unnamed' : firstName} $lastName'.trim();
    final draft = EnrollmentDraft(
      id: _currentDraftId!,
      savedAt: DateTime.now().millisecondsSinceEpoch,
      label: label,
      admissionNo: _admissionNoController.text.trim(),
      firstName: firstName,
      lastName: lastName,
      classId: _classId,
      maxReachedIndex: _maxReachedIndex,
      activeIndex: _activeIndex,
      data: _buildDraftSnapshotData(),
    );
    await _draftStore.upsert(draft);
    if (mounted) setState(() {}); // refresh the Drafts button's badge count
  }

  /// Entry point used by the AI Assist panel's quick actions — toast only,
  /// no confirmation modal (mirrors `saveDraftSnapshot()` + `showToast(...)`
  /// call sites, as opposed to the footer button's `saveDraftNow()`).
  Future<void> _saveDraftWithToast() async {
    await _saveDraftSnapshot();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved.'), backgroundColor: Color(0xFF10B981), duration: Duration(seconds: 3)),
    );
  }

  /// Footer "Save draft" button — mirrors `saveDraftNow()`: briefly flashes
  /// the breadcrumb dot to "Saving…" then shows the full "Draft saved!"
  /// confirmation dialog.
  Future<void> _saveDraftFromFooter() async {
    setState(() => _draftSaving = true);
    await _saveDraftSnapshot();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _draftSaving = false);
    showDialog(
      context: context,
      builder: (context) => StudentDraftSavedDialog(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        onEnrollAnother: _resetFormForNewEnrollment,
        onGoToList: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  /// "Enroll another student (fresh form)" — mirrors `clearDraftNow()`:
  /// resets every field and re-fetches a fresh auto-generated admission no.
  void _resetFormForNewEnrollment() {
    setState(() {
      _admissionNoController.clear();
      _admissionNoLocked = true;
      _isActive = true;
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _dobController.clear();
      _gender = null;
      _bloodGroup = null;
      _motherTongue = null;
      _motherTongueOtherController.clear();
      _religion = 'Prefer not to say';
      _religionOtherController.clear();
      _nationality = 'Indian';
      _nationalityOtherController.clear();
      _dobError = null;
      _academicYearId = _academicYears.where((y) => y.isCurrent).firstOrNull?.id;
      _classId = null;
      _sectionId = null;
      _categoryId = null;
      _admissionType = 'New admission';
      _previousSchoolNameController.clear();
      _rteCertificateController.clear();
      _phoneController.clear();
      _emailController.clear();
      _addressController.clear();
      _cityController.clear();
      _districtController.clear();
      _landmarkController.clear();
      _transportModes.clear();
      _stateController.clear();
      _pincodeController.clear();
      _guardians
        ..clear()
        ..add(GuardianDraft(clientId: '1', isPrimary: true));
      _apaarIdController.clear();
      _aadhaarController.clear();
      _aadhaarVisible = false;
      _penUdiseController.clear();
      _digilockerMobileController.clear();
      _abcIdController.clear();
      _photoUrl = null;
      _photoPreviewBytes = null;
      _photoError = null;
      _documentsUploaded.updateAll((key, value) => false);
      _documentsUploading.clear();
      _consentChecked = false;
      _allergiesController.clear();
      _medicationsController.clear();
      _emergencyContactController.clear();
      _isPwD = false;
      _pwdNotesController.clear();
      _identityMark1Controller.clear();
      _identityMark2Controller.clear();
      _birthmarkController.clear();
      _feeGroup = null;
      _concession = null;
      _reviewConfirmed = false;
      _activeIndex = 0;
      _maxReachedIndex = 0;
      _currentDraftId = null;
      _error = null;
    });
    _loadLookups();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft cleared.'), backgroundColor: Color(0xFF10B981), duration: Duration(seconds: 4)),
    );
  }

  /// "Resume" on a saved draft card — mirrors `restoreDraftFromObject()`.
  void _resumeFromDraft(EnrollmentDraft draft) {
    final data = draft.data;
    setState(() {
      _admissionNoController.text = (data['admissionNo'] as String?) ?? '';
      _admissionNoLocked = (data['admissionNoLocked'] as bool?) ?? true;
      _isActive = (data['isActive'] as bool?) ?? true;
      _firstNameController.text = (data['firstName'] as String?) ?? '';
      _middleNameController.text = (data['middleName'] as String?) ?? '';
      _lastNameController.text = (data['lastName'] as String?) ?? '';
      _dobController.text = (data['dob'] as String?) ?? '';
      final genderName = data['gender'] as String?;
      _gender = genderName == null ? null : StudentGender.values.where((g) => g.name == genderName).firstOrNull;
      _bloodGroup = data['bloodGroup'] as String?;
      _motherTongue = data['motherTongue'] as String?;
      _motherTongueOtherController.text = (data['motherTongueOther'] as String?) ?? '';
      _religion = (data['religion'] as String?) ?? 'Prefer not to say';
      _religionOtherController.text = (data['religionOther'] as String?) ?? '';
      _nationality = (data['nationality'] as String?) ?? 'Indian';
      _nationalityOtherController.text = (data['nationalityOther'] as String?) ?? '';
      _academicYearId = (data['academicYearId'] as num?)?.toInt();
      _classId = (data['classId'] as num?)?.toInt();
      _sectionId = (data['sectionId'] as num?)?.toInt();
      _categoryId = (data['categoryId'] as num?)?.toInt();
      _admissionType = (data['admissionType'] as String?) ?? 'New admission';
      _previousSchoolNameController.text = (data['previousSchoolName'] as String?) ?? '';
      _rteCertificateController.text = (data['rteCertificateNo'] as String?) ?? '';
      _phoneController.text = (data['phone'] as String?) ?? '';
      _emailController.text = (data['email'] as String?) ?? '';
      _addressController.text = (data['address'] as String?) ?? '';
      _cityController.text = (data['city'] as String?) ?? '';
      _districtController.text = (data['district'] as String?) ?? '';
      _stateController.text = (data['state'] as String?) ?? '';
      _pincodeController.text = (data['pincode'] as String?) ?? '';
      _landmarkController.text = (data['landmark'] as String?) ?? '';
      _transportModes
        ..clear()
        ..addAll(((data['transportModes'] as List?) ?? const []).map((e) => e.toString()));
      final guardiansData = (data['guardians'] as List?) ?? const [];
      _guardians.clear();
      if (guardiansData.isEmpty) {
        _guardians.add(GuardianDraft(clientId: '1', isPrimary: true));
      } else {
        for (final raw in guardiansData) {
          final map = raw as Map;
          _guardians.add(GuardianDraft(
            clientId: (map['clientId'] as String?) ?? '${_guardians.length + 1}',
            isPrimary: (map['isPrimary'] as bool?) ?? false,
            fullName: (map['fullName'] as String?) ?? '',
            relation: (map['relation'] as String?) ?? 'Father',
            phone: (map['phone'] as String?) ?? '',
            email: (map['email'] as String?) ?? '',
            occupation: (map['occupation'] as String?) ?? '',
          ));
        }
      }
      _apaarIdController.text = (data['apaarId'] as String?) ?? '';
      _aadhaarController.text = (data['aadhaar'] as String?) ?? '';
      _penUdiseController.text = (data['penUdise'] as String?) ?? '';
      _digilockerMobileController.text = (data['digilockerMobile'] as String?) ?? '';
      _abcIdController.text = (data['abcId'] as String?) ?? '';
      _photoUrl = data['photoUrl'] as String?;
      final docsData = (data['documentsUploaded'] as Map?)?.cast<String, dynamic>();
      if (docsData != null) {
        for (final key in _documentsUploaded.keys.toList()) {
          _documentsUploaded[key] = (docsData[key] as bool?) ?? false;
        }
      }
      _consentChecked = (data['consentChecked'] as bool?) ?? false;
      _allergiesController.text = (data['allergies'] as String?) ?? '';
      _medicationsController.text = (data['medications'] as String?) ?? '';
      _emergencyContactController.text = (data['emergencyContact'] as String?) ?? '';
      _isPwD = (data['isPwD'] as bool?) ?? false;
      _pwdNotesController.text = (data['pwdNotes'] as String?) ?? '';
      _identityMark1Controller.text = (data['identityMark1'] as String?) ?? '';
      _identityMark2Controller.text = (data['identityMark2'] as String?) ?? '';
      _birthmarkController.text = (data['birthmark'] as String?) ?? '';
      _feeGroup = data['feeGroup'] as String?;
      _concession = data['concession'] as String?;
      _reviewConfirmed = (data['reviewConfirmed'] as bool?) ?? false;
      _maxReachedIndex = draft.maxReachedIndex.clamp(0, _navItems.length - 1);
      _activeIndex = draft.activeIndex.clamp(0, _navItems.length - 1);
      _currentDraftId = draft.id;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded "${draft.label}". Continue from where you stopped.'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openDraftsDialog() {
    showDialog(
      context: context,
      builder: (context) => StudentDraftsDialog(totalSteps: _navItems.length - 1, onResume: _resumeFromDraft),
    );
  }

  /// Mirrors `isStepComplete()`'s 6-of-10 field checks, feeding the AI
  /// Assist panel's completion ring/tips.
  EnrollAiSnapshot _buildAiSnapshot() {
    return EnrollAiSnapshot(
      identityComplete: _firstNameController.text.trim().isNotEmpty &&
          _lastNameController.text.trim().isNotEmpty &&
          _dobController.text.trim().isNotEmpty,
      academicComplete: _academicYearId != null && _classId != null && _sectionId != null,
      contactComplete: _phoneController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty &&
          _stateController.text.trim().isNotEmpty &&
          _cityController.text.trim().isNotEmpty &&
          _pincodeController.text.trim().isNotEmpty,
      guardiansComplete: _guardians.isNotEmpty && _guardians[0].fullName.trim().isNotEmpty && _guardians[0].phone.trim().isNotEmpty,
      documentsComplete: _consentChecked,
      feesComplete: _feeGroup != null,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      dob: _dobController.text,
      phone: _phoneController.text,
      pincode: _pincodeController.text,
      guardianFullName: _guardians.isNotEmpty ? _guardians[0].fullName : '',
    );
  }

  void _jumpToSectionId(String sectionId) {
    final idx = _navItems.indexWhere((item) => item.id == sectionId);
    if (idx < 0) return;
    setState(() {
      _activeIndex = idx;
      if (idx > _maxReachedIndex) _maxReachedIndex = idx;
    });
  }

  void _openAiAssistDialog() {
    showDialog(
      context: context,
      builder: (context) => StudentAiAssistDialog(
        snapshot: _buildAiSnapshot(),
        onJumpToSection: _jumpToSectionId,
        onSaveDraft: _saveDraftWithToast,
        onViewDrafts: _openDraftsDialog,
        onPreviewPdf: _previewEnrollmentPdf,
      ),
    );
  }

  void _openChecklistDialog() {
    showDialog(
      context: context,
      builder: (context) => StudentEnrollChecklistDialog(schoolName: _schoolName),
    );
  }

  bool get _canPreviewPdf =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _admissionNoController.text.trim().isNotEmpty &&
      _classId != null &&
      _sectionId != null;

  /// Mirrors the hero "PDF" button / footer "🖨 Print / PDF" button opening
  /// `ConsentForm.tsx` with no initial action — its default view IS the
  /// Student Verification Form, ready to print. See
  /// `enrollment_pdf.dart`'s doc comment for the field-mapping/scope notes.
  Future<void> _previewEnrollmentPdf() async {
    final data = _buildVerificationPdfData();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => StudentVerificationFormPage(data: data)),
    );
  }

  EnrollmentPdfData _buildVerificationPdfData() {
    final schoolClass = _classes.where((c) => c.id == _classId).firstOrNull;
    final section = schoolClass?.sections.where((s) => s.id == _sectionId).firstOrNull;
    final academicYear = _academicYears.where((y) => y.id == _academicYearId).firstOrNull;
    final category = _categories.where((c) => c.id == _categoryId).firstOrNull;
    final data = EnrollmentPdfData(
      studentId: widget.editingStudent?.id,
      schoolName: _schoolName,
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      admissionNo: _admissionNoController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _gender?.label ?? '',
      bloodGroup: _bloodGroup ?? '',
      motherTongue: _motherTongueEffective,
      religion: _religionEffective == 'Prefer not to say' ? '' : _religionEffective,
      nationality: _nationalityEffective,
      isActive: _isActive,
      academicYearName: academicYear?.name ?? '',
      className: schoolClass?.name ?? '',
      sectionName: section?.name ?? '',
      admissionType: _admissionType,
      categoryName: category?.name ?? '',
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      stateName: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      guardians: _guardians
          .map((g) => EnrollmentPdfGuardian(
                fullName: g.fullName,
                relation: g.relation,
                phone: g.phone,
                email: g.email,
                occupation: g.occupation,
                isPrimary: g.isPrimary,
              ))
          .toList(),
      apaarProvided: _apaarIdController.text.trim().isNotEmpty,
      documents: [
        ('Birth certificate', _documentsUploaded['birth_certificate'] ?? false),
        ('Aadhaar card (masked)', _documentsUploaded['aadhaar'] ?? false),
        ('Caste certificate', _documentsUploaded['caste_certificate'] ?? false),
        ('UDID / disability certificate', _documentsUploaded['disability_certificate'] ?? false),
        ('Medical information', _documentsUploaded['medical_info'] ?? false),
        ('Transfer certificate', _documentsUploaded['transfer_certificate'] ?? false),
      ],
      allergies: _allergiesController.text.trim(),
      medications: _medicationsController.text.trim(),
      emergencyContact: _emergencyContactController.text.trim(),
      isPwD: _isPwD,
      pwdNotes: _pwdNotesController.text.trim(),
      identityMark1: _identityMark1Controller.text.trim(),
      identityMark2: _identityMark2Controller.text.trim(),
      birthmark: _birthmarkController.text.trim(),
      photoUrl: _photoUrl,
    );
    return data;
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    await _uploadPhotoBytes(Uint8List.fromList(file.bytes!), file.name, file.size);
  }

  /// "Take photo" — on mobile/desktop this launches the native OS camera
  /// directly (`camera_capture_io.dart`); on web it mirrors the frontend's
  /// own in-page `getUserMedia` camera modal exactly, since a browser has
  /// no native camera app to hand off to (`camera_capture_web.dart`).
  Future<void> _takePhoto() async {
    Uint8List? bytes;
    try {
      bytes = await captureStudentPhotoViaCamera(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoError = 'Could not open the camera: $e');
      return;
    }
    if (bytes == null || !mounted) return;
    await _uploadPhotoBytes(bytes, 'student-photo-${DateTime.now().millisecondsSinceEpoch}.jpg', bytes.length);
  }

  /// Shared by both "Upload file" and "Take photo" — mirrors
  /// `uploadStudentPhoto()`'s own client-side size gate, compression, and
  /// success/failure handling exactly, regardless of where the bytes came
  /// from.
  Future<void> _uploadPhotoBytes(Uint8List bytes, String sourceName, int sizeBytes) async {
    // Mirrors `uploadStudentPhoto()`'s own client-side gate exactly (the
    // frontend's separate, looser 5MB check on the raw <input> `onChange`
    // never actually matters — that same request still gets rejected by
    // this 4MB check moments later, so this is the one real limit).
    if (sizeBytes > 4 * 1024 * 1024) {
      setState(() => _photoError = 'Please choose an image up to 4MB before compression.');
      return;
    }
    setState(() {
      _photoUploading = true;
      _photoError = null;
    });
    try {
      // A hard ceiling so a platform-specific compression hiccup surfaces as
      // a normal error instead of leaving the spinner stuck forever.
      final compressed = await compressPhotoForUpload(bytes).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Photo processing took too long. Please try a different photo.'),
      );
      var filename = sourceName;
      if (!filename.toLowerCase().endsWith('.jpg') && !filename.toLowerCase().endsWith('.jpeg')) {
        filename = '${filename.contains('.') ? filename.substring(0, filename.lastIndexOf('.')) : filename}.jpg';
      }
      final url = await ref
          .read(studentRepositoryProvider)
          .uploadStudentPhoto(bytes: compressed, filename: filename)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Upload took too long. Please check your connection and try again.'),
          );
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        // Render straight from the just-uploaded bytes instead of re-fetching
        // the server URL over the network for the on-screen preview — avoids
        // a second round trip (and, on Flutter web, potential CORS failures
        // on the image fetch) so the photo the user just picked shows up
        // immediately and reliably, matching the frontend's end state (the
        // circle shows the uploaded photo) without depending on a live
        // network re-fetch to get there.
        _photoPreviewBytes = compressed;
        _photoUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded securely.')),
      );
    } catch (e) {
      if (!mounted) return;
      // Mirrors the frontend's own failure behavior exactly: the photo is
      // cleared back to the "ADD PHOTO" placeholder, not left showing a
      // stale/broken preview.
      setState(() {
        _photoUploading = false;
        _photoUrl = null;
        _photoPreviewBytes = null;
        _photoError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickAndUploadDocument(String documentType) async {
    final studentId = widget.editingStudent?.id;
    if (studentId == null) {
      _comingSoon('Document upload before enrollment');
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    setState(() => _documentsUploading[documentType] = true);
    try {
      await ref.read(studentRepositoryProvider).uploadStudentDocument(
            studentId: studentId,
            documentType: documentType,
            bytes: file.bytes!,
            filename: file.name,
          );
      if (!mounted) return;
      setState(() {
        _documentsUploading[documentType] = false;
        _documentsUploaded[documentType] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _documentsUploading[documentType] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  /// Parses the "Date of birth" field's `DD/MM/YYYY` hint format. Returns
  /// null (rather than throwing) for empty/malformed input — DOB is
  /// recommended in the UI but not hard-blocked by `_submit`'s own
  /// validation, so a bad/empty value should just omit the field.
  DateTime? _parseDob(String text) {
    if (text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _classId == null ||
        _sectionId == null) {
      setState(() => _error = 'First name, last name, class and section are required.');
      setState(() => _activeIndex = _classId == null || _sectionId == null ? 1 : 0);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final schoolClass = _classes.where((c) => c.id == _classId).firstOrNull;
    final section = schoolClass?.sections.where((s) => s.id == _sectionId).firstOrNull;
    final primaryGuardian = _guardians.where((g) => g.fullName.trim().isNotEmpty).firstOrNull;
    final editing = widget.editingStudent;
    final draft = StudentData(
      id: editing?.id ?? 0,
      admissionNo: _admissionNoController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _parseDob(_dobController.text.trim()),
      gender: _gender,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      classId: _classId!,
      className: schoolClass?.name ?? '',
      sectionId: _sectionId!,
      sectionName: section?.name ?? '',
      academicYearId: _academicYearId,
      categoryId: _categoryId,
      guardianId: editing?.guardianId,
      guardianName: primaryGuardian?.fullName.trim(),
      guardianPhone: primaryGuardian?.phone.trim(),
      guardianRelation: primaryGuardian?.relation,
      photoUrl: _photoUrl,
      addressLine: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
      status: _isActive ? StudentStatus.active : StudentStatus.inactive,
      enrolledAt: DateTime.now(),
    );
    try {
      final repo = ref.read(studentRepositoryProvider);
      if (isEditMode) {
        await repo.updateStudent(editing!.id, draft);
      } else {
        await repo.createStudent(draft);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.studentEnrollBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBreadcrumbRow(),
                    const SizedBox(height: 14),
                    _buildHero(),
                    if (!_scanBannerDismissed) ...[
                      const SizedBox(height: 12),
                      _buildScanBanner(),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorBanner(),
                    ],
                    const SizedBox(height: 14),
                    _buildStepStrip(),
                    const SizedBox(height: 14),
                    _buildActiveSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Dashboard / Students / ${isEditMode ? 'Edit' : 'Enroll'}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _PulsingDot(color: _draftSaving ? const Color(0xFF9CA3AF) : const Color(0xFF10B981), animate: _draftSaving),
        ),
        Text(_draftSaving ? 'Saving…' : 'Draft saved', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 480;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.studentEnrollInk,
                  height: 1.1,
                ),
                children: [
                  TextSpan(text: isEditMode ? 'Edit ' : 'Enroll a '),
                  TextSpan(
                    text: 'student',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: AppColors.studentEnrollBrand,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Admit a new student into the school records. We'll generate an admission number, place them in a class & section, and notify their guardian.",
              style: TextStyle(fontSize: 13, color: AppColors.studentEnrollMuted, height: 1.5),
            ),
          ],
        );
        final kpiBlock = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.studentEnrollLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadingLookups ? '…' : '${_currentEnrolledCount ?? 0}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const Text(
                'CURRENTLY ENROLLED',
                style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
        final showLabels = MediaQuery.sizeOf(context).width >= 600;
        final draftCount = _draftStore.load().length;
        final actionsRow = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroActionButton(
              variant: _HeroActionVariant.drafts,
              icon: Icons.description_outlined,
              label: 'Drafts',
              showLabel: showLabels,
              badgeCount: draftCount,
              onTap: _openDraftsDialog,
              tooltip: 'View saved drafts',
            ),
            _HeroActionButton(
              variant: _HeroActionVariant.ai,
              icon: Icons.auto_awesome,
              label: 'AI Assist',
              showLabel: showLabels,
              onTap: _openAiAssistDialog,
              tooltip: 'Get AI-powered help & suggestions',
            ),
            _HeroActionButton(
              variant: _HeroActionVariant.pdf,
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              showLabel: showLabels,
              onTap: _previewEnrollmentPdf,
              tooltip: 'Preview & print the consent PDF',
            ),
            _HeroActionButton(
              variant: _HeroActionVariant.info,
              icon: Icons.info_outline,
              label: "What I'll need",
              showLabel: showLabels,
              onTap: _openChecklistDialog,
              tooltip: "What documents & details will I need?",
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.studentEnrollLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [titleBlock, const SizedBox(height: 12), kpiBlock],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: titleBlock),
                        const SizedBox(width: 16),
                        kpiBlock,
                      ],
                    ),
              const SizedBox(height: 12),
              actionsRow,
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.studentScanBannerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.studentScanIconBg, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Scan to pre-fill',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.studentBadgeNewBg, borderRadius: BorderRadius.circular(999)),
                      child: const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scan a birth certificate or Aadhaar card to auto-fill this form.',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _comingSoon('Scan & fill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.studentEnrollBrand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Scan now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _scanBannerDismissed = true),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF9CA3AF)),
                      child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStepStrip() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _navItems.length,
        separatorBuilder: (context, index) {
          if (_navItems[index + 1].startsGroup) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: VerticalDivider(width: 1, thickness: 1, color: AppColors.studentEnrollLine),
            );
          }
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final item = _navItems[index];
          final isActive = index == _activeIndex;
          final isLocked = index > _maxReachedIndex + 1;
          return _StepChip(
            index: index + 1,
            label: item.label,
            badge: item.badge,
            isActive: isActive,
            isLocked: isLocked,
            onTap: isLocked ? null : () => _goToIndex(index),
          );
        },
      ),
    );
  }

  Widget _buildActiveSection() {
    final item = _navItems[_activeIndex];
    switch (item.id) {
      case 'identity':
        return _buildIdentitySection();
      case 'academic':
        return _buildAcademicSection();
      case 'contact':
        return _buildContactSection();
      case 'guardians':
        return _buildGuardiansSection();
      case 'apaar':
        return _buildApaarSection();
      case 'documents':
        return _buildDocumentsSection();
      case 'medical':
        return _buildMedicalSection();
      case 'speciallyAbled':
        return _buildSpeciallyAbledSection();
      case 'identityMarks':
        return _buildIdentityMarksSection();
      case 'fees':
        return _buildFeesSection();
      default:
        return _buildReviewSection();
    }
  }

  Widget _navButtons({bool isFirst = false, bool isLast = false}) {
    return Row(
      children: [
        if (!isFirst)
          OutlinedButton(
            onPressed: _prev,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.studentNavPrevText,
              side: const BorderSide(color: AppColors.studentNavPrevBorder),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('← Back'),
          ),
        const Spacer(),
        if (!isLast)
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.studentEnrollBrand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Next →', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 1 — IDENTITY
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildIdentitySection() {
    return EnrollSectionCard(
      title: 'Student identity',
      subtitle: 'Basic profile, date of birth, and photo',
      stepNumber: 1,
      navButtons: _navButtons(isFirst: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoField(),
          const SizedBox(height: 24),
          EnrollFieldGrid(children: [
            EnrollTextField(
              label: 'Admission number',
              controller: _admissionNoController,
              badge: EnrollBadge.required,
              readOnly: _admissionNoLocked,
              filledWhenReadOnly: false,
              hint: _firstNameController.text.trim().isNotEmpty ? 'e.g. ADM20240001' : 'Enter first name to generate',
              maxLines: 1,
              helpText: 'Auto-generated. Click Edit to customize.',
              suffixIcon: TextButton(
                onPressed: () => setState(() => _admissionNoLocked = !_admissionNoLocked),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.studentEnrollBrand,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_admissionNoLocked ? 'Edit' : 'Lock', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            EnrollTextField(
              label: 'Roll number',
              controller: TextEditingController(text: 'Auto when class is set'),
              badge: EnrollBadge.assignedLater,
              readOnly: true,
              enabled: false,
              helpText: 'Rolls are assigned after class allocation.',
            ),
          ]),
          const SizedBox(height: 16),
          _buildStatusToggle(),
          const SizedBox(height: 16),
          EnrollFieldGrid(
            maxColumns: 3,
            children: [
              EnrollTextField(label: 'First name', controller: _firstNameController, badge: EnrollBadge.required, onChanged: (_) => setState(() {})),
              EnrollTextField(label: 'Middle name', controller: _middleNameController, badge: EnrollBadge.optional),
              EnrollTextField(label: 'Last name', controller: _lastNameController, badge: EnrollBadge.required),
            ],
          ),
          const SizedBox(height: 16),
          EnrollFieldGrid(children: [
            EnrollTextField(
              label: 'Date of birth',
              controller: _dobController,
              badge: EnrollBadge.required,
              hint: 'DD / MM / YYYY',
              keyboardType: TextInputType.datetime,
              errorText: _dobError,
              onChanged: (_) => _validateDob(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                onPressed: _pickDob,
              ),
            ),
            EnrollDropdown<StudentGender>(
              label: 'Gender',
              badge: EnrollBadge.required,
              value: _gender,
              hint: 'Select',
              items: StudentGender.values
                  .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
          ]),
          const SizedBox(height: 16),
          EnrollFieldGrid(children: [
            EnrollDropdown<String>(
              label: 'Blood group',
              badge: EnrollBadge.optional,
              value: _bloodGroup,
              hint: 'Select',
              items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v),
            ),
            EnrollDropdown<String>(
              label: 'Mother tongue',
              badge: EnrollBadge.optional,
              value: _motherTongue,
              hint: 'Select',
              items: kMotherTongueOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _motherTongue = v),
            ),
          ]),
          if (_motherTongue == 'Other') ...[
            const SizedBox(height: 12),
            EnrollTextField(label: 'Specify language', controller: _motherTongueOtherController, badge: EnrollBadge.optional),
          ],
          const SizedBox(height: 16),
          EnrollFieldGrid(children: [
            EnrollDropdown<String>(
              label: 'Religion',
              badge: EnrollBadge.optional,
              value: _religion,
              hint: 'Select',
              items: kReligionOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _religion = v),
            ),
            EnrollDropdown<String>(
              label: 'Nationality',
              badge: EnrollBadge.required,
              value: _nationality,
              hint: 'Select Nationality',
              items: kNationalityOptions.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
              onChanged: (v) => setState(() => _nationality = v),
            ),
          ]),
          if (_religion == 'Other') ...[
            const SizedBox(height: 12),
            EnrollTextField(label: 'Specify religion', controller: _religionOtherController, badge: EnrollBadge.optional),
          ],
          if (_nationality == 'Other') ...[
            const SizedBox(height: 12),
            EnrollTextField(label: 'Specify nationality', controller: _nationalityOtherController, badge: EnrollBadge.required),
          ],
        ],
      ),
    );
  }

  /// Mirrors StudentAddPanel.tsx's photo uploader exactly: a large dashed
  /// circle placeholder (camera/plus icon + "ADD PHOTO" caption) beside a
  /// "Student photo" heading, description copy, and Upload file / Take
  /// photo actions.
  Widget _buildPhotoField() {
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 420;
      final circle = InkWell(
        onTap: _photoUploading ? null : _pickAndUploadPhoto,
        borderRadius: BorderRadius.circular(80),
        child: Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: _hasPhoto ? Colors.white : const Color(0xFFFAFAFA),
            shape: BoxShape.circle,
            // Mirrors `.photo-circle.has-photo { border: none; }` exactly —
            // the dashed placeholder ring disappears entirely once a photo
            // fills the circle, not just changes color.
            border: _hasPhoto ? null : Border.all(color: const Color(0xFFD1D5DB), width: 2),
          ),
          alignment: Alignment.center,
          child: _photoUploading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : _photoPreviewBytes != null
                  ? ClipOval(
                      child: Image.memory(
                        _photoPreviewBytes!,
                        width: 132,
                        height: 132,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _photoUrl!,
                            width: 132,
                            height: 132,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle, size: 32, color: Color(0xFF16A34A)),
                          ),
                        )
                      : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 26, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 4),
                        Text('ADD PHOTO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                      ],
                    ),
        ),
      );

      final details = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Student photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.studentEnrollInk)),
          const SizedBox(height: 6),
          const Text(
            "Square JPG or PNG, at least 400×400px. We'll crop it into a circle for ID cards and reports.",
            style: TextStyle(fontSize: 13, color: AppColors.studentEnrollMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Mirrors `.btn-upload-file` exactly — always present, label
              // swaps "Upload file" -> "Change" once a photo exists.
              _photoOutlinedButton(
                label: _hasPhoto ? 'Change' : 'Upload file',
                onPressed: _photoUploading ? null : _pickAndUploadPhoto,
              ),
              if (_hasPhoto) ...[
                _photoOutlinedButton(label: 'View image', onPressed: _photoUploading ? null : _openPhotoPreview),
                _photoLinkButton(label: 'Remove', onPressed: _photoUploading ? null : _removePhoto),
              ] else
                _photoLinkButton(label: 'Take photo', onPressed: _photoUploading ? null : _takePhoto),
            ],
          ),
          if (_photoError != null) ...[
            const SizedBox(height: 6),
            Text(_photoError!, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
          ],
        ],
      );

      return stacked
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [circle, const SizedBox(height: 16), details])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [circle, const SizedBox(width: 20), Expanded(child: details)]);
    });
  }

  /// Mirrors `.btn-upload-file` exactly — outlined, neutral, not bold.
  Widget _photoOutlinedButton({required String label, required VoidCallback? onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
      ),
      child: Text(label),
    );
  }

  /// Mirrors `.btn-take-photo` exactly — plain underlined brand-colour text
  /// link, no border/background/bold weight.
  Widget _photoLinkButton({required String label, required VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.studentEnrollBrand, padding: EdgeInsets.zero),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, decoration: TextDecoration.underline)),
    );
  }

  /// "View image" — mirrors `photoPreviewOpen`'s `.photo-preview-overlay`/
  /// `.photo-preview-card` exactly: a centered white card with just a close
  /// button and the full image, nothing else.
  void _openPhotoPreview() {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xAD0F172A),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
                    child: _photoPreviewBytes != null
                        ? Image.memory(_photoPreviewBytes!, fit: BoxFit.contain)
                        : Image.network(_photoUrl!, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('✕', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Remove" — mirrors `clearStudentPhoto()` exactly: clears the photo
  /// back to the empty "ADD PHOTO" state and any lingering error, with no
  /// backend delete call (the frontend doesn't make one either).
  void _removePhoto() {
    setState(() {
      _photoUrl = null;
      _photoPreviewBytes = null;
      _photoError = null;
    });
  }

  /// Mirrors StudentAddPanel.tsx's Active/Inactive radiogroup pills exactly
  /// — a two-way segmented toggle, not a Material [Switch].
  Widget _buildStatusToggle() {
    Widget pill(String label, bool active, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.studentEnrollBrand : Colors.white,
              border: Border.all(color: active ? AppColors.studentEnrollBrand : AppColors.studentEnrollLine),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.studentFieldLabel),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.studentFieldLabel)),
        const SizedBox(height: 6),
        Row(
          children: [
            pill('Active', _isActive, () => setState(() => _isActive = true)),
            const SizedBox(width: 8),
            pill('Inactive', !_isActive, () => setState(() => _isActive = false)),
          ],
        ),
      ],
    );
  }

  /// Mirrors StudentAddPanel.tsx's DOB blur validation exactly: under 2 or
  /// over 25 years old triggers a warning (does not hard-block `_submit`).
  void _validateDob() {
    final dob = _parseDob(_dobController.text.trim());
    setState(() {
      if (dob == null) {
        _dobError = null;
        return;
      }
      final age = DateTime.now().difference(dob).inDays / 365.25;
      if (age < 2) {
        _dobError = 'Student must be at least 2 years old';
      } else if (age > 25) {
        _dobError = 'Date of birth seems too old — please verify';
      } else {
        _dobError = null;
      }
    });
  }

  Future<void> _pickDob() async {
    final initial = _parseDob(_dobController.text.trim()) ?? DateTime(DateTime.now().year - 6);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
    _validateDob();
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 2 — ACADEMIC PLACEMENT
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildAcademicSection() {
    final selectedClass = _classes.where((c) => c.id == _classId).firstOrNull;
    return EnrollSectionCard(
      title: 'Academic placement',
      subtitle: 'Class, section, and academic year',
      stepNumber: 2,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnrollFieldGrid(children: [
            EnrollDropdown<int>(
              label: 'Academic year',
              badge: EnrollBadge.required,
              value: _academicYearId,
              hint: 'Select year',
              items: _academicYears
                  .map((y) => DropdownMenuItem(value: y.id, child: Text(y.name)))
                  .toList(),
              onChanged: (v) => setState(() => _academicYearId = v),
            ),
            EnrollDropdown<String>(
              label: 'Admission type',
              badge: EnrollBadge.required,
              value: _admissionType,
              hint: 'Select Admission Type',
              items: kAdmissionTypeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _admissionType = v ?? 'New admission'),
              helpText: 'New admission: first-time enrollment · Transfer: from another school · '
                  'Re-admission: previously enrolled, returning · RTE Quota: Right to Education Act 2009 reservation',
            ),
          ]),
          if (_admissionType == 'Transfer') ...[
            const SizedBox(height: 16),
            EnrollTextField(label: 'Previous school name', controller: _previousSchoolNameController),
          ],
          if (_admissionType == 'RTE Quota') ...[
            const SizedBox(height: 16),
            EnrollTextField(label: 'RTE certificate number', controller: _rteCertificateController, badge: EnrollBadge.required),
          ],
          const SizedBox(height: 16),
          EnrollFieldGrid(children: [
            EnrollDropdown<int>(
              label: 'Class',
              badge: EnrollBadge.required,
              value: _classId,
              hint: 'Select class',
              items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() {
                _classId = v;
                _sectionId = null;
              }),
            ),
            EnrollDropdown<int>(
              label: 'Section',
              badge: EnrollBadge.required,
              value: _sectionId,
              hint: selectedClass == null ? 'Select a class first' : 'Select section',
              items: (selectedClass?.sections ?? const [])
                  .map((s) => DropdownMenuItem(value: s.id, child: Text('Section ${s.name}')))
                  .toList(),
              onChanged: selectedClass == null ? null : (v) => setState(() => _sectionId = v),
            ),
          ]),
          const SizedBox(height: 16),
          EnrollDropdown<int>(
            label: 'Category',
            badge: EnrollBadge.optional,
            value: _categoryId,
            hint: 'Select category',
            items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 3 — CONTACT & ADDRESS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildContactSection() {
    return EnrollSectionCard(
      title: 'Contact & address',
      subtitle: 'Phone, email, and home address',
      stepNumber: 3,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnrollFieldGrid(children: [
            EnrollTextField(
              label: 'Phone',
              controller: _phoneController,
              badge: EnrollBadge.required,
              hint: '10-digit mobile number',
              keyboardType: TextInputType.phone,
            ),
            EnrollTextField(
              label: 'Email',
              controller: _emailController,
              badge: EnrollBadge.recommended,
              hint: 'student@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
          ]),
          const SizedBox(height: 16),
          EnrollFieldGrid(children: [
            EnrollTextField(label: 'Pincode', controller: _pincodeController, badge: EnrollBadge.required, keyboardType: TextInputType.number),
            EnrollTextField(label: 'Address line', controller: _addressController, badge: EnrollBadge.required),
          ]),
          const SizedBox(height: 16),
          EnrollFieldGrid(children: [
            EnrollTextField(label: 'State', controller: _stateController, badge: EnrollBadge.required),
            EnrollTextField(label: 'District', controller: _districtController, badge: EnrollBadge.required),
          ]),
          const SizedBox(height: 16),
          EnrollTextField(label: 'City', controller: _cityController, badge: EnrollBadge.required),
          const SizedBox(height: 16),
          EnrollTextField(label: 'Landmark', controller: _landmarkController, badge: EnrollBadge.optional, hint: 'Near school, landmark, area name…'),
          const SizedBox(height: 16),
          _buildTransportField(),
        ],
      ),
    );
  }

  static const List<String> _transportOptions = [
    'School bus', 'Private vehicle', 'Auto-rickshaw', 'Cycle', 'Walk', 'Public bus/metro', 'Cab/Taxi',
  ];

  /// Mirrors StudentAddPanel.tsx's "Means of transport" multi-select pill
  /// picker + custom free-text add row exactly.
  Widget _buildTransportField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollLabel('Means of transport', badge: EnrollBadge.optional),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._transportOptions.map((mode) {
              final selected = _transportModes.contains(mode);
              return FilterChip(
                label: Text(mode, style: const TextStyle(fontSize: 12.5)),
                selected: selected,
                onSelected: (v) => setState(() => v ? _transportModes.add(mode) : _transportModes.remove(mode)),
                selectedColor: AppColors.studentEnrollBrand.withValues(alpha: 0.12),
                checkmarkColor: AppColors.studentEnrollBrand,
                side: BorderSide(color: selected ? AppColors.studentEnrollBrand : AppColors.studentEnrollLine),
                backgroundColor: Colors.white,
              );
            }),
            ..._transportModes.where((m) => !_transportOptions.contains(m)).map((custom) => Chip(
                  label: Text(custom, style: const TextStyle(fontSize: 12.5)),
                  onDeleted: () => setState(() => _transportModes.remove(custom)),
                  backgroundColor: AppColors.studentEnrollBrand.withValues(alpha: 0.12),
                )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTransportController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Custom transport mode…',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.studentFieldBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.studentEnrollBrand, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final v = _customTransportController.text.trim();
                if (v.isEmpty) return;
                setState(() {
                  if (!_transportModes.contains(v)) _transportModes.add(v);
                  _customTransportController.clear();
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 4 — FAMILY & GUARDIANS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildGuardiansSection() {
    return EnrollSectionCard(
      title: 'Family & guardians',
      subtitle: 'Parent or guardian contact details',
      stepNumber: 4,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _guardians.length; i++) ...[
            _buildGuardianCard(_guardians[i], i),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _guardians.add(GuardianDraft(clientId: '${DateTime.now().microsecondsSinceEpoch}'));
            }),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add another guardian'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.studentEnrollBrand,
              side: BorderSide(color: AppColors.studentEnrollBrand),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianCard(GuardianDraft guardian, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        border: Border.all(color: AppColors.studentEnrollLine),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  guardian.fullName.isEmpty ? 'Guardian ${index + 1}' : guardian.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Primary', style: TextStyle(fontSize: 12, color: AppColors.studentEnrollMuted)),
                  Checkbox(
                    value: guardian.isPrimary,
                    onChanged: (v) => setState(() {
                      for (final g in _guardians) {
                        g.isPrimary = false;
                      }
                      guardian.isPrimary = v ?? false;
                    }),
                    activeColor: AppColors.studentEnrollBrand,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (_guardians.length > 1)
                IconButton(
                  onPressed: () => setState(() => _guardians.removeAt(index)),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          EnrollFieldGrid(children: [
            EnrollTextField(
              label: 'Full name',
              controller: TextEditingController(text: guardian.fullName)
                ..selection = TextSelection.collapsed(offset: guardian.fullName.length),
              badge: EnrollBadge.required,
              onChanged: (v) => guardian.fullName = v,
            ),
            EnrollDropdown<String>(
              label: 'Relation',
              badge: EnrollBadge.required,
              value: guardian.relation,
              hint: 'Select relation',
              items: guardianRelationOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => guardian.relation = v ?? guardian.relation),
            ),
          ]),
          const SizedBox(height: 12),
          EnrollFieldGrid(children: [
            EnrollTextField(
              label: 'Phone',
              controller: TextEditingController(text: guardian.phone)
                ..selection = TextSelection.collapsed(offset: guardian.phone.length),
              badge: EnrollBadge.required,
              keyboardType: TextInputType.phone,
              onChanged: (v) => guardian.phone = v,
            ),
            EnrollTextField(
              label: 'Email',
              controller: TextEditingController(text: guardian.email)
                ..selection = TextSelection.collapsed(offset: guardian.email.length),
              badge: EnrollBadge.optional,
              onChanged: (v) => guardian.email = v,
            ),
          ]),
          const SizedBox(height: 12),
          EnrollTextField(
            label: 'Occupation',
            controller: TextEditingController(text: guardian.occupation)
              ..selection = TextSelection.collapsed(offset: guardian.occupation.length),
            badge: EnrollBadge.optional,
            onChanged: (v) => guardian.occupation = v,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 5 — GOVERNMENT IDENTITY (APAAR)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildApaarSection() {
    return EnrollSectionCard(
      title: 'Government identity',
      subtitle: '"One Nation, One Student ID" — a 12-digit lifelong academic identity issued by the '
          'Ministry of Education (NEP 2020).',
      stepNumber: 5,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
            child: const Text(
              '📋 Entering a valid APAAR ID auto-fills all matching fields across the form.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ),
          const SizedBox(height: 16),
          EnrollTextField(
            label: 'APAAR ID',
            controller: _apaarIdController,
            badge: EnrollBadge.optional,
            hint: '1234 5678 9012',
          ),
          const SizedBox(height: 16),
          const Text('OTHER GOVERNMENT IDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.studentEnrollMuted)),
          const SizedBox(height: 12),
          EnrollTextField(
            label: 'Aadhaar number',
            controller: _aadhaarController,
            badge: EnrollBadge.optional,
            hint: '12-digit Aadhaar',
            obscureText: !_aadhaarVisible,
            keyboardType: TextInputType.number,
            helpText: 'Stored encrypted — used for APAAR KYC only. Only required if performing APAAR KYC verification.',
            suffixIcon: IconButton(
              icon: Icon(_aadhaarVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: () => setState(() => _aadhaarVisible = !_aadhaarVisible),
            ),
          ),
          const SizedBox(height: 16),
          EnrollFieldGrid(children: [
            EnrollTextField(label: 'PEN / UDISE+', controller: _penUdiseController, badge: EnrollBadge.optional, hint: 'Permanent Education Number'),
            EnrollTextField(label: 'DigiLocker mobile', controller: _digilockerMobileController, badge: EnrollBadge.optional, hint: 'Aadhaar-linked mobile'),
          ]),
          const SizedBox(height: 16),
          EnrollTextField(
            label: 'ABC Portal ID',
            controller: _abcIdController,
            badge: EnrollBadge.optional,
            hint: 'From abc.gov.in',
            helpText: 'Academic Bank of Credits ID issued by the National Academic Depository. Find yours at abc.gov.in',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFAFAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.studentEnrollLine)),
            child: const Text(
              '🔒 Aadhaar and biometric data are stored AES-256 encrypted and are never shared with third parties. '
              'Access is restricted to authorised school administrators only, in compliance with the DPDPA 2023.',
              style: TextStyle(fontSize: 11.5, color: AppColors.studentEnrollMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 6 — DOCUMENTS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDocumentsSection() {
    final selectedCategoryName = _categories.where((c) => c.id == _categoryId).firstOrNull?.name;
    final showCaste = selectedCategoryName != null && selectedCategoryName.trim().toLowerCase() != 'general';
    final docs = <(String key, String label, EnrollBadge badge, String description)>[
      ('birth_certificate', 'Birth certificate', EnrollBadge.docRequired, 'Government-issued proof of date of birth. PDF, JPG, or PNG up to 5 MB.'),
      ('aadhaar', 'Aadhaar card', EnrollBadge.masked, 'We store only the last 4 digits. The full number is never saved to disk or shared.'),
      if (showCaste)
        ('caste_certificate', 'Caste certificate', EnrollBadge.docRequired, 'Required for the selected reserved category. PDF, JPG, or PNG up to 5 MB.'),
      if (_isPwD)
        ('disability_certificate', 'UDID / disability certificate', EnrollBadge.docRequired, 'Unique Disability ID issued by the government. PDF, JPG, or PNG up to 5 MB.'),
      ('medical_info', 'Medical information', EnrollBadge.optional, 'Allergies, ongoing conditions, emergency contact for medical decisions. Stored encrypted.'),
      ('transfer_certificate', 'Transfer Certificate (TC)', EnrollBadge.optional, 'Previous school Transfer Certificate and last attended report card. Required for lateral admissions.'),
    ];

    return EnrollSectionCard(
      title: 'Documents',
      subtitle: 'Consent and student records',
      stepNumber: 6,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnrollFieldGrid(
            children: docs.map((doc) => _buildDocumentCard(doc.$1, doc.$2, doc.$3, doc.$4)).toList(),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _consentChecked = !_consentChecked),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consentChecked,
                  onChanged: (v) => setState(() => _consentChecked = v ?? false),
                  activeColor: AppColors.studentEnrollBrand,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: AppColors.studentFieldLabel, height: 1.5),
                        children: [
                          TextSpan(text: 'Parent / Guardian consent ', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: '*', style: TextStyle(color: AppColors.studentRequiredMark, fontWeight: FontWeight.w700)),
                          TextSpan(
                            text:
                                "\nI confirm that the student's parent or legal guardian has authorized me to submit these documents and has consented to their storage for school records, admissions, fee management, and legally required reporting. I understand that withdrawing consent requires a written request.",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String key, String label, EnrollBadge badge, String description) {
    final uploaded = _documentsUploaded[key] ?? false;
    final uploading = _documentsUploading[key] ?? false;
    return InkWell(
      onTap: uploading ? null : () => _pickAndUploadDocument(key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: uploaded ? const Color(0xFFF0FDF4) : const Color(0xFFFAFAFB),
          border: Border.all(color: uploaded ? const Color(0xFF86EFAC) : AppColors.studentEnrollLine),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (uploading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    uploaded ? Icons.check_circle : Icons.upload_file_outlined,
                    size: 18,
                    color: uploaded ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _docBadgeChip(badge),
            const SizedBox(height: 6),
            Text(
              uploading
                  ? 'Uploading…'
                  : uploaded
                      ? 'Uploaded'
                      : isEditMode
                          ? description
                          : 'Available once the student is enrolled',
              style: TextStyle(
                fontSize: 11,
                color: uploaded ? const Color(0xFF16A34A) : AppColors.studentHelpText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mirrors `StudentDocumentsUpload.tsx`'s `.doc-badge-req` /
  /// `.doc-badge-mask` / `.doc-badge-opt` — a text pill for every state
  /// (there is no bare-asterisk "required" convention in this component,
  /// unlike the rest of the wizard).
  Widget _docBadgeChip(EnrollBadge badge) {
    final (bg, text, label) = enrollBadgeStyle(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: text, letterSpacing: 0.4)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 7 — MEDICAL & EMERGENCY
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildMedicalSection() {
    return EnrollSectionCard(
      title: 'Medical & emergency',
      subtitle: 'Health notes and emergency contact',
      stepNumber: 7,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnrollTextField(
            label: 'Allergies',
            controller: _allergiesController,
            badge: EnrollBadge.optional,
            hint: 'e.g. Peanuts, penicillin',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          EnrollTextField(
            label: 'Current medications',
            controller: _medicationsController,
            badge: EnrollBadge.optional,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          EnrollTextField(
            label: 'Emergency contact (name & phone)',
            controller: _emergencyContactController,
            badge: EnrollBadge.recommended,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 8 — SPECIALLY ABLED
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSpeciallyAbledSection() {
    return EnrollSectionCard(
      title: 'Specially abled',
      subtitle: 'PwD accommodations',
      stepNumber: 8,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnrollToggle(
            label: 'Specially abled (PwD)',
            description: 'Enables accommodation notes and the UDID document requirement.',
            value: _isPwD,
            onChanged: (v) => setState(() => _isPwD = v),
          ),
          if (_isPwD) ...[
            const SizedBox(height: 12),
            EnrollTextField(
              label: 'Accommodation notes',
              controller: _pwdNotesController,
              badge: EnrollBadge.recommended,
              maxLines: 3,
              hint: 'e.g. Wheelchair access, extra exam time',
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 9 — IDENTITY MARKS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildIdentityMarksSection() {
    return EnrollSectionCard(
      title: 'Identity marks',
      subtitle: 'Physical identifiers',
      stepNumber: 9,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnrollFieldGrid(children: [
            EnrollTextField(label: 'Identity mark 1', controller: _identityMark1Controller, badge: EnrollBadge.optional),
            EnrollTextField(label: 'Identity mark 2', controller: _identityMark2Controller, badge: EnrollBadge.optional),
          ]),
          const SizedBox(height: 16),
          EnrollTextField(
            label: 'Birthmark description',
            controller: _birthmarkController,
            badge: EnrollBadge.optional,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 10 — FEE PLAN
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildFeesSection() {
    return EnrollSectionCard(
      title: 'Fee plan',
      subtitle: 'Assign fees & concessions',
      stepNumber: 10,
      navButtons: _navButtons(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnrollFieldGrid(children: [
            EnrollDropdown<String>(
              label: 'Fee group',
              badge: EnrollBadge.recommended,
              value: _feeGroup,
              hint: 'Select fee group',
              items: const ['Standard', 'Sibling discount', 'Staff ward']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _feeGroup = v),
            ),
            EnrollDropdown<String>(
              label: 'Concession',
              badge: EnrollBadge.optional,
              value: _concession,
              hint: 'None',
              items: const ['None', 'Merit scholarship', 'Financial aid']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _concession = v),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.studentEnrollLine),
            ),
            child: const Text(
              'The exact fee schedule is assigned once the student is enrolled and a fee plan is confirmed by the accounts team.',
              style: TextStyle(fontSize: 12, color: AppColors.studentEnrollMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SECTION 11 — REVIEW
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildReviewSection() {
    final schoolClass = _classes.where((c) => c.id == _classId).firstOrNull;
    final section = schoolClass?.sections.where((s) => s.id == _sectionId).firstOrNull;
    return EnrollSectionCard(
      title: 'Review',
      subtitle: 'Confirm details before enrolling',
      stepNumber: 11,
      navButtons: Row(
        children: [
          OutlinedButton(
            onPressed: _prev,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.studentNavPrevText,
              side: const BorderSide(color: AppColors.studentNavPrevBorder),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('← Back'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reviewRow('Student identity', '${_firstNameController.text} ${_lastNameController.text}'.trim(), 0),
          _reviewRow('Academic placement', schoolClass != null ? '${schoolClass.name} · Section ${section?.name ?? '—'}' : 'Not set', 1),
          _reviewRow('Contact & address', _phoneController.text.isEmpty ? 'Not provided' : _phoneController.text, 2),
          _reviewRow('Family & guardians', '${_guardians.length} guardian${_guardians.length == 1 ? '' : 's'}', 3),
          _reviewRow('Documents', '${_documentsUploaded.values.where((v) => v).length} of ${_documentsUploaded.length} uploaded', 5),
          _reviewRow('Fee plan', _feeGroup ?? 'Not selected', 9),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _reviewConfirmed = !_reviewConfirmed),
            child: Row(
              children: [
                Checkbox(
                  value: _reviewConfirmed,
                  onChanged: (v) => setState(() => _reviewConfirmed = v ?? false),
                  activeColor: AppColors.studentEnrollBrand,
                ),
                const Expanded(
                  child: Text(
                    "I've reviewed every section.",
                    style: TextStyle(fontSize: 13, color: AppColors.studentFieldLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, int jumpIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.studentEnrollLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.studentEnrollMuted)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _goToIndex(jumpIndex),
            style: TextButton.styleFrom(foregroundColor: AppColors.studentEnrollBrand, padding: EdgeInsets.zero),
            child: const Text('Edit →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // STICKY FOOTER
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    final isReviewStep = _activeIndex == _navItems.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFECECF2))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF3F4F6),
                      color: AppColors.studentEnrollBrand,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(_progress * 100).round()}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.studentEnrollMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: TextButton.styleFrom(foregroundColor: AppColors.studentEnrollMuted),
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: _saveDraftFromFooter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.studentEnrollInk,
                      side: const BorderSide(color: AppColors.studentEnrollLine),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save draft'),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: _canPreviewPdf ? 'Preview & customize the consent PDF' : 'Available after student is enrolled.',
                    child: OutlinedButton(
                      onPressed: _canPreviewPdf ? _previewEnrollmentPdf : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.studentEnrollInk,
                        side: const BorderSide(color: AppColors.studentEnrollLine),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('🖨 Print / PDF'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isReviewStep)
                    ElevatedButton(
                      onPressed: (_saving || !_reviewConfirmed) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.studentEnrollBrand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditMode ? 'Update student →' : 'Enroll student →'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.studentEnrollBrand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Next →'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small dot that pulses (fades in/out) while [animate] is true — used by
/// the breadcrumb row's "Saving…" state. Mirrors the frontend's `pulse
/// 1.5s ease-in-out infinite` CSS animation on `draftSaveStatus === 'saving'`.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool animate;
  const _PulsingDot({required this.color, required this.animate});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle));
    if (!widget.animate) return dot;
    return FadeTransition(opacity: Tween(begin: 0.35, end: 1.0).animate(_controller), child: dot);
  }
}

enum _HeroActionVariant { drafts, ai, pdf, info }

class _HeroActionStyle {
  final LinearGradient? gradient;
  final Color? background;
  final Color? borderColor;
  final Color foreground;
  final List<BoxShadow>? shadow;
  const _HeroActionStyle({this.gradient, this.background, this.borderColor, required this.foreground, this.shadow});
}

/// One hero-bar button — mirrors StudentAddPanel.tsx's `.hero-action-btn`
/// variants exactly: same per-button gradient/border/text colors, same
/// draft-count badge, same AI pulse dot. Hides its text label at
/// `MediaQuery` widths ≥600 are false (matching the frontend's own
/// `@media (max-width: 600px)` icon-only rule — always true on a phone).
class _HeroActionButton extends StatelessWidget {
  final _HeroActionVariant variant;
  final IconData icon;
  final String label;
  final bool showLabel;
  final int? badgeCount;
  final String tooltip;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.variant,
    required this.icon,
    required this.label,
    required this.showLabel,
    this.badgeCount,
    required this.tooltip,
    required this.onTap,
  });

  _HeroActionStyle get _style {
    switch (variant) {
      case _HeroActionVariant.drafts:
        return _HeroActionStyle(
          background: Colors.white.withValues(alpha: 0.85),
          borderColor: const Color(0xFFE5E7EB),
          foreground: const Color(0xFF374151),
        );
      case _HeroActionVariant.ai:
        return const _HeroActionStyle(
          gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          foreground: Colors.white,
          shadow: [BoxShadow(color: Color(0x738B5CF6), blurRadius: 14, offset: Offset(0, 4))],
        );
      case _HeroActionVariant.pdf:
        return const _HeroActionStyle(
          gradient: LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderColor: Color(0xFFDDD6FE),
          foreground: Color(0xFF6C3CE1),
        );
      case _HeroActionVariant.info:
        return const _HeroActionStyle(
          gradient: LinearGradient(colors: [Color(0xFFECFEFF), Color(0xFFCFFAFE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderColor: Color(0xFFA5F3FC),
          foreground: Color(0xFF0E7490),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 18 : 10, vertical: showLabel ? 10 : 8),
            decoration: BoxDecoration(
              gradient: style.gradient,
              color: style.gradient == null ? style.background : null,
              border: style.borderColor != null ? Border.all(color: style.borderColor!) : null,
              borderRadius: BorderRadius.circular(11),
              boxShadow: style.shadow,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: style.foreground),
                    if (showLabel) ...[
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: style.foreground)),
                    ],
                    if (badgeCount != null && badgeCount! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0x1F6C3CE1), borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6C3CE1)),
                        ),
                      ),
                    ],
                  ],
                ),
                if (variant == _HeroActionVariant.ai)
                  Positioned(top: 4, right: showLabel ? 4 : -2, child: _PulsingDot(color: Colors.white, animate: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors StudentAddPanel.tsx's `.nav-item`/`.nav-bullet` exactly — there is
/// no "done/completed" visual state in the frontend (only `active`,
/// `locked`, and default), so this never shows a checkmark for
/// visited-but-not-active steps.
class _StepChip extends StatelessWidget {
  final int index;
  final String label;
  final EnrollBadge? badge;
  final bool isActive;
  final bool isLocked;
  final VoidCallback? onTap;

  const _StepChip({
    required this.index,
    required this.label,
    required this.badge,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 116,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.studentNavActiveBg : (isLocked ? AppColors.studentNavLockedBg : Colors.white),
            border: Border.all(
              color: isActive ? AppColors.studentEnrollBrand : AppColors.studentEnrollLine,
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.studentEnrollBrand : AppColors.studentNavBulletBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.transparent : AppColors.studentEnrollLine,
                      ),
                    ),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppColors.studentNavBulletText,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    Flexible(child: _navBadgePill(badge!)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.studentEnrollBrand : AppColors.studentNavLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBadgePill(EnrollBadge badge) {
    final (bg, text, label) = enrollBadgeStyle(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: text, letterSpacing: 0.2),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
