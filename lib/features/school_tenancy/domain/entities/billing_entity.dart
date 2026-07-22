/// Billing Entity for Super Admin Billing Module
/// UI-only entity with local sample data

class BillingStateEntity {
  final List<InvoiceEntity> invoices;

  const BillingStateEntity({
    required this.invoices,
  });
}

class InvoiceEntity {
  final String invoiceNumber;
  final String schoolName;
  final double amount;
  final String status;
  final DateTime? dueDate;

  const InvoiceEntity({
    required this.invoiceNumber,
    required this.schoolName,
    required this.amount,
    required this.status,
    this.dueDate,
  });
}
