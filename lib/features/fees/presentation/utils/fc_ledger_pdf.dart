import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/school_header_info.dart';
import '../widgets/fees_collection_models.dart';
import 'fee_assignment_format.dart' show groupIndian, initials;
import 'fees_collection_format.dart' show fmtDate;
import 'pdf_unicode_theme.dart';

const Map<String, PdfColor> _fcStatusColor = {
  'partial': PdfColor.fromInt(0xFFD97706),
  'cleared': PdfColor.fromInt(0xFF15803D),
  'overdue': PdfColor.fromInt(0xFFDC2626),
  'unassigned': PdfColor.fromInt(0xFF6B7280),
};

Future<Uint8List?> _fetchImageBytes(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final response = await Dio().get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final data = response.data;
    return data == null ? null : Uint8List.fromList(data);
  } catch (_) {
    return null;
  }
}

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Mirrors FeesCollectionPanel.tsx's `generateLedgerPDF` (§14 of the port
/// spec) — same header band / student card / ledger table / balance box /
/// footer structure and colors, rebuilt with the `pdf` package's
/// widget-layout model (`pw.Column`/`pw.Container`) instead of jsPDF's
/// absolute-canvas `doc.text`/`doc.rect` calls, since there is no
/// equivalent raw-canvas API in `pw`. Auto-paginates via `pw.MultiPage`
/// (the source's own `checkPage` new-page logic) rather than repeating the
/// header per page, matching the source (header is drawn once, at the top
/// of the document, not on every page).
Future<void> shareLedgerPdf({required FcStudentRecord student, required SchoolHeaderInfo header}) async {
  final logoBytes = await _fetchImageBytes(header.logoUrl);
  final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
  final statusColor = _fcStatusColor[student.status] ?? _fcStatusColor['unassigned']!;
  final balance = student.ledgerBalance;
  final balanceColor = balance <= 0 ? const PdfColor.fromInt(0xFF15803D) : const PdfColor.fromInt(0xFFDC2626);

  final doc = pw.Document(theme: await pdfUnicodeTheme());
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16 * PdfPageFormat.mm),
      build: (context) => [
        // ── Header band ─────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF8F8FB), borderRadius: pw.BorderRadius.circular(3)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 45,
                height: 45,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF3F4F6),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFE8E8EE)),
                  borderRadius: pw.BorderRadius.circular(4),
                  image: logoImage != null ? pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover) : null,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(header.name.isEmpty ? 'School' : header.name, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      [header.address, header.email].where((s) => s.isNotEmpty).join('  ·  '),
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFF6D4AFF), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text('LEDGER', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Divider(color: const PdfColor.fromInt(0xFFE8E8EE), thickness: 0.4),
        pw.SizedBox(height: 7),
        // ── Student card ─────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF5F3FF),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFC4B5FD), width: 0.4),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 14,
                height: 14,
                alignment: pw.Alignment.center,
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6D4AFF), shape: pw.BoxShape.circle),
                child: pw.Text(initials(student.name), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(student.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
                    pw.Text('${student.admNo}  ·  Class ${student.cls}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF6B7280))),
                  ],
                ),
              ),
              pw.Text(_cap(student.status), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: statusColor)),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // ── Table header ─────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF8F8FB), border: pw.Border.all(color: const PdfColor.fromInt(0xFFE8E8EE), width: 0.3)),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 60, child: pw.Text('DATE', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFA0A3B8)))),
              pw.Expanded(child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFA0A3B8)))),
              pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFA0A3B8))),
            ],
          ),
        ),
        // ── Table rows ────────────────────────────────────────────────
        for (var i = 0; i < student.fullLedger.length; i++) _ledgerPdfRow(student.fullLedger[i], i),
        pw.Container(decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE8E8EE), width: 0.3)))),
        pw.SizedBox(height: 9),
        // ── Balance box ───────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF8F7FF),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFF6D4AFF), width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ledger Balance', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF6D4AFF))),
              pw.Text(
                'Rs. ${groupIndian(balance.round().abs().toString())}  ${balance <= 0 ? '(Settled)' : '(Due)'}',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: balanceColor),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: const PdfColor.fromInt(0xFFE8E8EE), thickness: 0.3),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            'This is a computer-generated ledger statement.  ·  ${header.name}',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFFA0A3B8)),
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'Ledger-${student.name}-${student.admNo}.pdf');
}

pw.Widget _ledgerPdfRow(FcLedgerEntry e, int index) {
  final hasNote = e.note.isNotEmpty;
  final zebra = index % 2 == 0;
  final amountColor = e.type == FcLedgerType.credit
      ? const PdfColor.fromInt(0xFF15803D)
      : (e.type == FcLedgerType.charge ? const PdfColor.fromInt(0xFFDC2626) : const PdfColor.fromInt(0xFF6B7280));
  final amountText = e.amount != null ? '${e.type == FcLedgerType.credit ? '-' : ''}Rs. ${groupIndian(e.amount!.round().abs().toString())}' : '';

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: pw.BoxDecoration(
      color: zebra ? const PdfColor.fromInt(0xFFFAFAFC) : null,
      border: const pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFF3F4F6), width: 0.3)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 60, child: pw.Text(fmtDate(e.date), style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF6B7280)))),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(e.title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
              if (hasNote) pw.Text(e.note, style: const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFFA0A3B8))),
            ],
          ),
        ),
        pw.Text(amountText, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: amountColor)),
      ],
    ),
  );
}
