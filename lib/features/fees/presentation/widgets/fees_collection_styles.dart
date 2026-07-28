import 'package:flutter/material.dart';
import '../utils/fee_assignment_format.dart' show avatarBg, initials;

/// Shared style building-blocks for the Collection screen — mirrors
/// FeesCollectionPanel.tsx's `pBtn`/`oBtn`/`CARD`/`TH`/`TD`/`ST_STYLE`/
/// `Avatar`/`ScoreCircle`/`StatusPill` helpers verbatim (own literal
/// values — kept separate from fee_assignment_styles.dart because that
/// screen's own `oBtn` uses a different non-small horizontal padding
/// (16px here vs 20px there), which would silently drift from this
/// screen's literal source spec if reused).
const fcBorder = Color(0xFFE8E8EE);
const fcInk1 = Color(0xFF181B2A);
const fcInk2 = Color(0xFF5B5E72);
const fcInk3 = Color(0xFFA0A3B8);
const fcPurple = Color(0xFF6D4AFF);
const fcPurpleBorder = Color(0xFFC4B5FD);
const fcPurpleTint = Color(0xFFF5F3FF);
const fcPurpleTintRow = Color(0xFFFAFAFF);
const fcPurpleDisabled = Color(0xFFA78BFA);

const fcThStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: fcInk3);

const Map<String, ({Color bg, Color color})> fcStatusStyle = {
  'partial': (bg: Color(0xFFFEF3C7), color: Color(0xFFD97706)),
  'cleared': (bg: Color(0xFFDCFCE7), color: Color(0xFF15803D)),
  'overdue': (bg: Color(0xFFFEE2E2), color: Color(0xFFDC2626)),
  'unassigned': (bg: Color(0xFFF3F4F6), color: Color(0xFF6B7280)),
};

class FcPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  final bool busy;
  const FcPrimaryButton({super.key, required this.label, required this.onPressed, this.small = false, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(small ? 7 : 9),
        boxShadow: const [BoxShadow(color: Color(0x336D4AFF), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: busy ? fcPurpleDisabled : fcPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: fcPurpleDisabled,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(0, small ? 32 : 38),
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 7 : 9)),
          textStyle: TextStyle(fontSize: small ? 12.5 : 13, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class FcOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FcOutlineButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: fcInk1,
        disabledBackgroundColor: Colors.white,
        disabledForegroundColor: fcInk3,
        elevation: 0,
        minimumSize: Size(0, small ? 32 : 38),
        padding: EdgeInsets.symmetric(horizontal: small ? 14 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 7 : 9), side: const BorderSide(color: fcBorder)),
        textStyle: TextStyle(fontSize: small ? 12.5 : 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class FcCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FcCard({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class FcStatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;
  const FcStatusPill({super.key, required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class FcAvatar extends StatelessWidget {
  final String name;
  final double size;
  const FcAvatar({super.key, required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: avatarBg(name)),
      child: Text(initials(name), style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

/// Mirrors `ScoreCircle` — used only for reconciliation records with
/// score>0. `createReconciliation` in this screen always sends score:0, so
/// this effectively never renders in practice, matching the source.
class FcScoreCircle extends StatelessWidget {
  final int score;
  const FcScoreCircle({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final col = score >= 90 ? const Color(0xFF16A34A) : (score >= 70 ? const Color(0xFFD97706) : const Color(0xFFDC2626));
    final bg = score >= 90 ? const Color(0xFFDCFCE7) : (score >= 70 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2));
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Text('$score%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: col)),
    );
  }
}

/// A labeled text/number/date input matching this screen's uniform
/// `border:1px solid #E8E8EE, radius:9, height:40, padding:"0 12px"` field
/// style, with the `10.5px/700/letterSpacing 0.07em/#A0A3B8` label above it.
class FcLabeledField extends StatelessWidget {
  final String label;
  final Widget field;
  const FcLabeledField({super.key, required this.label, required this.field});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: fcInk3)),
        const SizedBox(height: 7),
        field,
      ],
    );
  }
}

InputDecoration fcFieldDecoration({String? hintText, bool readOnly = false}) {
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: readOnly ? const Color(0xFFF8F8FB) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    hintStyle: const TextStyle(fontSize: 13.5, color: fcInk3),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: fcBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: fcBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: fcPurple)),
  );
}

/// Modal text-field decoration for the smaller Add-Reconciliation /
/// Edit-Header dialogs — `radius:8, padding:"9px 13px"`, distinct sizing
/// from [fcFieldDecoration] (the Payment Form's own `radius:9, height:40`).
InputDecoration fcModalFieldDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    hintStyle: const TextStyle(fontSize: 13, color: fcInk3),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fcBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fcBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fcPurple)),
  );
}
