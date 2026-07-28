import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/assignment_student.dart';
import '../../domain/models/fee_assignment.dart';
import '../../domain/models/fee_group.dart';
import '../../domain/models/fees_payment.dart';
import '../../domain/models/fees_reconciliation.dart';
import '../../domain/models/school_header_info.dart';
import '../providers/fees_assignment_providers.dart';
import '../providers/fees_collection_providers.dart';
import '../providers/fees_config_providers.dart';
import '../providers/fees_providers.dart';
import '../utils/fee_assignment_format.dart' show fmtRs, groupIndian;
import '../utils/fees_collection_format.dart' show fmtDate, resolvedDueAmount, resolvedTotal;
import '../utils/fc_ledger_pdf.dart';
import '../widgets/fc_add_reconciliation_dialog.dart';
import '../widgets/fc_confirm_payment_dialog.dart';
import '../widgets/fc_edit_header_dialog.dart';
import '../widgets/fc_receipt_preview_dialog.dart';
import '../widgets/fc_student_ledger_dialog.dart';
import '../widgets/fees_collection_models.dart';
import '../widgets/fees_collection_styles.dart';
import '../widgets/fees_layout.dart';
import '../widgets/fees_module_sub_nav.dart';

/// Collection — converted from
/// `frontend/components/fees/FeesCollectionPanel.tsx` (the "Collection" tab
/// of the Fees module, `/fees/collection`). The frontend is the sole
/// source of truth for this port; see the three tabs below (Collection,
/// Student Ledger, Recent Payments) plus the Confirm Payment / Add
/// Reconciliation / Student Ledger View / Edit Receipt Header dialogs and
/// the receipt/ledger PDF generators in `presentation/utils/fc_*_pdf.dart`.
class FeesCollectionPage extends ConsumerStatefulWidget {
  const FeesCollectionPage({super.key});

  @override
  ConsumerState<FeesCollectionPage> createState() => _FeesCollectionPageState();
}

class _FeesCollectionPageState extends ConsumerState<FeesCollectionPage> with WidgetsBindingObserver {
  List<AssignmentStudent> _studentsData = [];
  List<FeeAssignment> _assignments = [];
  List<FeesPayment> _paymentsList = [];
  // Fetched for fetch-parity with the source's own `fetchDynamicData` (which
  // fetches groups alongside students/assignments/payments/reconciliations/
  // school-info) but never actually read anywhere else in that file either.
  // ignore: unused_field
  List<FeesGroup> _groups = [];
  List<FeesReconciliation> _reconList = [];
  SchoolHeaderInfo _schoolHeader = const SchoolHeaderInfo();
  bool _loading = true;

  String? _selectedId;
  final _searchCtrl = TextEditingController();
  bool _showDrop = false;
  Set<String> _checked = {};
  final _amtPaidCtrl = TextEditingController(text: '0');
  String _method = 'Cash';
  final _dateTimeCtrl = TextEditingController(text: '27-05-2026 10:30');
  final _noteCtrl = TextEditingController(text: 'Parent requested receipt copy by email.');
  int _rcptN = 5315;
  String? _toast;
  int _activeTab = 0; // 0 collection, 1 ledger, 2 payments
  String _collectedBy = 'Finance Desk';
  String _counter = 'Counter 1';
  bool _printNow = true;
  bool _sendSms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDynamicData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _amtPaidCtrl.dispose();
    _dateTimeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mirrors the source's `document.visibilitychange` listener — a
    // lightweight assignments+payments-only refresh when the app resumes.
    if (state == AppLifecycleState.resumed) _refreshPaymentData();
  }

  void _showToast(String message) {
    setState(() => _toast = message);
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && _toast == message) setState(() => _toast = null);
    });
  }

  Future<void> _fetchDynamicData() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      ref.read(feesAssignmentRepositoryProvider).fetchStudents().catchError((_) => <AssignmentStudent>[]),
      ref.read(feesAssignmentRepositoryProvider).fetchAssignments().catchError((_) => <FeeAssignment>[]),
      ref.read(feesRepositoryProvider).fetchPayments().catchError((_) => <FeesPayment>[]),
      ref.read(feesConfigRepositoryProvider).fetchGroups().catchError((_) => <FeesGroup>[]),
      ref.read(feesCollectionRepositoryProvider).fetchReconciliations().catchError((_) => <FeesReconciliation>[]),
      ref.read(feesCollectionRepositoryProvider).fetchMySchoolInfo().catchError((_) => const SchoolHeaderInfo()),
    ]);
    if (!mounted) return;
    setState(() {
      _studentsData = results[0] as List<AssignmentStudent>;
      _assignments = results[1] as List<FeeAssignment>;
      _paymentsList = results[2] as List<FeesPayment>;
      _groups = results[3] as List<FeesGroup>;
      _reconList = results[4] as List<FeesReconciliation>;
      _schoolHeader = results[5] as SchoolHeaderInfo;
      _loading = false;
    });
  }

  Future<void> _refreshPaymentData() async {
    final results = await Future.wait<dynamic>([
      ref.read(feesAssignmentRepositoryProvider).fetchAssignments().catchError((_) => <FeeAssignment>[]),
      ref.read(feesRepositoryProvider).fetchPayments().catchError((_) => <FeesPayment>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _assignments = results[0] as List<FeeAssignment>;
      _paymentsList = results[1] as List<FeesPayment>;
    });
  }

  // ── Derived data (mirrors the source's STUDENTS/INIT_PAYMENTS useMemo blocks) ──

  List<FcStudentRecord> get _students {
    const methodLabel = {'cash': 'Cash', 'online': 'Online / UPI', 'bank': 'Bank Transfer', 'cheque': 'Cheque', 'wallet': 'Wallet'};
    const statusLabel = {
      'posted': 'Settled',
      'pending_clearance': 'Pending clearance',
      'pending_reconciliation': 'Pending reconciliation',
      'pending_verification': 'Pending verification',
      'reversed': 'Reversed',
    };

    return _studentsData.map((st) {
      final stAsgns = _assignments.where((a) => a.student.toString() == st.id.toString()).toList();
      final stPays = _paymentsList.where((p) => stAsgns.any((a) => a.id.toString() == p.assignment.toString())).toList();

      final ledger = <FcLedgerEntry>[];
      double totalDue = 0, totalPaid = 0;
      final dues = <FcDue>[];

      final asgnByKey = <String, FeeAssignment>{};
      int statusRank(String s) => s == 'paid' ? 2 : (s == 'partial' ? 1 : 0);
      for (final a in stAsgns) {
        final key = '${a.feesType}-${a.dueDate}';
        final existing = asgnByKey[key];
        if (existing == null || statusRank(a.status) > statusRank(existing.status)) {
          asgnByKey[key] = a;
        }
      }
      final uniqueAsgns = asgnByKey.values.toList();

      for (var i = 0; i < uniqueAsgns.length; i++) {
        final a = uniqueAsgns[i];
        final amt = double.tryParse(a.amount) ?? 0;
        final feeLabel = (a.feesTypeName?.isNotEmpty ?? false) ? a.feesTypeName! : 'Fee Assignment ${i + 1}';
        totalDue += amt;

        final pendingPays = stPays.where((p) => p.assignment.toString() == a.id.toString() && p.status != 'posted' && p.status != 'reversed').toList();
        final pendingAmt = pendingPays.fold<double>(0, (s, p) => s + (double.tryParse(p.amountPaid) ?? 0));

        final dueStatus = a.status == 'paid'
            ? 'Paid in full'
            : a.status == 'partial'
                ? 'Partially paid'
                : pendingPays.isNotEmpty
                    ? 'Payment pending verification'
                    : 'Pending payment';
        ledger.add(FcLedgerEntry(
          date: a.dueDate.isEmpty ? '2025-01-01' : a.dueDate,
          title: '$feeLabel assigned',
          note: 'Due ${fmtDate(a.dueDate)} · $dueStatus',
          amount: amt,
          type: FcLedgerType.charge,
        ));

        if (a.status != 'paid') {
          final netDue = double.tryParse(a.netDue ?? a.amount) ?? 0;
          final remaining = netDue - pendingAmt;
          final effectiveRemaining = remaining < 0 ? 0.0 : remaining;
          if (effectiveRemaining > 0) {
            dues.add(FcDue(id: a.id.toString(), label: feeLabel, amount: effectiveRemaining, due: a.dueDate.isEmpty ? 'N/A' : a.dueDate));
          }
        }
      }

      for (final p in stPays) {
        final pAmt = double.tryParse(p.amountPaid) ?? 0;
        if (p.status == 'posted') totalPaid += pAmt;
        final mLabel = methodLabel[p.method] ?? (p.method.isEmpty ? 'Payment' : p.method);
        final sLabel = statusLabel[p.status ?? ''] ?? (p.status ?? '');
        final datePart = p.paidAtRaw.split('T').first;
        ledger.add(FcLedgerEntry(
          date: datePart.isEmpty ? '2025-01-01' : datePart,
          title: 'Payment received — $mLabel',
          note: sLabel,
          amount: pAmt,
          type: FcLedgerType.credit,
        ));
      }

      String status;
      if (uniqueAsgns.isEmpty) {
        status = 'unassigned';
      } else if (totalDue == 0) {
        status = 'cleared';
      } else if (totalPaid >= totalDue) {
        status = 'cleared';
      } else if (totalPaid > 0) {
        status = 'partial';
      } else {
        status = 'overdue';
      }

      final clsName = (st.currentClassName?.isNotEmpty ?? false) ? st.currentClassName! : 'N/A';
      return FcStudentRecord(
        id: st.id.toString(),
        name: st.fullName,
        admNo: st.admissionNo.isEmpty ? 'ID-${st.id}' : st.admissionNo,
        cls: clsName,
        group: 'Assigned',
        status: status,
        dues: dues,
        ledger: ledger,
        fullLedger: ledger,
        ledgerBalance: totalDue - totalPaid,
      );
    }).toList();
  }

  List<FcPaymentRow> get _initPayments {
    final students = _students;
    final sorted = [..._paymentsList]..sort((a, b) => b.id.compareTo(a.id));
    return sorted.map((p) {
      final stuRecord = students.where((s) => s.id == p.student.toString()).firstOrNull;
      final stuRaw = stuRecord == null ? _studentsData.where((s) => s.id.toString() == p.student.toString()).firstOrNull : null;
      var name = stuRecord?.name ?? (stuRaw != null ? stuRaw.fullName : '');
      if (name.isEmpty) name = 'Unknown';
      final asgn = _assignments.where((a) => a.id.toString() == p.assignment.toString()).firstOrNull;
      final stuData = _studentsData.where((s) => s.id.toString() == p.student.toString()).firstOrNull;
      final admNo = (stuData != null && stuData.admissionNo.isNotEmpty) ? stuData.admissionNo : (stuRecord?.admNo ?? 'STU-${p.student}');
      final cls = (stuData?.currentClassName?.isNotEmpty ?? false) ? stuData!.currentClassName! : (stuRecord?.cls ?? '—');
      final datePart = p.paidAtRaw.split('T').first;
      return FcPaymentRow(
        id: p.id,
        rcpt: 'PMT-${p.id}',
        student: name,
        admNo: admNo,
        cls: cls,
        feeName: asgn?.feesTypeName ?? '',
        amount: double.tryParse(p.amountPaid) ?? 0,
        method: p.method.isEmpty ? 'cash' : p.method,
        status: p.status ?? 'posted',
        date: fmtDate(datePart),
        txRef: p.transactionReference ?? '',
        noteText: p.note ?? '',
      );
    }).toList();
  }

  FcStudentRecord? get _selected => _selectedId == null ? null : _students.where((s) => s.id == _selectedId).firstOrNull;

  List<FcStudentRecord> get _results {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return const [];
    return _students.where((s) => s.name.toLowerCase().contains(q) || s.admNo.toLowerCase().contains(q)).toList();
  }

  List<FcDue> get _selDues => _selected?.dues.where((d) => _checked.contains(d.id)).toList() ?? const [];

  // ── Actions ──────────────────────────────────────────────────────────────

  void _onCollectionSearchChanged(String value) {
    setState(() {
      _showDrop = true;
      if (_selectedId != null && value != (_selected?.name ?? '')) _selectedId = null;
    });
  }

  void _onLedgerSearchChanged(String value) {
    setState(() {
      _showDrop = true;
      _selectedId = null;
    });
  }

  void _pick(FcStudentRecord s) {
    setState(() {
      _selectedId = s.id;
      _searchCtrl.text = s.name;
      _showDrop = false;
      _checked = s.dues.map((d) => d.id).toSet();
      _amtPaidCtrl.text = _jsNumToString(s.dues.fold<double>(0, (a, d) => a + d.amount));
      _noteCtrl.text = '';
      _method = 'Cash';
    });
  }

  void _toggleDue(String id) {
    setState(() {
      if (_checked.contains(id)) {
        _checked.remove(id);
      } else {
        _checked.add(id);
      }
      final selDues = _selected?.dues.where((d) => _checked.contains(d.id)).toList() ?? const <FcDue>[];
      _amtPaidCtrl.text = _jsNumToString(selDues.fold<double>(0, (a, d) => a + d.amount));
    });
  }

  void _save() {
    if (_selected == null || _checked.isEmpty) {
      _showToast('Select a student and at least one item.');
      return;
    }
    _openConfirmDialog();
  }

  Future<void> _openConfirmDialog() async {
    final selected = _selected!;
    await FcConfirmPaymentDialog.show(
      context,
      studentName: selected.name,
      admNo: selected.admNo,
      cls: selected.cls,
      method: _method,
      selDues: _selDues,
      amtPaidText: _amtPaidCtrl.text,
      rcptPreview: 'RCPT-25-$_rcptN',
      initialCollectedBy: _collectedBy,
      initialCounter: _counter,
      initialPrintNow: _printNow,
      initialSendSms: _sendSms,
      onCollectedByChanged: (v) => _collectedBy = v,
      onCounterChanged: (v) => _counter = v,
      onPrintNowChanged: (v) => _printNow = v,
      onSendSmsChanged: (v) => _sendSms = v,
      onConfirm: _postPayment,
    );
  }

  static const _methodMap = {'Cash': 'cash', 'Online': 'online', 'Bank Transfer': 'bank', 'Cheque': 'cheque', 'Wallet': 'wallet'};

  String _parseDateTimeToIso(String dateStr) {
    final segs = dateStr.split(' ');
    final datePart = segs.isNotEmpty ? segs[0] : '';
    final timePart = segs.length > 1 && segs[1].isNotEmpty ? segs[1] : '00:00';
    final dParts = datePart.split('-');
    if (dParts.isNotEmpty && dParts[0].length == 4) {
      return '${datePart}T$timePart:00';
    }
    if (dParts.length == 3) {
      final dd = dParts[0], mm = dParts[1], yyyy = dParts[2];
      return '$yyyy-$mm-${dd}T$timePart:00';
    }
    return '${datePart}T$timePart:00';
  }

  Future<bool> _postPayment() async {
    final selected = _selected;
    if (selected == null) return false;
    final receipt = 'RCPT-25-$_rcptN';
    try {
      final paidAtIso = _parseDateTimeToIso(_dateTimeCtrl.text);
      final backendMethod = _methodMap[_method] ?? 'cash';
      final selDues = _selDues;
      for (final due in selDues) {
        final dueAmt = resolvedDueAmount(due, selDues.length, _amtPaidCtrl.text);
        // Do NOT send student/status — the backend derives both; see
        // FeesCollectionRepository's doc comment.
        await ref.read(feesCollectionRepositoryProvider).createPayment(
              assignment: int.parse(due.id),
              amountPaid: _jsNumToString(dueAmt),
              method: backendMethod,
              paidAt: paidAtIso,
              note: _noteCtrl.text,
            );
      }
      await _refreshPaymentData();
      if (!mounted) return true;
      setState(() {
        _rcptN += 1;
        _checked = {};
        _amtPaidCtrl.text = '0';
        _noteCtrl.text = '';
        _method = 'Cash';
      });
      _showToast('Receipt $receipt posted for ${selected.name}.');
      return true;
    } catch (_) {
      _showToast('Payment failed. Please try again.');
      return false;
    }
  }

  Future<void> _openAddReconciliation() async {
    final created = await FcAddReconciliationDialog.show(context, onToast: _showToast);
    if (created != null && mounted) {
      setState(() => _reconList = [created, ..._reconList]);
      _showToast('Reconciliation record added.');
    }
  }

  Future<void> _openEditHeader() async {
    final result = await FcEditHeaderDialog.show(context, initial: _schoolHeader);
    if (result != null && mounted) setState(() => _schoolHeader = result);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FeesLayout(
      activeTab: FeesModuleTab.collection,
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  if (_activeTab == 0) _buildCollectionTab(),
                  if (_activeTab == 1) _buildLedgerTab(),
                  if (_activeTab == 2) _buildPaymentsTab(),
                ],
              ),
            ),
            if (_toast != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 28, offset: Offset(0, 8))]),
                    child: Text(_toast!, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PAYMENT DESK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: fcPurple)),
          const SizedBox(height: 5),
          const Text('Collection', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: fcInk1, height: 1.1)),
          const SizedBox(height: 6),
          const Text('Search a student, record payment across one or more assignments, and issue a receipt.', style: TextStyle(fontSize: 14, color: fcInk3)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = [('Collection', 0), ('Student Ledger', 1), ('Recent Payments', 2)];
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: fcBorder, width: 2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [for (final t in tabs) _tabButton(t.$1, t.$2)]),
    );
  }

  Widget _tabButton(String label, int idx) {
    final active = _activeTab == idx;
    return InkWell(
      onTap: () => setState(() => _activeTab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? fcPurple : Colors.transparent, width: 3))),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? fcPurple : fcInk2)),
      ),
    );
  }

  // ── Shared search box / dropdown (used by both the Collection tab and the
  // Student Ledger tab's own "search a student" empty state) ──────────────

  Widget _searchBox({required ValueChanged<String> onChanged}) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(9)),
      child: Row(
        children: [
          const Text('Search', style: TextStyle(color: fcInk3, fontSize: 13.5, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: onChanged,
              onTap: () => setState(() => _showDrop = true),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              style: const TextStyle(fontSize: 13.5, color: fcInk1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(9), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8))]),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: [for (final s in _results) _dropdownRow(s)]),
    );
  }

  Widget _dropdownRow(FcStudentRecord s) {
    final st = fcStatusStyle[s.status] ?? fcStatusStyle['unassigned']!;
    return InkWell(
      onTap: () => _pick(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
        child: Row(
          children: [
            FcAvatar(name: s.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fcInk1)),
                  Text('${s.admNo} · Class ${s.cls} · ${s.group}', style: const TextStyle(fontSize: 12, color: fcInk3)),
                ],
              ),
            ),
            FcStatusPill(label: s.status, bg: st.bg, color: st.color),
          ],
        ),
      ),
    );
  }

  // ── Tab 1 — Collection ───────────────────────────────────────────────────

  Widget _buildCollectionTab() {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _studentSearchCard(),
        const SizedBox(height: 16),
        if (selected != null) ...[_paymentFormCard(selected), const SizedBox(height: 16)],
        _receiptPreviewCard(),
        const SizedBox(height: 16),
        _reconciliationCard(),
      ],
    );
  }

  Widget _studentSearchCard() {
    final selected = _selected;
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: Text('Student Search', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fcInk1))),
              FcOutlineButton(small: true, label: _loading ? 'Loading…' : '⟳ Refresh', onPressed: _loading ? null : _fetchDynamicData),
            ],
          ),
          const SizedBox(height: 3),
          const Text('Type a name or admission number to load outstanding assignments.', style: TextStyle(fontSize: 13, color: fcInk3)),
          const SizedBox(height: 16),
          _searchBox(onChanged: _onCollectionSearchChanged),
          if (_showDrop && _results.isNotEmpty && selected == null) _dropdown(),
          if (selected != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: fcPurpleTint, border: Border.all(color: fcPurpleBorder), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  FcAvatar(name: selected.name, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selected.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fcInk1)),
                        Text('${selected.admNo} · Class ${selected.cls} · ${selected.group}', style: const TextStyle(fontSize: 12.5, color: fcInk3)),
                      ],
                    ),
                  ),
                  FcStatusPill(
                    label: selected.status,
                    bg: (fcStatusStyle[selected.status] ?? fcStatusStyle['unassigned']!).bg,
                    color: (fcStatusStyle[selected.status] ?? fcStatusStyle['unassigned']!).color,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentFormCard(FcStudentRecord selected) {
    final selDues = _selDues;
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Form', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fcInk1)),
          const SizedBox(height: 3),
          const Text('Conditional cheque and transaction fields appear by method.', style: TextStyle(fontSize: 13, color: fcInk3)),
          const SizedBox(height: 18),
          if (selected.dues.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                selected.status == 'unassigned'
                    ? 'No fees have been assigned to this student yet. Go to the Fee Assignment panel to assign fees first.'
                    : 'All assigned fees are fully paid. Nothing outstanding.',
                style: TextStyle(fontSize: 13, color: selected.status == 'unassigned' ? const Color(0xFFD97706) : fcInk3),
              ),
            )
          else
            Column(children: [for (final due in selected.dues) ...[_dueRow(due), const SizedBox(height: 6)]]),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FcLabeledField(
                  label: 'AMOUNT PAID',
                  field: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _amtPaidCtrl,
                        readOnly: selDues.length > 1,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: fcFieldDecoration(readOnly: selDues.length > 1),
                      ),
                      if (selDues.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Auto-calculated — paying ${selDues.length} items in full', style: const TextStyle(fontSize: 11, color: fcInk3)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FcLabeledField(
                  label: 'PAYMENT METHOD',
                  field: DropdownButtonFormField<String>(
                    initialValue: _method,
                    isExpanded: true,
                    decoration: fcFieldDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Online', child: Text('Online')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      DropdownMenuItem(value: 'Wallet', child: Text('Wallet')),
                    ],
                    onChanged: (v) => setState(() => _method = v ?? 'Cash'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FcLabeledField(
            label: 'DATE / TIME',
            field: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: _dateTimeCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: fcFieldDecoration().copyWith(contentPadding: const EdgeInsets.only(left: 12, right: 40, top: 10, bottom: 10)),
                ),
                const Padding(padding: EdgeInsets.only(right: 12), child: Text('📅')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FcLabeledField(
            label: 'NOTE',
            field: TextField(
              controller: _noteCtrl,
              onChanged: (_) => setState(() {}),
              minLines: 3,
              maxLines: 3,
              decoration: fcFieldDecoration(hintText: 'Add a note (optional)'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FcPrimaryButton(label: 'Save & Print Receipt', onPressed: _save)),
        ],
      ),
    );
  }

  Widget _dueRow(FcDue due) {
    final checked = _checked.contains(due.id);
    return InkWell(
      onTap: () => _toggleDue(due.id),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: checked ? fcPurpleTintRow : Colors.white,
          border: Border.all(color: checked ? fcPurpleBorder : fcBorder),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Checkbox(value: checked, onChanged: (_) => _toggleDue(due.id), activeColor: fcPurple, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(due.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fcInk1)),
                  const SizedBox(height: 2),
                  Text('Due ${due.due}', style: const TextStyle(fontSize: 12, color: fcInk3)),
                ],
              ),
            ),
            Text(fmtRs(due.amount), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fcInk1)),
          ],
        ),
      ),
    );
  }

  Widget _receiptPreviewCard() {
    final selected = _selected;
    final selDues = _selDues;
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Receipt Preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fcInk1)),
          const SizedBox(height: 3),
          const Text('Formatted preview before Save & Print Receipt.', style: TextStyle(fontSize: 13, color: fcInk3)),
          const SizedBox(height: 16),
          if (selected != null && selDues.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Eskoolia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fcInk1, height: 1.2)),
                          SizedBox(height: 2),
                          Text('Aravali Public School', style: TextStyle(fontSize: 12, color: fcInk3)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('RCPT-25-$_rcptN', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fcInk1)),
                          const SizedBox(height: 2),
                          Text(_dateTimeCtrl.text, style: const TextStyle(fontSize: 12, color: fcInk3)),
                        ],
                      ),
                    ],
                  ),
                  Container(height: 1, color: fcBorder, margin: const EdgeInsets.symmetric(vertical: 12)),
                  _previewRow('Student', selected.name),
                  _previewRow('Class / Adm No', '${selected.cls} / ${selected.admNo}'),
                  for (final d in selDues) _previewRow(d.label, fmtRs(resolvedDueAmount(d, selDues.length, _amtPaidCtrl.text))),
                  _previewRow('Payment Method', _method),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Received', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fcInk1)),
                        Text(fmtRs(resolvedTotal(selDues, _amtPaidCtrl.text)), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fcPurple)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              // The source uses a dashed border here; Flutter has no
              // built-in dashed-border decoration and this app doesn't
              // otherwise depend on a dashed-border package, so a solid
              // border is used for this purely-cosmetic empty state.
              decoration: BoxDecoration(border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
              child: const Text('Select a student and fee items to preview receipt', style: TextStyle(fontSize: 13, color: fcInk3), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: fcInk2)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fcInk1), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _reconciliationCard() {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Payment Reconciliation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fcInk1)),
                    SizedBox(height: 3),
                    Text('Match bank, online, wallet, and cheque records against receipts.', style: TextStyle(fontSize: 13, color: fcInk3)),
                  ],
                ),
              ),
              FcPrimaryButton(small: true, label: '+ Add', onPressed: _openAddReconciliation),
            ],
          ),
          const SizedBox(height: 16),
          if (_reconList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No reconciliation records yet. Click + Add to create one.', style: TextStyle(fontSize: 13, color: fcInk3))),
            )
          else
            Column(children: [for (final r in _reconList) ...[_reconRow(r), const SizedBox(height: 10)]]),
        ],
      ),
    );
  }

  Widget _reconRow(FeesReconciliation r) {
    const statusMap = {
      'matched': (bg: Color(0xFFDCFCE7), color: Color(0xFF15803D)),
      'review': (bg: Color(0xFFFEF3C7), color: Color(0xFFD97706)),
      'needs_mapping': (bg: Color(0xFFFEE2E2), color: Color(0xFFDC2626)),
    };
    const labelMap = {'matched': 'Matched', 'review': 'Review', 'needs_mapping': 'Needs mapping'};
    const methodLabel = {'cash': 'Cash', 'bank': 'Bank', 'online': 'Online / UPI', 'cheque': 'Cheque', 'wallet': 'Wallet'};
    final st = statusMap[r.status] ?? statusMap['review']!;
    final amt = double.tryParse(r.amount) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.reference, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fcInk1)),
                const SizedBox(height: 3),
                Text('${methodLabel[r.method] ?? r.method} · Rs. ${groupIndian(amt.round().toString())} · ${r.date}', style: const TextStyle(fontSize: 12, color: fcInk3)),
                if ((r.matchNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.matchNote!, style: const TextStyle(fontSize: 12, color: fcInk3)),
                ],
                const SizedBox(height: 8),
                FcStatusPill(label: labelMap[r.status] ?? r.status, bg: st.bg, color: st.color),
              ],
            ),
          ),
          if (r.score > 0) ...[const SizedBox(width: 12), FcScoreCircle(score: r.score)],
        ],
      ),
    );
  }

  // ── Tab 2 — Student Ledger ───────────────────────────────────────────────

  Widget _buildLedgerTab() {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student Ledger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: fcInk1)),
        const SizedBox(height: 4),
        const Text('Per-student accounting timeline of charges, concessions, payments, and adjustments.', style: TextStyle(fontSize: 14, color: fcInk3)),
        const SizedBox(height: 20),
        if (selected == null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search a student to view their ledger', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fcInk1)),
                  const SizedBox(height: 10),
                  _searchBox(onChanged: _onLedgerSearchChanged),
                  if (_showDrop && _results.isNotEmpty && selected == null) _dropdown(),
                ],
              ),
            ),
          )
        else
          _ledgerCard(selected),
      ],
    );
  }

  Widget _ledgerCard(FcStudentRecord selected) {
    final st = fcStatusStyle[selected.status] ?? fcStatusStyle['unassigned']!;
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FcAvatar(name: selected.name, size: 42),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(selected.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fcInk1)),
                      Text('${selected.admNo} · Class ${selected.cls} · ${selected.group}', style: const TextStyle(fontSize: 12.5, color: fcInk3)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  FcStatusPill(label: selected.status, bg: st.bg, color: st.color),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FcOutlineButton(small: true, label: 'Change Student', onPressed: () => setState(() { _selectedId = null; _searchCtrl.clear(); })),
                  const SizedBox(width: 8),
                  FcOutlineButton(
                    small: true,
                    label: 'Full Ledger PDF',
                    onPressed: () => FcStudentLedgerDialog.show(
                      context,
                      student: selected,
                      onGeneratePdf: () => shareLedgerPdf(student: selected, header: _schoolHeader),
                      onToast: _showToast,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final e in selected.ledger) ...[_ledgerListRow(e), const SizedBox(height: 8)],
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: fcBorder, width: 2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ledger balance', style: TextStyle(fontSize: 14, color: fcInk2)),
                Text(fmtRs(selected.ledgerBalance), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: fcPurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledgerListRow(FcLedgerEntry e) {
    final color = e.type == FcLedgerType.credit ? const Color(0xFF16A34A) : (e.type == FcLedgerType.charge ? const Color(0xFFDC2626) : fcInk3);
    final amountText = e.amount != null ? '${e.type == FcLedgerType.credit ? '−' : ''}Rs. ${groupIndian(e.amount!.round().abs().toString())}' : 'Note';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFF0F0F0)), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(fmtDate(e.date), style: const TextStyle(fontSize: 11.5, color: fcInk3, height: 1.4)))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fcInk1)),
                const SizedBox(height: 3),
                Text(e.note, style: const TextStyle(fontSize: 12, color: fcInk3, height: 1.4)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: 2), child: Text(amountText, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color))),
        ],
      ),
    );
  }

  // ── Tab 3 — Recent Payments ──────────────────────────────────────────────

  Widget _buildPaymentsTab() {
    final rows = _initPayments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Recent Payments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: fcInk1)),
                const SizedBox(height: 4),
                Text(_loading ? 'Loading…' : '${rows.length} payment${rows.length == 1 ? '' : 's'} across all students', style: const TextStyle(fontSize: 14, color: fcInk3)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FcOutlineButton(small: true, label: 'Edit Header', onPressed: _openEditHeader),
                const SizedBox(width: 8),
                FcOutlineButton(small: true, label: 'Refresh', onPressed: _refreshPaymentData),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        FcCard(
          padding: EdgeInsets.zero,
          child: _loading
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: Text('Loading payments…', style: TextStyle(fontSize: 13, color: fcInk3))))
              : _paymentsTable(rows),
        ),
      ],
    );
  }

  static const _colRcpt = 90.0, _colDate = 90.0, _colStudent = 160.0, _colAmount = 100.0, _colMethod = 110.0, _colStatus = 150.0, _colActions = 100.0;
  static const _tableWidth = _colRcpt + _colDate + _colStudent + _colAmount + _colMethod + _colStatus + _colActions + 28;

  Widget _paymentsTable(List<FcPaymentRow> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _tableWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFFF8F8FB),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: const Row(
                children: [
                  SizedBox(width: _colRcpt, child: Text('#', style: fcThStyle)),
                  SizedBox(width: _colDate, child: Text('DATE', style: fcThStyle)),
                  SizedBox(width: _colStudent, child: Text('STUDENT', style: fcThStyle)),
                  SizedBox(width: _colAmount, child: Text('AMOUNT', style: fcThStyle)),
                  SizedBox(width: _colMethod, child: Text('METHOD', style: fcThStyle)),
                  SizedBox(width: _colStatus, child: Text('STATUS', style: fcThStyle)),
                  SizedBox(width: _colActions, child: Text('ACTIONS', style: fcThStyle)),
                ],
              ),
            ),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text('No payments have been posted yet.', style: TextStyle(fontSize: 13, color: fcInk3))),
              )
            else
              for (var i = 0; i < rows.length; i++) _paymentRow(rows[i], i < rows.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _paymentRow(FcPaymentRow p, bool divider) {
    const statusCfg = {
      'posted': (bg: Color(0xFFDCFCE7), color: Color(0xFF15803D), label: 'Posted'),
      'pending_clearance': (bg: Color(0xFFFEF3C7), color: Color(0xFFD97706), label: 'Pending clearance'),
      'pending_reconciliation': (bg: Color(0xFFFEF3C7), color: Color(0xFFD97706), label: 'Pending reconciliation'),
      'pending_verification': (bg: Color(0xFFEDE9FE), color: Color(0xFF7C3AED), label: 'Pending verification'),
      'reversed': (bg: Color(0xFFFEE2E2), color: Color(0xFFDC2626), label: 'Reversed'),
    };
    const methodLabel = {'cash': 'Cash', 'bank': 'Bank Transfer', 'online': 'Online / UPI', 'wallet': 'Wallet', 'cheque': 'Cheque'};
    final cfg = statusCfg[p.status] ?? statusCfg['posted']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(border: Border(bottom: divider ? const BorderSide(color: fcBorder) : BorderSide.none)),
      child: Row(
        children: [
          SizedBox(width: _colRcpt, child: Text(p.rcpt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fcPurple))),
          SizedBox(width: _colDate, child: Text(p.date.isEmpty ? '—' : p.date, style: const TextStyle(fontSize: 12, color: fcInk3))),
          SizedBox(width: _colStudent, child: Text(p.student, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fcInk1), overflow: TextOverflow.ellipsis)),
          SizedBox(width: _colAmount, child: Text(fmtRs(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fcInk1))),
          SizedBox(width: _colMethod, child: Text(methodLabel[p.method] ?? p.method, style: const TextStyle(fontSize: 12, color: fcInk1))),
          SizedBox(width: _colStatus, child: FcStatusPill(label: cfg.label, bg: cfg.bg, color: cfg.color)),
          SizedBox(width: _colActions, child: FcOutlineButton(small: true, label: 'Receipt', onPressed: () => FcReceiptPreviewDialog.show(context, payment: p, header: _schoolHeader))),
        ],
      ),
    );
  }
}

String _jsNumToString(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
