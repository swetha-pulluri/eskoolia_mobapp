import '../utils/ifsc_lookup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/designation_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_files_draft.dart';
import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';
import '../widgets/hr_layout.dart';
import '../widgets/hr_staff_theme.dart';

const _tabFieldMap = <String, int>{
  'staff_no': 0, 'role': 0, 'first_name': 0, 'last_name': 0, 'gender': 0, 'date_of_birth': 0,
  'email': 0, 'phone': 0, 'emergency_mobile': 0, 'marital_status': 0, 'fathers_name': 0,
  'mothers_name': 0, 'driving_license': 0, 'staff_photo': 0, 'department': 0, 'designation': 0,
  'join_date': 0, 'current_address': 0, 'permanent_address': 0, 'qualification': 0, 'experience': 0,
  'epf_no': 1, 'basic_salary': 1, 'contract_type': 1, 'location': 1,
  'bank_account_name': 2, 'bank_account_no': 2, 'bank_name': 2, 'bank_branch': 2, 'ifsc_code': 2, 'bank_mobile_no': 2,
  'facebook_url': 3, 'twitter_url': 3, 'linkedin_url': 3, 'instagram_url': 3,
  'other_document': 4,
};

/// A literal port of the real, dormant-but-real `HrStaffPanel`
/// (`components/hr/HrPanels.tsx`, lines 1328-3266 on `main`) — 5-tab
/// Add/Edit Staff form, verified field-for-field against the live backend
/// (`StaffSerializer`/`StaffViewSet`). "Other Documents" only ever
/// transmits filenames, never the actual file bytes — a confirmed real
/// quirk of the web app itself, preserved here rather than silently fixed.
class StaffFormPage extends ConsumerStatefulWidget {
  final int? editId;
  final int initialTab;
  const StaffFormPage({super.key, this.editId, this.initialTab = 0});

  @override
  ConsumerState<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends ConsumerState<StaffFormPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab.clamp(0, 4));
  bool get _isEdit => widget.editId != null;

  final _staffNoCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _fathersNameCtrl = TextEditingController();
  final _mothersNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyMobileCtrl = TextEditingController();
  final _drivingLicenseCtrl = TextEditingController();
  final _currentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  String _gender = '';
  String _maritalStatus = '';
  DateTime? _dateOfBirth;
  DateTime? _joinDate;
  bool _showPublic = false;
  int? _roleId;
  int? _departmentId;
  int? _designationId;
  PickedAttachment? _staffPhoto;
  String _existingStaffPhoto = '';

  final _epfNoCtrl = TextEditingController();
  final _basicSalaryCtrl = TextEditingController(text: '0.00');
  final _allowanceCtrl = TextEditingController(text: '0.00');
  final _deductionCtrl = TextEditingController(text: '0.00');
  final _locationCtrl = TextEditingController();
  String _contractType = '';

  final _bankAccountNameCtrl = TextEditingController();
  final _bankAccountNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankBranchCtrl = TextEditingController();
  final _bankMobileNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  bool _ifscAutoFilled = false;
  bool _ifscLoading = false;
  String? _ifscError;

  final _facebookCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  PickedAttachment? _resume;
  PickedAttachment? _joiningLetter;
  PickedAttachment? _tenthCertificate;
  PickedAttachment? _eleventhCertificate;
  PickedAttachment? _aadharCard;
  PickedAttachment? _drivingLicenseDoc;
  String _existingResume = '', _existingJoiningLetter = '', _existingTenth = '', _existingEleventh = '', _existingAadhar = '', _existingDrivingLicenseDoc = '';
  final List<PickedOtherDocument> _otherDocuments = [];

  bool _loading = true;
  bool _saving = false;
  String? _topError;
  final Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _staffNoCtrl, _firstNameCtrl, _lastNameCtrl, _fathersNameCtrl, _mothersNameCtrl, _emailCtrl, _phoneCtrl,
      _emergencyMobileCtrl, _drivingLicenseCtrl, _currentAddressCtrl, _permanentAddressCtrl, _qualificationCtrl,
      _experienceCtrl, _epfNoCtrl, _basicSalaryCtrl, _allowanceCtrl, _deductionCtrl, _locationCtrl,
      _bankAccountNameCtrl, _bankAccountNoCtrl, _bankNameCtrl, _bankBranchCtrl, _bankMobileNoCtrl, _ifscCtrl,
      _facebookCtrl, _twitterCtrl, _linkedinCtrl, _instagramCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(hrRepositoryProvider);
    try {
      if (_isEdit) {
        final staff = await repo.getStaffById(widget.editId!);
        _staffNoCtrl.text = staff.staffNo;
        _firstNameCtrl.text = staff.firstName;
        _lastNameCtrl.text = staff.lastName;
        _fathersNameCtrl.text = staff.fathersName;
        _mothersNameCtrl.text = staff.mothersName;
        _emailCtrl.text = staff.email;
        _phoneCtrl.text = staff.phone;
        _emergencyMobileCtrl.text = staff.emergencyMobile;
        _drivingLicenseCtrl.text = staff.drivingLicense;
        _currentAddressCtrl.text = staff.currentAddress;
        _permanentAddressCtrl.text = staff.permanentAddress;
        _qualificationCtrl.text = staff.qualification;
        _experienceCtrl.text = staff.experience;
        _gender = staff.gender;
        _maritalStatus = staff.maritalStatus;
        _dateOfBirth = staff.dateOfBirth != null ? DateTime.tryParse(staff.dateOfBirth!) : null;
        _joinDate = DateTime.tryParse(staff.joinDate);
        _showPublic = staff.showPublic;
        _roleId = staff.roleId;
        _departmentId = staff.departmentId;
        _designationId = staff.designationId;
        _existingStaffPhoto = staff.staffPhoto;
        _epfNoCtrl.text = staff.epfNo;
        _basicSalaryCtrl.text = staff.basicSalary;
        _allowanceCtrl.text = staff.allowance;
        _deductionCtrl.text = staff.deduction;
        _locationCtrl.text = staff.location;
        _contractType = staff.contractType;
        _bankAccountNameCtrl.text = staff.bankAccountName;
        _bankAccountNoCtrl.text = staff.bankAccountNo;
        _bankNameCtrl.text = staff.bankName;
        _bankBranchCtrl.text = staff.bankBranch;
        _bankMobileNoCtrl.text = staff.bankMobileNo;
        _ifscCtrl.text = staff.ifscCode;
        _facebookCtrl.text = staff.facebookUrl;
        _twitterCtrl.text = staff.twitterUrl;
        _linkedinCtrl.text = staff.linkedinUrl;
        _instagramCtrl.text = staff.instagramUrl;
        _existingResume = staff.resume;
        _existingJoiningLetter = staff.joiningLetter;
        _existingTenth = staff.tenthCertificate;
        _existingEleventh = staff.eleventhCertificate;
        _existingAadhar = staff.aadharCard;
        _existingDrivingLicenseDoc = staff.drivingLicenseDoc;
        _otherDocuments.addAll(staff.otherDocument.map(PickedOtherDocument.new));
      } else {
        final nextNo = await repo.getNextStaffNo();
        _staffNoCtrl.text = nextNo;
      }
    } catch (e) {
      _topError = e is HrApiException ? e.message : 'Failed to load staff.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile(void Function(PickedAttachment) onPicked, {List<String>? extensions}) async {
    final result = await FilePicker.pickFiles(type: extensions == null ? FileType.any : FileType.custom, allowedExtensions: extensions, withData: true);
    final file = result?.files.firstOrNull;
    if (file?.bytes != null) {
      onPicked(PickedAttachment(name: file!.name, bytes: file.bytes!, size: file.size));
    }
  }

  Future<void> _pickOtherDocuments() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: false);
    if (result == null) return;
    setState(() {
      _otherDocuments.addAll(result.files.map((f) => PickedOtherDocument(f.name)));
      _fieldErrors.remove('other_document');
    });
  }

  void _onIfscChanged(String value) {
    final normalized = value.trim().toUpperCase();
    if (_ifscCtrl.text != normalized) {
      _ifscCtrl.value = _ifscCtrl.value.copyWith(text: normalized, selection: TextSelection.collapsed(offset: normalized.length));
    }
    setState(() {
      _ifscError = null;
      _ifscAutoFilled = false;
      _fieldErrors.remove('ifsc_code');
    });
    if (!isValidIfscFormat(normalized)) return;
    _lookupIfsc(normalized);
  }

  Future<void> _lookupIfsc(String code) async {
    setState(() => _ifscLoading = true);
    final result = await lookupIfsc(code);
    if (!mounted) return;
    setState(() {
      _ifscLoading = false;
      if (result != null && !result.isEmpty) {
        if (result.bankName.isNotEmpty) _bankNameCtrl.text = result.bankName;
        if (result.branch.isNotEmpty) _bankBranchCtrl.text = result.branch;
        _ifscAutoFilled = true;
      } else {
        _ifscError = 'Could not auto-fill bank details for this IFSC.';
      }
    });
  }

  bool _validate() {
    final errors = <String, String>{};
    if (_firstNameCtrl.text.trim().isEmpty) errors['first_name'] = 'First name is required.';
    if (_emailCtrl.text.trim().isEmpty) {
      errors['email'] = 'Email is required.';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailCtrl.text.trim())) {
      errors['email'] = 'Enter a valid email address.';
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      errors['phone'] = 'Mobile number is required.';
    } else if (!RegExp(r'^\d{1,12}$').hasMatch(_phoneCtrl.text.trim())) {
      errors['phone'] = 'Mobile number must contain digits only and must not exceed 12 digits.';
    }
    if (_roleId == null) errors['role'] = 'Role is required.';
    if (_joinDate == null) errors['join_date'] = 'Joining date is required.';
    if (_staffPhoto == null && _existingStaffPhoto.isEmpty) errors['staff_photo'] = 'Staff photo is required.';
    if (_currentAddressCtrl.text.trim().isEmpty) errors['current_address'] = 'Current address is required.';
    if (_permanentAddressCtrl.text.trim().isEmpty) errors['permanent_address'] = 'Permanent address is required.';
    if (_otherDocuments.isEmpty) errors['other_document'] = 'Signature upload is required.';
    if (_bankAccountNameCtrl.text.trim().isEmpty) errors['bank_account_name'] = 'Account holder name is required.';
    if (_bankAccountNoCtrl.text.trim().isEmpty) errors['bank_account_no'] = 'Enter valid account number';
    if (_bankNameCtrl.text.trim().isEmpty) errors['bank_name'] = 'Bank name is required.';
    if (_bankBranchCtrl.text.trim().isEmpty) errors['bank_branch'] = 'Branch name is required.';
    final salary = double.tryParse(_basicSalaryCtrl.text.trim());
    if (salary == null || salary <= 0) errors['basic_salary'] = 'Enter valid salary amount';
    if (_contractType.isEmpty) errors['contract_type'] = 'Select contract type';

    setState(() => _fieldErrors
      ..clear()
      ..addAll(errors));
    if (errors.isNotEmpty) {
      final firstTab = errors.keys.map((k) => _tabFieldMap[k] ?? 0).reduce((a, b) => a < b ? a : b);
      _tabController.animateTo(firstTab);
    }
    return errors.isEmpty;
  }

  String? _fmtDate(DateTime? d) => d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    setState(() => _topError = null);
    if (!_validate()) {
      setState(() => _topError = 'Please fix the highlighted fields.');
      return;
    }
    setState(() => _saving = true);
    final draft = StaffEntity(
      id: widget.editId ?? 0,
      staffNo: _staffNoCtrl.text.trim(),
      roleId: _roleId,
      departmentId: _departmentId,
      designationId: _designationId,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      fathersName: _fathersNameCtrl.text.trim(),
      mothersName: _mothersNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gender: _gender,
      dateOfBirth: _fmtDate(_dateOfBirth),
      joinDate: _fmtDate(_joinDate) ?? '',
      phone: _phoneCtrl.text.trim(),
      maritalStatus: _maritalStatus,
      emergencyMobile: _emergencyMobileCtrl.text.trim(),
      drivingLicense: _drivingLicenseCtrl.text.trim(),
      staffPhoto: _existingStaffPhoto,
      showPublic: _showPublic,
      currentAddress: _currentAddressCtrl.text.trim(),
      permanentAddress: _permanentAddressCtrl.text.trim(),
      qualification: _qualificationCtrl.text.trim(),
      experience: _experienceCtrl.text.trim(),
      epfNo: _epfNoCtrl.text.trim(),
      basicSalary: _basicSalaryCtrl.text.trim(),
      contractType: _contractType,
      location: _locationCtrl.text.trim(),
      bankAccountName: _bankAccountNameCtrl.text.trim(),
      bankAccountNo: _bankAccountNoCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      bankBranch: _bankBranchCtrl.text.trim(),
      bankMobileNo: _bankMobileNoCtrl.text.trim(),
      customField: {
        if (_ifscCtrl.text.trim().isNotEmpty) 'ifsc_code': _ifscCtrl.text.trim(),
        'allowance': _allowanceCtrl.text.trim().isEmpty ? '0.00' : _allowanceCtrl.text.trim(),
        'deduction': _deductionCtrl.text.trim().isEmpty ? '0.00' : _deductionCtrl.text.trim(),
      },
      facebookUrl: _facebookCtrl.text.trim(),
      twitterUrl: _twitterCtrl.text.trim(),
      linkedinUrl: _linkedinCtrl.text.trim(),
      instagramUrl: _instagramCtrl.text.trim(),
      resume: _existingResume,
      joiningLetter: _existingJoiningLetter,
      tenthCertificate: _existingTenth,
      eleventhCertificate: _existingEleventh,
      aadharCard: _existingAadhar,
      drivingLicenseDoc: _existingDrivingLicenseDoc,
      status: 'active',
    );
    final files = StaffFilesDraft(
      staffPhoto: _staffPhoto,
      resume: _resume,
      joiningLetter: _joiningLetter,
      tenthCertificate: _tenthCertificate,
      eleventhCertificate: _eleventhCertificate,
      aadharCard: _aadharCard,
      drivingLicenseDoc: _drivingLicenseDoc,
    );
    try {
      final repo = ref.read(hrRepositoryProvider);
      if (_isEdit) {
        await repo.updateStaff(widget.editId!, draft, files: files, otherDocuments: _otherDocuments);
      } else {
        await repo.createStaff(draft, files: files, otherDocuments: _otherDocuments);
      }
      if (!mounted) return;
      invalidateStaffDirectory(ref);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Staff updated successfully.' : 'Staff created successfully.')));
      context.go('/hr/directory');
    } catch (e) {
      if (e is HrApiException) {
        setState(() {
          _topError = e.message;
          _fieldErrors.addAll(e.fieldErrors);
        });
        if (e.fieldErrors.isNotEmpty) {
          final firstTab = e.fieldErrors.keys.map((k) => _tabFieldMap[k] ?? 0).reduce((a, b) => a < b ? a : b);
          _tabController.animateTo(firstTab);
        }
      } else {
        setState(() => _topError = 'Failed to save staff.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const HrLayout(currentPath: '/hr/directory', child: Center(child: CircularProgressIndicator()));
    }
    final formOptionsAsync = ref.watch(staffFormOptionsProvider);
    final formOptions = formOptionsAsync.valueOrNull;

    return HrLayout(
      currentPath: '/hr/directory',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(_isEdit ? 'Edit Staff' : 'Add Staff', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: HrStaffColors.text)),
          ),
          if (_topError != null)
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(_topError!, style: const TextStyle(color: HrStaffColors.warning))),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: HrStaffColors.primary,
            tabs: const [
              Tab(text: 'Basic Info'),
              Tab(text: 'Payroll Details'),
              Tab(text: 'Bank Info Details'),
              Tab(text: 'Social Links Details'),
              Tab(text: 'Document Info'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _basicTab(formOptions),
                _payrollTab(),
                _bankTab(),
                _socialTab(),
                _documentTab(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => context.go('/hr/directory'), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: HrStaffColors.primary),
                    onPressed: _saving ? null : _submit,
                    child: Text(_saving ? 'Saving...' : (_isEdit ? 'Update Staff' : 'Save Staff')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────

  Widget _basicTab(dynamic formOptions) {
    final roles = (formOptions?.roles as List<RoleEntity>?) ?? const <RoleEntity>[];
    final departments = (formOptions?.departments as List<DepartmentEntity>?) ?? const <DepartmentEntity>[];
    final allDesignations = (formOptions?.designations as List<DesignationEntity>?) ?? const <DesignationEntity>[];
    final designations = _departmentId == null ? allDesignations : allDesignations.where((d) => d.departmentId == _departmentId).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('Basic Information'),
        _row([
          _field('Staff No *', TextField(controller: _staffNoCtrl, readOnly: true, decoration: _dec()), error: _fieldErrors['staff_no']),
          _field('First Name *', TextField(controller: _firstNameCtrl, decoration: _dec()), error: _fieldErrors['first_name']),
          _field('Last Name', TextField(controller: _lastNameCtrl, decoration: _dec())),
        ]),
        _row([
          _field('Gender', _dropdown(_gender.isEmpty ? null : _gender, const {'male': 'Male', 'female': 'Female', 'other': 'Other'}, 'Select', (v) => setState(() => _gender = v ?? ''))),
          _field('Date Of Birth', _datePicker(_dateOfBirth, (d) => setState(() => _dateOfBirth = d))),
          _field('Email *', TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _dec()), error: _fieldErrors['email']),
        ]),
        _row([
          _field('Mobile Number *', TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 12, decoration: _dec(counter: false)), error: _fieldErrors['phone']),
          _field('Emergency Mobile', TextField(controller: _emergencyMobileCtrl, keyboardType: TextInputType.phone, maxLength: 12, decoration: _dec(counter: false))),
          _field('Marital Status', _dropdown(_maritalStatus.isEmpty ? null : _maritalStatus, const {'single': 'Single', 'married': 'Married'}, 'Select', (v) => setState(() => _maritalStatus = v ?? ''))),
        ]),
        _row([
          _field('Father Name', TextField(controller: _fathersNameCtrl, decoration: _dec())),
          _field('Mother Name', TextField(controller: _mothersNameCtrl, decoration: _dec())),
          _field('Driving License', TextField(controller: _drivingLicenseCtrl, decoration: _dec())),
        ]),
        _row([
          _field('Show As Expert Staff', RadioGroup<bool>(
            groupValue: _showPublic,
            onChanged: (v) => setState(() => _showPublic = v ?? false),
            child: Row(children: const [
              Expanded(child: RadioListTile<bool>(value: true, title: Text('Yes'), dense: true, contentPadding: EdgeInsets.zero)),
              Expanded(child: RadioListTile<bool>(value: false, title: Text('No'), dense: true, contentPadding: EdgeInsets.zero)),
            ]),
          )),
        ]),
        _field('Staff Photo *', _filePickerTile(_staffPhoto, _existingStaffPhoto, () => _pickFile((f) => setState(() { _staffPhoto = f; _fieldErrors.remove('staff_photo'); }), extensions: ['jpg', 'jpeg', 'png']), () => setState(() => _staffPhoto = null)), error: _fieldErrors['staff_photo']),
        const SizedBox(height: 8),
        _sectionLabel('Job Details'),
        _row([
          _field('Role *', _dropdown(_roleId, {for (final r in roles) r.id: r.name}, 'Select role', (v) => setState(() => _roleId = v)), error: _fieldErrors['role']),
          _field('Department', _dropdown(_departmentId, {for (final d in departments) d.id: d.name}, 'Select department', (v) => setState(() { _departmentId = v; _designationId = null; }))),
          _field('Designation', _dropdown(_designationId, {for (final d in designations) d.id: d.name}, 'Select designation', (v) => setState(() => _designationId = v))),
        ]),
        _field('Date Of Joining *', _datePicker(_joinDate, (d) => setState(() => _joinDate = d)), error: _fieldErrors['join_date']),
        const SizedBox(height: 8),
        _sectionLabel('Additional Information'),
        _field('Current Address *', TextField(controller: _currentAddressCtrl, maxLines: 2, decoration: _dec()), error: _fieldErrors['current_address']),
        _field('Permanent Address *', TextField(controller: _permanentAddressCtrl, maxLines: 2, decoration: _dec()), error: _fieldErrors['permanent_address']),
        _field('Qualifications', TextField(controller: _qualificationCtrl, maxLines: 2, decoration: _dec())),
        _field('Experience', TextField(controller: _experienceCtrl, maxLines: 2, decoration: _dec())),
      ],
    );
  }

  Widget _payrollTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row([
          _field('EPF Number', TextField(controller: _epfNoCtrl, decoration: _dec()), error: _fieldErrors['epf_no']),
          _field('Basic Salary *', TextField(controller: _basicSalaryCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _dec()), error: _fieldErrors['basic_salary']),
        ]),
        _row([
          _field('Allowances', TextField(controller: _allowanceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _dec())),
          _field('Deductions', TextField(controller: _deductionCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _dec())),
        ]),
        _field('Net Salary (Preview)', TextField(
          readOnly: true,
          decoration: _dec(),
          controller: TextEditingController(
            text: (((double.tryParse(_basicSalaryCtrl.text) ?? 0) + (double.tryParse(_allowanceCtrl.text) ?? 0) - (double.tryParse(_deductionCtrl.text) ?? 0))).toStringAsFixed(2),
          ),
        )),
        _row([
          _field('Contract Type *', _dropdown(_contractType.isEmpty ? null : _contractType, const {'permanent': 'Permanent', 'contract': 'Contract'}, 'Select', (v) => setState(() => _contractType = v ?? '')), error: _fieldErrors['contract_type']),
          _field('Location', TextField(controller: _locationCtrl, decoration: _dec())),
        ]),
      ],
    );
  }

  Widget _bankTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('Account Holder Name *', TextField(controller: _bankAccountNameCtrl, decoration: _dec()), error: _fieldErrors['bank_account_name']),
        _field('Account Number *', TextField(controller: _bankAccountNoCtrl, keyboardType: TextInputType.number, maxLength: 18, decoration: _dec(counter: false)), error: _fieldErrors['bank_account_no']),
        _field('IFSC Code *', TextField(controller: _ifscCtrl, maxLength: 11, textCapitalization: TextCapitalization.characters, decoration: _dec(counter: false, suffix: _ifscLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null), onChanged: _onIfscChanged), error: _fieldErrors['ifsc_code'] ?? _ifscError),
        _row([
          _field('Bank Name *', TextField(controller: _bankNameCtrl, enabled: !_ifscAutoFilled, decoration: _dec()), error: _fieldErrors['bank_name']),
          _field('Branch Name *', TextField(controller: _bankBranchCtrl, enabled: !_ifscAutoFilled, decoration: _dec()), error: _fieldErrors['bank_branch']),
        ]),
        _field('Bank Contact Mobile', TextField(controller: _bankMobileNoCtrl, keyboardType: TextInputType.phone, maxLength: 12, decoration: _dec(counter: false)), error: _fieldErrors['bank_mobile_no']),
      ],
    );
  }

  Widget _socialTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('Facebook URL', TextField(controller: _facebookCtrl, decoration: _dec()), error: _fieldErrors['facebook_url']),
        _field('Twitter URL', TextField(controller: _twitterCtrl, decoration: _dec()), error: _fieldErrors['twitter_url']),
        _field('LinkedIn URL', TextField(controller: _linkedinCtrl, decoration: _dec()), error: _fieldErrors['linkedin_url']),
        _field('Instagram URL', TextField(controller: _instagramCtrl, decoration: _dec()), error: _fieldErrors['instagram_url']),
      ],
    );
  }

  Widget _documentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('Resume', _filePickerTile(_resume, _existingResume, () => _pickFile((f) => setState(() => _resume = f)), () => setState(() => _resume = null))),
        _field('Joining Letter', _filePickerTile(_joiningLetter, _existingJoiningLetter, () => _pickFile((f) => setState(() => _joiningLetter = f)), () => setState(() => _joiningLetter = null))),
        _field('10th Certificate', _filePickerTile(_tenthCertificate, _existingTenth, () => _pickFile((f) => setState(() => _tenthCertificate = f)), () => setState(() => _tenthCertificate = null))),
        _field('11th/12th Certificate', _filePickerTile(_eleventhCertificate, _existingEleventh, () => _pickFile((f) => setState(() => _eleventhCertificate = f)), () => setState(() => _eleventhCertificate = null))),
        _field('Aadhar Card', _filePickerTile(_aadharCard, _existingAadhar, () => _pickFile((f) => setState(() => _aadharCard = f)), () => setState(() => _aadharCard = null))),
        _field('Driving License (doc)', _filePickerTile(_drivingLicenseDoc, _existingDrivingLicenseDoc, () => _pickFile((f) => setState(() => _drivingLicenseDoc = f)), () => setState(() => _drivingLicenseDoc = null))),
        _field(
          'Other Documents *',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final d in _otherDocuments)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Expanded(child: Text(d.name, overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _otherDocuments.remove(d))),
                ]),
              ),
            OutlinedButton.icon(onPressed: _pickOtherDocuments, icon: const Icon(Icons.attach_file, size: 16), label: const Text('Add files')),
          ]),
          error: _fieldErrors['other_document'],
        ),
      ],
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: HrStaffColors.textMuted)),
      );

  Widget _row(List<Widget> children) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final c in children) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))]);

  Widget _field(String label, Widget child, {String? error}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HrStaffColors.textMuted)),
          const SizedBox(height: 4),
          child,
          if (error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(error, style: const TextStyle(fontSize: 11, color: HrStaffColors.errorRed))),
        ],
      ),
    );
  }

  InputDecoration _dec({bool counter = true, Widget? suffix}) => InputDecoration(border: const OutlineInputBorder(), isDense: true, counterText: counter ? null : '', suffixIcon: suffix);

  Widget _dropdown(dynamic value, Map<dynamic, String> options, String hint, ValueChanged<dynamic> onChanged) {
    return DropdownButtonFormField<dynamic>(
      initialValue: options.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: _dec(),
      items: [
        DropdownMenuItem(value: null, child: Text(hint)),
        for (final entry in options.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }

  Widget _datePicker(DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: value ?? DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime(2100));
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: _dec(),
        child: Text(value == null ? 'Select date' : _fmtDate(value)!, style: TextStyle(color: value == null ? Colors.grey : null)),
      ),
    );
  }

  Widget _filePickerTile(PickedAttachment? picked, String existing, VoidCallback onPick, VoidCallback onClear) {
    final label = picked?.name ?? (existing.isNotEmpty ? existing : 'Tap to choose a file');
    return Row(children: [
      Expanded(
        child: InkWell(
          onTap: onPick,
          child: InputDecorator(decoration: _dec(), child: Text(label, overflow: TextOverflow.ellipsis)),
        ),
      ),
      if (picked != null) IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onClear),
    ]);
  }
}
