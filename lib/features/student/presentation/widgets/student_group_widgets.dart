import 'package:flutter/material.dart';
import '../../domain/models/student_group.dart';

/// Shared constants/helpers/small widgets for the Student Group screen —
/// ported from frontend
/// app/(dashboard)/student-groups/StudentGroupPage.tsx +
/// styles/student-groups.css.

const List<String> kGroupClasses = [
  'Nursery', 'LKG', 'UKG',
  'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
  'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
];

const List<String> kHouseColors = ['#00b894', '#6c5ce7', '#e67e22', '#e74c3c'];
const List<String> kHouseBgs = ['#e6f9f5', '#f0eeff', '#fef3e8', '#fdeaea'];
const List<String> kClubColors = ['#2980b9', '#27ae60', '#f39c12', '#8e44ad'];
const List<String> kClubBgs = ['#e8f4fd', '#eafaf1', '#fef9e7', '#f5eefb'];
const List<String> kAvatarColors = ['#00b894', '#6c5ce7', '#e67e22', '#2980b9', '#e74c3c', '#27ae60', '#f39c12', '#8e44ad'];

const List<String> kGroupEmojiSuggestions = ['🏛️', '🏫', '🎓', '📚', '🧠', '🧮', '🔬', '🌍', '🎨', '🎼', '🚀', '⚡', '🛡️', '🌟', '🏆', '🕊️', '🌿', '🎯'];
const List<String> kClubEmojiSuggestions = ['🎭', '🔬', '🌿', '➗', '🎵', '⚽', '♟️', '💻', '🧪', '📸', '🎤', '🏀', '🧵', '📖', '🧑‍🏫', '📰', '🤖', '🛰️'];

Color hexColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final letters = parts.map((p) => p[0]).join();
  return letters.substring(0, letters.length < 2 ? letters.length : 2).toUpperCase();
}

Color avatarColorFor(int id) => hexColor(kAvatarColors[id % kAvatarColors.length]);

/// Mirrors `suggestEmojiFromName` — keyword-based emoji suggestion.
String suggestEmojiFromName(String name, String type) {
  final lower = name.trim().toLowerCase();
  const rules = <(List<String>, String)>[
    (['drama', 'theatre', 'theater', 'stage', 'acting'], '🎭'),
    (['science', 'lab', 'stem', 'physics', 'chemistry', 'biology'], '🔬'),
    (['math', 'mathematics', 'number', 'abacus', 'algebra'], '🧮'),
    (['music', 'band', 'choir', 'orchestra'], '🎼'),
    (['art', 'paint', 'drawing', 'design'], '🎨'),
    (['debate', 'speech', 'public speaking', 'moot'], '🎤'),
    (['robot', 'coding', 'code', 'tech', 'computer'], '🤖'),
    (['eco', 'environment', 'green', 'nature'], '🌿'),
    (['space', 'astronomy', 'satellite'], '🛰️'),
    (['sport', 'football', 'soccer', 'cricket', 'basketball'], '🏆'),
    (['literature', 'book', 'reading', 'library'], '📖'),
    (['peace', 'service', 'community'], '🕊️'),
    (['lead', 'leader', 'house', 'captain'], '🏛️'),
  ];
  for (final rule in rules) {
    if (rule.$1.any((k) => lower.contains(k))) return rule.$2;
  }
  if (type == 'HOUSE') return '🏛️';
  if (type == 'CLUB') return '🎭';
  return '📚';
}

/// Mirrors `generateDescriptionFromName` — pure local heuristic (no AI
/// backend call in the reference either; "AI Help" just runs this).
String generateDescriptionFromName(String name, String type) {
  final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleanName.isEmpty) return '';
  final lower = cleanName.toLowerCase();

  String slogan;
  if (lower.contains('science') || lower.contains('stem') || lower.contains('lab')) {
    slogan = 'Experiment with curiosity. Learn with evidence.';
  } else if (lower.contains('math')) {
    slogan = 'Think precisely. Solve confidently.';
  } else if (lower.contains('art')) {
    slogan = 'Imagine freely. Create beautifully.';
  } else if (lower.contains('drama') || lower.contains('theatre') || lower.contains('stage')) {
    slogan = 'Express boldly. Perform with confidence.';
  } else if (lower.contains('music') || lower.contains('band') || lower.contains('choir')) {
    slogan = 'Feel the rhythm. Share the harmony.';
  } else if (lower.contains('eco') || lower.contains('green') || lower.contains('nature')) {
    slogan = 'Protect today. Sustain tomorrow.';
  } else if (lower.contains('debate') || lower.contains('speech')) {
    slogan = 'Speak with clarity. Lead with ideas.';
  } else if (lower.contains('robot') || lower.contains('tech') || lower.contains('coding')) {
    slogan = 'Build smart. Innovate responsibly.';
  } else if (lower.contains('house') || lower.contains('leader') || lower.contains('captain')) {
    slogan = 'Lead with pride. Serve with purpose.';
  } else {
    slogan = type == 'HOUSE'
        ? 'Unity in spirit. Excellence in action.'
        : type == 'CLUB'
            ? 'Discover talents. Grow together.'
            : 'Belong, build, become.';
  }

  final String body;
  if (type == 'HOUSE') {
    body = '$cleanName strengthens school culture through leadership, discipline, mentoring, and inter-house '
        'participation that builds confidence and responsibility across every grade.';
  } else if (type == 'CLUB') {
    body = '$cleanName offers students a guided platform to practise core skills, collaborate on projects, '
        'prepare for competitions or showcases, and learn through consistent mentor support.';
  } else {
    body = '$cleanName brings students together around shared goals, positive identity, and meaningful '
        'participation in academics, campus events, and peer collaboration.';
  }

  return '$slogan\n$body';
}

/// Mirrors `.sg-pill` — a rounded toggle chip used across the Smart Filter.
class GroupPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const GroupPill({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6C5CE7) : Colors.white,
          border: Border.all(color: active ? const Color(0xFF6C5CE7) : const Color(0xFFE2E6F0)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: active ? Colors.white : const Color(0xFF4A5A7A)),
        ),
      ),
    );
  }
}

/// Mirrors `.sc` — one of the five header stat tiles.
class GroupStatCard extends StatelessWidget {
  final String eyebrow;
  final String value;
  final String label;
  final Color barColor;
  const GroupStatCard({super.key, required this.eyebrow, required this.value, required this.label, required this.barColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFFBFCFF)]),
        border: Border.all(color: const Color(0xFFE2E6F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(left: -14, top: -14, bottom: -14, width: 4, child: Container(color: barColor)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eyebrow.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFF8FA3C8))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF1A2744), height: 0.95, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8FA3C8))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mirrors `.hc` — a School House card.
class HouseCard extends StatelessWidget {
  final StudentGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const HouseCard({super.key, required this.group, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = hexColor(group.color);
    final bg = hexColor(group.bgColor);
    final pct = group.capacity > 0 ? (group.studentsCount / group.capacity * 100).clamp(0, 100).round() : 0;
    final desc = group.splitDescription;
    final motto = desc.slogan.isNotEmpty ? desc.slogan : (desc.body.isNotEmpty ? desc.body : 'Student leadership and house identity');
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 9),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                  child: Text(group.emoji, style: const TextStyle(fontSize: 17)),
                ),
                Text(group.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2744)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(motto, style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8), fontStyle: FontStyle.italic, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${group.studentsCount}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('students', style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('of ${group.capacity}', style: const TextStyle(fontSize: 10, color: Color(0xFF8FA3C8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: pct / 100, minHeight: 5, backgroundColor: const Color(0xFFF0F2F8), valueColor: AlwaysStoppedAnimation(color)),
                ),
                Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(top: 3), child: Text('$pct%', style: const TextStyle(fontSize: 10, color: Color(0xFF8FA3C8))))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(15, 9, 15, 11),
            decoration: const BoxDecoration(color: Color(0xFFFAFBFD), border: Border(top: BorderSide(color: Color(0xFFE2E6F0)))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${group.studentsCount} student${group.studentsCount != 1 ? 's' : ''} assigned',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _iconBtn(Icons.edit_outlined, onEdit),
                const SizedBox(width: 5),
                _iconBtn(Icons.delete_outline, onDelete, danger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(6), color: Colors.white),
        child: Icon(icon, size: 14, color: danger ? const Color(0xFFE74C3C) : const Color(0xFF4A5A7A)),
      ),
    );
  }
}

/// Mirrors `.cc` — a School Club card.
class ClubCard extends StatelessWidget {
  final StudentGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ClubCard({super.key, required this.group, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = hexColor(group.color);
    final bg = hexColor(group.bgColor);
    final desc = group.splitDescription;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                child: Text(group.emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // No maxLines/ellipsis — full club name (e.g. "Stagecraft
                    // and Performance") wraps onto a second line instead of
                    // being cut short.
                    Text(group.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2744), height: 1.25)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                      child: Text('CLUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: color)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (desc.slogan.isNotEmpty || desc.body.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (desc.slogan.isNotEmpty) Text(desc.slogan, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A2744)), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (desc.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(desc.body, style: const TextStyle(fontSize: 11.5, color: Color(0xFF8FA3C8), height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis)),
              ],
            )
          else
            const Text('Student-led activities and collaborative learning.', style: TextStyle(fontSize: 11.5, color: Color(0xFF8FA3C8), height: 1.5)),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF0F2F8), border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${group.studentsCount} / ${group.capacity}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A5A7A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _iconBtn(Icons.edit_outlined, onEdit),
              const SizedBox(width: 5),
              _iconBtn(Icons.delete_outline, onDelete, danger: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E6F0)), borderRadius: BorderRadius.circular(6), color: Colors.white),
        child: Icon(icon, size: 14, color: danger ? const Color(0xFFE74C3C) : const Color(0xFF4A5A7A)),
      ),
    );
  }
}

/// Mirrors `.cc-ghost` — the dashed "New Club" add-card.
class NewClubGhostCard extends StatelessWidget {
  final VoidCallback onTap;
  const NewClubGhostCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 130),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD0D8EC), width: 1.5, style: BorderStyle.solid)),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DashedCircle(),
              SizedBox(height: 8),
              Text('New Club', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB5C4D8))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB5C4D8), width: 1.5)),
      child: const Text('+', style: TextStyle(fontSize: 18, color: Color(0xFFB5C4D8))),
    );
  }
}

/// Mirrors `.toast` — a fixed dark pill that slides in from the top-right.
class GroupToastOverlay extends StatelessWidget {
  final String message;
  final bool visible;
  const GroupToastOverlay({super.key, required this.message, required this.visible});

  @override
  Widget build(BuildContext context) {
    // Positioned (via AnimatedPositioned) must be a direct child of the
    // ancestor Stack — IgnorePointer has to wrap the content *inside* it,
    // not sit above it, or Stack can't attach StackParentData.
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      top: visible ? 20 : -20,
      right: 24,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1 : 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFF1A2744), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x291A2744), blurRadius: 18, offset: Offset(0, 4))]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00B894), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Flexible(child: Text(message, style: const TextStyle(fontSize: 12.5, color: Colors.white), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
