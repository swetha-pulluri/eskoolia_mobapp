import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../providers/auth_providers.dart';
import '../../../../config/router/portal_routes.dart';

const _cardFill = Color(0x14FFFFFF); // white @ 8%
const _cardBorder = Color(0x26FFFFFF); // white @ 15%
const _fieldFill = Color(0xFF3A2B8F); // solid deep purple, not white
const _fieldBorder = Color(0x40FFFFFF); // white @ 25%
const _white70 = Color(0xB3FFFFFF);
const _white54 = Color(0x8AFFFFFF);

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
              // Role→route mapping lives once in portal_routes.dart, used
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            decoration: BoxDecoration(
                              // The logo file is a wordmark with its own
                              // white background baked in (not a
                              // transparent icon) — a white card here lets
                              // that blend in seamlessly instead of
                              // tinting/cropping the real artwork.
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Image.asset(
                              AppConstants.eskooliaLogo,
                              height: 46,
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

                        _fieldLabel('USERNAME / EMAIL'),
                        const SizedBox(height: 8),
                        _AuthField(
                          controller: _identifierController,
                          icon: Icons.person_outline,
                          hint: 'Enter your username',
                          autofocus: true,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 18),

                        _fieldLabel('PASSWORD'),
                        const SizedBox(height: 8),
                        _AuthField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          trailing: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 19,
                              color: _white70,
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

                        const _SchoolSelectStrip(),

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

                        const Text(
                          "Don't have an account?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _white70),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Contact your administrator',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _white70, letterSpacing: 1.0),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final bool autofocus;
  final Widget? trailing;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.autofocus = false,
    this.trailing,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Solid purple box (not a white-tinted one) behind the field.
    return Container(
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fieldBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 19, color: _white70),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              autofocus: autofocus,
              validator: validator,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _white54, fontSize: 15),
                // The app's global `InputDecorationTheme` (app_theme.dart)
                // sets `filled: true` with its own light fillColor and
                // separate enabled/focused/error border states — overriding
                // only `border` above left those other states (and the
                // fill) showing through as a nested white-ish box. Every
                // state needs to be overridden explicitly to fully suppress
                // it here.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: const TextStyle(color: Color(0xFFFFC9CF), fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Multi-tenant "logging into a specific school" flow — real functionality
/// (identifies which school's subdomain this device talks to), just
/// restyled as a small muted link instead of its own header strip, since
/// the reference this screen matches has no room/place for a whole
/// separate section for it.
class _SchoolSelectStrip extends ConsumerWidget {
  const _SchoolSelectStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subdomain = ref.watch(selectedSchoolSubdomainProvider);

    if (subdomain == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Center(
          child: TextButton(
            onPressed: () => context.push('/school-select'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text(
              "Logging into a specific school? Enter your school's URL",
              textAlign: TextAlign.center,
              style: TextStyle(color: _white70, fontSize: 11.5, decoration: TextDecoration.underline, decorationColor: _white70),
            ),
          ),
        ),
      );
    }

    final schoolInfoAsync = ref.watch(schoolInfoProvider(subdomain));
    final schoolName = schoolInfoAsync.maybeWhen(data: (info) => info?.name, orElse: () => null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, size: 13, color: _white70),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  schoolName ?? subdomain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => context.push('/school-select'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Change School', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
          TextButton(
            onPressed: () => clearSelectedSchool(ref),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Use main login instead', style: TextStyle(color: _white70, fontSize: 11.5, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}
