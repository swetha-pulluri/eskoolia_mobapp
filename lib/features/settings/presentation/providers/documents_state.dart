import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/policy_document_entity.dart';

const Object _unset = Object();

/// Combines every `useState` hook from `DocumentsPanel.tsx` (list + filter +
/// wizard + history) into one immutable state object for a single
/// `StateNotifier` — same pattern as every other Settings sub-feature.
class DocumentsState {
  final List<PolicyDocumentEntity> documents;
  final String? categoryFilter;
  final bool loading;
  final String? error;
  final String? success;
  final int? busyId;
  final int? viewingId;

  final bool wizardOpen;
  final int step;
  final int? editingId;
  final Map<String, dynamic> draft;
  final PickedAttachment? pickedFile;
  final bool saving;

  final int? historyOpenId;
  final List<DocumentAuditEntry> history;
  final bool historyLoading;

  const DocumentsState({
    this.documents = const [],
    this.categoryFilter,
    this.loading = true,
    this.error,
    this.success,
    this.busyId,
    this.viewingId,
    this.wizardOpen = false,
    this.step = 0,
    this.editingId,
    this.draft = const {},
    this.pickedFile,
    this.saving = false,
    this.historyOpenId,
    this.history = const [],
    this.historyLoading = false,
  });

  bool get isEditing => editingId != null;

  DocumentsState copyWith({
    List<PolicyDocumentEntity>? documents,
    Object? categoryFilter = _unset,
    bool? loading,
    Object? error = _unset,
    Object? success = _unset,
    Object? busyId = _unset,
    Object? viewingId = _unset,
    bool? wizardOpen,
    int? step,
    Object? editingId = _unset,
    Map<String, dynamic>? draft,
    Object? pickedFile = _unset,
    bool? saving,
    Object? historyOpenId = _unset,
    List<DocumentAuditEntry>? history,
    bool? historyLoading,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      categoryFilter: categoryFilter == _unset ? this.categoryFilter : categoryFilter as String?,
      loading: loading ?? this.loading,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
      busyId: busyId == _unset ? this.busyId : busyId as int?,
      viewingId: viewingId == _unset ? this.viewingId : viewingId as int?,
      wizardOpen: wizardOpen ?? this.wizardOpen,
      step: step ?? this.step,
      editingId: editingId == _unset ? this.editingId : editingId as int?,
      draft: draft ?? this.draft,
      pickedFile: pickedFile == _unset ? this.pickedFile : pickedFile as PickedAttachment?,
      saving: saving ?? this.saving,
      historyOpenId: historyOpenId == _unset ? this.historyOpenId : historyOpenId as int?,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
    );
  }
}

/// Mirrors the web's `startCreate` reset (`title:"", category:"other"`).
Map<String, dynamic> buildDocumentWizardDefaults() {
  return {'title': '', 'category': 'other'};
}
