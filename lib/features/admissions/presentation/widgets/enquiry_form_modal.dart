import 'package:flutter/material.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import '../../../administration/domain/entities/admin_setup_entity.dart';
import '../providers/admissions_local_data.dart';

const Color kAdmIndigo = Color(0xFF4F46E5);

String _addDays(String today, int days) {
  final d = DateTime.tryParse(today) ?? DateTime.now();
  return d.add(Duration(days: days)).toIso8601String().substring(0, 10);
}

bool _isValidName(String v) => RegExp(r"^[A-Za-z\s\-']+$").hasMatch(v);
bool _isValidPhone(String v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v);

/// New / Edit Enquiry — converted from `AdmissionsCommandCenter.tsx`'s
/// "ADMISSION FORM MODAL". Quick Add (5 fields) for brand-new inquiries,
/// or a Full 3-step wizard (Parent/Guardian → Child Details → Preferences)
/// for edits or when the user switches to "📋 Full". Includes the web's
/// duplicate-phone detection + merge-into-existing flow on Quick Add.
class EnquiryFormModal extends StatefulWidget {
  final InquiryEntity? editing;
  final List<SchoolClassEntity> classes;
  final List<AdminSetupEntity> sources;
  final List<AdminSetupEntity> references;
  final List<InquiryEntity> allInquiries;
  final String today;
  final VoidCallback onClose;
  final void Function(InquiryEntity saved, {required bool isNew}) onSaved;
  final ValueChanged<InquiryEntity> onOpenExisting;

  const EnquiryFormModal({
    super.key,
    required this.editing,
    required this.classes,
    required this.sources,
    required this.references,
    required this.allInquiries,
    required this.today,
    required this.onClose,
    required this.onSaved,
    required this.onOpenExisting,
  });

  @override
  State<EnquiryFormModal> createState() => _EnquiryFormModalState();
}

class _EnquiryFormModalState extends State<EnquiryFormModal> {
  bool get _editing => widget.editing != null;
  bool _quickAddMode = true;
  int _section = 0;
  bool _saving = false;
  bool _dupMerging = false;
  InquiryEntity? _dupRecord;
  final Map<String, String> _errors = {};

  late final _fullName = TextEditingController(text: widget.editing?.fullName ?? '');
  late final _phone = TextEditingController(text: widget.editing?.phone ?? '');
  late final _email = TextEditingController(text: widget.editing?.email ?? '');
  late final _homeArea = TextEditingController();
  late final _childName = TextEditingController();
  late final _previousSchool = TextEditingController();
  late final _specificRequirements = TextEditingController();
  late final _description = TextEditingController(text: widget.editing?.description ?? '');
  late final _note = TextEditingController(text: widget.editing?.note ?? '');
  late final _assigned = TextEditingController(text: widget.editing?.assigned ?? '');

  String _relationship = '';
  String _gender = '';
  int? _schoolClass;
  int? _source;
  int? _reference;
  String _childDob = '';
  late String _queryDate;
  late String _nextFollowUpDate;
  late String _preferredVisitDate;
  String _preferredVisitTime = '';
  int _activeStatus = 1;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _schoolClass = e?.schoolClass;
    _source = e?.source;
    _reference = e?.reference;
    _queryDate = e?.queryDate ?? widget.today;
    _nextFollowUpDate = e?.nextFollowUpDate ?? widget.today;
    _preferredVisitDate = _addDays(widget.today, 1);
    _activeStatus = e?.activeStatus == 2 ? 2 : 1;
    if (_editing) _quickAddMode = false;
  }

  @override
  void dispose() {
    for (final c in [_fullName, _phone, _email, _homeArea, _childName, _previousSchool, _specificRequirements, _description, _note, _assigned]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _combinedDescription {
    final ext = <String>[
      if (_childName.text.isNotEmpty) 'Child: ${_childName.text}',
      if (_childDob.isNotEmpty) 'DOB: $_childDob',
      if (_gender.isNotEmpty) 'Gender: $_gender',
      if (_previousSchool.text.isNotEmpty) 'Prev School: ${_previousSchool.text}',
      if (_specificRequirements.text.isNotEmpty) 'Requirements: ${_specificRequirements.text}',
      if (_relationship.isNotEmpty) 'Relationship: $_relationship',
      if (_homeArea.text.isNotEmpty) 'Area: ${_homeArea.text}',
      if (_preferredVisitDate.isNotEmpty) 'Visit Date: $_preferredVisitDate',
      if (_preferredVisitTime.isNotEmpty) 'Visit Time: $_preferredVisitTime',
    ];
    return [_description.text.trim(), ext.join(' | ')].where((s) => s.isNotEmpty).join('\n');
  }

  Map<String, String> _validateFull() {
    final errs = <String, String>{};
    if (_fullName.text.trim().isEmpty) {
      errs['full_name'] = 'Name is required.';
    } else if (!_isValidName(_fullName.text)) {
      errs['full_name'] = 'Name can only contain letters.';
    }
    if (_phone.text.trim().isEmpty) {
      errs['phone'] = 'Phone is required.';
    } else if (!_isValidPhone(_phone.text)) {
      errs['phone'] = 'Enter a valid 10-digit Indian mobile number.';
    }
    if (_assigned.text.trim().isEmpty) errs['assigned'] = 'Assigned To is required.';
    if (_source == null) errs['source'] = 'Source is required.';
    if (_reference == null) errs['reference'] = 'Reference is required.';
    if (_queryDate.isEmpty) errs['query_date'] = 'Query date is required.';
    if (_nextFollowUpDate.isEmpty) errs['next_follow_up_date'] = 'Next follow-up date is required.';
    return errs;
  }

  Future<void> _submitFull() async {
    final errs = _validateFull();
    if (errs.isNotEmpty) {
      setState(() => _errors.addAll(errs));
      return;
    }
    setState(() => _saving = true);
    try {
      if (_editing) {
        final updated = await AdmissionsLocalData.updateInquiry(widget.editing!.id, (c) => c.copyWith(
              fullName: _fullName.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
              description: _combinedDescription,
              queryDate: _queryDate,
              nextFollowUpDate: _nextFollowUpDate,
              assigned: _assigned.text.trim(),
              reference: _reference,
              source: _source,
              schoolClass: _schoolClass,
              activeStatus: _activeStatus,
              note: _note.text.trim(),
            ));
        widget.onSaved(updated, isNew: false);
      } else {
        final created = await AdmissionsLocalData.createInquiry(InquiryEntity(
          id: 0,
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          description: _combinedDescription,
          queryDate: _queryDate,
          nextFollowUpDate: _nextFollowUpDate,
          assigned: _assigned.text.trim(),
          reference: _reference,
          source: _source,
          schoolClass: _schoolClass,
          noOfChild: 1,
          activeStatus: _activeStatus,
          note: _note.text.trim(),
        ));
        widget.onSaved(created, isNew: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitQuickAdd() async {
    final errs = <String, String>{};
    if (_fullName.text.trim().isEmpty) {
      errs['full_name'] = 'Name is required.';
    } else if (!_isValidName(_fullName.text)) {
      errs['full_name'] = 'Name can only contain letters.';
    }
    if (_phone.text.trim().isEmpty) {
      errs['phone'] = 'Phone is required.';
    } else if (!_isValidPhone(_phone.text)) {
      errs['phone'] = 'Enter a valid 10-digit Indian mobile number.';
    }
    if (_nextFollowUpDate.isEmpty) errs['next_follow_up_date'] = 'Next follow-up date is required.';
    if (errs.isNotEmpty) {
      setState(() => _errors.addAll(errs));
      return;
    }

    final dupPhone = _phone.text.trim();
    final matches = widget.allInquiries.where((i) => i.phone == dupPhone).toList();
    final duplicate = matches.isEmpty ? null : matches.first;
    String siblingNote = '';
    if (duplicate != null) {
      final newClass = _schoolClass;
      final existingClass = duplicate.schoolClass;
      final sameClass = newClass != null && existingClass != null && newClass == existingClass;
      if (sameClass || newClass == null) {
        final existingClassName = widget.classes.where((c) => c.id == existingClass).map((c) => c.name).firstOrNull ?? '';
        setState(() {
          _dupRecord = duplicate;
          _errors['phone'] = 'Already in system: ${duplicate.fullName}${existingClassName.isNotEmpty ? ' · Grade $existingClassName' : ''} · ${kDetailStageLabelForModal[duplicate.status] ?? duplicate.status}';
        });
        return;
      }
      setState(() {
        _dupRecord = null;
        _errors.clear();
      });
      final siblingClassName = widget.classes.where((c) => c.id == existingClass).map((c) => c.name).firstOrNull ?? '${existingClass ?? ''}';
      siblingNote = 'Sibling already in enquiry (${duplicate.fullName}, Grade $siblingClassName)';
    }

    final assignedFinal = _assigned.text.trim().isEmpty ? 'Unassigned' : _assigned.text.trim();
    final sourceFinal = _source ?? (widget.sources.isNotEmpty ? widget.sources.first.id : null);
    final referenceFinal = _reference ?? (widget.references.isNotEmpty ? widget.references.first.id : null);
    final noteFinal = siblingNote.isNotEmpty ? (_note.text.trim().isNotEmpty ? '${_note.text.trim()} | $siblingNote' : siblingNote) : _note.text.trim();

    setState(() => _saving = true);
    try {
      final created = await AdmissionsLocalData.createInquiry(InquiryEntity(
        id: 0,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        description: _description.text.trim(),
        queryDate: _queryDate,
        nextFollowUpDate: _nextFollowUpDate,
        assigned: assignedFinal,
        reference: referenceFinal,
        source: sourceFinal,
        schoolClass: _schoolClass,
        noOfChild: 1,
        activeStatus: 1,
        note: noteFinal,
      ));
      widget.onSaved(created, isNew: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _mergeIntoExisting() async {
    final dup = _dupRecord;
    if (dup == null) return;
    setState(() => _dupMerging = true);
    try {
      final updated = await AdmissionsLocalData.updateInquiry(dup.id, (c) => c.copyWith(
            email: _email.text.trim().isNotEmpty ? _email.text.trim() : c.email,
            note: _note.text.trim().isNotEmpty ? (c.note.isNotEmpty ? '${c.note}\n[Merged] ${_note.text.trim()}' : _note.text.trim()) : c.note,
            nextFollowUpDate: _nextFollowUpDate,
            assigned: _assigned.text.trim().isNotEmpty ? _assigned.text.trim() : c.assigned,
          ));
      widget.onOpenExisting(updated);
    } finally {
      if (mounted) setState(() => _dupMerging = false);
    }
  }

  void _goNext() {
    if (_section == 0) {
      final errs = <String, String>{};
      if (_fullName.text.trim().isEmpty) errs['full_name'] = 'Required';
      if (_phone.text.trim().isEmpty || !_isValidPhone(_phone.text)) errs['phone'] = 'Invalid phone';
      if (errs.isNotEmpty) {
        setState(() => _errors.addAll(errs));
        return;
      }
      setState(() => _errors.clear());
    }
    setState(() => _section++);
  }

  @override
  Widget build(BuildContext context) {
    final showFull = !_quickAddMode || _editing;
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x80000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                if (showFull) _stepper(),
                Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: showFull ? _fullFormSection() : _quickAddForm())),
                _footer(showFull),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: kAdmIndigo,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_editing ? 'Edit Enquiry' : 'New Enquiry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                if (!_editing) const Text('Quick Add captures in 10 seconds · Full form adds more detail', style: TextStyle(fontSize: 10.5, color: Color(0xCCFFFFFF))),
              ],
            ),
          ),
          if (!_editing)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                _toggleBtn('⚡ Quick', _quickAddMode, () => setState(() => _quickAddMode = true)),
                _toggleBtn('📋 Full', !_quickAddMode, () => setState(() {
                      _quickAddMode = false;
                      _section = 0;
                    })),
              ]),
            ),
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? kAdmIndigo : const Color(0xD9FFFFFF))),
      ),
    );
  }

  Widget _stepper() {
    const labels = ['Parent/Guardian', 'Child Details', 'Preferences'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFFF8FAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i <= _section;
          return Row(children: [
            Column(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, color: active ? kAdmIndigo : Colors.white, border: Border.all(color: active ? kAdmIndigo : const Color(0xFFD1D5DB), width: 2)),
                alignment: Alignment.center,
                child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF6B7280))),
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: TextStyle(fontSize: 10, fontWeight: i == _section ? FontWeight.w700 : FontWeight.w500, color: active ? kAdmIndigo : const Color(0xFF6B7280))),
            ]),
            if (i < 2) Container(width: 40, height: 2, margin: const EdgeInsets.only(left: 8, right: 8, bottom: 18), color: i < _section ? kAdmIndigo : const Color(0xFFD1D5DB)),
          ]);
        }),
      ),
    );
  }

  Widget _quickAddForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), border: Border.all(color: const Color(0xFFBFDBFE)), borderRadius: BorderRadius.circular(10)),
          child: const Text.rich(TextSpan(children: [
            TextSpan(text: 'Quick Add', style: TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: ' — capture a lead in seconds. Add more details later from the inquiry page.'),
          ]), style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8))),
        ),
        const SizedBox(height: 14),
        _field('Parent / Guardian Name *', error: _errors['full_name'], child: TextField(controller: _fullName, autofocus: true, decoration: _dec())),
        const SizedBox(height: 14),
        _field('Mobile Number *', error: _errors['phone'], child: _phoneField()),
        if (_dupRecord != null) _dupActions(),
        const SizedBox(height: 14),
        _field('Grade Applying For', child: _classDropdown()),
        const SizedBox(height: 14),
        _field('How did they hear about us?', child: _sourceDropdown()),
        const SizedBox(height: 14),
        _field('Next Follow-up *', error: _errors['next_follow_up_date'], child: _followUpQuickField()),
      ],
    );
  }

  Widget _fullFormSection() {
    switch (_section) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('Parent / Guardian Full Name *', error: _errors['full_name'], child: TextField(controller: _fullName, decoration: _dec())),
          const SizedBox(height: 12),
          _field('Relationship', child: _dropdown(_relationship, const ['Father', 'Mother', 'Guardian', 'Other'], (v) => setState(() => _relationship = v ?? ''))),
          const SizedBox(height: 12),
          _field('Mobile Number *', error: _errors['phone'], child: _phoneField()),
          const SizedBox(height: 12),
          _field('Email', child: TextField(controller: _email, decoration: _dec(hint: 'parent@example.com'))),
          const SizedBox(height: 12),
          _field('Home Area / Locality', child: TextField(controller: _homeArea, decoration: _dec(hint: 'e.g. Koramangala'))),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field("Child's Full Name", child: TextField(controller: _childName, decoration: _dec(hint: "Child's full name"))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Date of Birth', child: _dateField(_childDob, (v) => setState(() => _childDob = v)))),
            const SizedBox(width: 10),
            Expanded(child: _field('Gender', child: _dropdown(_gender, const ['Boy', 'Girl', 'Prefer not to say'], (v) => setState(() => _gender = v ?? '')))),
          ]),
          const SizedBox(height: 12),
          _field('Grade Applying For', child: _classDropdown()),
          const SizedBox(height: 12),
          _field('Previous School', child: TextField(controller: _previousSchool, decoration: _dec(hint: 'Previous school name'))),
          const SizedBox(height: 12),
          _field('Special Needs / Support', child: TextField(controller: _specificRequirements, maxLines: 3, decoration: _dec(hint: 'Any special needs...'))),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('How did you hear about us?', error: _errors['source'], child: _sourceDropdown()),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Preferred Visit Date', child: _dateField(_preferredVisitDate, (v) => setState(() => _preferredVisitDate = v)))),
            const SizedBox(width: 10),
            Expanded(child: _field('Preferred Visit Time', child: _dropdown(_preferredVisitTime, const ['Morning 9-11 AM', 'Afternoon 1-3 PM', 'Evening 4-6 PM', 'Flexible'], (v) => setState(() => _preferredVisitTime = v ?? '')))),
          ]),
          const SizedBox(height: 12),
          _field("Parent's Message / Notes", child: TextField(controller: _description, maxLines: 3, decoration: _dec(hint: 'Any message from the parent...'))),
          const SizedBox(height: 12),
          _field('Internal Note', child: TextField(controller: _note, maxLines: 2, decoration: _dec(hint: 'Internal notes...'))),
          const SizedBox(height: 12),
          _field('Assigned Counsellor *', error: _errors['assigned'], child: TextField(controller: _assigned, decoration: _dec(hint: 'e.g. Mr. Sharma'))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Query Date *', error: _errors['query_date'], child: _dateField(_queryDate, _editing ? (v) => setState(() => _queryDate = v) : null))),
            const SizedBox(width: 10),
            Expanded(child: _field('Next Follow-up *', error: _errors['next_follow_up_date'], child: _dateField(_nextFollowUpDate, (v) => setState(() => _nextFollowUpDate = v)))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Reference *', error: _errors['reference'], child: _referenceDropdown())),
            const SizedBox(width: 10),
            Expanded(child: _field('Status', child: _dropdown(_activeStatus == 1 ? 'Active' : 'Inactive', const ['Active', 'Inactive'], (v) => setState(() => _activeStatus = v == 'Active' ? 1 : 2)))),
          ]),
        ]);
    }
  }

  Widget _footer(bool showFull) {
    if (!showFull) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _saving ? null : _submitQuickAdd,
              style: ElevatedButton.styleFrom(backgroundColor: kAdmIndigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
              child: Text(_saving ? 'Saving...' : '⚡ Add Inquiry'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(onPressed: widget.onClose, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('Cancel')),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        mainAxisAlignment: _section == 0 ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
        children: [
          if (_section > 0) OutlinedButton(onPressed: () => setState(() => _section--), child: const Text('Back')),
          if (_section < 2)
            ElevatedButton(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(backgroundColor: kAdmIndigo, foregroundColor: Colors.white),
              child: const Text('Next'),
            ),
          if (_section == 2)
            ElevatedButton(
              onPressed: _saving ? null : _submitFull,
              style: ElevatedButton.styleFrom(backgroundColor: kAdmIndigo, foregroundColor: Colors.white),
              child: Text(_saving ? 'Saving...' : (_editing ? 'Update' : 'Save')),
            ),
        ],
      ),
    );
  }

  Widget _dupActions() {
    final dup = _dupRecord!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        OutlinedButton(
          onPressed: () {
            widget.onClose();
            widget.onOpenExisting(dup);
          },
          style: OutlinedButton.styleFrom(foregroundColor: kAdmIndigo, backgroundColor: const Color(0xFFEFF6FF), side: const BorderSide(color: Color(0xFFC7D2FE)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          child: const Text('👤 Open existing record →'),
        ),
        ElevatedButton(
          onPressed: _dupMerging ? null : _mergeIntoExisting,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          child: Text(_dupMerging ? 'Merging…' : '🔀 Merge into existing'),
        ),
      ]),
    );
  }

  Widget _field(String label, {Widget? child, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
        const SizedBox(height: 4),
        ?child,
        if (error != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(error, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
      ],
    );
  }

  InputDecoration _dec({String? hint, bool err = false}) {
    final borderColor = err ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kAdmIndigo, width: 2)),
    );
  }

  Widget _phoneField() {
    return Row(children: [
      Container(
        width: 48,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8), color: const Color(0xFFF8FAFC)),
        child: const Text('+91', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: TextField(
          controller: _phone,
          keyboardType: TextInputType.number,
          maxLength: 10,
          decoration: _dec(hint: '9876543210', err: _errors.containsKey('phone')).copyWith(counterText: ''),
          onChanged: (_) => setState(() {
            _dupRecord = null;
            _errors.remove('phone');
          }),
        ),
      ),
    ]);
  }

  Widget _followUpQuickField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dateField(_nextFollowUpDate, (v) => setState(() => _nextFollowUpDate = v)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, children: [
        _quickDateChip('+1 day', 1),
        _quickDateChip('+2 days', 2),
        _quickDateChip('+1 week', 7),
      ]),
    ]);
  }

  Widget _quickDateChip(String label, int days) {
    return OutlinedButton(
      onPressed: () => setState(() => _nextFollowUpDate = _addDays(widget.today, days)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), minimumSize: Size.zero, textStyle: const TextStyle(fontSize: 11)),
      child: Text(label),
    );
  }

  Widget _dateField(String value, ValueChanged<String>? onChanged) {
    return TextField(
      controller: TextEditingController(text: value),
      readOnly: true,
      enabled: onChanged != null,
      decoration: _dec().copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 14)),
      onTap: onChanged == null
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(value) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) onChanged(picked.toIso8601String().substring(0, 10));
            },
    );
  }

  Widget _dropdown(String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: _dec(),
      hint: const Text('Select', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12.5)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _classDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _schoolClass,
      isExpanded: true,
      decoration: _dec(),
      hint: const Text('Select Grade', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
      items: widget.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 12.5)))).toList(),
      onChanged: (v) => setState(() => _schoolClass = v),
    );
  }

  Widget _sourceDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _source,
      isExpanded: true,
      decoration: _dec(err: _errors.containsKey('source')),
      hint: const Text('Select Source', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
      items: widget.sources.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 12.5)))).toList(),
      onChanged: (v) => setState(() {
        _source = v;
        _errors.remove('source');
      }),
    );
  }

  Widget _referenceDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _reference,
      isExpanded: true,
      decoration: _dec(err: _errors.containsKey('reference')),
      hint: const Text('Select', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
      items: widget.references.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name, style: const TextStyle(fontSize: 12.5)))).toList(),
      onChanged: (v) => setState(() {
        _reference = v;
        _errors.remove('reference');
      }),
    );
  }
}

const Map<String, String> kDetailStageLabelForModal = {
  'new': 'New',
  'contacted': 'In Conversation',
  'visited': 'Decision Pending',
  'enrolled': 'Enrolled',
  'waitlisted': 'Waitlist',
  'declined': 'Cold / Dropped',
};
