import '../../domain/entities/attendance_calendar_entity.dart';
import '../../domain/entities/child_detail_entity.dart';
import '../../domain/entities/child_fees_entity.dart';
import '../../domain/entities/notice_item_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../../domain/repositories/parent_repository.dart';
import '../datasources/parent_remote_datasource.dart';

class ParentRepositoryImpl implements ParentRepository {
  final ParentRemoteDataSource _dataSource;

  ParentRepositoryImpl(this._dataSource);

  @override
  Future<ParentMeEntity> getMe() => _dataSource.getMe();

  @override
  Future<ChildDetailEntity> getChildDetail(int childId) => _dataSource.getChildDetail(childId);

  @override
  Future<ChildFeesEntity> getChildFees(int childId) => _dataSource.getChildFees(childId);

  @override
  Future<List<NoticeItemEntity>> getNotices() => _dataSource.getNotices();

  @override
  Future<AttendanceCalendarEntity> getAttendanceCalendar(int childId, String month) =>
      _dataSource.getAttendanceCalendar(childId, month);
}
