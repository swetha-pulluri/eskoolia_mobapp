import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/attendance_pulse_entity.dart';
import '../providers/dashboard_provider.dart';
import '../theme/home_dark_theme.dart';

// Frosted-glass wash used for both the header icon chip and the donut's
// background track — translucent so it reads correctly against the Home
// screen's dark-purple gradient regardless of exactly where the card sits.
const Color _pulseIconBg = Color(0x26FFFFFF);
const Color _lateDot = Color(0xFF94A3B8); // no AppColors equivalent for this one
const Color _pendingBg = Color(0x26F59E0B);
const Color _pendingBorder = Color(0xFFF59E0B);
const Color _pendingHeading = Color(0xFFFBBF24);
const Color _pendingBadgeText = Color(0xFFFBBF24);
const Color _pendingBadgeBg = Color(0x33F59E0B);
const Color _errorBg = Color(0x26E0463A);
const Color _errorBorder = Color(0xFFE0463A);
const Color _errorText = Color(0xFFFF8A80);
const Color _shimmerA = Color(0x1AFFFFFF);
const Color _shimmerB = Color(0x33FFFFFF);

/// Home screen → "Today's Pulse" → Student Attendance card — a 1:1 port of
/// `frontend/components/widgets/pulse/AttendanceSnapshot.tsx`. On web this
/// lives in a left rail hidden below 1024px viewport width (no existing
/// mobile layout to copy) — placed inline on the Home screen here instead,
/// same content, adapted to a full-width mobile card.
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
      color: HomeDarkTheme.cardFill,
      borderColor: HomeDarkTheme.cardBorder,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(13), child: child),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: _pulseIconBg, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.brandPurple),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('STUDENT ATTENDANCE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: HomeDarkTheme.textSecondary, letterSpacing: 0.5)),
            ),
            const Icon(Icons.chevron_right, size: 16, color: HomeDarkTheme.textTertiary),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Donut(percent: data.attendancePercentage),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatRow(color: AppColors.success, label: 'Present', value: data.present),
                  _StatRow(color: AppColors.error, label: 'Absent', value: data.absent),
                  _StatRow(color: AppColors.warning, label: 'Leave', value: data.leave),
                  _StatRow(color: _lateDot, label: 'Late', value: data.late),
                ],
              ),
            ),
          ],
        ),
        if (showPending) ...[
          const SizedBox(height: 8),
          _PendingBanner(pendingClasses: data.pendingClasses, nudging: nudging, onNudge: onNudge),
        ],
        if (data.trend.isNotEmpty) ...[
          const SizedBox(height: 10),
          _TrendBars(trend: data.trend),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, size: 12, color: HomeDarkTheme.textTertiary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Marked at ${data.lastUpdated} · ${data.markedTeachers}/${data.totalTeachers} teachers',
                style: const TextStyle(fontSize: 10.5, color: HomeDarkTheme.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (allTeachersMarked) const Icon(Icons.check_circle, size: 13, color: AppColors.success),
          ],
        ),
      ],
    );
  }
}

class _Donut extends StatelessWidget {
  final double percent;

  const _Donut({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _DonutPainter(percent: percent.clamp(0, 100)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HomeDarkTheme.textPrimary)),
              const Text('present', style: TextStyle(fontSize: 8.5, color: HomeDarkTheme.textTertiary)),
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
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 10) / 2;
    final stroke = 8.0;

    final track = Paint()
      ..color = _pulseIconBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (percent > 0) {
      final fill = Paint()
        ..color = AppColors.brandPurple
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: HomeDarkTheme.textSecondary))),
          Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HomeDarkTheme.textPrimary)),
        ],
      ),
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
                Icon(Icons.warning_amber_rounded, size: 14, color: _pendingHeading),
                SizedBox(width: 6),
                Text('Attendance pending', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _pendingHeading)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _pendingBadgeBg, border: Border.all(color: _pendingBorder), borderRadius: BorderRadius.circular(999)),
                    child: Text(cls.name, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _pendingBadgeText)),
                  ),
                if (extra > 0) Text('+$extra more', style: const TextStyle(fontSize: 10.5, color: _pendingHeading)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.notifications_outlined, size: 14),
                label: Text(nudging ? 'Sending…' : 'Nudge teachers', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  final List<double> trend;

  const _TrendBars({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxVal = trend.fold<double>(1, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < trend.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 22 * (trend[i] / maxVal).clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      color: i == trend.length - 1 ? AppColors.brandPurple : Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(trend[i].round().toString(), style: const TextStyle(fontSize: 8.5, color: HomeDarkTheme.textTertiary)),
                ],
              ),
            ),
            if (i != trend.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_shimmerA, _shimmerB])),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < 4; i++) ...[
          _bar(10),
          if (i != 3) const SizedBox(height: 8),
        ],
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
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _errorBg, border: Border.all(color: _errorBorder), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 15, color: _errorText),
                SizedBox(width: 6),
                Text('Failed to load attendance data', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _errorText)),
              ],
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 11, color: HomeDarkTheme.textSecondary)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(foregroundColor: _errorText, side: const BorderSide(color: _errorBorder)),
              child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
