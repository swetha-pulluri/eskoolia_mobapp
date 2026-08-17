import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../widgets_panel/presentation/providers/widget_prefs_provider.dart';
import '../providers/ai_assistant_controller.dart';
import 'ai_launcher_button.dart';
import 'ai_panel.dart';

/// Fixed height of `GlobalAppShell`'s `_GlobalBottomNav` row, excluding its
/// own bottom safe-area inset (added separately below) — kept in sync with
/// that widget's `SizedBox(height: 56)` by hand, since the two live in
/// different features and neither imports the other.
const _bottomNavHeight = 56.0;

/// Global mount point for the AI Assistant — wraps the routed app content in
/// a [Stack] and layers the launcher + panel on top, bottom-right, exactly
/// like AIBot.tsx's `position: fixed` launcher/panel. Mounted once via
/// `MaterialApp.router`'s `builder:` (see lib/main.dart) so every screen
/// gets it automatically, with no per-screen wiring. Hidden whenever the
/// user isn't authenticated (login/splash/etc.), matching the fact that the
/// frontend only ever renders `<AIBot />` inside its authenticated app shell.
class AiAssistantOverlay extends ConsumerWidget {
  final Widget child;

  const AiAssistantOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.maybeWhen(authenticated: (_) => true, orElse: () => false);

    if (!isAuthenticated) return child;

    final panelOpen = ref.watch(aiAssistantControllerProvider.select((s) => s.open));
    final controller = ref.read(aiAssistantControllerProvider.notifier);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = (screenWidth - 44).clamp(240.0, 380.0);

    // `GlobalAppShell` only shows its persistent bottom tab bar for the
    // Admin chrome (not Teacher, and not Parent/Student, which get no shell
    // at all) — reserve space above it there so the launcher orb sits clear
    // of the "Profile" tab instead of covering it.
    final role = ref.watch(currentPortalRoleProvider);
    final hasBottomNav = isAuthenticated && role != 'teacher' && role != 'parent' && role != 'student';
    final bottomNavReserve = hasBottomNav ? _bottomNavHeight + MediaQuery.paddingOf(context).bottom : 0.0;

    return Stack(
      children: [
        child,
        if (panelOpen)
          Positioned(
            right: 22,
            bottom: 92 + bottomNavReserve,
            child: AiPanel(width: panelWidth),
          ),
        Positioned(
          right: 22,
          bottom: 22 + bottomNavReserve,
          child: AiLauncherButton(onTap: controller.togglePanel),
        ),
      ],
    );
  }
}
