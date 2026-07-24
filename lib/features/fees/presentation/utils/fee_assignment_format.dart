import 'package:flutter/material.dart';

/// Mirrors FeesAssignmentPanel.tsx's small formatting/avatar helpers
/// (`avatarBg`, `initials`, `fmtRs`, `fmtInr`).
const _avatarColors = [
  Color(0xFF6D4AFF),
  Color(0xFF0E7490),
  Color(0xFF16A34A),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFF7C3AED),
  Color(0xFF0284C7),
  Color(0xFF9333EA),
  Color(0xFFCA8A04),
  Color(0xFF059669),
];

Color avatarBg(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return _avatarColors[h % _avatarColors.length];
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts[0][0];
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}

String groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

String fmtRs(num n) => 'Rs. ${groupIndian(n.round().abs().toString())}';
String fmtInr(num n) => '₹${groupIndian(n.round().abs().toString())}';
