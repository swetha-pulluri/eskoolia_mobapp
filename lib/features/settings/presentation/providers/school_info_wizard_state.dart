import '../../domain/entities/school_info_entity.dart';

/// One labeled "from → to" row shown in the map's reverse-geocode confirm
/// panel — mirrors the web's `{ label, from, to }` diff entries.
class LocationDiffEntry {
  final String label;
  final String from;
  final String to;

  const LocationDiffEntry({required this.label, required this.from, required this.to});
}

/// A location-implied address change awaiting user confirmation (with a
/// typed reason) before it's applied to the form and saved — mirrors the
/// web's `pendingLocationUpdate` state.
class PendingLocationUpdate {
  final Map<String, dynamic> values;
  final List<LocationDiffEntry> diff;

  const PendingLocationUpdate({required this.values, required this.diff});
}

/// Combines every `useState` hook from `SchoolInfoPanel.tsx` into one
/// immutable state object for a single `StateNotifier`.
class SchoolInfoWizardState {
  final SchoolInfoEntity? info;
  final Map<String, dynamic> form;
  final int step;
  final bool loading;
  final bool saving;
  final String? error;
  final String? success;

  final bool logoUploading;
  final String? logoError;
  final List<int>? logoBytes;

  final bool locating;
  final String? locationError;
  final bool geocoding;
  final PendingLocationUpdate? pendingLocationUpdate;
  final String locationUpdateReason;

  const SchoolInfoWizardState({
    this.info,
    this.form = const {},
    this.step = 0,
    this.loading = true,
    this.saving = false,
    this.error,
    this.success,
    this.logoUploading = false,
    this.logoError,
    this.logoBytes,
    this.locating = false,
    this.locationError,
    this.geocoding = false,
    this.pendingLocationUpdate,
    this.locationUpdateReason = '',
  });

  static const int stepCount = 6;

  SchoolInfoWizardState copyWith({
    SchoolInfoEntity? info,
    Map<String, dynamic>? form,
    int? step,
    bool? loading,
    bool? saving,
    Object? error = _unset,
    Object? success = _unset,
    bool? logoUploading,
    Object? logoError = _unset,
    Object? logoBytes = _unset,
    bool? locating,
    Object? locationError = _unset,
    bool? geocoding,
    Object? pendingLocationUpdate = _unset,
    String? locationUpdateReason,
  }) {
    return SchoolInfoWizardState(
      info: info ?? this.info,
      form: form ?? this.form,
      step: step ?? this.step,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
      logoUploading: logoUploading ?? this.logoUploading,
      logoError: logoError == _unset ? this.logoError : logoError as String?,
      logoBytes: logoBytes == _unset ? this.logoBytes : logoBytes as List<int>?,
      locating: locating ?? this.locating,
      locationError: locationError == _unset ? this.locationError : locationError as String?,
      geocoding: geocoding ?? this.geocoding,
      pendingLocationUpdate:
          pendingLocationUpdate == _unset ? this.pendingLocationUpdate : pendingLocationUpdate as PendingLocationUpdate?,
      locationUpdateReason: locationUpdateReason ?? this.locationUpdateReason,
    );
  }
}

const Object _unset = Object();
