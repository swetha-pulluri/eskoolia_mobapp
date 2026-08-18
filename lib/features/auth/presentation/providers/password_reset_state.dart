/// Password Reset State
/// Represents the state of a single forgot/verify/reset step. Plain sealed
/// class (no freezed/codegen) — the shape is small enough not to need it.
sealed class PasswordResetState {
  const PasswordResetState();
}

class PasswordResetInitial extends PasswordResetState {
  const PasswordResetInitial();
}

class PasswordResetLoading extends PasswordResetState {
  const PasswordResetLoading();
}

class PasswordResetSuccess extends PasswordResetState {
  final String message;
  const PasswordResetSuccess(this.message);
}

class PasswordResetError extends PasswordResetState {
  final String message;
  const PasswordResetError(this.message);
}
