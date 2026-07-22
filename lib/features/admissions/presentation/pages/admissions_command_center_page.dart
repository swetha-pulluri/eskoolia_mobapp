import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import '../providers/admissions_provider.dart';
import '../providers/admissions_local_data.dart';
import '../widgets/admissions_layout.dart';
import '../widgets/morning_brief.dart';
import '../widgets/class_portfolio_grid.dart';
import '../widgets/class_workspace.dart';
import '../widgets/enquiry_form_modal.dart';
import '../widgets/log_contact_modal.dart';
import '../widgets/call_flow_modal.dart';
import '../widgets/whatsapp_composer_modal.dart';
import '../widgets/ai_tip_popup.dart';

String _healthStatus(int enrolled, int capacity, int overdueCount) {
  if (capacity > 0 && enrolled / capacity > 0.9) return 'urgent';
  if (overdueCount > 10) return 'urgent';
  if (enrolled == 0) return 'quiet';
  if (overdueCount > 3) return 'active';
  return 'healthy';
}

/// Admissions Command Center — converted from `AdmissionsCommandCenter.tsx`.
/// Orchestrates Morning Brief → Class Portfolio → Class Workspace, plus the
/// New/Edit Enquiry, Log Contact, Call Flow, WhatsApp Composer modals and
/// the post-create AI Tip popup.
///
/// Not reproduced: the Broadcast modal and Document Checklist modal, and
/// the WhatsApp Composer's "AI Compose" button. All three are unreachable
/// dead code in the real web app too — their only trigger buttons are
/// commented out there (`{/* <button onClick={...Broadcast...} /> */}`)
/// or (AI Compose) require a live AI backend this offline module doesn't
/// have. Building unreachable UI would add surface area with zero
/// corresponding web behavior to match.
class AdmissionsCommandCenterPage extends ConsumerStatefulWidget {
  const AdmissionsCommandCenterPage({super.key});

  @override
  ConsumerState<AdmissionsCommandCenterPage> createState() => _AdmissionsCommandCenterPageState();
}

class _AdmissionsCommandCenterPageState extends ConsumerState<AdmissionsCommandCenterPage> {
  late final String _today = DateTime.now().toIso8601String().substring(0, 10);
  final _searchController = TextEditingController();
  String _globalSearch = '';
  String? _forcedStage;
  AiTip? _aiTip;
  String? _aiTipPhone;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => ref.read(admissionsReloadProvider.notifier).state++;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _selectClass(int? id) {
    ref.read(selectedClassIdProvider.notifier).state = id;
    ref.read(classWorkspaceVisibleProvider.notifier).state = true;
  }

  void _onMorningBriefCardClick(String stage) {
    _selectClass(null);
    setState(() => _forcedStage = stage);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _forcedStage = null);
    });
  }

  void _openEnquiryModal({InquiryEntity? editing, required List<SchoolClassEntity> classes, required dynamic sources, required dynamic references, required List<InquiryEntity> allInquiries}) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      pageBuilder: (dialogContext, a1, a2) => EnquiryFormModal(
        editing: editing,
        classes: classes,
        sources: sources,
        references: references,
        allInquiries: allInquiries,
        today: _today,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onSaved: (saved, {required isNew}) {
          Navigator.of(dialogContext).maybePop();
          _reload();
          if (isNew) {
            _toast('New inquiry added.');
            setState(() {
              _aiTip = generateAiTip(saved, sources, classes);
              _aiTipPhone = saved.phone;
            });
          } else {
            _toast('Inquiry updated.');
          }
        },
        onOpenExisting: (existing) {
          Navigator.of(dialogContext).maybePop();
          _reload();
          _openEnquiryModal(editing: existing, classes: classes, sources: sources, references: references, allInquiries: allInquiries);
        },
      ),
    );
  }

  void _openLogModal(InquiryEntity inq, {String? prefilledOutcome, String? prefilledNote}) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      pageBuilder: (dialogContext, a1, a2) => LogContactModal(
        inquiry: inq,
        today: _today,
        prefilledOutcome: prefilledOutcome,
        prefilledNote: prefilledNote,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onSaved: () {
          Navigator.of(dialogContext).maybePop();
          _reload();
          _toast('Contact logged!');
        },
      ),
    );
  }

  void _openCallModal(InquiryEntity inq) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      pageBuilder: (dialogContext, a1, a2) => CallFlowModal(
        inquiry: inq,
        today: _today,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onEnrolled: () {
          _reload();
          _toast('Enrolled!');
        },
        onLogUpdate: (i) => _openLogModal(i),
      ),
    );
  }

  void _openWAModal(InquiryEntity inq) {
    if (inq.phone.isEmpty) {
      _toast('No phone number available.');
      return;
    }
    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      pageBuilder: (dialogContext, a1, a2) => WhatsAppComposerModal(
        inquiry: inq,
        onClose: () => Navigator.of(dialogContext).maybePop(),
        onSent: () {
          Navigator.of(dialogContext).maybePop();
          // LogContactModal defaults next_follow_up_date to today+2 itself,
          // matching web's sendWADirect behavior.
          _openLogModal(inq, prefilledOutcome: 'whatsapp_sent', prefilledNote: 'WhatsApp sent via Command Center');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = ref.watch(inquiriesProvider).maybeWhen(data: (v) => v, orElse: () => const <InquiryEntity>[]);
    final classes = ref.watch(schoolClassesProvider).maybeWhen(data: (v) => v, orElse: () => const <SchoolClassEntity>[]);
    final sources = ref.watch(admissionSourcesProvider).maybeWhen(data: (v) => v, orElse: () => const []);
    final references = ref.watch(admissionReferencesProvider).maybeWhen(data: (v) => v, orElse: () => const []);
    final selectedClassId = ref.watch(selectedClassIdProvider);
    final showWorkspace = ref.watch(classWorkspaceVisibleProvider);

    final total = inquiries.length;
    final enrolled = inquiries.where((i) => i.status == 'enrolled').length;
    final weekAgo = DateTime.parse(_today).subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);
    final newThisWeek = inquiries.where((i) => i.queryDate != null && i.queryDate!.compareTo(weekAgo) >= 0).length;
    final overdue = inquiries.where((i) => i.activeStatus == 1 && i.nextFollowUpDate != null && i.nextFollowUpDate!.compareTo(_today) < 0).length;

    final briefData = MorningBriefData(
      newToday: inquiries.where((i) => i.queryDate == _today).length,
      overdueFollowUp: overdue,
      visitsToday: inquiries.where((i) => i.activeStatus == 1 && i.nextFollowUpDate == _today).length,
      decisionsPending: inquiries.where((i) => i.status == 'visited' && i.activeStatus == 1).length,
    );

    final classConfigs = classes.map((cls) {
      final ci = inquiries.where((i) => i.schoolClass == cls.id).toList();
      final enrolledCount = ci.where((i) => i.status == 'enrolled').length;
      final pipelineCount = ci.where((i) => i.activeStatus == 1).length;
      final overdueCount = ci.where((i) => i.activeStatus == 1 && i.nextFollowUpDate != null && i.nextFollowUpDate!.compareTo(_today) < 0).length;
      final capacity = cls.sections.isNotEmpty ? cls.sections.fold<int>(0, (s, sec) => s + sec.capacity) : 30;
      return ClassConfigEntity(
        id: cls.id,
        name: cls.name,
        capacity: capacity,
        sections: cls.sections,
        pipelineCount: pipelineCount,
        enrolledCount: enrolledCount,
        overdueCount: overdueCount,
        healthStatus: _healthStatus(enrolledCount, capacity, overdueCount),
      );
    }).toList();

    final priorityText = _computePriorityText(briefData);

    final filteredInquiries = _globalSearch.isEmpty
        ? inquiries
        : inquiries.where((i) => i.fullName.toLowerCase().contains(_globalSearch.toLowerCase()) || i.phone.contains(_globalSearch)).toList();

    final selectedClassConfig = selectedClassId != null ? classConfigs.where((c) => c.id == selectedClassId).firstOrNull : null;

    return AdmissionsLayout(
      currentPath: '/admissions/command-center',
      child: Stack(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pageHeader(total, overdue, newThisWeek, enrolled, classes, sources, references, inquiries),
                      MorningBrief(data: briefData, onCardClick: _onMorningBriefCardClick, priorityText: priorityText),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ClassPortfolioGrid(
                        classes: classConfigs,
                        selectedClassId: selectedClassId,
                        onSelectClass: _selectClass,
                        onClassesUpdated: _reload,
                      ),
                      if (showWorkspace) ...[
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        ClassWorkspace(
                          selectedClassId: selectedClassId,
                          classes: classes,
                          allInquiries: filteredInquiries,
                          today: _today,
                          onOpenLog: (i) => _openLogModal(i),
                          onOpenCall: _openCallModal,
                          onOpenWA: _openWAModal,
                          onEdit: (i) => _openEnquiryModal(editing: i, classes: classes, sources: sources, references: references, allInquiries: inquiries),
                          onReload: _reload,
                          forcedStage: _forcedStage,
                          classConfig: selectedClassConfig,
                          onInlineStageMove: (id, stage) => AdmissionsLocalData.updateInquiry(
                            id,
                            (c) => c.copyWith(status: stage, activeStatus: stage == 'enrolled' || stage == 'declined' ? 2 : 1),
                          ),
                          onBulkMoveStage: (ids, stage) async {
                            for (final id in ids) {
                              await AdmissionsLocalData.updateInquiry(
                                id,
                                (c) => c.copyWith(status: stage, activeStatus: stage == 'enrolled' || stage == 'declined' ? 2 : 1),
                              );
                            }
                          },
                          onBulkAssign: (ids, name) async {
                            for (final id in ids) {
                              await AdmissionsLocalData.updateInquiry(id, (c) => c.copyWith(assigned: name));
                            }
                          },
                          onBulkDelete: (ids) async {
                            for (final id in ids) {
                              await AdmissionsLocalData.deleteInquiry(id);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_aiTip != null)
            AiTipPopup(
              tip: _aiTip!,
              phone: _aiTipPhone,
              onClose: () => setState(() => _aiTip = null),
              onSend: () {
                _toast('Opening WhatsApp…');
                setState(() => _aiTip = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _pageHeader(int total, int overdue, int newThisWeek, int enrolled, List<SchoolClassEntity> classes, dynamic sources, dynamic references, List<InquiryEntity> inquiries) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Icon(Icons.bar_chart, size: 18, color: Color(0xFF6366F1)),
              const Text.rich(TextSpan(children: [
                TextSpan(text: 'Admissions ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                TextSpan(text: 'Command Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic, color: Color(0xFF6366F1))),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: const [
                _Dot(),
                SizedBox(width: 4),
                Text('Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _pill('Total: $total', const Color(0xFFF3F4F6), const Color(0xFF374151)),
            if (overdue > 0) _pill('$overdue Overdue', const Color(0xFFFEF2F2), const Color(0xFFB91C1C), border: const Color(0xFFFECACA)),
            _pill('$newThisWeek this week', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
            if (enrolled > 0) _pill('$enrolled enrolled', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _globalSearch = v),
                decoration: InputDecoration(
                  hintText: 'Search name, phone...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF9CA3AF)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _reload, tooltip: 'Refresh', icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF9CA3AF))),
            ElevatedButton.icon(
              onPressed: () => _openEnquiryModal(editing: null, classes: classes, sources: sources, references: references, allInquiries: inquiries),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('New Enquiry'),
              style: ElevatedButton.styleFrom(backgroundColor: kAdmIndigo, foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, border: border != null ? Border.all(color: border) : null, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle));
  }
}

String _computePriorityText(MorningBriefData d) {
  final overdueFollowUp = d.overdueFollowUp;
  final newToday = d.newToday;
  final visitsToday = d.visitsToday;
  final decisionsPending = d.decisionsPending;
  if (overdueFollowUp > 0 && visitsToday > 0) {
    return '$overdueFollowUp follow-up${overdueFollowUp > 1 ? "s" : ""} overdue · $visitsToday visit${visitsToday > 1 ? "s" : ""} scheduled today — start with overdue.';
  }
  if (overdueFollowUp > 5) return '$overdueFollowUp follow-ups are overdue — clear these before taking new inquiries.';
  if (overdueFollowUp > 0) return '$overdueFollowUp follow-up${overdueFollowUp > 1 ? "s" : ""} overdue — reach out before end of day.';
  if (visitsToday > 0) return '$visitsToday campus visit${visitsToday > 1 ? "s" : ""} today — confirm time slots and prepare welcome kits.';
  if (decisionsPending > 0) return '$decisionsPending application${decisionsPending > 1 ? "s" : ""} awaiting a decision — follow up to close.';
  if (newToday > 0) return '$newToday new inquiry${newToday > 1 ? "ies" : "y"} today — respond within 30 minutes for best conversion.';
  return 'All clear — great time to proactively reach out to cold leads.';
}
