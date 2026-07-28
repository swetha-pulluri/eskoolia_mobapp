import '../models/due_interaction.dart';
import '../models/dues_class_group.dart';
import '../models/dues_summary.dart';

/// Seam over the Dues & Reminders screen's data needs. Reference:
/// frontend components/fees/FeesDuesRemindersPanel.tsx.
abstract class FeesDuesRepository {
  Future<List<DuesClassGroup>> fetchByClass({required int tier});

  Future<DuesSummary> fetchSummary();

  Future<List<DueInteraction>> fetchInteractions(String studentId);

  /// `interactionType` is always `"note"` from every call site in the
  /// source screen — not exposed as a parameter to keep callers honest.
  Future<DueInteraction> createInteraction({
    required String student,
    required String note,
    String? agreedAmount,
    String? agreedDate,
  });

  Future<DueInteraction> resolveDue(String studentId, {String? note});

  /// Returns the number of reminders actually sent (`sent` field of the
  /// backend response).
  Future<int> sendReminders(List<String> studentIds, String message);

  /// Raw CSV bytes — mobile has no browser download tray, so the caller
  /// writes these to a temp file and shares/reports the path, mirroring
  /// the established convention in student_export_page.dart.
  Future<List<int>> exportCsv();
}
