import 'package:flutter/material.dart';

/// Purely visual "press" feedback — scales its [child] down slightly while
/// a finger is down on it, and back to 1.0 on release/cancel.
///
/// Deliberately built on [Listener] rather than [GestureDetector]: a
/// [Listener] only observes raw pointer events and never joins the gesture
/// arena, so it can never intercept, delay, or steal a tap from whatever
/// real `onTap`/`InkWell`/`GestureDetector` already lives inside [child].
/// That keeps this a strictly additive presentation-layer wrapper — no
/// existing tap/navigation logic is touched by adding it around a card.
class TapScale extends StatefulWidget {
  final Widget child;

  const TapScale({super.key, required this.child});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
