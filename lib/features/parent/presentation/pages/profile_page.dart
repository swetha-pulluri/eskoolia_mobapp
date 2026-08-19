import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/child_detail_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';
import '../widgets/sibling_tabs.dart';

const Color _dangerRed = Color(0xFFE11D48);

/// My Profile — real port of web's `(parent-portal)/parent/profile/page.tsx`:
/// the admission-wizard-captured data for each of the guardian's children
/// (personal info, address, background, admission details, identity
/// documents, physical/medical info, linked guardians) — NOT academic
/// performance (that stays on `/parent/children`). Reuses the same
/// `fetchChildDetail`/`childDetailProvider` already powering `ChildrenPage`
/// and the Home widgets — the backend just returns more fields now.
///
/// The Logout section at the bottom is the one Flutter-only addition, not
/// from web: web still keeps logout in its header avatar dropdown, but this
/// app's `ParentTopBar` dropped that dropdown to match Admin's simpler top
/// bar (see `ParentTopBar`'s doc comment), so logout needs a home — the
/// bottom-nav Profile tab that already routes here is it, exactly mirroring
/// how Admin's own bottom-nav `ProfilePage` also owns logout.
class ParentProfilePage extends ConsumerWidget {
  const ParentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(parentMeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentMeProvider);
          ref.invalidate(childDetailProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: meAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _LoadError(error: error, onRetry: () => ref.invalidate(parentMeProvider)),
            data: (me) => _ProfileContent(me: me),
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _LoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Could not load profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final ParentMeEntity me;
  const _ProfileContent({required this.me});

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
    final selected = ref.watch(selectedChildProvider);
    final detailAsync = ref.watch(childDetailProvider);
    final detail = detailAsync.valueOrNull;
    final loading = detailAsync.isLoading;
    final hasError = detailAsync.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                  SizedBox(height: 4),
                  Text('The details recorded during admission for each of your children.', style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.4)),
                ],
              ),
            ),
            if (me.children.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), color: AppColors.bg2),
                child: Text('${me.children.length} ${me.children.length == 1 ? 'child' : 'children'}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, fontWeight: FontWeight.w500)),
              ),
            ],
          ],
        ),
        if (me.children.length > 1) ...[
          const SizedBox(height: 14),
          SiblingTabs(children: me.children, selectedId: selected?.id),
        ],
        const SizedBox(height: 14),
        if (me.children.isEmpty)
          _card(const Center(child: Text('No active children linked to your account. Contact the school administrator.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.ink3))))
        else if (loading && detail == null)
          _card(const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator())))
        else if (hasError)
          _card(const Center(child: Text("Could not load this child's profile.", style: TextStyle(fontSize: 12.5, color: AppColors.ink3))))
        else if (detail != null) ...[
          _heroHeader(detail),
          const SizedBox(height: 16),
          _section(
            icon: Icons.person_outline,
            title: 'Personal Info',
            fields: [
              _Field('Gender', (detail.customGender?.isNotEmpty ?? false) ? detail.customGender : detail.gender),
              _Field('Date of Birth', detail.dateOfBirth),
              _Field('First Name', detail.firstName),
              _Field('Middle Name', detail.middleName),
              _Field('Last Name', detail.lastName),
              _Field('Blood Group', detail.bloodGroup, wide: true),
            ],
          ),
          const SizedBox(height: 12),
          _contactAddressCard(detail),
          const SizedBox(height: 12),
          _section(
            icon: Icons.public_outlined,
            title: 'Background',
            fields: [
              _Field('Mother Tongue', (detail.background.otherMotherTongue?.isNotEmpty ?? false) ? detail.background.otherMotherTongue : detail.background.motherTongue),
              _Field('Religion', detail.background.religion),
              _Field('Nationality', (detail.background.otherNationality?.isNotEmpty ?? false) ? detail.background.otherNationality : detail.background.nationality, wide: true),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.school_outlined,
            title: 'Admission Details',
            fields: [
              _Field('Admission Type', detail.admission.admissionType),
              _Field('RTE Certificate No.', detail.admission.rteCertificateNo),
              _Field('Previous School', detail.admission.previousSchoolName, wide: true),
              _Field('Stream', detail.admission.stream),
              _Field(
                'Transport',
                [
                  if (detail.admission.transportModes.isNotEmpty) detail.admission.transportModes.join(', '),
                  if ((detail.admission.transportCustom ?? '').isNotEmpty) detail.admission.transportCustom,
                ].join(' · '),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.badge_outlined,
            title: 'Identity Documents',
            fields: [
              _Field('APAAR ID', detail.identityDocuments.apaarId),
              _Field('Aadhaar No.', detail.identityDocuments.aadhaarNo),
              _Field('PEN', detail.identityDocuments.pen),
              _Field('DigiLocker Mobile', detail.identityDocuments.digilockerMobile),
              _Field('ABC ID', detail.identityDocuments.abcId),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.favorite_border,
            title: 'Physical & Medical',
            fields: [
              _Field('Height (cm)', detail.physical.heightCm?.toStringAsFixed(0)),
              _Field('Weight (kg)', detail.physical.weightKg?.toStringAsFixed(0)),
              _Field('Vision', detail.medical.vision),
              _Field('Medical Conditions', detail.medical.medicalConditions.isNotEmpty ? detail.medical.medicalConditions.join(', ') : null),
              _Field('Allergies', detail.medical.allergies.isNotEmpty ? detail.medical.allergies.join(', ') : null),
              _Field('Current Medications', detail.medical.currentMedications),
              _Field('Treating Doctor', detail.medical.treatingDoctor),
              _Field('Vaccinations', detail.medical.vaccinations.isNotEmpty ? detail.medical.vaccinations.join(', ') : null),
              _Field('Medical Notes', detail.medical.medicalNotes),
              if (detail.medical.isPwd) ...[
                _Field('Disability Type(s)', detail.medical.disabilityTypes.isNotEmpty ? detail.medical.disabilityTypes.join(', ') : null),
                _Field('Disability %', detail.medical.disabilityPercent?.toStringAsFixed(0)),
                _Field('Accommodations', detail.medical.disabilityAccommodations.isNotEmpty ? detail.medical.disabilityAccommodations.join(', ') : null),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _guardiansCard(detail.guardians),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dangerRed,
              side: const BorderSide(color: _dangerRed),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

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

  /// Photo-centered hero — big circular avatar (real [ChildDetailEntity.photoUrl]
  /// when the school has one on file, else a purple-soft initials disc),
  /// name, and an admission-number pill underneath. Card background is the
  /// same light-purple gradient as Admin's own bottom-nav `ProfilePage` hero
  /// card (`Color(0xFFF2EFFE)` → `Color(0xFFDCD3FB)`), including its white
  /// "halo" ring behind the avatar, so this page's hero matches Admin's
  /// look exactly instead of a plain white card. Rebuilds from
  /// [childDetailProvider] every time the selected child (or the sibling
  /// switcher's selection) changes, so a newly admitted child's profile
  /// shows up here the moment their onboarding data is fetched — no
  /// separate wiring needed.
  Widget _heroHeader(ChildDetailEntity detail) {
    final initials = detail.name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
    final classLine = [
      [detail.className, detail.sectionName].where((s) => s.isNotEmpty).join(' '),
      if ((detail.rollNo ?? '').isNotEmpty) 'Roll ${detail.rollNo}',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF2EFFE), Color(0xFFDCD3FB)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // White "halo" ring behind the avatar so it stays crisp against
          // the purple gradient, matching Admin's own profile hero.
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: ClipOval(
              child: (detail.photoUrl?.isNotEmpty ?? false)
                  ? Image.network(
                      detail.photoUrl!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _avatarFallback(initials),
                    )
                  : _avatarFallback(initials),
            ),
          ),
          const SizedBox(height: 14),
          Text(detail.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink1), textAlign: TextAlign.center),
          if (classLine.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(classLine, style: const TextStyle(fontSize: 12.5, color: AppColors.ink3), textAlign: TextAlign.center),
          ],
          if ((detail.admissionNo ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.4))),
              child: Text(detail.admissionNo!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.brandPurple)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarFallback(String initials) {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.purpleSoft, border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.35), width: 2)),
      child: Text(initials, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.purpleDeep)),
    );
  }

  /// Small purple "badge" behind each card's section icon, and the heading
  /// text itself colored in brand purple — the accent that makes each card
  /// read as its own distinct, on-brand block instead of plain black-on-white.
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
        Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.purpleDeep)),
      ],
    );
  }

  Widget _section({required IconData icon, required String title, required List<_Field> fields}) {
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

  /// Contact & Address — the one section styled as a stacked icon-led list
  /// (phone/mail/emergency-contact rows, then a divider and one combined
  /// address block) instead of the label-grid pattern every other section
  /// uses, matching the reference design's own distinct treatment of this
  /// section. All of the address's sub-fields (landmark, city, district,
  /// state, PIN) are folded into one flowing address line rather than
  /// dropped, so no data is lost versus the old 2-column grid.
  Widget _contactAddressCard(ChildDetailEntity detail) {
    final emergency = (detail.contact.emergencyContactName?.isNotEmpty ?? false) && (detail.contact.emergencyContactPhone?.isNotEmpty ?? false)
        ? '${detail.contact.emergencyContactName} (${detail.contact.emergencyContactPhone})'
        : (detail.contact.emergencyContactName ?? detail.contact.emergencyContactPhone);
    final address = [
      [detail.address.addressLine, detail.address.landmark].where((s) => (s ?? '').isNotEmpty).join(', '),
      [detail.address.city, detail.address.district].where((s) => (s ?? '').isNotEmpty).join(', '),
      [detail.address.state, detail.address.pincode].where((s) => (s ?? '').isNotEmpty).join(' - '),
    ].where((s) => s.isNotEmpty).join(', ');

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(Icons.contact_page_outlined, 'Contact & Address'),
          const SizedBox(height: 16),
          _contactRow(Icons.call_outlined, 'Phone', detail.contact.phone),
          const SizedBox(height: 14),
          _contactRow(Icons.mail_outline, 'Email', detail.contact.email),
          const SizedBox(height: 14),
          _contactRow(Icons.error_outline, 'Emergency Contact', emergency),
          if (address.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.border)),
            _contactRow(Icons.location_on_outlined, 'Address', address),
          ],
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

  Widget _guardiansCard(List<ChildGuardianEntity> guardians) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitleRow(Icons.people_outline, 'Guardians on Record'),
          const SizedBox(height: 14),
          if (guardians.isEmpty)
            const Text('No guardians on file.', style: TextStyle(fontSize: 12.5, color: AppColors.ink3))
          else
            _fieldGrid([
              for (final g in guardians)
                _Field(
                  '${g.relation}${g.isPrimary ? ' · primary' : ''}',
                  [g.fullName, g.phone].where((s) => (s ?? '').isNotEmpty).join(' · '),
                ),
            ]),
        ],
      ),
    );
  }

  /// Web renders these as a 3-column CSS grid — on a phone screen that's
  /// replaced with a responsive 2-per-row wrap, same pattern
  /// `TeacherProfilePage`/`ChildrenPage` already use for their own field
  /// grids, rather than squeezing 3 fixed columns into a narrow width.
  /// [_Field.wide] fields (long values like a school name) take the full
  /// row instead of half, matching the reference design's own mix of
  /// half-width and full-width rows per section.
  Widget _fieldGrid(List<_Field> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final colWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [for (final f in fields) SizedBox(width: f.wide ? constraints.maxWidth : colWidth, child: _fieldTile(f))],
        );
      },
    );
  }

  Widget _fieldTile(_Field field) {
    final value = field.value?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.ink3)),
        const SizedBox(height: 3),
        Text(value == null || value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13.5, color: AppColors.ink1)),
      ],
    );
  }
}

class _Field {
  final String label;
  final String? value;
  final bool wide;
  const _Field(this.label, this.value, {this.wide = false});
}
