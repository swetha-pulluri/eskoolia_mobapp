import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/child_fees_entity.dart';
import '../../domain/entities/parent_me_entity.dart';
import '../providers/parent_providers.dart';
import '../widgets/sibling_tabs.dart';

const Color _brandPurple = Color(0xFF6D4AFF);
const Color _ok = Color(0xFF0E9F6E);
const Color _warn = Color(0xFFD97706);
const Color _danger = Color(0xFFDC2626);

class _StatusCfg {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.label, this.color, this.bg, this.icon);
}

const _statusCfg = {
  'paid': _StatusCfg('Paid', Color(0xFF22C55E), Color(0x1A22C55E), Icons.check_circle_outline),
  'partial': _StatusCfg('Partial', _warn, Color(0xFFFFFBEB), Icons.access_time),
  'unpaid': _StatusCfg('Unpaid', _danger, Color(0xFFFEF2F2), Icons.error_outline),
};

String _fmt(double n) => '₹${NumberFormat('#,##0.00', 'en_IN').format(n)}';

/// Fee Summary — mobile port of web's `(parent-portal)/parent/fees/page.tsx`:
/// a 3-stat summary bar (Total Billed/Paid/Outstanding) followed by fee
/// assignments grouped by fees group. Mobile simplification: web's 6-column
/// table (Fee Type/Due Date/Amount/Paid/Due/Status) becomes a compact
/// 2-line row per fee item, same as the Home screen's Fee Status widget.
class FeesPage extends ConsumerWidget {
  const FeesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(parentMeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentMeProvider);
          ref.invalidate(childFeesProvider);
        },
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(error: error, onRetry: () => ref.invalidate(parentMeProvider)),
          data: (me) => _FeesContent(me: me),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _LoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 32, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text('Could not load fees', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                  const SizedBox(height: 6),
                  Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeesContent extends ConsumerWidget {
  final ParentMeEntity me;
  const _FeesContent({required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedChildProvider);
    final feesAsync = ref.watch(childFeesProvider);
    final data = feesAsync.valueOrNull;
    final loading = feesAsync.isLoading;
    final hasError = feesAsync.hasError;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.ink1, fontWeight: FontWeight.w600),
              children: const [
                TextSpan(text: 'Fee '),
                TextSpan(text: 'Summary', style: TextStyle(color: _brandPurple, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Fee assignments, payment status, and outstanding dues.', style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.4)),
          if (me.children.length > 1) ...[
            const SizedBox(height: 14),
            SiblingTabs(children: me.children, selectedId: selected?.id),
          ],
          if (hasError) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(10)),
              child: const Text('Could not load fee data. Pull to refresh.', style: TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C))),
            ),
          ],
          const SizedBox(height: 14),
          if (loading)
            _SummarySkeleton()
          else if (data != null)
            _SummaryBar(summary: data.summary),
          const SizedBox(height: 14),
          if (loading)
            Column(children: [for (var i = 0; i < 2; i++) ...[_GroupSkeleton(), if (i == 0) const SizedBox(height: 12)]])
          else if (data != null && data.groups.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final group in data.groups) ...[_FeeGroupCard(group: group), const SizedBox(height: 12)]],
            )
          else if (!hasError)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text('No fee records found for this child.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.ink3)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(height: 80, decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14))),
          ),
        ],
      ],
    );
  }
}

class _GroupSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 180, decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)));
  }
}

class _SummaryBar extends StatelessWidget {
  final FeesSummaryEntity summary;
  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final dueColor = summary.totalDue > 0 ? _danger : _ok;
    final dueBg = summary.totalDue > 0 ? const Color(0xFFFEF2F2) : const Color(0x1422C55E);
    final dueIcon = summary.totalDue > 0 ? Icons.error_outline : Icons.check_circle_outline;

    // `IntrinsicHeight` gives this Row an actual bounded height (the
    // tallest child's) for `CrossAxisAlignment.stretch` to stretch the
    // other two cards to — without it, the Row sits directly inside
    // `_FeesContent`'s `Column`, which hands plain children UNBOUNDED
    // height, and `stretch` has no bound to stretch to. That's what was
    // actually crashing this page (not a hover/mouse-tracker bug at all —
    // the mouse-tracker assertions were fallout from this Row never
    // completing layout, the same cascade pattern as the earlier top-bar
    // overflow).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _stat('Total Billed', summary.totalBilled, AppColors.ink1, AppColors.bg2, Icons.credit_card_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _stat('Total Paid', summary.totalPaid, _ok, const Color(0x1422C55E), Icons.check_circle_outline)),
          const SizedBox(width: 8),
          Expanded(child: _stat('Outstanding', summary.totalDue, dueColor, dueBg, dueIcon)),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: bg, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.ink3, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            _fmt(value),
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FeeGroupCard extends StatelessWidget {
  final FeeGroupEntity group;
  const _FeeGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final groupDue = group.items.fold<double>(0, (sum, i) => sum + i.dueAmount);

    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(color: AppColors.bg2, border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                Expanded(
                  child: Text(group.groupName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                ),
                if (groupDue > 0) Text('${_fmt(groupDue)} due', style: const TextStyle(fontSize: 11.5, color: _danger, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            children: [for (var i = 0; i < group.items.length; i++) _FeeItemRow(item: group.items[i], showDivider: i < group.items.length - 1)],
          ),
        ],
      ),
    );
  }
}

class _FeeItemRow extends StatelessWidget {
  final FeeItemEntity item;
  final bool showDivider;
  const _FeeItemRow({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final cfg = _statusCfg[item.status] ?? _statusCfg['unpaid']!;
    final dueDate = DateTime.tryParse(item.dueDate);
    final dueLabel = dueDate != null ? DateFormat('d MMM yyyy').format(dueDate) : item.dueDate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.feeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cfg.bg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cfg.icon, size: 10, color: cfg.color),
                    const SizedBox(width: 4),
                    Text(cfg.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: cfg.color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text('Due $dueLabel', style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
          const SizedBox(height: 8),
          Row(
            children: [
              _amountChip('Billed', item.netAmount, AppColors.ink2),
              const SizedBox(width: 8),
              _amountChip('Paid', item.paidAmount, _ok),
              const SizedBox(width: 8),
              _amountChip('Due', item.dueAmount, item.dueAmount > 0 ? _danger : AppColors.ink3, bold: item.dueAmount > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountChip(String label, double value, Color color, {bool bold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.ink3)),
          const SizedBox(height: 1),
          Text(
            _fmt(value),
            style: TextStyle(fontSize: 11.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
