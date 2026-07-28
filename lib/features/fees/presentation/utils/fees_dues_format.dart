import 'package:flutter/material.dart';

/// Mirrors FeesDuesRemindersPanel.tsx's `avBg` — same hash formula as
/// fee_assignment_format.dart's `avatarBg`, but a DIFFERENT 8-color palette
/// (vs. that file's 10 colors), so the modulo lands on different colors for
/// the same name — kept as its own function rather than reusing
/// `avatarBg` to stay pixel-accurate to this screen's own avatar palette.
const _duesAvatarColors = [
  Color(0xFF6D4AFF),
  Color(0xFF0E7490),
  Color(0xFF16A34A),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFF7C3AED),
  Color(0xFF0284C7),
  Color(0xFF9333EA),
];

Color duesAvatarBg(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return _duesAvatarColors[h % _duesAvatarColors.length];
}

/// Mirrors `fmtDate` — parses any ISO date/datetime string (not just
/// `YYYY-MM-DD` like the Collection screen's own `fmtDate`) into
/// `D MMM YYYY` (e.g. "12 Jul 2026"). Null/empty → "—" (em dash); an
/// unparseable non-empty string is returned unchanged, matching the
/// source's `catch { return d; }` fallback.
String fmtDuesDate(String? d) {
  if (d == null || d.isEmpty) return '—';
  final parsed = DateTime.tryParse(d);
  if (parsed == null) return d;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

/// Mirrors `tierStatus()` — the client-side-computed status pill shown on
/// every student row/card, derived from days overdue (NOT the API's own
/// `status` field, which this screen only ever displays verbatim in the
/// Late Fee Calculator preview card).
String duesTierStatus(int daysOverdue) {
  if (daysOverdue <= 15) return 'Payment Watch';
  if (daysOverdue <= 30) return 'Escalated';
  return 'Defaulter';
}

const Map<String, ({Color bg, Color color})> duesStatusStyle = {
  'Payment Watch': (bg: Color(0xFFFEF3C7), color: Color(0xFFD97706)),
  'Escalated': (bg: Color(0xFFFED7AA), color: Color(0xFFEA580C)),
  'Defaulter': (bg: Color(0xFFFCE7F3), color: Color(0xFF9D174D)),
  'Overdue': (bg: Color(0xFFFEE2E2), color: Color(0xFFDC2626)),
};

/// Days-overdue cell text color: >30 red, >15 amber, else default ink.
Color duesOverdueTextColor(int daysOverdue) {
  if (daysOverdue > 30) return const Color(0xFFDC2626);
  if (daysOverdue > 15) return const Color(0xFFD97706);
  return const Color(0xFF181B2A);
}
