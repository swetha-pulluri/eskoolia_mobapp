import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/child_detail_entity.dart';

const Color _headerIconBg = Color(0xFFEEEAFF);
const Color _brandPurple = Color(0xFF6D4AFF);
const Color _ok = Color(0xFF0E9F6E);
const Color _warn = Color(0xFFD97706);
const Color _danger = Color(0xFFDC2626);

/// Home screen → "Attendance" widget — mobile port of web's
/// `ParentAttendanceWidget.tsx`: an attendance ring plus Present/Absent/Late
/// counts for the currently selected child, over the last 90 days.
class ParentAttendanceWidget extends StatelessWidget {
  final String? childName;
  final ChildDetailEntity? detail;
  final bool loading;

  const ParentAttendanceWidget({super.key, required this.childName, required this.detail, required this.loading});

  @override
  Widget build(BuildContext context) {
    final att = detail?.attendance;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PremiumCard(
        radius: 14,
        color: Colors.white,
        borderColor: AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: _headerIconBg, borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.calendar_month_outlined, size: 13, color: _brandPurple),
                  ),
                  const SizedBox(width: 7),
                  const Text('Attendance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/parent/attendance'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Calendar', style: TextStyle(fontSize: 11.5, color: _brandPurple, fontWeight: FontWeight.w500)),
                        Icon(Icons.chevron_right, size: 13, color: _brandPurple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _body(att),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AttendanceSummaryEntity? att) {
    if (loading && detail == null) {
      return const SizedBox(
        height: 76,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (att == null) {
      return const SizedBox(
        height: 40,
        child: Center(child: Text('No child selected', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
      );
    }

    final pct = att.pct ?? 0;
    final barColor = pct >= 85 ? _ok : _danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (childName != null) ...[
          Text(
            childName!.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _brandPurple, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AttendanceRing(pct: pct),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statRow('Present', att.present + att.late, _ok),
                  const SizedBox(height: 7),
                  _statRow('Absent', att.absent, _danger),
                  const SizedBox(height: 7),
                  _statRow('Late', att.late, _warn),
                ],
              ),
            ),
          ],
        ),
        if (att.total > 0) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            pct >= 85 ? '✓ Good standing' : '⚠ Below 85% threshold',
            style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
          ),
        ],
      ],
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, height: 1)),
        ),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
      ],
    );
  }
}

class _AttendanceRing extends StatelessWidget {
  final double pct;
  const _AttendanceRing({required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 85 ? _ok : (pct >= 70 ? _warn : _danger);
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _RingPainter(pct: pct.clamp(0, 100), color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              const Text('attended', style: TextStyle(fontSize: 9, color: AppColors.ink3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color color;
  const _RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 6) / 2;
    const stroke = 6.0;

    final track = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    if (pct > 0) {
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * (pct / 100);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}
