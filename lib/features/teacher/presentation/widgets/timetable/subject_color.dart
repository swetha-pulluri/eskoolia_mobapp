import 'package:flutter/material.dart';

class SubjectPalette {
  final Color bg;
  final Color text;
  final Color border;
  const SubjectPalette({required this.bg, required this.text, required this.border});
}

/// Exact port of web's `SUBJECT_COLORS`/`subjectColor()` in
/// `(teacher-portal)/teacher/timetable/page.tsx` — deterministic 8-color
/// hash by summing character codes mod 8, so the same subject name always
/// gets the same color across the whole timetable.
const List<SubjectPalette> _subjectColors = [
  SubjectPalette(bg: Color(0xFFEEF2FF), text: Color(0xFF4F46E5), border: Color(0xFFC7D2FE)),
  SubjectPalette(bg: Color(0xFFF0FDF4), text: Color(0xFF15803D), border: Color(0xFFBBF7D0)),
  SubjectPalette(bg: Color(0xFFFFF7ED), text: Color(0xFFC2410C), border: Color(0xFFFED7AA)),
  SubjectPalette(bg: Color(0xFFFDF4FF), text: Color(0xFFA21CAF), border: Color(0xFFE9D5FF)),
  SubjectPalette(bg: Color(0xFFECFDF5), text: Color(0xFF047857), border: Color(0xFFA7F3D0)),
  SubjectPalette(bg: Color(0xFFEFF6FF), text: Color(0xFF1D4ED8), border: Color(0xFFBFDBFE)),
  SubjectPalette(bg: Color(0xFFFFFBEB), text: Color(0xFFB45309), border: Color(0xFFFDE68A)),
  SubjectPalette(bg: Color(0xFFFFF1F2), text: Color(0xFFBE123C), border: Color(0xFFFECDD3)),
];

SubjectPalette subjectColor(String name) {
  var hash = 0;
  for (final code in name.codeUnits) {
    hash = (hash + code) % _subjectColors.length;
  }
  return _subjectColors[hash];
}
