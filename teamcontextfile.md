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

# Archana's Development Log (Home Dashboard, School Tenancy, Administration, Admissions, Attendance)

## Name
Archana Kashetti

## Date
July 16, 2026

## Branch
main

## Today's Work Done

- Converted the existing eSkoolia web dashboard experience into the Flutter mobile app inside `eskoolia-mobapp` using the existing web frontend as the source of truth.
- Implemented and refined the mobile dashboard UI using Riverpod and Clean Architecture.
- Matched the mobile dashboard to the original eSkoolia dashboard visual language and layout.
- Corrected Quick Access module names and definitions to match the exact existing web module definitions:
  - Student Attendance — Attendance
  - Student Enroll & List — Students
  - Fees Collection — Fees
  - Marks Register — Examination
- Corrected the Quick Access pinned module count to 4 and verified the exact web DEFAULT_PINS behavior.
- Corrected the All Modules list to use the exact existing eSkoolia web module definitions and removed the extra/invented modules.
- Added the eSkoolia app icon/logo in the mobile dashboard app bar.
- Added the scrollable dashboard navigation items beside the eSkoolia name:
  - Dashboard
  - School Tenancy
  - Roles and Permissions
  - Administration
  - Admissions
  - Students
  - Attendance
  - Academics
  - Examination
  - Reports
  - Fees
  - Human Resource
- Added and corrected the Recently Visited dashboard section.
- Reduced excessive spacing and adjusted dashboard proportions to more closely match the original eSkoolia UI.
- Fixed Quick Access card layout and spacing to make the dashboard more compact.
- Fixed Quick Access responsive layout to prevent pixel overflow on mobile devices.
- Identified and handled the Recently Visited API endpoint mismatch without modifying the backend.
- Tested the Flutter dashboard on mobile and reviewed UI overflow and API connectivity issues.
- Kept all changes strictly inside `eskoolia-mobapp`; no frontend or backend files were modified.

---


## DAILY UPDATE

Name: Archana
Date: July 17, 2026
Git Branch: main

Work Done Today:

1. Continued the eSkoolia Web to Flutter Mobile conversion inside `eskoolia-mobapp`.
2. Used the existing web frontend (`eSkoolia-version1-full/frontend`) and backend as READ-ONLY
   references only — no frontend or backend files were touched.
3. Extensively worked on the **School Tenancy** module (`lib/features/school_tenancy/`), covering
   all 5 tabs: Dashboard, Schools, Billing, Audit Log, and Policies.
4. Compared the Flutter implementation against the actual web pages multiple times
   (`super-admin/dashboard/page.tsx`, `schools/page.tsx`, `billing/page.tsx`, `audit/page.tsx`,
   `policies/page.tsx`) after an initial pass was found not to match the web closely enough —
   re-verified each tab directly against the web source rather than against the previous Flutter
   code.
5. Matched the web UI by refining layouts, card shapes, tables, buttons, spacing, typography
   (Instrument Serif for large numbers, exact letter-spacing/weights), colors, and mobile-responsive
   behavior across all 5 tabs.
6. Implemented sections that were previously missing, to match the web exactly:
   - **Dashboard**: Schools by Board, Geographic Distribution, and Plan Revenue sections.
   - **Schools**: the numbered-accordion School Management / Add New School section, Smart Filters,
     and the Schools List table.
   - **Billing**: Recent Invoices rebuilt as a real table, plus the full Tax Invoice preview (GST
     breakdown, amount-in-words, payment terms/bank details).
   - **Audit Log**: a real data table (Time/Actor/Action/Detail/IP Address/Severity) with a
     tap-through event detail sheet, replacing an earlier card-based layout that didn't match web.
   - **Policies**: category tabs, per-category unsaved-changes bar, and the Platform Settings /
     Quick Actions panels.
7. Fixed multiple overflow and responsive layout issues, including:
   - A `Container(color:, decoration:)` runtime crash in the Billing invoice table (Flutter does
     not allow setting both on the same widget).
   - `RenderFlex overflowed` errors on the Schools accordion headers and the dashboard's Quick
     Access module card, found via a 320px-width headless-browser check rather than guesswork.
8. Performed `flutter analyze` and manual UI verification after each fix pass — 0 errors/warnings
   each time (pre-existing info-level lints only).
9. Started the **Administration** module: inspected the web frontend and backend as READ-ONLY
   references and put in the initial module structure (the module's nav entry and theme colors)
   ahead of building the actual screens.
10. Verified that only files inside `eskoolia-mobapp` were modified; no frontend or backend files
    were changed.

---

## DAILY UPDATE

Name: Archana
Date: July 20, 2026
Git Branch: archana/home-screen

Work Done Today:

1. Continued the eSkoolia Web to Flutter Mobile conversion inside `eskoolia-mobapp`.
2. Used the web frontend and backend strictly as READ-ONLY references throughout; confirmed no
   frontend or backend files were modified at any point.
3. Continued implementation of the **Administration** module, moving from the initial structure
   started on 17 July to actual working screens.
4. Inspected the complete Administration web module structure before implementation:
   `frontend/lib/routes.ts`, `ModuleSubNav.tsx`, and the real panel source files
   (`VisitorBookPanel.tsx`, `ComplaintPanel.tsx`, `PhoneCallLogPanel.tsx`, `PostalReceivePanel.tsx`,
   `PostalDispatchPanel.tsx`, `AdminSetupPanel.tsx`, `StudentCategoryManagerPanel.tsx`), plus the
   backend (`apps/admissions`, `apps/students`) for the underlying data contract.
5. Implemented the Administration module navigation and screen hierarchy: the 4 main tabs
   (Communication Hub, Postal Management, Documents Studio, System Config) now open correctly from
   Admin Home — previously Administration was a dead link with no registered route. Added
   `administration_layout.dart` and registered the routes in `app_router.dart`.
6. Built out Communication Hub (Visitor Book, Complaints, Phone Calls), Postal Management (Postal
   Received, Postal Dispatched), and System Config (Admin Setup's 4 lookup types, Student
   Categories) as real screens with forms, validation, and tables — not placeholders.
7. Compared the Flutter Administration screens with the web frontend and identified concrete UI
   differences (flagged that the first pass didn't match closely enough), then re-compared
   line-by-line against the actual source rather than working from assumptions.
8. Refined the **Visitor Book** screen specifically by comparing it directly against
   `VisitorBookPanel.tsx`, and carried the same fidelity fixes into Complaints, Phone Calls, and
   the Postal screens:
   - **Layout/UI structure**: exact button styling (new shared `WebButton` matching the web's
     `buttonStyle()`), plain field labels instead of an invented colored asterisk, breadcrumb
     headers where the web has them, and the correct delete-confirmation dialog per panel (Visitor
     Book's own plain dialog vs. the shared icon `ConfirmationModal` used elsewhere).
   - **Search width**: corrected to the web's 240px.
   - **Validation messages**: added the inline validation banner and matched the web's exact
     field-level error text.
   - **Sorting behavior**: natural (API) order by default, only sorting by Name after the column
     header is tapped — matching the web instead of a forced default sort.
   - **Spacing**: tightened form field spacing to match the web's CSS grid gap.
   - Added the Attachment file field (`file_picker` package) to match the web's file input,
     including the same 5MB size-limit validation message.
9. Verified the existing backend API integration without modifying the backend: ran the actual
   Flutter build in a browser via an automated driver and confirmed real HTTP requests were
   reaching the real Django endpoints (`/api/v1/admissions/visitors/`, `/admin-setups/`, etc.)
   rather than any mock data being used.
10. That live run surfaced real Administration UI bugs that static review had missed, all fixed:
    a required dropdown (Purpose/Complaint Type/Source) disappearing entirely when its options
    failed to load, unwanted character counters appearing on fields that don't show one on web,
    and a raw technical exception message being displayed to the user instead of a clean error
    message.
11. Performed `flutter analyze` repeatedly through this work — 0 errors, 0 warnings each time
    (pre-existing info-level lints only).
12. Checked responsive behavior at narrow (360px) width and resolved an overflow risk in the
    shared `AdminSectionCard` header (title + search box), which could squeeze the title into a
    one-character-per-line wrap — the same overflow class already seen in School Tenancy.
13. Per a later instruction, removed backend/API integration from the Administration module for
    now: added local in-memory placeholder data and rewired the Riverpod providers to use it
    instead of the real repository, while leaving the real API/repository code untouched
    underneath so it can be reconnected later without changing any screen file.
14. Confirmed that only files inside `eskoolia-mobapp` were modified and no web frontend or
    backend files were changed at any point. Not committed or pushed.

---

## DAILY UPDATE

Name: Archana
Date: July 21, 2026
Git Branch: archana/home-screen

Work Done Today:

1. Started a new feature: the **Admissions** module, converting eSkoolia web's Admissions
   experience into `eskoolia-mobapp` (Command Center, Analytics, Marketing — the 3 sections
   listed in web's `routes.ts`).
2. Inspected the full web Admissions module read-only before writing any code:
   `AdmissionsCommandCenter.tsx` and its `command-center/` subcomponents (MorningBrief,
   ClassPortfolioGrid, ClassWorkspace, ApplicationRow, ApplicationDetailPanel, BulkActionBar,
   TemplatePicker), `AdmissionsAnalytics.tsx`, `AdmissionsMarketing.tsx`, `types/admissions.ts`,
   and the backend `apps/admissions/{models,views,urls,serializers}.py` for the data model and
   API shape only. No backend or web frontend file was modified.
3. Built the Admissions module using the same Riverpod + Clean Architecture already established
   for Administration: domain entities mirroring the backend models, an `AdmissionsLocalData`
   in-memory store (no backend calls, matching Administration's current architecture), and
   Riverpod providers wired to it.
4. Followed the same "don't invent data" rule learned on Administration: inquiries/classes/
   sources/references start empty (the real web data is backend-driven, so there's no static
   demo data to reproduce); Marketing's campaigns/templates/events are reproduced verbatim
   because the real `AdmissionsMarketing.tsx` makes zero API calls and hardcodes them itself.
5. Built the full Command Center: Morning Brief, Class Portfolio Grid (with Manage mode,
   hide/restore, seat editing), Class Workspace (stage tabs, search, paginated table,
   conversion funnel bar), Application Row/Detail Panel, Bulk Action Bar, Template Picker, and
   the New/Edit Enquiry (Quick Add + full 3-step wizard with duplicate-phone detection/merge),
   Log Contact, 3-step Call Flow, WhatsApp Composer, and post-create AI Tip popup — each matched
   against the literal web source (exact labels, colors, validation messages, button text).
6. Built the Analytics page (KPI cards with count-up + sparklines, conversion funnel, a custom
   `CustomPainter` 6-month trend chart since no chart package exists in this project, source/
   grade breakdowns, counsellor leaderboard, key insights) and extended `AdmissionsLocalData` to
   actually compute those aggregations (by source/grade/month/counsellor) from the local
   inquiries instead of leaving them empty, mirroring the backend's real aggregation logic.
7. Built the Marketing page (campaigns list + summary stats, message template library with
   channel tabs and search, preview/edit/new-campaign modals, events manager) verbatim from web.
8. Deliberately did **not** build the Broadcast modal, Document Checklist modal, or the
   WhatsApp Composer's "AI Compose" button — all three are unreachable in the real web app
   today (their only triggers are commented-out buttons, or require a live AI backend this
   offline module doesn't have), so building them would add dead UI with no corresponding web
   behavior to match.
9. Registered the 3 Admissions routes in `app_router.dart`; the Admissions Home tile already
   pointed at the right path from earlier work.
10. Ran `flutter analyze` after every file (0 issues throughout), ran a full `flutter build web
    --release`, and smoke-tested all 3 sections plus the New Enquiry and template-preview modals
    with a headless Chrome/Playwright driver at a 390×844 mobile viewport — zero page errors.
11. Confirmed that only files inside `eskoolia-mobapp` were modified and no web frontend or
    backend files were changed at any point. Not committed or pushed.



1. Started a new feature: **Attendance**. Before writing any code, traced the actual web
   rendering path end to end rather than assuming: `frontend/lib/routes.ts` (Attendance's only
   nav entry is "Student Attendance" → `/attendance/student`) → `app/(dashboard)/attendance/
   student/page.tsx` → which imports and renders only `components/shared/ComingSoon.tsx`. Also
   inspected `app/(dashboard)/layout.tsx` and `components/nav/ModuleSubNav.tsx` to confirm the
   active nav shell (`.env.local` has `NEXT_PUBLIC_NEW_NAV=1`) and that a single-item sub-nav
   still renders its one tab, plus `styles/tokens.css` for the exact placeholder colors.
2. Found that the web codebase actually contains three separate, unfinished, disconnected
   candidate implementations for this same screen (`components/attendance/
   StudentAttendancePanel.tsx`, `StudentAttendancePremiumPanel.tsx`, and a 22-file rebuild under
   `app/(dashboard)/attendance/student/components/*`) — none of them imported by `page.tsx`, so
   none are part of what the web app actually renders today. Per instruction, built strictly
   from the real render path only and ignored all three as orphaned/legacy.
3. Built the Attendance module to match that real render path exactly: a shared `ComingSoonView`
   widget (`lib/core/widgets/coming_soon_view.dart`, pixel-matched to `ComingSoon.tsx` — icon
   badge, title, subtitle, "Back to Dashboard" button, exact token colors), an `AttendanceLayout`
   wrapper matching the same breadcrumb+tab convention already used for Admissions/
   Administration (single "Student Attendance" tab, matching `ModuleSubNav`'s real behavior for
   a 1-item sub array), and `AttendanceStudentPage` wiring them together.
4. Registered the `/attendance/student` route in `app_router.dart`, and flipped the Home
   screen's Attendance tile from `comingSoon: true` (which only showed a SnackBar and never
   navigated) to actually navigating to the real route — matching the web behavior of visiting
   the module and seeing its Coming Soon page in place, rather than staying on the dashboard.
5. Ran `flutter analyze` (0 new issues), a full `flutter build web --release`, and a headless
   Chrome/Playwright smoke test at a 390×844 mobile viewport — tapped the Attendance quick-access
   card from Home, confirmed it navigates to `/attendance/student`, and confirmed the rendered
   screen visually matches web's Coming Soon exactly.
6. Confirmed that only files inside `eskoolia-mobapp` were modified and no web frontend or
    backend files were changed at any point. Not committed or pushed.



1. Corrected course on Attendance: the "Coming Soon" placeholder built earlier turned out to be
   wrong — traced the issue further and found the real implementation was never deleted, just
   disconnected. `app/(dashboard)/attendance/student/page.tsx` has a comment saying the original
   implementation "contained encoding issues" and was commented out, "preserved in git history."
   Verified this directly: `git log` on that file, and `git show` on commit `b03a1c9f` (2026-05-04,
   before the file was blanked to `<ComingSoon />`), recovered the full 1118-line real
   `StudentAttendancePage` that composes every component under
   `app/(dashboard)/attendance/student/`.
2. Read every one of the 22 components, 3 hooks, `types.ts`, and `utils/attendanceHelpers.ts` in
   that folder in full (directly and via 5 parallel research agents), and confirmed via the
   recovered page source plus a repo-wide import search which components are actually composed
   (`AttendancePageHeader`, `AttendanceAlert`, `AttendanceKPIs`, `AttendanceFilterBar`,
   `GlobalControls`, `ClassAccordionGrid` — which owns its own internal `ClassCard`/
   `SectionBody`/`SectionInnerBar`/`SectionFooter`, not the separate `ClassAccordionCard.tsx`/
   `SectionPanel.tsx`/`SectionSummaryBar.tsx` files, which are dead code — plus `SectionTabs`,
   `AttendanceTable`/`AttendanceTableRow`, `AttendanceRing`, `BulkActionBar`, `MonthlyReport`,
   and the dialogs: `AbsentNoteDialog`, `LateCommerDialog`, `NotesModal`, `ViewNotesModal`,
   `UnlockEditDialog`, `ConfirmDialog`, `ExportOptionsDialog`, `StudentAttendanceImportDialog`).
3. Rebuilt the entire Student Attendance screen in `eskoolia-mobapp` from that real
   implementation: domain entities mirroring `types.ts` verbatim, an `AttendanceLocalData` store
   (classes/students start empty — same "no backend, no invented data" rule already applied to
   Administration/Admissions, since web's own hooks fetch everything from
   `/api/v1/attendance/...` and `/api/v1/core/...` with zero hardcoded fallback), and Riverpod
   providers wired to it.
4. Built every widget pixel-for-pixel against the literal source (colors, spacing, icons,
   button/label text, empty states): page header (Download Sample/Import/Export), the RTE-risk
   alert banner, the 4 KPI cards with their skeleton/error/data branches, the Academic
   Year + level-filter bar, the date-strip/search/filter `GlobalControls` bar (week/month
   pickers, day chips, mark-all-visible P/A/L buttons), the class accordion (health-colored
   attendance ring, present/absent/late pills, section tabs, the student table with all 11
   columns and every toggle/badge/action icon), the bulk-action bar, the monthly report card,
   and all 8 dialogs (absent/late reason capture, notes add/view/edit/delete, past-date unlock,
   the imperative confirm/export-options dialogs, and the multi-step import dialog with its
   "Download Sample (XLSX)" button).
5. Adapted only what genuinely requires a backend, and disclosed each adaptation directly in
   code comments: `UnlockEditDialog` accepts any password locally instead of re-verifying
   against `/api/v1/auth/login/`; `StudentAttendanceImportDialog` simulates the upload
   progress/success instead of posting to `/bulk-store/`; `MonthlyReport` always shows its real
   "no data" empty state since there's no persisted historical attendance log to compute from
   locally; and the two "AI Suggest" buttons (in the absent/late dialogs) were left out rather
   than guessed at, since their exact templated-sentence generators weren't inspected.
6. Ran `flutter analyze` after every file (0 new issues throughout — same 6 pre-existing
   unrelated lints each time), a full `flutter build web --release`, and a headless
   Chrome/Playwright smoke test at a 390×844 mobile viewport: loaded `/attendance/student`
   directly, scrolled through the whole page (KPIs, filter bar, date strip, empty class-list
   state, Monthly Report's empty state), and opened the Import Attendance dialog — zero page
   errors or console errors throughout.
7. Confirmed that only files inside `eskoolia-mobapp` were modified and no web frontend or
   backend files were changed at any point. Not committed or pushed.

---

## Merge Log — 2026-07-22: `archana/home-screen` → `feature/login-screen`

Merged Archana's Home Dashboard / School Tenancy / Administration / Admissions / Attendance
work into Swetha's branch (Login, Login Permission, Roles & Permissions, Student Enroll & List).
The two branches had diverged from an early shared commit and built entirely different feature
sets, so no functionality overlapped — the merge conflicts were all in shared infrastructure
(routing, theming, network client, auth core, constants) plus the two `teamcontextfile.md` logs.

### Files with real conflicts, and how each was resolved
- **`pubspec.yaml`** — merged dependency lists, taking the higher version constraint for every
  package both branches specified; added `file_picker` (used by 4 Administration/Attendance
  screens but was missing from both branches' pubspec).
- **`lib/main.dart`** — kept the login branch's `MyApp`/`ProviderScope` structure and auth-status
  check on startup; added the dashboard branch's `SharedPrefs().init()` call before `runApp`
  (needed by the dashboard's pins/recents store); default theme set to `AppTheme.lightTheme`
  (dashboard-first look) with `AppTheme.darkTheme` still available.
- **`lib/config/router/app_router.dart`** — kept the login branch's `appRouterProvider` (Riverpod
  `Provider<GoRouter>`) with its auth-redirect guard (unauthenticated → `/login`), since the
  dashboard branch's static `AppRouter.router` had no auth guard at all. The `/home` route now
  points at Archana's real `AdminHomePage` (replacing the login branch's placeholder `HomePage`,
  whose own comment said "TODO: Replace with actual dashboard"). All of both branches' routes are
  registered together (login, login-permission, roles-permissions, students, students/enroll,
  home, dashboard, super-admin/*, administration/*, admissions/*, attendance/student).
- **`lib/core/theme/app_colors.dart`** — both branches added unrelated palettes to the same file
  and both used `textPrimary`/`textSecondary`/`textTertiary` for different colors. Renamed the
  login/Login-Permission/Roles set to `inkPrimary`/`inkSecondary`/`inkTertiary` (updated in the
  15 files that used them); the dashboard/administration/school-tenancy/admissions/attendance
  set keeps `textPrimary`/`textSecondary`/`textTertiary`. Both palettes now live in one file.
- **`lib/core/theme/app_theme.dart`** — kept both theme getters: `darkTheme` (login branch's
  glassmorphism auth theme, Plus Jakarta Sans) and `lightTheme` (dashboard branch's, matching web
  tokens exactly). Discarded the dashboard branch's `darkTheme => lightTheme` stub. Note:
  `AppTheme.lightTheme` reads colors from a **second**, pre-existing `AppColors` class at
  `lib/core/constants/app_colors.dart` (bg0/ink1/brandPurple tokens) — this file already existed
  as a second color system on Archana's own branch (used by the dashboard's own widgets); it was
  left as-is since consolidating it into the theme/ one is a larger refactor outside this merge's
  scope. Flagged here for a future cleanup pass.
- **`lib/data/network/dio_client.dart`** — kept the login branch's `DioClient` (constructor takes
  `SecureStorageService`, has the auth token interceptor + automatic refresh-on-401 + formatted
  error interceptor) and added the dashboard branch's convenience `get/post/put/patch/delete`
  methods so existing and future feature datasources can keep calling them directly.
- **Auth core** (`user_entity.dart`, `auth_repository.dart`, `auth_repository_impl.dart`,
  `auth_remote_datasource.dart`, `get_current_user_usecase.dart`) — kept the login branch's
  versions entirely. The dashboard branch had built a second, much simpler parallel auth stack
  (`auth_provider.dart`, `data/local/secure_storage.dart`, `user_dto.dart`, `api_interceptor.dart`)
  used by exactly one widget (`greeting_section.dart`). Repointed that widget at the real
  `authNotifierProvider`/`AuthState` and deleted the four now-unused parallel files, plus removed
  `dashboard_provider.dart`'s duplicate `dioClientProvider` in favor of the canonical one in
  `auth_providers.dart`.
- **`lib/core/constants/api_constants.dart`** — kept all of the login branch's real endpoints
  (auth, login-permission, roles, students, core); adopted the dashboard branch's `EnvConfig`-based
  dynamic `baseUrl` (web/Android/iOS aware) instead of a hardcoded IP; added the one endpoint the
  dashboard branch actually uses (`attentionCountEndpoint`). Dropped the dashboard branch's other
  placeholder endpoints (`studentsEndpoint`, `feesEndpoint`, etc.) since they were unused on both
  sides and duplicated concepts the login branch's endpoints already cover.
- **`lib/core/constants/app_constants.dart`** — simple additive merge (storage keys/validation
  from login branch + pins/recents/date-format constants from dashboard branch).
- **`teamcontextfile.md`** — both logs kept in full (Swetha's original log, then Archana's log as
  its own section), plus this merge log.

### Bugs found and fixed while reconciling the home screen with the real routes
- `Modules.all` (home screen's module grid) pointed the Roles & Permissions tile at `/roles` and
  the Students tile at `/students/list` — neither route exists; the real routes are
  `/roles-permissions` and `/students`. Fixed both, plus the matching default-pin path.
- The "Dashboard" module tile was marked `comingSoon: true` ("KPI page not implemented yet in
  Flutter") — but it already was implemented, as Swetha's `SchoolOverviewPage`. Registered it at
  `/dashboard` and flipped `comingSoon` to `false` so the tile now navigates to a real screen.

### Verification
- `flutter pub get` — required upgrading the local Flutter SDK (3.41.7 → 3.44.7) since
  `pubspec.yaml`'s `sdk: ^3.12.1` constraint (pre-existing on both branches) exceeded the
  previously-installed Dart 3.11.5.
- `flutter analyze` — 0 errors. 38 pre-existing `info`-level style lints remain (snake_case JSON
  model fields, deprecated Radio API, `print` in one auth file, etc.) — none introduced by the
  merge.
- Swept for duplicate routes, provider identifiers, and class names across `lib/`. No
  compile-breaking duplicates. A few same-named classes exist in different, never-co-imported
  files (e.g. two unrelated `KpiCard` widgets, two unrelated `classesProvider`s in
  attendance vs. administration) — pre-existing on Archana's branch, harmless, left as-is.
- `flutter test test/widget_test.dart` fails on a `NetworkImageLoadException` — pre-existing on
  the login branch alone (the login page's `TrustStrip` widget loads placeholder faculty photos
  over the network, which Flutter's test sandbox always blocks); not a merge regression. Fixed
  the test's stale `EskooliaApp()` reference to `MyApp()` (the class was renamed back during the
  `main.dart` merge) — otherwise the test wouldn't even compile.
