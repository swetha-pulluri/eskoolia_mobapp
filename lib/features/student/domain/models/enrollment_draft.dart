/// One saved enrollment-in-progress — mirrors frontend
/// components/students/StudentAddPanel.tsx's multi-draft system
/// (`students:add:drafts:v2` in localStorage). `data` carries a snapshot of
/// every field the Flutter Enroll form itself collects (a subset of the
/// frontend's own field set — see [EnrollmentDraftStore]), keyed the same
/// way the page's controllers/state are named.
class EnrollmentDraft {
  final String id;
  final int savedAt; // epoch milliseconds
  final String label;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final int? classId;
  final int maxReachedIndex;
  final int activeIndex;
  final Map<String, dynamic> data;

  const EnrollmentDraft({
    required this.id,
    required this.savedAt,
    required this.label,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    this.classId,
    required this.maxReachedIndex,
    required this.activeIndex,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt,
        'label': label,
        'admissionNo': admissionNo,
        'firstName': firstName,
        'lastName': lastName,
        'classId': classId,
        'maxReachedIndex': maxReachedIndex,
        'activeIndex': activeIndex,
        'data': data,
      };

  factory EnrollmentDraft.fromJson(Map<String, dynamic> json) => EnrollmentDraft(
        id: json['id'] as String,
        savedAt: (json['savedAt'] as num?)?.toInt() ?? 0,
        label: (json['label'] as String?) ?? '',
        admissionNo: (json['admissionNo'] as String?) ?? '',
        firstName: (json['firstName'] as String?) ?? '',
        lastName: (json['lastName'] as String?) ?? '',
        classId: (json['classId'] as num?)?.toInt(),
        maxReachedIndex: (json['maxReachedIndex'] as num?)?.toInt() ?? -1,
        activeIndex: (json['activeIndex'] as num?)?.toInt() ?? 0,
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// Mirrors StudentAddPanel.tsx's `computeDraftStats()` used by the Drafts
/// modal's cards: completion % from the saved step index (not a full
/// required-field re-check), plus up to 2 "still missing" labels.
class EnrollmentDraftStats {
  final int pct;
  final List<String> missing;
  const EnrollmentDraftStats(this.pct, this.missing);
}

EnrollmentDraftStats computeDraftStats(EnrollmentDraft draft, int totalSteps) {
  final pct = draft.maxReachedIndex >= 0
      ? (((draft.maxReachedIndex + 1) / totalSteps) * 100).round().clamp(0, 99)
      : 0;
  final data = draft.data;
  final missing = <String>[];
  final firstName = data['firstName'] as String? ?? '';
  final lastName = data['lastName'] as String? ?? '';
  if (firstName.trim().isEmpty || lastName.trim().isEmpty) missing.add('Name');
  if ((data['dob'] as String? ?? '').trim().isEmpty) missing.add('DOB');
  if (data['classId'] == null) missing.add('Class');
  if ((data['phone'] as String? ?? '').trim().isEmpty) missing.add('Phone');
  final guardians = (data['guardians'] as List?) ?? const [];
  final hasGuardian = guardians.isNotEmpty &&
      ((guardians.first as Map)['fullName'] as String? ?? '').trim().isNotEmpty;
  if (!hasGuardian) missing.add('Guardian');
  return EnrollmentDraftStats(pct, missing);
}
