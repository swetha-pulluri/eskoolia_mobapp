import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/school_entity.dart';
import '../providers/school_tenancy_provider.dart';

/// Mobile equivalent of web's `NewInvoiceDrawer` (`billing/NewInvoiceDrawer.tsx`)
/// — numbered "Billed to" / "Invoice details" / "Line items" / "Notes & terms"
/// sections, a live proactive duplicate-invoice check (debounced, matching
/// the drawer's own `useEffect` on `[tenantId, invoiceDate]`), live GST
/// computation (CGST+SGST for intra-state, IGST for inter-state), a Tax
/// summary + Tax logic applied preview, and a real
/// `POST /api/super-admin/billing/invoices/` submission with the same
/// duplicate-invoice (409) confirmation flow as a fallback.
///
/// Web's drawer is a SINGLE component for both "New" and "Edit" — passing
/// [invoice] switches this into the same edit mode: School/Subscription
/// plan/line items become locked (re-issue for corrections), the footer
/// collapses to one "Save changes" action, and submit only PATCHes the
/// safely-editable fields (`status`/`due_date`/`notes`/`terms_conditions`
/// — `InvoiceUpdateSerializer`, "Intentionally restricted to fields that do
/// not change GST-relevant amounts"). Previously this was a second,
/// independently-hand-built `EditInvoiceSheet` widget that inevitably drifted
/// out of sync with the real page (missing School/Plan/GSTIN/State, the Line
/// items table, and the Tax summary/Tax logic panels) — mirroring the web's
/// own single-component design instead keeps both modes sharing one source
/// of truth for layout.
///
/// Seller identity (`SELLER_DEFAULTS` in the web source) is hardcoded on web
/// itself, not fetched from any API — replicated verbatim here rather than
/// invented.
class NewInvoiceSheet extends ConsumerStatefulWidget {
  const NewInvoiceSheet({super.key, this.invoice});

  /// When provided, opens in edit mode pre-filled from this invoice.
  final InvoiceEntity? invoice;

  @override
  ConsumerState<NewInvoiceSheet> createState() => _NewInvoiceSheetState();

  static const sellerName = 'Eskoolia Technologies Pvt Ltd';
  static const sellerGstin = '29AABCE1234F1ZS';
  static const sellerState = 'Karnataka';

  // Matches web's own `STATE_CODE` map exactly (`NewInvoiceDrawer.tsx:17-25`)
  // — a different (and slightly different) list than billing_tab.dart's own
  // `_stateCodes`, which mirrors billing/page.tsx's own `stateCode()` instead.
  static const stateCodes = {
    'andhra pradesh': '37', 'telangana': '36', 'karnataka': '29', 'tamil nadu': '33',
    'kerala': '32', 'maharashtra': '27', 'gujarat': '24', 'rajasthan': '08',
    'madhya pradesh': '23', 'uttar pradesh': '09', 'bihar': '10', 'west bengal': '19',
    'odisha': '21', 'jharkhand': '20', 'chhattisgarh': '22', 'haryana': '06',
    'punjab': '03', 'himachal pradesh': '02', 'uttarakhand': '05', 'delhi': '07',
    'goa': '30', 'assam': '18', 'manipur': '14', 'meghalaya': '17',
    'tripura': '16', 'sikkim': '11',
  };
}

class _LineDraft {
  String description;
  String sacCode;
  int quantity;
  double unitPrice;

  _LineDraft({this.description = '', this.sacCode = '998313', this.quantity = 1, this.unitPrice = 0});

  double get amount => quantity * unitPrice;
}

class _NewInvoiceSheetState extends ConsumerState<NewInvoiceSheet> {
  bool get _isEditMode => widget.invoice != null;

  String? _tenantId;
  String? _planCode;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  late String _invoiceNumber;
  bool _reverseCharge = false;
  late String _status;
  String? _submittingStatus;
  final _notesController = TextEditingController();
  final _termsController = TextEditingController(
    text: 'Payment due within 15 days. Late payments attract interest @ 1.5% per month.',
  );
  final List<_LineDraft> _lines = [];
  bool _submitting = false;
  Map<String, dynamic>? _duplicateWarning;
  bool _forceCreate = false;
  Timer? _dupTimer;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    if (invoice != null) {
      // Edit mode — hydrate from the existing invoice
      // (`NewInvoiceDrawer.tsx:194-211`).
      _tenantId = invoice.tenantId;
      _planCode = null; // web always resets planCode to '' in edit mode
      _invoiceDate = DateTime.tryParse(invoice.invoiceDate) ?? DateTime.now();
      _dueDate = DateTime.tryParse(invoice.dueDate) ?? DateTime.now().add(const Duration(days: 15));
      _invoiceNumber = invoice.invoiceNumber;
      _reverseCharge = false; // web hardcodes this on edit-mode hydrate too
      _status = invoice.status;
      _notesController.text = invoice.notes ?? '';
      _termsController.text = invoice.termsConditions ?? '';
      _lines.addAll(invoice.lineItems.map((li) => _LineDraft(
            description: li.description,
            sacCode: li.sacCode,
            quantity: li.quantity,
            unitPrice: li.unitPrice,
          )));
    } else {
      _invoiceNumber = _generateInvoiceNumber();
      _status = 'draft';
      _lines.add(_LineDraft());
    }
    // Web refetches schools + plans every time the drawer opens so newly
    // created plans/schools appear (`NewInvoiceDrawer.tsx:191-207`) — this
    // sheet is a fresh widget instance per open, but the underlying
    // providers aren't `autoDispose`, so force a refresh to match.
    Future.microtask(() {
      ref.invalidate(schoolsForInvoicePickerProvider);
      ref.invalidate(plansProvider);
    });
  }

  @override
  void dispose() {
    _dupTimer?.cancel();
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  /// Mirrors backend's `build_invoice_number()`: INV-YYYYMM-XXXXXXXX (8 hex
  /// chars, upper) — matches web's client-side `generateInvoiceNumber()`
  /// (`NewInvoiceDrawer.tsx:52-64`), which the backend accepts verbatim if
  /// supplied (`views.py:920`: `data.get("invoice_number") or build_invoice_number()`).
  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final yyyymm = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final rnd = Random();
    final bytes = List.generate(4, (_) => rnd.nextInt(256));
    final suffix = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    return 'INV-$yyyymm-$suffix';
  }

  SchoolEntity? _selectedSchool(List<SchoolEntity> schools) {
    if (_tenantId == null) return null;
    for (final s in schools) {
      if (s.tenantId == _tenantId) return s;
    }
    return null;
  }

  /// Matches web's `selectedSchool?.gstin || invoice?.buyer_gstin`
  /// (`NewInvoiceDrawer.tsx:620`) — the freshly-fetched school record wins
  /// when it has a GSTIN, falling back to what's stored on the invoice
  /// (relevant in edit mode if the school isn't in the fetched list, e.g.
  /// archived).
  String _effectiveGstin(SchoolEntity? school) {
    final g = school?.gstin;
    if (g != null && g.isNotEmpty) return g;
    return widget.invoice?.buyerGstin ?? '';
  }

  /// Matches web's `selectedSchool?.state || invoice?.buyer_state`
  /// (`NewInvoiceDrawer.tsx:347`).
  String _effectiveBuyerState(SchoolEntity? school) {
    final s = school?.state;
    if (s != null && s.isNotEmpty) return s;
    return widget.invoice?.buyerState ?? '';
  }

  SubscriptionPlanEntity? _selectedPlan(PlansCatalogEntity? catalog) {
    if (_planCode == null || catalog == null) return null;
    for (final p in catalog.plans) {
      if (p.code == _planCode) return p;
    }
    return null;
  }

  void _onSchoolChanged(String? tenantId, List<SchoolEntity> schools, PlansCatalogEntity? catalog) {
    setState(() {
      _tenantId = tenantId;
      if (tenantId == null || catalog == null) return;
      final school = _selectedSchool(schools);
      final schoolPlan = (school?.plan ?? '').toLowerCase();
      if (schoolPlan.isEmpty || schoolPlan == 'trial' || schoolPlan == 'custom') return;
      for (final p in catalog.plans) {
        if (p.code.toLowerCase() == schoolPlan) {
          _planCode = p.code;
          _applyPlanToFirstLine(p, catalog);
          break;
        }
      }
    });
    _scheduleDuplicateCheck();
  }

  void _applyPlanToFirstLine(SubscriptionPlanEntity plan, PlansCatalogEntity catalog) {
    _lines[0] = _LineDraft(
      description: 'Eskoolia ERP — ${plan.name} plan',
      sacCode: catalog.sacCode,
      quantity: 1,
      unitPrice: plan.priceInr,
    );
  }

  double get _subtotal => _lines.fold(0.0, (sum, l) => sum + l.amount);

  bool _isInterState(String buyerState) {
    if (buyerState.isEmpty) return false;
    return buyerState.trim().toLowerCase() != NewInvoiceSheet.sellerState.trim().toLowerCase();
  }

  String _stateCode(String state) => NewInvoiceSheet.stateCodes[state.trim().toLowerCase()] ?? '';

  /// Proactive duplicate check, debounced 600ms — mirrors web's own
  /// `useEffect` on `[tenantId, invoiceDate]` (`NewInvoiceDrawer.tsx:211-251`):
  /// queries invoices for this school within the invoice date's billing
  /// month and flags the first non-cancelled one whose first line-item
  /// description matches the current line 1 (or any, if line 1 is blank).
  /// Skipped entirely in edit mode (`isEditMode` short-circuits web's own
  /// effect) — in practice this never fires here either, since none of its
  /// triggers (school picker, invoice-date picker, line-1 description field)
  /// are interactive once locked.
  void _scheduleDuplicateCheck() {
    if (_isEditMode) return;
    _dupTimer?.cancel();
    if (_tenantId == null) {
      setState(() {
        _duplicateWarning = null;
        _forceCreate = false;
      });
      return;
    }
    setState(() => _forceCreate = false);
    final tenantId = _tenantId!;
    final year = _invoiceDate.year;
    final month = _invoiceDate.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    final dateFrom = '$year-${month.toString().padLeft(2, '0')}-01';
    final dateTo = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    _dupTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final repository = ref.read(schoolTenancyRepositoryProvider);
        final res = await repository.getInvoices(tenantId: tenantId, dateFrom: dateFrom, dateTo: dateTo, pageSize: 10);
        if (!mounted || _tenantId != tenantId) return;
        final planDesc = _lines.isNotEmpty ? _lines[0].description.trim() : '';
        InvoiceEntity? match;
        for (final inv in res.results) {
          if (inv.status == 'cancelled') continue;
          final invDesc = inv.lineItems.isNotEmpty ? inv.lineItems[0].description.trim() : '';
          if (planDesc.isEmpty || invDesc == planDesc) {
            match = inv;
            break;
          }
        }
        setState(() {
          _duplicateWarning = match == null
              ? null
              : {'id': match.id, 'invoice_number': match.invoiceNumber, 'status': match.status};
        });
      } catch (_) {
        // Best-effort — silently ignore, matching web's own `.catch(() => {})`.
      }
    });
  }

  Future<void> _submit(String status, List<SchoolEntity> schools, PlansCatalogEntity? catalog) async {
    final school = _selectedSchool(schools);
    if (school == null || catalog == null) return;
    if (_lines.any((l) => l.description.trim().isEmpty || l.quantity <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Every line needs a description and a quantity greater than 0.')),
      );
      return;
    }
    if (_subtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice subtotal must be greater than ₹0.')),
      );
      return;
    }

    setState(() {
      _status = status;
      _submitting = true;
      _submittingStatus = status;
    });
    try {
      final gstPercent = catalog.gstPercent;
      final inter = _isInterState(school.state ?? '');
      final subtotal = _subtotal;
      final igst = inter ? double.parse((subtotal * gstPercent / 100).toStringAsFixed(2)) : 0.0;
      final cgst = !inter ? double.parse((subtotal * gstPercent / 200).toStringAsFixed(2)) : 0.0;
      final sgst = !inter ? double.parse((subtotal * gstPercent / 200).toStringAsFixed(2)) : 0.0;
      final totalTax = double.parse((igst + cgst + sgst).toStringAsFixed(2));
      final grandTotal = double.parse((subtotal + totalTax).toStringAsFixed(2));

      final lineItems = _lines.map((l) {
        final amount = double.parse(l.amount.toStringAsFixed(2));
        final gstAmount = double.parse((amount * gstPercent / 100).toStringAsFixed(2));
        return {
          'description': l.description.trim(),
          'sac_code': l.sacCode.isEmpty ? catalog.sacCode : l.sacCode,
          'quantity': l.quantity,
          'unit_price': l.unitPrice,
          'amount': amount,
          'gst_percent': gstPercent,
          'gst_amount': gstAmount,
        };
      }).toList();

      final payload = <String, dynamic>{
        'tenant_id': school.tenantId,
        'invoice_number': _invoiceNumber,
        'school_name': school.name,
        'invoice_date': _isoDate(_invoiceDate),
        'due_date': _isoDate(_dueDate),
        'status': status,
        'seller_name': NewInvoiceSheet.sellerName,
        'seller_gstin': NewInvoiceSheet.sellerGstin,
        'seller_state': NewInvoiceSheet.sellerState,
        'buyer_name': school.name,
        'buyer_gstin': school.gstin ?? '',
        'buyer_state': school.state ?? '',
        'line_items': lineItems,
        'tax_breakdown': {
          'subtotal': double.parse(subtotal.toStringAsFixed(2)),
          'igst': igst,
          'cgst': cgst,
          'sgst': sgst,
          'total_tax': totalTax,
          'grand_total': grandTotal,
          'amount_in_words': _amountInWords(grandTotal),
        },
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
        if (_termsController.text.trim().isNotEmpty) 'terms_conditions': _termsController.text.trim(),
        if (_forceCreate) 'force': true,
      };

      final repository = ref.read(schoolTenancyRepositoryProvider);
      final created = await repository.createInvoice(payload);
      ref.invalidate(invoicesProvider);
      if (mounted) {
        Navigator.pop(context, created);
      }
    } catch (e) {
      final duplicate = _extractDuplicateInvoice(e);
      if (duplicate != null) {
        setState(() => _duplicateWarning = duplicate);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invoice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Edit-mode submit — only the same safely-editable fields the real web
  /// sends are PATCHed (`NewInvoiceDrawer.tsx:394-407`); School/line items/
  /// amounts/GST are never touched once an invoice is issued.
  Future<void> _submitEdit() async {
    final invoice = widget.invoice;
    if (invoice == null) return;
    setState(() => _submitting = true);
    try {
      final repository = ref.read(schoolTenancyRepositoryProvider);
      final updated = await repository.updateInvoice(invoice.id, {
        'status': _status,
        'due_date': _isoDate(_dueDate),
        'notes': _notesController.text.trim(),
        'terms_conditions': _termsController.text.trim(),
      });
      ref.invalidate(invoicesProvider);
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Detects the backend's 409 duplicate-invoice guard
  /// (`{code: 'duplicate_invoice', existing_invoice: {...}}`,
  /// `views.py:883-900`) so the user can confirm overriding it with `force`.
  Map<String, dynamic>? _extractDuplicateInvoice(Object e) {
    try {
      final response = (e as dynamic).response;
      if (response?.statusCode == 409 && response?.data is Map) {
        final data = response.data as Map;
        if (data['code'] == 'duplicate_invoice') {
          return Map<String, dynamic>.from(data['existing_invoice'] as Map? ?? {});
        }
      }
    } catch (_) {
      // Not a DioException with the expected shape — treat as a generic error.
    }
    return null;
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Matches web's plain `${n}%` template-literal interpolation
  /// (`NewInvoiceDrawer.tsx:744-748`) — JS numbers don't print a trailing
  /// ".0" for whole values, so `18/2` renders as "9", not "9.0".
  String _trimZero(double n) => n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString();

  String _amountInWords(double amount) {
    if (amount <= 0) return 'Indian Rupees Zero Only';
    const ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
      'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    String two(int n) => n < 20 ? ones[n] : '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${ones[n % 10]}' : ''}';
    String three(int n) {
      final h = n ~/ 100;
      final r = n % 100;
      return (h != 0 ? '${ones[h]} Hundred${r != 0 ? ' ' : ''}' : '') + (r != 0 ? two(r) : '');
    }

    final n = amount.round();
    final cr = n ~/ 10000000;
    final lk = (n % 10000000) ~/ 100000;
    final th = (n % 100000) ~/ 1000;
    final rem = n % 1000;
    var words = '';
    if (cr != 0) words += '${two(cr)} Crore ';
    if (lk != 0) words += '${two(lk)} Lakh ';
    if (th != 0) words += '${two(th)} Thousand ';
    if (rem != 0) words += three(rem);
    return 'Indian Rupees ${words.trim()} Only';
  }

  Future<void> _pickDate(bool isInvoiceDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInvoiceDate ? _invoiceDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
        } else {
          _dueDate = picked;
        }
      });
      // Web's duplicate check re-runs on `[tenantId, invoiceDate]` only, not
      // `dueDate` (`NewInvoiceDrawer.tsx:251`).
      if (isInvoiceDate) _scheduleDuplicateCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsForInvoicePickerProvider);
    final plansAsync = ref.watch(plansProvider);
    final schools = schoolsAsync.value?.results ?? const <SchoolEntity>[];
    final catalog = plansAsync.value;
    final school = _selectedSchool(schools);
    final buyerState = _effectiveBuyerState(school);
    final inter = _isInterState(buyerState);
    final subtotal = _subtotal;
    final gstPercent = catalog?.gstPercent ?? 18;
    final igst = inter ? subtotal * gstPercent / 100 : 0.0;
    final cgst = !inter ? subtotal * gstPercent / 200 : 0.0;
    final sgst = !inter ? subtotal * gstPercent / 200 : 0.0;
    final grandTotal = subtotal + igst + cgst + sgst;
    final buyerCode = _stateCode(buyerState);
    final sellerCode = _stateCode(NewInvoiceSheet.sellerState);

    final invoiceDateStr = _isoDate(_invoiceDate);
    final canSubmit = _isEditMode
        ? false
        : school != null &&
            catalog != null &&
            _lines.isNotEmpty &&
            _lines.every((l) => l.description.trim().isNotEmpty && l.quantity > 0) &&
            subtotal > 0 &&
            !_submitting &&
            (_duplicateWarning == null || _forceCreate);
    final isPaidLocked = _isEditMode && widget.invoice!.status == 'paid';
    final canSubmitEdit = _isEditMode && !_submitting && !isPaidLocked && _isoDate(_dueDate).compareTo(invoiceDateStr) >= 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // HEADER — matches web's icon + "New"/"Edit Invoice" (italic
            // accent) + GST subtitle (`NewInvoiceDrawer.tsx:415-437,497-510`).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(9)),
                    child: Icon(_isEditMode ? Icons.edit_outlined : Icons.description_outlined, size: 17, color: AppColors.purpleDeep),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_isEditMode ? 'Edit ' : 'New ', style: AppTextStyles.sectionTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
                            Text('Invoice', style: AppTextStyles.pageTitleAccent.copyWith(fontSize: 19)),
                          ],
                        ),
                        Text(
                          _isEditMode
                              ? 'Invoice $_invoiceNumber · SAC ${catalog?.sacCode ?? '998313'} · GST ${gstPercent.toStringAsFixed(0)}%'
                              : 'GST-compliant tax invoice · SAC ${catalog?.sacCode ?? '998313'} · GST ${gstPercent.toStringAsFixed(0)}%',
                          style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (schoolsAsync.isLoading || plansAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: LinearProgressIndicator(),
                      ),

                    // Lock banners — matches `NewInvoiceDrawer.tsx:533-564`.
                    // Only 'paid' hard-locks submission; every other status
                    // (including 'cancelled') just shows the amber notice and
                    // stays saveable — a real, verified quirk of the web app,
                    // not something to "fix" here.
                    if (_isEditMode && widget.invoice!.status == 'paid')
                      _banner(
                        color: AppColors.dangerRed,
                        title: 'This invoice is paid and cannot be edited',
                        body: 'Paid invoices are locked to preserve the audit trail and GST compliance. '
                            'To make corrections, cancel this invoice and re-issue a new one.',
                      )
                    else if (_isEditMode)
                      _banner(
                        color: AppColors.warningAmber,
                        title: 'Editing an issued invoice',
                        body: 'School, line items, amounts and GST cannot be modified once issued. To correct '
                            'those, cancel this invoice and create a new one. You can still update status, '
                            'due date, notes and payment terms here.',
                      ),
                    if (_isEditMode) const SizedBox(height: 4),

                    // 1. BILLED TO
                    _sectionHead('1', 'Billed to'),
                    const SizedBox(height: 12),
                    Text('SCHOOL', style: _label),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _tenantId,
                      hint: const Text('Select a school…', style: TextStyle(fontSize: 13)),
                      // In edit mode the school is locked — a single
                      // synthetic item mirrors web's `disabled={isEditMode}`
                      // <select> without risking a "value doesn't match any
                      // item" crash if the real school isn't in the fetched
                      // (active-schools-only) picker list.
                      items: _isEditMode
                          ? [
                              DropdownMenuItem(
                                value: _tenantId,
                                child: Text(
                                  widget.invoice!.buyerName.isNotEmpty ? widget.invoice!.buyerName : widget.invoice!.schoolName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]
                          : schools
                              .map((s) => DropdownMenuItem(
                                    value: s.tenantId,
                                    child: Text('${s.name}${(s.state ?? '').isNotEmpty ? ' · ${s.state}' : ''}', overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                      onChanged: _isEditMode ? null : (v) => _onSchoolChanged(v, schools, catalog),
                    ),
                    const SizedBox(height: 14),

                    Text('SUBSCRIPTION PLAN', style: _label),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _planCode,
                      hint: const Text('— No plan —', style: TextStyle(fontSize: 13)),
                      // Web always resets this to blank in edit mode too
                      // (`NewInvoiceDrawer.tsx:196`) — locked, no options.
                      items: _isEditMode
                          ? const <DropdownMenuItem<String>>[]
                          : (catalog?.plans ?? const <SubscriptionPlanEntity>[])
                              .map((p) => DropdownMenuItem(value: p.code, child: Text('${p.name} · ${formatINR(p.priceInr, compact: false, fraction: 0)}/${p.billingCycle == 'monthly' ? 'mo' : 'yr'}')))
                              .toList(),
                      onChanged: _isEditMode || catalog == null
                          ? null
                          : (v) => setState(() {
                                _planCode = v;
                                final p = _selectedPlan(catalog);
                                if (p != null) _applyPlanToFirstLine(p, catalog);
                              }),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      school != null
                          ? 'Current subscription: ${school.plan.isEmpty ? '—' : school.plan[0].toUpperCase() + school.plan.substring(1)} (auto-selected; override if needed)'
                          : 'Pick a school first to auto-select its plan',
                      style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
                    ),
                    const SizedBox(height: 14),

                    Text('GSTIN', style: _label),
                    const SizedBox(height: 6),
                    _readonlyField(_effectiveGstin(school), placeholder: 'Auto from school', mono: true),
                    const SizedBox(height: 14),

                    Text('STATE', style: _label),
                    const SizedBox(height: 6),
                    _readonlyField(buyerState, placeholder: 'Auto from school'),
                    const SizedBox(height: 3),
                    Text(
                      buyerCode.isNotEmpty ? 'State code $buyerCode' : 'Selected school\'s state',
                      style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5),
                    ),

                    // Duplicate invoice warning banner — matches
                    // `NewInvoiceDrawer.tsx:518-559`.
                    if (_duplicateWarning != null) ...[
                      const SizedBox(height: 16),
                      _duplicateBanner(),
                    ],

                    const SizedBox(height: 20),
                    // 2. INVOICE DETAILS
                    _sectionHead('2', 'Invoice details'),
                    const SizedBox(height: 12),
                    Text('INVOICE NO. · AUTO-GENERATED', style: _label),
                    const SizedBox(height: 6),
                    _readonlyField(_invoiceNumber, mono: true),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        // Invoice date is locked in edit mode
                        // (`readOnly={isEditMode}`, `NewInvoiceDrawer.tsx:708`).
                        Expanded(child: _buildDateField('INVOICE DATE', _invoiceDate, _isEditMode ? null : () => _pickDate(true))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDateField('DUE DATE', _dueDate, () => _pickDate(false))),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text('STATUS', style: _label),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _status,
                      // Matches web's exact conditional option list
                      // (`NewInvoiceDrawer.tsx:732-737`) — Paid/Overdue/
                      // Cancelled only show up once editing an existing
                      // invoice. 'Partially Paid' is added defensively (not
                      // in the web list) since it's a real live status and
                      // Flutter's DropdownButton crashes outright on a value
                      // with no matching item, unlike an HTML <select>.
                      items: [
                        const DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        const DropdownMenuItem(value: 'sent', child: Text('Sent')),
                        if (_isEditMode) const DropdownMenuItem(value: 'partially_paid', child: Text('Partially Paid')),
                        if (_isEditMode) const DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        if (_isEditMode) const DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                        if (_isEditMode) const DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'draft'),
                    ),
                    const SizedBox(height: 14),

                    Text('REVERSE CHARGE', style: _label),
                    const SizedBox(height: 6),
                    AppDropdown<bool>(
                      value: _reverseCharge,
                      items: const [
                        DropdownMenuItem(value: false, child: Text('No')),
                        DropdownMenuItem(value: true, child: Text('Yes')),
                      ],
                      onChanged: (v) => setState(() => _reverseCharge = v ?? false),
                    ),
                    const SizedBox(height: 14),

                    Text('CURRENCY', style: _label),
                    const SizedBox(height: 6),
                    _readonlyField('INR'),

                    const SizedBox(height: 20),
                    // 3. LINE ITEMS — "Add line" only in create mode; rows
                    // are locked in edit mode (`NewInvoiceDrawer.tsx:757-851`).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionHead('3', 'Line items'),
                        if (!_isEditMode)
                          TextButton.icon(
                            onPressed: () => setState(() => _lines.add(_LineDraft(sacCode: catalog?.sacCode ?? '998313'))),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add line'),
                          ),
                      ],
                    ),
                    _lineItemsHeader(),
                    ..._lines.asMap().entries.map((entry) => _buildLineEditor(entry.key, entry.value, readOnly: _isEditMode)),

                    const SizedBox(height: 20),
                    // 4. NOTES & TERMS
                    _sectionHead('4', 'Notes & terms'),
                    const SizedBox(height: 12),
                    Text('NOTES', style: _label),
                    const SizedBox(height: 3),
                    Text('Internal or buyer-visible note', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: _fieldDecoration().copyWith(hintText: 'Any additional notes…'),
                    ),
                    const SizedBox(height: 14),

                    Text('PAYMENT TERMS', style: _label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _termsController,
                      maxLines: 3,
                      decoration: _fieldDecoration(),
                    ),

                    const SizedBox(height: 20),
                    // TAX SUMMARY — matches `NewInvoiceDrawer.tsx:736-755`.
                    Text('TAX SUMMARY', style: _label),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        border: Border.all(color: AppColors.borderPrimary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _totalsRow('Subtotal', subtotal),
                          _totalsRow('Discount', 0, muted: true),
                          _totalsRow('Taxable value', subtotal),
                          if (inter) _totalsRow('IGST · ${_trimZero(gstPercent)}%', igst, accent: true),
                          if (!inter) _totalsRow('CGST · ${_trimZero(gstPercent / 2)}%', cgst, accent: true),
                          if (!inter) _totalsRow('SGST · ${_trimZero(gstPercent / 2)}%', sgst, accent: true),
                          const Divider(),
                          _totalsRow('Total payable', grandTotal, bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _amountInWords(grandTotal),
                      style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                    ),

                    const SizedBox(height: 16),
                    // TAX LOGIC APPLIED — matches `NewInvoiceDrawer.tsx:757-788`.
                    Text('TAX LOGIC APPLIED', style: _label),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        border: Border.all(color: AppColors.borderPrimary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _logicRow('Seller state', '${sellerCode.isNotEmpty ? '$sellerCode ' : ''}${NewInvoiceSheet.sellerState}'),
                          _logicRow('Buyer state', '${buyerCode.isNotEmpty ? '$buyerCode ' : ''}${buyerState.isNotEmpty ? buyerState : '—'}'),
                          _logicRow('Supply type', inter ? 'Inter-state' : 'Intra-state'),
                          _logicRow('Applied', inter ? 'IGST' : 'CGST + SGST', accent: true),
                          _logicRow('Reverse charge', _reverseCharge ? 'Yes' : 'No'),
                          _logicRow('SAC', '${catalog?.sacCode ?? '998313'} — ${catalog?.sacDescription ?? 'Education software'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // FOOTER — total payable + save action(s). Edit mode collapses
            // to a single "Save changes" (plus Cancel) instead of the
            // draft/send pair, matching `NewInvoiceDrawer.tsx:937-981`.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderPrimary)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 12.5),
                      children: [
                        const TextSpan(text: 'Total payable  '),
                        TextSpan(
                          text: formatINR(grandTotal, compact: false),
                          style: AppTextStyles.boardCount.copyWith(fontSize: 18, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isEditMode)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canSubmitEdit ? _submitEdit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                            child: Text(_submitting ? 'Saving…' : 'Save changes'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: canSubmit ? () => _submit('draft', schools, catalog) : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                            child: Text(_submitting && _submittingStatus == 'draft' ? 'Saving…' : 'Save as draft'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canSubmit ? () => _submit('sent', schools, catalog) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                            child: Text(_submitting && _submittingStatus == 'sent' ? 'Sending…' : 'Save & send'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle get _label => AppTextStyles.sectionSubtitle.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6);

  /// Matches web's `SectionHead` (`NewInvoiceDrawer.tsx:118-127`) — a small
  /// numbered badge next to the section title.
  Widget _sectionHead(String num, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(6)),
          child: Text(num, style: AppTextStyles.chipLabel(color: AppColors.purpleDeep).copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
      ],
    );
  }

  /// Matches web's paid/amber lock notices (`NewInvoiceDrawer.tsx:533-564`).
  Widget _banner({required Color color, required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: AppTextStyles.boardLabel.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }

  Widget _readonlyField(String value, {String placeholder = '—', bool mono = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.isEmpty ? placeholder : value,
        style: AppTextStyles.boardLabel.copyWith(
          fontSize: 13,
          fontFamily: mono ? 'monospace' : null,
          color: value.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _duplicateBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        border: Border.all(color: AppColors.warningAmber),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warningAmber),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.boardLabel.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    children: [
                      const TextSpan(text: 'Duplicate detected — invoice '),
                      TextSpan(text: '${_duplicateWarning!['invoice_number'] ?? ''}', style: const TextStyle(fontFamily: 'monospace')),
                      const TextSpan(text: ' already exists for this school in this billing month ('),
                      TextSpan(text: '${_duplicateWarning!['status'] ?? ''}'),
                      const TextSpan(text: ').'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Best practice: void or cancel the existing invoice before generating a new one. '
            'If this is intentional (e.g. a correction or multi-license), confirm below.',
            style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, color: const Color(0xFF92400E)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!_forceCreate)
                OutlinedButton(
                  onPressed: () => setState(() => _forceCreate = true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.amberSoft,
                    side: const BorderSide(color: AppColors.warningAmber),
                    foregroundColor: const Color(0xFF92400E),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: const Text('I understand — create anyway', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.warningAmber, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Override confirmed', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                    ],
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _duplicateWarning = null;
                  _forceCreate = false;
                }),
                child: const Text('Dismiss', style: TextStyle(fontSize: 11.5, decoration: TextDecoration.underline, color: Color(0xFF92400E))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.bgSecondary,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderPrimary)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildDateField(String label, DateTime value, VoidCallback? onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: onTap == null ? AppColors.bgTertiary : AppColors.bgSecondary,
              border: Border.all(color: AppColors.borderPrimary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_isoDate(value), style: AppTextStyles.boardLabel.copyWith(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  /// Column headings for the line-item cards below — matches web's real
  /// `<thead>` labels exactly (`NewInvoiceDrawer.tsx`: Description / SAC /
  /// Qty / Rate (₹) / Amount (₹)), laid out with the same flex ratios as
  /// `_buildLineEditor`'s SAC/Qty/Rate row so the columns line up.
  Widget _lineItemsHeader() {
    final style = AppTextStyles.sectionSubtitle.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESCRIPTION', style: style),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(flex: 3, child: Text('SAC', style: style)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: Text('QTY', style: style)),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: Text('RATE (₹)', style: style)),
            ],
          ),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: Text('AMOUNT (₹)', style: style)),
        ],
      ),
    );
  }

  Widget _buildLineEditor(int index, _LineDraft line, {bool readOnly = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('desc_$index'),
                  initialValue: line.description,
                  enabled: !readOnly,
                  decoration: _fieldDecoration().copyWith(hintText: 'e.g. Eskoolia ERP — Premium plan'),
                  onChanged: (v) => setState(() {
                    line.description = v;
                    if (index == 0) _scheduleDuplicateCheck();
                  }),
                ),
              ),
              if (!readOnly && _lines.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => setState(() => _lines.removeAt(index)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('sac_$index'),
                  initialValue: line.sacCode,
                  enabled: !readOnly,
                  decoration: _fieldDecoration().copyWith(hintText: 'SAC'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                  onChanged: (v) => setState(() => line.sacCode = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: ValueKey('qty_$index'),
                  initialValue: line.quantity.toString(),
                  enabled: !readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _fieldDecoration().copyWith(hintText: 'Qty'),
                  onChanged: (v) => setState(() => line.quantity = int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('price_$index'),
                  initialValue: line.unitPrice.toString(),
                  enabled: !readOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration().copyWith(hintText: 'Rate (₹)'),
                  onChanged: (v) => setState(() => line.unitPrice = double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              // Web's amount cell has no ₹ symbol, just the formatted number
              // (`NewInvoiceDrawer.tsx:687-689`).
              formatINR(line.amount, compact: false, symbol: false),
              style: AppTextStyles.boardLabel.copyWith(fontSize: 12.5, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsRow(String label, double value, {bool bold = false, bool accent = false, bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.sectionSubtitle.copyWith(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: muted ? AppColors.textTertiary : AppColors.textSecondary,
            ),
          ),
          Text(
            formatINR(value, compact: false),
            style: AppTextStyles.boardLabel.copyWith(
              fontSize: bold ? 14 : 12,
              fontFamily: bold ? null : 'monospace',
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: accent ? AppColors.purpleDeep : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logicRow(String label, String value, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 12)),
          Text(
            value,
            style: AppTextStyles.boardLabel.copyWith(
              fontSize: 11.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: accent ? AppColors.purpleDeep : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
