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

const _launcherSize = 58.0;

/// Global mount point for the AI Assistant — wraps the routed app content in
/// a [Stack] and layers the launcher + panel on top, bottom-right by
/// default, exactly like AIBot.tsx's `position: fixed` launcher/panel.
/// Mounted once via `MaterialApp.router`'s `builder:` (see lib/main.dart) so
/// every screen gets it automatically, with no per-screen wiring. Hidden
/// whenever the user isn't authenticated (login/splash/etc.), matching the
/// fact that the frontend only ever renders `<AIBot />` inside its
/// authenticated app shell.
///
/// The launcher orb is user-draggable (mobile-only affordance, no web
/// equivalent to port) — [_dragOffset] holds the user's chosen top-left
/// position once they've moved it at least once; before that it sits at the
/// original fixed bottom-right spot.
class AiAssistantOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AiAssistantOverlay({super.key, required this.child});

  @override
  ConsumerState<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends ConsumerState<AiAssistantOverlay> {
  Offset? _dragOffset;

  Offset _clamp(Offset offset, Size screenSize, double topInset) {
    return Offset(
      offset.dx.clamp(8.0, screenSize.width - _launcherSize - 8.0),
      offset.dy.clamp(topInset + 8.0, screenSize.height - _launcherSize - 8.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.maybeWhen(authenticated: (_) => true, orElse: () => false);

    if (!isAuthenticated) return widget.child;

    final panelOpen = ref.watch(aiAssistantControllerProvider.select((s) => s.open));
    final controller = ref.read(aiAssistantControllerProvider.notifier);
    final screenSize = MediaQuery.sizeOf(context);
    final panelWidth = (screenSize.width - 44).clamp(240.0, 380.0);
    final topInset = MediaQuery.paddingOf(context).top;

    // `GlobalAppShell` shows a persistent bottom tab bar for both Admin
    // (`_GlobalBottomNav`) and Parent (`ParentBottomNav`, added later) — not
    // Teacher (desktop-style header pills, no bottom nav) or Student (no
    // shell at all). Reserve space above whichever bar is showing so the
    // launcher orb's *default* position sits clear of the "Profile" tab
    // instead of covering it — this was still `role != 'parent'` from
    // before Parent had its own bottom nav, which left the orb sitting
    // directly on top of Parent's Profile tab.
    final role = ref.watch(currentPortalRoleProvider);
    final hasBottomNav = isAuthenticated && role != 'teacher' && role != 'student';
    final bottomNavReserve = hasBottomNav ? _bottomNavHeight + MediaQuery.paddingOf(context).bottom : 0.0;

    final defaultOffset = Offset(
      screenSize.width - 22 - _launcherSize,
      screenSize.height - (22 + bottomNavReserve) - _launcherSize,
    );
    final position = _clamp(_dragOffset ?? defaultOffset, screenSize, topInset);

    // Panel anchors to the launcher's *current* position (same fixed gap
    // above/right of it as the original bottom:92/right:22 vs
    // bottom:22/right:22 pairing), so it still opens right next to the orb
    // no matter where the user has dragged it.
    final panelRight = (screenSize.width - position.dx - _launcherSize).clamp(0.0, screenSize.width - panelWidth);
    final panelBottom = screenSize.height - position.dy + 12;

    return Stack(
      children: [
        widget.child,
        if (panelOpen)
          Positioned(
            right: panelRight,
            bottom: panelBottom,
            child: AiPanel(width: panelWidth),
          ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _dragOffset = _clamp(position + details.delta, screenSize, topInset);
              });
            },
            child: AiLauncherButton(onTap: controller.togglePanel),
          ),
        ),
      ],
    );
  }
}
