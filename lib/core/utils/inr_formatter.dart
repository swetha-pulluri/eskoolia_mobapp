/// Matches the web frontend's `fmtINR()` exactly
/// (`frontend/app/(dashboard)/super-admin/billing/page.tsx:37-52`), used by
/// every School Tenancy screen that displays money (Billing, New Invoice).
///
/// - `compact: true` (default) abbreviates to Cr/L/K, no digit grouping.
/// - `compact: false` shows the full amount with real Indian digit grouping
///   (e.g. 1234567.89 → "12,34,567.89") — `Intl.NumberFormat('en-IN', ...)`
///   on web.
String formatINR(double amount, {bool compact = true, bool symbol = true, int fraction = 2}) {
  final sign = symbol ? '₹' : '';
  if (compact) {
    final abs = amount.abs();
    if (abs >= 10000000) return '$sign${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (abs >= 100000) return '$sign${(amount / 100000).toStringAsFixed(2)}L';
    if (abs >= 1000) return '$sign${(amount / 1000).toStringAsFixed(0)}K';
    return '$sign${amount.toStringAsFixed(0)}';
  }
  final symbolPrefix = symbol ? '₹ ' : '';
  return '$symbolPrefix${_indianGrouped(amount, fraction)}';
}

/// `Intl.NumberFormat('en-IN', {...}).format(n)` equivalent — groups the
/// integer part as 3 digits then pairs of 2 (e.g. 1234567 → "12,34,567").
String _indianGrouped(double amount, int fraction) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(fraction);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : null;

  String grouped;
  if (intPart.length <= 3) {
    grouped = intPart;
  } else {
    final last3 = intPart.substring(intPart.length - 3);
    final groups = <String>[];
    var remaining = intPart.substring(0, intPart.length - 3);
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);
    grouped = '${groups.join(',')},$last3';
  }
  return '${negative ? '-' : ''}$grouped${decPart != null ? '.$decPart' : ''}';
}
