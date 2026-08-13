import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../administration/domain/entities/picked_attachment.dart';
import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/documents_remote_datasource.dart';
import '../../data/repositories/documents_repository_impl.dart';
import '../../domain/entities/policy_document_entity.dart';
import '../../domain/repositories/documents_repository.dart';
import 'documents_state.dart';

final documentsRemoteDataSourceProvider = Provider<DocumentsRemoteDataSource>((ref) {
  return DocumentsRemoteDataSource(ref.watch(dioClientProvider));
});

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepositoryImpl(ref.watch(documentsRemoteDataSourceProvider));
});

final documentsNotifierProvider =
    StateNotifierProvider.autoDispose<DocumentsNotifier, DocumentsState>((ref) {
  return DocumentsNotifier(ref.watch(documentsRepositoryProvider));
});

/// Drives the document list + filter + 2/3-step wizard — a 1:1 port of
/// every function in `DocumentsPanel.tsx`.
class DocumentsNotifier extends StateNotifier<DocumentsState> {
  final DocumentsRepository _repository;

  DocumentsNotifier(this._repository) : super(const DocumentsState()) {
    load();
  }

  Future<void> load([String? category]) async {
    final effectiveCategory = category ?? state.categoryFilter;
    state = state.copyWith(loading: true, error: null, categoryFilter: effectiveCategory);
    try {
      final documents = await _repository.getDocuments(category: effectiveCategory);
      state = state.copyWith(loading: false, documents: documents);
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  void setCategoryFilter(String? category) => load(category);

  void startCreate() {
    state = state.copyWith(
      editingId: null,
      draft: buildDocumentWizardDefaults(),
      pickedFile: null,
      step: 0,
      wizardOpen: true,
    );
  }

  void startEdit(PolicyDocumentEntity doc) {
    state = state.copyWith(
      editingId: doc.id,
      draft: {'title': doc.title, 'category': doc.category, 'file_name': doc.fileName},
      pickedFile: null,
      step: 0,
      wizardOpen: true,
    );
  }

  void closeWizard() {
    state = state.copyWith(wizardOpen: false, editingId: null, pickedFile: null);
  }

  void setStep(int step) => state = state.copyWith(step: step);

  void setDraftField(String key, dynamic value) {
    state = state.copyWith(draft: {...state.draft, key: value});
  }

  void setPickedFile(PickedAttachment? file) => state = state.copyWith(pickedFile: file);

  Future<void> submit() async {
    final title = ((state.draft['title'] as String?) ?? '').trim();
    if (title.isEmpty) {
      state = state.copyWith(error: 'Title is required.');
      return;
    }
    final editingId = state.editingId;
    if (editingId == null && state.pickedFile == null) {
      state = state.copyWith(error: 'A file is required.');
      return;
    }

    state = state.copyWith(saving: true, error: null, success: null);
    try {
      final category = (state.draft['category'] as String?) ?? 'other';
      if (editingId != null) {
        final updated = await _repository.updateDocument(editingId, title: title, category: category);
        state = state.copyWith(
          saving: false,
          documents: [for (final d in state.documents) if (d.id == editingId) updated else d],
          success: 'Document updated.',
          wizardOpen: false,
          editingId: null,
        );
      } else {
        final created = await _repository.createDocument(title: title, category: category, file: state.pickedFile!);
        state = state.copyWith(
          saving: false,
          documents: [created, ...state.documents],
          success: 'Document uploaded.',
          wizardOpen: false,
          pickedFile: null,
        );
      }
    } catch (e) {
      state = state.copyWith(saving: false, error: adminErrorMessage(e));
      rethrow;
    }
  }

  Future<bool> delete(PolicyDocumentEntity doc) async {
    state = state.copyWith(busyId: doc.id, error: null);
    try {
      await _repository.deleteDocument(doc.id);
      state = state.copyWith(busyId: null, documents: state.documents.where((d) => d.id != doc.id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(busyId: null, error: adminErrorMessage(e));
      return false;
    }
  }

  /// The mobile equivalent of the web's "fetch as blob (authenticated) then
  /// open in a new tab" — `doc.file` is served by the authenticated media
  /// proxy, so it's fetched via the same bearer-token'd Dio client rather
  /// than opened as a bare link, then handed to the OS share/open sheet
  /// (same "practical mobile equivalent of a browser download" pattern
  /// already used for CSV exports elsewhere in this app).
  Future<void> viewDocument(PolicyDocumentEntity doc) async {
    state = state.copyWith(viewingId: doc.id, error: null);
    try {
      final bytes = await _repository.downloadFile(doc.file);
      await Share.shareXFiles([
        XFile.fromData(Uint8List.fromList(bytes), name: doc.fileName, mimeType: policyDocumentMimeType(doc.fileType)),
      ]);
      state = state.copyWith(viewingId: null);
    } catch (e) {
      state = state.copyWith(viewingId: null, error: adminErrorMessage(e));
    }
  }

  Future<void> toggleHistory(PolicyDocumentEntity doc) async {
    if (state.historyOpenId == doc.id) {
      state = state.copyWith(historyOpenId: null);
      return;
    }
    state = state.copyWith(historyOpenId: doc.id, historyLoading: true, history: const []);
    try {
      final history = await _repository.getAuditLog(doc.id);
      state = state.copyWith(history: history, historyLoading: false);
    } catch (_) {
      state = state.copyWith(history: const [], historyLoading: false);
    }
  }
}
