import '../../../data/local/shared_prefs.dart';
import '../domain/models/school_header_settings.dart';

const _schoolHeaderKey = 'eskoolia:school:header:v2';

/// SharedPrefs-backed store for the school branding shown on the Student
/// Verification Form — mirrors `ConsentForm.tsx`'s own
/// `localStorage.getItem/setItem('eskoolia:school:header:v2')` persistence
/// exactly: same key, same "missing/blank falls back to defaults" behavior.
class SchoolHeaderStore {
  SchoolHeaderSettings load() {
    final raw = SharedPrefs().getJson(_schoolHeaderKey);
    if (raw == null) return const SchoolHeaderSettings();
    return SchoolHeaderSettings.fromJson(raw);
  }

  Future<void> save(SchoolHeaderSettings settings) async {
    await SharedPrefs().setJson(_schoolHeaderKey, settings.toJson());
  }
}
