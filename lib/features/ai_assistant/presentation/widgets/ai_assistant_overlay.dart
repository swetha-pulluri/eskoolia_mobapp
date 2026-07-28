import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/ai_assistant_controller.dart';
import 'ai_launcher_button.dart';
import 'ai_panel.dart';

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

    return Stack(
      children: [
        child,
        if (panelOpen)
          Positioned(
            right: 22,
            bottom: 92,
            child: AiPanel(width: panelWidth),
          ),
        Positioned(
          right: 22,
          bottom: 22,
          child: AiLauncherButton(onTap: controller.togglePanel),
        ),
      ],
    );
  }
}
