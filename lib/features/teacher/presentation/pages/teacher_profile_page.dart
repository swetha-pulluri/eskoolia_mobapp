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
                const SizedBox(height: 16),
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
                // Clear gap from the Bank & Payroll card above — previously
                // butted right up against it with zero spacing, reading as
                // one merged block instead of two separate elements.
                const SizedBox(height: 20),
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
    // Now its own card (same purple-bordered/shadowed `_card()` shell as
    // every section below) instead of floating text directly on the page
    // background, per explicit request.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: _card(
        const Column(
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
      ),
    );
  }

  Widget _content(TeacherProfileEntity profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroHeader(profile),
        const SizedBox(height: 16),
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
        const SizedBox(height: 12),
        _contactAddressCard(profile),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        _bankCard(profile),
      ],
    );
  }

  /// Card shell shared by every section below — white fill, a faint
  /// brand-purple border/shadow instead of a plain gray border, matching
  /// `ParentProfilePage`'s own `_card()` treatment exactly.
  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.brandPurple.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  /// Photo-centered hero, matching `ParentProfilePage._heroHeader` exactly:
  /// purple gradient card, a white "halo" ring behind the avatar, centered
  /// name, a centered meta line, and an ID pill underneath. Same data as
  /// before (name, staff no., designation, department, status) — just
  /// reshaped into that same visual template instead of a compact left-icon
  /// row: the staff number takes the pill's role (an ID, like a child's
  /// admission number), and designation/department/status become the
  /// centered meta line (like a child's class/section/roll line).
  Widget _heroHeader(TeacherProfileEntity profile) {
    final metaLine = [
      profile.designationName?.isNotEmpty == true ? profile.designationName! : '—',
      profile.departmentName?.isNotEmpty == true ? profile.departmentName! : '—',
      if (profile.status.isNotEmpty) profile.status,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF2EFFE), Color(0xFFDCD3FB)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandPurple),
              child: Text(
                profile.initials,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink1),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (metaLine.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(metaLine, style: const TextStyle(fontSize: 12.5, color: AppColors.ink3), textAlign: TextAlign.center),
          ],
          if (profile.staffNo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.4))),
              child: Text(profile.staffNo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brandPurple)),
            ),
          ],
        ],
      ),
    );
  }

  /// Small purple "badge" behind the section icon, and a deep-purple bold
  /// heading — matching `ParentProfilePage._sectionTitleRow` exactly.
  Widget _sectionTitleRow(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 15, color: AppColors.brandPurple),
        ),
        const SizedBox(width: 10),
        // `Expanded` so a longer title (e.g. "Qualifications & Employment")
        // wraps to a second line instead of overflowing the card's width —
        // a bare `Text` here has no bound and can't shrink or wrap.
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.purpleDeep)),
        ),
      ],
    );
  }

  Widget _section({required IconData icon, required String title, required List<_ProfileField> fields}) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(icon, title),
          const SizedBox(height: 14),
          _fieldGrid(fields),
        ],
      ),
    );
  }

  /// Contact & Address — same 6 fields as before, restyled as a stacked
  /// icon-led list (matching `ParentProfilePage._contactAddressCard`
  /// exactly) instead of the plain label-grid every other section uses.
  Widget _contactAddressCard(TeacherProfileEntity profile) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(Icons.call_outlined, 'Contact & Address'),
          const SizedBox(height: 16),
          _contactRow(Icons.mail_outline, 'Email', profile.email),
          const SizedBox(height: 14),
          _contactRow(Icons.call_outlined, 'Phone', profile.phone),
          const SizedBox(height: 14),
          _contactRow(Icons.error_outline, 'Emergency Contact', profile.emergencyMobile),
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.border)),
          _contactRow(Icons.location_on_outlined, 'Current Address', profile.currentAddress),
          const SizedBox(height: 14),
          _contactRow(Icons.location_on_outlined, 'Permanent Address', profile.permanentAddress),
          const SizedBox(height: 14),
          _contactRow(Icons.map_outlined, 'City / State', profile.cityState),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String? value) {
    final v = value?.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.brandPurple),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.ink3)),
              const SizedBox(height: 3),
              Text(v == null || v.isEmpty ? '—' : v, style: const TextStyle(fontSize: 13.5, color: AppColors.ink1, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bankCard(TeacherProfileEntity profile) {
    final salary = profile.basicSalary.trim();
    // Same purple `_card`/`_sectionTitleRow` treatment as every other
    // section now, per explicit request — no more standalone red tint.
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitleRow(Icons.account_balance_outlined, 'Bank & Payroll')),
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
