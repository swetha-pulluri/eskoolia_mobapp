import '../../../student/domain/models/academic_year.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/holiday_entity.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/staff_assignment_entities.dart';
import '../../domain/entities/subject_entry.dart';
import '../../domain/repositories/academics_repository.dart';
import '../datasources/academics_remote_datasource.dart';

class AcademicsRepositoryImpl implements AcademicsRepository {
  final AcademicsRemoteDataSource _remote;
  AcademicsRepositoryImpl(this._remote);

  @override
  Future<List<AcademicYear>> fetchAcademicYears() => _remote.fetchAcademicYears();

  @override
  Future<AcademicYear> createAcademicYear({
    String? board,
    String? numberOfTerms,
    required String startDate,
    required String endDate,
    required bool isCurrent,
    required bool isActive,
  }) {
    return _remote.createAcademicYear({
      'board': ?board,
      'number_of_terms': ?numberOfTerms,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'is_active': isActive,
    });
  }

  @override
  Future<AcademicYear> updateAcademicYear(
    int id, {
    String? board,
    String? numberOfTerms,
    required String startDate,
    required String endDate,
    required bool isCurrent,
    required bool isActive,
  }) {
    return _remote.updateAcademicYear(id, {
      'board': ?board,
      'number_of_terms': ?numberOfTerms,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'is_active': isActive,
    });
  }

  @override
  Future<void> deleteAcademicYear(int id) => _remote.deleteAcademicYear(id);

  @override
  Future<List<Holiday>> fetchHolidays({int? academicYearId}) => _remote.fetchHolidays(academicYearId: academicYearId);

  @override
  Future<void> createHoliday({
    required String name,
    required String date,
    String? endDate,
    required String holidayType,
    String description = '',
    int? academicYearId,
  }) {
    return _remote.createHoliday({
      'name': name,
      'date': date,
      'end_date': endDate,
      'holiday_type': holidayType,
      'description': description,
      'academic_year': ?academicYearId,
    });
  }

  @override
  Future<void> updateHoliday(
    int id, {
    required String name,
    required String date,
    String? endDate,
    required String holidayType,
    String description = '',
    int? academicYearId,
  }) {
    return _remote.updateHoliday(id, {
      'name': name,
      'date': date,
      'end_date': endDate,
      'holiday_type': holidayType,
      'description': description,
      'academic_year': ?academicYearId,
    });
  }

  @override
  Future<void> deleteHoliday(int id) => _remote.deleteHoliday(id);

  @override
  Future<({int created, int skipped})> copyHolidaysFromYear({
    required int sourceYearId,
    required int targetYearId,
    required bool shiftYear,
  }) {
    return _remote.copyHolidaysFromYear({
      'source_academic_year': sourceYearId,
      'target_academic_year': targetYearId,
      'shift_year': shiftYear,
    });
  }

  @override
  Future<List<FoundationClass>> fetchClasses() => _remote.fetchClasses();

  @override
  Future<void> createClass({required String name, int? capacity, List<({int streamId, int capacity})>? streamCapacities}) {
    return _remote.createClass({
      'name': name,
      'capacity': ?capacity,
      if (streamCapacities != null) 'stream_capacities': streamCapacities.map((s) => {'stream': s.streamId, 'capacity': s.capacity}).toList(),
    });
  }

  @override
  Future<void> updateClass(int id, {required String name, List<({int streamId, int capacity})>? streamCapacities}) {
    return _remote.updateClass(id, {
      'name': name,
      if (streamCapacities != null) 'stream_capacities': streamCapacities.map((s) => {'stream': s.streamId, 'capacity': s.capacity}).toList(),
    });
  }

  @override
  Future<void> deleteClass(int id) => _remote.deleteClass(id);

  @override
  Future<void> toggleClassActive(int id, bool isActive) => _remote.toggleClassActive(id, isActive);

  @override
  Future<List<StreamDetail>> fetchStreams() => _remote.fetchStreams();

  @override
  Future<StreamDetail> createStream(String name) => _remote.createStream(name);

  @override
  Future<({int created, int deleted})> replaceSections({
    required List<int> classIds,
    required List<String> oldNames,
    required List<String> newNames,
    required int capacity,
  }) {
    return _remote.replaceSections({
      'class_ids': classIds,
      'old_names': oldNames,
      'new_names': newNames,
      'capacity': capacity,
    });
  }

  @override
  Future<void> renameSection(int id, String name) => _remote.renameSection(id, name);

  @override
  Future<void> deleteSection(int id) => _remote.deleteSection(id);

  @override
  Future<int> bulkDeleteSections(List<int> ids) => _remote.bulkDeleteSections(ids);

  @override
  Future<List<ClassSubjectEntry>> fetchClassSubjectEntries() => _remote.fetchClassSubjectEntries();

  @override
  Future<List<String>> fetchGlobalSubjectNames() => _remote.fetchGlobalSubjectNames();

  @override
  Future<({int created, int skipped, List<ClassSubjectEntry> data, List<({int classId, String message})> errors})> createSubjectEntry({
    required List<int> classIds,
    required String name,
    required String code,
    required String subjectType,
    int? periodsPerWeek,
  }) async {
    final res = await _remote.createSubjectEntry({
      'class_ids': classIds,
      'name': name,
      'code': code,
      'subject_type': subjectType,
      'periods_per_week': ?periodsPerWeek,
    });
    final data = ((res['data'] as List<dynamic>?) ?? const []).map((e) => ClassSubjectEntry.fromJson(e as Map<String, dynamic>)).toList();
    final errors = ((res['errors'] as List<dynamic>?) ?? const [])
        .map((e) => (classId: (e as Map<String, dynamic>)['class_id'] as int? ?? 0, message: (e['message'] as String?) ?? ''))
        .toList();
    return (created: res['created'] as int? ?? 0, skipped: res['skipped'] as int? ?? 0, data: data, errors: errors);
  }

  @override
  Future<ClassSubjectEntry> updateSubjectEntry(int id, {required String name, required String code, required String subjectType, required int periodsPerWeek}) {
    return _remote.updateSubjectEntry(id, {'name': name, 'code': code, 'subject_type': subjectType, 'periods_per_week': periodsPerWeek});
  }

  @override
  Future<ClassSubjectEntry> toggleSubjectEntryActive(int id, bool activeStatus) {
    return _remote.updateSubjectEntry(id, {'active_status': activeStatus});
  }

  @override
  Future<void> deleteSubjectEntry(int id) => _remote.deleteSubjectEntry(id);

  @override
  Future<void> resetClassSubjects(int classId) => _remote.resetClassSubjects(classId);

  @override
  Future<List<FoundationRoom>> fetchRooms() => _remote.fetchRooms();

  @override
  Future<void> createRoom({required String roomNo, String floor = '', required int capacity, int? sectionId}) {
    return _remote.createRoom({'room_no': roomNo, 'floor': floor, 'capacity': capacity, 'section': sectionId});
  }

  @override
  Future<void> updateRoom(int id, {required String roomNo, String floor = '', required int capacity, int? sectionId}) {
    return _remote.updateRoom(id, {'room_no': roomNo, 'floor': floor, 'capacity': capacity, 'section': sectionId});
  }

  @override
  Future<void> toggleRoomActive(int id, bool activeStatus) => _remote.updateRoom(id, {'active_status': activeStatus});

  @override
  Future<void> deleteRoom(int id) => _remote.deleteRoom(id);

  // ── Staff Assignment ─────────────────────────────────────────────────
  @override
  Future<List<StaffTeacher>> fetchStaffTeachers() => _remote.fetchStaffTeachers();

  @override
  Future<List<CTAssignment>> fetchClassTeacherAssignments({int? academicYearId}) =>
      _remote.fetchClassTeacherAssignments(academicYearId: academicYearId);

  @override
  Future<({bool success, String message, int? id})> assignClassTeacher({
    required int sectionId,
    required int teacherId,
    required int classId,
    required int academicYearId,
  }) async {
    final res = await _remote.createClassTeacherAssignment({
      'section_id': sectionId,
      'teacher_id': teacherId,
      'class_id': classId,
      'academic_year_id': academicYearId,
    });
    final data = res['data'] as Map<String, dynamic>?;
    return (success: res['success'] as bool? ?? false, message: (res['message'] as String?) ?? '', id: data?['id'] as int?);
  }

  @override
  Future<void> lockClassTeacher(int ctId) => _remote.lockClassTeacher(ctId);

  @override
  Future<({bool success, String message})> unlockClassTeacher({
    required int ctId,
    int? newTeacherId,
    required String reason,
  }) async {
    final res = await _remote.unlockClassTeacher(ctId, {
      'new_teacher_id': ?newTeacherId,
      'reason': reason,
    });
    return (success: res['success'] as bool? ?? false, message: (res['message'] as String?) ?? '');
  }

  @override
  Future<List<StaffSubjectRow>> fetchStaffSubjectRows({int? academicYearId, int? classId, int? sectionId}) =>
      _remote.fetchStaffSubjectRows(academicYearId: academicYearId, classId: classId, sectionId: sectionId);

  @override
  Future<({bool success, String message})> assignSubjectTeacher({required int rowId, required int teacherId}) async {
    final res = await _remote.updateSubjectAssignmentTeacher(rowId, {'teacher_id': teacherId});
    return (success: res['success'] as bool? ?? false, message: (res['message'] as String?) ?? '');
  }

  @override
  Future<StaffKpi> fetchStaffKpi({int? academicYearId}) => _remote.fetchStaffKpi(academicYearId: academicYearId);

  @override
  Future<List<StaffWorkloadEntry>> fetchStaffWorkload({int? academicYearId}) => _remote.fetchStaffWorkload(academicYearId: academicYearId);

  @override
  Future<List<StaffAuditLogEntry>> fetchStaffAuditLog() => _remote.fetchStaffAuditLog();
}
