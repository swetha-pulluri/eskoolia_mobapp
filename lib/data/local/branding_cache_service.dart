import '../../core/constants/storage_keys.dart';
import 'shared_prefs.dart';

/// Last known-good school branding, persisted via the existing
/// [SharedPrefs] singleton (already `init()`'d in `main()` before
/// `runApp()`, so reads here are synchronous — no extra async gap on the
/// splash screen's first frame).
class CachedBranding {
  final int? schoolId;
  final String? brandColorHex;
  final String? logoUrl;
  final String? logoLocalPath;

  const CachedBranding({this.schoolId, this.brandColorHex, this.logoUrl, this.logoLocalPath});
}

/// Reads/writes the cached school branding (brand color hex + downloaded
/// logo file path). Not secret data, so this deliberately uses the plain
/// `SharedPrefs` tier rather than `SecureStorageService`.
class BrandingCacheService {
  CachedBranding read() {
    return CachedBranding(
      schoolId: SharedPrefs().getInt(StorageKeys.schoolBrandingSchoolId),
      brandColorHex: SharedPrefs().getString(StorageKeys.schoolBrandingColor),
      logoUrl: SharedPrefs().getString(StorageKeys.schoolBrandingLogoUrl),
      logoLocalPath: SharedPrefs().getString(StorageKeys.schoolBrandingLogoLocalPath),
    );
  }

  Future<void> saveColor({required int? schoolId, required String? brandColorHex}) async {
    if (schoolId != null) {
      await SharedPrefs().setInt(StorageKeys.schoolBrandingSchoolId, schoolId);
    }
    if (brandColorHex == null) {
      await SharedPrefs().remove(StorageKeys.schoolBrandingColor);
    } else {
      await SharedPrefs().setString(StorageKeys.schoolBrandingColor, brandColorHex);
    }
  }

  Future<void> saveLogo({required String? logoUrl, required String? logoLocalPath}) async {
    if (logoUrl == null) {
      await SharedPrefs().remove(StorageKeys.schoolBrandingLogoUrl);
    } else {
      await SharedPrefs().setString(StorageKeys.schoolBrandingLogoUrl, logoUrl);
    }
    if (logoLocalPath == null) {
      await SharedPrefs().remove(StorageKeys.schoolBrandingLogoLocalPath);
    } else {
      await SharedPrefs().setString(StorageKeys.schoolBrandingLogoLocalPath, logoLocalPath);
    }
  }
}
