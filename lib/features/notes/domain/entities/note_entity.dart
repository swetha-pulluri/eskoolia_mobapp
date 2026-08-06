/// A sticky note, matching `backend/apps/notes/`'s `Note` model/serializer
/// exactly. `color` is a plain string (`yellow|pink|green|blue|purple`),
/// matching the backend's own `CharField(choices=...)`, rather than a Dart
/// enum — it's only ever looked up against a small display table anyway.
class NoteEntity {
  final int id;
  final String route;
  final String color;
  final String text;
  final int positionX;
  final int positionY;
  final int width;
  final int height;
  final bool pinned;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? authorInitials;

  const NoteEntity({
    required this.id,
    required this.route,
    required this.color,
    required this.text,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    required this.pinned,
    required this.archived,
    this.createdAt,
    this.updatedAt,
    this.authorInitials,
  });

  factory NoteEntity.fromJson(Map<String, dynamic> json) => NoteEntity(
        id: json['id'] as int,
        route: json['route'] as String? ?? '',
        color: json['color'] as String? ?? 'yellow',
        text: json['text'] as String? ?? '',
        positionX: json['position_x'] as int? ?? 80,
        positionY: json['position_y'] as int? ?? 120,
        width: json['width'] as int? ?? 240,
        height: json['height'] as int? ?? 160,
        pinned: json['pinned'] as bool? ?? false,
        archived: json['archived'] as bool? ?? false,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
        authorInitials: json['author_initials'] as String?,
      );

  NoteEntity copyWith({String? text, bool? pinned, bool? archived}) => NoteEntity(
        id: id,
        route: route,
        color: color,
        text: text ?? this.text,
        positionX: positionX,
        positionY: positionY,
        width: width,
        height: height,
        pinned: pinned ?? this.pinned,
        archived: archived ?? this.archived,
        createdAt: createdAt,
        updatedAt: updatedAt,
        authorInitials: authorInitials,
      );
}
