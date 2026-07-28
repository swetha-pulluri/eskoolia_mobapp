import 'package:flutter/material.dart';

/// Shared style building-blocks for the Year-End screen — mirrors
/// YearEndPage.tsx's `TH`/`BTN_OUTLINE` constants (this screen has no
/// `pBtn`/`oBtn` factory pair like the other Fees screens; most buttons
/// here are styled inline/one-off in the source itself, so this file only
/// factors out what the source itself shares, plus common color tokens).
const fyBorder = Color(0xFFE8E8EE);
const fyInk1 = Color(0xFF181B2A);
const fyInk2 = Color(0xFF5B5E72);
const fyInk3 = Color(0xFFA0A3B8);
const fyPurple = Color(0xFF6D4AFF);
const fyPurpleTint = Color(0xFFF5F3FF);
const fyPurpleBorder = Color(0xFFC4B5FD);

const fyThStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: fyInk3);

/// Mirrors `BTN_OUTLINE` — the "Generate PDF"/"Export CSV" report-row
/// buttons, height 32, padding "0 14px", radius 8, font 13/500.
class FyOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const FyOutlineButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: fyInk1,
        disabledBackgroundColor: Colors.white,
        disabledForegroundColor: fyInk1.withValues(alpha: 0.6),
        elevation: 0,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: fyBorder)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

InputDecoration fyFieldDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    hintStyle: const TextStyle(fontSize: 13, color: fyInk3),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fyBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fyBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: fyPurple)),
  );
}

const fyFieldLabelStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: fyInk3);
