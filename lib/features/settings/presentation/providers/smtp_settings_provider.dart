import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administration/presentation/providers/administration_list_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/smtp_settings_remote_datasource.dart';
import '../../data/repositories/smtp_settings_repository_impl.dart';
import '../../domain/entities/smtp_config_entity.dart';
import '../../domain/repositories/smtp_settings_repository.dart';
import 'smtp_settings_state.dart';

final smtpSettingsRemoteDataSourceProvider = Provider<SmtpSettingsRemoteDataSource>((ref) {
  return SmtpSettingsRemoteDataSource(ref.watch(dioClientProvider));
});

final smtpSettingsRepositoryProvider = Provider<SmtpSettingsRepository>((ref) {
  return SmtpSettingsRepositoryImpl(ref.watch(smtpSettingsRemoteDataSourceProvider));
});

final smtpSettingsNotifierProvider =
    StateNotifierProvider.autoDispose<SmtpSettingsNotifier, SmtpSettingsState>((ref) {
  return SmtpSettingsNotifier(ref.watch(smtpSettingsRepositoryProvider));
});

/// A 1:1 port of every function in `SmtpSettingsPanel.tsx`.
class SmtpSettingsNotifier extends StateNotifier<SmtpSettingsState> {
  final SmtpSettingsRepository _repository;

  SmtpSettingsNotifier(this._repository) : super(const SmtpSettingsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final configs = await _repository.getConfigs();
      state = state.copyWith(loading: false, configs: configs);
    } catch (e) {
      state = state.copyWith(loading: false, error: adminErrorMessage(e));
    }
  }

  void startCreate() {
    state = state.copyWith(
      editingId: null,
      draft: buildSmtpWizardDefaults(),
      step: 0,
      testEmail: '',
      wizardOpen: true,
    );
  }

  void startEdit(SmtpConfigEntity config) {
    state = state.copyWith(
      editingId: config.id,
      draft: config.toDraftMap(),
      step: 0,
      testEmail: '',
      wizardOpen: true,
    );
  }

  void closeWizard() {
    state = state.copyWith(wizardOpen: false, editingId: null);
  }

  void setStep(int step) => state = state.copyWith(step: step);

  void setDraftField(String key, dynamic value) {
    state = state.copyWith(draft: {...state.draft, key: value});
  }

  void setTestEmail(String value) => state = state.copyWith(testEmail: value);

  /// Mirrors `handleSubmit`'s payload rule: a blank password is dropped from
  /// the payload entirely (not sent as `""`) on both create and update, so
  /// the backend's "blank = keep existing" logic applies and the endpoint's
  /// own default (blank on create) is used instead of an explicit empty string.
  Map<String, dynamic> _buildPayload() {
    final payload = {...state.draft};
    if ((payload['password'] as String?)?.isEmpty ?? true) {
      payload.remove('password');
    }
    return payload;
  }

  Future<void> submit() async {
    state = state.copyWith(saving: true, error: null, success: null);
    try {
      final payload = _buildPayload();
      final editingId = state.editingId;
      if (editingId != null) {
        final updated = await _repository.updateConfig(editingId, payload);
        state = state.copyWith(
          saving: false,
          configs: [for (final c in state.configs) if (c.id == editingId) updated else c],
          success: 'SMTP config updated.',
          wizardOpen: false,
          editingId: null,
        );
      } else {
        final created = await _repository.createConfig(payload);
        state = state.copyWith(
          saving: false,
          configs: [...state.configs, created],
          success: 'SMTP config added.',
          wizardOpen: false,
          editingId: null,
        );
      }
    } catch (e) {
      state = state.copyWith(saving: false, error: adminErrorMessage(e));
      rethrow;
    }
  }

  Future<void> activate(int id) async {
    state = state.copyWith(busyId: id, error: null);
    try {
      await _repository.activateConfig(id);
      state = state.copyWith(success: 'Activated.');
      await load();
    } catch (e) {
      state = state.copyWith(error: adminErrorMessage(e));
    } finally {
      state = state.copyWith(busyId: null);
    }
  }

  Future<void> delete(SmtpConfigEntity config) async {
    state = state.copyWith(busyId: config.id, error: null);
    try {
      await _repository.deleteConfig(config.id);
      state = state.copyWith(configs: state.configs.where((c) => c.id != config.id).toList());
    } catch (e) {
      state = state.copyWith(error: adminErrorMessage(e));
    } finally {
      state = state.copyWith(busyId: null);
    }
  }

  /// Sends via the raw, unsaved wizard draft — mirrors `handleTestSend`,
  /// which never requires the config to be saved first.
  Future<void> sendTestEmail() async {
    state = state.copyWith(testSending: true, error: null, success: null);
    try {
      final payload = {...state.draft};
      if (state.testEmail.trim().isNotEmpty) {
        payload['to_email'] = state.testEmail.trim();
      }
      await _repository.testSend(payload);
      state = state.copyWith(testSending: false, success: 'Test email sent.');
    } catch (e) {
      state = state.copyWith(testSending: false, error: adminErrorMessage(e));
    }
  }

  Future<void> toggleHistory(SmtpConfigEntity config) async {
    if (state.historyOpenId == config.id) {
      state = state.copyWith(historyOpenId: null);
      return;
    }
    state = state.copyWith(historyOpenId: config.id, historyLoading: true, history: const []);
    try {
      final history = await _repository.getAuditLog(config.id);
      state = state.copyWith(history: history, historyLoading: false);
    } catch (_) {
      state = state.copyWith(history: const [], historyLoading: false);
    }
  }
}
