import 'package:flutter/material.dart';

/// Exact color tokens from the real, deployed web's `app/globals.css`
/// (`demo`/`mobile`/`BugFix` branches) HR/HRMS token block.
class HrColors {
  HrColors._();

  static const brand = Color(0xFF6D4AFF);
  static const strong = Color(0xFF4F35CC);
  static const soft = Color(0xFFEEEAFF);
  static const ink = Color(0xFF15172A);
  static const muted = Color(0xFF5B5E72);
  static const page = Color(0xFFFAFAFB);
  static const bg1 = Color(0xFFFFFFFF);
  static const bg2 = Color(0xFFF5F5FB);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFE0463A);
  static const amber = Color(0xFFF59E0B);
  static const blue = Color(0xFF2563EB);
  static const line = Color(0xFFDBE4F0);

  // Badge variants (bg / fg)
  static const purpleBg = soft;
  static const purpleFg = brand;
  static const greenBg = Color(0xFFECFDF5);
  static const greenFg = Color(0xFF059669);
  static const redBg = Color(0xFFFFF1F2);
  static const redFg = red;
  static const amberBg = Color(0xFFFFFBEB);
  static const amberFg = amber;
  static const blueBg = Color(0xFFEFF6FF);
  static const blueFg = blue;
  static const greyBg = Color(0xFFF1F5F9);
  static const greyFg = Color(0xFF64748B);
}

enum HrBadgeVariant { purple, green, red, amber, blue, grey, archived }

/// Matches web's `HrBadge` — fully-rounded pill, 11px/850-weight text.
class HrBadge extends StatelessWidget {
  final String label;
  final HrBadgeVariant variant;

  const HrBadge({super.key, required this.label, this.variant = HrBadgeVariant.grey});

  /// Matches web's `statusToBadge(status)` helper.
  factory HrBadge.status(String status) {
    final s = status.toLowerCase();
    final variant = switch (s) {
      'active' => HrBadgeVariant.green,
      'inactive' => HrBadgeVariant.grey,
      'probation' => HrBadgeVariant.amber,
      'terminated' || 'offboarded' => HrBadgeVariant.red,
      'archived' => HrBadgeVariant.archived,
      _ => HrBadgeVariant.grey,
    };
    return HrBadge(label: status.isEmpty ? '' : (status[0].toUpperCase() + status.substring(1).toLowerCase()), variant: variant);
  }

  (Color, Color) get _colors => switch (variant) {
        HrBadgeVariant.purple => (HrColors.purpleBg, HrColors.purpleFg),
        HrBadgeVariant.green => (HrColors.greenBg, HrColors.greenFg),
        HrBadgeVariant.red => (HrColors.redBg, HrColors.redFg),
        HrBadgeVariant.amber => (HrColors.amberBg, HrColors.amberFg),
        HrBadgeVariant.blue => (HrColors.blueBg, HrColors.blueFg),
        HrBadgeVariant.grey || HrBadgeVariant.archived => (HrColors.greyBg, HrColors.greyFg),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          decoration: variant == HrBadgeVariant.archived ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

/// Matches web's `HrKpiCard` — static presentational stat card.
class HrKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? color;

  const HrKpiCard({super.key, required this.label, required this.value, this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: HrColors.line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x140F1222), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 0.8, color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1, color: color ?? HrColors.ink)),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(sub!, style: const TextStyle(fontSize: 12, color: HrColors.muted)),
          ],
        ],
      ),
    );
  }
}

/// Matches web's `HrField` — label (+ required marker) / error text wrapper.
class HrField extends StatelessWidget {
  final String label;
  final bool required;
  final String? error;
  final Widget child;

  const HrField({super.key, required this.label, this.required = false, this.error, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: Color(0xFF64748B), fontWeight: FontWeight.w800),
            children: [
              TextSpan(text: label.toUpperCase()),
              if (required) const TextSpan(text: ' *', style: TextStyle(color: HrColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 9),
        child,
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: const TextStyle(fontSize: 11, color: HrColors.red)),
        ],
      ],
    );
  }
}

/// Matches web's `HrStepWizard` — 3-circle step indicator with connectors.
class HrStep {
  final String label;
  final String? hint;
  const HrStep(this.label, [this.hint]);
}

class HrStepWizard extends StatelessWidget {
  final List<HrStep> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTap;

  const HrStepWizard({super.key, required this.steps, required this.currentStep, this.onStepTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepCircle(
            step: steps[i],
            num: i + 1,
            done: (i + 1) < currentStep,
            active: (i + 1) == currentStep,
            onTap: onStepTap == null ? null : () => onStepTap!(i + 1),
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Container(height: 2, color: (i + 1) < currentStep ? HrColors.green : const Color(0xFFE5E7EB)),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final HrStep step;
  final int num;
  final bool done;
  final bool active;
  final VoidCallback? onTap;

  const _StepCircle({required this.step, required this.num, required this.done, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color bg = done ? HrColors.green : (active ? HrColors.brand : const Color(0xFFF3F4F6));
    final Color border = done ? HrColors.green : (active ? HrColors.brand : const Color(0xFFE5E7EB));
    final Color fg = (done || active) ? Colors.white : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: border, width: 2)),
              child: Text(done ? '✓' : '$num', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: fg)),
            ),
            const SizedBox(height: 8),
            Text(step.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            if (step.hint != null) ...[
              const SizedBox(height: 2),
              Text(step.hint!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ],
        ),
      ),
    );
  }
}

/// Matches web's `HrConfirmDialog` — reusable confirm/delete dialog.
Future<void> showHrConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  var loading = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: danger ? Colors.orange : HrColors.brand, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
        ]),
        content: Text(message, style: const TextStyle(fontSize: 13, color: HrColors.muted)),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger ? HrColors.red : HrColors.brand),
            onPressed: loading
                ? null
                : () async {
                    setState(() => loading = true);
                    await onConfirm();
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
            child: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}

/// Matches web's `HrSkeleton` — flat pulsing placeholder rows.
class HrSkeleton extends StatelessWidget {
  final int rows;
  const HrSkeleton({super.key, this.rows = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _PulsingBar(),
          ],
        ],
      ),
    );
  }
}

class _PulsingBar extends StatefulWidget {
  @override
  State<_PulsingBar> createState() => _PulsingBarState();
}

class _PulsingBarState extends State<_PulsingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(height: 44, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10))),
    );
  }
}

/// Matches web's `useHrToast` — near-black for success, dark-red for error,
/// dark-blue for info, auto-dismisses, top-right on web / top SnackBar here.
void showHrToast(BuildContext context, String message, {String type = 'success'}) {
  final color = switch (type) {
    'error' => const Color(0xFF991B1B),
    'info' => const Color(0xFF1E40AF),
    _ => const Color(0xFF111827),
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(milliseconds: 2200),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
