/// Billing entities for the Super Admin Billing module (UI-only, local sample data).
class BillingStateEntity {
  final List<InvoiceEntity> invoices;
  final List<SubscriptionPlanEntity> plans;

  const BillingStateEntity({
    required this.invoices,
    this.plans = const [],
  });
}

class InvoiceEntity {
  final String invoiceNumber;
  final String schoolName;
  final double amount;
  final String status;
  final DateTime? dueDate;
  final DateTime? issuedDate;
  final String? gstin;
  final String? buyerState;

  const InvoiceEntity({
    required this.invoiceNumber,
    required this.schoolName,
    required this.amount,
    required this.status,
    this.dueDate,
    this.issuedDate,
    this.gstin,
    this.buyerState,
  });
}

/// Subscription plan catalog entry
/// Matches the plan list exposed in the web "Add school" plan dropdown
/// (schools/page.tsx) and the Billing "Subscription plans" section.
class SubscriptionPlanEntity {
  final String code;
  final String name;
  final double priceInr;
  final String description;

  const SubscriptionPlanEntity({
    required this.code,
    required this.name,
    required this.priceInr,
    required this.description,
  });
}
