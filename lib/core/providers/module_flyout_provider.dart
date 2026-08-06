import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which module's dropdown flyout is open, and where to position it —
/// screen-global coordinates captured from the triggering pill via
/// `RenderBox.localToGlobal`, the same technique `_AvatarMenu` already uses
/// in `global_app_shell.dart`.
class ModuleFlyoutTarget {
  final String moduleId;
  final double top;
  final double left;

  const ModuleFlyoutTarget({required this.moduleId, required this.top, required this.left});
}

/// A single shared notifier — not one boolean per pill — so "only one
/// dropdown open at a time" is automatic: opening module B just reassigns
/// this state, which closes module A with no cross-widget coordination.
/// Also centralizes the 140ms close-delay timer (ports `ModulePill.tsx`'s
/// `handleLeave`) so both the pill and the flyout panel itself can
/// cancel/reschedule it as the pointer moves between them.
class ModuleFlyoutNotifier extends StateNotifier<ModuleFlyoutTarget?> {
  ModuleFlyoutNotifier() : super(null);

  Timer? _closeTimer;

  void openNow(ModuleFlyoutTarget target) {
    _closeTimer?.cancel();
    state = target;
  }

  void scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 140), () {
      state = null;
    });
  }

  void cancelScheduledClose() {
    _closeTimer?.cancel();
  }

  void closeNow() {
    _closeTimer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }
}

final moduleFlyoutProvider = StateNotifierProvider<ModuleFlyoutNotifier, ModuleFlyoutTarget?>(
  (ref) => ModuleFlyoutNotifier(),
);
