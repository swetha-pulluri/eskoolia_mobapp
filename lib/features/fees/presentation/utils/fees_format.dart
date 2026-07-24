/// Formatting helpers mirroring FeesPaymentsPanel.tsx's `fmtAmt` (Indian
/// digit grouping via `Number.toLocaleString('en-IN')`) and `nowTime`
/// (`toLocaleTimeString('en-IN', { hour12: false })` → 24-hour `HH:mm`).
String feesFormatAmount(num value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final wholePart = abs.truncate();
  final grouped = _groupIndian(wholePart.toString());

  final fraction = abs - wholePart;
  if (fraction == 0) {
    return isNegative ? '-$grouped' : grouped;
  }
  var fractionDigits = fraction.toStringAsFixed(2).substring(2);
  fractionDigits = fractionDigits.replaceFirst(RegExp(r'0+$'), '');
  if (fractionDigits.isEmpty) {
    return isNegative ? '-$grouped' : grouped;
  }
  final result = '$grouped.$fractionDigits';
  return isNegative ? '-$result' : result;
}

String feesFormatAmountFromString(String raw) => feesFormatAmount(double.tryParse(raw) ?? 0);

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

String feesNowTime() => feesFormatTime(DateTime.now());

String feesFormatTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
