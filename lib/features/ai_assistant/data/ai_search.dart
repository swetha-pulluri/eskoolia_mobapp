import '../domain/ai_flat_index.dart';
import '../domain/models/flat_index_entry.dart';

/// Mirrors frontend lib/aiSearch.ts exactly — same synonym map, same
/// normalize/strip rules, same exact-match and scored-fuzzy-search logic,
/// just run against [aiFlatIndex] (the Flutter-routes-only equivalent of
/// web's `FLAT_INDEX`) instead of the web index.
const Map<String, String> aiSyn = {
  'fee': 'fees', 'pay': 'fees payments', 'collect': 'fees payments',
  'attend': 'attendance', 'present': 'attendance', 'absent': 'attendance',
  'enroll': 'students list', 'register': 'students add', 'new student': 'students add',
  'visitor': 'visitor book', 'guest': 'visitor book',
  'mark': 'marks register', 'grade': 'marks',
  'bus': 'transport bus tracking', 'route': 'transport routes',
  'staff': 'hr', 'teacher': 'hr', 'leave': 'hr leave',
  'salary': 'payroll', 'book': 'library', 'borrow': 'library issues',
  'incident': 'behaviour', 'complaint': 'admin complaint',
  'admission': 'admissions admission-query',
  'permission': 'roles', 'role': 'roles',
};

String _normalize(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'[?.!]+$'), '').replaceAll(RegExp(r'\s+'), ' ');

String _strip(String s) => s
    .replaceFirst(RegExp(r'^(open|go to|goto|show( me)?|take me to|navigate to|find)\s+', caseSensitive: false), '')
    .replaceFirst(RegExp(r'\s+page$', caseSensitive: false), '');

FlatIndexEntry? exactMatch(String q, {List<FlatIndexEntry>? index}) {
  final norm = _normalize(q);
  final stripped = _strip(norm);
  for (final it in index ?? aiFlatIndex) {
    final label = it.label.toLowerCase();
    if (label == stripped || label == norm || it.path.toLowerCase() == stripped) return it;
  }
  return null;
}

class ScoredFlatIndexEntry {
  final FlatIndexEntry entry;
  final int score;
  const ScoredFlatIndexEntry(this.entry, this.score);
}

List<FlatIndexEntry> localFuzzySearch(String q, {List<FlatIndexEntry>? index}) {
  final norm = _normalize(q);
  final stripped = _strip(norm);
  var expanded = stripped;
  for (final e in aiSyn.entries) {
    if (stripped.contains(e.key)) {
      expanded = expanded.replaceFirst(e.key, e.value);
      break;
    }
  }
  final terms = expanded.split(' ').where((t) => t.isNotEmpty).toList();

  final scored = <ScoredFlatIndexEntry>[];
  for (final it in index ?? aiFlatIndex) {
    final label = it.label.toLowerCase();
    final path = it.path.toLowerCase();
    var score = 0;
    for (final t in terms) {
      if (label.contains(t)) score += label.startsWith(t) ? 3 : 2;
      if (path.contains(t)) score += 1;
    }
    if (score > 0) scored.add(ScoredFlatIndexEntry(it, score));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.take(8).map((s) => s.entry).toList();
}
