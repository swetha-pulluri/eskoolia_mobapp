import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/attendance_pulse_entity.dart';
import '../providers/dashboard_provider.dart';

// Exact web hex values (frontend/components/widgets/pulse/
// AttendanceSnapshot.tsx) — not the app's own approximate design tokens —
// since this card is a 1:1 port of that real component.
const Color _iconBg = Color(0xFFEEEAFF);
const Color _donutTrack = Color(0xFFEEEAFF);
const Color _donutFill = Color(0xFF6D4AFF);
const Color _lateDot = Color(0xFF94A3B8);
const Color _pendingBg = Color(0xFFFFFBEB);
const Color _pendingBorder = Color(0xFFF59E0B);
const Color _pendingHeading = Color(0xFF92400E);
const Color _pendingBadgeBg = Color(0xFFFEF3C7);
const Color _pendingBadgeText = Color(0xFFD97706);
const Color _sparkBarActive = Color(0xFF6D4AFF);
const Color _sparkBarInactive = Color(0xFFEEEAFF);
const Color _errorBg = Color(0xFFFEF2F2);
const Color _errorBorder = Color(0xFFFDD8D8);
const Color _errorHeading = Color(0xFFC2264E);
const Color _errorMessage = Color(0xFF8B5D6F);
const Color _shimmerA = Color(0xFFF0F0F6);
const Color _shimmerB = Color(0xFFE0E0E8);

/// Home screen → "Today's Pulse" → Student Attendance card — a 1:1 port of
/// `frontend/components/widgets/pulse/AttendanceSnapshot.tsx`: donut chart +
/// Present/Absent/Leave/Late stat rows, the "attendance pending → nudge
/// teachers" banner, the 5-day trend sparkbar, and the "marked at" footer —
/// not a mobile-only redesign. On web this lives in a left rail hidden
/// below 1024px viewport width (no existing mobile layout to copy) — placed
/// inline on the Home screen here instead, same content/data/behavior.
class AttendancePulseCard extends ConsumerStatefulWidget {
  const AttendancePulseCard({super.key});

  @override
  ConsumerState<AttendancePulseCard> createState() => _AttendancePulseCardState();
}

class _AttendancePulseCardState extends ConsumerState<AttendancePulseCard> {
  bool _nudging = false;

  /// Mirrors `AttendanceSnapshot.tsx`'s `nudge()` exactly: there is no real
  /// nudge/notification backend endpoint (confirmed absent from the actual
  /// Django app) — the web's own handler just re-fetches the dashboard and
  /// resets the button, with no toast or confirmation of any kind. This is
  /// a known stub on both platforms, not a bug to "complete" here.
  Future<void> _nudge(AttendancePulseEntity data) async {
    if (_nudging || data.pendingClasses.isEmpty) return;
    setState(() => _nudging = true);
    try {
      ref.invalidate(attendancePulseProvider);
      await ref.read(attendancePulseProvider.future);
    } catch (_) {
      // Matches web's empty catch block.
    } finally {
      if (mounted) setState(() => _nudging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pulseAsync = ref.watch(attendancePulseProvider);

    return pulseAsync.when(
      loading: () => _shell(child: const _PulseSkeleton(), onTap: null),
      error: (error, _) => _shell(
        child: _ErrorState(message: error.toString(), onRetry: () => ref.invalidate(attendancePulseProvider)),
        onTap: null,
      ),
      data: (data) => _shell(
        child: _PulseContent(data: data, nudging: _nudging, onNudge: () => _nudge(data)),
        onTap: () {
          recordModuleVisit(ref, '/attendance/student');
          context.push('/attendance/student');
        },
      ),
    );
  }

  Widget _shell({required Widget child, required VoidCallback? onTap}) {
    final card = PremiumCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      radius: 16,
      color: Colors.white,
      borderColor: AppColors.border.withValues(alpha: 0.8),
      borderWidth: 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
    // Only give the press-scale feedback when the card is actually
    // tappable (skeleton/error states pass onTap: null).
    return onTap == null ? card : TapScale(child: card);
  }
}

class _PulseContent extends StatelessWidget {
  final AttendancePulseEntity data;
  final bool nudging;
  final VoidCallback onNudge;

  const _PulseContent({required this.data, required this.nudging, required this.onNudge});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final showPending = data.pendingClasses.isNotEmpty && now.hour >= 10;
    final allTeachersMarked = data.totalTeachers > 0 && data.markedTeachers == data.totalTeachers;
    final maxBar = data.trend.isNotEmpty ? data.trend.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.people_alt_outlined, size: 11, color: AppColors.brandPurple),
            ),
            const SizedBox(width: 5),
            const Expanded(
              child: Text(
                'STUDENT ATTENDANCE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.6),
              ),
            ),
            const Icon(Icons.chevron_right, size: 13, color: AppColors.ink3),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Donut(percent: data.attendancePercentage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatRow(color: AppColors.success, label: 'Present', value: data.present),
                  const SizedBox(height: 6),
                  _StatRow(color: AppColors.error, label: 'Absent', value: data.absent),
                  const SizedBox(height: 6),
                  _StatRow(color: AppColors.warning, label: 'Leave', value: data.leave),
                  const SizedBox(height: 6),
                  _StatRow(color: _lateDot, label: 'Late', value: data.late),
                ],
              ),
            ),
          ],
        ),

        if (showPending) ...[
          const SizedBox(height: 10),
          _PendingBanner(pendingClasses: data.pendingClasses, nudging: nudging, onNudge: onNudge),
        ],

        if (data.trend.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < data.trend.length; i++) ...[
                if (i != 0) const SizedBox(width: 4),
                _MiniBar(value: data.trend[i], max: maxBar, highlight: i == data.trend.length - 1),
              ],
            ],
          ),
        ],

        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, size: 10, color: AppColors.ink3),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Marked at ${data.lastUpdated} · ${data.markedTeachers}/${data.totalTeachers} teachers',
                style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (allTeachersMarked) const Icon(Icons.check_circle, size: 10, color: AppColors.success),
          ],
        ),
      ],
    );
  }
}

/// Matches `DonutChart` in AttendanceSnapshot.tsx: r=40, stroke=10, on a
/// 96x96 canvas, percent shown with one decimal + a "present" caption
/// inside the ring.
class _Donut extends StatelessWidget {
  final double percent;

  const _Donut({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _DonutPainter(percent: percent.clamp(0, 100)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink1)),
              const Text('present', style: TextStyle(fontSize: 9, color: AppColors.ink3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;

  const _DonutPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(48, 48);
    const radius = 40.0;
    const stroke = 10.0;

    final track = Paint()
      ..color = _donutTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    if (percent > 0) {
      final fill = Paint()
        ..color = _donutFill
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * (percent / 100);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.percent != percent;
}

class _StatRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _StatRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink3))),
        Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink1)),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final List<PendingClassEntity> pendingClasses;
  final bool nudging;
  final VoidCallback onNudge;

  const _PendingBanner({required this.pendingClasses, required this.nudging, required this.onNudge});

  @override
  Widget build(BuildContext context) {
    final shown = pendingClasses.take(3).toList();
    final extra = pendingClasses.length - shown.length;

    return GestureDetector(
      // Absorbs taps so they never bubble up to the card's own
      // navigate-on-tap — matches web's `e.stopPropagation()`.
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _pendingBg, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: _pendingBorder, width: 3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFD97706)),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Attendance pending',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _pendingHeading),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final cls in shown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: _pendingBadgeBg, border: Border.all(color: _pendingBorder), borderRadius: BorderRadius.circular(12)),
                    child: Text(cls.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _pendingBadgeText)),
                  ),
                if (extra > 0) Text('+$extra more', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _pendingBadgeText, decoration: TextDecoration.underline)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: nudging ? null : onNudge,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _pendingBadgeBg,
                  foregroundColor: _pendingBadgeText,
                  side: const BorderSide(color: _pendingBorder),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.notifications_outlined, size: 12),
                label: Text(nudging ? 'Sending…' : 'Nudge teachers', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matches `MiniBar` in AttendanceSnapshot.tsx: max height 28, width 6,
/// last bar highlighted purple, others a light purple tint.
class _MiniBar extends StatelessWidget {
  final double value;
  final double max;
  final bool highlight;

  const _MiniBar({required this.value, required this.max, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final height = (value / max * 28).clamp(4.0, 28.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 28,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 6,
              height: height,
              decoration: BoxDecoration(color: highlight ? _sparkBarActive : _sparkBarInactive, borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(value.round().toString(), style: const TextStyle(fontSize: 9, color: AppColors.ink3)),
      ],
    );
  }
}

class _PulseSkeleton extends StatelessWidget {
  const _PulseSkeleton();

  Widget _bar(double height) => Container(
        height: height,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_shimmerA, _shimmerB]), borderRadius: BorderRadius.circular(6)),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 96, height: 96, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_shimmerA, _shimmerB]))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                _bar(16),
                if (i != 3) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _errorBg, border: Border.all(color: _errorBorder), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: _errorHeading),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed to load attendance data',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _errorHeading),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 11, color: _errorMessage)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _errorHeading,
                    backgroundColor: _errorBg,
                    side: const BorderSide(color: _errorHeading),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
