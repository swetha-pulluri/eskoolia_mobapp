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
- **Responsibility:** Login, Login Permission, Roles & Permissions, Student Enroll & List

- **Developer:** Archana Kashetti
- **Role:** Flutter Developer
- **Responsibility:** Home Dashboard, School Tenancy, Administration, Admissions, Attendance

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

## Date: 2026-07-17 (Friday)

Developer: Swetha
Git Branch: feature/login-screen

Completed Work:
- Set up Clean Architecture folders (data / domain / presentation) for the `auth` feature
- Added core infrastructure: API constants, app constants, app colors/theme, Dio client, secure storage, preferences service
- Built auth data layer: login/user models (with generated freezed & json files), remote & local data sources, repository implementation
- Built auth domain layer: login/user entities, repository interface, login/logout/get-current-user/check-auth-status use cases
- Built auth presentation layer: auth state, auth notifier, auth providers, full Login page UI, reusable widgets (buttons, input fields, glass panel, feature card, gateway badge, trust strip, security panel)
- Wired up GoRouter (`app_router.dart`) and `main.dart` with ProviderScope
- Added login feature documentation set (implementation summary, setup guide, verification doc, React-to-Flutter mapping, completion doc)
- Added app logo asset and this team context file

---

## Date: 2026-07-20 (Monday)

Developer: Swetha
Git Branch: feature/login-screen

Completed Work:
- Built full Login Permission feature (models, repositories, providers, pages, widgets)
- Completed Login Permission UI to match the frontend exactly (portal tabs, stats cards, users table)
- Login Permission backend integration: meta/roles, users list, toggle login access, reset password, set initial password
- Implemented bulk-selection checkboxes and floating bulk action bar (Enable All / Disable All / Reset Passwords) with confirmation dialog, matching frontend
- Added hover/tap-reveal action icons on role cards: Assign Permissions, Edit, Deactivate/Activate, Delete
- Wired Edit, Deactivate/Activate, and Delete actions to the backend, with confirmation dialogs and toasts
- Rebuilt the Assign Permissions screen to match the frontend completely: header, Save Permissions button, summary stat cards, Active Role section with role switcher, Module Access list with switches, Operation Level cards, full Page-Level Access permissions table
- Implemented all four frontend confirmation dialogs: Confirm Delete Permission, Full Control includes Delete, Review Permissions, Sensitive Module Access
- Replaced the placeholder empty state with the full role-picker grid (matching frontend), including working role creation
- Backend integration for Assign Permissions: permission tree, assign-permissions save, and role create/edit/delete/activate
- Moved Assign Permissions from a separate placeholder route into a tab within the Roles & Permissions page, matching frontend navigation; removed the obsolete placeholder page
- Fixed a SliverPersistentHeader geometry crash and a stats-card overflow on the Login Permission screen
- Fixed a ListTile ink-splash rendering assertion by wrapping checkbox lists in a transparent Material
- Fixed save-permission failures incorrectly hiding the module editor behind a retry screen
- Added missing `mounted` checks around async dialog flows to prevent unmounted-widget crashes
- Fixed an unmounted-widget crash on the Login page's auth-state listener

---

## Date: 2026-07-21 (Tuesday)

Developer: Swetha
Git Branch: feature/login-screen

Completed Work:
- Rebuilt the Student List screen's Smart Filters panel to match the frontend exactly: compact spacing, working Academic Year / Class / Section dropdowns, Status and Special & Medical chips, Saved Presets row
- Created a reusable `AppDropdown` component (guaranteed white popup, consistent styling) after finding dropdown menus were rendering in the app's dark theme colors; rolled it out across Roles and Login Permission dropdowns too
- Rebuilt "Browse & Edit by Class" cards to match the frontend exactly: student / active / special-needs / docs-pending / sections badges plus a progress bar per class
- Found and fixed two real rendering crashes surfaced while testing the class cards (a `Border` with non-uniform colors combined with `borderRadius`, and a `Row` using `CrossAxisAlignment.stretch` under unbounded height)
- Found and fixed a real bug where Status/Saved Presets pills were stretching full width instead of hugging their content (a `Container` + `alignment` sizing issue)
- Completed backend integration for the Student Enroll & List screen: Dio-backed datasource/repository/providers replacing all mock data, loading/empty/error/success states, guardian create-then-link flow, admission number generation, and category/class/section/academic-year lookups
- Fixed the student roster table: added the missing "Message parent" action icon (View → Edit → Message → Archive order), added hover tooltips/colors, and corrected the DOB/Age format to two separate lines (`DD/MM/YYYY` then `N yrs`)
- Rebuilt the Student Profile page to match the frontend's detail drawer exactly: fetches real student + guardian detail on open, Identity/Contact sections, colored status pill, working Activate/Deactivate wired to the backend, and Message parent/Edit profile footer actions

---

## Date: 2026-07-22 (Wednesday)

Developer: Swetha
Git Branch: feature/login-screen

Completed Work:
- Started the Academics module: built the Foundation setup flow (Academic Year, Classes, Rooms, Sections, and Subjects steps) matching the frontend's step-by-step setup UI
- Built the Staff Assignment screens: workload tab, audit log tab, and the related assignment dialogs
- Registered the new Academics routes and sub-nav in `app_router.dart`
- Reconciled and briefly stashed in-progress Student backend/profile-page work before syncing with Main

*Note: reconstructed from git history — no separate commit exists for this date; content is split by module from the combined 2026-07-24 commit per your confirmation.*

---

## Date: 2026-07-23 (Thursday)

Developer: Swetha
Git Branch: feature/login-screen

Completed Work:
- Built out the Fees module: Fees Home (KPI cards, live payment feed, task queue, audit trail), Fee Configuration (Fee Types, Fee Groups, Fee Schedules, Late Fee Rules tabs), and Fee Assignment (assign/edit, bulk assign, change plan, and concession rules dialogs)
- Added the supporting data layer for Fees: remote datasources, repositories, and domain models for fee types/groups/schedules/assignments/late-fee rules
- Extended `api_constants.dart` with the new Fees endpoints

*Note: reconstructed from git history — no separate commit exists for this date; content is split by module from the combined 2026-07-24 commit per your confirmation.*

---

## Date: 2026-07-24 (Friday)

Developer: Swetha
Git Branch: Main

Completed Work:
- Added Student module extras beyond Enroll/List/Profile: Student Categories, Deleted, Disabled, Export, Groups, Promotion, Subject Assignment, and Unassigned pages
- Extended the Student Class Accordion with the additional data/actions needed by the new pages above
- Added the supporting data layer for the new Student pages: remote datasources and repositories for promotion, student category, student group, and subject assignment
- Wired all new Academics, Fees, and Student pages into `app_router.dart` and finished polishing/testing the combined work before committing
- Committed the combined Academics + Fees + Student-extras work as "Completed Fees Home, Fee Configuration and Fee Assignment modules"

*Note: this date's commit (`4a385941`) is the only one in git history covering 2026-07-22 through 2026-07-24 — its Academics/Student-extras portions were reconstructed and moved to the 22nd/23rd entries above per your confirmation; final integration, routing, and commit happened on this date.*

---

## Date: 2026-07-27 (Monday)

Developer: Swetha
Git Branch: Main

Completed Work:
- Completed Fees Home
- Completed Fee Configuration
- Completed Fee Assignment
- Completed Collection
- Completed Dues & Reminders
- Completed Year-End
- Completed backend integration and verification for the Fees module
- Verified UI with the frontend

---

## Date: 2026-07-28 (Tuesday)

Developer: Swetha
Git Branch: Main

Completed Work:
- Audited backend integration for Dashboard, Roles & Permissions, Students, Academics, and Fees
- Fixed Dashboard Quick Actions navigation
- Fixed global header and breadcrumb navigation
- Corrected Student module navigation (Add Student, Student Enroll & List, Export flow)
- Fixed responsive layout and overflow issues
- Performed frontend comparison and resolved UI/navigation mismatches
- Continued end-to-end testing and bug fixes
- Fixed a bottom-sheet overflow ("More Students tools" on Student List) and audited/fixed the same overflow risk across ~14 other dialogs, bottom sheets, and menus app-wide (Fees, School Tenancy, Admissions, Attendance, Roles, Login Permission, Administration)
- Implemented the Student Enroll screen's Drafts feature: local multi-draft save/resume/delete with search, sort, and progress tracking, matching the frontend's local-storage-based drafts flow
- Implemented the Student Enroll screen's AI Assist panel: local completion-based tips engine matching the frontend exactly (no backend/LLM call)
- Implemented the Student Enroll screen's PDF action: generates a real filled-admission-form PDF and opens the native print/share sheet
- Implemented the Student Enroll screen's "What I'll need" checklist modal, plus a printable checklist PDF
- Restyled the Enroll screen's hero action buttons (Drafts / AI Assist / PDF / What I'll need) to match the frontend's colors, icons, badges, and pulse animation exactly
- Verified with `flutter analyze` and a full `flutter build web --release` — no new errors or warnings
- Completed the Student Enroll hero action bar (Drafts, AI Assist, PDF, What I'll Need)
- Implemented the Student Verification Form with PDF preview
- Fixed Dashboard → Quick Actions → Add Student navigation
- Fixed Export behavior to match the frontend
- Fixed the Student photo upload flow
- Added Change, View Image, and Remove actions after a successful photo upload
- Implemented the Admission Number Edit ↔ Lock toggle behavior
- Fixed Multi Subject Assignment overflow issues
- Fixed bottom sheet/dialog overflow issues across the Students module
- Performed UI refinements to match the frontend exactly
- Ran `flutter analyze`/build and resolved issues where applicable

---

## Date: 2026-08-06 (Thursday)

Developer: Swetha
Git Branch: Main

Completed Work:
- Implemented the Settings module's School Info feature (initial version): entities, repository, remote datasource, provider, and the School Info page
- Added the `Settings` entry to the dashboard module list and registered its route in `app_router.dart`

---

## Date: 2026-08-13 (Thursday)

Developer: Swetha
Git Branch: Main

Completed Work:
- Rebuilt the Home Dashboard: new theme, redesigned Module Card/Grid, Quick Access Grid, Recents Row, Section Label, Attendance Pulse Card, Fees Today Card, Attention Banner, Greeting Section, and a new Manage Pins modal
- Added shared UI widgets: `fade_slide_in`, `premium_card`, `tap_scale`
- Greatly expanded the Settings module beyond School Info: Attendance Rules, Document Branding, Documents, Holiday Calendar, Leave Policy, SMTP Settings, and a Settings Audit Log — each with its own entities, repository, remote datasource, provider, page, and supporting widgets (step indicators, wizards, stat tiles, cards)
- Rebuilt the School Info page as a full step-by-step wizard (map picker, logo/color fields, review step)
- Added a new Profile page
- Updated global app shell, module sub-nav, and navigation utilities to support the new module flyout/pin system
- Added new app icon assets for all modules
- Stashed in-progress work once mid-day to pull and merge the latest `Main` (Archana's "home screen" and "school tenancy" commits), then restored the stash and continued

---

## Date: 2026-08-17 (Monday)

Developer: Swetha
Git Branch: Main

Completed Work:
- Replaced the flat module icon set with new 3D icon assets (Academics, Administration, Admissions, Attendance, Dashboard, Examination, Fees, HR, Reports, Roles & Permissions, School Tenancy, Settings, Students, Marks Register)
- Restored and refined the Widget Manager button/panel (module flyout provider, nav utils) on the dashboard
- Refined the global app shell, module card, dashboard page, and related dashboard widgets (attendance pulse card, attention banner, fees today card, greeting section, quick access grid, recents row, section label) to work with the new icon set and shell changes
- Removed the now-unused `home_dark_theme.dart`

---

## Date: 2026-08-18 (Tuesday) — Work in progress, not yet committed

Developer: Swetha
Git Branch: Main

Completed Work:
- Built a new Parent portal module from scratch (`lib/features/parent/`): data/domain/presentation layers with entities for attendance calendar, child detail, child fees, notices, parent profile ("parent me"), and parent module list
- Built the Parent portal pages: Parent Home, Children, Attendance, Fees, Notices, Profile, and a Modules page
- Built supporting Parent widgets: child switcher, sibling tabs, bottom nav, module grid, quick access grid, attendance/fees/notices/results widgets, top bar
- Added a Parent repository implementation and remote datasource, plus a dedicated Parent API exception type
- Reworked the Attendance Pulse Card, Fees Today Card, Greeting Section, Module Card/Grid, Quick Access Grid, and Recents Row on the dashboard; removed `home_ambient_particles.dart`
- Updated the AI Assistant overlay and launcher button
- Extended `app_router.dart`, `api_constants.dart`, `storage_keys.dart`, and `dio_client.dart` to support the new Parent module's routes, endpoints, and storage
- Minor update to the notification remote datasource and the login page

*Note: as of this entry these changes are uncommitted local work (git status shows modified/untracked files only) — not yet committed to `Main`.*

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

---

# Archana's Development Log (Home Dashboard, School Tenancy, Administration, Admissions, Attendance, Human Resource)

> Reorganized 30-07-2026 for readability: one section per date (no repeated Date/Branch headers), long paragraphs converted to bullet points. All original information preserved — nothing removed, only reformatted. A stray, contentless text fragment accidentally appended to the end of the file (a duplicate of a same-day chat instruction, not a work-log entry) was dropped during this cleanup.

## 16-07-2026
Developer: Archana
Git Branch: Main

### Work Done
- Converted the eSkoolia web dashboard into the Flutter mobile app (`eskoolia-mobapp`) using the existing web frontend as the source of truth.
- Implemented and refined the mobile dashboard UI using Riverpod and Clean Architecture, matching the original eSkoolia visual language and layout.
- Corrected Quick Access module names/definitions to match the exact web module definitions:
  - Student Attendance → Attendance
  - Student Enroll & List → Students
  - Fees Collection → Fees
  - Marks Register → Examination
- Corrected the Quick Access pinned module count to 4 and verified against web's exact `DEFAULT_PINS` behavior.
- Corrected the All Modules list to the exact eSkoolia web module definitions; removed extra/invented modules.
- Added the eSkoolia app icon/logo to the mobile dashboard app bar.
- Added scrollable dashboard nav items beside the eSkoolia name: Dashboard, School Tenancy, Roles and Permissions, Administration, Admissions, Students, Attendance, Academics, Examination, Reports, Fees, Human Resource.
- Added and corrected the Recently Visited dashboard section.
- Reduced excessive spacing and adjusted dashboard proportions to match the original eSkoolia UI more closely.
- Fixed Quick Access card layout and spacing to make the dashboard more compact.

### Bugs Fixed
- Fixed Quick Access responsive layout to prevent pixel overflow on mobile devices.
- Identified and handled the Recently Visited API endpoint mismatch without modifying the backend.

### Testing / Verification
- Tested the Flutter dashboard on mobile; reviewed UI overflow and API connectivity issues.

### Remarks
- All changes kept strictly inside `eskoolia-mobapp`; no frontend or backend files modified.

---

## 17-07-2026
Developer: Archana
Git Branch: Main

### Work Done
- Continued the eSkoolia Web → Flutter Mobile conversion inside `eskoolia-mobapp`.
- Used the existing web frontend (`eSkoolia-version1-full/frontend`) and backend as READ-ONLY references only — no frontend or backend files touched.
- Extensively worked on the **School Tenancy** module (`lib/features/school_tenancy/`), covering all 5 tabs: Dashboard, Schools, Billing, Audit Log, and Policies.
- Compared the Flutter implementation against the real web pages multiple times (`super-admin/dashboard/page.tsx`, `schools/page.tsx`, `billing/page.tsx`, `audit/page.tsx`, `policies/page.tsx`) after an initial pass was found not to match closely enough — re-verified each tab directly against the web source instead of the previous Flutter code.
- Matched the web UI by refining layouts, card shapes, tables, buttons, spacing, typography (Instrument Serif for large numbers, exact letter-spacing/weights), colors, and mobile-responsive behavior across all 5 tabs.
- Implemented sections that were previously missing, to match the web exactly:
  - **Dashboard** — Schools by Board, Geographic Distribution, and Plan Revenue sections.
  - **Schools** — the numbered-accordion School Management / Add New School section, Smart Filters, and the Schools List table.
  - **Billing** — Recent Invoices rebuilt as a real table, plus the full Tax Invoice preview (GST breakdown, amount-in-words, payment terms/bank details).
  - **Audit Log** — a real data table (Time/Actor/Action/Detail/IP Address/Severity) with a tap-through event detail sheet, replacing an earlier card-based layout that didn't match web.
  - **Policies** — category tabs, per-category unsaved-changes bar, and the Platform Settings / Quick Actions panels.
- Started the **Administration** module: inspected the web frontend and backend as READ-ONLY references and put in the initial module structure (nav entry + theme colors) ahead of building the actual screens.

### Bugs Fixed
- A `Container(color:, decoration:)` runtime crash in the Billing invoice table (Flutter doesn't allow setting both on the same widget).
- `RenderFlex overflowed` errors on the Schools accordion headers and the dashboard's Quick Access module card, found via a 320px-width headless-browser check rather than guesswork.

### Testing / Verification
- Ran `flutter analyze` and manual UI verification after each fix pass — 0 errors/warnings each time (pre-existing info-level lints only).
- Verified only files inside `eskoolia-mobapp` were modified; no frontend or backend files changed.

---

## 20-07-2026
Developer: Archana
**Branch:** archana/home-screen

### Work Done
- Continued the eSkoolia Web → Flutter Mobile conversion inside `eskoolia-mobapp`; frontend/backend used strictly as READ-ONLY references throughout — confirmed no frontend or backend files were modified at any point.
- Continued implementation of the **Administration** module, moving from the initial structure (started 17 July) to actual working screens.
- Inspected the complete Administration web module structure before implementation: `frontend/lib/routes.ts`, `ModuleSubNav.tsx`, and the real panel source files (`VisitorBookPanel.tsx`, `ComplaintPanel.tsx`, `PhoneCallLogPanel.tsx`, `PostalReceivePanel.tsx`, `PostalDispatchPanel.tsx`, `AdminSetupPanel.tsx`, `StudentCategoryManagerPanel.tsx`), plus the backend (`apps/admissions`, `apps/students`) for the underlying data contract.
- Implemented the Administration module navigation and screen hierarchy: the 4 main tabs (Communication Hub, Postal Management, Documents Studio, System Config) now open correctly from Admin Home — previously Administration was a dead link with no registered route. Added `administration_layout.dart` and registered the routes in `app_router.dart`.
- Built out Communication Hub (Visitor Book, Complaints, Phone Calls), Postal Management (Postal Received, Postal Dispatched), and System Config (Admin Setup's 4 lookup types, Student Categories) as real screens with forms, validation, and tables — not placeholders.
- Refined the **Visitor Book** screen specifically by comparing it directly against `VisitorBookPanel.tsx`, then carried the same fidelity fixes into Complaints, Phone Calls, and the Postal screens:
  - Exact button styling (new shared `WebButton` matching web's `buttonStyle()`), plain field labels instead of an invented colored asterisk, breadcrumb headers where web has them, and the correct delete-confirmation dialog per panel.
  - Search width corrected to web's 240px.
  - Added the inline validation banner and matched web's exact field-level error text.
  - Sorting behavior corrected to natural (API) order by default, only sorting by Name after the column header is tapped.
  - Tightened form field spacing to match web's CSS grid gap.
  - Added the Attachment file field (`file_picker`) to match web's file input, including the same 5MB size-limit validation message.
- Verified the existing backend API integration without modifying the backend: ran the actual Flutter build in a browser via an automated driver and confirmed real HTTP requests were reaching the real Django endpoints (`/api/v1/admissions/visitors/`, `/admin-setups/`, etc.) rather than any mock data.
- Per a later instruction, removed backend/API integration from the Administration module for now: added local in-memory placeholder data and rewired the Riverpod providers to use it instead of the real repository, while leaving the real API/repository code untouched underneath so it can be reconnected later without changing any screen file.

### Bugs Fixed
- A required dropdown (Purpose/Complaint Type/Source) disappearing entirely when its options failed to load.
- Unwanted character counters appearing on fields that don't show one on web.
- A raw technical exception message being displayed to the user instead of a clean error message.
- An overflow risk in the shared `AdminSectionCard` header (title + search box) at 360px width, which could squeeze the title into a one-character-per-line wrap — the same overflow class already seen in School Tenancy.

### Testing / Verification
- Compared Flutter Administration screens against the web frontend and identified concrete UI differences, then re-compared line-by-line against the actual source rather than working from assumptions.
- That live run surfaced the 3 real bugs listed above, all fixed.
- Ran `flutter analyze` repeatedly — 0 errors, 0 warnings each time (pre-existing info-level lints only).
- Checked responsive behavior at narrow (360px) width.

### Remarks
- Confirmed only files inside `eskoolia-mobapp` were modified; no web frontend or backend files changed. Not committed or pushed.

---

## 21-07-2026
Developer: Archana
**Branch:** archana/home-screen

### Work Done
- Started a new feature: the **Admissions** module, converting eSkoolia web's Admissions experience into `eskoolia-mobapp` (Command Center, Analytics, Marketing — the 3 sections listed in web's `routes.ts`).
- Inspected the full web Admissions module read-only before writing any code: `AdmissionsCommandCenter.tsx` and its `command-center/` subcomponents (MorningBrief, ClassPortfolioGrid, ClassWorkspace, ApplicationRow, ApplicationDetailPanel, BulkActionBar, TemplatePicker), `AdmissionsAnalytics.tsx`, `AdmissionsMarketing.tsx`, `types/admissions.ts`, and the backend `apps/admissions/{models,views,urls,serializers}.py` for the data model/API shape only.
- Built the Admissions module using the same Riverpod + Clean Architecture already established for Administration: domain entities mirroring the backend models, an `AdmissionsLocalData` in-memory store (no backend calls, matching Administration's current architecture), and Riverpod providers wired to it.
- Followed the same "don't invent data" rule learned on Administration: inquiries/classes/sources/references start empty; Marketing's campaigns/templates/events are reproduced verbatim since the real `AdmissionsMarketing.tsx` makes zero API calls and hardcodes them itself.
- Built the full Command Center: Morning Brief, Class Portfolio Grid (Manage mode, hide/restore, seat editing), Class Workspace (stage tabs, search, paginated table, conversion funnel bar), Application Row/Detail Panel, Bulk Action Bar, Template Picker, New/Edit Enquiry (Quick Add + full 3-step wizard with duplicate-phone detection/merge), Log Contact, 3-step Call Flow, WhatsApp Composer, and post-create AI Tip popup — each matched against the literal web source.
- Built the Analytics page (KPI cards with count-up + sparklines, conversion funnel, a custom `CustomPainter` 6-month trend chart since no chart package exists in this project, source/grade breakdowns, counsellor leaderboard, key insights) and extended `AdmissionsLocalData` to compute those aggregations locally, mirroring the backend's real aggregation logic.
- Built the Marketing page (campaigns list + summary stats, message template library with channel tabs and search, preview/edit/new-campaign modals, events manager) verbatim from web.
- Deliberately did **not** build the Broadcast modal, Document Checklist modal, or the WhatsApp Composer's "AI Compose" button — all three are unreachable in the real web app today (only triggers are commented-out buttons, or need a live AI backend this offline module doesn't have).
- Registered the 3 Admissions routes in `app_router.dart`; the Admissions Home tile already pointed at the right path from earlier work.
- Started a new feature: **Attendance**. Traced the actual web rendering path end to end before writing code: `frontend/lib/routes.ts` (Attendance's only nav entry is "Student Attendance" → `/attendance/student`) → `app/(dashboard)/attendance/student/page.tsx`, which at the time only imported/rendered `components/shared/ComingSoon.tsx`.
- Found the web codebase actually contains three separate, unfinished, disconnected candidate implementations for that same screen (`StudentAttendancePanel.tsx`, `StudentAttendancePremiumPanel.tsx`, and a 22-file rebuild under `app/(dashboard)/attendance/student/components/*`) — none imported by `page.tsx`, so none were part of what the web app actually rendered at the time. Built strictly from the real render path and ignored all three as orphaned/legacy.
- Built the Attendance module to match that real render path: a shared `ComingSoonView` widget (pixel-matched to `ComingSoon.tsx`), an `AttendanceLayout` wrapper matching the same breadcrumb+tab convention already used for Admissions/Administration, and `AttendanceStudentPage` wiring them together.
- Registered the `/attendance/student` route in `app_router.dart`, and flipped the Home screen's Attendance tile from `comingSoon: true` (which only showed a SnackBar and never navigated) to actually navigating to the real route.
- **Corrected course on Attendance same day**: the "Coming Soon" placeholder just built turned out to be wrong — the real implementation was never deleted, just disconnected (`page.tsx` had a comment saying the original "contained encoding issues" and was commented out, "preserved in git history"). Verified via `git log`/`git show` on commit `b03a1c9f` (2026-05-04) and recovered the full 1118-line real `StudentAttendancePage`.
- Read every one of the 22 components, 3 hooks, `types.ts`, and `utils/attendanceHelpers.ts` in that folder in full (directly and via 5 parallel research agents), confirming which components are actually composed (`AttendancePageHeader`, `AttendanceAlert`, `AttendanceKPIs`, `AttendanceFilterBar`, `GlobalControls`, `ClassAccordionGrid` with its own internal `ClassCard`/`SectionBody`/`SectionInnerBar`/`SectionFooter` — not the separate dead-code `ClassAccordionCard.tsx`/`SectionPanel.tsx`/`SectionSummaryBar.tsx` — plus `SectionTabs`, `AttendanceTable`/`AttendanceTableRow`, `AttendanceRing`, `BulkActionBar`, `MonthlyReport`, and 8 dialogs).
- Rebuilt the entire Student Attendance screen from that real implementation: domain entities mirroring `types.ts` verbatim, an `AttendanceLocalData` store (classes/students start empty — same "no backend, no invented data" rule), and Riverpod providers wired to it. Built every widget pixel-for-pixel against the literal source.
- Adapted only what genuinely requires a backend, disclosed directly in code comments: `UnlockEditDialog` accepts any password locally instead of re-verifying against `/api/v1/auth/login/`; `StudentAttendanceImportDialog` simulates upload progress/success instead of posting to `/bulk-store/`; `MonthlyReport` always shows its real "no data" empty state (no persisted historical attendance log locally); the two "AI Suggest" buttons were left out rather than guessed at.

### Testing / Verification
- Ran `flutter analyze` after every file (0 issues throughout), a full `flutter build web --release`, and smoke-tested all 3 Admissions sections plus New Enquiry/template-preview modals with a headless Chrome/Playwright driver at 390×844 — zero page errors.
- Ran the same verification for Attendance: `flutter analyze` (0 new issues), full release build, headless Chrome/Playwright smoke test at 390×844 (tapped the Attendance quick-access card from Home, confirmed navigation to `/attendance/student`, confirmed the screen visually matches web's Coming Soon).
- After the Attendance correction: re-ran `flutter analyze` (0 new issues, same 6 pre-existing unrelated lints) and a full release build; headless smoke test loaded `/attendance/student` directly, scrolled the whole page (KPIs, filter bar, date strip, empty class-list state, Monthly Report's empty state), and opened the Import Attendance dialog — zero page/console errors.

### Remarks
- Confirmed only files inside `eskoolia-mobapp` were modified and no web frontend or backend files were changed at any point, for both the Admissions and Attendance work (including the same-day Attendance correction). Not committed or pushed.

---

## 22-07-2026 — Merge Log
Developer: Archana
**Branch:** archana/home-screen → feature/login-screen (merge)

### Work Done
- Merged Archana's Home Dashboard / School Tenancy / Administration / Admissions / Attendance work into Swetha's branch (Login, Login Permission, Roles & Permissions, Student Enroll & List). The two branches had diverged from an early shared commit and built entirely different feature sets, so no functionality overlapped — conflicts were all in shared infrastructure (routing, theming, network client, auth core, constants) plus the two `teamcontextfile.md` logs.
- Files with real conflicts, and how each was resolved:
  - **`pubspec.yaml`** — merged dependency lists (higher version constraint for every shared package); added `file_picker` (used by 4 Administration/Attendance screens, missing from both branches).
  - **`lib/main.dart`** — kept the login branch's `MyApp`/`ProviderScope` structure and auth-status check on startup; added the dashboard branch's `SharedPrefs().init()` call before `runApp`; default theme set to `AppTheme.lightTheme` with `AppTheme.darkTheme` still available.
  - **`lib/config/router/app_router.dart`** — kept the login branch's `appRouterProvider` (has an auth-redirect guard) since the dashboard branch's static router had none. `/home` now points at the real `AdminHomePage`. All routes from both branches registered together.
  - **`lib/core/theme/app_colors.dart`** — both branches used `textPrimary`/`textSecondary`/`textTertiary` for different colors; renamed the login/Login-Permission/Roles set to `inkPrimary`/`inkSecondary`/`inkTertiary` (updated in 15 files); the dashboard/administration/school-tenancy/admissions/attendance set keeps the original names. Both palettes now live in one file.
  - **`lib/core/theme/app_theme.dart`** — kept both theme getters (`darkTheme` for auth, `lightTheme` for dashboard, matching web tokens exactly); discarded the dashboard branch's `darkTheme => lightTheme` stub. Flagged that `AppTheme.lightTheme` reads from a second, pre-existing `AppColors` class at `lib/core/constants/app_colors.dart` — left as-is (larger refactor, out of scope), noted for a future cleanup pass.
  - **`lib/data/network/dio_client.dart`** — kept the login branch's `DioClient` (auth interceptor + refresh-on-401 + error interceptor) and added the dashboard branch's convenience `get/post/put/patch/delete` methods.
  - **Auth core** — kept the login branch's versions entirely; repointed the dashboard branch's one dependent widget (`greeting_section.dart`) at the real `authNotifierProvider`/`AuthState` and deleted 4 now-unused parallel auth files.
  - **`lib/core/constants/api_constants.dart`** — kept all of the login branch's real endpoints; adopted the dashboard branch's `EnvConfig`-based dynamic `baseUrl`; added the one endpoint the dashboard branch actually uses; dropped unused placeholder endpoints.
  - **`lib/core/constants/app_constants.dart`** — simple additive merge.
  - **`teamcontextfile.md`** — both logs kept in full, plus this merge log.
- Bugs found and fixed while reconciling the home screen with the real routes:
  - `Modules.all` pointed Roles & Permissions at `/roles` and Students at `/students/list` — neither route exists; fixed to the real `/roles-permissions` and `/students` (plus the matching default-pin path).
  - The "Dashboard" module tile was marked `comingSoon: true` even though it was already implemented as Swetha's `SchoolOverviewPage` — registered at `/dashboard` and flipped `comingSoon` to `false`.

### Testing / Verification
- `flutter pub get` — required upgrading the local Flutter SDK (3.41.7 → 3.44.7) since `pubspec.yaml`'s pre-existing `sdk: ^3.12.1` constraint exceeded the previously-installed Dart 3.11.5.
- `flutter analyze` — 0 errors; 38 pre-existing info-level style lints remain, none introduced by the merge.
- Swept for duplicate routes/provider identifiers/class names across `lib/` — no compile-breaking duplicates (a few harmless same-named classes in never-co-imported files, pre-existing).
- `flutter test test/widget_test.dart` — fails on a pre-existing `NetworkImageLoadException` unrelated to the merge (Flutter's test sandbox always blocks the login page's network-loaded placeholder photos); fixed the test's stale `EskooliaApp()` reference to `MyApp()` so the test at least compiles.

---

## 23-07-2026
Developer: Archana
**Branch:** Main

*This day had 4 separate work passes as new information came in — including one explicit correction of an earlier conclusion. Kept in chronological order below so the investigation trail isn't lost.*

### Work Done — Pass 1: Administration connected to the real backend
- Connected the entire **Administration** module to the real backend (API integration had been deliberately stripped out on 20 July and replaced with local placeholder data, with the real repository left underneath specifically for this reconnection).
- Re-inspected the web frontend (`components/administration/*.tsx`) and backend (`apps/admissions`, `apps/students`) for every sub-module via 4 parallel research passes before changing anything.
- Fixed real bugs found during verification:
  - Backend wraps every create/update response as `{"success","message","data"}` — added a shared `_unwrap()` helper so create/update calls parse the real nested record.
  - Purpose / Complaint Type / Complaint Source are returned by the backend as the resolved **name**, never the numeric id — added id-or-name dual-match resolution to Visitor Book's and Complaints' Edit forms (mirrors web's own workaround).
  - Complaint attachments and Postal Received/Dispatched attachments were being silently dropped (sent as plain JSON, no file field) — switched both to multipart `file_upload`.
  - Added the missing "View existing file" link on Postal Received/Dispatched edit forms, and the missing CSV Export button on Postal Dispatch.
  - Student Categories: added the backend's `summary/`, `check-name/`, `bulk-status/`, `bulk-delete/` endpoints and `search`/`attention` query params; reworked the delete flow to attempt the delete and react to the backend's real "assigned to students" error instead of a pre-check that could never trigger.
  - Admin Setup: added surfacing of the backend's delete-dependency-block message and the missing per-type page-size selector (5/10/25/50).
- Rewired `administration_provider.dart` so Communication Hub, Postal Management, and System Config read/write through the real repository instead of local data.
- Built out **Documents Studio** (Certificates, ID Cards) from scratch — verified the backend genuinely has a complete, working implementation despite the web project's own internal tracker claiming otherwise. Added entity JSON mapping, full datasource/repository CRUD + `generate-setup` + `recipients` for both template types, a `getRoles()` call, and a `.family` recipients provider keyed by (role, class, section).
- Replaced every fake file-upload tap handler in Certificates/ID Cards' Design Template forms with real `file_picker` picks + multipart upload wired to the backend's actual field names.
- Deleted `administration_local_data.dart` once nothing referenced it.

### Work Done — Pass 2: discovery that the deployed web app is on `origin/demo`, not `main`
- Critical discovery while re-verifying Visitor Book against fresh screenshots: the web frontend/backend on `main` (verified against all day) is stale — the real, currently-shipped app lives on `origin/demo` (byte-identical to `origin/mobile`/`origin/BugFix`), which has an "Administration module UI Modernization" pass never merged back to `main`. Found by grepping all branches for UI text visible in the screenshots; 14 branches matched, `main` did not.
- Re-verified screen by screen against `origin/demo` (via `git show`, read-only):
  - Visitor Book, Complaints, Phone Calls, Postal Receive, Postal Dispatch redesigned around a shared 3-step numbered nav, new card titles, an "Editing X: {value}" chip, relabeled fields, icon-button row actions, and a new Confirm Delete modal.
  - Admin Setup: simpler 2-step nav, relaxed validation, and — confirmed from source — the redesigned list genuinely has no pagination controls at all (a real web limitation, not something to "fix").
  - Complaints' backend model changed to real FK lookup tables (`ComplaintType`/`ComplaintSource`) replacing the old admin-setup entries.
  - Complaints/Phone Calls/Postal Receive/Postal Dispatch/ID Cards all fetch their list with zero query params (confirmed via `ApiPageNumberPagination.page_size = 10`), so the real web only ever shows the backend's default first page — reproduced faithfully rather than "improved."
  - ID Cards kept its own two-column layout but gained live image thumbnail previews and dropped old CSV-style pagination. Certificates/Generate panels confirmed unchanged.
- Rebuilt, in full: `visitor_book_screen.dart`, `complaints_screen.dart`, `phone_calls_screen.dart`, `postal_receive_screen.dart`, `postal_dispatch_screen.dart`, `admin_setup_screen.dart`, plus a polish pass on `id_cards_screen.dart`.
- Built a new shared widget set (`admin_stepper_shell.dart`) so the 6 stepper-based screens share one implementation instead of each reinventing it; extended pagination/file-field widgets to match.
- Backend wiring: added `search`/`purpose`/`date` params to Visitor Book's server-side filter; added Complaint Type/Source lookups against the new FK tables; switched several screens to the real "no query params" fetch.
- Deleted `admin_badges.dart` and `AdminRadioGroup` once fully unused after the rebuild.

### Work Done — Pass 3: CORRECTION to Pass 2's Complaints conclusion
- Went back into the Complaints bugs with direct, read-only database inspection instead of route-probing, since probing alone can't distinguish "route doesn't exist" from "route exists but is broken."
- Found the live Neon Postgres database's `complaint_entries` table has **already been migrated** to `origin/demo`'s FK-based design (`complaint_type_id`/`complaint_source_id`/`assigned_to_id` exist; the old `assigned` column does not) — but the corresponding `demo` migration files don't exist on disk in the `main` checkout, and `main`'s backend code was never updated to match. The database and `main`'s backend code are now permanently out of sync for this one table.
- Directly reproduced the "Browse Complaints HTTP 500" (read-only, no writes): `main`'s real serializer throws `psycopg2.errors.UndefinedColumn: complaint_entries.assigned does not exist` on every list/retrieve/create/update — a **backend-only defect**, not something fixable from the Flutter side; flagged as needing either a merge of `demo`'s Complaint model/serializer/views into `main`, or a corrective migration.
- Reverted the earlier "keep Complaints on the old CharField contract" decision and rebuilt Complaints' data layer against `origin/demo`'s actual, live-schema-matching contract: new `ComplaintLookupEntity` + real `/complaint-types/`/`/complaint-sources/` endpoints (with an explicit `page_size=100`), integer FK ids in `toJson()`, `assigned`/`assigned_to` deliberately not sent (matches a real gap in the web itself), corrected phone validation to `origin/demo`'s real rule, and a visible validation banner on incomplete Save (previously silently no-op'd).
- Separately fixed a real, confirmed pagination-starvation bug on Visitor Book's Purpose dropdown: `AdminSetupEntryViewSet` paginates at `page_size=5` and orders Purpose entries first, so any school with 5+ Purpose entries starved out every other type. Fixed by switching to the already-existing type-filtered fetch (`type: '1', pageSize: 50`); removed the now-dead unfiltered fetch method.

### Work Done — Pass 4: full re-audit, two systemic root causes + Documents Studio fixes
- Went through Visitor Book, Complaints, Documents Studio, and System Config again, this time exercising the real DRF views directly (`force_authenticate`, read-only) instead of just reading serializer code. Found two systemic, **non-code** root causes for most remaining "dropdown mismatch"/"not loading" reports:
  1. Superuser test accounts see every tenant's data merged together by design (several `get_queryset()`s skip the `school_id` filter for superusers) — confirmed the test account is a superuser, seeing 249 roles/143 classes/302 sections merged from every school. Fix needed on the account side (use a school-scoped account), not in code.
  2. The only role with any Administration permission (`Principal`, school 1) has nobody assigned to it — a real non-superuser test account has zero `admin_section.*` permission codes, so every protected endpoint correctly 403s. Confirmed Flutter already surfaces the real error message; no code change needed, just flagged for whoever tests these screens next.
- Real Documents Studio fixes made this pass (after a research subagent mapped every web/backend/Flutter file first):
  - ID Card Design Template's role source was wrong (web tries `/access-control/roles/` first, falls back to `generate-setup`) — added `idCardDesignRolesProvider` with the correct primary+fallback order.
  - Both Generate & Print screens sourced their Template dropdown from the wrong (paginated, truncating) endpoint instead of `generate-setup`'s own unpaginated `templates` array — fixed both.
  - ID Card recipients endpoint truncates past 10 students per class on both web and the previous Flutter code — added an explicit `page_size=100` (a deliberate, disclosed deviation from literal web parity).
  - "Generate & Print still using dummy data" was real: neither screen's Print action built any real document from the selected template/recipients. Added `pdf`/`printing` packages and a new `document_print_helper.dart` that builds a real PDF from real template + recipient data and hands it to the native print/share dialog.
  - Confirmed System Config's Admin Setup Browse has no code bug — its "5 items per type, no pagination" behavior is a genuine, intentional web limitation already matched correctly.

### Testing / Verification
- Ran `flutter analyze` (0 errors, only pre-existing info-level lints) and a full `flutter build web --release` after every pass.
- All backend investigation was read-only (`git show` against reference commits/branches, `force_authenticate` against real views, plain ORM/raw-SQL reads) — no data created, modified, or deleted on the shared database. One `get_or_create()` call during troubleshooting hit an unrelated constraint and was automatically rolled back; verified afterward the row was never persisted, and the throwaway script was deleted immediately.

### Remarks
- Confirmed only files inside `eskoolia_mobapp` were modified across all 4 passes; no git operations performed.

---

## 24-07-2026
Developer: Archana
**Branch:** Main

### Work Done — Admissions: connected to the real backend
- Continued from the earlier local-data-only Admissions build; confirmed the running frontend dev server serves `main` (not `origin/demo`, which an earlier Administration session had wrongly assumed was authoritative for this module).
- Built `admissions_remote_datasource.dart`/`admissions_repository.dart`/`_impl.dart` plus JSON mapping on `InquiryEntity`, `SchoolClassEntity`/`SectionEntity`, `AnalyticsDataEntity`. Command Center inquiries/classes/sources/references now load from the real endpoints; New Enquiry, Edit, Log Contact, Call outcome, stage-move, bulk assign/delete, and seat-capacity editing now write to the real backend.
- Fixed two features that were previously fake stubs: "Open WhatsApp" now opens a real `wa.me` deep link; built real **AI Compose** (previously skipped entirely).
- Analytics now calls the real `/analytics/overview/` endpoint. Marketing confirmed already correct (its templates/campaigns/events are copied verbatim from web's own hardcoded constants).
- Real, disclosed backend defects found (not fixable from Flutter): `admin_section.admission_query.*` permission codes don't exist (403s for every non-superuser); `merge`/`actions/*` routes have no permission code at all (403s for everyone); `/ai/generate/` always 500s (wrong method signature); `/bulk/`/`/consent/` always 500 (wrong model field name in an audit-log call).
- **Regression #1 — "Classes repeated, counts/seats wrong"**: reproduced directly — several viewsets skip the `school_id` filter for superusers, so the test account's unfiltered fetch returned every school's classes merged. Fixed by adding `schoolId` to the relevant entities/user model, adding a client-side re-scope to the current school, and adding pagination-looping (`_fetchAllPages()`) so the re-scope filter has the complete dataset to filter from (verified: recovers exactly the real 15 classes for school 1, zero duplicates).
- **Regression #2 — "New Enquiry not working" / "Marketing buttons not working"**: no test credentials available to test live, so wrote a throwaway widget test to tap the buttons directly. Found two real bugs affecting all 9 modals in the module:
  1. Every `showGeneralDialog` call passed `barrierDismissible: true` with no `barrierLabel`, which throws a hard assertion in debug mode only (invisible to release-build verification, but breaks every button under `flutter run`). Fixed by adding `barrierLabel` to all 9 calls.
  2. None of those modals' content had a `Material` ancestor (`showGeneralDialog` doesn't provide one automatically) — every text field/dropdown inside threw "No Material widget found." Fixed by wrapping each modal's root content in a transparent `Material`.

### Work Done — Attendance: connected to the real backend
- Inspected the real backend (`apps/attendance`, `apps/core`) and web frontend before writing code; re-confirmed the recovered `page.tsx` implementation (commit `b03a1c9f`) is still current against `ClassAccordionGrid.tsx`/`MonthlyReport.tsx`'s latest bugfixes.
- Built `attendance_remote_datasource.dart`/`attendance_repository.dart`/`_impl.dart` wired to the real endpoints: classes/sections, daily-summary + class-summary KPIs, student-search + store (mark), Monthly Report + report-insights + client-computed week donuts, Download Sample/Export/Import, and a real password re-verification for the Unlock Editing dialog (via a direct login call, matching web's own "re-entry theater").
- Real, disclosed backend defects/limitations found (not fixable here): 3 missing permission codes (Import + the whole Subject Attendance tab permanently 403 for non-superusers); no RTE-compliance field exists server-side (matches web's own honest always-0 behavior); the real store endpoint has no way to clear a status back to "unmarked" (Reset scoped to "reload fresh from server" instead); the Academic Year dropdown is decorative on web itself; the Section filter is hardcoded to `['A','B','C']` on web itself.
- Found and fixed a real bug via a widget test: every attendance grid row threw a `RenderFlex overflowed by 3.0 pixels` because a `Border.left` color indicator deflated that row's layout width relative to the (border-less) header row. Fixed by moving the indicator to a `Positioned` overlay in a `Stack` instead of a layout-affecting border.
- Known, disclosed scope reductions: the Import dialog still uses the parent page's class list rather than the dedicated import-criteria endpoint (functionally equivalent); Subject Attendance (a separate tab) was out of scope for this pass.

### Testing / Verification
- Ran `flutter analyze` (0 errors, same pre-existing info-level lints) and a full `flutter build web --release` after both Admissions and Attendance work.
- Re-ran the Admissions widget test after both modal fixes: New Enquiry now opens with real content, zero exceptions; Marketing's New Campaign/Edit Campaign/Template Preview modals confirmed opening with real content too. Deleted the throwaway test file afterward.
- Re-ran the Attendance widget test after the overflow fix: class expand → real student-search results render; Sign In tap → real store call, zero exceptions; Monthly Report Generate → real report-insights data renders; zero RenderFlex/Material exceptions anywhere. Deleted the throwaway test file afterward.

### Remarks
- No files outside `eskoolia_mobapp` modified (added `share_plus` for real CSV export on Admissions' Class Workspace/Analytics, and reused it for Attendance); no git operations performed.

---

## 27-07-2026
Developer: Archana
**Branch:** main

### Work Done — Human Resource module: Setup, Staff Directory, and the 10-step Onboarding Wizard
- Started a new module, **Human Resource** (Setup / Staff List & Onboarding / Attendance), continuing the same "inspect real web + backend read-only first" discipline. Found the same `main`-is-stale-vs-`demo`-is-real pattern seen earlier in Administration: `main`'s HR pages are dormant/simpler, while the actually-live product's richer HR schema and pages live on `origin/demo`/`origin/BugFix`.
- **HR Setup — Department drawer**: re-verified the Add/Edit Department drawer after a user-reported mismatch; found the real, migrated `Department` model on `origin/demo` has 9 real fields an earlier pass had incorrectly stripped out. Rebuilt the entity/form to carry all 9, added `DepartmentTypeEntity` + the department-types endpoint, wired Department Head/Deputy Head to the real active-staff list. Root-caused a "dropdown shows only two options" report to the real `/api/v1/master/*` endpoints not existing on `main` at all — a backend deployment gap, disclosed rather than faked.
- **HR Staff List & Onboarding (Directory)**:
  - Added the missing **Present Today** Smart Filter (real, computed from actual daily attendance records) and an **Employment** filter kept intentionally decorative, matching a confirmed real web limitation.
  - Rebuilt the department accordion's stat row/ring to match the real page exactly (previously completely missing); fixed the department list's sort order (real web sorts alphabetically; Flutter was trusting unsorted backend order).
  - Rebuilt the row-level action icons to the real 4-icon set with a working overflow menu.
  - **Found and fixed a real crash**: tapping the View (eye) icon threw immediately (`showGeneralDialog` with `barrierDismissible: true` but no `barrierLabel`) — reproduced via a widget test and fixed. Rebuilt the profile drawer's content to match the real drawer exactly (added genuinely-real email/whatsapp fields, relabeled a compensation field, confirmed two fields should always show "—" since they aren't real backend fields even on web).
  - Fixed Edit/Documents action buttons, which were navigating to the old 5-tab Staff form instead of the real Onboarding Wizard — repointed to `/hr/onboard?edit={id}` / `?edit={id}&step=9`, adding `?step=` support to the router.
- **HR Onboarding Wizard — full build (`/hr/onboard`, 10 steps)**:
  - Investigated thoroughly (two parallel research passes over the real ~4,790-line source and its backend) after discovering an earlier assumption — that this wizard's backend was "100% non-functional" — was wrong. Confirmed real: draft/document models, reportlab-generated blank/filled PDF views, master-data endpoints, and a pincode-lookup proxy. Confirmed genuinely decorative even on the real web itself: AI Assist, "Scan to pre-fill", Upload signed, Scan & fill — kept as the same toast-only stubs; substituted the browser-only Print/PDF with a real filled-form PDF download+share.
  - Built all 10 steps (Staff identity → Role & placement → Contact & address → Family & emergency → Government identity → Qualifications → Medical & fitness → Payroll setup → Documents → Review & onboard) against the real endpoints: drafts save/resume/delete/list, blank/filled PDF, document upload/list/delete, master-data dropdowns, PIN code auto-fill, and a shared IFSC bank-lookup helper. Final submit reuses the existing create/update staff endpoint; fields beyond the existing entity schema are carried through the real `Staff.custom_field` JSON blob.
  - Added a compact "Step X/10" progress header + tap-to-jump bottom sheet as the mobile-appropriate replacement for the real page's desktop-only sidebar.
  - Found and fixed a real overflow bug via a widget test: header + footer together exceeded the viewport height once squeezed by a narrow layout — fixed by folding the header into the same scrollable region as the step content.
- **Dropdown mismatch investigation (read-only, no fixes applied yet, per explicit instruction)**: audited all 24 distinct dropdown/select fields across the Onboarding Wizard against the real web and backend. Headline findings: Mother Tongue/Religion/Nationality/Employment Type each have a duplicate "Other" item (would crash `DropdownButton`'s exactly-one-match assertion the moment "Other" is selected); the Role dropdown reads from the wrong backend endpoint; Department/Designation dropdowns similarly use the wrong (active-only) endpoint; Emergency Contact/Nominee "Relationship" should be a dropdown but was built as free text; the Degree and Disability Status lists don't match the real web's actual values. Full mismatch report with exact file/line targets delivered, but not yet acted on this session.

### Testing / Verification
- Found/reproduced the View-icon crash and the wizard's header/footer overflow via throwaway widget tests (deleted after confirming each fix).

### Remarks
- HR Onboarding's dropdown-mismatch findings are flagged for a future session — not fixed yet as of this entry, per instruction to investigate only.

---

## 28-07-2026
Developer: Archana
**Branch:** main

### Work Done — HR Module: Staff List, Onboarding Wizard fixes
- **Staff List → Export**: replaced `Share.shareXFiles` (opened the OS/Android/iOS share sheet) with the app-wide `saveBytesForDownload` helper — the same convention already used for School Tenancy's exports — so Export now downloads the CSV directly with zero share-sheet dialog, matching the real web's own `<a download>` behavior exactly.
- **Onboard → Staff Identity → "Take Photo"**: checked the real web source (`hr/onboard/page.tsx`) and confirmed it has a real "Take photo" button that opens a camera capture flow — Flutter had none, only a file/gallery picker. Reused the platform-conditional camera utility already built for Student Enroll (`camera_capture_helper.dart`) instead of adding a new dependency: opens the native OS camera directly on mobile, and the same in-page camera modal used on web when running as a web build.
- **Uploaded Photo/File → Delete/Remove**: added a small red "X" remove badge on the photo circle, shown only once a photo is set, matching the real web's `onPhotoRemove` button exactly (position, size, color). Tapping it clears the photo and lets the user upload or capture a new one.
- **Staff Code auto-generation**: found it was already being fetched automatically from the real `next-staff-no` endpoint, but was rendered as an editable text field, making it look like manual entry was expected. Checked the real web and found Staff Code is a genuine **read-only** field ("Auto generated on save" / "Generating…" placeholder until the real value arrives). Added a `readOnly` mode to the shared `onboardText` field widget and applied it here, matching web's grey/disabled styling.
- **HR Setup → "Start Onboarding" button**: was showing a "Staff Onboarding is not built yet in the app" toast — stale, since the real 10-step Onboarding Wizard (built 27-07-2026) already exists and is routed at `/hr/onboard`. Rewired the button to navigate there directly, matching the real web's own `window.location.href = "/hr/onboard"` behavior and the same route "Staff List & Onboarding → Add Staff" already used.

### Testing / Verification
- Verified each fix against the real web source before implementing (export mechanism, camera capture flow, remove-photo button, Staff Code read-only styling, Start Onboarding navigation target).
- Verified with `flutter analyze` (0 issues across the whole HR feature) and throwaway widget tests (Staff Code shows the real read-only placeholder text, Take Photo button is present, remove button clears the photo, Start Onboarding navigates to the real wizard route) — all passed, then deleted.

### Remarks
- No backend changes.
- No web frontend modifications.
- All work performed only inside `eskoolia_mobapp`.

---

## 29-07-2026
Developer: Archana
**Branch:** Main

### Work Done / Testing / Verification
- Tested the **School Tenancy** module against the real web application.
- Tested the **Administration** module against the real web application.
- Tested the **Admission** module against the real web application.
- Tested the **Attendance** module against the real web application.
- Verified Flutter screens against the web application throughout.
- Reported UI, functionality, and data mismatches found during testing.

### Remarks
- This was a testing-only pass — no code fixes were made.
- No backend modifications.
- All work performed only inside `eskoolia_mobapp`.

---

## 30-07-2026
Developer: Archana
**Branch:** Main

### Work Done
- Worked on the **School Tenancy** module: fixed the Billing/Dashboard export buttons to download directly (root cause: the backend returns real binary files that were being requested as plain text); rebuilt the Edit Invoice sheet to match the real web's Billed To / Tax Summary / Tax Logic layout instead of a stripped-down placeholder version; fixed the Recent Invoices "eye" (View) action, which was updating state correctly but scrolling nowhere visible; wired up the previously-decorative Region filter on the Schools screen (confirmed the backend filter is real, even though the reference web itself never wired its own control to it); fixed a missing "Data Isolation" tab label and missing per-category headings on the Policies screen; and rebuilt the Audit Log screen with real server-side pagination, severity/action filters, and search — replacing an earlier version that only ever filtered a fixed batch of already-loaded rows client-side.
- Implemented and verified several small UI/UX fixes flagged by testing: a missing "Attachment" label above the file picker on Administration's Visitor Book screen.
- Tested mobile responsiveness across **every HR module screen and submodule** (Setup, Staff Directory, the full 10-step Onboarding Wizard, Staff Attendance + Monthly Report, Staff Form, Verification Preview) and the School Tenancy → Audit Log screen, at 320dp/360dp/390dp/412dp widths.
- Identified and fixed real `RenderFlex`/pixel-overflow issues across the HR module and Audit Log: header button rows converted to wrap-based layouts, KPI cards switched from a fixed-aspect-ratio grid (which forced a fixed height regardless of real text content) to the existing width-constrained/height-intrinsic `KpiCardGrid`, long dynamic text (school/staff names, action names, IP addresses, labels) given proper ellipsis/wrap handling, button/filter rows split into responsive wrap/multi-line layouts on narrow screens instead of a single row that could overflow, and the Onboarding Wizard's field-grid width math corrected for narrow screens.
- Confirmed the HR module is now fully responsive end to end — zero RenderFlex/pixel-overflow warnings remaining across all HR screens and Audit Log at all 4 tested widths.

### Testing / Verification
- Verified every fix against the real web application's exact behavior before implementing (export mechanism, Edit Invoice layout, Region filter, Policies headings, Audit Log pagination/filters).
- Verified functionality with throwaway widget tests per fix (export helpers, Edit Invoice rendering, Region filter wiring, Policies headings, Audit Log pagination/filters, overflow width-sweeps at 320/360/390/412dp) — each deleted after confirming a pass.
- Ran `flutter analyze` after every change — clean, with only the same pre-existing baseline info-level lints throughout.
- Swept every HR screen and the Audit Log screen for overflow at all 4 required mobile widths — all clear.

### Remarks
- No backend changes.
- No web frontend modifications.
- All work performed only inside `eskoolia_mobapp`.
- Not committed or pushed.

---

## 04-08-2026
Developer: Archana
**Branch:** Main

*Dated from git history — one commit today, `e1e434c0` ("updated changes", 11:47:47). No per-fix breakdown exists beyond the file list itself, so this is reported at file/module level rather than invented specifics.*

### Work Done
- A broad refinement/bug-fix pass across several already-built modules in one combined commit:
  - **Documents Studio / Administration**: `admin_setup_screen.dart`, `generate_certificate_screen.dart`, `generate_id_card_screen.dart`, `id_cards_screen.dart`, `student_categories_screen.dart`, `admin_stepper_shell.dart`.
  - **Admissions**: `admissions_analytics_page.dart`, `class_portfolio_grid.dart`, `enquiry_form_modal.dart`, `morning_brief.dart`.
  - **Attendance**: `attendance_filter_bar.dart`, `attendance_kpis.dart`, `attendance_table.dart`, `class_accordion_grid.dart`, `absent_note_dialog.dart`, `export_options_dialog.dart`, `student_attendance_import_dialog.dart`.
  - **Home Dashboard**: `greeting_section.dart`, `quick_access_grid.dart`, `recents_row.dart`.
  - **Human Resource**: `designation_entity.dart`, `hr_setup_page.dart`, `staff_attendance_page.dart`, `staff_directory_page.dart`, `staff_onboard_page.dart`, `hr_department_card.dart`, `hr_department_form.dart`, `hr_designation_dept_card.dart`, `hr_designation_form.dart`, onboarding wizard steps (`step_contact.dart`, `step_payroll.dart`).
  - **Shared infrastructure**: `env_config.dart`, `api_constants.dart`, `global_app_shell.dart`, `kpi_card.dart`, `filter_pill_widget.dart`, `file_download_io.dart`, and an iOS `Info.plist` entry.

### Testing / Verification
- Not recorded for this date beyond the commit itself.

### Remarks
- No backend changes; no web frontend modifications.

---

## 06-08-2026
Developer: Archana
**Branch:** Main

*Dated from git history — three commits today.*

### Work Done — Commit `40ccfcf8`, "Implement Settings module - School Info" (12:38:38)
- Built the Settings → School Info screen: new `school_info_entity.dart`, `school_info_repository.dart`/`_impl.dart`, `school_info_remote_datasource.dart`, `school_info_page.dart`, `settings_provider.dart`; registered the route in `app_router.dart`; added a `module_entity.dart` entry and an `app_colors.dart` token for it.

### Work Done — Commit `d2b4ddf0`, "school tenancy" (12:53:48)
- Refined `add_school_page.dart` (School Tenancy's Add School form).

### Work Done — Commit `4f639a6d`, "home screen" (17:44:35)
- Built shared module-navigation infrastructure — `module_flyout_provider.dart`, `module_nav_utils.dart`, `module_pill_with_flyout.dart`, `module_sub_nav.dart` (one shared, data-driven sub-nav strip) — replacing three separate hand-coded per-module sub-nav copies (`academics_module_sub_nav.dart`, `fees_module_sub_nav.dart` deleted; `administration_layout.dart`/`admissions_layout.dart`/`attendance_layout.dart` simplified to use the shared widget instead).
- Added `search_command_palette.dart` (the global search feature).
- Updated `global_app_shell.dart`, `dashboard_provider.dart`, `module_entity.dart`, `greeting_section.dart`, `api_constants.dart`, `app_colors.dart`/`app_constants.dart`/`storage_keys.dart`, and `platform_capabilities.dart`.

### Testing / Verification
- Not recorded for this date beyond the 3 commits.

### Remarks
- No backend changes; no web frontend modifications.

---

## 13-08-2026
Developer: Archana
**Branch:** Main

*Dated from git history — two commits today.*

### Work Done — Commit `7eb64b54`, "Implemented teacher modules and updated school tenancy" (10:28:47)
- Scaffolded the entire Teacher Portal feature's data/domain layer: datasources and repository implementations for Broadcast, My Classes, Teacher Attendance, Teacher Profile, Teacher (general), Teacher Timetable, and To-dos; domain entities for all of the above plus `teacher_me_entity.dart`, `teacher_module_entity.dart`, `student_credentials_entity.dart`, `student_list_item_entity.dart`, `student_profile_entity.dart`, `reset_password_result_entity.dart`.
- Wired Teacher routing into `app_router.dart`/`portal_routes.dart`; added `portal_not_implemented_page.dart` (the Parent/Student placeholder); small `login_page.dart` tweak.
- Continued School Tenancy work: significant updates to `add_school_page.dart`, `audit_tab.dart`, `dashboard_tab.dart`, `schools_tab.dart`.
- Continued Fees Configuration polish: `concession_rules_tab.dart`, `fee_groups_tab.dart`, `fee_schedules_tab.dart`, `fee_types_tab.dart`, `late_fee_rules_tab.dart`, new `fee_config_styles.dart`.
- Other touches: `class_portfolio_grid.dart`/`class_accordion_grid.dart` (Admissions/Attendance), `fee_collection_page.dart`, `all_notes_sheet.dart`, `action_badge_widget.dart`, `module_pill_with_flyout.dart`/`module_sub_nav.dart`/`global_app_shell.dart`.

### Work Done — Commit `93cbccf6`, "new" (18:00:08)
- Added real per-module icon assets (`assets/icons/*.png` for every module) and registered them in the Android manifest / iOS `Info.plist`.
- Added new shared UI/animation widgets: `fade_slide_in.dart`, `premium_card.dart`, `tap_scale.dart`.
- Built the Home Dashboard's "Today's Pulse" live-data cards: `attendance_pulse_entity.dart`, `fees_today_entity.dart`, plus the matching datasource/repository wiring (`dashboard_local_datasource.dart`, `dashboard_remote_datasource.dart`, `dashboard_repository_impl.dart`/`_repository.dart`) and `dashboard_page.dart` updates.
- Continued Administration (`administration_remote_datasource.dart`, `admin_setup_screen.dart`, `admin_section_card.dart`, `log_contact_modal.dart`) and Attendance (`attendance_remote_datasource.dart`) work.
- Further updates to `dio_client.dart`, `global_app_shell.dart`, `module_sub_nav.dart`, `module_nav_utils.dart`, `api_constants.dart`.

### Testing / Verification
- Not recorded for this date beyond the 2 commits.

### Remarks
- No backend changes; no web frontend modifications.

---

## 17-08-2026
Developer: Archana
**Branch:** Main

*Dated from git evidence, not memory: commits `71c7916f` ("login", 12:32:02) and `6791b0c1` ("new", 13:20:41) both landed today; all further work below remained uncommitted as of this entry, with on-disk file timestamps (15:21–17:51) confirming the same day.*

### Work Done — Git merge-conflict resolution
- Resolved a git-stash-pop conflict in `module_entity.dart`: reconciled a new `iconAsset` field added to `ModuleEntity` upstream with the same field needing to be added to `SubModuleEntity` (a compile error the visible conflict markers hadn't flagged), and merged per-module `iconAsset`/`comingSoon`/`subModules` changes across Reports, Settings, and the rest of `Modules.all` without losing either side's real work.
- Resolved a second, larger conflict in `global_app_shell.dart`: compared the local (older, module-pills-in-top-bar) design against a newer upstream redesign (simplified Admin top bar + a real bottom nav) and took upstream's version, since it was a complete, later redesign superseding the older approach — not a live disagreement to guess at.
- Both files staged (`git add`) but deliberately not committed, per instruction.

### Work Done — Reports, Teacher Timetable, Fees, Attendance fixes (bundled into the `login` commit)
- **Reports module performance**: added 4 shared, non-autoDispose Riverpod providers (`reportsClassesProvider`, `reportsClassOptionsProvider`, `reportsSectionOptionsProvider`, `reportsExportClassesProvider` in `reports_providers.dart`) so every report submodule's Class/Section dropdowns load once and are reused, instead of each screen independently re-fetching from a cold start. Updated `student_attendance_report_page.dart`, `report_explorer_page.dart`, and `student_export_page.dart` to use them.
- **Teacher Timetable overflow**: `timetable_kpi_row.dart` — replaced a fixed-aspect-ratio `GridView.count` with responsive `Expanded` cards (2-per-row narrow / 4-per-row wide via `LayoutBuilder`), fixing a vertical overflow when caption text wrapped.
- **Fees overflow**: `fee_assignment_page.dart`'s class-card header and `fee_year_end_page.dart`'s two carry-forward-card title/subtitle rows converted from `Row` to `Wrap`, fixing overflow when class names/subtitles ran long.
- **Attendance reset bug**: rewrote `attendance_student_page.dart`'s `_handleReset` to match the real web behavior — reset now sets every student to "unmarked", then persists a "present" baseline for the section, then reloads, instead of a reset that silently did nothing.
- **Fees "Audit Trial" text bug — investigated, not resolved**: checked `fees_audit_trail_card.dart` and the rest of the Fees module for any code-level cause of a reported rendering glitch; found only a normal `Text('Audit Trail', ...)` widget with nothing unusual. Requested a screenshot to continue; none was received, so this remains open, not fixed.
- School Tenancy (`add_school_page.dart`, `edit_school_page.dart`, `school_detail_page.dart`, `schools_tab.dart`) and several Administration screens (`id_cards_screen.dart`, `student_categories_screen.dart`, `call_flow_modal.dart`, `class_workspace.dart`) and HR screens (`hr_setup_page.dart`, `staff_attendance_page.dart`, `attendance_absent_dialog.dart`, `hr_department_card.dart`, `hr_designation_dept_card.dart`) are present in the same commit — included here for completeness since they're part of today's git history, though their specific prior changes weren't part of this session's own work log.

### Work Done — Multi-school login (subdomain identification)
- Built a school-identification step (`school_select_page.dart`) so one APK can serve multiple schools: user enters their school's web address, it's checked against the existing public `GET /tenancy/school-info/?subdomain=` endpoint, and the resolved school's name/logo are shown before handing off to the existing (unmodified) login form.
- After clarification, made the plain `app.eskoolia.com`-style login the **default, un-gated** path — `/school-select` is a separate, optional page reachable only via a link on the login screen, never forced.
- New: `school_info_model.dart`. Changed: `auth_providers.dart`, `auth_remote_datasource.dart`, `app_router.dart`, `login_page.dart`, `api_constants.dart`.
- Confirmed via code inspection that no school URL is ever fabricated or hardcoded — the typed subdomain is only ever passed to the backend's own lookup endpoint.

### Work Done — Chrome "No Internet Connection" bug, root-caused and fixed
- Diagnosed (via git diff against the pre-feature commit and live console logs, not guesswork) that a newly-added `X-Tenant` header on the post-login `/me/` call forces a CORS preflight in Chrome that the backend's CORS policy doesn't allow-list — harmless on Android (no CORS layer there), but it broke every teacher/admin login on Flutter Web.
- Fix: `dio_client.dart` now skips the `X-Tenant` header only when `kIsWeb`; Android/iOS behavior is unchanged. Verified live against the real production backend with direct API calls before and after the fix.

### Work Done — Forgot Access Key (full password-reset flow)
- Confirmed the backend already implements `forgot-password/` / `verify-reset-code/` / `reset-password/` and that web already has a working UI for it — reused both verbatim, no backend or web changes.
- Built the full Clean Architecture stack: 3 usecases (`forgot_password_usecase.dart`, `verify_reset_code_usecase.dart`, `reset_password_usecase.dart`), repository/datasource methods, a `password_reset_notifier.dart`/`password_reset_state.dart` state layer, and two screens.
- Rebuilt the two screens a second time after the first pass didn't match web closely enough — pulled the actual web CSS/TSX source and replicated it (gradient heading, watermark text, step progress bar, password-strength meter, resend cooldown) via new shared widgets `recovery_shell.dart`, `recovery_input_field.dart`, `recovery_button.dart`.

### Work Done — LKG Teacher Home screen
- Investigated the existing login response, teacher role detection, and Teacher Home/routing before writing code; confirmed no LKG-specific screen exists on web to copy from (a greenfield UI decision, not a port).
- Identified LKG teachers from real, already-fetched backend data — `teacherMeProvider`'s `class_teacher_for.class_name == 'LKG'` (from `GET /api/v1/teacher/me/`) — not a hardcoded condition.
- `teacher_home_page.dart` now branches to a new `lkg_teacher_home_content.dart`, which reuses every existing Teacher Home widget, just reordered to foreground the class-teacher/attendance card; nothing removed.

### Work Done — Teacher bottom navigation and top-bar correction
- Added a real Home / All Modules / Profile bottom nav for Teacher (`global_app_shell.dart`) without changing Admin's own bottom nav at all.
- Made `modules_page.dart`/`module_grid.dart` reusable via optional parameters (Admin's own `/modules` call site behavior is unchanged) instead of duplicating a screen, and added the missing `/teacher/modules` route.
- Added a Logout button to `teacher_profile_page.dart`, needed once the top bar's avatar/logout dropdown was removed.
- First redesigned `teacher_top_bar.dart` down to logo/badge/title/search/notes/profile-icon, which turned out to remove functionality still wanted — **corrected same day**: restored the existing module-pill navigation strip exactly as it was, and set the top-right icons to exactly Search, Sticky Notes, and Notifications (no profile icon there, no Widgets icon), per direct follow-up instruction. Bottom nav was not touched during this correction.

### Testing / Verification
- Ran `flutter analyze` after every change across all of the above — clean, only the same pre-existing baseline info-level lints throughout (`avoid_print`, `non_constant_identifier_names` on backend-mirrored fields, a few `unnecessary_const`/deprecated-API infos elsewhere in the codebase), zero new errors or warnings.
- Verified the Chrome CORS fix and the Forgot Access Key endpoints live against the real production backend with direct API calls (not just code review).
- Attempted to test the Teacher bottom-nav/top-bar changes interactively (emulator + login), but no Android emulator and no browser-automation tool were available in this environment — flagged as still needing a manual device test.

### Remarks
- No backend changes. No web frontend modifications.
- All work performed only inside `eskoolia_mobapp`.
- Nothing committed or pushed during this session's own work (the `login`/`new` commits predate it, per git history above).

---

## 17-08-2026 (addendum)
*Commit `cd622bc0` ("done", 10:35:03) landed earlier the same day, before `login`/`new` above — not part of that entry, added here for completeness.*

### Work Done
- Replaced the flat icon set with a new "3D" icon set (`*_3d.png` for academics, administration, admissions, attendance, dashboard, examination, fees, hr, reports, roles & permissions, settings, students, plus a new `school_tenancy_3d.png` and `marks-register.png`).
- Re-added `module_flyout_provider.dart` and built the **Widget Manager** feature (`widget_manager_button.dart`, `widget_manager_panel.dart`) — lets a user toggle which optional Home-dashboard widgets are visible.
- Continued Home Dashboard refinements: `dashboard_page.dart`, `greeting_section.dart`, `module_card.dart`, `quick_access_grid.dart`, `recents_row.dart`, `section_label.dart`, `attendance_pulse_card.dart`, `attention_banner.dart`, `fees_today_card.dart`, `module_nav_utils.dart`, `module_sub_nav.dart`, `global_app_shell.dart`, `premium_card.dart`, `ai_assistant_overlay.dart`, `module_entity.dart`.
- Removed an unused `home_dark_theme.dart`.

### Testing / Verification
- Not recorded for this date beyond the commit itself.

### Remarks
- No backend changes; no web frontend modifications.
`