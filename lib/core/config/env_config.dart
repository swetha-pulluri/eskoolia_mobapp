import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// Environment Configuration for API Base URL
///
/// Android and iOS (including debug builds) use the shared hosted backend
/// by default — see [apiBaseUrl]. [_developmentLanIp] is only needed if you
/// switch [apiBaseUrl] back to [physicalDeviceUrl] to point at a local
/// Django instance on your LAN.
class EnvConfig {
  EnvConfig._();

  /// Development machine's LAN IP, used only by [physicalDeviceUrl].
  /// If you point [apiBaseUrl] at this instead of the hosted backend, also
  /// update the matching `<domain>` entry in
  /// android/app/src/debug/res/xml/network_security_config.xml, which
  /// permits cleartext (http://) traffic only for this IP + 10.0.2.2 —
  /// without it, API 28+ blocks cleartext traffic by default and every
  /// request fails immediately regardless of whether the IP is correct.
  static const String _developmentLanIp = '192.168.170.202';
  
  /// Backend port (default Django port)
  static const String _backendPort = '8000';

  /// Shared hosted backend — root host only, no `/api/v1` suffix.
  /// ApiConstants.apiBasePath ('/api/v1') is already appended to every
  /// endpoint constant in api_constants.dart, so if this included `/api/v1`
  /// too, every request would resolve to `.../api/v1/api/v1/...`.
  static const String _productionApiUrl = 'https://app.eskoolia.com';

  /// Get the appropriate API base URL based on platform and environment
  static String get apiBaseUrl {
    // Release builds always use the shared hosted backend, regardless of
    // platform — never a developer's LAN IP, which only exists on whichever
    // laptop happens to be running `manage.py runserver` at the time.
    if (kReleaseMode) {
      return _productionApiUrl;
    }

    if (kIsWeb) {
      // Web: use a local Django dev server, NOT the shared hosted backend
      // (unlike Android/iOS below) — the hosted backend's CORS policy
      // (backend/config/settings/production.py: CORS_ALLOW_ALL_ORIGINS =
      // False, allow-list restricted to *.eskoolia.com origins only) will
      // block any request from Flutter web's dev server, which always runs
      // on a random http://localhost:<port> origin. A local Django instance
      // running dev/base settings (CORS_ALLOW_ALL_ORIGINS = True there) is
      // the only way to test the web build without a real *.eskoolia.com
      // deployment to serve it from.
      return 'http://localhost:$_backendPort';
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile (debug): use the shared hosted backend/database, same as
      // release mode, instead of the dev machine's local LAN backend — the
      // local backend requires the dev machine's Django server + DB to be
      // running and reachable, which physical devices frequently can't do.
      return _productionApiUrl;
    }

    // Default fallback (Desktop platforms)
    return 'http://localhost:$_backendPort';
  }

  /// Alternative: Get emulator-specific URL for Android emulator
  static String get androidEmulatorUrl => 'http://10.0.2.2:$_backendPort';

  /// Alternative: Get LAN IP URL for physical devices
  static String get physicalDeviceUrl => 'http://$_developmentLanIp:$_backendPort';
}
