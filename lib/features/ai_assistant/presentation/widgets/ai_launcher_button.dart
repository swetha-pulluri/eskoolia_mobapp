import 'package:flutter/material.dart';

/// Draws AIBot.tsx's 4-point sparkle SVG path
/// (`M16 3 L18.4 12.2 L27.6 14.6 L18.4 17 L16 26.2 L13.6 17 L4.4 14.6 L13.6 12.2 Z`
/// plus its two small accent dots), scaled from the source's 32x32 viewBox.
class _SparklePainter extends CustomPainter {
  final Color glow;
  const _SparklePainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32;
    Offset p(double x, double y) => Offset(x * scale, y * scale);

    final star = Path()
      ..moveTo(p(16, 3).dx, p(16, 3).dy)
      ..lineTo(p(18.4, 12.2).dx, p(18.4, 12.2).dy)
      ..lineTo(p(27.6, 14.6).dx, p(27.6, 14.6).dy)
      ..lineTo(p(18.4, 17).dx, p(18.4, 17).dy)
      ..lineTo(p(16, 26.2).dx, p(16, 26.2).dy)
      ..lineTo(p(13.6, 17).dx, p(13.6, 17).dy)
      ..lineTo(p(4.4, 14.6).dx, p(4.4, 14.6).dy)
      ..lineTo(p(13.6, 12.2).dx, p(13.6, 12.2).dy)
      ..close();

    final glowPaint = Paint()
      ..color = glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(star, glowPaint);

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Colors.white, Color(0xFFE9DEFB), Color(0xFFA78BFA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(star, gradientPaint);

    canvas.drawCircle(p(25, 7), 1.6 * scale, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(p(6, 24), 1.1 * scale, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => false;
}

const _orbRadialGradient = RadialGradient(
  center: Alignment(-0.4, -0.44),
  colors: [Color(0xFF3A2A82), Color(0xFF150D3A), Color(0xFF0A0820)],
  stops: [0.0, 0.6, 1.0],
);

/// Mirrors AIBot.tsx's floating launcher button exactly: a dark purple orb
/// with a rotating conic-gradient halo ring, a pulsing sparkle glyph, and an
/// orbiting particle — all CSS keyframe animations there, `AnimationController`s
/// here.
class AiLauncherButton extends StatefulWidget {
  final VoidCallback onTap;

  const AiLauncherButton({super.key, required this.onTap});

  @override
  State<AiLauncherButton> createState() => _AiLauncherButtonState();
}

class _AiLauncherButtonState extends State<AiLauncherButton> with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _spinRevCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat();
    _spinRevCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _spinRevCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _orbRadialGradient,
              boxShadow: [
                BoxShadow(color: const Color(0xFF5836E0).withValues(alpha: 0.55), blurRadius: 32, offset: const Offset(0, 14), spreadRadius: -10),
                BoxShadow(color: const Color(0xFF0E1020).withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _spinCtrl,
                  child: Opacity(
                    opacity: 0.85,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF7C5BFF),
                            Color(0xFFA78BFA),
                            Colors.transparent,
                            Color(0xFF5836E0),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.25, 0.4, 0.6, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(1),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _orbRadialGradient),
                  ),
                ),
                ScaleTransition(
                  scale: _pulseScale,
                  child: CustomPaint(size: const Size(30, 30), painter: const _SparklePainter(glow: Color(0x99A78BFA))),
                ),
                RotationTransition(
                  turns: ReverseAnimation(_spinRevCtrl),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.white.withValues(alpha: 0.95), blurRadius: 8),
                            BoxShadow(color: const Color(0xFFA78BFA).withValues(alpha: 0.7), blurRadius: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
