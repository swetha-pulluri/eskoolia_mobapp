import 'package:equatable/equatable.dart';

/// Pin Item Entity - represents a pinned module
class PinItemEntity extends Equatable {
  final String path;
  final String label;
  final String moduleId;

  const PinItemEntity({
    required this.path,
    required this.label,
    required this.moduleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'label': label,
      'modId': moduleId,
    };
  }

  factory PinItemEntity.fromJson(Map<String, dynamic> json) {
    return PinItemEntity(
      path: json['path'] as String,
      label: json['label'] as String,
      moduleId: json['modId'] as String,
    );
  }

  @override
  List<Object?> get props => [path, label, moduleId];
}

/// Default Pins - Exactly 4 default pins as shown in original eSkoolia dashboard
class DefaultPins {
  DefaultPins._();

  static final List<PinItemEntity> all = [
    const PinItemEntity(
      path: '/attendance/student',
      label: 'Student Attendance',
      moduleId: 'attendance',
    ),
    const PinItemEntity(
      path: '/students/list',
      label: 'Student Enroll & List',
      moduleId: 'students',
    ),
    const PinItemEntity(
      path: '/fees/payments',
      label: 'Fees Collection',
      moduleId: 'fees',
    ),
    const PinItemEntity(
      path: '/exams/marks-register',
      label: 'Marks Register',
      moduleId: 'exam',
    ),
  ];
}
