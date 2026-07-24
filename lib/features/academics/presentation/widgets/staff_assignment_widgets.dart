// Staff Assignment — ports of KpiCards, SubjectTeacherRow, SectionCard and
// ClassAccordion from components/academics/StaffAssignmentPanels.tsx.

import 'package:flutter/material.dart';

import '../../domain/entities/class_entity.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/entities/staff_assignment_entities.dart';

Widget _spinner({Color color = Colors.white, double size = 14}) {
  return SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 2, color: color));
}

// ─── KPI Cards ────────────────────────────────────────────────────────────

class StaffKpiCards extends StatelessWidget {
  final StaffKpi? kpi;
  const StaffKpiCards({super.key, required this.kpi});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (label: 'Total Teachers', value: '${kpi?.totalTeachers ?? 0}', icon: Icons.people_outline, bg: staffBrandSoft, fg: staffBrand),
      (label: 'CT Assigned', value: '${kpi?.ctAssigned ?? 0}', icon: Icons.how_to_reg_outlined, bg: const Color(0xFFF0FDF4), fg: const Color(0xFF15803D)),
      (label: 'Avg Load / Week', value: kpi != null && kpi!.avgLoad > 0 ? '${kpi!.avgLoad}p' : '—', icon: Icons.show_chart, bg: const Color(0xFFEFF6FF), fg: const Color(0xFF1D4ED8)),
      (label: 'Overloaded', value: '${kpi?.overloaded ?? 0}', icon: Icons.warning_amber_rounded, bg: const Color(0xFFFEF2F2), fg: const Color(0xFFB91C1C)),
    ];
    Widget buildCard(({String label, String value, IconData icon, Color bg, Color fg}) c) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: staffLine), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(12)), child: Icon(c.icon, size: 18, color: c.fg)),
          const SizedBox(height: 8),
          Text(c.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(c.label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.3)),
        ]),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: buildCard(cards[0])), const SizedBox(width: 12), Expanded(child: buildCard(cards[1]))]),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: buildCard(cards[2])), const SizedBox(width: 12), Expanded(child: buildCard(cards[3]))]),
    ]);
  }
}

// ─── Subject Teacher Row ───────────────────────────────────────────────────

class StaffSubjectTeacherRow extends StatefulWidget {
  final StaffSubjectRow row;
  final String subjectName;
  final (Color bg, Color fg, Color border) colors;
  final List<StaffTeacher> teachers;
  final Future<void> Function(int rowId, int teacherId) onSave;
  final bool saving;

  const StaffSubjectTeacherRow({super.key, required this.row, required this.subjectName, required this.colors, required this.teachers, required this.onSave, required this.saving});

  @override
  State<StaffSubjectTeacherRow> createState() => _StaffSubjectTeacherRowState();
}

class _StaffSubjectTeacherRowState extends State<StaffSubjectTeacherRow> {
  int? _selected;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.row.teacherId;
    _editing = widget.row.teacherId == null;
  }

  @override
  void didUpdateWidget(covariant StaffSubjectTeacherRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.teacherId != widget.row.teacherId) {
      _selected = widget.row.teacherId;
      _editing = widget.row.teacherId == null;
    }
  }

  StaffTeacher? _assignedTeacher() {
    for (final t in widget.teachers) {
      if (t.id == widget.row.teacherId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final assigned = _assignedTeacher();
    final isOverloaded = assigned?.periodsPerWeek != null && assigned!.periodsPerWeek! > 28;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 148,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: widget.colors.$1, border: Border.all(color: widget.colors.$3), borderRadius: BorderRadius.circular(6)),
            child: Text(widget.subjectName, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.colors.$2)),
          ),
        ),
        Expanded(
          child: _editing
              ? DropdownButtonFormField<int>(
                  initialValue: _selected,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: widget.saving ? const Color(0xFFF3F4F6) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: staffBrand)),
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                  items: widget.teachers.map((t) {
                    final over = t.periodsPerWeek != null && t.periodsPerWeek! > 28;
                    final label = '${over ? '⚠ ' : ''}${t.fullName}${t.periodsPerWeek != null ? ' (${t.periodsPerWeek}/28)' : ''}';
                    return DropdownMenuItem(value: t.id, child: Text(label, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: widget.saving ? null : (v) => setState(() => _selected = v),
                )
              : Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text.rich(
                        TextSpan(children: [
                          if (isOverloaded) const TextSpan(text: '⚠ '),
                          TextSpan(text: assigned?.fullName ?? widget.row.teacherName),
                        ]),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOverloaded ? const Color(0xFFB91C1C) : const Color(0xFF1F2937)),
                      ),
                      if (assigned?.periodsPerWeek != null)
                        Text('${assigned!.periodsPerWeek}/28 periods', style: TextStyle(fontSize: 11, color: isOverloaded ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF))),
                    ]),
                  ),
                  if (isOverloaded)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('OVERLOADED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C))),
                    ),
                ]),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 104,
          child: Align(
            alignment: Alignment.centerRight,
            child: _editing
                ? ElevatedButton(
                    onPressed: (widget.saving || _selected == null) ? null : () => widget.onSave(widget.row.id, _selected!).then((_) => setState(() => _editing = false)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: staffBrand,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: staffBrand.withValues(alpha: 0.4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: widget.saving
                        ? _spinner(size: 12)
                        : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline, size: 11, color: Colors.white), SizedBox(width: 4), Text('Assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]),
                  )
                : OutlinedButton(
                    onPressed: () => setState(() => _editing = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_outlined, size: 11), SizedBox(width: 4), Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]),
                  ),
          ),
        ),
      ]),
    );
  }
}

// ─── Section Card ───────────────────────────────────────────────────────────

class StaffSectionCard extends StatefulWidget {
  final FoundationSection section;
  final List<StaffTeacher> teachers;
  final List<StaffSubjectRow> subjectRows;
  final CTAssignment? ctAssignment;
  final List<CTAssignment> ctAssignments;
  final Future<void> Function(int sectionId, int teacherId) onCTConfirmLock;
  final void Function(int ctId, String currentTeacherName) onCTEditRequest;
  final Future<void> Function(int rowId, int teacherId) onSubjectSave;
  final Set<int> savingSubjKeys;
  final bool savingCT;
  final bool isOpen;
  final VoidCallback onToggle;

  const StaffSectionCard({
    super.key,
    required this.section,
    required this.teachers,
    required this.subjectRows,
    required this.ctAssignment,
    required this.ctAssignments,
    required this.onCTConfirmLock,
    required this.onCTEditRequest,
    required this.onSubjectSave,
    required this.savingSubjKeys,
    required this.savingCT,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<StaffSectionCard> createState() => _StaffSectionCardState();
}

class _StaffSectionCardState extends State<StaffSectionCard> {
  int? _selectedCT;

  @override
  void initState() {
    super.initState();
    _selectedCT = widget.ctAssignment?.teacherId;
  }

  @override
  void didUpdateWidget(covariant StaffSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ctAssignment?.teacherId != widget.ctAssignment?.teacherId) {
      _selectedCT = widget.ctAssignment?.teacherId;
    }
  }

  String? get _ctValidationError {
    if (_selectedCT == null) return null;
    final existing = widget.ctAssignments.where((ct) => ct.teacherId == _selectedCT && ct.sectionId != widget.section.id);
    if (existing.isNotEmpty) return 'This teacher is already assigned as Class Teacher for another section.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.ctAssignment?.isLocked ?? false;
    final ctTeacherName = widget.ctAssignment == null
        ? ''
        : (widget.teachers.where((t) => t.id == widget.ctAssignment!.teacherId).firstOrNull?.fullName ?? widget.ctAssignment!.teacherName);
    final validationError = _ctValidationError;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              Icon(widget.isOpen ? Icons.expand_more : Icons.chevron_right, size: 16, color: const Color(0xFF9CA3AF)),
              Text('Sec ${widget.section.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              Text('Strength: ${widget.section.capacity}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              Text('| ${widget.subjectRows.length} Subject${widget.subjectRows.length != 1 ? 's' : ''} Assigned', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), border: Border.all(color: const Color(0xFFBBF7D0)), borderRadius: BorderRadius.circular(999)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_outline, size: 11, color: Color(0xFF15803D)),
                    SizedBox(width: 6),
                    Text('CT Assigned', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                  ]),
                ),
            ]),
          ),
        ),
        if (widget.isOpen)
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              // Class Teacher block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('CLASS TEACHER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 1)),
                  ),
                  if (isLocked)
                    Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Container(
                        constraints: const BoxConstraints(minWidth: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), border: Border.all(color: const Color(0xFFBBF7D0)), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_outline, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 10),
                          Flexible(child: Text(ctTeacherName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF166534)))),
                        ]),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          if (widget.ctAssignment != null) widget.onCTEditRequest(widget.ctAssignment!.id, ctTeacherName);
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFFFFBEB), foregroundColor: const Color(0xFFB45309), side: const BorderSide(color: Color(0xFFFDE68A)), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_outlined, size: 12), SizedBox(width: 4), Text('Edit Class Teacher', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]),
                      ),
                    ])
                  else
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedCT,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: validationError != null ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: validationError != null ? const Color(0xFFF87171) : const Color(0xFFE5E7EB))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: validationError != null ? const Color(0xFFF87171) : const Color(0xFFE5E7EB))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: validationError != null ? const Color(0xFFEF4444) : staffBrand)),
                            ),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                            items: widget.teachers.map((t) {
                              final assignedElsewhere = widget.ctAssignments.any((ct) => ct.teacherId == t.id && ct.sectionId != widget.section.id);
                              final label = '${t.fullName}${t.periodsPerWeek != null ? ' (${t.periodsPerWeek}p)' : ''}${assignedElsewhere ? ' - Already CT: Another Section' : ''}';
                              return DropdownMenuItem(value: t.id, enabled: !assignedElsewhere, child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: assignedElsewhere ? const Color(0xFF9CA3AF) : null)));
                            }).toList(),
                            onChanged: widget.savingCT ? null : (v) => setState(() => _selectedCT = v),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: (_selectedCT == null || widget.savingCT || validationError != null) ? null : () => widget.onCTConfirmLock(widget.section.id, _selectedCT!),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.4), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (widget.savingCT) ...[_spinner(size: 15), const SizedBox(width: 8)] else ...[const Icon(Icons.check_circle_outline, size: 15), const SizedBox(width: 8)],
                            const Text('Confirm & Lock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                      if (validationError != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(8)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(validationError, style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)))),
                          ]),
                        ),
                    ]),
                ]),
              ),
              // Subject Teachers block
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Text('SUBJECT TEACHERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 1)),
                      if (widget.subjectRows.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
                          child: Text('${widget.subjectRows.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                        ),
                    ]),
                  ),
                  if (widget.subjectRows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: Text('No subjects configured. Set up subjects in Foundation first.', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 480,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: const [
                              SizedBox(width: 148, child: Text('SUBJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
                              Expanded(child: Text('TEACHER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
                              SizedBox(width: 8),
                              SizedBox(width: 104, child: Text('ACTION', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
                            ]),
                          ),
                          for (var i = 0; i < widget.subjectRows.length; i++)
                            StaffSubjectTeacherRow(
                              key: ValueKey(widget.subjectRows[i].id),
                              row: widget.subjectRows[i],
                              subjectName: widget.subjectRows[i].subjectName.isNotEmpty ? widget.subjectRows[i].subjectName : 'Subject ${widget.subjectRows[i].subjectId}',
                              colors: staffSubjectPillColors[i % staffSubjectPillColors.length],
                              teachers: widget.teachers,
                              onSave: widget.onSubjectSave,
                              saving: widget.savingSubjKeys.contains(widget.subjectRows[i].id),
                            ),
                        ]),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ─── Class Accordion ────────────────────────────────────────────────────────

class StaffClassAccordion extends StatefulWidget {
  final FoundationClass cls;
  final (Color bg, Color fg) badgeColors;
  final List<FoundationSection> sections;
  final List<StaffTeacher> teachers;
  final List<StaffSubjectRow> subjectRows;
  final List<CTAssignment> ctAssignments;
  final Future<void> Function(int sectionId, int teacherId) onCTConfirmLock;
  final void Function(int ctId, String name) onCTEditRequest;
  final Future<void> Function(int rowId, int teacherId) onSubjectSave;
  final Set<int> savingCTSects;
  final Set<int> savingSubjKeys;

  const StaffClassAccordion({
    super.key,
    required this.cls,
    required this.badgeColors,
    required this.sections,
    required this.teachers,
    required this.subjectRows,
    required this.ctAssignments,
    required this.onCTConfirmLock,
    required this.onCTEditRequest,
    required this.onSubjectSave,
    required this.savingCTSects,
    required this.savingSubjKeys,
  });

  @override
  State<StaffClassAccordion> createState() => _StaffClassAccordionState();
}

class _StaffClassAccordionState extends State<StaffClassAccordion> {
  bool _open = false;
  int? _openSectionId;

  @override
  Widget build(BuildContext context) {
    final classSections = widget.sections.where((s) => s.classId == widget.cls.id).toList();
    final confirmedCT = widget.ctAssignments.where((ct) => ct.isLocked).length;
    final classSubjects = widget.subjectRows.map((r) => r.subjectId).toSet().length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: staffLine), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))]),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: widget.badgeColors.$1, borderRadius: BorderRadius.circular(6)),
                child: Text(widget.cls.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.badgeColors.$2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${classSections.length} section${classSections.length != 1 ? 's' : ''} · $confirmedCT/${classSections.length} CT confirmed · $classSubjects subject${classSubjects != 1 ? 's' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ),
              Icon(_open ? Icons.expand_more : Icons.chevron_right, size: 18, color: const Color(0xFF9CA3AF)),
            ]),
          ),
        ),
        if (_open)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: classSections.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: Text('No sections configured for ${widget.cls.name}. Add sections in Core Setup.', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: classSections.map((sec) {
                      final sectionSpecific = widget.subjectRows.where((r) => r.sectionId == sec.id).toList();
                      final classLevelRows = widget.subjectRows.where((r) => r.sectionId == null).toList();
                      final seenSubjects = sectionSpecific.map((r) => r.subjectId).toSet();
                      final merged = [...sectionSpecific, ...classLevelRows.where((r) => !seenSubjects.contains(r.subjectId))];
                      final ct = widget.ctAssignments.where((c) => c.sectionId == sec.id).firstOrNull;
                      return StaffSectionCard(
                        key: ValueKey(sec.id),
                        section: sec,
                        teachers: widget.teachers,
                        subjectRows: merged,
                        ctAssignment: ct,
                        ctAssignments: widget.ctAssignments,
                        onCTConfirmLock: widget.onCTConfirmLock,
                        onCTEditRequest: widget.onCTEditRequest,
                        onSubjectSave: widget.onSubjectSave,
                        savingSubjKeys: widget.savingSubjKeys,
                        savingCT: widget.savingCTSects.contains(sec.id),
                        isOpen: _openSectionId == sec.id,
                        onToggle: () => setState(() => _openSectionId = _openSectionId == sec.id ? null : sec.id),
                      );
                    }).toList(),
                  ),
          ),
      ]),
    );
  }
}
