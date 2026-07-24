/// Room — Source: components/academics/foundation/panes/RoomsPane.tsx.
/// Backend: apps/core — ClassRoom model/ClassRoomSerializer,
/// GET/POST/PATCH/DELETE /api/v1/core/class-rooms/.
class FoundationRoom {
  final int id;
  final String roomNo;
  final String floor;
  final int capacity;
  final int? sectionId;
  final String sectionLabel;
  final bool activeStatus;

  const FoundationRoom({
    required this.id,
    required this.roomNo,
    this.floor = '',
    required this.capacity,
    this.sectionId,
    this.sectionLabel = '',
    this.activeStatus = true,
  });

  factory FoundationRoom.fromJson(Map<String, dynamic> json) {
    return FoundationRoom(
      id: json['id'] as int,
      roomNo: (json['room_no'] as String?) ?? '',
      floor: (json['floor'] as String?) ?? '',
      capacity: json['capacity'] as int? ?? 35,
      sectionId: json['section'] as int?,
      sectionLabel: (json['section_label'] as String?) ?? '',
      activeStatus: json['active_status'] as bool? ?? true,
    );
  }
}
