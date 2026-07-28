import '../domain/ai_flat_index.dart';
import '../domain/models/ai_intent.dart';
import '../domain/models/flat_index_entry.dart';

/// Mirrors frontend lib/aiBotIntent.ts's `parseIntent` exactly — same
/// priority order and same regexes (translated 1:1 to Dart `RegExp`),
/// matched against [aiFlatIndex] instead of web's `FLAT_INDEX`.
const _moduleKeywords = [
  'attendance', 'fees', 'exam', 'result', 'homework', 'transport', 'bus', 'library',
  'certificate', 'admission', 'report', 'marks', 'student list', 'staff', 'leave',
  'inventory', 'finance', 'hr', 'behaviour', 'lesson', 'setup', 'roles', 'open', 'go to',
  'show me', 'navigate', 'take me', 'admin', 'utilities', 'communication',
];

FlatIndexEntry? _exactPageMatch(String norm) {
  final collapsedNorm = norm.replaceAll(RegExp(r'\s+'), '');
  for (final e in aiFlatIndex) {
    final label = e.label.toLowerCase();
    if (label == norm || label.replaceAll(RegExp(r'\s+'), '') == collapsedNorm) return e;
  }
  return null;
}

class _QaTopic {
  final String key;
  final List<RegExp> patterns;
  const _QaTopic(this.key, this.patterns);
}

final _qaTopics = [
  _QaTopic('fees-class', [RegExp(r'fee[s]?.*class', caseSensitive: false), RegExp(r'how much.*class', caseSensitive: false), RegExp(r'fee structure', caseSensitive: false), RegExp(r'class.*fee', caseSensitive: false)]),
  _QaTopic('holidays', [RegExp(r'holida', caseSensitive: false), RegExp(r'school.*closed', caseSensitive: false), RegExp(r'off day', caseSensitive: false), RegExp(r'vacation', caseSensitive: false)]),
  _QaTopic('school-timing', [RegExp(r'school time', caseSensitive: false), RegExp(r'timing', caseSensitive: false), RegExp(r'what time.*school', caseSensitive: false), RegExp(r'open.*time', caseSensitive: false), RegExp(r'close.*time', caseSensitive: false)]),
  _QaTopic('transport-route', [RegExp(r'bus route', caseSensitive: false), RegExp(r'which bus', caseSensitive: false), RegExp(r'route.*\d', caseSensitive: false), RegExp(r'transport for', caseSensitive: false)]),
  _QaTopic('admission-process', [RegExp(r'how to.*admit', caseSensitive: false), RegExp(r'admission process', caseSensitive: false), RegExp(r'enroll', caseSensitive: false), RegExp(r'new student.*admit', caseSensitive: false)]),
  _QaTopic('exam-schedule', [RegExp(r'exam.*schedule', caseSensitive: false), RegExp(r'when.*exam', caseSensitive: false), RegExp(r'exam.*date', caseSensitive: false), RegExp(r'exam.*when', caseSensitive: false), RegExp(r'next exam', caseSensitive: false)]),
  _QaTopic('syllabus', [RegExp(r'syllabus', caseSensitive: false), RegExp(r'curriculum', caseSensitive: false), RegExp(r'what.*taught', caseSensitive: false), RegExp(r'chapter', caseSensitive: false)]),
];

String? _matchParentQaTopic(String norm) {
  for (final t in _qaTopics) {
    if (t.patterns.any((p) => p.hasMatch(norm))) return t.key;
  }
  return null;
}

/// Parse a free-text bot query into a typed intent. Priority: phone →
/// call-log report triggers → exact page match → planner task → compose
/// message → enquiry lookup → student lookup → parent Q&A → fuzzy fallback.
AiIntent parseIntent(String q) {
  final norm = q.toLowerCase().trim();

  // 0. Phone number
  final phoneMatch = RegExp(r'^(?:\+91[-\s]?|91[-\s]?)?([6-9]\d{9})$').firstMatch(q.trim());
  if (phoneMatch != null) {
    return PhoneLookupIntent(phoneMatch.group(1)!);
  }

  // 0.5 Call-log reporting intents
  if (RegExp(
    r"\b(report\s+abs[e]?nce|mark\s+abs[e]?nt|child\s+is\s+(sick|ill|unwell)|child\s+(won'?t|cannot|can'?t)\s+(come|attend)|not\s+coming\s+today|sick\s+today|home\s+sick|calling\s+.*abs[e]?nt|abs[e]?nt\s+today)\b",
    caseSensitive: false,
  ).hasMatch(norm)) {
    final nameMatch = RegExp(r"\b(?:mark|report)\s+(?:abs[e]?nt\s+)?(.+?)\s+(?:abs[e]?nt|sick|today)\b", caseSensitive: false).firstMatch(norm) ??
        RegExp(r"\b(.+?)\s+(?:is|won'?t|cannot|can'?t)\s+", caseSensitive: false).firstMatch(norm);
    final rawName = nameMatch != null ? (nameMatch.group(1) ?? '').trim() : '';
    final query = RegExp(r'^(report|mark|child|my|his|her|the)$', caseSensitive: false).hasMatch(rawName) ? '' : rawName;
    return ReportAbsenceIntent(query);
  }

  if (RegExp(r'\bbus\s*(late|delay|breakdown|issue|problem|miss|stuck|not\s+coming|broke)\b|\b(late\s+bus|bus\s+broke|bus\s+is\s+late|bus\s+delay|missed.*bus)\b', caseSensitive: false).hasMatch(norm)) {
    return ReportBusIntent(norm);
  }

  if (RegExp(r'\b(forgot\s+(lunch|food|tiffin)|no\s+lunch|lunch\s+(forgot|concern|issue)|dietary\s+restriction|lunch\s+allergy|allergy\s+remind)\b', caseSensitive: false).hasMatch(norm)) {
    return ReportLunchIntent(norm);
  }

  if (RegExp(r'\b(emergency\s+pickup|early\s+pickup|pick\s+up\s+early|pickup\s+early|urgent\s+pickup|pick\s+(him|her|child)\s+up\s+early)\b', caseSensitive: false).hasMatch(norm)) {
    return ReportEmergencyIntent(norm);
  }

  // 1. Exact page/module match
  final exact = _exactPageMatch(norm);
  if (exact != null) return NavigateIntent(path: exact.path, label: exact.label);

  // 2. Planner task
  final plannerMatch = RegExp(
    r'^add\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s+(.+)',
    caseSensitive: false,
  ).firstMatch(norm);
  if (plannerMatch != null) {
    return PlannerTaskIntent(day: plannerMatch.group(1)!, time: plannerMatch.group(2)!, title: plannerMatch.group(3)!, raw: norm);
  }

  // 3. Compose / draft message
  final composeMatch = RegExp(r'^(compose|draft|write|create|generate)\s+(message|msg|reply|note|letter|email|sms|communication)\s+(?:to|for|about)?\s*(.+)', caseSensitive: false).firstMatch(norm);
  if (composeMatch != null) {
    final topic = composeMatch.group(3);
    return ComposeMessageIntent(topic: (topic != null && topic.isNotEmpty) ? topic : norm, raw: norm);
  }

  // 4. Enquiry lookup — must come before student-lookup ("admission" is in MODULE_KEYWORDS)
  final hasEnquiryKw = RegExp(r'enquir|inquir', caseSensitive: false).hasMatch(norm);
  if (hasEnquiryKw) {
    final enquiryQuery = norm
        .replaceFirst(RegExp(r'^(find|search|lookup|show|get|look up)\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'admission\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'enquir[y]?\s*(for\s+)?', caseSensitive: false), '')
        .replaceFirst(RegExp(r'inquir[y]?\s*(for\s+)?', caseSensitive: false), '')
        .trim();
    if (enquiryQuery.length >= 2) return EnquiryLookupIntent(enquiryQuery);
  }

  // 5. Student lookup
  final hasModuleKw = _moduleKeywords.any((k) => norm.contains(k));
  final lookupVerb = RegExp(r'^(find|search|lookup|show|who is|get)\s+', caseSensitive: false).hasMatch(norm);
  final looksLikeName = RegExp(r"^[a-z][\w\s\-']+$", caseSensitive: false).hasMatch(norm) && norm.split(RegExp(r'\s+')).length <= 4 && !hasModuleKw;

  if (lookupVerb || looksLikeName) {
    final query = norm
        .replaceFirst(RegExp(r'^(find|search|lookup|show|who is|get|look up)\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^student[s]?\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s+student[s]?\s*$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s+class\s*\d+\w*', caseSensitive: false), '')
        .trim();
    if (query.length >= 2 && !RegExp(r'^student[s]?$', caseSensitive: false).hasMatch(query)) {
      return StudentLookupIntent(query);
    }
  }

  // 5. Parent Q&A topics
  final qaTopic = _matchParentQaTopic(norm);
  if (qaTopic != null) return ParentQaIntent(topic: qaTopic, raw: norm);

  // 6. Fuzzy page search fallback
  return FuzzyPagesIntent(norm);
}
