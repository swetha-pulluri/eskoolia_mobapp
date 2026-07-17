# eSkoolia Mobile App - Quick Start Guide

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
cd eskoolia_mobapp
flutter pub get
```

### Step 2: Generate Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Run the App

```bash
# Run on connected device/emulator
flutter run

# Or run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>        # Run on specific device
```

---

## 🔧 Development Commands

### Install Dependencies
```bash
flutter pub get
```

### Generate Code (after model changes)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run App
```bash
flutter run              # Debug mode
flutter run --release    # Release mode
```

### Hot Reload
- Press `r` in terminal
- Or save files in IDE (auto hot reload)

### Hot Restart
- Press `R` in terminal

### Check for Issues
```bash
flutter doctor           # Check Flutter installation
flutter analyze          # Analyze code for issues
```

---

## 📱 Testing

### Run on Android Emulator
1. Open Android Studio
2. Start an emulator
3. Run: `flutter run`

### Run on iOS Simulator (Mac only)
1. Open Simulator app
2. Run: `flutter run`

### Run on Physical Device
1. Enable USB debugging (Android) or trust computer (iOS)
2. Connect device via USB
3. Run: `flutter devices` to verify
4. Run: `flutter run`

---

## 🐛 Troubleshooting

### Issue: Dependencies not found
**Solution:**
```bash
flutter clean
flutter pub get
```

### Issue: Generated files missing
**Solution:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Build fails
**Solution:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Hot reload not working
**Solution:**
- Try Hot Restart (`R` in terminal)
- Or stop and restart: `flutter run`

---

## 📋 Pre-Flight Checklist

Before running the app, ensure:

- [ ] Flutter SDK installed (`flutter --version`)
- [ ] Flutter doctor passes (`flutter doctor`)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Code generated (`flutter pub run build_runner build`)
- [ ] Backend server running at `http://localhost:8000`
- [ ] Device/emulator connected (`flutter devices`)

---

## 🔗 Backend Connection

The app connects to the backend at:
- **Dev URL**: `http://localhost:8000`
- **Endpoints**: 
  - `/api/v1/auth/login/`
  - `/api/v1/auth/me/`
  - `/api/dashboard/attention-count/`
  - `/api/user/recents/`

**Note**: Ensure the backend server is running before testing API features.

---

## 📝 Notes

1. **First Launch**: Default pinned modules will be created automatically
2. **No Login**: Currently bypasses login (connects directly to dashboard)
3. **Module Navigation**: Not yet implemented (shows snackbar messages)
4. **Manage Pins**: UI not yet implemented (shows snackbar message)

---

## ✅ What Works

- ✅ Dashboard loads
- ✅ Greeting section with time-based emoji
- ✅ User name displays (from API)
- ✅ Attention count (from API)
- ✅ Recently visited modules (from API)
- ✅ Pinned modules (from local storage)
- ✅ Can remove pins
- ✅ All modules grid
- ✅ Coming soon indicators
- ✅ Pull to refresh
- ✅ Responsive layout

## ⏳ Coming Soon

- ⏳ Manage pins modal
- ⏳ Module navigation
- ⏳ Login page
- ⏳ Other module screens

---

**Ready to run!** 🎉
