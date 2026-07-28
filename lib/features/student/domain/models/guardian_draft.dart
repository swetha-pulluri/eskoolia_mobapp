/// One guardian card's editable state on the Enroll form's "Family &
/// guardians" step — Source: frontend/components/students/
/// StudentGuardiansStep.tsx GuardianDraft type. `clientId` is a local-only
/// identifier (form state, not a backend id) so cards can be added/removed
/// before anything is ever saved.
class GuardianDraft {
  final String clientId;
  bool isPrimary;
  String fullName;
  String relation;
  String phone;
  String email;
  String occupation;

  GuardianDraft({
    required this.clientId,
    this.isPrimary = false,
    this.fullName = '',
    this.relation = 'Father',
    this.phone = '',
    this.email = '',
    this.occupation = '',
  });
}

const List<String> guardianRelationOptions = [
  'Father',
  'Mother',
  'Guardian',
  'Grandfather',
  'Grandmother',
  'Uncle',
  'Aunt',
  'Other',
];
