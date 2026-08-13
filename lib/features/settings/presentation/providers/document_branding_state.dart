import '../../domain/entities/document_branding_entity.dart';

const Object _unset = Object();

/// Combines every `useState` hook from `DocumentBrandingPanel.tsx` into one
/// immutable state object for a single `StateNotifier` — same pattern as
/// every other Settings sub-feature. Note: unlike most other Settings
/// screens, the web pairs this with `useUnsavedChangesGuard` (a shared
/// cross-app React context that auto-saves on navigate-away); there is no
/// Flutter equivalent of that context anywhere in this app (the same gap
/// already noted for Attendance Rules), so leaving this screen with unsaved
/// changes here simply discards them, like every other Settings screen.
class DocumentBrandingState {
  final DocumentBrandingEntity? settings;
  final Map<String, dynamic> draft;
  final bool loading;
  final String? error;
  final String? success;
  final bool saving;
  final bool uploading;

  /// 0 = Header tab, 1 = Declarations tab.
  final int activeTab;
  final String selectedDeclarationKey;

  /// Whether School Info has a logo set — gates the "Include logo" toggle,
  /// mirrors the web's own `schoolLogoUrl` check.
  final bool hasSchoolLogo;

  final List<int>? previewBytes;
  final bool previewLoading;
  final bool bwPreview;

  const DocumentBrandingState({
    this.settings,
    this.draft = const {},
    this.loading = true,
    this.error,
    this.success,
    this.saving = false,
    this.uploading = false,
    this.activeTab = 0,
    this.selectedDeclarationKey = 'declaration_student_verification',
    this.hasSchoolLogo = false,
    this.previewBytes,
    this.previewLoading = false,
    this.bwPreview = false,
  });

  DocumentBrandingState copyWith({
    Object? settings = _unset,
    Map<String, dynamic>? draft,
    bool? loading,
    Object? error = _unset,
    Object? success = _unset,
    bool? saving,
    bool? uploading,
    int? activeTab,
    String? selectedDeclarationKey,
    bool? hasSchoolLogo,
    Object? previewBytes = _unset,
    bool? previewLoading,
    bool? bwPreview,
  }) {
    return DocumentBrandingState(
      settings: settings == _unset ? this.settings : settings as DocumentBrandingEntity?,
      draft: draft ?? this.draft,
      loading: loading ?? this.loading,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
      saving: saving ?? this.saving,
      uploading: uploading ?? this.uploading,
      activeTab: activeTab ?? this.activeTab,
      selectedDeclarationKey: selectedDeclarationKey ?? this.selectedDeclarationKey,
      hasSchoolLogo: hasSchoolLogo ?? this.hasSchoolLogo,
      previewBytes: previewBytes == _unset ? this.previewBytes : previewBytes as List<int>?,
      previewLoading: previewLoading ?? this.previewLoading,
      bwPreview: bwPreview ?? this.bwPreview,
    );
  }
}
