import '../entities/attendance_calendar_entity.dart';
import '../entities/child_detail_entity.dart';
import '../entities/child_fees_entity.dart';
import '../entities/notice_item_entity.dart';
import '../entities/parent_me_entity.dart';

abstract class ParentRepository {
  Future<ParentMeEntity> getMe();
  Future<ChildDetailEntity> getChildDetail(int childId);
  Future<ChildFeesEntity> getChildFees(int childId);
  Future<List<NoticeItemEntity>> getNotices();
  /// [month] is `YYYY-MM`, matching the backend's expected query format.
  Future<AttendanceCalendarEntity> getAttendanceCalendar(int childId, String month);
}
