import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_field.dart';
import '../../../../config/router/portal_routes.dart';

const _cardFill = Color(0x14FFFFFF); // white @ 8%
const _cardBorder = Color(0x26FFFFFF); // white @ 15%
const _white70 = Color(0xB3FFFFFF);

/// Login Page — Eskoolia's real brand purple (not a separate "Atrium"
/// theme), matching the app's actual mobile design reference: a single
/// centered translucent card on a deep purple gradient, not the old
/// desktop-oriented split "Identity Panel"/"Auth Panel" layout.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listenManual(authNotifierProvider, (previous, next) {
        next.when(
          initial: () {},
          loading: () {},
          authenticated: (user) {
            final target = resolveHomeRouteForPortal(user.portalType);
            debugPrint('[LoginPage] authenticated -> navigating to $target (user: ${user.username}, portalType: ${user.portalType})');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome, ${user.firstName} ${user.lastName}!'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Explicit navigation — do not rely solely on the router's
              // redirect-on-rebuild side effect (see app_router.dart).
              // Roleâ†’route mapping lives once in portal_routes.dart, used
              // by both this and the router's own redirect callback.
              context.go(target);
            }
          },
          unauthenticated: () {},
          error: (message) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: AppColors.error),
              );
            }
          },
        );
      });
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email or username is required.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required.'), backgroundColor: AppColors.error),
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).login(identifier, password);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).maybeWhen(loading: () => true, orElse: () => false);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1F87), AppColors.brandPurple, Color(0xFF5B4FE8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: BoxDecoration(
                    color: _cardFill,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          // One plain rounded white box, sized to hug the
                          // logo (not a large padded panel) — the logo
                          // file's own baked-in white background blends
                          // into it since both are the same solid white.
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Image.asset(
                              AppConstants.eskooliaLogo,
                              height: 116,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Text(
                                'Eskoolia',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.brandPurple),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Please sign in to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: _white70),
                        ),
                        const SizedBox(height: 26),

                        const AuthFieldLabel('USERNAME / EMAIL'),
                        const SizedBox(height: 8),
                        AuthField(
                          controller: _identifierController,
                          icon: Icons.person_outline,
                          hint: 'Enter your username',
                          autofocus: true,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 18),

                        const AuthFieldLabel('PASSWORD'),
                        const SizedBox(height: 8),
                        AuthField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          trailing: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 19,
                              color: AppColors.purpleDeep,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Consumer(
                          builder: (context, ref, child) {
                            final authState = ref.watch(authNotifierProvider);
                            return authState.maybeWhen(
                              error: (message) => Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFFFFC9CF), fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              orElse: () => const SizedBox.shrink(),
                            );
                          },
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.purpleDeep,
                              disabledBackgroundColor: Colors.white.withValues(alpha: 0.85),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.purpleDeep),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('SIGN IN', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Matches the real web login footer exactly
                        // (frontend/app/login/page.tsx) — was "Don't have
                        // an account? / Contact your administrator".
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            const Text('Secured by eSkoolia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Institutional-grade 256-bit AES encryption active.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: _white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
