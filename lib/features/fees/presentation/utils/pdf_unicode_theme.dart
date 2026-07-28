import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;

pw.ThemeData? _cachedTheme;

/// The `pdf` package's default base-14 fonts (Helvetica/Helvetica-Bold) only
/// cover a narrow Latin-1-ish subset — text containing an em dash ("—", used
/// in ledger entry titles like "Payment received — Cash") or a middle dot
/// ("·", used throughout the receipt/ledger headers and rows) renders as a
/// blank glyph and logs "has no Unicode support" at runtime. Embedding a
/// real Unicode font fixes rendering without changing any of the actual
/// label/copy strings, which are intentionally kept as-is to match the
/// source. Cached after first load since both PDF generators call this and
/// the font bytes don't change between calls.
///
/// `PdfGoogleFonts` fetches the font over the network on first use (then
/// caches it on disk) — on a device/emulator with no or restricted internet
/// access this call would otherwise hang indefinitely or throw, silently
/// blocking every PDF export (receipts, ledgers, the Dues & Reminders
/// report) forever on "Generating…"/"Posting…". Bounded with a timeout and
/// never rethrows: on any failure this falls back to the default Helvetica
/// theme so PDF generation always completes (worst case, the handful of
/// non-ASCII glyphs render blank, exactly as before this fix existed).
Future<pw.ThemeData> pdfUnicodeTheme() async {
  final cached = _cachedTheme;
  if (cached != null) return cached;
  try {
    final base = await PdfGoogleFonts.notoSansRegular().timeout(const Duration(seconds: 8));
    final bold = await PdfGoogleFonts.notoSansBold().timeout(const Duration(seconds: 8));
    final theme = pw.ThemeData.withFont(base: base, bold: bold);
    _cachedTheme = theme;
    return theme;
  } catch (e, st) {
    debugPrint('pdfUnicodeTheme: Google Fonts unavailable, falling back to default theme — $e\n$st');
    return pw.ThemeData();
  }
}
