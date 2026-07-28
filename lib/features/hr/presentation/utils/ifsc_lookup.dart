import 'package:dio/dio.dart' as dio;

/// Real, external (not the app's own backend) IFSC lookup — deliberately
/// unauthenticated, matching the real web's own inline
/// `fetch('https://ifsc.razorpay.com/${code}')` call exactly. Shared between
/// `StaffFormPage`'s Bank tab and the onboarding wizard's Step 5 (Government
/// identity) so both hit the same real API the same way.
class IfscLookupResult {
  final String bankName;
  final String branch;
  const IfscLookupResult({required this.bankName, required this.branch});

  bool get isEmpty => bankName.isEmpty && branch.isEmpty;
}

final _ifscRegex = RegExp(r'^[A-Z]{4}0\d{6}$');

bool isValidIfscFormat(String code) => _ifscRegex.hasMatch(code);

/// Returns null on any failure (network error, not-found, malformed
/// response) — callers should show a generic "Could not auto-fill bank
/// details for this IFSC." message on null, matching the real web's own
/// behavior.
Future<IfscLookupResult?> lookupIfsc(String code) async {
  try {
    final response = await dio.Dio().get<Map<String, dynamic>>('https://ifsc.razorpay.com/$code');
    final data = response.data;
    final bank = data?['BANK']?.toString().trim() ?? '';
    final branch = data?['BRANCH']?.toString().trim() ?? '';
    if (bank.isEmpty && branch.isEmpty) return null;
    return IfscLookupResult(bankName: bank, branch: branch);
  } catch (_) {
    return null;
  }
}
