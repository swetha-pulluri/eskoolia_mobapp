import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/filter_pill_widget.dart';
import '../../../domain/entities/student_list_item_entity.dart';
import '../../providers/my_classes_providers.dart';
import 'load_error_card.dart';

(Color bg, Color text) _genderColors(String gender) {
  switch (gender.toLowerCase()) {
    case 'male':
      return (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8));
    case 'female':
      return (const Color(0xFFFDF4FF), const Color(0xFFA21CAF));
    default:
      return (const Color(0xFFF5F5FB), AppColors.ink2);
  }
}

String _genderLabel(String gender) {
  switch (gender.toLowerCase()) {
    case 'male':
      return 'Male';
    case 'female':
      return 'Female';
    case 'other':
      return 'Other';
    default:
      return gender.isEmpty ? '—' : gender;
  }
}

Color _attendanceColor(double pct) {
  if (pct >= 75) return const Color(0xFF15803D);
  if (pct >= 50) return const Color(0xFFB45309);
  return const Color(0xFFB42318);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final letters = parts.map((p) => p[0]).take(2).join();
  return letters.toUpperCase();
}

/// Search + gender-filter + roster list for the active class — mirrors
/// `StudentTable` in `classes/page.tsx`. Give this widget a
/// `key: ValueKey(activeClassIndex)` from the parent so switching class
/// tabs remounts it, resetting search/filter state exactly like web's own
/// `useEffect` reset keyed on a fresh `students` array reference.
class StudentRoster extends ConsumerStatefulWidget {
  final void Function(int studentId) onSelectStudent;

  const StudentRoster({super.key, required this.onSelectStudent});

  @override
  ConsumerState<StudentRoster> createState() => _StudentRosterState();
}

const List<(String, String)> _genderFilters = [
  ('all', 'All'),
  ('male', 'Male'),
  ('female', 'Female'),
  ('other', 'Other'),
];

class _StudentRosterState extends ConsumerState<StudentRoster> {
  final _searchController = TextEditingController();
  String _search = '';
  String _genderFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsForActiveClassProvider);

    return studentsAsync.when(
      loading: () => Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(height: 44, decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ),
      error: (error, _) => LoadErrorCard(
        title: 'Could not load students',
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(studentsForActiveClassProvider),
        iconSize: 28,
        padding: const EdgeInsets.symmetric(vertical: 24),
      ),
      data: (students) {
        if (students.isEmpty) {
          return _emptyBlock(
            icon: Icons.people_outline,
            title: 'No students yet',
            subtitle: 'No active students are enrolled in this class section.',
            dashed: true,
          );
        }

        final query = _search.trim().toLowerCase();
        final filtered = students.where((s) {
          final matchesGender = _genderFilter == 'all' || s.gender.toLowerCase() == _genderFilter;
          if (!matchesGender) return false;
          if (query.isEmpty) return true;
          return s.name.toLowerCase().contains(query) ||
              s.rollNo.toLowerCase().contains(query) ||
              s.admissionNo.toLowerCase().contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchAndFilterBar(students.length, filtered.length),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              _emptyBlock(icon: Icons.search, title: 'No results', subtitle: 'No students match your search.', dashed: false)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 700) return _wideTable(filtered);
                  return _narrowCardList(filtered);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _searchAndFilterBar(int total, int filteredCount) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.search, size: 14, color: AppColors.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search by name, roll or admission no…',
                    ),
                  ),
                ),
                if (_search.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() {
                      _searchController.clear();
                      _search = '';
                    }),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.close, size: 14, color: AppColors.ink3),
                    ),
                  ),
              ],
            ),
          ),
        ),
        for (final (value, label) in _genderFilters)
          FilterPill(label: label, isSelected: _genderFilter == value, onTap: () => setState(() => _genderFilter = value)),
        Text('$filteredCount of $total student(s)', style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
      ],
    );
  }

  Widget _emptyBlock({required IconData icon, required String title, required String subtitle, required bool dashed}) {
    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: dashed ? 56 : 40, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: dashed ? 32 : 26, color: AppColors.ink3.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink1)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
        ],
      ),
    );
    if (!dashed) return content;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  Widget _avatar(StudentListItemEntity s) {
    final (bg, fg) = _genderColors(s.gender);
    return CircleAvatar(
      radius: 16,
      backgroundColor: bg,
      backgroundImage: s.photoUrl != null ? NetworkImage(s.photoUrl!) : null,
      child: s.photoUrl == null ? Text(_initials(s.name), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)) : null,
    );
  }

  Widget _wideTable(List<StudentListItemEntity> students) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.bg2),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('#', style: _headerStyle)),
            DataColumn(label: Text('STUDENT', style: _headerStyle)),
            DataColumn(label: Text('ROLL NO.', style: _headerStyle)),
            DataColumn(label: Text('ADMISSION NO.', style: _headerStyle)),
            DataColumn(label: Text('GENDER', style: _headerStyle)),
            DataColumn(label: Text('ATTENDANCE', style: _headerStyle)),
            DataColumn(label: Text('AVG. SCORE', style: _headerStyle)),
          ],
          rows: [
            for (var i = 0; i < students.length; i++) _dataRow(i, students[i]),
          ],
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink3, letterSpacing: 0.5);

  DataRow _dataRow(int index, StudentListItemEntity s) {
    final (genderBg, genderFg) = _genderColors(s.gender);
    return DataRow(
      onSelectChanged: (_) => widget.onSelectStudent(s.id),
      cells: [
        DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 11, color: AppColors.ink3))),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(s),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                Text(
                  'ID: ${s.studentId.length > 8 ? '${s.studentId.substring(0, 8)}…' : s.studentId}',
                  style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                ),
              ],
            ),
          ],
        )),
        DataCell(Text(s.rollNo.isEmpty ? '—' : s.rollNo, style: const TextStyle(fontSize: 13, color: AppColors.ink1))),
        DataCell(Text(s.admissionNo.isEmpty ? '—' : s.admissionNo, style: const TextStyle(fontSize: 12, color: AppColors.ink2, fontFamily: 'monospace'))),
        DataCell(
          s.gender.isEmpty
              ? const Text('—', style: TextStyle(color: AppColors.ink3))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: genderBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(_genderLabel(s.gender), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: genderFg)),
                ),
        ),
        DataCell(
          s.attendancePct == null
              ? const Text('—', style: TextStyle(fontSize: 11, color: AppColors.ink3, fontStyle: FontStyle.italic))
              : Text(
                  '${s.attendancePct!.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _attendanceColor(s.attendancePct!)),
                ),
        ),
        DataCell(
          s.avgScore == null
              ? const Text('—', style: TextStyle(fontSize: 11, color: AppColors.ink3, fontStyle: FontStyle.italic))
              : Text(s.avgScore!.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink1)),
        ),
      ],
    );
  }

  Widget _narrowCardList(List<StudentListItemEntity> students) {
    return Column(
      children: [
        for (final s in students)
          InkWell(
            onTap: () => widget.onSelectStudent(s.id),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  _avatar(s),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                        const SizedBox(height: 2),
                        Text(
                          'Roll ${s.rollNo.isEmpty ? '—' : s.rollNo} · Adm. ${s.admissionNo.isEmpty ? '—' : s.admissionNo}',
                          style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (s.attendancePct != null)
                        Text(
                          '${s.attendancePct!.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _attendanceColor(s.attendancePct!)),
                        ),
                      if (s.gender.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_genderLabel(s.gender), style: const TextStyle(fontSize: 10, color: AppColors.ink3)),
                      ],
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
