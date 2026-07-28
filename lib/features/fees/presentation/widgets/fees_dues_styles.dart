import 'package:flutter/material.dart';

/// Shared style building-blocks for the Dues & Reminders screen — mirrors
/// FeesDuesRemindersPanel.tsx's `pBtn`/`oBtn`/`TH`/`TD` helpers verbatim.
/// Kept as its own file (not reusing fee_assignment_styles.dart or
/// fees_collection_styles.dart) because this screen's own button
/// dimensions differ from both: height 30/36 here vs. 32/38 (Collection)
/// or 32/38 (Fee Assignment), and outline-button padding "0 12px"/"0 16px"
/// here vs. "0 14px"/"0 16px" elsewhere — reusing either would silently
/// drift from this screen's literal source spec.
const fdBorder = Color(0xFFE8E8EE);
const fdInk1 = Color(0xFF181B2A);
const fdInk2 = Color(0xFF5B5E72);
const fdInk3 = Color(0xFFA0A3B8);
const fdPurple = Color(0xFF6D4AFF);
const fdPurpleTint = Color(0xFFF5F3FF);
const fdPurpleBorder = Color(0xFFC4B5FD);

const fdThStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: fdInk3);

class FdPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FdPrimaryButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(small ? 7 : 9),
        boxShadow: disabled ? null : const [BoxShadow(color: Color(0x336D4AFF), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: fdPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: fdPurple.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(0, small ? 30 : 36),
          padding: EdgeInsets.symmetric(horizontal: small ? 12 : 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 7 : 9)),
          textStyle: TextStyle(fontSize: small ? 12 : 13, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

class FdOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FdOutlineButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: fdInk1,
        disabledBackgroundColor: Colors.white,
        disabledForegroundColor: fdInk3,
        elevation: 0,
        minimumSize: Size(0, small ? 30 : 36),
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 7 : 9), side: const BorderSide(color: fdBorder)),
        textStyle: TextStyle(fontSize: small ? 12 : 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class FdStatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;
  final bool small;
  const FdStatusPill({super.key, required this.label, required this.bg, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 9 : 12, vertical: small ? 2 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class FdAvatar extends StatelessWidget {
  final Color background;
  final String initials;
  final double size;
  const FdAvatar({super.key, required this.background, required this.initials, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Text(initials, style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

InputDecoration fdFieldDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    hintStyle: const TextStyle(fontSize: 13.5, color: fdInk3),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: fdBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: fdBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: fdPurple)),
  );
}

const fdFieldLabelStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: fdInk3);
