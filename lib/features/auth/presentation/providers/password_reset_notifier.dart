import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import 'password_reset_state.dart';

/// Password Reset Notifier
/// Drives the forgot-password / verify-code / reset-password screens.
/// Deliberately holds no email/code/password fields itself — those live in
/// the pages' own `TextEditingController`s and are passed in per call, so
/// nothing sensitive is retained here longer than the in-flight request.
class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final VerifyResetCodeUseCase _verifyResetCodeUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  PasswordResetNotifier(
    this._forgotPasswordUseCase,
    this._verifyResetCodeUseCase,
    this._resetPasswordUseCase,
  ) : super(const PasswordResetInitial());

  Future<void> requestCode(String email) async {
    state = const PasswordResetLoading();
    try {
      final message = await _forgotPasswordUseCase(email);
      state = PasswordResetSuccess(message);
    } catch (e) {
      state = PasswordResetError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> verifyCode(String email, String code) async {
    state = const PasswordResetLoading();
    try {
      await _verifyResetCodeUseCase(email, code);
      state = const PasswordResetSuccess('Code verified.');
    } catch (e) {
      state = PasswordResetError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    state = const PasswordResetLoading();
    try {
      final message = await _resetPasswordUseCase(email, code, newPassword);
      state = PasswordResetSuccess(message);
    } catch (e) {
      state = PasswordResetError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Clears any stale success/error from a previous step so it doesn't leak
  /// into the next one (e.g. after moving from the code step to the
  /// password step).
  void reset() {
    state = const PasswordResetInitial();
  }

  /// Surfaces a client-side validation error (e.g. code/password format)
  /// without making a network call — mirrors the same
  /// [PasswordResetError] state a failed API call would produce.
  void setError(String message) {
    state = PasswordResetError(message);
  }
}
