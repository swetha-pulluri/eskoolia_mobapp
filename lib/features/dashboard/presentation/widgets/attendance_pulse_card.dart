import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/attendance_pulse_entity.dart';
import '../providers/dashboard_provider.dart';

// Light purple wash used for both the header icon chip and the donut's
// background track, now that the card itself is a solid white surface
// rather than a frosted glass panel over the purple page background.
const Color _pulseIconBg = AppColors.purpleSoft;
const Color _lateDot = Color(
  0xFF94A3B8,
); // no AppColors equivalent for this one
// "Attendance pending" callout — light purple, readable on the white card.
const Color _pendingBg = AppColors.purpleSoft;
const Color _pendingBorder = AppColors.brandPurple;
const Color _pendingHeading = AppColors.purpleDeep;
const Color _pendingBadgeText = AppColors.purpleDeep;
const Color _pendingBadgeBg = Color(0xFFEDE9FE);
const Color _errorBg = Color(0x14E0463A);
const Color _errorBorder = Color(0xFFE0463A);
const Color _errorText = Color(0xFFE0463A);
const Color _shimmerA = Color(0xFFEDEBF5);
const Color _shimmerB = Color(0xFFE0DCEE);
// Non-active trend bars — a light purple tint instead of translucent white.
const Color _trendBarInactive = Color(0xFFE5E1F5);

/// Home screen → "Today's Pulse" → Student Attendance card — a 1:1 port of
/// `frontend/components/widgets/pulse/AttendanceSnapshot.tsx`. On web this
/// lives in a left rail hidden below 1024px viewport width (no existing
/// mobile layout to copy) — placed inline on the Home screen here instead,
/// same content, adapted to a full-width mobile card.
class AttendancePulseCard extends ConsumerStatefulWidget {
  const AttendancePulseCard({super.key});

  @override
  ConsumerState<AttendancePulseCard> createState() =>
      _AttendancePulseCardState();
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
        child: _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(attendancePulseProvider),
        ),
        onTap: null,
      ),
      data: (data) => _shell(
        child: _PulseContent(
          data: data,
          nudging: _nudging,
          onNudge: () => _nudge(data),
        ),
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
      // Flat, barely-there edge — matches the Stitch reference's plain
      // white cards (was a bold blue brand-colored border).
      borderColor: AppColors.border.withValues(alpha: 0.8),
      borderWidth: 1,
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

  const _PulseContent({
    required this.data,
    required this.nudging,
    required this.onNudge,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final showPending = data.pendingClasses.isNotEmpty && now.hour >= 10;
    final allTeachersMarked =
        data.totalTeachers > 0 && data.markedTeachers == data.totalTeachers;
    // "Total" isn't its own field on the API — it's the real sum of every
    // marked status, matching the Stitch reference's TOTAL stat exactly
    // (not a fabricated number).
    final total = data.present + data.absent + data.leave + data.late;
    final percent = data.attendancePercentage.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ATTENDANCE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink2,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _pulseIconBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.how_to_reg_outlined,
                size: 17,
                color: AppColors.brandPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.ink1,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 10),

        // Progress bar — replaces the old donut, matching the Stitch
        // reference's attendance card exactly.
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 7,
            child: Stack(
              children: [
                Container(color: _pulseIconBg),
                FractionallySizedBox(
                  widthFactor: (percent / 100).clamp(0, 1).toDouble(),
                  child: Container(color: AppColors.brandPurple),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Total/Present/Absent/Leave stat grid, matching the Stitch
        // reference. "Late" has no cell of its own in that 2x2 layout, so
        // it's surfaced as a small line below instead of being dropped.
        Row(
          children: [
            Expanded(
              child: _StatCell(
                label: 'TOTAL',
                value: total,
                color: AppColors.ink1,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCell(
                label: 'PRESENT',
                value: data.present,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCell(
                label: 'ABSENT',
                value: data.absent,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCell(
                label: 'LEAVE',
                value: data.leave,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        if (data.late > 0) ...[
          const SizedBox(height: 6),
          Text(
            '+${data.late} late',
            style: const TextStyle(
              fontSize: 10.5,
              color: _lateDot,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        if (showPending) ...[
          const SizedBox(height: 10),
          _PendingBanner(
            pendingClasses: data.pendingClasses,
            nudging: nudging,
            onNudge: onNudge,
          ),
        ],
        if (data.trend.isNotEmpty) ...[
          const SizedBox(height: 10),
          _TrendBars(trend: data.trend),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, size: 12, color: AppColors.ink3),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Marked at ${data.lastUpdated} · ${data.markedTeachers}/${data.totalTeachers} teachers',
                style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (allTeachersMarked)
              const Icon(
                Icons.check_circle,
                size: 13,
                color: AppColors.success,
              ),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final List<PendingClassEntity> pendingClasses;
  final bool nudging;
  final VoidCallback onNudge;

  const _PendingBanner({
    required this.pendingClasses,
    required this.nudging,
    required this.onNudge,
  });

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
        decoration: BoxDecoration(
          color: _pendingBg,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: _pendingBorder, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: _pendingHeading,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Attendance pending',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _pendingHeading,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _pendingBadgeBg,
                      border: Border.all(color: _pendingBorder),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      cls.name,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _pendingBadgeText,
                      ),
                    ),
                  ),
                if (extra > 0)
                  Text(
                    '+$extra more',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: _pendingHeading,
                    ),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.notifications_outlined, size: 14),
                label: Text(
                  nudging ? 'Sending…' : 'Nudge teachers',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                      color: i == trend.length - 1
                          ? AppColors.brandPurple
                          : _trendBarInactive,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trend[i].round().toString(),
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.ink3,
                    ),
                  ),
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
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_shimmerA, _shimmerB]),
      borderRadius: BorderRadius.circular(6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: _bar(24)),
        const SizedBox(height: 12),
        _bar(7),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _bar(16)),
            const SizedBox(width: 14),
            Expanded(child: _bar(16)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _bar(16)),
            const SizedBox(width: 14),
            Expanded(child: _bar(16)),
          ],
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
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _errorBg,
          border: Border.all(color: _errorBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 15, color: _errorText),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Failed to load attendance data',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _errorText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 11, color: AppColors.ink2),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: _errorText,
                side: const BorderSide(color: _errorBorder),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
