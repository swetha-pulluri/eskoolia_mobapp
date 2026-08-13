import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// School-themed static PNG icons (assets/icons/) cycled across the
/// falling particles below.
const List<String> _particleAssets = [
  'assets/icons/book.png',
  'assets/icons/bag.png',
  'assets/icons/cap.png',
  'assets/icons/bus.png',
  'assets/icons/pencil.png',
  'assets/icons/openbook.png',
  'assets/icons/calculator.png',
  'assets/icons/graduation.png',
  'assets/icons/school.png',
  'assets/icons/teacher.png',
];

/// Subtle, purely decorative "falling particles" overlay for the Home
/// screen — small, low-opacity, brand-purple-tinted school-themed icons
/// that drift slowly downward with a gentle side-to-side sway, each
/// looping back to the top at a fresh random position once it exits the
/// bottom (like gentle rain, never in lockstep with each other).
///
/// The caller places this as the *last* child of a `Stack` (sized via
/// `Positioned.fill`) so it floats visually in front of the real screen
/// content — but it's wrapped in [IgnorePointer] so it can never intercept
/// a tap/scroll meant for that content despite being on top, and in
/// [RepaintBoundary] so its continuous animation never forces the actual
/// Home screen content to repaint alongside it.
class HomeAmbientParticles extends StatefulWidget {
  const HomeAmbientParticles({super.key});

  @override
  State<HomeAmbientParticles> createState() => _HomeAmbientParticlesState();
}

class _HomeAmbientParticlesState extends State<HomeAmbientParticles>
    with TickerProviderStateMixin {
  // One particle per icon — plain static images are cheap to composite
  // repeatedly (no per-frame vector decoding like an animated composition
  // would need), so this stays a straightforward 1:1 mapping.
  static final int _particleCount = _particleAssets.length;

  final _random = Random();
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _particleCount; i++) {
      final particle = _Particle(
        asset: _particleAssets[i],
        controller: AnimationController(
          vsync: this,
          duration: _randomFallDuration(),
        ),
      );
      _randomizeCycle(particle);
      particle.controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _randomizeCycle(particle);
          particle.controller.duration = _randomFallDuration();
          particle.controller.forward(from: 0);
        }
      });
      // Start already mid-fall at a random phase so the particles don't
      // all begin their descent from the top in lockstep.
      particle.controller.forward(from: _random.nextDouble());
      _particles.add(particle);
    }
  }

  Duration _randomFallDuration() =>
      Duration(milliseconds: 14000 + _random.nextInt(12000));

  void _randomizeCycle(_Particle p) {
    p.startXFraction = _random.nextDouble();
    p.size = 22 + _random.nextDouble() * 16; // 22-38 logical px — small
    p.opacity = 0.10 + _random.nextDouble() * 0.14; // 0.10-0.24 — subtle
    p.swayAmplitude = 8 + _random.nextDouble() * 16;
    p.swayCycles = 1 + _random.nextDouble(); // 1-2 side-to-side sways per fall
    p.swayPhase = _random.nextDouble() * 2 * pi;
  }

  @override
  void dispose() {
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Falls the full available height (whatever screen size this
            // Home screen happens to render at) plus one particle's worth
            // of overshoot above/below, so it works unchanged across phone
            // sizes rather than assuming a fixed height.
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final p in _particles)
                  AnimatedBuilder(
                    animation: p.controller,
                    builder: (context, child) {
                      final t = p.controller.value;
                      final top = -p.size + t * (height + p.size * 2);
                      final sway =
                          sin(t * 2 * pi * p.swayCycles + p.swayPhase) *
                          p.swayAmplitude;
                      final left = p.startXFraction * (width - p.size) + sway;
                      return Positioned(
                        top: top,
                        left: left,
                        width: p.size,
                        height: p.size,
                        child: Opacity(opacity: p.opacity, child: child),
                      );
                    },
                    // Passed as `child`, not rebuilt by AnimatedBuilder on
                    // every tick — only the Positioned/Opacity wrapper
                    // above is recomputed per frame. Tinted to the
                    // Eskoolia brand purple (srcIn treats the source PNG
                    // as an alpha mask) so every icon reads as one
                    // consistent "brand" silhouette regardless of its own
                    // original artwork color.
                    child: Image.asset(
                      p.asset,
                      fit: BoxFit.contain,
                      color: AppColors.brandPurple,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final String asset;
  final AnimationController controller;
  double startXFraction = 0;
  double size = 28;
  double opacity = 0.15;
  double swayAmplitude = 12;
  double swayCycles = 1;
  double swayPhase = 0;

  _Particle({required this.asset, required this.controller});
}
