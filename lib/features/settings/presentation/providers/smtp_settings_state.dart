import '../../domain/entities/smtp_config_entity.dart';

const Object _unset = Object();

/// Combines every `useState` hook from `SmtpSettingsPanel.tsx` into one
/// immutable state object for a single `StateNotifier`.
class SmtpSettingsState {
  final List<SmtpConfigEntity> configs;
  final bool loading;
  final String? error;
  final String? success;
  final int? busyId;

  final bool wizardOpen;
  final int step;
  final int? editingId;
  final Map<String, dynamic> draft;
  final bool saving;
  final String testEmail;
  final bool testSending;

  final int? historyOpenId;
  final List<SmtpAuditEntry> history;
  final bool historyLoading;

  const SmtpSettingsState({
    this.configs = const [],
    this.loading = true,
    this.error,
    this.success,
    this.busyId,
    this.wizardOpen = false,
    this.step = 0,
    this.editingId,
    this.draft = const {},
    this.saving = false,
    this.testEmail = '',
    this.testSending = false,
    this.historyOpenId,
    this.history = const [],
    this.historyLoading = false,
  });

  bool get isEditing => editingId != null;

  SmtpSettingsState copyWith({
    List<SmtpConfigEntity>? configs,
    bool? loading,
    Object? error = _unset,
    Object? success = _unset,
    Object? busyId = _unset,
    bool? wizardOpen,
    int? step,
    Object? editingId = _unset,
    Map<String, dynamic>? draft,
    bool? saving,
    String? testEmail,
    bool? testSending,
    Object? historyOpenId = _unset,
    List<SmtpAuditEntry>? history,
    bool? historyLoading,
  }) {
    return SmtpSettingsState(
      configs: configs ?? this.configs,
      loading: loading ?? this.loading,
      error: error == _unset ? this.error : error as String?,
      success: success == _unset ? this.success : success as String?,
      busyId: busyId == _unset ? this.busyId : busyId as int?,
      wizardOpen: wizardOpen ?? this.wizardOpen,
      step: step ?? this.step,
      editingId: editingId == _unset ? this.editingId : editingId as int?,
      draft: draft ?? this.draft,
      saving: saving ?? this.saving,
      testEmail: testEmail ?? this.testEmail,
      testSending: testSending ?? this.testSending,
      historyOpenId: historyOpenId == _unset ? this.historyOpenId : historyOpenId as int?,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
    );
  }
}

/// Fresh-draft defaults for "Add Another Config" — mirrors `WIZARD_DEFAULTS`.
Map<String, dynamic> buildSmtpWizardDefaults() => {
      'name': '',
      'smtp_type': 'server',
      'host': '',
      'port': 587,
      'username': '',
      'password': '',
      'use_tls': true,
      'from_email': '',
      'bcc_email': '',
      'sender_name': '',
      'priority': 'normal',
      'receiver_email_type': 'email_id',
    };
