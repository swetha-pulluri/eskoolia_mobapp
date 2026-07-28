import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/due_student.dart';
import '../../domain/models/dues_class_group.dart';
import '../../domain/models/dues_summary.dart';
import 'fee_assignment_format.dart' show groupIndian;
import 'fees_dues_format.dart';
import 'pdf_unicode_theme.dart';

const Map<String, ({PdfColor bg, PdfColor fg})> _statusPdfColors = {
  'Payment Watch': (bg: PdfColor.fromInt(0xFFFEF3C7), fg: PdfColor.fromInt(0xFFD97706)),
  'Escalated': (bg: PdfColor.fromInt(0xFFFED7AA), fg: PdfColor.fromInt(0xFFEA580C)),
  'Defaulter': (bg: PdfColor.fromInt(0xFFFCE7F3), fg: PdfColor.fromInt(0xFF9D174D)),
};

/// Mirrors FeesDuesRemindersPanel.tsx's `generateReport` (client-side jsPDF
/// export) — same landscape-A4 layout, purple header bar, 4 summary boxes,
/// per-class purple-tinted section headers, striped student tables with a
/// colored status pill, and a page-number footer repeated on every page
/// (built here via `pw.MultiPage`'s own `footer:` slot rather than manually
/// counting pages like jsPDF does).
Future<void> shareDuesReportPdf({
  required int activeTier,
  required String tierLabel,
  required DuesSummary? summary,
  required List<DuesClassGroup> groups,
}) async {
  final today = _fmtToday();
  final doc = pw.Document(theme: await pdfUnicodeTheme());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 6),
        child: pw.Text(
          'Eskoolia School ERP  ·  Dues & Reminders Report  ·  Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFFB4B4C3)),
        ),
      ),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const pw.EdgeInsets.only(bottom: 14),
          color: const PdfColor.fromInt(0xFF6D4AFF),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('DUES & REMINDERS REPORT', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Text('$tierLabel  ·  Generated: $today', style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
            ],
          ),
        ),
        if (summary != null) _summaryBoxes(summary),
        for (final group in groups) _classSection(group),
      ],
    ),
  );

  // `Printing.layoutPdf` opens a print-preview surface (a full print dialog
  // on desktop/mobile, a new print-preview page on web) — the source's own
  // `doc.save(...)` triggers a direct browser file download instead, with
  // no intermediate print UI. `Printing.sharePdf` is the equivalent here:
  // on web it forces a real download; on mobile/desktop it opens the native
  // share sheet — either way, no print-preview page.
  final bytes = await doc.save();
  await Printing.sharePdf(bytes: bytes, filename: 'dues-report-tier$activeTier-${_fmtIsoDate()}.pdf');
}

String _fmtToday() {
  final now = DateTime.now();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

String _fmtIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

pw.Widget _summaryBoxes(DuesSummary summary) {
  final stats = [
    ('TOTAL OVERDUE', 'Rs. ${groupIndian((double.tryParse(summary.totalOverdueAmount) ?? 0).round().toString())}'),
    ('STUDENTS WITH DUES', '${summary.studentsWithDues}'),
    ('AVG DAYS OVERDUE', '${summary.avgDaysOverdue}'),
    ('% COLLECTED', '${summary.pctCollected}%'),
  ];
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 3),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF8F8FB), borderRadius: pw.BorderRadius.circular(2)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(stats[i].$1, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFA0A3B8))),
                  pw.SizedBox(height: 3),
                  pw.Text(stats[i].$2, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

const _colFlex = [3, 1.3, 1.6, 1.1, 1.8, 1.5]; // STUDENT | ADM NO | AMOUNT DUE | DAYS | LAST REMINDER | STATUS
const _colHeaders = ['STUDENT', 'ADM NO', 'AMOUNT DUE', 'DAYS', 'LAST REMINDER', 'STATUS'];

pw.Widget _classSection(DuesClassGroup group) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFEBE8FF),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFC8BEFF), width: 0.4),
          ),
          child: pw.Text(
            'Class ${group.cls}  ·  ${group.students.length} student${group.students.length != 1 ? 's' : ''} with dues',
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF5028C8)),
          ),
        ),
        pw.Container(
          color: const PdfColor.fromInt(0xFFF0F0F8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Row(
            children: [
              for (var i = 0; i < _colHeaders.length; i++)
                pw.Expanded(
                  flex: (_colFlex[i] * 10).round(),
                  child: pw.Text(_colHeaders[i], style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF646782))),
                ),
            ],
          ),
        ),
        for (var ri = 0; ri < group.students.length; ri++) _studentRow(group.students[ri], ri),
      ],
    ),
  );
}

pw.Widget _studentRow(DueStudent st, int ri) {
  final status = duesTierStatus(st.daysOverdue);
  final cfg = _statusPdfColors[status];
  final rowBg = ri % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFFAFAFE);
  final vals = [
    st.name,
    st.admNo,
    'Rs. ${groupIndian((double.tryParse(st.amountDue) ?? 0).round().toString())}',
    '${st.daysOverdue}',
    fmtDuesDate(st.lastReminder),
    status,
  ];
  return pw.Container(
    color: rowBg,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE8E8EE), width: 0.3))),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < vals.length; i++)
          pw.Expanded(
            flex: (_colFlex[i] * 10).round(),
            child: i == 5 && cfg != null
                ? pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(color: cfg.bg, borderRadius: pw.BorderRadius.circular(3)),
                      child: pw.Text(vals[i], style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: cfg.fg)),
                    ),
                  )
                : pw.Text(vals[i], style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF181B2A))),
          ),
      ],
    ),
  );
}
