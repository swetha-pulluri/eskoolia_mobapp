/// Invoice Entity
class InvoiceEntity {
  final String id;
  final String invoiceNumber;
  final String schoolName;
  final String tenantId;
  final String invoiceDate;
  final String dueDate;
  final String status;
  final String sellerName;
  final String sellerGstin;
  final String sellerState;
  final String buyerName;
  final String buyerGstin;
  final String buyerState;
  final List<InvoiceLineItemEntity> lineItems;
  final TaxBreakdownEntity taxBreakdown;
  final String? notes;
  final String? termsConditions;
  final bool reverseCharge;
  final double paidAmount;
  final double dueAmount;
  final String? lastPaymentOn;
  final List<InvoicePaymentEntity> payments;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.schoolName,
    required this.tenantId,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    required this.sellerName,
    required this.sellerGstin,
    required this.sellerState,
    required this.buyerName,
    required this.buyerGstin,
    required this.buyerState,
    required this.lineItems,
    required this.taxBreakdown,
    this.notes,
    this.termsConditions,
    this.reverseCharge = false,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.lastPaymentOn,
    this.payments = const [],
  });
}

/// Payment-ledger entry against an invoice — mirrors `SuperAdminInvoicePayment`
/// (`InvoicePaymentSerializer`). Enables partial payments and an auditable
/// payment history per invoice.
class InvoicePaymentEntity {
  final String id;
  final double amount;
  final String paidOn;
  final String method;
  final String? referenceNo;
  final String? notes;
  final String? receivedByUsername;
  final String? createdAt;

  const InvoicePaymentEntity({
    required this.id,
    required this.amount,
    required this.paidOn,
    required this.method,
    this.referenceNo,
    this.notes,
    this.receivedByUsername,
    this.createdAt,
  });
}

/// Response shape of `POST /billing/invoices/{id}/payments/` —
/// `{payment: {...}, invoice: {...}}` (`BillingInvoicePaymentsView.post`).
class RecordPaymentResultEntity {
  final InvoicePaymentEntity payment;
  final InvoiceEntity invoice;

  const RecordPaymentResultEntity({
    required this.payment,
    required this.invoice,
  });
}

class InvoiceLineItemEntity {
  final String description;
  final int quantity;
  final double unitPrice;
  final String sacCode;
  final double amount;
  final double? gstPercent;
  final double? gstAmount;

  const InvoiceLineItemEntity({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.sacCode,
    required this.amount,
    this.gstPercent,
    this.gstAmount,
  });
}

class TaxBreakdownEntity {
  final double subtotal;
  final double? igst;
  final double? cgst;
  final double? sgst;
  final double totalTax;
  final double grandTotal;
  final String amountInWords;

  const TaxBreakdownEntity({
    required this.subtotal,
    this.igst,
    this.cgst,
    this.sgst,
    required this.totalTax,
    required this.grandTotal,
    required this.amountInWords,
  });
}

/// Response shape of `POST /billing/invoices/{id}/reminder/` — a small
/// envelope, not a full invoice (`views.py` `BillingInvoiceReminderView`).
class InvoiceReminderResultEntity {
  final String invoiceNumber;
  final String status;
  final bool reminderRecorded;

  const InvoiceReminderResultEntity({
    required this.invoiceNumber,
    required this.status,
    required this.reminderRecorded,
  });
}

class BillingMrrEntity {
  final double currentMrr;
  final double previousMrr;
  final double gstCollected;
  final double outstandingAmount;
  final double atRiskAmount;
  final double trendPercent;
  final double gstIgst;
  final double gstCgstSgst;

  const BillingMrrEntity({
    required this.currentMrr,
    required this.previousMrr,
    required this.gstCollected,
    required this.outstandingAmount,
    required this.atRiskAmount,
    required this.trendPercent,
    this.gstIgst = 0,
    this.gstCgstSgst = 0,
  });
}

class SubscriptionPlanEntity {
  final String code;
  final String name;
  final String description;
  final double priceInr;
  final String billingCycle;
  final bool popular;
  final List<String> features;
  final int sortOrder;

  const SubscriptionPlanEntity({
    required this.code,
    required this.name,
    required this.description,
    required this.priceInr,
    required this.billingCycle,
    required this.popular,
    required this.features,
    this.sortOrder = 0,
  });
}

class PlansCatalogEntity {
  final List<SubscriptionPlanEntity> plans;
  final double gstPercent;
  final String sacCode;
  final String sacDescription;
  final String currency;

  const PlansCatalogEntity({
    required this.plans,
    required this.gstPercent,
    required this.sacCode,
    required this.sacDescription,
    required this.currency,
  });
}

/// Paginated Invoices
class PaginatedInvoicesEntity {
  final int count;
  final String? next;
  final String? previous;
  final List<InvoiceEntity> results;

  const PaginatedInvoicesEntity({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
