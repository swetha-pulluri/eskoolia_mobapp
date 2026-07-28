import '../widgets/fees_collection_models.dart';

/// Mirrors FeesCollectionPanel.tsx's `fmtDate` — `YYYY-MM-DD` → `D MMM YYYY`
/// (e.g. "27 May 2026"). Returns the input unchanged if it isn't parseable,
/// same fallback as the source. `fmtRs`/`avatarBg`/`initials` are reused
/// as-is from fee_assignment_format.dart (identical algorithms in the
/// source's own `fmtRs`/`avBg`/`ini`) — import that file alongside this one.
String fmtDate(String d) {
  if (d.isEmpty) return '';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final parts = d.split('-');
  if (parts.length < 3 || parts[0].isEmpty || parts[1].isEmpty || parts[2].isEmpty) return d;
  final monthIndex = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (monthIndex == null || day == null || monthIndex < 1 || monthIndex > 12) return d;
  return '$day ${months[monthIndex - 1]} ${parts[0]}';
}

/// Mirrors the source's `selDues.length===1?(parseInt(amtPaid)||d.amount):d.amount`
/// used by the Receipt Preview card and the Confirm modal's per-due
/// breakdown (and by `postPayment`'s actual posted amount). NOTE: JS's `||`
/// treats a parsed `0` the same as a failed parse — both fall back to
/// `due.amount` — a real source quirk (typing "0" with a single due
/// selected silently charges the full due amount) that is preserved here
/// intentionally rather than "fixed".
double resolvedDueAmount(FcDue due, int selectedCount, String amtPaidText) {
  if (selectedCount != 1) return due.amount;
  final parsed = int.tryParse(amtPaidText);
  return (parsed != null && parsed != 0) ? parsed.toDouble() : due.amount;
}

/// Mirrors the source's `total` — `selDues.length===1?(parseInt(amtPaid)||0):sum`.
/// Unlike [resolvedDueAmount], a `0`/unparseable Amount Paid here falls back
/// to 0, not to the due amount — the same inconsistency exists in the
/// source between what the preview/confirm-total shows and what actually
/// gets posted, and is preserved as-is.
double resolvedTotal(List<FcDue> selDues, String amtPaidText) {
  if (selDues.length == 1) return (int.tryParse(amtPaidText) ?? 0).toDouble();
  return selDues.fold(0.0, (s, d) => s + d.amount);
}
