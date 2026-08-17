/// Mirrors web's `frontend/lib/reports-config.ts` exactly — the generic
/// "Report Explorer" engine's catalog of 29 report definitions (the ones
/// with a "/"-segmented key; the 5 legacy single-segment aliases like
/// `student`/`exam`/`staff`/`fees`/`accounts` duplicate one of these and
/// aren't shown on the Hub, matching `getGroupedReportDefinitions()`).
///
/// Two corrections vs. the web frontend's own (verified-wrong) assumptions,
/// made against the real Django backend (`apps/reports/`, `apps/exams/`)
/// rather than copying web's bugs:
///  - The "Exam" filter (`exam_term_id`) is a FK to the `ExamType` model
///    (`GET /api/v1/exams/types/`, field `title`) — NOT `Exam`
///    (`/api/v1/exams/exams/`), which web's own filter source incorrectly
///    assumes. `ExamMarkRegister.exam_term` confirms this.
///  - Vehicles cannot be filtered by Route server-side (`VehicleViewSet`
///    has no such filter) — so `vehicle_id` has no `dependsOn` here, unlike
///    web's config which assumes a route→vehicle cascade that doesn't work.
enum ReportFieldType { text, date, select }

enum LookupSource { classes, sections, students, subjects, examTypes, departments, designations, staff, routes, vehicles, books, categories, suppliers, incidents }

class ReportFilterFieldDef {
  final String key;
  final String label;
  final ReportFieldType type;
  final String? placeholder;
  final List<(String, String)>? staticOptions; // (value, label) — '' value means "All"
  final LookupSource? lookupSource;
  final List<String>? dependsOn;

  const ReportFilterFieldDef({
    required this.key,
    required this.label,
    required this.type,
    this.placeholder,
    this.staticOptions,
    this.lookupSource,
    this.dependsOn,
  });
}

class ReportDefinitionEntity {
  final String key; // "{module}/{report}" — matches the Hub's card link exactly
  final String title;
  final String endpoint;
  final List<ReportFilterFieldDef> filterFields;

  const ReportDefinitionEntity({required this.key, required this.title, required this.endpoint, required this.filterFields});
}

const _kDefaultFilters = [
  ReportFilterFieldDef(key: 'keyword', label: 'Keyword', type: ReportFieldType.text, placeholder: 'Search'),
  ReportFilterFieldDef(key: 'start_date', label: 'Start Date', type: ReportFieldType.date),
  ReportFilterFieldDef(key: 'end_date', label: 'End Date', type: ReportFieldType.date),
];

const _kClassSectionStudentFilters = [
  ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
  ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
  ReportFilterFieldDef(key: 'student_id', label: 'Student', type: ReportFieldType.select, lookupSource: LookupSource.students, dependsOn: ['class_id', 'section_id']),
  ..._kDefaultFilters,
];

const _kExamScopeFilters = [
  ReportFilterFieldDef(key: 'exam_term_id', label: 'Exam', type: ReportFieldType.select, lookupSource: LookupSource.examTypes),
  ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
  ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
  ReportFilterFieldDef(key: 'student_id', label: 'Student', type: ReportFieldType.select, lookupSource: LookupSource.students, dependsOn: ['class_id', 'section_id']),
  ReportFilterFieldDef(key: 'subject_id', label: 'Subject', type: ReportFieldType.select, lookupSource: LookupSource.subjects),
  ..._kDefaultFilters,
];

const _kAttendanceTypeStatic = [('', 'All'), ('present', 'Present'), ('absent', 'Absent'), ('late', 'Late'), ('half_day', 'Half Day')];

const _kStaffFilters = [
  ReportFilterFieldDef(key: 'department_id', label: 'Department', type: ReportFieldType.select, lookupSource: LookupSource.departments),
  ReportFilterFieldDef(key: 'designation_id', label: 'Designation', type: ReportFieldType.select, lookupSource: LookupSource.designations, dependsOn: ['department_id']),
  ReportFilterFieldDef(key: 'staff_id', label: 'Staff', type: ReportFieldType.select, lookupSource: LookupSource.staff, dependsOn: ['department_id', 'designation_id']),
  ReportFilterFieldDef(key: 'attendance_type', label: 'Attendance Type', type: ReportFieldType.select, staticOptions: _kAttendanceTypeStatic),
  ..._kDefaultFilters,
];

const _kTransportFilters = [
  ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
  ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
  ReportFilterFieldDef(key: 'route_id', label: 'Route', type: ReportFieldType.select, lookupSource: LookupSource.routes),
  ReportFilterFieldDef(key: 'vehicle_id', label: 'Vehicle', type: ReportFieldType.select, lookupSource: LookupSource.vehicles),
  ..._kDefaultFilters,
];

/// The 29 Hub-linked report definitions — key/title/endpoint/filter set
/// match `reports-config.ts`'s `REPORTS` map verbatim (module/report
/// grouping, order within each group) for every entry with a "/"-segmented
/// key.
const kReportDefinitions = <String, ReportDefinitionEntity>{
  'students/student-report': ReportDefinitionEntity(key: 'students/student-report', title: 'Student Report', endpoint: '/api/v1/reports/students/student-report/', filterFields: _kClassSectionStudentFilters),
  'students/guardian-report': ReportDefinitionEntity(key: 'students/guardian-report', title: 'Guardian Report', endpoint: '/api/v1/reports/students/guardian-report/', filterFields: _kClassSectionStudentFilters),
  'students/list': ReportDefinitionEntity(key: 'students/list', title: 'Students List', endpoint: '/api/v1/reports/students/list/', filterFields: _kClassSectionStudentFilters),
  'students/attendance': ReportDefinitionEntity(
    key: 'students/attendance',
    title: 'Student Attendance',
    endpoint: '/api/v1/reports/students/attendance/',
    filterFields: [
      ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
      ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
      ReportFilterFieldDef(key: 'student_id', label: 'Student', type: ReportFieldType.select, lookupSource: LookupSource.students, dependsOn: ['class_id', 'section_id']),
      const ReportFilterFieldDef(key: 'attendance_type', label: 'Attendance Type', type: ReportFieldType.select, staticOptions: _kAttendanceTypeStatic),
      ..._kDefaultFilters,
    ],
  ),
  'fees/balance-fees-report': ReportDefinitionEntity(key: 'fees/balance-fees-report', title: 'Balance Fees Report', endpoint: '/api/v1/reports/fees/balance-fees-report/', filterFields: _kClassSectionStudentFilters),
  'fees/collection-report': ReportDefinitionEntity(key: 'fees/collection-report', title: 'Collection Report', endpoint: '/api/v1/reports/fees/collection-report/', filterFields: _kClassSectionStudentFilters),
  'fees/student-fine-report': ReportDefinitionEntity(key: 'fees/student-fine-report', title: 'Student Fine Report', endpoint: '/api/v1/reports/fees/student-fine-report/', filterFields: _kClassSectionStudentFilters),
  'academics/class-report': ReportDefinitionEntity(
    key: 'academics/class-report',
    title: 'Class Report',
    endpoint: '/api/v1/reports/academics/class-report/',
    filterFields: [
      ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
      ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
      const ReportFilterFieldDef(key: 'exam_term_id', label: 'Exam', type: ReportFieldType.select, lookupSource: LookupSource.examTypes),
      const ReportFilterFieldDef(key: 'subject_id', label: 'Subject', type: ReportFieldType.select, lookupSource: LookupSource.subjects),
      ..._kDefaultFilters,
    ],
  ),
  'academics/class-routine-report': ReportDefinitionEntity(
    key: 'academics/class-routine-report',
    title: 'Class Routine Report',
    endpoint: '/api/v1/reports/academics/class-routine-report/',
    filterFields: [
      ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
      ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
      const ReportFilterFieldDef(key: 'exam_term_id', label: 'Exam', type: ReportFieldType.select, lookupSource: LookupSource.examTypes),
      ..._kDefaultFilters,
    ],
  ),
  'examination/exam-routine-report': ReportDefinitionEntity(key: 'examination/exam-routine-report', title: 'Exam Routine Report', endpoint: '/api/v1/reports/examination/exam-routine-report/', filterFields: _kExamScopeFilters),
  'examination/teacher-class-routine-report': ReportDefinitionEntity(key: 'examination/teacher-class-routine-report', title: 'Teacher Class Routine Report', endpoint: '/api/v1/reports/examination/teacher-class-routine-report/', filterFields: _kExamScopeFilters),
  'examination/merit-list-report': ReportDefinitionEntity(key: 'examination/merit-list-report', title: 'Merit List Report', endpoint: '/api/v1/reports/examination/merit-list-report/', filterFields: _kExamScopeFilters),
  'examination/online-exam-report': ReportDefinitionEntity(key: 'examination/online-exam-report', title: 'Online Exam Report', endpoint: '/api/v1/reports/examination/online-exam-report/', filterFields: _kExamScopeFilters),
  'examination/mark-sheet-report-student': ReportDefinitionEntity(key: 'examination/mark-sheet-report-student', title: 'Mark Sheet Report Student', endpoint: '/api/v1/reports/examination/mark-sheet-report-student/', filterFields: _kExamScopeFilters),
  'examination/tabulation-sheet-report': ReportDefinitionEntity(key: 'examination/tabulation-sheet-report', title: 'Tabulation Sheet Report', endpoint: '/api/v1/reports/examination/tabulation-sheet-report/', filterFields: _kExamScopeFilters),
  'examination/progress-card-report': ReportDefinitionEntity(key: 'examination/progress-card-report', title: 'Progress Card Report', endpoint: '/api/v1/reports/examination/progress-card-report/', filterFields: _kExamScopeFilters),
  'examination/marks': ReportDefinitionEntity(key: 'examination/marks', title: 'Examination Marks', endpoint: '/api/v1/reports/examination/marks/', filterFields: _kExamScopeFilters),
  'examination/result-summary': ReportDefinitionEntity(key: 'examination/result-summary', title: 'Exam Result Summary', endpoint: '/api/v1/reports/examination/result-summary/', filterFields: _kExamScopeFilters),
  'accounts/payroll-report': ReportDefinitionEntity(key: 'accounts/payroll-report', title: 'Payroll Report', endpoint: '/api/v1/reports/accounts/payroll-report/', filterFields: _kStaffFilters),
  'hr/staff-attendance': ReportDefinitionEntity(key: 'hr/staff-attendance', title: 'HR Staff Attendance', endpoint: '/api/v1/reports/hr/staff-attendance/', filterFields: _kStaffFilters),
  'accounts/fee-collection': ReportDefinitionEntity(key: 'accounts/fee-collection', title: 'Accounts Fee Collection', endpoint: '/api/v1/reports/accounts/fee-collection/', filterFields: _kClassSectionStudentFilters),
  'accounts/expense': const ReportDefinitionEntity(key: 'accounts/expense', title: 'Accounts Expense', endpoint: '/api/v1/reports/accounts/expense/', filterFields: _kDefaultFilters),
  'dormitory/student-dormitory-report': ReportDefinitionEntity(key: 'dormitory/student-dormitory-report', title: 'Student Dormitory Report', endpoint: '/api/v1/reports/dormitory/student-dormitory-report/', filterFields: _kClassSectionStudentFilters),
  'transport/student-transport-report': ReportDefinitionEntity(key: 'transport/student-transport-report', title: 'Student Transport Report', endpoint: '/api/v1/reports/transport/student-transport-report/', filterFields: _kTransportFilters),
  'transport/student': ReportDefinitionEntity(key: 'transport/student', title: 'Transport Student', endpoint: '/api/v1/reports/transport/student/', filterFields: _kTransportFilters),
  'library/issue-return': ReportDefinitionEntity(
    key: 'library/issue-return',
    title: 'Library Issue Return',
    endpoint: '/api/v1/reports/library/issue-return/',
    filterFields: [
      const ReportFilterFieldDef(key: 'book_id', label: 'Book', type: ReportFieldType.select, lookupSource: LookupSource.books),
      const ReportFilterFieldDef(key: 'status', label: 'Status', type: ReportFieldType.select, staticOptions: [('', 'All'), ('issued', 'Issued'), ('returned', 'Returned'), ('lost', 'Lost')]),
      const ReportFilterFieldDef(key: 'member_type', label: 'Member Type', type: ReportFieldType.select, staticOptions: [('', 'All'), ('student', 'Student'), ('staff', 'Staff')]),
      ..._kDefaultFilters,
    ],
  ),
  'academic/class-performance': ReportDefinitionEntity(
    key: 'academic/class-performance',
    title: 'Academic Class Performance',
    endpoint: '/api/v1/reports/academic/class-performance/',
    filterFields: [
      const ReportFilterFieldDef(key: 'exam_term_id', label: 'Exam', type: ReportFieldType.select, lookupSource: LookupSource.examTypes),
      ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
      ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
      const ReportFilterFieldDef(key: 'subject_id', label: 'Subject', type: ReportFieldType.select, lookupSource: LookupSource.subjects),
      ..._kDefaultFilters,
    ],
  ),
  'inventory/stock': ReportDefinitionEntity(
    key: 'inventory/stock',
    title: 'Inventory Stock',
    endpoint: '/api/v1/reports/inventory/stock/',
    filterFields: [
      const ReportFilterFieldDef(key: 'category_id', label: 'Category', type: ReportFieldType.select, lookupSource: LookupSource.categories),
      const ReportFilterFieldDef(key: 'supplier_id', label: 'Supplier', type: ReportFieldType.select, lookupSource: LookupSource.suppliers),
      const ReportFilterFieldDef(key: 'low_stock_only', label: 'Low Stock Only', type: ReportFieldType.select, staticOptions: [('', 'All'), ('true', 'Yes'), ('false', 'No')]),
      ..._kDefaultFilters,
    ],
  ),
  'behaviour/incidents': ReportDefinitionEntity(
    key: 'behaviour/incidents',
    title: 'Behaviour Incidents',
    endpoint: '/api/v1/reports/behaviour/incidents/',
    filterFields: [
      const ReportFilterFieldDef(key: 'incident_id', label: 'Incident', type: ReportFieldType.select, lookupSource: LookupSource.incidents),
      ReportFilterFieldDef(key: 'class_id', label: 'Class', type: ReportFieldType.select, lookupSource: LookupSource.classes),
      ReportFilterFieldDef(key: 'section_id', label: 'Section', type: ReportFieldType.select, lookupSource: LookupSource.sections, dependsOn: ['class_id']),
      ReportFilterFieldDef(key: 'student_id', label: 'Student', type: ReportFieldType.select, lookupSource: LookupSource.students, dependsOn: ['class_id', 'section_id']),
      ..._kDefaultFilters,
    ],
  ),
};
