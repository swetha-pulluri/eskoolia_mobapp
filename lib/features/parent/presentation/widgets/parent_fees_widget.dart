import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/child_fees_entity.dart';

const Color _iconBg = Color(0xFFFFF7ED);
const Color _iconColor = Color(0xFFD97706);
const Color _brandPurple = Color(0xFF6D4AFF);

class _StatusConfig {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  const _StatusConfig(this.icon, this.color, this.bg, this.label);
}

const _statusConfig = {
  'paid': _StatusConfig(Icons.check_circle_outline, Color(0xFF22C55E), Color(0x1A22C55E), 'Paid'),
  'partial': _StatusConfig(Icons.access_time, Color(0xFFD97706), Color(0xFFFFF7ED), 'Partial'),
  'unpaid': _StatusConfig(Icons.error_outline, Color(0xFFDC2626), Color(0xFFFEF2F2), 'Unpaid'),
};

/// Home screen → "Fee Status" widget — mobile port of web's
/// `ParentFeesWidget.tsx`: up to 4 of the selected child's fee items plus
/// the total amount due.
class ParentFeesWidget extends StatelessWidget {
  final ChildFeesEntity? fees;
  final bool loading;

  const ParentFeesWidget({super.key, required this.fees, required this.loading});

  String _fmt(double n) => '₹${NumberFormat('#,##0', 'en_IN').format(n)}';

  @override
  Widget build(BuildContext context) {
    final items = (fees?.allItems ?? const <FeeItemEntity>[]).take(4).toList();
    final totalDue = fees?.summary.totalDue ?? 0;

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
                    decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.credit_card_outlined, size: 13, color: _iconColor),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text('Fee Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                  ),
                  if (totalDue > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(20)),
                      child: Text('${_fmt(totalDue)} due', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => context.go('/parent/fees'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Details', style: TextStyle(fontSize: 11.5, color: _brandPurple, fontWeight: FontWeight.w500)),
                        Icon(Icons.chevron_right, size: 13, color: _brandPurple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            if (loading)
              const SizedBox(
                height: 60,
                child: Center(child: Text('Loading…', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
              )
            else if (items.isEmpty)
              const SizedBox(
                height: 60,
                child: Center(child: Text('No fee records found.', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) _FeeRow(item: items[i], showDivider: i < items.length - 1, fmt: _fmt),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final FeeItemEntity item;
  final bool showDivider;
  final String Function(double) fmt;

  const _FeeRow({required this.item, required this.showDivider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[item.status] ?? _statusConfig['unpaid']!;
    final dueDate = DateTime.tryParse(item.dueDate);
    final dueLabel = dueDate != null ? DateFormat('d MMM').format(dueDate) : item.dueDate;

    return InkWell(
      onTap: () => context.go('/parent/fees'),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: cfg.bg, borderRadius: BorderRadius.circular(7)),
              alignment: Alignment.center,
              child: Icon(cfg.icon, size: 14, color: cfg.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.feeName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink1), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Due $dueLabel', style: const TextStyle(fontSize: 10.5, color: AppColors.ink3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fmt(item.netAmount), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cfg.color)),
                Text(cfg.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cfg.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
