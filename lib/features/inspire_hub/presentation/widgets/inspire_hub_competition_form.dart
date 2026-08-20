import 'package:flutter/material.dart';

import '../../../student/domain/models/student_group.dart';
import '../../../student/presentation/widgets/student_group_widgets.dart' show hexColor;
import '../../domain/inspire_hub_store.dart' show titleCaseInspireHub;
import '../../domain/models/competition.dart';

/// The competition details form — used both to create a brand-new event
/// (from the Compose tab) and to edit an existing one (from
/// InspireHubResultsPage's "Edit details" toggle). Mirrors web's
/// CompetitionForm.jsx: quick-start presets, icon type-chips, level
/// dropdown, house/class/section scope pickers, and AI-assisted name/notes
/// suggestions.
class CompetitionFormCard extends StatefulWidget {
  final Competition? editing;
  final List<StudentGroup> houses;
  final List<GroupStudentRow> allStudents;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  const CompetitionFormCard({super.key, required this.editing, required this.houses, required this.allStudents, required this.onSubmit});

  @override
  State<CompetitionFormCard> createState() => _CompetitionFormCardState();
}

const _kQuickPresets = <(String label, String icon, String compType, String level, String location)>[
  ('Inter-House Quiz', '🏠📚', 'academic', 'inter_house', 'Auditorium'),
  ('Inter-House Sports', '🏠🏆', 'sports', 'inter_house', 'School Ground'),
  ('Annual Cultural', '🎭', 'cultural', 'intra_school', 'Auditorium'),
  ('Inter-School Debate', '🎤', 'debate', 'inter_school', ''),
  ('Science Fair', '🔬', 'stem', 'intra_school', 'Science Lab'),
];

String _suggestName(String compType, String level, String date, StudentGroup? houseA, StudentGroup? houseB) {
  const typeMap = {
    'academic': 'Quiz',
    'sports': 'Tournament',
    'cultural': 'Festival',
    'arts': 'Showcase',
    'debate': 'Debate',
    'stem': 'Challenge',
    'other': 'Competition',
  };
  final t = typeMap[compType] ?? 'Competition';
  if (level == 'inter_house' && houseA != null && houseB != null) {
    return 'Inter-House $t Final · ${houseA.name} vs ${houseB.name}';
  }
  final lvl = CompetitionLevel.fromValue(level).label;
  final year = DateTime.tryParse(date)?.year ?? DateTime.now().year;
  return '$lvl $t $year'.trim();
}

String _suggestNotes(String compType, String level, String name, String location, StudentGroup? houseA, StudentGroup? houseB) {
  const typeBlurb = {
    'academic': 'Tests subject mastery, quick recall, and clear reasoning under timed pressure.',
    'sports': 'Emphasises teamwork, stamina, sportsmanship, and tactical awareness.',
    'cultural': 'Celebrates expression, stagecraft, originality, and cultural awareness.',
    'arts': 'Rewards creativity, technique, composition, and emotional storytelling.',
    'debate': 'Judged on argument structure, evidence, rebuttal, and persuasive delivery.',
    'stem': 'Assesses problem-solving, scientific method, innovation, and presentation.',
    'other': 'Recognises preparation, effort, and graceful conduct throughout the event.',
  };
  final lvl = CompetitionLevel.fromValue(level).label;
  final parts = <String>[
    'Event: ${name.isEmpty ? '(untitled)' : name} · $lvl${location.isNotEmpty ? ' at $location' : ''}.',
    typeBlurb[compType] ?? '',
  ];
  if (level == 'inter_house' && houseA != null && houseB != null) {
    parts.add('Finalist houses: ${houseA.name} vs ${houseB.name}. Encourage healthy rivalry, team spirit, and respect for opponents.');
  }
  parts.add('Tone for reviews: warm, age-appropriate, confidence-building. Highlight effort over outcome and offer one concrete next step.');
  return parts.join(' ');
}

class _CompetitionFormCardState extends State<CompetitionFormCard> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _location = TextEditingController(text: widget.editing?.location ?? '');
  late final TextEditingController _opponent = TextEditingController(text: widget.editing?.opponent ?? '');
  late final TextEditingController _notes = TextEditingController(text: widget.editing?.notes ?? '');
  late String _date = widget.editing?.date ?? DateTime.now().toIso8601String().substring(0, 10);
  late String _level = widget.editing?.level.value ?? 'intra_school';
  late String _compType = widget.editing?.compType.value ?? 'academic';
  late int? _houseAId = widget.editing?.houseAId;
  late int? _houseBId = widget.editing?.houseBId;
  late final List<String> _classes = List.of(widget.editing?.classes ?? const []);
  late String _className = widget.editing?.className ?? '';
  late List<String> _sections = List.of(widget.editing?.sections ?? const []);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _opponent.dispose();
    _notes.dispose();
    super.dispose();
  }

  List<String> get _allClasses {
    final set = <String>{};
    for (final s in widget.allStudents) {
      if (s.className.isNotEmpty && s.className != '-') set.add(s.className);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get _sectionsForClass {
    if (_className.isEmpty) return const [];
    final set = <String>{};
    for (final s in widget.allStudents) {
      if (s.className == _className && s.sectionName.isNotEmpty && s.sectionName != '-') set.add(s.sectionName);
    }
    return set.toList()..sort();
  }

  StudentGroup? _house(int? id) => id == null ? null : widget.houses.where((h) => h.id == id).firstOrNull;

  void _applyPreset((String, String, String, String, String) preset) {
    setState(() {
      _compType = preset.$3;
      _level = preset.$4;
      _location.text = preset.$5;
      _name.text = _suggestName(_compType, _level, _date, _house(_houseAId), _house(_houseBId));
      _notes.text = _suggestNotes(_compType, _level, _name.text, _location.text, _house(_houseAId), _house(_houseBId));
    });
  }

  void _pickHouse(String slot, int id) {
    setState(() {
      if (slot == 'a') {
        if (_houseAId == id) {
          _houseAId = null;
        } else if (_houseBId == id) {
          _houseBId = _houseAId;
          _houseAId = id;
        } else {
          _houseAId = id;
        }
      } else {
        if (_houseBId == id) {
          _houseBId = null;
        } else if (_houseAId == id) {
          _houseAId = _houseBId;
          _houseBId = id;
        } else {
          _houseBId = id;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked.toIso8601String().substring(0, 10));
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Please give the competition a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await widget.onSubmit({
      'name': titleCaseInspireHub(_name.text.trim()),
      'date': _date,
      'level': _level,
      'comp_type': _compType,
      'location': _location.text.trim(),
      'opponent': _opponent.text.trim(),
      'notes': _notes.text.trim(),
      'house_a_id': _houseAId,
      'house_b_id': _houseBId,
      'classes': _classes,
      'class_name': _className,
      'sections': _sections,
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isInterHouse = _level == 'inter_house';
    final isInterClass = _level == 'inter_class';
    final isIntraClass = _level == 'intra_class';
    final houseA = _house(_houseAId);
    final houseB = _house(_houseBId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Competition details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in _kQuickPresets)
                OutlinedButton(
                  onPressed: () => _applyPreset(p),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                  child: Text('${p.$2} ${p.$1}', style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Name *'),
          Row(
            children: [
              Expanded(child: TextField(controller: _name, decoration: buildInputDecoration('e.g. Inter-House Quiz Championship'))),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Suggest a name',
                onPressed: () => setState(() => _name.text = _suggestName(_compType, _level, _date, houseA, houseB)),
                icon: const Text('✨', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _label('Date'),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: buildInputDecoration(null),
              child: Text(_date, style: const TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 10),
          _label('Type'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in CompetitionType.values)
                ChoiceChip(
                  label: Text('${t.icon} ${t.label}', style: const TextStyle(fontSize: 11.5)),
                  selected: _compType == t.value,
                  onSelected: (_) => setState(() => _compType = t.value),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _label('Level'),
          DropdownButtonFormField<String>(
            initialValue: _level,
            decoration: buildInputDecoration(null),
            items: [for (final l in CompetitionLevel.values) DropdownMenuItem(value: l.value, child: Text(l.label))],
            onChanged: (v) => setState(() => _level = v ?? _level),
          ),
          const SizedBox(height: 10),
          _label('Location'),
          TextField(controller: _location, decoration: buildInputDecoration('School auditorium')),
          const SizedBox(height: 10),
          if (!isInterHouse && !isInterClass && !isIntraClass) ...[
            _label('Opponent / Host'),
            TextField(controller: _opponent, decoration: buildInputDecoration('Optional')),
            const SizedBox(height: 10),
          ],
          if (isInterClass) _scopeCard(
            icon: '🎓',
            title: 'Pick the participating classes',
            hint: 'select 2 or more',
            color: const Color(0xFF0EA5E9),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in _allClasses)
                  ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 11.5)),
                    selected: _classes.contains(c),
                    onSelected: (_) => setState(() => _classes.contains(c) ? _classes.remove(c) : _classes.add(c)),
                  ),
              ],
            ),
          ),
          if (isIntraClass) _scopeCard(
            icon: '🏫',
            title: 'Pick the class',
            hint: 'single class',
            color: const Color(0xFF10B981),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in _allClasses)
                      ChoiceChip(
                        label: Text(c, style: const TextStyle(fontSize: 11.5)),
                        selected: _className == c,
                        onSelected: (_) => setState(() {
                          _className = _className == c ? '' : c;
                          _sections = [];
                        }),
                      ),
                  ],
                ),
                if (_className.isNotEmpty && _sectionsForClass.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in _sectionsForClass)
                        ChoiceChip(
                          label: Text('Sec $s', style: const TextStyle(fontSize: 11)),
                          selected: _sections.contains(s),
                          onSelected: (_) => setState(() => _sections.contains(s) ? _sections.remove(s) : _sections.add(s)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isInterHouse) _scopeCard(
            icon: '🏠',
            title: 'Pick the two finalist houses',
            hint: 'tap once for A, again for B',
            color: const Color(0xFF7C3AED),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in widget.houses)
                  HouseTile(
                    house: h,
                    slot: _houseAId == h.id ? 'A' : (_houseBId == h.id ? 'B' : null),
                    onTap: () => _pickHouse(_houseAId == h.id || _houseBId == h.id ? (_houseAId == h.id ? 'a' : 'b') : (_houseAId == null ? 'a' : 'b'), h.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _label('Notes for AI context')),
              TextButton(
                onPressed: () => setState(() => _notes.text = _suggestNotes(_compType, _level, _name.text, _location.text, houseA, houseB)),
                child: const Text('✨ Auto-fill', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          TextField(controller: _notes, maxLines: 3, decoration: buildInputDecoration('Themes, judging criteria, special challenges…')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              child: Text(_saving ? 'Saving…' : (widget.editing == null ? 'Continue →' : 'Save changes')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF64748B))),
  );

  Widget _scopeCard({required String icon, required String title, required String hint, required Color color, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.06), border: Border.all(color: color.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text(icon), const SizedBox(width: 6), Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))), Text(hint, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))]),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class HouseTile extends StatelessWidget {
  final StudentGroup house;
  final String? slot;
  final VoidCallback onTap;
  const HouseTile({super.key, required this.house, required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = hexColor(house.color);
    final on = slot != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: on ? color.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(color: on ? color : const Color(0xFFE2E8F0), width: on ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 12, backgroundColor: color, child: Text(house.emoji, style: const TextStyle(fontSize: 11))),
            const SizedBox(width: 6),
            Text(house.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? color : const Color(0xFF334155))),
            if (on) ...[const SizedBox(width: 6), Text(slot!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))],
          ],
        ),
      ),
    );
  }
}

InputDecoration buildInputDecoration(String? hint) => InputDecoration(
  isDense: true,
  hintText: hint,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
);
