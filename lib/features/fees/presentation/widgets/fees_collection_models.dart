/// View-model classes for the Collection screen — mirrors
/// FeesCollectionPanel.tsx's `Due`/`LedgerEntry`/`StudentRecord`/
/// `LateFeeCalc`/the `INIT_PAYMENTS` row shape. Kept separate from the
/// domain models (fee_assignment.dart etc.) since these are derived,
/// display-only shapes computed from the raw API data, not API payloads
/// themselves.
class FcDue {
  final String id; // assignment id, stringified
  final String label;
  final double amount;
  final String due;
  const FcDue({required this.id, required this.label, required this.amount, required this.due});
}

enum FcLedgerType { charge, credit, note }

class FcLedgerEntry {
  final String date;
  final String title;
  final String note;
  final double? amount;
  final FcLedgerType type;
  const FcLedgerEntry({required this.date, required this.title, required this.note, required this.amount, required this.type});
}

/// Never actually populated by the source (nothing sets `lateFeeCalc`
/// anywhere in FeesCollectionPanel.tsx) — kept so the "Late Fee Calculator
/// Preview" block in the Student Ledger View modal has a real type to guard
/// on, matching the source's always-false `if (selected.lateFeeCalc)`.
class FcLateFeeCalc {
  final String label;
  final String dueRule;
  final double outstanding;
  final int daysOverdue;
  final int chargeableDays;
  final double rawPenalty;
  final double finalDue;
  const FcLateFeeCalc({
    required this.label,
    required this.dueRule,
    required this.outstanding,
    required this.daysOverdue,
    required this.chargeableDays,
    required this.rawPenalty,
    required this.finalDue,
  });
}

// partial | cleared | overdue | unassigned
class FcStudentRecord {
  final String id;
  final String name;
  final String admNo;
  final String cls;
  final String group;
  final String status;
  final List<FcDue> dues;
  final List<FcLedgerEntry> ledger;
  final List<FcLedgerEntry> fullLedger;
  final double ledgerBalance;
  final FcLateFeeCalc? lateFeeCalc;

  const FcStudentRecord({
    required this.id,
    required this.name,
    required this.admNo,
    required this.cls,
    required this.group,
    required this.status,
    required this.dues,
    required this.ledger,
    required this.fullLedger,
    required this.ledgerBalance,
    this.lateFeeCalc,
  });
}

/// One row of the Recent Payments tab — mirrors `INIT_PAYMENTS`'s mapped
/// shape (a payment joined with its student + assignment for display).
class FcPaymentRow {
  final int id;
  final String rcpt; // "PMT-{id}"
  final String student;
  final String admNo;
  final String cls;
  final String feeName;
  final double amount;
  final String method; // cash | bank | online | wallet | cheque
  final String status; // posted | pending_clearance | pending_reconciliation | pending_verification | reversed
  final String date; // already fmtDate()'d
  final String txRef;
  final String noteText;

  const FcPaymentRow({
    required this.id,
    required this.rcpt,
    required this.student,
    required this.admNo,
    required this.cls,
    required this.feeName,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    required this.txRef,
    required this.noteText,
  });
}
