// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceReminderResultDto _$InvoiceReminderResultDtoFromJson(
  Map<String, dynamic> json,
) => InvoiceReminderResultDto(
  invoiceNumber: json['invoice_number'] as String,
  status: json['status'] as String,
  reminderRecorded: json['reminder_recorded'] as bool,
);

Map<String, dynamic> _$InvoiceReminderResultDtoToJson(
  InvoiceReminderResultDto instance,
) => <String, dynamic>{
  'invoice_number': instance.invoiceNumber,
  'status': instance.status,
  'reminder_recorded': instance.reminderRecorded,
};

InvoicePaymentDto _$InvoicePaymentDtoFromJson(Map<String, dynamic> json) =>
    InvoicePaymentDto(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidOn: json['paid_on'] as String,
      method: json['method'] as String,
      referenceNo: json['reference_no'] as String?,
      notes: json['notes'] as String?,
      receivedByUsername: json['received_by_username'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$InvoicePaymentDtoToJson(InvoicePaymentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'paid_on': instance.paidOn,
      'method': instance.method,
      'reference_no': instance.referenceNo,
      'notes': instance.notes,
      'received_by_username': instance.receivedByUsername,
      'created_at': instance.createdAt,
    };

RecordPaymentResultDto _$RecordPaymentResultDtoFromJson(
  Map<String, dynamic> json,
) => RecordPaymentResultDto(
  payment: InvoicePaymentDto.fromJson(json['payment'] as Map<String, dynamic>),
  invoice: InvoiceDto.fromJson(json['invoice'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RecordPaymentResultDtoToJson(
  RecordPaymentResultDto instance,
) => <String, dynamic>{
  'payment': instance.payment,
  'invoice': instance.invoice,
};

InvoiceLineItemDto _$InvoiceLineItemDtoFromJson(Map<String, dynamic> json) =>
    InvoiceLineItemDto(
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      sacCode: json['sac_code'] as String,
      amount: (json['amount'] as num).toDouble(),
      gstPercent: (json['gst_percent'] as num?)?.toDouble(),
      gstAmount: (json['gst_amount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$InvoiceLineItemDtoToJson(InvoiceLineItemDto instance) =>
    <String, dynamic>{
      'description': instance.description,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'sac_code': instance.sacCode,
      'amount': instance.amount,
      'gst_percent': instance.gstPercent,
      'gst_amount': instance.gstAmount,
    };

TaxBreakdownDto _$TaxBreakdownDtoFromJson(Map<String, dynamic> json) =>
    TaxBreakdownDto(
      subtotal: (json['subtotal'] as num).toDouble(),
      igst: (json['igst'] as num?)?.toDouble(),
      cgst: (json['cgst'] as num?)?.toDouble(),
      sgst: (json['sgst'] as num?)?.toDouble(),
      totalTax: (json['total_tax'] as num).toDouble(),
      grandTotal: (json['grand_total'] as num).toDouble(),
      amountInWords: json['amount_in_words'] as String,
    );

Map<String, dynamic> _$TaxBreakdownDtoToJson(TaxBreakdownDto instance) =>
    <String, dynamic>{
      'subtotal': instance.subtotal,
      'igst': instance.igst,
      'cgst': instance.cgst,
      'sgst': instance.sgst,
      'total_tax': instance.totalTax,
      'grand_total': instance.grandTotal,
      'amount_in_words': instance.amountInWords,
    };

InvoiceDto _$InvoiceDtoFromJson(Map<String, dynamic> json) => InvoiceDto(
  id: json['id'] as String,
  invoiceNumber: json['invoice_number'] as String,
  schoolName: json['school_name'] as String,
  tenantId: json['tenant_id'] as String?,
  invoiceDate: json['invoice_date'] as String,
  dueDate: json['due_date'] as String,
  status: json['status'] as String,
  sellerName: json['seller_name'] as String,
  sellerGstin: json['seller_gstin'] as String?,
  sellerState: json['seller_state'] as String,
  buyerName: json['buyer_name'] as String,
  buyerGstin: json['buyer_gstin'] as String?,
  buyerState: json['buyer_state'] as String,
  lineItems: (json['line_items'] as List<dynamic>)
      .map((e) => InvoiceLineItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  taxBreakdown: TaxBreakdownDto.fromJson(
    json['tax_breakdown'] as Map<String, dynamic>,
  ),
  notes: json['notes'] as String?,
  termsConditions: json['terms_conditions'] as String?,
  reverseCharge: json['reverse_charge'] as bool? ?? false,
  paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
  dueAmount: (json['due_amount'] as num?)?.toDouble() ?? 0.0,
  lastPaymentOn: json['last_payment_on'] as String?,
  payments:
      (json['payments'] as List<dynamic>?)
          ?.map((e) => InvoicePaymentDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$InvoiceDtoToJson(InvoiceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice_number': instance.invoiceNumber,
      'school_name': instance.schoolName,
      'tenant_id': instance.tenantId,
      'invoice_date': instance.invoiceDate,
      'due_date': instance.dueDate,
      'status': instance.status,
      'seller_name': instance.sellerName,
      'seller_gstin': instance.sellerGstin,
      'seller_state': instance.sellerState,
      'buyer_name': instance.buyerName,
      'buyer_gstin': instance.buyerGstin,
      'buyer_state': instance.buyerState,
      'line_items': instance.lineItems,
      'tax_breakdown': instance.taxBreakdown,
      'notes': instance.notes,
      'terms_conditions': instance.termsConditions,
      'reverse_charge': instance.reverseCharge,
      'paid_amount': instance.paidAmount,
      'due_amount': instance.dueAmount,
      'last_payment_on': instance.lastPaymentOn,
      'payments': instance.payments,
    };

PaginatedInvoicesDto _$PaginatedInvoicesDtoFromJson(
  Map<String, dynamic> json,
) => PaginatedInvoicesDto(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => InvoiceDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedInvoicesDtoToJson(
  PaginatedInvoicesDto instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};

SubscriptionPlanDto _$SubscriptionPlanDtoFromJson(Map<String, dynamic> json) =>
    SubscriptionPlanDto(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      priceInr: (json['price_inr'] as num).toDouble(),
      billingCycle: json['billing_cycle'] as String,
      popular: json['popular'] as bool,
      features: (json['features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SubscriptionPlanDtoToJson(
  SubscriptionPlanDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'price_inr': instance.priceInr,
  'billing_cycle': instance.billingCycle,
  'popular': instance.popular,
  'features': instance.features,
  'sort_order': instance.sortOrder,
};

PlansCatalogDto _$PlansCatalogDtoFromJson(Map<String, dynamic> json) =>
    PlansCatalogDto(
      plans: (json['plans'] as List<dynamic>)
          .map((e) => SubscriptionPlanDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      gstPercent: (json['gst_percent'] as num).toDouble(),
      sacCode: json['sac_code'] as String,
      sacDescription: json['sac_description'] as String,
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$PlansCatalogDtoToJson(PlansCatalogDto instance) =>
    <String, dynamic>{
      'plans': instance.plans,
      'gst_percent': instance.gstPercent,
      'sac_code': instance.sacCode,
      'sac_description': instance.sacDescription,
      'currency': instance.currency,
    };

BillingMrrDto _$BillingMrrDtoFromJson(Map<String, dynamic> json) =>
    BillingMrrDto(
      currentMrr: (json['current_mrr'] as num).toDouble(),
      previousMrr: (json['previous_mrr'] as num).toDouble(),
      gstCollected: (json['gst_collected'] as num).toDouble(),
      outstandingAmount: (json['outstanding_amount'] as num).toDouble(),
      atRiskAmount: (json['at_risk_amount'] as num).toDouble(),
      trendPercent: (json['trend_percent'] as num).toDouble(),
      gstIgst: (json['gst_igst'] as num?)?.toDouble() ?? 0.0,
      gstCgstSgst: (json['gst_cgst_sgst'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$BillingMrrDtoToJson(BillingMrrDto instance) =>
    <String, dynamic>{
      'current_mrr': instance.currentMrr,
      'previous_mrr': instance.previousMrr,
      'gst_collected': instance.gstCollected,
      'outstanding_amount': instance.outstandingAmount,
      'at_risk_amount': instance.atRiskAmount,
      'trend_percent': instance.trendPercent,
      'gst_igst': instance.gstIgst,
      'gst_cgst_sgst': instance.gstCgstSgst,
    };
