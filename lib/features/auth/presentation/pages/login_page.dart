import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../widgets/feature_card.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gateway_badge.dart';
import '../widgets/trust_strip.dart';
import '../widgets/security_panel.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/atrium_button.dart';
import '../providers/auth_providers.dart';

/// Login Page
/// Fully responsive mobile-first implementation
/// Maintains frontend design with zero overflow
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

/// Responsive sizing helper mixin
mixin ResponsiveSizes {
  // Calculate responsive font size
  double responsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85;
    if (width < 400) return baseSize * 0.9;
    return baseSize;
  }

  // Calculate responsive spacing
  double responsiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSpacing * 0.7;
    if (width < 400) return baseSpacing * 0.85;
    return baseSpacing;
  }

  // Calculate responsive icon size
  double responsiveIconSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.8;
    if (width < 400) return baseSize * 0.9;
    return baseSize;
  }
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin, ResponsiveSizes {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberDevice = false;

  // Parallax blob animation
  Offset _blobOffset = Offset.zero;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listenManual(authNotifierProvider, (previous, next) {
        next.when(
          initial: () {},
          loading: () {},
          authenticated: (user) {
            debugPrint('[LoginPage] authenticated -> navigating to /home (user: ${user.username}, portalType: ${user.portalType})');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome, ${user.firstName} ${user.lastName}!'),
                  backgroundColor: AppColors.airaTeal,
                ),
              );
              // Explicit navigation — do not rely solely on the router's
              // redirect-on-rebuild side effect (see app_router.dart).
              context.go('/home');
            }
          },
          unauthenticated: () {},
          error: (message) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        );
      });
    });
  }

  void _handleMouseMove(PointerEvent event, Size screenSize) {
    if (!mounted) return;
    setState(() {
      _blobOffset = Offset(
        (event.position.dx / screenSize.width - 0.5) * 80,
        (event.position.dy / screenSize.height - 0.5) * 80,
      );
    });
  }

  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email or username is required.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password is required.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Call login from auth notifier
    await ref.read(authNotifierProvider.notifier).login(identifier, password);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isMobile = screenWidth < 900;

    return Scaffold(
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
                              ),
                            ),

                            // ═══ Footer ═══
                            _buildFooter(screenWidth),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Background Layers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBackgroundLayers(double screenWidth) {
    // Responsive blob sizes
    final blobSize = screenWidth < 400 ? 500.0 : 700.0;
    final blobOffset = screenWidth < 400 ? -150.0 : -200.0;

    return Stack(
      children: [
        // Mandala Background
        Positioned.fill(
          child: Opacity(
            opacity: 0.04,
            child: Image.network(
              AppConstants.mandalaImage,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        ),

        // Aura Teal Blob
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          right: blobOffset + _blobOffset.dx,
          top: blobOffset + _blobOffset.dy,
          child: Container(
            width: blobSize,
            height: blobSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.auraTealBlob, Colors.transparent],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),

        // Aura Saffron Blob
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          left: blobOffset - _blobOffset.dx,
          bottom: blobOffset - _blobOffset.dy,
          child: Container(
            width: blobSize,
            height: blobSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.auraSaffronBlob, Colors.transparent],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════════════════════

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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsiveSpacing(context, 8)),

        // Description
        Text(
          'Welcome to your unified institutional workspace. Securely access the complete academic ecosystem designed for the modern ${AppConstants.schoolName} family.',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: descriptionFontSize,
            height: 1.5,
          ).copyWith(fontFamily: 'Plus Jakarta Sans'),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(bool isVerySmall, bool isSmall) {
    // Use LayoutBuilder to make grid responsive
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isSmall ? 2 : 2;
        final spacing = responsiveSpacing(context, isVerySmall ? 8 : 10);
        final availableWidth = constraints.maxWidth;
        final itemWidth =
            (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        // Increased height ratios to prevent overflow: 0.58 for very small, 0.52 for normal
        final itemHeight = isVerySmall ? itemWidth * 0.58 : itemWidth * 0.52;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: itemWidth / itemHeight,
          children: const [
            FeatureCard(
              icon: Icons.school,
              title: 'ACADEMICS',
              note: 'Curriculum & Grading',
              tone: FeatureCardTone.teal,
            ),
            FeatureCard(
              icon: Icons.payments,
              title: 'FINANCES',
              note: 'Fee Management',
              tone: FeatureCardTone.saffron,
            ),
            FeatureCard(
              icon: Icons.how_to_reg,
              title: 'ADMISSIONS',
              note: 'Enrollment Hub',
              tone: FeatureCardTone.marigold,
            ),
            FeatureCard(
              icon: Icons.forum,
              title: 'CONNECT',
              note: 'Parent Portal',
              tone: FeatureCardTone.indigo,
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Auth Panel (Right Side / Top on Mobile)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAuthPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    final isSmall = screenWidth < 600;

    final padding = responsiveSpacing(context, isSmall ? 20 : 36);
    final headingFontSize = responsiveFontSize(
      context,
      isVerySmall
          ? 24
          : isSmall
          ? 28
          : 32,
    );
    final subheadingFontSize = responsiveFontSize(
      context,
      isVerySmall ? 11 : 12,
    );

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          left: BorderSide(color: AppColors.glassStroke, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 60,
            offset: const Offset(-30, 0),
            spreadRadius: -15,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Auth Heading
            _buildAuthHeading(headingFontSize, subheadingFontSize, isVerySmall),
            SizedBox(height: responsiveSpacing(context, 16)),

            // Form Fields
            AuthInputField(
              label: 'Institutional Email / Username',
              placeholder: 'username@${AppConstants.schoolEmailDomain}',
              icon: Icons.alternate_email,
              tone: AuthInputTone.teal,
              controller: _identifierController,
              autofocus: true,
            ),
            SizedBox(height: responsiveSpacing(context, 12)),

            AuthInputField(
              label: 'Access Key / Password',
              placeholder: '••••••••••••',
              icon: Icons.key,
              tone: AuthInputTone.saffron,
              controller: _passwordController,
              obscureText: true,
              showPasswordToggle: true,
            ),
            SizedBox(height: responsiveSpacing(context, 12)),

            // Error Message
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authNotifierProvider);
                return authState.maybeWhen(
                  error: (message) => Padding(
                    padding: EdgeInsets.only(
                      bottom: responsiveSpacing(context, 12),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: responsiveFontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),

            // Form Options
            _buildFormOptions(isSmall, isVerySmall),
            SizedBox(height: responsiveSpacing(context, 12)),

            // Submit Button
            AtriumButton(
              text: 'Enter the Digital Atrium',
              onPressed: _handleSubmit,
              isLoading: ref
                  .watch(authNotifierProvider)
                  .maybeWhen(loading: () => true, orElse: () => false),
            ),
            SizedBox(height: responsiveSpacing(context, 16)),

            // Security Panel
            const SecurityPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthHeading(
    double headingFontSize,
    double subheadingFontSize,
    bool isVerySmall,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heading Rule
        Container(
          width: responsiveSpacing(context, isVerySmall ? 40 : 50),
          height: responsiveSpacing(context, 4),
          decoration: BoxDecoration(
            color: AppColors.airaTeal,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        SizedBox(height: responsiveSpacing(context, 10)),

        // Heading
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.atriumIndigo,
              fontSize: headingFontSize,
              height: 1.2,
              letterSpacing: 0,
            ).copyWith(fontFamily: 'Plus Jakarta Sans'),
            children: const [
              TextSpan(
                text: 'Gateway ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: 'to Mastery',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsiveSpacing(context, 8)),

        // Subheading
        Text(
          'Authenticate your institutional identity to enter the command center of academic excellence.',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: subheadingFontSize,
            height: 1.5,
          ).copyWith(fontFamily: 'Plus Jakarta Sans'),
        ),
      ],
    );
  }

  Widget _buildFormOptions(bool isSmall, bool isVerySmall) {
    final fontSize = responsiveFontSize(context, isVerySmall ? 12 : 13);

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRememberDevice(fontSize),
          SizedBox(height: responsiveSpacing(context, 8)),
          _buildForgotPassword(fontSize),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _buildRememberDevice(fontSize)),
        SizedBox(width: responsiveSpacing(context, 8)),
        _buildForgotPassword(fontSize),
      ],
    );
  }

  Widget _buildRememberDevice(double fontSize) {
    return InkWell(
      onTap: () {
        setState(() => _rememberDevice = !_rememberDevice);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: responsiveSpacing(context, 20),
            height: responsiveSpacing(context, 20),
            decoration: BoxDecoration(
              color: _rememberDevice ? AppColors.airaTeal : AppColors.white,
              border: Border.all(
                color: _rememberDevice
                    ? AppColors.airaTeal
                    : AppColors.outlineVariant,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _rememberDevice
                ? Icon(
                    Icons.check,
                    size: responsiveIconSize(context, 14),
                    color: AppColors.white,
                  )
                : null,
          ),
          SizedBox(width: responsiveSpacing(context, 8)),
          Flexible(
            child: Text(
              'Trust this device',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ).copyWith(fontFamily: 'Plus Jakarta Sans'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword(double fontSize) {
    return TextButton(
      onPressed: () {
        // TODO: Navigate to forgot password
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Forgot Access Key?',
        style: TextStyle(
          color: AppColors.deepSaffron,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.deepSaffron.withValues(alpha: 0.3),
        ).copyWith(fontFamily: 'Plus Jakarta Sans'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Footer
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFooter(double screenWidth) {
    final isSmall = screenWidth < 700;
    final fontSize = responsiveFontSize(context, isSmall ? 10 : 11);
    final padding = EdgeInsets.symmetric(
      horizontal: responsiveSpacing(context, isSmall ? 16 : 32),
      vertical: responsiveSpacing(context, isSmall ? 12 : 16),
    );

    if (isSmall) {
      return Container(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCopyright(fontSize),
            SizedBox(height: responsiveSpacing(context, 8)),
            _buildFooterLinks(fontSize, isSmall: true),
          ],
        ),
      );
    }

    return Container(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: _buildCopyright(fontSize)),
          SizedBox(width: responsiveSpacing(context, 16)),
          Flexible(child: _buildFooterLinks(fontSize)),
        ],
      ),
    );
  }

  Widget _buildCopyright(double fontSize) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: fontSize,
        ).copyWith(fontFamily: 'Plus Jakarta Sans'),
        children: [
          const TextSpan(text: '© 2024 '),
          TextSpan(
            text: '${AppConstants.schoolName} Institutional Node',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '. Built on '),
          TextSpan(
            text: 'eSkoolia Infrastructure v4.8.2',
            style: TextStyle(color: AppColors.airaTeal.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks(double fontSize, {bool isSmall = false}) {
    if (isSmall) {
      return Wrap(
        spacing: responsiveSpacing(context, 12),
        runSpacing: responsiveSpacing(context, 8),
        children: [
          _footerLink('Privacy Hub', fontSize),
          _footerLink('Legal Terms', fontSize),
          _buildConcierge(fontSize),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _footerLink('Privacy Hub', fontSize),
        SizedBox(width: responsiveSpacing(context, 12)),
        _footerLink('Legal Terms', fontSize),
        SizedBox(width: responsiveSpacing(context, 16)),
        _buildConcierge(fontSize),
      ],
    );
  }

  Widget _buildConcierge(double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Academic Concierge',
          style: TextStyle(
            color: AppColors.airaTeal.withValues(alpha: 0.8),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ).copyWith(fontFamily: 'Plus Jakarta Sans'),
        ),
        SizedBox(width: responsiveSpacing(context, 6)),
        Icon(
          Icons.support_agent,
          size: responsiveIconSize(context, 14),
          color: AppColors.airaTeal.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  Widget _footerLink(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none,
      ).copyWith(fontFamily: 'Plus Jakarta Sans'),
    );
  }
}
