import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administration/domain/entities/picked_attachment.dart';
import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/document_branding_remote_datasource.dart';
import '../../data/repositories/document_branding_repository_impl.dart';
import '../../domain/entities/document_branding_entity.dart';
import '../../domain/repositories/document_branding_repository.dart';
import '../../domain/repositories/school_info_repository.dart';
import 'document_branding_state.dart';
import 'settings_provider.dart' show schoolInfoRepositoryProvider;

final documentBrandingRemoteDataSourceProvider = Provider<DocumentBrandingRemoteDataSource>((ref) {
  return DocumentBrandingRemoteDataSource(ref.watch(dioClientProvider));
});

final documentBrandingRepositoryProvider = Provider<DocumentBrandingRepository>((ref) {
  return DocumentBrandingRepositoryImpl(ref.watch(documentBrandingRemoteDataSourceProvider));
});

final documentBrandingNotifierProvider =
    StateNotifierProvider.autoDispose<DocumentBrandingNotifier, DocumentBrandingState>((ref) {
  return DocumentBrandingNotifier(ref.watch(documentBrandingRepositoryProvider), ref.watch(schoolInfoRepositoryProvider));
});

/// Drives the Header/Declarations form + live preview — a 1:1 port of every
/// function in `DocumentBrandingPanel.tsx`.
class DocumentBrandingNotifier extends StateNotifier<DocumentBrandingState> {
  final DocumentBrandingRepository _repository;
  final SchoolInfoRepository _schoolInfoRepository;
  Timer? _previewDebounce;

  DocumentBrandingNotifier(this._repository, this._schoolInfoRepository) : super(const DocumentBrandingState()) {
    load();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final settingsFuture = _repository.getBranding();
      final logoFuture = _schoolInfoRepository
          .getSchoolInfo()
          .then((info) => info.logoUrl.isNotEmpty)
          .catchError((_) => false);
      final settings = await settingsFuture;
      final hasLogo = await logoFuture;
      state = state.copyWith(loading: false, settings: settings, draft: settings.toFormMap(), hasSchoolLogo: hasLogo);
      await _refreshPreview();
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  void setActiveTab(int tab) => state = state.copyWith(activeTab: tab);

  void selectDeclaration(String key) => state = state.copyWith(selectedDeclarationKey: key);

  void toggleBw() => state = state.copyWith(bwPreview: !state.bwPreview);

  void setDraftField(String key, dynamic value) {
    state = state.copyWith(draft: {...state.draft, key: value});
    if (documentBrandingPreviewFields.contains(key) && (state.draft['header_mode'] as String?) == 'generated') {
      _schedulePreview();
    }
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 420), _refreshPreview);
  }

  Future<void> _refreshPreview() async {
    final mode = (state.draft['header_mode'] as String?) ?? 'generated';
    state = state.copyWith(previewLoading: true);
    try {
      final bytes = mode == 'uploaded'
          ? await _repository.getHeaderImageBytes()
          : await _repository.getPreviewBytes({for (final key in documentBrandingPreviewFields) key: state.draft[key]});
      state = state.copyWith(previewBytes: bytes, previewLoading: false);
    } catch (_) {
      // Preview is supplementary — matches the web's own silent catch,
      // which just leaves the last-rendered preview (or the empty state) up.
      state = state.copyWith(previewLoading: false);
    }
  }

  Future<void> uploadLetterhead(PickedAttachment file, String mimeType) async {
    state = state.copyWith(uploading: true, error: null, success: null);
    try {
      final updated = await _repository.uploadLetterhead(file, mimeType);
      state = state.copyWith(
        uploading: false,
        settings: updated,
        draft: updated.toFormMap(),
        success: 'Letterhead uploaded and applied everywhere.',
      );
      await _refreshPreview();
    } catch (e) {
      state = state.copyWith(uploading: false, error: adminErrorMessage(e));
    }
  }

  Future<void> submit() async {
    state = state.copyWith(saving: true, error: null, success: null);
    try {
      final updated = await _repository.updateBranding(Map<String, dynamic>.from(state.draft));
      state = state.copyWith(
        saving: false,
        settings: updated,
        draft: updated.toFormMap(),
        success: 'Saved — this header now applies to every printed document across the ERP.',
      );
    } catch (e) {
      state = state.copyWith(saving: false, error: adminErrorMessage(e));
    }
  }
}
