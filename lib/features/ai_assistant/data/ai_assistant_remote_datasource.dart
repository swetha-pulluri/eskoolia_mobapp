import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

/// Result of a successful chatbot-mark call — mirrors
/// frontend/components/aibot/AbsenceFlow.tsx's `AbsenceResult`.
class AiAbsenceMarkResult {
  final int studentId;
  final String studentName;
  final String className;
  final String sectionName;
  final String date;
  final String notes;

  const AiAbsenceMarkResult({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.sectionName,
    required this.date,
    required this.notes,
  });

  factory AiAbsenceMarkResult.fromJson(Map<String, dynamic> json) {
    return AiAbsenceMarkResult(
      studentId: json['student_id'] as int,
      studentName: (json['student_name'] as String?) ?? '',
      className: (json['class_name'] as String?) ?? '',
      sectionName: (json['section_name'] as String?) ?? '',
      date: (json['attendance_date'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

/// Thrown when the backend rejects the mark (surfaces its own `detail`
/// message, matching AbsenceFlow.tsx's own `err.detail` extraction).
class AiAbsenceMarkException implements Exception {
  final String message;
  const AiAbsenceMarkException(this.message);
  @override
  String toString() => message;
}

/// The AI Assistant's own narrowly-scoped remote calls — kept separate from
/// the main Attendance feature's repository since `chatbot-mark/` is a
/// distinct action route the assistant alone uses.
class AiAssistantRemoteDataSource {
  final Dio _dio;
  AiAssistantRemoteDataSource(this._dio);

  Future<AiAbsenceMarkResult> markAbsence({
    required int studentId,
    required String notes,
    required String attendanceDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.studentAttendanceChatbotMark,
        data: {
          'student_id': studentId,
          'attendance_type': 'A',
          'notes': notes,
          'attendance_date': attendanceDate,
        },
      );
      return AiAbsenceMarkResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] as String? : null;
      throw AiAbsenceMarkException(detail ?? 'Failed to mark attendance. Please try again.');
    }
  }
}
