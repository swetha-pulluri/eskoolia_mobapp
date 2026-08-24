import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import '../../../../config/router/app_router.dart';
import '../../../../config/router/portal_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';

// Precisely measured from the source asset itself (not eyeballed) — the PNG
// is a square 1254×1254 canvas, RGB with no alpha channel (fully opaque),
// filled with a flat #FAFAFA background outside the logo. Scanning the raw
// pixel data for the bounding box of non-background pixels gives the exact
// region the actual "eSkoolia" wordmark + mascot icon occupies within that
// canvas.
const double _logoLeftFrac = 0.0542;
const double _logoTopFrac = 0.2823;
const double _logoWidthFrac = 0.8931;
const double _logoHeightFrac = 0.3892;

// Single split between the mascot face (top) and the "eSkoolia" wordmark
// (bottom) within that content region — measured by scanning row-by-row ink
// width. Deliberately the SAME value for both the mascot's `sliceBottom` and
// the letters' `sliceTop` (no overlap band): the mascot's glasses double as
// the wordmark's two "o"s, so any overlap made that shared region get drawn,
// scaled and faded independently by *two* animated layers at once — visible
// as a wobbling "cut" double-image right at the "o"s during the reveal, even
// though at rest the duplicate pixels lined up perfectly. Splitting at one
// exact boundary means every pixel is owned by exactly one animated layer.
const double _mascotBottomFrac = 0.47;
const double _wordmarkTopFrac = 0.47;

// The wordmark's letters are drawn touching/overlapping (a joined, rounded
// logotype — there is no fully-blank column anywhere across "eSkoolia"), so
// a literal per-letter cut is impossible without recreating the artwork.
// These 8 boundaries were instead found by scanning per-column ink density
// across the wordmark and locating its 7 lowest-ink dips (the thin
// connecting strokes between letters) — in left-to-right order they line up
// exactly with the 8 letters "e S k o o l i a", so each span below is that
// letter's own measured slice of the real logo pixels, not a guess.
const List<double> _letterBoundaries = [0.0, 0.134, 0.3315, 0.3843, 0.4424, 0.5317, 0.6363, 0.8007, 1.0];

// The asset's own flat background colour, sampled directly from its corner
// pixel (measured, not guessed) — chroma-keyed out at runtime below so only
// the logo itself ever paints, never the rectangular canvas around it.
const double _bgR = 250, _bgG = 250, _bgB = 250;
const double _chromaThreshold = 40; // distance below which a pixel counts as background
const double _chromaFeather = 30; // extra distance over which alpha ramps in, for a soft/anti-aliased cutout edge instead of a jagged one

// The logo is never displayed wider than 340 logical pixels (see
// `logoWidth`'s clamp in `build()`); at up to a ~3x device pixel ratio that's
// ~1020 physical pixels for the whole canvas. 720 stays comfortably above
// that for the actual logo *content* (which is smaller than the full canvas
// margin-to-margin) while cutting the source's native 1254×1254 down to
// roughly a third of the pixels the chroma-key scan has to touch.
const int _chromaKeyWorkingSize = 720;

// The logo itself is a cool, saturated blue. A warm, light backdrop (not
// another blue/purple) is what actually makes it pop via contrast, rather
// than blending into a same-family gradient — a soft ivory-to-champagne
// wash, with a touch of warm gold in the glass light effects.
const Color _bgWarmTop = Color(0xFFFFFFFF);
const Color _bgWarmMid = Color(0xFFFDF6EA);
const Color _bgWarmBottom = Color(0xFFF7EAD2);
const Color _glassGold = Color(0xFFE8C777);

/// Decodes the logo PNG's own bytes and makes every background-coloured
/// pixel transparent (with a soft feathered edge near the logo's own
/// strokes), returning a *re-encoded* PNG's bytes. This never touches the
/// asset file on disk and never alters a single logo pixel's colour — it
/// only ever changes the *alpha* of pixels that already match the known
/// flat background colour.
///
/// `encodePng(..., level: 0, filter: PngFilter.none)` — the package's own
/// default (`level: 6`, Paeth filtering) runs real zlib DEFLATE compression
/// plus per-scanline filtering over the full ~6.3MB buffer, both for
/// nothing: this PNG is never written to disk or sent anywhere, it's handed
/// straight back to the caller and immediately decoded again by
/// `Image.memory`. Skipping that saves real time on every call.
///
/// Runs synchronously on the calling isolate (not via `compute()`) — an
/// earlier attempt to run this off-thread via `compute()` as a background
/// upgrade caused the splash to get stuck and never navigate at all, because
/// whatever `compute()` does on this platform/SDK combination interfered
/// with the animation ticker instead of staying safely off it. Run inline,
/// the worst case if this loop is ever slow on a given device is a
/// proportionally delayed splash (still bounded, still eventually
/// completes) — never a permanent hang, since there's no concurrent
/// Future/isolate race involved at all.
///
/// Resizes to [_chromaKeyWorkingSize] before the per-pixel scan — this was
/// the actual cause of the multi-second-to-multi-minute delay this function
/// used to have on a slow/interpreted runtime (Flutter Web's debug-mode DDC
/// in particular): the source PNG is a fixed 1254×1254 canvas, but the logo
/// is only ever displayed at a max width of ~340 logical pixels, so scanning
/// all ~1.57M source pixels one at a time did roughly 10-20× more work than
/// what's ever actually visible on screen. `_chromaKeyWorkingSize` is picked
/// comfortably above the largest real on-screen size (accounting for a
/// ~3x device pixel ratio), so this costs nothing in visible sharpness.
Uint8List _chromaKeyLogoBytes(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) return sourceBytes;
  final resized = decoded.width > _chromaKeyWorkingSize || decoded.height > _chromaKeyWorkingSize
      ? img.copyResize(decoded, width: _chromaKeyWorkingSize, height: _chromaKeyWorkingSize, interpolation: img.Interpolation.average)
      : decoded;
  final rgba = resized.numChannels == 4 ? resized : resized.convert(numChannels: 4);
  final bytes = rgba.getBytes(order: img.ChannelOrder.rgba);

  for (var i = 0; i < bytes.length; i += 4) {
    final dist = ((bytes[i] - _bgR).abs() + (bytes[i + 1] - _bgG).abs() + (bytes[i + 2] - _bgB).abs()) / 3;
    if (dist <= _chromaThreshold) {
      bytes[i + 3] = 0;
    } else if (dist <= _chromaThreshold + _chromaFeather) {
      bytes[i + 3] = (255 * (dist - _chromaThreshold) / _chromaFeather).round();
    }
  }

  final result = img.Image.fromBytes(
    width: rgba.width,
    height: rgba.height,
    bytes: bytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return img.encodePng(result, level: 0, filter: img.PngFilter.none);
}

/// App entry splash screen — the very first thing shown on cold start,
/// before `/login` or the user's own home route. A fixed-duration logo
/// reveal that also waits for `checkAuthStatus()` (triggered once in
/// `main.dart`'s `MyApp.initState`, and shared here via the same
/// `authNotifierProvider` singleton) to actually resolve, then navigates
/// straight to the correct destination itself — an already-authenticated
/// user goes directly to their portal's home route, everyone else goes to
/// `/login`. Deliberately not "always go to `/login` and let the router
/// bounce an authenticated user onward afterwards": that used to race the
/// splash's own fixed timer against the async auth check, so whichever
/// finished first decided what the *first frame after splash* looked
/// like — often a visible flash of the login screen immediately before
/// bouncing to home. Waiting for both here removes that race entirely.
///
/// A `next` query param (set by `app_router.dart`'s `redirect` whenever it
/// forced a mid-session location through `/splash` — e.g. a Flutter Web hot
/// restart/refresh while already deep-linked past login) takes priority
/// over the auth-based destination above when present, so the user lands
/// back where they actually were instead of being redirected to their
/// portal home.
///
/// Reveal choreography (all driven off the *same* unaltered logo pixels,
/// sliced into rectangles and never redrawn): the mascot fades in first,
/// then the 8 measured letter slices of "eSkoolia" cascade in left-to-right,
/// each with its own staggered fade, so the wordmark visibly assembles
/// letter by letter without ever recreating it as text. Fade-only (no
/// scale/slide) deliberately — see `_mascotBottomFrac`/`_wordmarkTopFrac`.
/// Once fully revealed, one soft diagonal light sweep crosses the logo,
/// then it holds, still and fully visible, until the 5-second-plus floor
/// elapses.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _mascotFade;
  late final List<Animation<double>> _letterFade;
  late final Animation<double> _wholeLogoFade;
  late final Animation<double> _wholeLogoScale;

  late final AnimationController _sweepController;
  late final Animation<double> _sweep;

  Uint8List? _transparentLogoBytes;
  // Only true once the chroma-key pass actually succeeded — the letter-by-
  // letter cascade below relies on each letter's box having a transparent
  // background; on the raw (non-keyed) fallback, each box's flat opaque
  // background would instead pop in as a visible rectangle in the wrong-
  // looking order, so that fallback shows one simple whole-logo fade instead.
  bool _isTransparent = false;
  // True when a school has its own logo cached locally (Settings → School
  // Info → Branding) — shown via a plain fade+scale instead of the
  // eSkoolia-specific chroma-key/letter-cascade below, since the crop
  // fractions that cascade relies on are measured against the eSkoolia
  // asset's own canvas and don't apply to an arbitrary uploaded logo.
  bool _useSchoolLogo = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ~3.4s for the mascot + letter cascade, leaving a ~1.1s hold after the
    // 500ms light-sweep, inside the 5-second total splash duration — all the
    // Interval fractions below scale automatically with this duration.
    _revealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
    // Fade only — deliberately no scale or slide here. The mascot's glasses
    // are the same pixels as the wordmark's two "o"s, so the mascot box and
    // the letter boxes share a boundary right through that shape. Any
    // independent transform (scale, translate) on either side of that
    // boundary makes the shared edge grow/move at a different rate on each
    // side, which showed up as a visible "cut" seam through the O's mid-
    // animation — a fade only ever changes opacity, never size or position,
    // so nothing can misalign at the boundary no matter the timing.
    _mascotFade = CurvedAnimation(parent: _revealController, curve: const Interval(0.0, 0.10, curve: Curves.easeOut));

    // 8 letters, each one now clearly finishing (or nearly so) before the
    // next starts — a ~480ms gap between starts vs. a ~600ms fade each,
    // instead of the previous fast/overlapping cascade.
    final letterCount = _letterBoundaries.length - 1;
    const stagger = 0.105;
    const letterDuration = 0.13;
    const firstStart = 0.10;
    _letterFade = [];
    for (var i = 0; i < letterCount; i++) {
      final start = firstStart + i * stagger;
      final end = (start + letterDuration).clamp(0.0, 1.0);
      _letterFade.add(CurvedAnimation(parent: _revealController, curve: Interval(start, end, curve: Curves.easeOut)));
    }

    // Used only for the raw-fallback path (chroma-key failed/timed out): one
    // simple fade + scale of the whole logo, over roughly the same span the
    // mascot+letters would otherwise have taken.
    _wholeLogoFade = CurvedAnimation(parent: _revealController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _wholeLogoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    _sweepController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _sweep = CurvedAnimation(parent: _sweepController, curve: Curves.easeInOut);

    // Navigation waits on the hard floor timer, the full splash sequence
    // actually finishing, AND `checkAuthStatus()` resolving — not the timer
    // alone. Crucially, the reveal animation itself doesn't start until the
    // logo has finished loading (see `_runSplashSequence`): starting it
    // immediately at launch would let its clock run *while the image is
    // still loading* — the controller could already be well past several
    // letters' reveal windows by the time there's anything to paint, so the
    // first visible frame would already show most letters "done" instead of
    // a clean cascade. 5s total, per explicit request.
    final floor = Future<void>.delayed(const Duration(milliseconds: 5000));
    final sequenceDone = _runSplashSequence();
    // Also wait for `checkAuthStatus()` (triggered in `main.dart`) to
    // actually resolve, so the destination below reflects its real outcome
    // instead of racing it — see the class doc for why. Deliberately no
    // extra timeout wrapper here: `checkAuthStatus()`'s own network call
    // (`GET /auth/me/`) can legitimately take close to `ApiConstants`'s own
    // 30s connect/receive timeouts on a slow/cold connection (e.g. right
    // after a hot restart, before the OS network stack has "warmed up") —
    // a splash-side timeout shorter than that raced ahead of a still-
    // loading, but perfectly healthy, auth check and fell back to `/login`
    // while it was still resolving, which is exactly the bug this whole
    // wait exists to prevent. `checkAuthStatus()` is guaranteed to settle
    // to a terminal state on its own regardless (see `AuthNotifier`), so
    // there is nothing to bound here beyond that.
    final authResolved = _waitForAuthResolved();
    Future.wait([floor, sequenceDone, authResolved]).then((_) {
      if (!mounted || _navigated) return;
      _navigated = true;
      // Marks the forced-splash handoff as genuinely complete — until this
      // flips, `app_router.dart`'s `redirect` keeps bouncing any location
      // back to `/splash` (including a race from `checkAuthStatus()`
      // resolving mid-splash), so this must be set *before* navigating away
      // or that same redirect would just force this page right back open.
      ref.read(splashHandoffDoneProvider.notifier).state = true;

      // `next` takes priority when present — it means the router forced a
      // mid-session location through `/splash` (see class doc), so the user
      // should land back where they actually were rather than at their
      // portal home.
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      if (next != null && next.isNotEmpty) {
        context.go(next);
        return;
      }
      final destination = ref.read(authNotifierProvider).maybeWhen(
        authenticated: (user) => resolveHomeRouteForPortal(user.portalType),
        orElse: () => '/login',
      );
      context.go(destination);
    });
  }

  /// Completes as soon as `authNotifierProvider`'s state leaves
  /// `AuthState.initial()` — i.e. `checkAuthStatus()` has produced a real
  /// answer. Resolves immediately if that has already happened by the time
  /// this runs.
  Future<void> _waitForAuthResolved() {
    final isInitial = ref.read(authNotifierProvider).maybeWhen(initial: () => true, orElse: () => false);
    if (!isInitial) return Future.value();

    final completer = Completer<void>();
    late final ProviderSubscription<AuthState> subscription;
    subscription = ref.listenManual(authNotifierProvider, (previous, next) {
      final stillInitial = next.maybeWhen(initial: () => true, orElse: () => false);
      if (!stillInitial && !completer.isCompleted) {
        completer.complete();
        subscription.close();
      }
    });
    return completer.future;
  }

  Future<void> _runSplashSequence() async {
    await _loadLogo();
    if (!mounted) return;
    await _revealController.forward();
    if (!mounted) return;
    await _sweepController.forward();
  }

  /// Prefers the currently logged-in school's own cached logo (downloaded
  /// by `BrandingNotifier.syncFromUser` on a previous auth resolution) over
  /// the static eSkoolia asset — so a school that has configured a logo
  /// sees its own branding on this very first frame, cache-first with no
  /// network round trip. Falls back to the eSkoolia asset + chroma-key
  /// reveal (unchanged) when no school logo is cached yet.
  Future<void> _loadLogo() async {
    final schoolLogoFile = ref.read(brandingNotifierProvider).logoFile;
    if (schoolLogoFile != null) {
      try {
        final bytes = await schoolLogoFile.readAsBytes();
        if (mounted) {
          setState(() {
            _transparentLogoBytes = bytes;
            _isTransparent = false;
            _useSchoolLogo = true;
          });
        }
        return;
      } catch (e) {
        debugPrint('[SplashPage] failed to read cached school logo, falling back to eSkoolia asset: $e');
      }
    }
    await _loadTransparentLogo();
  }

  Future<void> _loadTransparentLogo() async {
    try {
      final data = await rootBundle.load(AppConstants.eskooliaLogo);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      Uint8List? transparent;
      try {
        final stopwatch = Stopwatch()..start();
        transparent = _chromaKeyLogoBytes(bytes);
        debugPrint('[SplashPage] chroma-key took ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        debugPrint('[SplashPage] chroma-key failed, showing raw logo instead: $e');
        transparent = null;
      }
      if (mounted) {
        setState(() {
          _transparentLogoBytes = transparent ?? bytes;
          _isTransparent = transparent != null;
        });
      }
    } catch (e, st) {
      debugPrint('[SplashPage] failed to load logo asset: $e\n$st');
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: the logo lockup is wide (~2.3:1), so it's sized off
    // screen width rather than a square footprint, clamped so it neither
    // shrinks too small on compact phones nor grows oversized on tablets.
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final logoWidth = (shortestSide * 0.62).clamp(200.0, 340.0);
    final logoBytes = _transparentLogoBytes;
    final logoHeight = _logoHeightFrac * (logoWidth / _logoWidthFrac);
    final mascotSliceHeight = _mascotBottomFrac * logoHeight;
    final wordmarkTopOffset = _wordmarkTopFrac * logoHeight;
    final wordmarkHeight = (1.0 - _wordmarkTopFrac) * logoHeight;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Base background — a warm ivory-to-champagne wash (no
          // blue/purple), chosen to contrast with, not blend into, the
          // logo's own cool blue.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgWarmTop, _bgWarmMid, _bgWarmBottom],
              ),
            ),
          ),
          // Soft, blurred ambient "glass" light — large blurred circles in
          // white and a touch of warm gold, sitting behind the logo. This
          // is the glassmorphism *background* only; the logo itself is
          // never placed inside a glass card/panel.
          Positioned(
            top: -80,
            left: -60,
            child: _glassOrb(diameter: 260, color: Colors.white.withValues(alpha: 0.8)),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _glassOrb(diameter: 320, color: _glassGold.withValues(alpha: 0.22)),
          ),
          Positioned(
            top: 120,
            right: -90,
            child: _glassOrb(diameter: 220, color: Colors.white.withValues(alpha: 0.6)),
          ),
          SafeArea(
            child: Center(
              // Briefly empty (just the background) for the short moment
              // the chroma-key pass takes to finish — negligible against
              // the 5-second floor, and far better than ever showing the
              // logo's original rectangular background even for one frame.
              child: logoBytes == null
                  ? const SizedBox.shrink()
                  : AnimatedBuilder(
                      animation: Listenable.merge([_revealController, _sweepController]),
                      builder: (context, child) {
                        return ShaderMask(
                          // `srcATop`: paints the gradient over the logo
                          // using the *gradient's own alpha* — transparent
                          // stops leave the original logo pixels completely
                          // untouched, so the highlight only ever brightens
                          // a narrow moving band instead of replacing
                          // colour.
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (bounds) {
                            // A single soft diagonal highlight band, swept
                            // once left-to-right across the completed logo.
                            // Both ends of the sweep sit well outside the
                            // visible bounds (±1.5 alignment) so the logo
                            // shows with no highlight at all before/after
                            // it passes.
                            final t = _sweep.value;
                            final center = -1.5 + 3.0 * t;
                            return LinearGradient(
                              begin: Alignment(center - 0.4, -1),
                              end: Alignment(center + 0.4, 1),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds);
                          },
                          child: child,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _revealController,
                        builder: (context, child) {
                          if (_useSchoolLogo) {
                            // A school's own uploaded logo has no known
                            // crop margin/background color, so it's shown
                            // as-is (no `_LogoRegion` slicing, no chroma
                            // key) — just the same fade+scale reveal the
                            // raw-fallback path below already uses.
                            return FadeTransition(
                              opacity: _wholeLogoFade,
                              child: ScaleTransition(
                                scale: _wholeLogoScale,
                                child: SizedBox(
                                  width: logoWidth,
                                  height: logoWidth,
                                  child: Image.memory(
                                    logoBytes,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (!_isTransparent) {
                            // Chroma-key didn't complete in time (or at
                            // all): the letter-cascade below relies on each
                            // letter's box being transparent outside its
                            // strokes — on the raw asset each box's flat
                            // background would instead pop in as a visible
                            // rectangle, in a confusing order. One plain
                            // fade + scale of the whole logo avoids that.
                            return FadeTransition(
                              opacity: _wholeLogoFade,
                              child: ScaleTransition(
                                scale: _wholeLogoScale,
                                child: _LogoRegion(
                                  bytes: logoBytes,
                                  contentWidth: logoWidth,
                                  sliceTop: 0.0,
                                  sliceBottom: 1.0,
                                ),
                              ),
                            );
                          }
                          // A single `Stack` at each layer's *true* absolute
                          // position within the full logo (not a `Column`
                          // stacking two independently-sized boxes with a
                          // gap, which duplicated their shared border row).
                          // The mascot and the letter boxes meet at one exact
                          // boundary (`_mascotBottomFrac == _wordmarkTopFrac`
                          // — the mascot's glasses double as the wordmark's
                          // two "o"s, right at that seam) and reveal via
                          // fade only, deliberately with no scale/slide: any
                          // independent transform on either side of that
                          // boundary would grow or move the shared edge at a
                          // different rate on each side, which is what
                          // caused the visible "cut" through the O's before.
                          return SizedBox(
                            width: logoWidth,
                            height: logoHeight,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  width: logoWidth,
                                  height: mascotSliceHeight,
                                  child: FadeTransition(
                                    opacity: _mascotFade,
                                    child: _LogoRegion(
                                      bytes: logoBytes,
                                      contentWidth: logoWidth,
                                      sliceTop: 0.0,
                                      sliceBottom: _mascotBottomFrac,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: wordmarkTopOffset,
                                  left: 0,
                                  width: logoWidth,
                                  height: wordmarkHeight,
                                  child: Stack(
                                    children: [
                                      for (var i = 0; i < _letterBoundaries.length - 1; i++)
                                        Positioned(
                                          left: _letterBoundaries[i] * logoWidth,
                                          top: 0,
                                          width: (_letterBoundaries[i + 1] - _letterBoundaries[i]) * logoWidth,
                                          height: wordmarkHeight,
                                          child: FadeTransition(
                                            opacity: _letterFade[i],
                                            child: _LogoRegion(
                                              bytes: logoBytes,
                                              contentWidth: logoWidth,
                                              sliceLeft: _letterBoundaries[i],
                                              sliceRight: _letterBoundaries[i + 1],
                                              sliceTop: _wordmarkTopFrac,
                                              sliceBottom: 1.0,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassOrb({required double diameter, required Color color}) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Renders one rectangular region of the chroma-keyed logo image — a
/// fraction box [sliceLeft]..[sliceRight] × [sliceTop]..[sliceBottom] of the
/// logo's own content area (not the full canvas, which also includes the
/// background margin) — at [contentWidth] on screen. The full image is laid
/// out at a larger-than-displayed size (so the *whole* content region, at
/// that scale, matches [contentWidth]), then shifted so the requested
/// region lands at the visible box's origin; everything else is clipped
/// away. The scale is uniform in both axes (the source image is square),
/// so nothing is ever stretched, distorted, recoloured, or recreated — same
/// logo pixels as the original asset throughout, just with the flat
/// background made transparent.
class _LogoRegion extends StatelessWidget {
  final Uint8List bytes;
  final double contentWidth;
  final double sliceLeft;
  final double sliceRight;
  final double sliceTop;
  final double sliceBottom;

  const _LogoRegion({
    required this.bytes,
    required this.contentWidth,
    this.sliceLeft = 0.0,
    this.sliceRight = 1.0,
    required this.sliceTop,
    required this.sliceBottom,
  });

  @override
  Widget build(BuildContext context) {
    final fullSide = contentWidth / _logoWidthFrac;
    final contentHeightPx = _logoHeightFrac * fullSide;
    final sliceWidth = (sliceRight - sliceLeft) * contentWidth;
    final sliceHeight = (sliceBottom - sliceTop) * contentHeightPx;
    final offsetX = (_logoLeftFrac * fullSide) + (sliceLeft * contentWidth);
    final offsetY = (_logoTopFrac * fullSide) + (sliceTop * contentHeightPx);

    return ClipRect(
      child: SizedBox(
        width: sliceWidth,
        height: sliceHeight,
        child: Stack(
          children: [
            Positioned(
              left: -offsetX,
              top: -offsetY,
              width: fullSide,
              height: fullSide,
              child: Image.memory(bytes, fit: BoxFit.fill, gaplessPlayback: true),
            ),
          ],
        ),
      ),
    );
  }
}
