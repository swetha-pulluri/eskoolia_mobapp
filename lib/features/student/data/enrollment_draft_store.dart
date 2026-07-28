import '../../../data/local/shared_prefs.dart';
import '../domain/models/enrollment_draft.dart';

const _draftsKey = 'students:add:drafts:v2';

/// SharedPrefs-backed multi-draft store — mirrors frontend
/// components/students/StudentAddPanel.tsx's own
/// `localStorage.getItem/setItem('students:add:drafts:v2')` persistence
/// exactly: same key, same upsert-by-admission-number behavior (an existing
/// draft with the same non-empty admission no. is replaced in place rather
/// than duplicated).
class EnrollmentDraftStore {
  List<EnrollmentDraft> load() {
    final raw = SharedPrefs().getJsonList(_draftsKey);
    if (raw == null) return [];
    return raw.map(EnrollmentDraft.fromJson).toList();
  }

  Future<void> upsert(EnrollmentDraft draft) async {
    final drafts = load();
    final admissionNo = draft.admissionNo.trim();
    final existingIdx = admissionNo.isNotEmpty ? drafts.indexWhere((d) => d.admissionNo == admissionNo) : -1;
    if (existingIdx >= 0) {
      drafts[existingIdx] = draft;
    } else {
      drafts.add(draft);
    }
    await SharedPrefs().setJsonList(_draftsKey, drafts.map((d) => d.toJson()).toList());
  }

  Future<void> delete(String id) async {
    final drafts = load()..removeWhere((d) => d.id == id);
    await SharedPrefs().setJsonList(_draftsKey, drafts.map((d) => d.toJson()).toList());
  }
}
