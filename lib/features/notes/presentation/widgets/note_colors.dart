import 'package:flutter/material.dart';

/// The 5 note colors + labels, matching web's `NoteTrigger.tsx` swatch
/// picker (yellow/pink/green/blue/purple = Reminder/Urgent/Done/Follow-up/AI).
class NoteColorDef {
  final String key;
  final String label;
  final Color swatch;
  final Color background;
  final Color border;

  const NoteColorDef({required this.key, required this.label, required this.swatch, required this.background, required this.border});
}

const List<NoteColorDef> noteColors = [
  NoteColorDef(key: 'yellow', label: 'Reminder', swatch: Color(0xFFF59E0B), background: Color(0xFFFEF3C7), border: Color(0xFFFDE68A)),
  NoteColorDef(key: 'pink', label: 'Urgent', swatch: Color(0xFFDB2777), background: Color(0xFFFCE7F3), border: Color(0xFFFBCFE8)),
  NoteColorDef(key: 'green', label: 'Done / FYI', swatch: Color(0xFF059669), background: Color(0xFFD1FAE5), border: Color(0xFFA7F3D0)),
  NoteColorDef(key: 'blue', label: 'Follow-up', swatch: Color(0xFF3B82F6), background: Color(0xFFDBEAFE), border: Color(0xFFBFDBFE)),
  NoteColorDef(key: 'purple', label: 'AI / System', swatch: Color(0xFF7C3AED), background: Color(0xFFEDE9FE), border: Color(0xFFDDD6FE)),
];

NoteColorDef noteColorFor(String key) => noteColors.firstWhere((c) => c.key == key, orElse: () => noteColors.first);
