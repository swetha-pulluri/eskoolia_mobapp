# eSkoolia Mobile - Team Context File

## Project Information
- **Project Name:** eSkoolia Mobile Application
- **Platform:** Flutter (Mobile)
- **Architecture:** Clean Architecture + MVVM + Riverpod
- **Backend:** Django REST API at http://localhost:8000/api/v1
- **Frontend Reference:** React/Next.js at frontend/app/

---

## Team Members
- **Developer:** Swetha
- **Role:** Flutter Developer
- **Responsibility:** Complete mobile app implementation

---

## Development Log

### [2024] - Login Feature Implementation ✅ COMPLETE

**Feature:** Authentication & Login Module  
**Status:** ✅ Completed and Ready for Testing  
**Total Files Created:** 28 files + 7 generated files  

#### Implementation Summary

Successfully implemented the complete Login feature following enterprise-grade Flutter architecture:

**Architecture Pattern:**
- Clean Architecture (Data → Domain → Presentation)
- MVVM with Riverpod StateNotifier
- Repository Pattern
- Dependency Injection with Riverpod Providers

**Key Components:**

1. **Core Infrastructure (7 files)**
   - API Constants with all auth endpoints
   - App Constants (storage keys, validation rules)
   - App Colors extracted from frontend globals.css
   - App Theme with Material3 dark theme
   - DioClient with auth & error interceptors
   - SecureStorageService for encrypted tokens
   - PreferencesService for app settings

2. **Data Layer (6 files)**
   - Models with freezed: LoginRequestModel, LoginResponseModel, UserModel
   - AuthRemoteDataSource for API calls
   - AuthLocalDataSource for local storage
   - AuthRepositoryImpl implementing domain interface

3. **Domain Layer (6 files)**
   - Entities: LoginEntity, UserEntity (with Equatable)
   - AuthRepository interface
   - UseCases: Login, GetCurrentUser, Logout, CheckAuthStatus

4. **Presentation Layer (6 files)**
   - AuthState with freezed (initial, loading, authenticated, unauthenticated, error)
   - AuthNotifier (StateNotifier for state management)
   - AuthProviders (complete Riverpod DI setup)
   - LoginPage with glassmorphism design matching frontend
   - Reusable widgets: CustomTextField, PasswordField, PrimaryButton

5. **Configuration (2 files)**
   - AppRouter with go_router (navigation + auth guards)
   - Main.dart with ProviderScope and router setup

**Backend Integration:**
- ✅ POST /api/v1/auth/login/ - Login endpoint
- ✅ GET /api/v1/auth/me/ - Get user profile
- ✅ POST /api/v1/auth/logout/ - Logout endpoint
- ✅ POST /api/v1/auth/refresh/ - Token refresh
- ✅ Automatic token refresh on 401
- ✅ Django REST error format handling (detail, message, error, non_field_errors)
- ✅ Multi-format username support (username/email/phone/full name)

**Security Features:**
- ✅ JWT authentication with encrypted storage
- ✅ Android: EncryptedSharedPreferences
- ✅ iOS: Keychain with first_unlock
- ✅ Automatic token refresh
- ✅ Public endpoint detection

**UI Design:**
- ✅ Exact match with frontend/app/login/page.tsx
- ✅ Glassmorphism card with backdrop blur
- ✅ Dark gradient background (slate-900)
- ✅ Cyan and Amber gradient blobs
- ✅ Color palette from globals.css:
  - Primary: #06B6D4 (cyan-500)
  - Secondary: #F59E0B (amber-500)
  - Background: #0F172A (slate-900)
- ✅ Form validation with real-time error clearing
- ✅ Loading states and error handling
- ✅ Remember Me checkbox
- ✅ Password visibility toggle

**Dependencies Added:**
```yaml
Production:
- flutter_riverpod: ^2.5.1
- riverpod_annotation: ^2.3.5
- dio: ^5.4.3+1
- pretty_dio_logger: ^1.3.1
- flutter_secure_storage: ^9.2.2
- shared_preferences: ^2.2.3
- freezed_annotation: ^2.4.1
- json_annotation: ^4.9.0
- go_router: ^14.2.0
- equatable: ^2.0.5
- logger: ^2.3.0
- intl: ^0.19.0

Dev:
- build_runner: ^2.4.11
- freezed: ^2.5.2
- json_serializable: ^6.8.0
- riverpod_generator: ^2.4.0
```

**Code Generation:**
- ✅ Ran build_runner successfully
- ✅ Generated 7 files (.freezed.dart and .g.dart)
- ✅ No compilation errors

**Issues Resolved:**
1. Fixed syntax errors in main.dart (ColorScheme, MainAxisAlignment)
2. Fixed DioClient error handling (immutable error field)
3. Fixed CardTheme → CardThemeData type error
4. Removed retrofit temporarily (version conflict)
5. Removed duplicate equatable dependency

**Testing Status:**
- Manual testing: Ready
- Backend integration: Ready (localhost:8000)
- UI/UX: Matches frontend exactly

**Documentation Created:**
- LOGIN_FEATURE_COMPLETE.md (comprehensive implementation guide)

**Next Phase (Pending Approval):**
- Dashboard implementation (portal-type specific)
- Additional auth features (forgot password, change password)
- Offline support
- Unit & integration tests

---

## Project Structure

```
eskoolia_mobapp/
├── lib/
│   ├── main.dart                              # App entry point
│   ├── config/
│   │   └── router/
│   │       └── app_router.dart                # Navigation config
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart             # API endpoints
│   │   │   └── app_constants.dart             # App constants
│   │   └── theme/
│   │       ├── app_colors.dart                # Color palette
│   │       └── app_theme.dart                 # Material theme
│   ├── data/
│   │   ├── network/
│   │   │   └── dio_client.dart                # HTTP client
│   │   └── local/
│   │       ├── secure_storage_service.dart    # Encrypted storage
│   │       └── preferences_service.dart       # App preferences
│   └── features/
│       └── auth/
│           ├── data/
│           │   ├── models/                    # Data models
│           │   ├── datasources/               # Remote & local
│           │   └── repositories/              # Impl
│           ├── domain/
│           │   ├── entities/                  # Business objects
│           │   ├── repositories/              # Interface
│           │   └── usecases/                  # Business logic
│           └── presentation/
│               ├── pages/                     # UI screens
│               ├── widgets/                   # Reusable widgets
│               └── providers/                 # State management
└── pubspec.yaml                               # Dependencies
```

---

## Backend API Reference

### Authentication Endpoints

**Login**
```
POST /api/v1/auth/login/
Body: {
  "username": "string",  // Accepts: username, email, phone, "First Last"
  "password": "string"
}
Response: {
  "access": "jwt_token",
  "refresh": "jwt_token",
  "must_change_password": false,
  "school_code": "string",
  "tenant_id": "string",
  "portal_type": "admin|teacher|parent|student"
}
```

**Get Current User**
```
GET /api/v1/auth/me/
Headers: Authorization: Bearer {access_token}
Response: UserModel JSON
```

**Logout**
```
POST /api/v1/auth/logout/
Headers: Authorization: Bearer {access_token}
Body: { "refresh": "refresh_token" }
```

**Refresh Token**
```
POST /api/v1/auth/refresh/
Body: { "refresh": "refresh_token" }
Response: { "access": "new_access_token" }
```

---

## Frontend Reference

### Files Referenced
- `frontend/app/login/page.tsx` - Login UI design
- `frontend/app/globals.css` - Color tokens and styles
- `frontend/components/ui/` - Component patterns

### Design Tokens Used
```css
--cyan-500: #06B6D4     → AppColors.primary
--amber-500: #F59E0B    → AppColors.secondary
--slate-900: #0F172A    → AppColors.background
--slate-800: #1E293B    → AppColors.surface
```

---

## Code Standards

### Flutter Best Practices
✅ Clean Architecture with clear layer separation
✅ SOLID principles (Single Responsibility, Dependency Inversion)
✅ Immutable data models with freezed
✅ Type-safe state management with Riverpod
✅ Dependency injection with Provider hierarchy
✅ Error handling at all layers
✅ Const constructors where possible
✅ Meaningful variable and function names

### File Naming Convention
- `snake_case` for file names
- `PascalCase` for classes
- `camelCase` for variables and methods
- `SCREAMING_SNAKE_CASE` for constants

### Code Organization
- One class per file
- Group related files in folders
- Barrel files for exports (if needed)
- Clear imports (no wildcard imports)

---

## Development Workflow

### Adding New Features
1. Start with domain layer (entities, repository interface, usecases)
2. Implement data layer (models, datasources, repository impl)
3. Build presentation layer (pages, widgets, providers)
4. Run code generation if using freezed/json_serializable
5. Test integration with backend
6. Update this team context file

### Code Generation Commands
```bash
# Generate freezed and json_serializable code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Running the App
```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run with specific device
flutter run -d <device_id>

# Build release APK
flutter build apk --release
```

---

## Notes

### Important Constraints
1. ✅ NEVER modify anything inside `frontend/` folder
2. ✅ NEVER modify anything inside `backend/` folder
3. ✅ Use frontend and backend only as reference
4. ✅ All implementation happens in `eskoolia_mobapp/` folder

### Backend Server
- Must be running at `http://localhost:8000`
- Database should be seeded with test data
- Test credentials required for manual testing

### Design Philosophy
- Match frontend design exactly
- Follow backend API contracts strictly
- Use enterprise-grade architecture
- Write maintainable, testable code
- Document as you build

---

## Quick Reference Links

### Documentation
- [LOGIN_FEATURE_COMPLETE.md](LOGIN_FEATURE_COMPLETE.md) - Complete login implementation guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall architecture documentation
- [FOLDER_GUIDE.md](FOLDER_GUIDE.md) - Folder structure guide
- [SUMMARY.md](SUMMARY.md) - Project summary

### External Resources
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Freezed Package](https://pub.dev/packages/freezed)
- [go_router](https://pub.dev/packages/go_router)

---

**Last Updated:** 2024  
**Last Update By:** Swetha  
**Last Feature:** Login Module Implementation (COMPLETE)
