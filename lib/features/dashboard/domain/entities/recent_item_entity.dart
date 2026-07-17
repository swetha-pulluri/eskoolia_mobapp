import 'package:equatable/equatable.dart';

/// Recent Item Entity - represents a recently visited module
class RecentItemEntity extends Equatable {
  final String path;
  final DateTime visitedAt;

  const RecentItemEntity({
    required this.path,
    required this.visitedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'visited_at': visitedAt.toIso8601String(),
    };
  }

  factory RecentItemEntity.fromJson(Map<String, dynamic> json) {
    return RecentItemEntity(
      path: json['path'] as String,
      visitedAt: DateTime.parse(json['visited_at'] as String),
    );
  }

  @override
  List<Object?> get props => [path, visitedAt];
}
