import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/teacher_profile_entity.dart';
import '../providers/teacher_profile_providers.dart';
import '../widgets/my_classes/load_error_card.dart';

const _dangerRed = Color(0xFFE11D48);

/// Teacher Portal — My Profile. Mirrors
/// `(teacher-portal)/teacher/profile/page.tsx`, which renders
/// `StaffProfilePanel` unchanged — this page implements exactly that
/// component's non-admin ("self-view") branch: a teacher never has
/// `human_resource.staff.view`, so they only ever see their own record via
/// `GET /api/v1/hr/staff/me/`, with no staff picker and no Documents
/// section (both admin-only on web). The panel is read-only on web — there
/// is no edit/save/cancel flow, no validation, and no dialogs to port; a
/// real photo is never rendered either (web derives an initials avatar
/// client-side, so this page does the same rather than inventing a photo
/// upload feature that doesn't exist).
class TeacherProfilePage extends ConsumerWidget {
  const TeacherProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of Eskoolia?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out', style: TextStyle(color: _dangerRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(teacherProfileProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pageHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: profileAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    // Web's catch() ignores the real error/status entirely and
                    // always shows this same fixed message — matched exactly,
                    // including for network/5xx errors, not just a 404.
                    error: (error, _) => LoadErrorCard(
                      title: 'Could not load profile',
                      message: 'No staff profile is linked to your account yet.',
                      onRetry: () => ref.invalidate(teacherProfileProvider),
                    ),
                    data: (profile) => _content(profile),
                  ),
                ),
                // Only remaining logout entry point now that the top bar's
                // avatar dropdown (which used to carry it) is gone in favor
                // of the bottom-nav Profile tab — mirrors the Admin
                // `ProfilePage`'s own logout button exactly.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context, ref),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _dangerRed,
                        side: const BorderSide(color: _dangerRed),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEACHER PORTAL · MY PROFILE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.ink2),
          ),
          SizedBox(height: 6),
          Text('Staff Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink1)),
          SizedBox(height: 4),
          Text(
            'Your own onboarding and payroll details, as recorded during onboarding.',
            style: TextStyle(fontSize: 13, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }

  Widget _content(TeacherProfileEntity profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerCard(profile),
        const SizedBox(height: 14),
        _section(
          icon: Icons.person_outline,
          title: 'Personal Info',
          fields: [
            _ProfileField('First Name', profile.firstName),
            _ProfileField('Last Name', profile.lastName),
            _ProfileField('Gender', profile.gender),
            _ProfileField('Date of Birth', profile.dateOfBirth),
            _ProfileField('Marital Status', profile.maritalStatus),
            _ProfileField('Blood Group', profile.bloodGroup),
            _ProfileField('Nationality', profile.nationality),
          ],
        ),
        const SizedBox(height: 14),
        _section(
          icon: Icons.call_outlined,
          title: 'Contact & Address',
          fields: [
            _ProfileField('Email', profile.email),
            _ProfileField('Phone', profile.phone),
            _ProfileField('Emergency Contact', profile.emergencyMobile),
            _ProfileField('Current Address', profile.currentAddress),
            _ProfileField('Permanent Address', profile.permanentAddress),
            _ProfileField('City / State', profile.cityState),
          ],
        ),
        const SizedBox(height: 14),
        _section(
          icon: Icons.school_outlined,
          title: 'Qualifications & Employment',
          fields: [
            _ProfileField('Qualification', profile.qualification),
            _ProfileField('Experience', profile.experience),
            _ProfileField('Role', profile.roleName),
            _ProfileField('Contract Type', profile.contractType),
            _ProfileField('Joining Date', profile.joinDate),
          ],
        ),
        const SizedBox(height: 14),
        _bankCard(profile),
      ],
    );
  }

  Widget _headerCard(TeacherProfileEntity profile) {
    final metaParts = [
      profile.staffNo,
      profile.designationName?.isNotEmpty == true ? profile.designationName! : '—',
      profile.departmentName?.isNotEmpty == true ? profile.departmentName! : '—',
      if (profile.status.isNotEmpty) profile.status,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.purpleSoft),
            child: Text(
              profile.initials,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brandPurple),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink1),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  metaParts.join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required IconData icon, required String title, required List<_ProfileField> fields}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.brandPurple),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink1)),
            ],
          ),
          const SizedBox(height: 14),
          _fieldGrid(fields),
        ],
      ),
    );
  }

  Widget _bankCard(TeacherProfileEntity profile) {
    final salary = profile.basicSalary.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, size: 16, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              const Text('Bank & Payroll', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink1)),
              const Spacer(),
              const Flexible(
                child: Text(
                  'SENSITIVE',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldGrid([
            _ProfileField('Account Holder', profile.bankAccountName),
            _ProfileField('Account Number', profile.bankAccountNo),
            _ProfileField('Bank Name', profile.bankName),
            _ProfileField('Branch', profile.bankBranch),
            _ProfileField('EPF No.', profile.epfNo),
            _ProfileField('Basic Salary', salary.isEmpty ? null : '₹$salary'),
          ]),
        ],
      ),
    );
  }

  /// Web renders these as a 3-column CSS grid — on a phone screen that's
  /// replaced with a responsive 2-per-row wrap (via `LayoutBuilder`, the
  /// same pattern `my_classes_page.dart`'s header uses) rather than
  /// squeezing 3 fixed columns into a narrow width.
  Widget _fieldGrid(List<_ProfileField> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final colWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            for (final f in fields)
              SizedBox(width: colWidth, child: _fieldTile(f)),
          ],
        );
      },
    );
  }

  Widget _fieldTile(_ProfileField field) {
    final value = field.value?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label.toUpperCase(),
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.ink3),
        ),
        const SizedBox(height: 3),
        Text(
          value == null || value.isEmpty ? '—' : value,
          style: const TextStyle(fontSize: 13.5, color: AppColors.ink1),
        ),
      ],
    );
  }
}

class _ProfileField {
  final String label;
  final String? value;
  const _ProfileField(this.label, this.value);
}
