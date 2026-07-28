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

  // School Info Endpoint (public - no auth required)
  static const String schoolInfo = '$apiBasePath/tenancy/school-info/';

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
  // Authenticated variant of `schoolInfo` above — distinct endpoint used only
  // by the Collection screen's receipt/ledger header (schoolInfo is public,
  // no-auth; this one requires a logged-in session).
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

  // Dashboard Endpoints
  static const String attentionCountEndpoint =
      '/api/dashboard/attention-count/';
  // Real, confirmed backend endpoint (backend/apps/dashboard/views.py::DashboardKPIView,
  // registered in backend/config/urls.py) — school-scoped, field names match
  // KpiData.fromJson exactly (total_students, attendance_today, fees_collected_mtd,
  // open_admissions, total_staff, library_books, pending_homework, exams_this_week).
  static const String dashboardKpis = '$apiBasePath/dashboard/kpis/';
  // NOTE: Backend has NO /api/user/recents/ endpoint - use localStorage only
}
