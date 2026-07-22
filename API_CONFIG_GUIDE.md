# API Configuration for Physical Device Testing

## Problem

When running the Flutter app on a **physical Android device**, `localhost:8000` refers to the mobile device itself, not your development machine where Django is running.

## Solution

The app now uses **environment-based API configuration** that automatically selects the correct base URL based on the platform.

## Configuration Required

### For Android Physical Devices

1. **Find Your Development Machine's LAN IP Address:**

   **Windows:**
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" under your active network adapter (usually starts with `192.168.x.x` or `10.x.x.x`)

   **macOS/Linux:**
   ```bash
   ifconfig
   # or
   ip addr show
   ```
   Look for the `inet` address (not `127.0.0.1`)

2. **Update the Configuration:**

   Open: `lib/core/config/env_config.dart`

   Find the line:
   ```dart
   static const String _developmentLanIp = '192.168.1.100';
   ```

   Replace `'192.168.1.100'` with **your actual LAN IP address**.

   Example:
   ```dart
   static const String _developmentLanIp = '192.168.0.105'; // Your IP here
   ```

3. **Ensure Django Backend is Running:**

   Make sure your Django backend is running and accessible on port 8000:
   ```bash
   cd backend
   python manage.py runserver 0.0.0.0:8000
   ```

   The `0.0.0.0` binding makes Django accessible from other devices on the network.

4. **Test the Connection:**

   From your mobile device's browser, try accessing:
   ```
   http://YOUR_LAN_IP:8000/health/
   ```

   Example: `http://192.168.1.100:8000/health/`

   If this works, the Flutter app will also work.

## Platform-Specific Behavior

| Platform | API Base URL |
|----------|--------------|
| **Android Physical Device** | `http://YOUR_LAN_IP:8000` |
| **Android Emulator** | `http://YOUR_LAN_IP:8000` (can use `10.0.2.2` instead) |
| **iOS Physical Device** | `http://YOUR_LAN_IP:8000` |
| **iOS Simulator** | `http://YOUR_LAN_IP:8000` or `http://localhost:8000` |
| **Web** | `http://localhost:8000` |
| **Desktop (Windows/macOS/Linux)** | `http://localhost:8000` |

## Alternative: Android Emulator

If you're using an **Android Emulator** (not physical device), you can use the special alias:

In `env_config.dart`, change:
```dart
static const String _developmentLanIp = '10.0.2.2';
```

The `10.0.2.2` address is a special alias that the Android emulator uses to refer to the host machine's `localhost`.

## Troubleshooting

### Connection Refused Error

**Symptom:** `Connection refused` when making API requests

**Solutions:**
1. Verify your LAN IP is correct in `env_config.dart`
2. Ensure Django is running with `0.0.0.0:8000` binding
3. Check that your mobile device is on the same Wi-Fi network as your development machine
4. Disable any firewall blocking port 8000

### 404 Errors on Specific Endpoints

**Symptom:** Connection works but endpoints return 404

**Solution:** Some endpoints may not be implemented in the backend yet (e.g., `/api/dashboard/attention-count/`). The app handles these gracefully by returning default values.

### Cannot Find LAN IP

**Windows:**
```powershell
# PowerShell - get all network adapters with IP
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*"} | Select-Object IPAddress, InterfaceAlias
```

**macOS/Linux:**
```bash
# Show all network interfaces
ip -4 addr show | grep inet
```

## Files Modified

- `lib/core/config/env_config.dart` - **NEW** - Environment configuration
- `lib/core/constants/api_constants.dart` - Updated to use `EnvConfig.apiBaseUrl`

## Next Steps

1. Update `_developmentLanIp` in `env_config.dart` with your LAN IP
2. Rebuild the Flutter app: `flutter run`
3. Test API connectivity on your physical device
4. Verify dashboard loads correctly
