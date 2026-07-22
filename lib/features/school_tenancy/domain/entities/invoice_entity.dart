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

class BillingMrrEntity {
  final double currentMrr;
  final double previousMrr;
  final double gstCollected;
  final double outstandingAmount;
  final double atRiskAmount;
  final double trendPercent;

  const BillingMrrEntity({
    required this.currentMrr,
    required this.previousMrr,
    required this.gstCollected,
    required this.outstandingAmount,
    required this.atRiskAmount,
    required this.trendPercent,
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
