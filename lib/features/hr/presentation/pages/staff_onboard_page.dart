import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/onboard_draft_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_files_draft.dart';
import '../../domain/repositories/hr_repository.dart';
import '../providers/hr_provider.dart';
import '../widgets/hr_layout.dart';
import '../widgets/hr_theme.dart';
import '../widgets/onboard/onboard_steps.dart';
import '../widgets/onboard/onboard_validators.dart';
import '../widgets/onboard/step_contact.dart';
import '../widgets/onboard/step_documents.dart';
import '../widgets/onboard/step_family.dart';
import '../widgets/onboard/step_gov_id.dart';
import '../widgets/onboard/step_identity.dart';
import '../widgets/onboard/step_medical.dart';
import '../widgets/onboard/step_payroll.dart';
import '../widgets/onboard/step_qualifications.dart';
import '../widgets/onboard/step_review.dart';
import '../widgets/onboard/step_role.dart';
import 'staff_verification_preview_page.dart';

/// A real, connected port of the live web's 10-step `/hr/onboard` wizard —
/// verified read-only against `demo`/`BugFix`'s frontend (`hr/onboard/
/// page.tsx`) and backend (`StaffOnboardDraft`/`StaffOnboardDocument`
/// models, reportlab PDF views, `/api/v1/master/*`, pincode proxy — all
/// confirmed real, not stubs). Decorative-only on the real web too: AI
/// Assist, "Scan to pre-fill"/"Scan now", Upload signed, Scan & fill,
/// "What I'll need" — kept as the same toast-only stubs here. "Print/PDF"
/// has no mobile equivalent to the web's `window.print()`, so it downloads
/// and shares the real filled-form PDF instead.
///
/// The extra fields this wizard collects beyond the existing 5-tab
/// `StaffFormPage`'s schema (blood group, nationality, emergency contacts,
/// nominees, qualifications, previous employment, medical/disability,
/// address breakdown, etc.) are carried through the real `Staff.custom_field`
/// JSONField — a genuine schema-less blob on the backend — rather than
/// silently dropped or requiring a wider `StaffEntity` rewrite.
class StaffOnboardPage extends ConsumerStatefulWidget {
  final int? editId;
  final int? resumeDraftId;
  final int? initialDepartmentId;
  final int? initialStep;

  const StaffOnboardPage({super.key, this.editId, this.resumeDraftId, this.initialDepartmentId, this.initialStep});

  @override
  ConsumerState<StaffOnboardPage> createState() => _StaffOnboardPageState();
}

class _StaffOnboardPageState extends ConsumerState<StaffOnboardPage> {
  PickedAttachment? _photo;
  bool _bannerDismissed = false;
  bool _loadingInitial = false;
  bool _submitting = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (widget.editId != null) {
        await _loadFromStaff(widget.editId!);
      } else if (widget.resumeDraftId != null) {
        await _loadFromDraft(widget.resumeDraftId!);
      } else if (widget.initialDepartmentId != null) {
        _onChange('department', widget.initialDepartmentId.toString());
      }
      if (widget.initialStep != null) {
        final step = widget.initialStep!.clamp(1, onboardTotalSteps);
        ref.read(onboardStepProvider.notifier).state = step;
        if (step > ref.read(onboardHighestStepProvider)) ref.read(onboardHighestStepProvider.notifier).state = step;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onChange(String key, dynamic value) {
    final current = ref.read(onboardFormProvider);
    ref.read(onboardFormProvider.notifier).state = {...current, key: value};
  }

  Future<void> _loadFromStaff(int id) async {
    setState(() => _loadingInitial = true);
    try {
      final staff = await ref.read(hrRepositoryProvider).getStaffById(id);
      ref.read(onboardFormProvider.notifier).state = _formFromStaff(staff);
    } catch (e) {
      if (mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to load staff record.', type: 'error');
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  Future<void> _loadFromDraft(int draftId) async {
    setState(() => _loadingInitial = true);
    try {
      final drafts = await ref.read(hrRepositoryProvider).getOnboardDrafts();
      final draft = drafts.where((d) => d.id == draftId).firstOrNull;
      if (draft != null) {
        ref.read(onboardFormProvider.notifier).state = draft.formData;
        ref.read(onboardDraftIdProvider.notifier).state = draft.id;
        ref.read(onboardStepProvider.notifier).state = draft.currentStep;
        ref.read(onboardHighestStepProvider.notifier).state = draft.currentStep;
      }
    } catch (e) {
      if (mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to load draft.', type: 'error');
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  Map<String, dynamic> _formFromStaff(StaffEntity s) {
    final custom = s.customField;
    return {
      'first_name': s.firstName,
      'last_name': s.lastName,
      'date_of_birth': s.dateOfBirth ?? '',
      'gender': s.gender.isEmpty ? '' : (s.gender[0].toUpperCase() + s.gender.substring(1)),
      'status': s.status == 'active' ? 'active' : 'inactive',
      'staff_no': s.staffNo,
      'department': s.departmentId?.toString() ?? '',
      'designation': s.designationId?.toString() ?? '',
      'role': s.roleId?.toString() ?? '',
      'joining_date': s.joinDate,
      'contract_type': s.contractType,
      'mobile': s.phone,
      'personal_email': s.email,
      'current_address': s.currentAddress,
      'permanent_address': s.permanentAddress,
      'bank_account_name': s.bankAccountName,
      'bank_account_no': s.bankAccountNo,
      'bank_name': s.bankName,
      'bank_branch': s.bankBranch,
      'ifsc_code': custom['ifsc_code'] ?? '',
      'basic_salary_input': s.basicSalary,
      'marital_status': s.maritalStatus == 'married' ? 'Married' : (s.maritalStatus.isEmpty ? '' : 'Single'),
      'blood_group_input': custom['blood_group'] ?? '',
      'nationality': custom['nationality'] ?? '',
      'mother_tongue': custom['mother_tongue'] ?? '',
      'religion': custom['religion'] ?? '',
      'nin': custom['aadhaar_number'] ?? '',
      'pan': custom['pan_number'] ?? '',
      'emergency_contacts': custom['emergency_contacts'] ?? const [],
      'nominees': custom['nominees'] ?? const [],
      'qualifications': custom['qualifications'] ?? const [],
      'previous_employment': custom['previous_employment'] ?? const [],
    };
  }

  Future<void> _saveDraft() async {
    final form = ref.read(onboardFormProvider);
    if ((form['first_name'] as String? ?? '').trim().isEmpty) {
      showHrToast(context, 'Enter at least the staff member\'s first name before saving a draft.', type: 'error');
      return;
    }
    try {
      final draft = await ref.read(hrRepositoryProvider).saveOnboardDraft(
            id: ref.read(onboardDraftIdProvider),
            formData: form,
            currentStep: ref.read(onboardStepProvider),
          );
      ref.read(onboardDraftIdProvider.notifier).state = draft.id;
      invalidateOnboardDrafts(ref);
      if (mounted) showHrToast(context, 'Draft "${draft.draftName}" saved');
    } catch (e) {
      if (mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to save draft.', type: 'error');
    }
  }

  Future<void> _showDraftsSheet() async {
    final drafts = await ref.refresh(onboardDraftsProvider.future).catchError((_) => <OnboardDraftEntity>[]);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Drafts (${drafts.length}/10)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (drafts.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No saved drafts yet.', style: TextStyle(color: HrColors.muted))),
              for (final d in drafts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.draftName.isEmpty ? 'Untitled draft' : d.draftName),
                  subtitle: Text('Step ${d.currentStep}/10'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(onboardFormProvider.notifier).state = d.formData;
                    ref.read(onboardDraftIdProvider.notifier).state = d.id;
                    ref.read(onboardStepProvider.notifier).state = d.currentStep;
                    ref.read(onboardHighestStepProvider.notifier).state = d.currentStep;
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: HrColors.red),
                    onPressed: () async {
                      try {
                        await ref.read(hrRepositoryProvider).deleteOnboardDraft(d.id);
                        invalidateOnboardDrafts(ref);
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        if (context.mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to delete draft.', type: 'error');
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStepJumpSheet() async {
    final current = ref.read(onboardStepProvider);
    final highest = ref.read(onboardHighestStepProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          children: [
            for (final g in onboardStepGroups) ...[
              Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(g.group.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: HrColors.muted))),
              for (final s in g.steps)
                ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: s.num < highest ? HrColors.green : (s.num == current ? HrColors.brand : const Color(0xFFF1F5F9)),
                    child: Text(s.num < highest ? '✓' : '${s.num}', style: TextStyle(fontSize: 11, color: s.num <= highest || s.num == current ? Colors.white : const Color(0xFF64748B))),
                  ),
                  title: Text(s.label, style: TextStyle(fontWeight: s.num == current ? FontWeight.w800 : FontWeight.w600)),
                  subtitle: Text(s.sub, style: const TextStyle(fontSize: 11.5)),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref.read(onboardStepProvider.notifier).state = s.num;
                    if (s.num > highest) ref.read(onboardHighestStepProvider.notifier).state = s.num;
                    _scrollController.jumpTo(0);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _goBack() {
    final step = ref.read(onboardStepProvider);
    if (step > 1) ref.read(onboardStepProvider.notifier).state = step - 1;
  }

  Future<void> _goNext() async {
    final step = ref.read(onboardStepProvider);
    final form = ref.read(onboardFormProvider);

    if (step == 9) {
      final docs = ref.read(onboardDocumentsProvider).valueOrNull ?? const [];
      final missing = [
        if (!docs.any((d) => d.docKey == 'signature')) 'Signature',
        if (!docs.any((d) => d.docKey == 'aadhaar')) 'Aadhaar Card',
      ];
      if (missing.isNotEmpty) {
        showHrToast(context, 'Missing required documents: ${missing.join(', ')}', type: 'error');
        return;
      }
    } else {
      final errors = validateOnboardStep(step, form);
      if (errors.isNotEmpty) {
        showHrToast(context, errors.first, type: 'error');
        return;
      }
    }

    if (step >= onboardTotalSteps) {
      await _submit();
      return;
    }
    final next = step + 1;
    ref.read(onboardStepProvider.notifier).state = next;
    final highest = ref.read(onboardHighestStepProvider);
    if (next > highest) ref.read(onboardHighestStepProvider.notifier).state = next;
    _scrollController.jumpTo(0);
  }

  String _inferContractType(String employmentType) {
    return employmentType.toLowerCase().contains('contract') ? 'contract' : 'permanent';
  }

  String _summarizeList(List rows, String Function(Map) render) {
    return rows.cast<Map>().map(render).where((s) => s.trim().isNotEmpty).join('; ');
  }

  Future<void> _submit() async {
    final form = ref.read(onboardFormProvider);
    const requiredKeys = ['first_name', 'last_name', 'department', 'designation', 'joining_date', 'bank_account_name', 'bank_account_no', 'bank_name', 'basic_salary_input'];
    final missingLabels = <String>[];
    for (final k in requiredKeys) {
      if ((form[k]?.toString() ?? '').trim().isEmpty) missingLabels.add(k.replaceAll('_', ' '));
    }
    if (missingLabels.isNotEmpty) {
      showHrToast(context, 'Missing required fields: ${missingLabels.join(', ')}', type: 'error');
      return;
    }

    setState(() => _submitting = true);
    try {
      var staffNo = form['staff_no'] as String? ?? '';
      if (staffNo.isEmpty) staffNo = await ref.read(hrRepositoryProvider).getNextStaffNo();

      final docs = ref.read(onboardDocumentsProvider).valueOrNull ?? const [];
      final signatureDoc = docs.where((d) => d.docKey == 'signature').firstOrNull;

      final emergencyContacts = (form['emergency_contacts'] as List?) ?? const [];
      final row0 = emergencyContacts.isNotEmpty ? emergencyContacts.first as Map : const {};

      final maritalStatus = form['marital_status'] as String? ?? '';
      final email = (form['official_email'] as String?)?.isNotEmpty == true ? form['official_email'] as String : (form['personal_email'] as String? ?? '');

      // Mother Tongue/Religion/Nationality/Employment Type store the literal
      // 'Other' in their own key when that option is picked (matching the
      // web's `SearchableSelect` contract) — prefer the typed free-text here
      // so it isn't lost, falling back to the literal 'Other' only if none
      // was typed.
      String masterValue(String key) {
        final v = form[key] as String? ?? '';
        if (v != 'Other') return v;
        final other = form['${key}_other'] as String? ?? '';
        return other.isNotEmpty ? other : v;
      }

      // StepRole's Designation dropdown uses a fixed list with negative
      // sentinel ids (see step_role.dart's `_fixedDesignations`) — those
      // don't correspond to any real `/api/v1/hr/designations/` row, so
      // treat them as "no designation" rather than sending a bogus id (the
      // backend's `designation` FK is nullable).
      final parsedDesignationId = int.tryParse(form['designation']?.toString() ?? '');
      final designationId = (parsedDesignationId != null && parsedDesignationId > 0) ? parsedDesignationId : null;

      final customField = <String, dynamic>{
        'ifsc_code': form['ifsc_code'] ?? '',
        'allowance': '0.00',
        'deduction': '0.00',
        'blood_group': form['blood_group_input'] ?? '',
        'nationality': masterValue('nationality'),
        'mother_tongue': masterValue('mother_tongue'),
        'religion': masterValue('religion'),
        'preferred_communication': form['preferred_communication'] ?? '',
        'personal_email': form['personal_email'] ?? '',
        'official_email': form['official_email'] ?? '',
        'whatsapp': form['whatsapp'] ?? '',
        'alternate_mobile': form['alternate_mobile'] ?? '',
        'city': form['city'] ?? '',
        'state': form['state'] ?? '',
        'current_pin': form['current_pin'] ?? '',
        'current_country': form['current_country'] ?? '',
        'aadhaar_number': form['nin'] ?? '',
        'pan_number': form['pan'] ?? '',
        'passport_no': form['passport_no'] ?? '',
        'driving_licence': form['driving_licence'] ?? '',
        'uan': form['uan'] ?? '',
        'esi_no': form['esi_no'] ?? '',
        'pt_registration': form['pt_registration'] ?? '',
        'employment_type': masterValue('employment_type'),
        'probation_value': form['probation_value'] ?? '',
        'probation_unit': form['probation_unit'] ?? '',
        'reporting_manager': form['reporting_manager'] ?? '',
        'marital_status_detail': maritalStatus,
        'num_children': form['num_children'] ?? '',
        'spouse_parent_name': form['spouse_parent_name'] ?? '',
        'emergency_contacts': emergencyContacts,
        'nominees': form['nominees'] ?? const [],
        'qualifications': form['qualifications'] ?? const [],
        'previous_employment': form['previous_employment'] ?? const [],
        'disability_status': form['disability_status'] ?? '',
        'disability_cert_no': form['disability_cert_no'] ?? '',
        'disability_pct': form['disability_pct'] ?? '',
        'disability_authority': form['disability_authority'] ?? '',
        'workplace_accommodations': form['workplace_accommodations'] ?? '',
        'med_cert_no': form['med_cert_no'] ?? '',
        'med_exam_date': form['med_exam_date'] ?? '',
        'cert_valid_till': form['cert_valid_till'] ?? '',
      };

      final sameAddress = form['same_address'] == 'true';
      final qualificationsSummary = _summarizeList(
        (form['qualifications'] as List?) ?? const [],
        (q) => [q['degree'], q['university'], q['year']].where((v) => (v?.toString() ?? '').isNotEmpty).join(', '),
      );
      final experienceSummary = _summarizeList(
        (form['previous_employment'] as List?) ?? const [],
        (e) => [e['employer'], e['designation'], e['experience'] != null ? '${e['experience']} yrs' : null].where((v) => (v?.toString() ?? '').isNotEmpty).join(', '),
      );

      final draft = StaffEntity(
        id: widget.editId ?? 0,
        staffNo: staffNo,
        firstName: (form['first_name'] as String? ?? '').trim(),
        lastName: (form['last_name'] as String? ?? '').trim(),
        dateOfBirth: (form['date_of_birth'] as String?)?.isNotEmpty == true ? form['date_of_birth'] as String : null,
        email: email,
        phone: form['mobile'] as String? ?? '',
        emergencyMobile: (row0['mobile'] as String? ?? ''),
        gender: (form['gender'] as String? ?? '').toLowerCase(),
        maritalStatus: maritalStatus == 'Married' ? 'married' : 'single',
        drivingLicense: form['driving_licence'] as String? ?? '',
        currentAddress: form['current_address'] as String? ?? '',
        permanentAddress: sameAddress ? (form['current_address'] as String? ?? '') : (form['permanent_address'] as String? ?? ''),
        qualification: qualificationsSummary,
        experience: experienceSummary,
        epfNo: form['uan'] as String? ?? '',
        bankAccountName: form['bank_account_name'] as String? ?? '',
        bankAccountNo: form['bank_account_no'] as String? ?? '',
        bankName: form['bank_name'] as String? ?? '',
        bankBranch: form['bank_branch'] as String? ?? '',
        departmentId: int.tryParse(form['department']?.toString() ?? ''),
        designationId: designationId,
        roleId: int.tryParse(form['role']?.toString() ?? ''),
        contractType: _inferContractType(masterValue('employment_type')),
        joinDate: form['joining_date'] as String? ?? '',
        basicSalary: form['basic_salary_input'] as String? ?? '0.00',
        status: (form['status'] as String? ?? 'active'),
        customField: customField,
        otherDocument: signatureDoc != null ? [signatureDoc.fileName] : const [],
      );

      final files = StaffFilesDraft(staffPhoto: _photo);
      final repo = ref.read(hrRepositoryProvider);
      if (widget.editId != null) {
        await repo.updateStaff(widget.editId!, draft, files: files);
      } else {
        await repo.createStaff(draft, files: files);
      }

      if (ref.read(onboardDraftIdProvider) != null) {
        try {
          await repo.deleteOnboardDraft(ref.read(onboardDraftIdProvider)!);
        } catch (_) {
          // Non-blocking — the staff record was already created successfully.
        }
      }
      invalidateStaffDirectory(ref);
      invalidateOnboardDrafts(ref);
      if (!mounted) return;
      showHrToast(context, widget.editId != null ? 'Staff updated successfully.' : 'Staff onboarded successfully.');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/hr/directory');
      }
    } catch (e) {
      if (mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to submit.', type: 'error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openVerificationPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => StaffVerificationPreviewPage(form: ref.read(onboardFormProvider))),
    );
  }

  Future<void> _downloadBlankForm() async {
    try {
      final bytes = await ref.read(hrRepositoryProvider).downloadBlankForm();
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), name: 'staff-onboarding-blank-form.pdf', mimeType: 'application/pdf')]);
    } catch (e) {
      if (mounted) showHrToast(context, e is HrApiException ? e.message : 'Failed to generate PDF.', type: 'error');
    }
  }

  void _stub(String message) => showHrToast(context, message, type: 'info');

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardFormProvider);
    final step = ref.watch(onboardStepProvider);
    final draftsAsync = ref.watch(onboardDraftsProvider);
    final activeStaffAsync = ref.watch(activeStaffProvider);
    final stepInfo = onboardStepByNum(step);

    return HrLayout(
      currentPath: '/hr/onboard',
      child: _loadingInitial
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/hr/directory'), icon: const Icon(Icons.arrow_back)),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: HrColors.ink), children: [
                                    const TextSpan(text: 'Onboard a '),
                                    TextSpan(text: 'staff member', style: TextStyle(color: HrColors.brand, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400)),
                                  ]),
                                ),
                              ),
                              Text('${activeStaffAsync.valueOrNull?.count ?? '—'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: HrColors.ink)),
                            ]),
                            const Text('CURRENT STAFF', style: TextStyle(fontSize: 10, color: HrColors.muted, letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              OutlinedButton.icon(
                                onPressed: _showDraftsSheet,
                                icon: const Icon(Icons.description_outlined, size: 15),
                                label: Text('Drafts${draftsAsync.valueOrNull != null ? ' (${draftsAsync.valueOrNull!.length})' : ''}'),
                              ),
                              OutlinedButton.icon(onPressed: () => _stub('AI Assist coming soon'), icon: const Icon(Icons.auto_awesome, size: 15), label: const Text('AI Assist')),
                              OutlinedButton.icon(
                                onPressed: _openVerificationPreview,
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                                label: const Text('PDF'),
                              ),
                              OutlinedButton.icon(onPressed: () => _stub('Documents checklist: Aadhaar, PAN, photo, bank proof, certificates, offer letter'), icon: const Icon(Icons.info_outline, size: 15), label: const Text("What I'll need")),
                            ]),
                            if (!_bannerDismissed) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: HrColors.ink, borderRadius: BorderRadius.circular(12)),
                                child: Row(children: [
                                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  const Expanded(child: Text('Scan to pre-fill — Got Aadhaar QR, PAN, or a joining form? Scan it once to prepare fields.', style: TextStyle(color: Colors.white, fontSize: 12))),
                                  TextButton(onPressed: () => _stub('QR scanner coming soon'), child: const Text('Scan now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                                  IconButton(onPressed: () => setState(() => _bannerDismissed = true), icon: const Icon(Icons.close, color: Colors.white70, size: 16)),
                                ]),
                              ),
                            ],
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _showStepJumpSheet,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Expanded(
                                    child: Text(
                                      'Step $step/$onboardTotalSteps: ${stepInfo.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: HrColors.ink),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.unfold_more, size: 16, color: HrColors.muted),
                                ]),
                                const SizedBox(height: 6),
                                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: step / onboardTotalSteps, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), color: HrColors.brand)),
                              ]),
                            ),
                          ]),
                        ),
                        const Divider(height: 1),
                        _buildStep(step, form),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                _buildFooter(step),
              ],
            ),
    );
  }

  Widget _buildStep(int step, Map<String, dynamic> form) {
    switch (step) {
      case 1:
        return StepIdentity(form: form, onChange: _onChange, photo: _photo, onPhotoChanged: (p) => setState(() => _photo = p));
      case 2:
        return StepRole(form: form, onChange: _onChange);
      case 3:
        return StepContact(form: form, onChange: _onChange);
      case 4:
        return StepFamily(form: form, onChange: _onChange);
      case 5:
        return StepGovId(form: form, onChange: _onChange);
      case 6:
        return StepQualifications(form: form, onChange: _onChange);
      case 7:
        return StepMedical(form: form, onChange: _onChange);
      case 8:
        return StepPayroll(form: form, onChange: _onChange);
      case 9:
        return const StepDocuments();
      case 10:
      default:
        return StepReview(form: form, onChange: _onChange);
    }
  }

  Widget _buildFooter(int step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            TextButton(onPressed: () => _confirmDiscard(), child: const Text('Discard', style: TextStyle(color: HrColors.muted))),
            OutlinedButton(onPressed: _saveDraft, child: const Text('Save draft')),
            OutlinedButton(onPressed: () => _stub('Upload signed document — coming soon'), child: const Text('Upload signed')),
            OutlinedButton(onPressed: _downloadBlankForm, child: const Text('Blank form')),
            OutlinedButton(onPressed: () => _stub('QR scan to fill — coming soon'), child: const Text('Scan & fill')),
            OutlinedButton(onPressed: _openVerificationPreview, child: const Text('Print / PDF')),
          ]),
          // `Wrap` (not a `Row(mainAxisSize: min)`) — this group is a child
          // of the outer spaceBetween `Wrap`, so it's handed the FULL
          // footer width, not the leftover after the action-buttons Wrap;
          // "Back" + a long final-step label ("Update & Onboard") can
          // exceed that on a narrow phone.
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (step > 1) TextButton(onPressed: _goBack, child: const Text('Back')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: HrColors.brand),
              onPressed: _submitting ? null : _goNext,
              child: _submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(step >= onboardTotalSteps ? (widget.editId != null ? 'Update & Onboard' : 'Submit & Onboard') : onboardStepByNum(step + 1).label),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this staff onboarding?'),
        content: const Text('Unsaved changes will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: HrColors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/hr/directory');
      }
    }
  }
}
