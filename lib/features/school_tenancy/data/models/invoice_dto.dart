import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/invoice_entity.dart';

part 'invoice_dto.g.dart';

@JsonSerializable()
class InvoiceReminderResultDto {
  @JsonKey(name: 'invoice_number')
  final String invoiceNumber;

  final String status;

  @JsonKey(name: 'reminder_recorded')
  final bool reminderRecorded;

  InvoiceReminderResultDto({
    required this.invoiceNumber,
    required this.status,
    required this.reminderRecorded,
  });

  factory InvoiceReminderResultDto.fromJson(Map<String, dynamic> json) => _$InvoiceReminderResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceReminderResultDtoToJson(this);

  InvoiceReminderResultEntity toEntity() {
    return InvoiceReminderResultEntity(
      invoiceNumber: invoiceNumber,
      status: status,
      reminderRecorded: reminderRecorded,
    );
  }
}

@JsonSerializable()
class InvoicePaymentDto {
  final String id;
  final double amount;

  @JsonKey(name: 'paid_on')
  final String paidOn;

  final String method;

  @JsonKey(name: 'reference_no')
  final String? referenceNo;

  final String? notes;

  @JsonKey(name: 'received_by_username')
  final String? receivedByUsername;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  InvoicePaymentDto({
    required this.id,
    required this.amount,
    required this.paidOn,
    required this.method,
    this.referenceNo,
    this.notes,
    this.receivedByUsername,
    this.createdAt,
  });

  factory InvoicePaymentDto.fromJson(Map<String, dynamic> json) => _$InvoicePaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoicePaymentDtoToJson(this);

  InvoicePaymentEntity toEntity() {
    return InvoicePaymentEntity(
      id: id,
      amount: amount,
      paidOn: paidOn,
      method: method,
      referenceNo: referenceNo,
      notes: notes,
      receivedByUsername: receivedByUsername,
      createdAt: createdAt,
    );
  }
}

/// Response shape of `POST /billing/invoices/{id}/payments/` —
/// `{payment: {...}, invoice: {...}}`.
@JsonSerializable()
class RecordPaymentResultDto {
  final InvoicePaymentDto payment;
  final InvoiceDto invoice;

  RecordPaymentResultDto({required this.payment, required this.invoice});

  factory RecordPaymentResultDto.fromJson(Map<String, dynamic> json) => _$RecordPaymentResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecordPaymentResultDtoToJson(this);

  RecordPaymentResultEntity toEntity() {
    return RecordPaymentResultEntity(payment: payment.toEntity(), invoice: invoice.toEntity());
  }
}

@JsonSerializable()
class InvoiceLineItemDto {
  final String description;
  final int quantity;

  @JsonKey(name: 'unit_price')
  final double unitPrice;

  @JsonKey(name: 'sac_code')
  final String sacCode;

  final double amount;

  @JsonKey(name: 'gst_percent')
  final double? gstPercent;

  @JsonKey(name: 'gst_amount')
  final double? gstAmount;

  InvoiceLineItemDto({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.sacCode,
    required this.amount,
    this.gstPercent,
    this.gstAmount,
  });

  factory InvoiceLineItemDto.fromJson(Map<String, dynamic> json) => _$InvoiceLineItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceLineItemDtoToJson(this);

  InvoiceLineItemEntity toEntity() {
    return InvoiceLineItemEntity(
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      sacCode: sacCode,
      amount: amount,
      gstPercent: gstPercent,
      gstAmount: gstAmount,
    );
  }
}

@JsonSerializable()
class TaxBreakdownDto {
  final double subtotal;
  final double? igst;
  final double? cgst;
  final double? sgst;

  @JsonKey(name: 'total_tax')
  final double totalTax;

  @JsonKey(name: 'grand_total')
  final double grandTotal;

  @JsonKey(name: 'amount_in_words')
  final String amountInWords;

  TaxBreakdownDto({
    required this.subtotal,
    this.igst,
    this.cgst,
    this.sgst,
    required this.totalTax,
    required this.grandTotal,
    required this.amountInWords,
  });

  factory TaxBreakdownDto.fromJson(Map<String, dynamic> json) => _$TaxBreakdownDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TaxBreakdownDtoToJson(this);

  TaxBreakdownEntity toEntity() {
    return TaxBreakdownEntity(
      subtotal: subtotal,
      igst: igst,
      cgst: cgst,
      sgst: sgst,
      totalTax: totalTax,
      grandTotal: grandTotal,
      amountInWords: amountInWords,
    );
  }
}

@JsonSerializable()
class InvoiceDto {
  final String id;

  @JsonKey(name: 'invoice_number')
  final String invoiceNumber;

  @JsonKey(name: 'school_name')
  final String schoolName;

  @JsonKey(name: 'tenant_id')
  final String? tenantId;

  @JsonKey(name: 'invoice_date')
  final String invoiceDate;

  @JsonKey(name: 'due_date')
  final String dueDate;

  final String status;

  @JsonKey(name: 'seller_name')
  final String sellerName;

  @JsonKey(name: 'seller_gstin')
  final String? sellerGstin;

  @JsonKey(name: 'seller_state')
  final String sellerState;

  @JsonKey(name: 'buyer_name')
  final String buyerName;

  @JsonKey(name: 'buyer_gstin')
  final String? buyerGstin;

  @JsonKey(name: 'buyer_state')
  final String buyerState;

  @JsonKey(name: 'line_items')
  final List<InvoiceLineItemDto> lineItems;

  @JsonKey(name: 'tax_breakdown')
  final TaxBreakdownDto taxBreakdown;

  final String? notes;

  @JsonKey(name: 'terms_conditions')
  final String? termsConditions;

  @JsonKey(name: 'reverse_charge', defaultValue: false)
  final bool reverseCharge;

  @JsonKey(name: 'paid_amount', defaultValue: 0.0)
  final double paidAmount;

  @JsonKey(name: 'due_amount', defaultValue: 0.0)
  final double dueAmount;

  @JsonKey(name: 'last_payment_on')
  final String? lastPaymentOn;

  @JsonKey(defaultValue: [])
  final List<InvoicePaymentDto> payments;

  InvoiceDto({
    required this.id,
    required this.invoiceNumber,
    required this.schoolName,
    this.tenantId,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    required this.sellerName,
    this.sellerGstin,
    required this.sellerState,
    required this.buyerName,
    this.buyerGstin,
    required this.buyerState,
    required this.lineItems,
    required this.taxBreakdown,
    this.notes,
    this.termsConditions,
    this.reverseCharge = false,
    this.paidAmount = 0.0,
    this.dueAmount = 0.0,
    this.lastPaymentOn,
    this.payments = const <InvoicePaymentDto>[],
  });

  factory InvoiceDto.fromJson(Map<String, dynamic> json) => _$InvoiceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InvoiceDtoToJson(this);

  InvoiceEntity toEntity() {
    return InvoiceEntity(
      id: id,
      invoiceNumber: invoiceNumber,
      schoolName: schoolName,
      tenantId: tenantId ?? '',
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      status: status,
      sellerName: sellerName,
      sellerGstin: sellerGstin ?? '',
      sellerState: sellerState,
      buyerName: buyerName,
      buyerGstin: buyerGstin ?? '',
      buyerState: buyerState,
      lineItems: lineItems.map((e) => e.toEntity()).toList(),
      taxBreakdown: taxBreakdown.toEntity(),
      notes: notes,
      termsConditions: termsConditions,
      reverseCharge: reverseCharge,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      lastPaymentOn: lastPaymentOn,
      payments: payments.map((e) => e.toEntity()).toList(),
    );
  }
}

@JsonSerializable()
class PaginatedInvoicesDto {
  final int count;
  final String? next;
  final String? previous;
  final List<InvoiceDto> results;

  PaginatedInvoicesDto({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedInvoicesDto.fromJson(Map<String, dynamic> json) => _$PaginatedInvoicesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedInvoicesDtoToJson(this);

  PaginatedInvoicesEntity toEntity() {
    return PaginatedInvoicesEntity(
      count: count,
      next: next,
      previous: previous,
      results: results.map((e) => e.toEntity()).toList(),
    );
  }
}

@JsonSerializable()
class SubscriptionPlanDto {
  final String code;
  final String name;
  final String description;

  @JsonKey(name: 'price_inr')
  final double priceInr;

  @JsonKey(name: 'billing_cycle')
  final String billingCycle;

  final bool popular;
  final List<String> features;

  @JsonKey(name: 'sort_order', defaultValue: 0)
  final int sortOrder;

  SubscriptionPlanDto({
    required this.code,
    required this.name,
    required this.description,
    required this.priceInr,
    required this.billingCycle,
    required this.popular,
    required this.features,
    this.sortOrder = 0,
  });

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanDtoToJson(this);

  SubscriptionPlanEntity toEntity() {
    return SubscriptionPlanEntity(
      code: code,
      name: name,
      description: description,
      priceInr: priceInr,
      billingCycle: billingCycle,
      popular: popular,
      features: features,
      sortOrder: sortOrder,
    );
  }
}

@JsonSerializable()
class PlansCatalogDto {
  final List<SubscriptionPlanDto> plans;

  @JsonKey(name: 'gst_percent')
  final double gstPercent;

  @JsonKey(name: 'sac_code')
  final String sacCode;

  @JsonKey(name: 'sac_description')
  final String sacDescription;

  final String currency;

  PlansCatalogDto({
    required this.plans,
    required this.gstPercent,
    required this.sacCode,
    required this.sacDescription,
    required this.currency,
  });

  factory PlansCatalogDto.fromJson(Map<String, dynamic> json) => _$PlansCatalogDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlansCatalogDtoToJson(this);

  PlansCatalogEntity toEntity() {
    return PlansCatalogEntity(
      plans: plans.map((e) => e.toEntity()).toList(),
      gstPercent: gstPercent,
      sacCode: sacCode,
      sacDescription: sacDescription,
      currency: currency,
    );
  }
}

@JsonSerializable()
class BillingMrrDto {
  @JsonKey(name: 'current_mrr')
  final double currentMrr;

  @JsonKey(name: 'previous_mrr')
  final double previousMrr;

  @JsonKey(name: 'gst_collected')
  final double gstCollected;

  @JsonKey(name: 'outstanding_amount')
  final double outstandingAmount;

  @JsonKey(name: 'at_risk_amount')
  final double atRiskAmount;

  @JsonKey(name: 'trend_percent')
  final double trendPercent;

  @JsonKey(name: 'gst_igst', defaultValue: 0.0)
  final double gstIgst;

  @JsonKey(name: 'gst_cgst_sgst', defaultValue: 0.0)
  final double gstCgstSgst;

  BillingMrrDto({
    required this.currentMrr,
    required this.previousMrr,
    required this.gstCollected,
    required this.outstandingAmount,
    required this.atRiskAmount,
    required this.trendPercent,
    this.gstIgst = 0.0,
    this.gstCgstSgst = 0.0,
  });

  factory BillingMrrDto.fromJson(Map<String, dynamic> json) => _$BillingMrrDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BillingMrrDtoToJson(this);

  BillingMrrEntity toEntity() {
    return BillingMrrEntity(
      currentMrr: currentMrr,
      previousMrr: previousMrr,
      gstCollected: gstCollected,
      outstandingAmount: outstandingAmount,
      atRiskAmount: atRiskAmount,
      trendPercent: trendPercent,
      gstIgst: gstIgst,
      gstCgstSgst: gstCgstSgst,
    );
  }
}
