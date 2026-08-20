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
<<<<<<< Updated upstream
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.brandPurple),
      body: SafeArea(
        child: MouseRegion(
          onHover: (event) => _handleMouseMove(event, screenSize),
          child: Container(
            width: screenWidth,
            height: screenHeight,
            color: AppColors.surfaceBright,
            child: Stack(
              children: [
                // ═══ Background Layers ═══
                _buildBackgroundLayers(screenWidth),

                // ═══ Scrollable Content ═══
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ═══ Header ═══
                            _buildHeader(screenWidth),

                            // ═══ Main Content ═══
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsiveSpacing(
                                  context,
                                  isMobile ? 16 : 40,
                                ),
                                vertical: responsiveSpacing(
                                  context,
                                  isMobile ? 20 : 40,
                                ),
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1080,
                                  ),
                                  child: isMobile
                                      ? _buildMobileLayout()
                                      : _buildDesktopLayout(),
                                ),
>>>>>>> Stashed changes
=======
                                style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
<<<<<<< Updated upstream
                        const Text(
                          "Don't have an account?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _white70),
=======
                        // Matches the real web login footer exactly
                        // (frontend/app/login/page.tsx) — was "Don't have
                        // an account? / Contact your administrator".
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text('Secured by eSkoolia', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
>>>>>>> Stashed changes
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Institutional-grade 256-bit AES encryption active.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: _white70),
                        ),
                      ],
=======
  Widget _buildHeader(double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    final logoHeight = isSmallScreen ? 60.0 : 70.0;
    final headerPadding = EdgeInsets.symmetric(
      horizontal: responsiveSpacing(context, isSmallScreen ? 8 : 12),
      vertical: responsiveSpacing(context, 4),
    );

    return GlassPanel(
      padding: headerPadding,
      child: isSmallScreen
          ? _buildCompactHeader(logoHeight)
          : _buildFullHeader(logoHeight, screenWidth),
    );
  }

  Widget _buildCompactHeader(double logoHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Flexible(
          child: Image.asset(
            AppConstants.eskooliaLogo,
            height: logoHeight,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              height: logoHeight,
              width: logoHeight,
              color: Colors.grey[300],
              child: Icon(Icons.school, size: logoHeight * 0.5),
            ),
          ),
        ),
        SizedBox(width: responsiveSpacing(context, 8)),
        // Status indicator only
        _buildStatusDot(),
      ],
    );
  }

  Widget _buildFullHeader(double logoHeight, double screenWidth) {
    final showFullStatus = screenWidth > 700;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Flexible(
          flex: 2,
          child: Image.asset(
            AppConstants.eskooliaLogo,
            height: logoHeight,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              height: logoHeight,
              width: logoHeight,
              color: Colors.grey[300],
              child: Icon(Icons.school, size: logoHeight * 0.5),
            ),
          ),
        ),

        // Header Actions
        Flexible(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Pill
              if (showFullStatus)
                Flexible(child: _buildStatusPill())
              else
                _buildStatusDot(),
              SizedBox(width: responsiveSpacing(context, 12)),
              // Partner Brand
              if (screenWidth > 800) Flexible(child: _buildPartnerBrand()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDot() {
    return Container(
      width: responsiveSpacing(context, 8),
      height: responsiveSpacing(context, 8),
      decoration: BoxDecoration(
        color: AppColors.statusActive,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.statusActive.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final fontSize = responsiveFontSize(context, 9);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsiveSpacing(context, 12),
        vertical: responsiveSpacing(context, 4),
      ),
      decoration: BoxDecoration(
        color: AppColors.atriumIndigo.withValues(alpha: 0.03),
        border: Border.all(
          color: AppColors.atriumIndigo.withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: responsiveSpacing(context, 6),
                height: responsiveSpacing(context, 6),
                decoration: BoxDecoration(
                  color: AppColors.statusActive,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusActive.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsiveSpacing(context, 6)),
              Text(
                'ACTIVE',
                style: TextStyle(
                  color: AppColors.atriumIndigo.withValues(alpha: 0.8),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: responsiveSpacing(context, 12),
            ),
            width: 1,
            height: responsiveSpacing(context, 12),
            color: AppColors.atriumIndigo.withValues(alpha: 0.1),
          ),
          // Session Group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: responsiveIconSize(context, 12),
                color: AppColors.atriumIndigo.withValues(alpha: 0.6),
              ),
              SizedBox(width: responsiveSpacing(context, 6)),
              Text(
                AppConstants.session.toUpperCase(),
                style: TextStyle(
                  color: AppColors.atriumIndigo,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerBrand() {
    return Opacity(
      opacity: 0.6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'POWERED BY',
            style: TextStyle(
              color: AppColors.atriumIndigo.withValues(alpha: 0.6),
              fontSize: responsiveFontSize(context, 9),
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(width: responsiveSpacing(context, 8)),
          Image.asset(
            AppConstants.eskooliaLogo,
            height: responsiveIconSize(context, 14),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Desktop Layout
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopLayout() {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity Panel (Left)
          Expanded(child: _buildIdentityPanel()),
          // Auth Panel (Right)
          SizedBox(width: 440, child: _buildAuthPanel()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Mobile Layout
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return GlassCard(
      borderRadius: 24,
      child: Column(
        children: [
          _buildAuthPanel(),
          const Divider(height: 1),
          _buildIdentityPanel(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Identity Panel (Left Side / Bottom on Mobile)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildIdentityPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    final isSmall = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(responsiveSpacing(context, isSmall ? 20 : 32)),
      decoration: const BoxDecoration(
        gradient: AppColors.identityPanelGradient,
      ),
      child: Stack(
        children: [
          // Campus Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.grey.withValues(alpha: 0.4),
                  BlendMode.saturation,
                ),
                child: Opacity(
                  opacity: 0.28,
                  child: Image.network(
                    AppConstants.campusImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gateway Badge
              const GatewayBadge(),
              SizedBox(height: responsiveSpacing(context, 14)),

              // Hero Copy
              _buildHeroCopy(isVerySmall, isSmall),
              SizedBox(height: responsiveSpacing(context, 14)),

              // Feature Grid
              _buildFeatureGrid(isVerySmall, isSmall),
              SizedBox(height: responsiveSpacing(context, 20)),

              // Trust Strip
              const TrustStrip(facultyImages: AppConstants.facultyImages),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCopy(bool isVerySmall, bool isSmall) {
    final eyebrowFontSize = responsiveFontSize(context, isVerySmall ? 9 : 11);
    final headingFontSize = responsiveFontSize(
      context,
      isVerySmall
          ? 22
          : isSmall
          ? 26
          : 30,
    );
    final descriptionFontSize = responsiveFontSize(
      context,
      isVerySmall ? 12 : 13,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow
        Text(
          'EXCELLENCE DEFINED',
          style: TextStyle(
            color: AppColors.deepSaffron,
            fontSize: eyebrowFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: isVerySmall ? 2.0 : 3.0,
          ).copyWith(fontFamily: 'Plus Jakarta Sans'),
        ),
        SizedBox(height: responsiveSpacing(context, 6)),

        // Heading
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.atriumIndigo,
              fontSize: headingFontSize,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: 0,
            ).copyWith(fontFamily: 'Plus Jakarta Sans'),
            children: [
              const TextSpan(text: 'The Heart of\n'),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.heroTextGradient.createShader(bounds),
                  child: Text(
                    'Educational Mastery.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      height: 1.15,
>>>>>>> Stashed changes
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
