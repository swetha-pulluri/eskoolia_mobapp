import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/widgets/global_app_shell.dart';
import 'data/local/shared_prefs.dart';
import 'features/ai_assistant/presentation/widgets/ai_assistant_overlay.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences (used by the dashboard's pins/recents store)
  await SharedPrefs().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app start
    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).checkAuthStatus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Downloads/refreshes the logged-in school's logo + brand color right
    // after `checkAuthStatus()` (cold start) or `login()` resolves, without
    // threading a Dio/branding dependency through `AuthNotifier` itself.
    // Never blocks or affects auth state — see `BrandingNotifier.syncFromUser`.
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        authenticated: (user) => ref.read(brandingNotifierProvider.notifier).syncFromUser(
          user.schoolBranding,
          ref.read(dioProvider),
          schoolId: user.schoolId,
        ),
      );
    });
    final brandColor = ref.watch(brandingNotifierProvider).brandColor;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(brandColor),
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, routedChild) => AiAssistantOverlay(
        child: GlobalAppShell(child: routedChild ?? const SizedBox.shrink()),
      ),
    );
  }
}
