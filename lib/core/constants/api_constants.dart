import '../config/env_config.dart';

/// API Constants for Eskoolia Backend
/// Reference: backend/apps/users/urls.py and views.py
class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  // Base URL - Configured based on platform and environment
  // For Android physical devices, update the LAN IP in env_config.dart
  static String get baseUrl => EnvConfig.apiBaseUrl;

  // API Version
  static const String apiVersion = 'v1';

  // API Base Path
  static const String apiBasePath = '/api/$apiVersion';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String login = '$apiBasePath/auth/login/';
  static const String logout = '$apiBasePath/auth/logout/';
  static const String me = '$apiBasePath/auth/me/';
  static const String refresh = '$apiBasePath/auth/refresh/';
  static const String changePassword = '$apiBasePath/auth/change-password/';

  // Forgot/Reset Password (public — no auth required). Reference:
  // backend/apps/users/views.py — ForgotPasswordView, VerifyResetCodeView,
  // ResetPasswordView; backend/apps/users/urls.py. Same 3-step,
  // email + 6-digit-OTP flow web's /forgot-password and /reset-password
  // pages already use (frontend/lib/auth-context.tsx) — reused verbatim,
  // no backend changes.
  static const String forgotPassword = '$apiBasePath/auth/forgot-password/';
  static const String verifyResetCode = '$apiBasePath/auth/verify-reset-code/';
  static const String resetPassword = '$apiBasePath/auth/reset-password/';

  // Tenancy — School Setup (a super-admin cross-school CRUD surface, NOT the
  // Settings → School Info screen — see settingsSchoolInfo below for that).
  // Reference: backend/apps/tenancy/urls.py (SchoolViewSet, router-registered
  // "schools").
  static const String tenancySchools = '$apiBasePath/tenancy/schools/';
  static String tenancySchoolDetail(int id) => '$tenancySchools$id/';

  // Settings → School Info screen (the single-school-tenant profile wizard:
  // identity, principal contact, address/map, compliance, branding).
  // Reference: backend/apps/settings/{urls,views,serializers}.py
  // (SchoolInfoView, SchoolInfoLogoUploadView), frontend/components/settings/
  // SchoolInfoPanel.tsx. Logo upload's multipart field name is `file`, not
  // `logo` — confirmed from SchoolInfoLogoUploadView.post().
  static const String settingsSchoolInfo = '$apiBasePath/settings/school-info/';
  static const String settingsSchoolInfoLogo = '${settingsSchoolInfo}logo/';

  // Settings → Leave Policy screen (leave-type CRUD + carry-forward
  // sub-resources). Reference: backend/apps/settings/{urls,views,
  // serializers}.py (LeavePolicyViewSet, LeaveCarryForward*View),
  // frontend/components/settings/LeavePolicyPanel.tsx.
  static const String settingsLeavePolicy = '$apiBasePath/settings/leave-policy/';
  static String settingsLeavePolicyDetail(int id) => '$settingsLeavePolicy$id/';
  static const String settingsLeaveCarryForwardPreview =
      '$apiBasePath/settings/leave-carry-forward/preview/';
  static const String settingsLeaveCarryForwardRun =
      '$apiBasePath/settings/leave-carry-forward/run/';
  static const String settingsLeaveCarryForwardHistory =
      '$apiBasePath/settings/leave-carry-forward/history/';
  // Filtered with ?module=<ModelName>&object_id=<id> — confirmed against
  // SettingsAuditLogViewSet.get_queryset() (object_type__iexact=module).
  static const String settingsAuditLog = '$apiBasePath/settings/audit-log/';

  // Settings → Holiday Calendar screen. Reads/writes the same `Holiday` rows
  // as Academics > Foundation's own calendar (via `coreHolidays` below) plus
  // a Settings-only exclusion join-table and a read-only aggregation view.
  // Reference: backend/apps/settings/{urls,views,serializers}.py
  // (StaffHolidayCalendarView, StaffHolidayExclusionViewSet),
  // frontend/components/settings/HolidaysPanel.tsx.
  static const String settingsStaffHolidayCalendar = '$apiBasePath/settings/staff-holiday-calendar/';
  static const String settingsStaffHolidayExclusions = '$apiBasePath/settings/staff-holiday-exclusions/';
  static String settingsStaffHolidayExclusionDetail(int id) => '$settingsStaffHolidayExclusions$id/';

  // Settings → SMTP Settings screen. Reference: backend/apps/settings/
  // {urls,views,serializers}.py (SchoolSMTPSettingsViewSet),
  // frontend/components/settings/SmtpSettingsPanel.tsx. `password` is
  // write-only server-side (never returned — only a masked
  // `password_display`); `test_send` accepts the raw unsaved draft, no
  // saved config id required.
  static const String settingsSmtp = '$apiBasePath/settings/smtp/';
  static String settingsSmtpDetail(int id) => '$settingsSmtp$id/';
  static String settingsSmtpActivate(int id) => '${settingsSmtpDetail(id)}activate/';
  static const String settingsSmtpTestSend = '${settingsSmtp}test_send/';

  // Settings → Attendance Rules screen. Reference: backend/apps/settings/
  // {urls,views,serializers}.py (SchoolAttendancePolicyViewSet — a real CRUD
  // list, unlike SMTP/School Info's singleton endpoints; exactly one policy
  // per school is flagged `is_default` via the `make_default/` action),
  // frontend/components/settings/AttendanceRulesPanel.tsx.
  static const String settingsAttendancePolicies = '$apiBasePath/settings/attendance-policies/';
  static String settingsAttendancePolicyDetail(int id) => '$settingsAttendancePolicies$id/';
  static String settingsAttendancePolicyMakeDefault(int id) => '${settingsAttendancePolicyDetail(id)}make_default/';

  // Settings → Documents screen ("Policy Documents"). Reference:
  // backend/apps/settings/{urls,views,serializers}.py
  // (SchoolPolicyDocumentViewSet — multipart create, JSON-only PATCH for
  // title/category, soft delete via is_active), frontend/components/
  // settings/DocumentsPanel.tsx. Category is a fixed 4-value enum, not a
  // manageable list.
  static const String settingsDocuments = '$apiBasePath/settings/documents/';
  static String settingsDocumentDetail(int id) => '$settingsDocuments$id/';

  // Settings → Document Branding screen. Reference: backend/apps/settings/
  // {urls,views,serializers}.py (DocumentBrandingSettingsView,
  // DocumentBrandingUploadLetterheadView, DocumentBrandingHeaderImageView,
  // DocumentBrandingPreviewView), frontend/components/settings/
  // DocumentBrandingPanel.tsx. A singleton settings form (one row per
  // school), unlike the letterhead/rendered image itself, which has no URL
  // field at all — only fetched via the two binary PNG endpoints below.
  static const String settingsDocumentBranding = '$apiBasePath/settings/document-branding/';
  static const String settingsDocumentBrandingUploadLetterhead =
      '${settingsDocumentBranding}upload-letterhead/';
  static const String settingsDocumentBrandingHeaderImage = '${settingsDocumentBranding}header-image/';
  static const String settingsDocumentBrandingPreview = '${settingsDocumentBranding}preview/';

  // Access Control — Login Permission Endpoints
  // Reference: backend/apps/access_control/views.py - LoginPermissionViewSet
  static const String accessControlBasePath = '$apiBasePath/access-control';
  static const String loginPermissionBasePath =
      '$accessControlBasePath/login-permission';
  static const String loginPermissionMeta = '$loginPermissionBasePath/meta/';
  static const String loginPermissionUsers = '$loginPermissionBasePath/users/';
  static const String loginPermissionToggle =
      '$loginPermissionBasePath/toggle/';
  static const String loginPermissionResetPassword =
      '$loginPermissionBasePath/reset-password/';
  static const String loginPermissionSetInitialPassword =
      '$loginPermissionBasePath/set-initial-password/';
  static const String loginPermissionBulkAccess =
      '$loginPermissionBasePath/bulk-access/';
  static const String loginPermissionBulkReset =
      '$loginPermissionBasePath/bulk-reset/';

  // Access Control — Roles Endpoints
  // Reference: backend/apps/access_control/views.py - RoleViewSet
  static const String roles = '$accessControlBasePath/roles/';
  static String roleDetail(int id) => '$accessControlBasePath/roles/$id/';
  static String rolePermissionTree(int id) =>
      '$accessControlBasePath/roles/$id/permission-tree/';
  static String roleAssignPermissions(int id) =>
      '$accessControlBasePath/roles/$id/assign-permissions/';

  // Students
  // Reference: backend/apps/students/urls.py + views.py::StudentViewSet
  static const String studentsBasePath = '$apiBasePath/students';
  static const String students = '$studentsBasePath/students/';
  static String studentDetail(int id) => '$studentsBasePath/students/$id/';
  static const String studentsSummary = '$studentsBasePath/students/summary/';
  static const String studentNextAdmissionNo =
      '$studentsBasePath/students/next-admission-no/';
  static String studentSetStatus(int id) =>
      '$studentsBasePath/students/$id/set-status/';
  static String studentSoftDelete(int id) =>
      '$studentsBasePath/students/$id/soft-delete/';
  static const String studentCategories = '$studentsBasePath/categories/';
  static const String guardians = '$studentsBasePath/guardians/';
  static String guardianDetail(int id) => '$guardians$id/';
  static const String studentUploadPhoto = '$studentsBasePath/students/upload-photo/';
  static const String studentDocumentUpload = '$studentsBasePath/documents/upload_document/';
  static String studentRestore(int id) => '$studentsBasePath/students/$id/restore/';
  static String studentPermanentDelete(int id) =>
      '$studentsBasePath/students/$id/permanent-delete/';
  static const String studentRecordAudits = '$studentsBasePath/record-audits/';
  static const String studentExportXlsx = '$studentsBasePath/students/export-xlsx/';

  // Student Categories (full CRUD) — Reference: apps/students/views.py::StudentCategoryViewSet
  static String categoryDetail(int id) => '$studentCategories$id/';
  static const String categorySummary = '${studentCategories}summary/';
  static const String categoryCheckName = '${studentCategories}check-name/';
  static const String categoryBulkStatus = '${studentCategories}bulk-status/';
  static const String categoryBulkDelete = '${studentCategories}bulk-delete/';

  // Student Groups / Clubs — Reference: apps/students/views.py::StudentGroupViewSet
  static const String studentGroups = '$studentsBasePath/groups/';
  static String studentGroupDetail(int id) => '$studentGroups$id/';
  static const String studentGroupStats = '${studentGroups}stats/';
  static const String studentGroupStudents = '${studentGroups}students/';
  static const String studentGroupAssign = '${studentGroups}assign/';
  static const String studentGroupBulkAssign = '${studentGroups}bulk-assign/';
  static const String studentGroupClubToggle = '${studentGroups}club-toggle/';
  static const String studentGroupClubAssign = '${studentGroups}club-assign/';
  static const String studentGroupSortwellPreview = '${studentGroups}sortwell-preview/';
  static const String studentGroupSortwell = '${studentGroups}sortwell/';

  // InspireHub (Competitions & AI Reviews) — Reference: apps/competitions/urls.py.
  // Competitions/results themselves live primarily on-device (InspireHubStore);
  // these are used for best-effort backend sync — see CompetitionsRepository.
  static const String competitionsBasePath = '$apiBasePath/competitions';
  static const String competitions = '$competitionsBasePath/competitions/';
  static const String competitionResultsBulk = '$competitionsBasePath/results/bulk/';
  static const String competitionAiReview = '$competitionsBasePath/ai/review/';

  // Student Promotion — Reference: apps/students/views.py::PromotionBatchViewSet
  static const String promotionBatches = '$studentsBasePath/promotion-batches/';
  static const String promotionBatchCreateOrGet =
      '${promotionBatches}create-or-get/';
  static String promotionBatchUpdateRecord(int batchId) =>
      '$promotionBatches$batchId/update-record/';
  static String promotionBatchBulkUpdate(int batchId) =>
      '$promotionBatches$batchId/bulk-update/';
  static String promotionBatchAiRecommendation(int batchId) =>
      '$promotionBatches$batchId/ai-recommendation/';
  static String promotionBatchConfirm(int batchId) =>
      '$promotionBatches$batchId/confirm/';
  static String promotionBatchFinalize(int batchId) =>
      '$promotionBatches$batchId/finalize/';

  // Multi Subject Assignment — Reference: apps/students/views.py (StudentViewSet +
  // StudentSubjectAssignmentViewSet actions). Frontend route is named
  // "multi-class" but the actual screen is subject (2nd language/sport/etc.)
  // assignment, not multiple homeroom classes — see student_subject_assignment
  // feature doc comment.
  static const String subjectAssignmentStats =
      '$studentsBasePath/students/subject-assignment-stats/';
  static const String subjectAssignmentClassSectionTree =
      '$studentsBasePath/students/class-section-tree/';
  static const String subjectAssignmentSectionStudents =
      '$studentsBasePath/students/section-students/';
  static const String subjectAssignmentUpsertOptional =
      '$studentsBasePath/subject-assignments/upsert-optional/';

  // Attendance — Reference: backend/apps/attendance/urls.py + views.py
  static const String attendanceBasePath = '$apiBasePath/attendance';
  static const String studentAttendance = '$attendanceBasePath/student-attendance/';
  // AI Assistant's "report absence" flow — a distinct action route from the
  // main Attendance screen's own `store/` (confirmed in
  // frontend/components/aibot/AbsenceFlow.tsx): single-student, one-shot
  // mark, returns the resolved student/class/section names in the response.
  static const String studentAttendanceChatbotMark = '${studentAttendance}chatbot-mark/';
  // Home screen's "Today's Pulse" attendance card. Reference:
  // backend/apps/attendance/views.py::StudentAttendanceDashboardAPIView,
  // frontend/components/widgets/pulse/AttendanceSnapshot.tsx (via
  // frontend/lib/services/attendanceDashboardService.ts). Accepts an
  // optional `?date=YYYY-MM-DD` query param (defaults to today server-side).
  static const String attendanceDashboardToday = '$attendanceBasePath/dashboard/today/';

  // Core — Classes / Sections / Academic Years / Streams / Rooms / Holidays
  // Reference: backend/apps/core/urls.py + views.py
  static const String coreBasePath = '$apiBasePath/core';
  static const String coreClasses = '$coreBasePath/classes/';
  static const String coreSections = '$coreBasePath/sections/';
  static const String coreSectionsReplace = '${coreSections}replace/';
  static const String coreSectionsBulkDelete = '${coreSections}bulk-delete/';
  static const String coreAcademicYears = '$coreBasePath/academic-years/';
  static const String coreStreams = '$coreBasePath/streams/';
  static const String coreClassRooms = '$coreBasePath/class-rooms/';
  static const String coreHolidays = '$coreBasePath/holidays/';
  static const String coreHolidaysCopyFromYear = '${coreHolidays}copy-from-year/';
  static const String coreSubjects = '$coreBasePath/subjects/';

  // Academics — Foundation setup (class-subject entries)
  // Reference: backend/apps/academics/urls.py + views.py
  static const String academicsBasePath = '$apiBasePath/academics';
  static const String academicsClassSubjectEntries = '$academicsBasePath/class-subject-entries/';
  static const String academicsClassSubjectEntriesResetClass = '${academicsClassSubjectEntries}reset-class/';

  // Academics — Staff Assignment (class teachers, subject teachers, workload, audit, KPI)
  // Reference: backend/apps/academics/urls.py + views.py
  static const String staffTeachers = '$academicsBasePath/staff/teachers/';
  static const String staffClassTeachers = '$academicsBasePath/staff/class-teachers/';
  static const String staffSubjectAssignments = '$academicsBasePath/staff/subject-assignments/';
  static const String staffWorkload = '$academicsBasePath/staff/workload/';
  static const String staffAuditLog = '$academicsBasePath/staff/audit-log/';
  static const String staffKpi = '$academicsBasePath/staff/kpi/';

  // Fees — Home screen only (Payments feed, Assignments summary, Home
  // dashboard tasks/audit). Reference: backend/apps/fees/urls.py + views.py.
  static const String feesBasePath = '$apiBasePath/fees';
  static const String feesAssignments = '$feesBasePath/assignments/';
  static String feesAssignmentDetail(int id) => '$feesAssignments$id/';
  static const String feesAssignmentsSummary =
      '$feesBasePath/assignments/summary/';
  static const String feesPayments = '$feesBasePath/payments/';
  // Home screen's "Today's Fees" card. Reference:
  // backend/apps/fees/views.py::TodayFeesSummaryAPIView, frontend/components/
  // widgets/pulse/FeesToday.tsx. The frontend calls the non-versioned
  // `/api/fees/today-summary/`, but the backend registers the exact same
  // view at `/api/v1/fees/today-summary/` too (config/urls.py) — using the
  // versioned path here for consistency with every other endpoint in this
  // file; same data either way. Response fields are camelCase (unlike most
  // of this backend), confirmed against the real view — not a typo.
  static const String feesTodaySummary = '$feesBasePath/today-summary/';
  // NOTE: no `home/` route exists on the backend yet — see
  // fees_repository_impl.dart::fetchHomeDashboard doc comment.
  static const String feesHome = '$feesBasePath/home/';

  // Fees — Fee Configuration screen (Groups, Types, Term Settings,
  // Schedules, Concession Rules, Late Fee Rules).
  // Reference: backend/apps/fees/urls.py + views.py.
  static const String feesGroups = '$feesBasePath/groups/';
  static String feesGroupDetail(int id) => '$feesGroups$id/';
  static const String feesTypes = '$feesBasePath/types/';
  static String feesTypeDetail(int id) => '$feesTypes$id/';
  static const String feesTermSettings = '$feesBasePath/term-settings/';
  static String feesTermSettingsDetail(int id) => '$feesTermSettings$id/';
  static const String feesSchedules = '$feesBasePath/schedules/';
  static String feesScheduleDetail(int id) => '$feesSchedules$id/';
  static const String feesConcessionRules = '$feesBasePath/concession-rules/';
  static String feesConcessionRuleDetail(int id) => '$feesConcessionRules$id/';
  static const String feesLateFeeRules = '$feesBasePath/late-fee-rules/';
  static String feesLateFeeRuleDetail(int id) => '$feesLateFeeRules$id/';

  // Fees — Collection screen (payment posting, bank/UPI/cheque
  // reconciliation, authenticated receipt/ledger header info).
  // Reference: frontend components/fees/FeesCollectionPanel.tsx.
  static const String feesReconciliations = '$feesBasePath/reconciliations/';
  static String feesReconciliationDetail(int id) => '$feesReconciliations$id/';
  // Used by the Collection screen's receipt/ledger header
  // (fees_collection_remote_datasource.dart::fetchMySchoolInfo) — kept
  // as-is; out of scope for the School Info (Settings) screen rebuild,
  // which now uses the real `tenancySchools` CRUD endpoint instead.
  static const String tenancyMySchoolInfo = '$apiBasePath/tenancy/my-school-info/';

  // Fees — Dues & Reminders screen (escalation tiers, class-wise due lists,
  // per-student interaction log, bulk reminders, CSV/PDF export).
  // Reference: frontend components/fees/FeesDuesRemindersPanel.tsx.
  static const String feesDuesBasePath = '$feesBasePath/dues';
  static const String feesDuesSummary = '$feesDuesBasePath/summary/';
  static const String feesDuesByClass = '$feesDuesBasePath/by-class/';
  static const String feesDuesInteractions = '$feesDuesBasePath/interactions/';
  static const String feesDuesResolve = '$feesDuesBasePath/resolve/';
  static const String feesDuesSendReminder = '$feesDuesBasePath/send-reminder/';
  static const String feesDuesExportCsv = '$feesDuesBasePath/export-csv/';

  // Fees — Year-End screen (carry-forward resolution, PDF/CSV year-end
  // reports, next-year fee-amount staging for rollover).
  // Reference: frontend app/(dashboard)/fees/year-end/page.tsx.
  static const String feesYearEndBasePath = '$feesBasePath/year-end';
  static const String feesYearEndGroupAmounts = '$feesYearEndBasePath/group-amounts/';
  static const String feesYearEndReport = '$feesYearEndBasePath/report/';

  // Notifications — Reference: backend/apps/utilities/communication (NotificationViewSet),
  // matches frontend/components/nav/NotificationBell.tsx's endpoints exactly.
  static const String notificationsBasePath = '$apiBasePath/utilities/communication/notifications';
  static const String notifications = '$notificationsBasePath/';
  static const String notificationsMarkAllRead = '$notificationsBasePath/mark-all-read/';
  static String notificationMarkRead(int id) => '$notificationsBasePath/$id/mark-read/';

  // Dashboard Endpoints
  static const String attentionCountEndpoint =
      '/api/dashboard/attention-count/';
  // Real, confirmed backend endpoint (backend/apps/dashboard/views.py::DashboardKPIView,
  // registered in backend/config/urls.py) — school-scoped, field names match
  // KpiData.fromJson exactly (total_students, attendance_today, fees_collected_mtd,
  // open_admissions, total_staff, library_books, pending_homework, exams_this_week).
  static const String dashboardKpis = '$apiBasePath/dashboard/kpis/';
  // NOTE: Backend has NO /api/user/recents/ endpoint - use localStorage only

  // Sticky Notes Endpoints (backend/apps/notes/, mounted at the app root —
  // NOT under $apiBasePath, matching attentionCountEndpoint's precedent for
  // a non-versioned path).
  static const String notesBasePath = '/api/notes';
  static const String notes = '$notesBasePath/';
  static String noteDetail(int id) => '$notesBasePath/$id/';

  // Teacher Portal — backend/apps/teacher_portal/, mounted under $apiBasePath.
  static const String teacherBasePath = '$apiBasePath/teacher';
  static const String teacherMe = '$teacherBasePath/me/';

  // Teacher Portal — Timetable (Weekly View).
  static const String teacherTimetable = '$teacherBasePath/timetable/';

  // Teacher Portal — My Classes (Class Overview + Student Profile).
  static const String teacherClasses = '$teacherBasePath/my-classes/';
  static const String teacherStudents = '$teacherBasePath/students/';
  static String teacherStudentDetail(int id) => '$teacherStudents$id/';
  static String teacherStudentCredentials(int id) => '$teacherStudents$id/credentials/';
  static String teacherStudentResetPassword(int id) => '$teacherStudents$id/reset-password/';

  // Teacher Portal — Attendance. Reference: backend/apps/teacher_portal/urls.py
  // (TeacherAttendanceFetchView, TeacherAttendanceStoreView) — scoped to only
  // the class+section(s) the requesting teacher is assigned to; only the
  // class teacher of a section can actually save (view-only for a subject
  // teacher of that same section).
  static const String teacherAttendanceStudents = '$teacherBasePath/attendance/students/';
  static const String teacherAttendanceStore = '$teacherBasePath/attendance/store/';

  // Teacher Portal — My Profile. Reuses backend/apps/hr/views.py's
  // StaffViewSet.me() action (the same self-scoped endpoint web's
  // Settings > Staff Profile panel calls for any non-admin user) — not
  // teacherMe above, which is a distinct apps.teacher_portal endpoint.
  static const String hrStaffMe = '$apiBasePath/hr/staff/me/';

  // Smart To-Do — backend/apps/todos/, mounted at the app root like Notes
  // (bare array responses, no pagination envelope — same convention).
  static const String todosBasePath = '/api/user/todos';
  static const String todos = '$todosBasePath/';
  static String todoDetail(int id) => '$todosBasePath/$id/';

  // Quick Broadcast — backend/apps/communication/, mounted under
  // $apiBasePath/utilities/communication (same base as Notifications above).
  static const String broadcastBasePath = '$apiBasePath/utilities/communication/broadcast';
  static const String broadcastAudienceOptions = '$broadcastBasePath/audience-options/';
  static const String broadcastSend = '$broadcastBasePath/';

  // Parent Portal — backend/apps/parent_portal/, mounted under $apiBasePath.
  // Every endpoint is scoped server-side to request.user.guardian_profile —
  // no student id in these paths is trusted without that guardian check.
  static const String parentBasePath = '$apiBasePath/parent';
  static const String parentMe = '$parentBasePath/me/';
  static const String parentChildren = '$parentBasePath/children/';
  static String parentChildDetail(int childId) => '$parentChildren$childId/';
  static const String parentAttendance = '$parentBasePath/attendance/';
  static const String parentFees = '$parentBasePath/fees/';
  static const String parentNotices = '$parentBasePath/notices/';
}
