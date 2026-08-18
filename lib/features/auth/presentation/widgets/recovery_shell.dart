import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';

/// Shared chrome for the Forgot Password / Reset Password screens.
///
/// Exact replica of frontend/app/globals.css's `.auth-flow-shell` /
/// `.reset-shell` + `.compact-header` + `.compact-footer` + `.flow-aura` +
/// `.typo-bleed` + `.form-rule` rules, collapsed to the same single-column
/// layout web itself renders at mobile widths (`@media (max-width: 980px)`
/// in that file hides `.recovery-visual`/`.reset-visual` and the header's
/// pill/subtitle entirely) — this is not a from-scratch mobile design, it's
/// web's own real narrow-viewport rendering.
class RecoveryShell extends StatelessWidget {
  final String bleedText;
  final Widget child;
  final VoidCallback onBack;
  final String backLabel;

  const RecoveryShell({
    super.key,
    required this.bleedText,
    required this.child,
    required this.onBack,
    this.backLabel = 'Back to Digital Atrium',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            _CompactHeader(),
            Expanded(
              child: Stack(
                children: [
                  // .flow-aura-teal (top-left) / .flow-aura-purple (bottom-right)
                  Positioned(
                    top: -150,
                    left: -150,
                    child: _blob(480, AppColors.airaTeal.withValues(alpha: 0.15)),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -80,
                    child: _blob(400, AppColors.atriumIndigo.withValues(alpha: 0.12)),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: AppColors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: Stack(
                          children: [
                            // .typo-bleed
                            Positioned(
                              top: -20,
                              right: -20,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0.05,
                                  child: Text(
                                    bleedText,
                                    style: const TextStyle(
                                      color: AppColors.atriumIndigo,
                                      fontSize: 110,
                                      fontWeight: FontWeight.w900,
                                      height: 0.8,
                                    ).copyWith(fontFamily: 'Plus Jakarta Sans'),
                                  ),
                                ),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // .form-rule
                                  Container(
                                    width: 64,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 32),
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.recoveryButtonGradient,
                                    ),
                                  ),
                                  child,
                                  const SizedBox(height: 32),
                                  Center(
                                    child: TextButton(
                                      onPressed: onBack,
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.arrow_back, size: 16, color: AppColors.atriumIndigo),
                                          const SizedBox(width: 8),
                                          Text(
                                            backLabel.toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.atriumIndigo,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ).copyWith(fontFamily: 'Plus Jakarta Sans'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _CompactFooter(),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

/// .compact-header, collapsed to its mobile rendering (brand text + the
/// grayscale "powered by" logo only — the pill/subtitle/divider are
/// `display: none` under 980px in globals.css).
class _CompactHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xB8F5FAF8), // rgba(245,250,248,0.72)
            border: Border(bottom: BorderSide(color: AppColors.glassStroke)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppConstants.schoolName.toUpperCase()} SCHOOL',
                style: const TextStyle(
                  color: AppColors.atriumIndigo,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ).copyWith(fontFamily: 'Plus Jakarta Sans'),
              ),
              Opacity(
                opacity: 0.65,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.asset(
                    AppConstants.eskooliaLogo,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// .compact-footer, collapsed to its mobile (column) rendering.
class _CompactFooter extends StatelessWidget {
  const _CompactFooter();

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: AppColors.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ).copyWith(fontFamily: 'Plus Jakarta Sans'),
              children: [
                const TextSpan(text: '© 2024 '),
                TextSpan(
                  text: '${AppConstants.schoolName} Institutional Node',
                  style: const TextStyle(color: AppColors.atriumIndigo),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: const [
              Text('PRIVACY', style: linkStyle),
              Text('TERMS', style: linkStyle),
              Text('SUPPORT', style: TextStyle(
                color: AppColors.surfaceTint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              )),
            ],
          ),
        ],
      ),
    );
  }
}
