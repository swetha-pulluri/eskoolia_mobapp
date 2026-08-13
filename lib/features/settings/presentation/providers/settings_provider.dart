import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/school_info_remote_datasource.dart';
import '../../data/repositories/school_info_repository_impl.dart';
import '../../domain/repositories/school_info_repository.dart';
import '../../domain/school_choices.dart';
import 'school_info_wizard_state.dart';

final schoolInfoRemoteDataSourceProvider = Provider<SchoolInfoRemoteDataSource>((ref) {
  return SchoolInfoRemoteDataSource(ref.watch(dioClientProvider));
});

final schoolInfoRepositoryProvider = Provider<SchoolInfoRepository>((ref) {
  return SchoolInfoRepositoryImpl(ref.watch(schoolInfoRemoteDataSourceProvider));
});

final schoolInfoNotifierProvider =
    StateNotifierProvider.autoDispose<SchoolInfoNotifier, SchoolInfoWizardState>((ref) {
  return SchoolInfoNotifier(ref.watch(schoolInfoRepositoryProvider));
});

/// Editable field keys (in `form`) that map 1:1 to the web's
/// `EDITABLE_FIELDS` — drives both the PATCH payload builder below and, via
/// `_nullableNumericFields`, which of them must serialize as JSON `null`
/// rather than `""` when empty (DRF's Integer/DecimalField reject `""`).
const List<String> _editableFieldKeys = [
  'board', 'school_type', 'medium_of_instruction', 'year_established', 'motto',
  'principal_name', 'principal_email', 'principal_phone', 'school_phone', 'school_email', 'website',
  'campus_address', 'city', 'state', 'region', 'pin_code', 'country',
  'latitude', 'longitude', 'geofence_radius_meters',
  'affiliation_number', 'udise_code', 'gstin', 'pan', 'logo_url', 'brand_color',
];

const Set<String> _nullableNumericFields = {
  'year_established', 'latitude', 'longitude', 'geofence_radius_meters',
};

const List<String> _logoAllowedMimeTypes = ['image/jpeg', 'image/png'];
const int _logoMaxBytes = 2 * 1024 * 1024;

/// Drives the Settings → School Info wizard — a 1:1 port of every function
/// in `frontend/components/settings/SchoolInfoPanel.tsx`, combined into a
/// single Riverpod `StateNotifier` instead of ~15 separate `useState` hooks.
class SchoolInfoNotifier extends StateNotifier<SchoolInfoWizardState> {
  final SchoolInfoRepository _repository;
  int _geocodeRequestId = 0;

  SchoolInfoNotifier(this._repository) : super(const SchoolInfoWizardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final info = await _repository.getSchoolInfo();
      state = state.copyWith(loading: false, info: info, form: info.toFormMap());
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  void setStep(int step) => state = state.copyWith(step: step);

  void setField(String key, dynamic value) {
    state = state.copyWith(form: {...state.form, key: value});
  }

  /// Mirrors `handleSave` — silent saves (from the map/step "Save & Exit")
  /// skip the loud "School info updated." message in favor of a quieter one.
  Future<void> save({
    bool silent = false,
    Map<String, dynamic>? overrides,
    String? reason,
    String? successMessage,
  }) async {
    state = state.copyWith(saving: true, error: null, success: null);
    try {
      final source = {...state.form, ...?overrides};
      final payload = <String, dynamic>{};
      for (final key in _editableFieldKeys) {
        final value = source[key];
        if (_nullableNumericFields.contains(key)) {
          payload[key] = (value == null || value == '') ? null : value;
        } else {
          payload[key] = value ?? '';
        }
      }
      if (reason != null && reason.isNotEmpty) {
        payload['location_update_reason'] = reason;
      }
      final updated = await _repository.updateSchoolInfo(payload);
      state = state.copyWith(
        saving: false,
        info: updated,
        form: updated.toFormMap(),
        success: successMessage ?? (silent ? 'Saved.' : 'School info updated.'),
      );
    } catch (e) {
      state = state.copyWith(saving: false, error: adminErrorMessage(e));
      rethrow;
    }
  }

  Future<void> uploadLogo(List<int> bytes, String filename, String mimeType) async {
    state = state.copyWith(logoError: null);
    if (!_logoAllowedMimeTypes.contains(mimeType)) {
      state = state.copyWith(logoError: 'Only JPG or PNG images are allowed.');
      return;
    }
    if (bytes.length > _logoMaxBytes) {
      state = state.copyWith(logoError: 'File exceeds the ${_logoMaxBytes ~/ (1024 * 1024)}MB limit.');
      return;
    }
    state = state.copyWith(logoUploading: true);
    try {
      final updated = await _repository.uploadLogo(bytes, filename, mimeType);
      state = state.copyWith(
        logoUploading: false,
        info: updated,
        form: updated.toFormMap(),
        logoBytes: bytes,
        success: 'Logo uploaded.',
      );
    } catch (e) {
      state = state.copyWith(logoUploading: false, logoError: adminErrorMessage(e));
    }
  }

  /// Saves the pin position immediately (independent of the wizard's own
  /// Save button — a nudge that doesn't imply a different City/State would
  /// otherwise never get persisted), then looks up the address for it.
  Future<void> setLocation(double lat, double lng) async {
    final latitude = lat.toStringAsFixed(6);
    final longitude = lng.toStringAsFixed(6);
    setField('latitude', latitude);
    setField('longitude', longitude);
    unawaited(save(
      silent: true,
      overrides: {'latitude': latitude, 'longitude': longitude},
      successMessage: 'Location saved.',
    ).catchError((_) {}));
    unawaited(_applyReverseGeocode(lat, lng));
  }

  Future<void> _applyReverseGeocode(double lat, double lng) async {
    final requestId = ++_geocodeRequestId;
    state = state.copyWith(geocoding: true);
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'addressdetails': 1,
          'accept-language': 'en',
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (requestId != _geocodeRequestId) return; // a newer pin drop superseded this lookup

      final addr = (response.data?['address'] as Map?)?.cast<String, dynamic>() ?? {};
      final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'] ?? addr['county'])
          as String?;
      final pinCode = addr['postcode'] as String?;
      final stateCode = matchStateNameToCode(addr['state'] as String?);
      final regionCode = stateCode != null ? stateCodeToRegion[stateCode] : null;
      final road = [addr['road'], addr['suburb'] ?? addr['neighbourhood']]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
      final country = addr['country'] as String?;

      final current = state.form;
      final proposed = <String, dynamic>{};
      final diff = <LocationDiffEntry>[];

      if (city != null && city != current['city']) {
        proposed['city'] = city;
        diff.add(LocationDiffEntry(label: 'City', from: (current['city'] as String?) ?? '—', to: city));
      }
      if (pinCode != null && pinCode != current['pin_code']) {
        proposed['pin_code'] = pinCode;
        diff.add(LocationDiffEntry(label: 'PIN Code', from: (current['pin_code'] as String?) ?? '—', to: pinCode));
      }
      if (stateCode != null && stateCode != current['state']) {
        proposed['state'] = stateCode;
        diff.add(LocationDiffEntry(
          label: 'State',
          from: stateLabel(current['state'] as String?),
          to: stateLabel(stateCode),
        ));
      }
      if (regionCode != null && regionCode != current['region']) {
        proposed['region'] = regionCode;
        diff.add(LocationDiffEntry(
          label: 'Region',
          from: regionLabel(current['region'] as String?),
          to: regionLabel(regionCode),
        ));
      }
      if (country != null && country != current['country']) {
        proposed['country'] = country;
        diff.add(LocationDiffEntry(label: 'Country', from: (current['country'] as String?) ?? '—', to: country));
      }
      // Only ever suggest campus_address when it's still blank — a nudge of
      // the pin shouldn't be able to overwrite an address someone typed in.
      final currentAddress = (current['campus_address'] as String?)?.trim() ?? '';
      if (currentAddress.isEmpty && road.isNotEmpty) {
        proposed['campus_address'] = road;
        diff.add(LocationDiffEntry(label: 'Campus Address', from: '—', to: road));
      }

      if (diff.isNotEmpty) {
        state = state.copyWith(
          locationUpdateReason: '',
          pendingLocationUpdate: PendingLocationUpdate(values: proposed, diff: diff),
        );
      }
    } catch (_) {
      // Best-effort — the lat/lng itself is already saved; leave the address
      // fields untouched on failure.
    } finally {
      if (requestId == _geocodeRequestId) {
        state = state.copyWith(geocoding: false);
      }
    }
  }

  void setLocationUpdateReason(String reason) => state = state.copyWith(locationUpdateReason: reason);

  /// Applies the proposed address fields and saves immediately rather than
  /// waiting for a separate "Save & Exit" click — waiting here meant a
  /// refresh right after confirming lost the update entirely.
  Future<void> confirmLocationUpdate() async {
    final pending = state.pendingLocationUpdate;
    final reason = state.locationUpdateReason.trim();
    if (pending == null || reason.isEmpty) return;
    state = state.copyWith(
      form: {...state.form, ...pending.values},
      pendingLocationUpdate: null,
      locationUpdateReason: '',
    );
    try {
      await save(
        silent: true,
        overrides: pending.values,
        reason: reason,
        successMessage: 'Address updated and saved.',
      );
    } catch (_) {
      // Error already surfaced via state.error.
    }
  }

  void discardLocationUpdate() {
    state = state.copyWith(pendingLocationUpdate: null, locationUpdateReason: '');
  }

  Future<void> useCurrentLocation() async {
    state = state.copyWith(locationError: null, locating: true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(locating: false, locationError: 'Location permission was denied.');
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = state.copyWith(locating: false, locationError: 'Location services are disabled.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      state = state.copyWith(locating: false);
      await setLocation(position.latitude, position.longitude);
    } catch (e) {
      state = state.copyWith(locating: false, locationError: 'Could not get your current location.');
    }
  }
}
