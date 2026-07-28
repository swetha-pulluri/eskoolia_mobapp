import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/due_student.dart';
import '../providers/fees_dues_providers.dart';
import '../utils/fee_assignment_format.dart' show fmtRs;
import 'fees_dues_styles.dart';

const _resolveActions = [
  (key: 'collect_now', emoji: '💳', label: 'Collect Now', sub: 'Switch to collection desk for this student'),
  (key: 'send_reminder', emoji: '🔔', label: 'Send Final Reminder', sub: 'Log reminder and mark Final Reminder Sent'),
  (key: 'payment_plan', emoji: '📋', label: 'Create Payment Plan', sub: 'Set up instalments with agreed dates'),
  (key: 'write_off', emoji: '✏️', label: 'Write Off', sub: 'Write off balance with reason and approval'),
  (key: 'escalate', emoji: 'ℹ️', label: 'Escalate', sub: 'Flag for principal or legal follow-up'),
  (key: 'start_offboarding', emoji: '🟠', label: 'Start Offboarding', sub: 'Student leaving — begin clearance process'),
];
const _obChecklist = [
  'Collect outstanding fee balance',
  'Library clearance confirmed',
  'Transport clearance confirmed',
  'Hostel / Lunch clearance confirmed',
  'Transfer Certificate issued',
  'Caution deposit refund processed (if applicable)',
  'Parent portal access closed',
  'Student record archived',
];
const _woReasons = ['Financial hardship', 'Scholarship grant', 'Management decision', 'Duplicate charge', 'Other'];
const _escTo = ['Principal', 'Vice Principal', 'Accountant', 'Management', 'Legal'];
const _escPriorities = ['High', 'Medium', 'Low'];

/// "Resolve Outstanding Dues" modal — mirrors FeesDuesRemindersPanel.tsx's
/// `resolveTarget` modal exactly: 6 toggleable action cards, 4 mutually
/// exclusive conditional sub-forms, and a footer whose Confirm button is
/// gated exactly like the source (disabled until an action is picked, and
/// for Start Offboarding until all 8 checklist items are checked).
///
/// Returns (via [show]) `true` if the confirmed action was write-off or
/// start-offboarding (student should be hidden from all lists), `false` if
/// some other action succeeded, or `null` if the dialog was dismissed
/// without confirming.
class FdResolveDialog extends ConsumerStatefulWidget {
  final DueStudent student;
  final void Function(String message) onToast;

  const FdResolveDialog({super.key, required this.student, required this.onToast});

  static Future<bool?> show(BuildContext context, {required DueStudent student, required void Function(String) onToast}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: 'Resolve Outstanding Dues',
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim1, anim2) => FdResolveDialog(student: student, onToast: onToast),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(opacity: curved, child: ScaleTransition(scale: Tween<double>(begin: 0.97, end: 1).animate(curved), child: child));
      },
    );
  }

  @override
  ConsumerState<FdResolveDialog> createState() => _FdResolveDialogState();
}

class _FdResolveDialogState extends ConsumerState<FdResolveDialog> {
  String _action = '';
  bool _saving = false;

  // Payment plan
  final _ppInst1 = TextEditingController();
  final _ppDue1 = TextEditingController();
  final _ppInst2 = TextEditingController();
  final _ppDue2 = TextEditingController();
  final _ppNote = TextEditingController();
  // Write off
  String _woReason = _woReasons.first;
  final _woApproved = TextEditingController(text: 'Principal');
  final _woNote = TextEditingController();
  // Escalate
  String _escToVal = _escTo.first;
  String _escPriority = 'High';
  final _escNotes = TextEditingController();
  // Offboarding
  final Set<String> _obChecked = {};

  @override
  void dispose() {
    _ppInst1.dispose();
    _ppDue1.dispose();
    _ppInst2.dispose();
    _ppDue2.dispose();
    _ppNote.dispose();
    _woApproved.dispose();
    _woNote.dispose();
    _escNotes.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final student = widget.student;
    setState(() => _saving = true);
    try {
      switch (_action) {
        case 'collect_now':
          widget.onToast('Redirecting to collection desk for ${student.name}.');
          if (mounted) Navigator.of(context).pop(false);
          return;
        case 'send_reminder':
          await ref.read(feesDuesRepositoryProvider).sendReminders([student.id], 'Final reminder — please clear outstanding fee immediately.');
          widget.onToast('Final reminder sent to ${student.name}.');
          if (mounted) Navigator.of(context).pop(false);
          return;
        case 'payment_plan':
          final planNote = 'Payment plan: Instalment 1 ₹${_ppInst1.text} by ${_ppDue1.text}, Instalment 2 ₹${_ppInst2.text} by ${_ppDue2.text}.'
              '${_ppNote.text.isNotEmpty ? ' ${_ppNote.text}' : ''}';
          await ref.read(feesDuesRepositoryProvider).createInteraction(
                student: student.id,
                note: planNote,
                agreedAmount: _ppInst1.text.isEmpty ? null : _ppInst1.text,
                agreedDate: _ppDue1.text.isEmpty ? null : _ppDue1.text,
              );
          widget.onToast('Payment plan saved for ${student.name}.');
          if (mounted) Navigator.of(context).pop(false);
          return;
        case 'write_off':
          await ref.read(feesDuesRepositoryProvider).resolveDue(
                student.id,
                note: 'Write off — $_woReason. Approved by: ${_woApproved.text}.${_woNote.text.isNotEmpty ? ' ${_woNote.text}' : ''}',
              );
          widget.onToast('Balance written off for ${student.name}.');
          if (mounted) Navigator.of(context).pop(true);
          return;
        case 'escalate':
          await ref.read(feesDuesRepositoryProvider).createInteraction(
                student: student.id,
                note: 'Escalated to $_escToVal ($_escPriority priority).${_escNotes.text.isNotEmpty ? ' ${_escNotes.text}' : ''}',
              );
          widget.onToast("Escalated ${student.name}'s dues to $_escToVal.");
          if (mounted) Navigator.of(context).pop(false);
          return;
        case 'start_offboarding':
          await ref.read(feesDuesRepositoryProvider).resolveDue(student.id, note: 'Student offboarding initiated. All clearance items confirmed.');
          widget.onToast('Offboarding started for ${student.name}.');
          if (mounted) Navigator.of(context).pop(true);
          return;
      }
    } catch (_) {
      widget.onToast('Action failed. Please try again.');
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _confirmEnabled => _action.isNotEmpty && !_saving && !(_action == 'start_offboarding' && _obChecked.length < _obChecklist.length);

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _saving ? null : () => Navigator.of(context).pop(),
      child: Container(
        color: const Color(0x59000000),
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 64, offset: Offset(0, 24))],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Resolve Outstanding Dues', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fdInk1)),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${student.name} · ${student.admNo} · Due: ${fmtRs(double.tryParse(student.amountDue) ?? 0)} · ${student.daysOverdue} days overdue',
                                      style: const TextStyle(fontSize: 12.5, color: fdInk3),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: _saving ? null : () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: fdBorder)),
                                  child: Text('×', style: TextStyle(fontSize: 16, color: _saving ? fdInk3.withValues(alpha: 0.4) : fdInk3, height: 1)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text("Choose one action to resolve or progress this student's outstanding balance.", style: TextStyle(fontSize: 13, color: fdInk2)),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _actionGrid(),
                            if (_action == 'write_off') _writeOffForm(),
                            if (_action == 'escalate') _escalateForm(),
                            if (_action == 'payment_plan') _paymentPlanForm(),
                            if (_action == 'start_offboarding') _offboardingChecklist(),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: fdBorder))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FdOutlineButton(label: 'Cancel', onPressed: _saving ? null : () => Navigator.of(context).pop()),
                          const SizedBox(width: 10),
                          FdPrimaryButton(label: _saving ? 'Processing…' : 'Confirm Action', onPressed: _confirmEnabled ? _confirm : null),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: [
        for (final act in _resolveActions)
          InkWell(
            onTap: () => setState(() => _action = _action == act.key ? '' : act.key),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _action == act.key ? fdPurple : fdBorder, width: _action == act.key ? 2 : 1),
                borderRadius: BorderRadius.circular(10),
                color: _action == act.key ? fdPurpleTint : Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(act.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(act.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fdInk1))),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(act.sub, style: const TextStyle(fontSize: 12, color: fdInk3, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: fdFieldLabelStyle));

  Widget _writeOffForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('REASON FOR WRITE-OFF'),
          DropdownButtonFormField<String>(
            initialValue: _woReason,
            isExpanded: true,
            decoration: fdFieldDecoration(),
            items: [for (final r in _woReasons) DropdownMenuItem(value: r, child: Text(r))],
            onChanged: (v) => setState(() => _woReason = v ?? _woReasons.first),
          ),
          const SizedBox(height: 12),
          _label('APPROVED BY'),
          TextField(controller: _woApproved, decoration: fdFieldDecoration(hintText: 'Principal')),
          const SizedBox(height: 12),
          _label('NOTE'),
          TextField(controller: _woNote, minLines: 3, maxLines: 3, decoration: fdFieldDecoration(hintText: 'Additional context for audit trail...')),
        ],
      ),
    );
  }

  Widget _escalateForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _label('ESCALATE TO'),
                    DropdownButtonFormField<String>(
                      initialValue: _escToVal,
                      isExpanded: true,
                      decoration: fdFieldDecoration(),
                      items: [for (final r in _escTo) DropdownMenuItem(value: r, child: Text(r))],
                      onChanged: (v) => setState(() => _escToVal = v ?? _escTo.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _label('PRIORITY'),
                    DropdownButtonFormField<String>(
                      initialValue: _escPriority,
                      isExpanded: true,
                      decoration: fdFieldDecoration(),
                      items: [for (final r in _escPriorities) DropdownMenuItem(value: r, child: Text(r))],
                      onChanged: (v) => setState(() => _escPriority = v ?? 'High'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('NOTES'),
          TextField(controller: _escNotes, minLines: 3, maxLines: 3, decoration: fdFieldDecoration(hintText: 'Summary for escalation report...')),
        ],
      ),
    );
  }

  Widget _paymentPlanForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _label('INSTALMENT 1'),
                    TextField(controller: _ppInst1, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fdFieldDecoration(hintText: 'Amount')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [_label('DUE DATE'), _dateField(_ppDue1)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _label('INSTALMENT 2'),
                    TextField(controller: _ppInst2, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fdFieldDecoration(hintText: 'Amount')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [_label('DUE DATE'), _dateField(_ppDue2)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('AGREEMENT NOTE'),
          TextField(controller: _ppNote, minLines: 3, maxLines: 3, decoration: fdFieldDecoration(hintText: 'e.g. Parent confirmed via phone on 27 May 2026')),
        ],
      ),
    );
  }

  Widget _dateField(TextEditingController ctrl) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 2), lastDate: DateTime(now.year + 5));
        if (picked != null) {
          setState(() => ctrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: fdFieldDecoration(hintText: 'YYYY-MM-DD'),
        child: Text(ctrl.text, style: const TextStyle(fontSize: 13.5, color: fdInk1)),
      ),
    );
  }

  Widget _offboardingChecklist() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STUDENT OFFBOARDING CHECKLIST', style: fdFieldLabelStyle),
          const SizedBox(height: 10),
          Column(
            children: [
              for (final item in _obChecklist) ...[
                InkWell(
                  onTap: () => setState(() => _obChecked.contains(item) ? _obChecked.remove(item) : _obChecked.add(item)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: fdBorder),
                      borderRadius: BorderRadius.circular(8),
                      color: _obChecked.contains(item) ? const Color(0xFFFAFAFF) : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Checkbox(value: _obChecked.contains(item), onChanged: (_) => setState(() => _obChecked.contains(item) ? _obChecked.remove(item) : _obChecked.add(item)), activeColor: fdPurple),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 13.5, color: fdInk1))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
          const SizedBox(height: 6),
          const Text('All items must be checked before the record can be archived.', style: TextStyle(fontSize: 12, color: fdInk3, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
