import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment Configuration for API Base URL
/// 
/// IMPORTANT: For Android physical device testing, update [_developmentLanIp]
/// with your development machine's LAN IP address.
/// 
/// To find your LAN IP:
/// - Windows: Run `ipconfig` and look for IPv4 Address (e.g., 192.168.1.100)
/// - macOS/Linux: Run `ifconfig` or `ip addr` and look for inet address
/// 
/// Example: static const String _developmentLanIp = '192.168.1.100';
class EnvConfig {
  EnvConfig._();

  /// YOUR DEVELOPMENT MACHINE'S LAN IP ADDRESS
  /// Update this when testing on physical Android devices, and whenever this
  /// machine's IP changes (e.g. reconnecting to a different Wi-Fi network) —
  /// a stale value here is a silent `DioException: Connection timeout` with
  /// no other symptom, since the app never learns the address is wrong, it
  /// just never gets a response. Run `ipconfig` (Windows) / `ifconfig`
  /// (macOS/Linux) to find the current one. Also update the matching
  /// `<domain>` entry in
  /// android/app/src/debug/res/xml/network_security_config.xml, which
  /// permits cleartext (http://) traffic only for this IP + 10.0.2.2 —
  /// without it, API 28+ blocks cleartext traffic by default and every
  /// request fails immediately regardless of whether the IP is correct.
  static const String _developmentLanIp = '192.168.170.202'; // ← CHANGE THIS TO YOUR LAN IP

  /// Backend port (default Django port)
  static const String _backendPort = '8000';

  /// Get the appropriate API base URL based on platform and environment
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Web: Use localhost
      return 'http://localhost:$_backendPort';
    }

    if (Platform.isAndroid) {
      // Android Emulator: Use 10.0.2.2 (special alias for host machine)
      // Android Physical Device: Use LAN IP of development machine
      // 
      // To detect if running on emulator vs physical device is complex,
      // so we use the configured LAN IP which works for both if set correctly.
      // If you're using an emulator, you can change this to '10.0.2.2'
      return 'http://$_developmentLanIp:$_backendPort';
    }

    if (Platform.isIOS) {
      // iOS Simulator: Use localhost
      // iOS Physical Device: Use LAN IP of development machine
      // For simulator, localhost works; for device, use LAN IP
      return 'http://$_developmentLanIp:$_backendPort';
    }

    // Default fallback (Desktop platforms)
    return 'http://localhost:$_backendPort';
  }

  /// Alternative: Get emulator-specific URL for Android emulator
  static String get androidEmulatorUrl => 'http://10.0.2.2:$_backendPort';

  /// Alternative: Get LAN IP URL for physical devices
  static String get physicalDeviceUrl => 'http://$_developmentLanIp:$_backendPort';

  /// Production API URL (update when deploying to production)
  static const String productionApiUrl = 'https://api.eskoolia.com'; // Update with real production URL
}
