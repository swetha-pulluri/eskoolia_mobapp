import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/due_interaction.dart';
import '../../domain/models/due_student.dart';
import '../providers/fees_dues_providers.dart';
import '../utils/fee_assignment_format.dart' show fmtRs;
import '../utils/fees_dues_format.dart';
import 'fees_dues_styles.dart';

/// Right-side slide-in "Follow-up" drawer — mirrors
/// FeesDuesRemindersPanel.tsx's `followUp` panel exactly: student summary
/// card, interaction timeline, add-note textarea, agreed amount/date, and
/// a full-width Save Follow-up button. Backdrop click always closes (no
/// saving-guard), matching the source.
class FdFollowUpPanel extends ConsumerStatefulWidget {
  final DueStudent student;
  final void Function(String message) onToast;

  const FdFollowUpPanel({super.key, required this.student, required this.onToast});

  static Future<void> show(BuildContext context, {required DueStudent student, required void Function(String) onToast}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Follow-up',
      barrierColor: const Color(0x2E000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) => FdFollowUpPanel(student: student, onToast: onToast),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<FdFollowUpPanel> createState() => _FdFollowUpPanelState();
}

class _FdFollowUpPanelState extends ConsumerState<FdFollowUpPanel> {
  final _noteCtrl = TextEditingController();
  final _agreedAmtCtrl = TextEditingController();
  final _agreedDateCtrl = TextEditingController();
  List<DueInteraction> _interactions = const [];
  bool _interLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _agreedAmtCtrl.dispose();
    _agreedDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInteractions() async {
    setState(() => _interLoading = true);
    try {
      final data = await ref.read(feesDuesRepositoryProvider).fetchInteractions(widget.student.id);
      if (!mounted) return;
      setState(() => _interactions = data);
    } catch (_) {
      if (mounted) setState(() => _interactions = const []);
    } finally {
      if (mounted) setState(() => _interLoading = false);
    }
  }

  Future<void> _save() async {
    if (_noteCtrl.text.trim().isEmpty) {
      widget.onToast('Please enter a note.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(feesDuesRepositoryProvider).createInteraction(
            student: widget.student.id,
            note: _noteCtrl.text,
            agreedAmount: _agreedAmtCtrl.text.isEmpty ? null : _agreedAmtCtrl.text,
            agreedDate: _agreedDateCtrl.text.isEmpty ? null : _agreedDateCtrl.text,
          );
      widget.onToast('Follow-up saved for ${widget.student.name}.');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      widget.onToast('Failed to save follow-up.');
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAgreedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 2), lastDate: DateTime(now.year + 5));
    if (picked != null) {
      setState(() => _agreedDateCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.student;
    final tier = duesTierStatus(st.daysOverdue);
    final tierStyle = duesStatusStyle[tier]!;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          color: Colors.white,
          child: SizedBox(
            height: double.infinity,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: fdBorder)),
                boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 32, offset: Offset(-8, 0))],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${st.name} Follow-up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fdInk1)),
                                const SizedBox(height: 3),
                                Text('${st.admNo} · Class ${st.cls} · Due ${fmtRs(double.tryParse(st.amountDue) ?? 0)}', style: const TextStyle(fontSize: 12, color: fdInk3)),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: fdBorder)),
                              child: const Text('×', style: TextStyle(fontSize: 16, color: fdInk3, height: 1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: fdBorder),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(color: fdPurpleTint, border: Border.all(color: fdPurpleBorder), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  FdAvatar(background: duesAvatarBg(st.name), initials: _initials(st.name), size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(st.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fdInk1)),
                                        const SizedBox(height: 2),
                                        st.lastReminder != null
                                            ? const Text('Reminder sent', style: TextStyle(fontSize: 11.5, color: fdPurple, fontWeight: FontWeight.w500))
                                            : Text('${st.daysOverdue} days overdue', style: const TextStyle(fontSize: 11.5, color: fdInk3)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FdStatusPill(label: tier, bg: tierStyle.bg, color: tierStyle.color, small: true),
                                      const SizedBox(height: 5),
                                      const FdStatusPill(label: 'unpaid', bg: Color(0xFFFEE2E2), color: Color(0xFFDC2626), small: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (_interLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: Text('Loading history…', style: TextStyle(fontSize: 13, color: fdInk3))),
                              )
                            else if (_interactions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  children: [for (var i = 0; i < _interactions.length; i++) _timelineRow(_interactions[i], i < _interactions.length - 1)],
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: Text('No interaction log yet.', style: TextStyle(fontSize: 13, color: fdInk3))),
                              ),
                            const Text('ADD NOTE / LOG CALL', style: fdFieldLabelStyle),
                            const SizedBox(height: 7),
                            TextField(
                              controller: _noteCtrl,
                              minLines: 3,
                              maxLines: 3,
                              decoration: fdFieldDecoration(hintText: 'e.g. Spoke to parent. Expected payment by end of month.'),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('AGREED AMOUNT', style: fdFieldLabelStyle),
                                      const SizedBox(height: 7),
                                      TextField(controller: _agreedAmtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fdFieldDecoration(hintText: '0')),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('AGREED DATE', style: fdFieldLabelStyle),
                                      const SizedBox(height: 7),
                                      InkWell(
                                        onTap: _pickAgreedDate,
                                        child: InputDecorator(
                                          decoration: fdFieldDecoration(hintText: 'YYYY-MM-DD'),
                                          child: Text(_agreedDateCtrl.text, style: const TextStyle(fontSize: 13.5, color: fdInk1)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: fdBorder))),
                      child: SizedBox(
                        width: double.infinity,
                        child: FdPrimaryButton(label: _saving ? 'Saving…' : 'Save Follow-up', onPressed: _saving ? null : _save),
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

  Widget _timelineRow(DueInteraction e, bool hasNext) {
    return Padding(
      padding: EdgeInsets.only(bottom: hasNext ? 14 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 10,
              child: Column(
                children: [
                  Container(margin: const EdgeInsets.only(top: 3), width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: fdPurple)),
                  if (hasNext) Expanded(child: Container(margin: const EdgeInsets.only(top: 4), width: 2, color: fdBorder)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.note, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fdInk1)),
                  const SizedBox(height: 2),
                  Text('${fmtDuesDate(e.createdAt)} · ${e.createdByName.isNotEmpty ? e.createdByName : "System"}', style: const TextStyle(fontSize: 11.5, color: fdInk3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts[0][0];
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}
