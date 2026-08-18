import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../domain/entities/fees_today_entity.dart';
import '../providers/dashboard_provider.dart';

const Color _feesIconBg = Color(0x26059669); // translucent green wash
const Color _feesIconColor = Color(0xFF059669);
const Color _positiveText = Color(0xFF059669);
const Color _positiveBg = Color(0x2634D399);
const Color _negativeText = Color(0xFFE0463A);
const Color _negativeBg = Color(0x26E0463A);

/// Mirrors `formatINR` in `FeesToday.tsx` exactly: `₹{n/100000}L` (2
/// decimals, trailing zeros stripped) at/above ₹100,000, else plain Indian
/// digit grouping with no decimals.
String formatInr(double amount) {
  if (amount >= 100000) {
    var lakhs = (amount / 100000).toStringAsFixed(2);
    lakhs = lakhs
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return '₹${lakhs}L';
  }
  return '₹${NumberFormat.decimalPattern('en_IN').format(amount.round())}';
}

/// Home screen → "Today's Pulse" → Today's Fees card — a 1:1 port of
/// `frontend/components/widgets/pulse/FeesToday.tsx`. Deliberately has no
/// loading/error UI, matching the real web card exactly: it initializes to
/// zero and a failed fetch just leaves it at zero forever, with no spinner
/// or error banner (confirmed against the actual component source, not an
/// oversight here).
class FeesTodayCard extends ConsumerWidget {
  const FeesTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref
        .watch(feesTodayProvider)
        .maybeWhen(data: (d) => d, orElse: () => const FeesTodayEntity.empty());
    final hasDelta = data.vsAvgDay.isNotEmpty && data.vsAvgPercent != 0;
    final positive = data.vsAvgPercent > 0;

    return TapScale(
      child: PremiumCard(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        radius: 16,
        color: Colors.white,
        // Flat, barely-there edge — matches the Stitch reference's plain
        // white cards (was a bold green brand-colored border).
        borderColor: AppColors.border.withValues(alpha: 0.8),
        borderWidth: 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              recordModuleVisit(ref, '/fees/payments');
              context.push('/fees/payments');
            },
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "TODAY'S FEES",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink2,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _feesIconBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.currency_rupee,
                          size: 14,
                          color: _feesIconColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatInr(data.collectedAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${data.transactionCount} transactions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink2,
                        ),
                      ),
                      if (hasDelta)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: positive ? _positiveBg : _negativeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                positive
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 11,
                                color: positive ? _positiveText : _negativeText,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${positive ? '+' : ''}${data.vsAvgPercent}% vs avg ${data.vsAvgDay}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: positive
                                      ? _positiveText
                                      : _negativeText,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (data.sparkline7d.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: CustomPaint(
                        painter: _SparklinePainter(values: data.sparkline7d),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;

  const _SparklinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final minVal = values.fold<double>(maxVal, (m, v) => v < m ? v : m);
    final range = (maxVal - minVal).abs() < 1e-9 ? 1.0 : (maxVal - minVal);
    final stepX = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final normalized = (values[i] - minVal) / range;
      return Offset(i * stepX, size.height - normalized * size.height);
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(pointAt(values.length - 1).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandPurple.withValues(alpha: 0.15),
            AppColors.brandPurple.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.brandPurple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      pointAt(values.length - 1),
      2.5,
      Paint()..color = AppColors.brandPurple,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}
