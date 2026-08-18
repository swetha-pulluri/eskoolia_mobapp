import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/child_detail_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';
import '../widgets/sibling_tabs.dart';

const Color _brandPurple = Color(0xFF6D4AFF);
const Color _purpleDeep = Color(0xFF4F35CC);
const Color _purpleSoft = Color(0xFFEEEAFF);
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
          _summaryCard(detail),
          const SizedBox(height: 14),
          _section(
            icon: Icons.person_outline,
            title: 'Personal Info',
            fields: [
              _Field('First Name', detail.firstName),
              _Field('Middle Name', detail.middleName),
              _Field('Last Name', detail.lastName),
              _Field('Date of Birth', detail.dateOfBirth),
              _Field('Gender', (detail.customGender?.isNotEmpty ?? false) ? detail.customGender : detail.gender),
              _Field('Blood Group', detail.bloodGroup),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.location_on_outlined,
            title: 'Contact & Address',
            fields: [
              _Field('Phone', detail.contact.phone),
              _Field('Email', detail.contact.email),
              _Field(
                'Emergency Contact',
                (detail.contact.emergencyContactName?.isNotEmpty ?? false) && (detail.contact.emergencyContactPhone?.isNotEmpty ?? false)
                    ? '${detail.contact.emergencyContactName} (${detail.contact.emergencyContactPhone})'
                    : detail.contact.emergencyContactName,
              ),
              _Field('Address', [detail.address.addressLine, detail.address.landmark].where((s) => (s ?? '').isNotEmpty).join(', ')),
              _Field('City / District', [detail.address.city, detail.address.district].where((s) => (s ?? '').isNotEmpty).join(', ')),
              _Field('State / PIN', [detail.address.state, detail.address.pincode].where((s) => (s ?? '').isNotEmpty).join(' - ')),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.public_outlined,
            title: 'Background',
            fields: [
              _Field('Mother Tongue', (detail.background.otherMotherTongue?.isNotEmpty ?? false) ? detail.background.otherMotherTongue : detail.background.motherTongue),
              _Field('Religion', detail.background.religion),
              _Field('Nationality', (detail.background.otherNationality?.isNotEmpty ?? false) ? detail.background.otherNationality : detail.background.nationality),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.school_outlined,
            title: 'Admission Details',
            fields: [
              _Field('Admission Type', detail.admission.admissionType),
              _Field('Previous School', detail.admission.previousSchoolName),
              _Field('RTE Certificate No.', detail.admission.rteCertificateNo),
              _Field('Stream', detail.admission.stream),
              _Field('Transport', detail.admission.transportModes.isNotEmpty ? detail.admission.transportModes.join(', ') : null),
              _Field('Transport (other)', detail.admission.transportCustom),
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
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _summaryCard(ChildDetailEntity detail) {
    final initials = detail.name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
    return _card(
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _purpleSoft),
            child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _purpleDeep)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(detail.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink1), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  [
                    detail.admissionNo ?? '',
                    [detail.className, detail.sectionName].where((s) => s.isNotEmpty).join(' '),
                    if ((detail.rollNo ?? '').isNotEmpty) 'Roll ${detail.rollNo}',
                  ].where((s) => s.isNotEmpty).join(' · '),
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

  Widget _section({required IconData icon, required String title, required List<_Field> fields}) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _brandPurple),
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

  Widget _guardiansCard(List<ChildGuardianEntity> guardians) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: _brandPurple),
              SizedBox(width: 8),
              Text('Guardians on Record', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink1)),
            ],
          ),
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
  Widget _fieldGrid(List<_Field> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final colWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [for (final f in fields) SizedBox(width: colWidth, child: _fieldTile(f))],
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
  const _Field(this.label, this.value);
}
