import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/due_student.dart';
import '../../domain/models/dues_class_group.dart';
import 'fee_assignment_format.dart' show groupIndian;
import 'pdf_unicode_theme.dart';

/// Mirrors YearEndPage.tsx's `generatePDF` (client-side jsPDF export) — same
/// purple header band, per-report-type body (a real table for
/// `outstanding_dues`/`class_wise_report`, a 2×2 stat-box summary page for
/// the other three report types), and footer band. Uses `pw.MultiPage`'s
/// own `footer:` slot for the page-number line (correctly incrementing per
/// page) rather than the source's own literal `Page 1 of {N}` text, which
/// is a static string baked in once regardless of which page it lands on —
/// a source bug not worth reproducing verbatim.
Future<void> shareYearEndReportPdf({
  required String reportName,
  required String reportType,
  required List<DuesClassGroup> groups,
  required List<DueStudent> allStudents,
  required double collected,
  required double outstanding,
  required double concessions,
}) async {
  final doc = pw.Document(theme: await pdfUnicodeTheme());
  final today = _fmtToday();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: pw.EdgeInsets.zero,
      header: (context) => context.pageNumber == 1
          ? pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(28, 14, 28, 10),
              color: const PdfColor.fromInt(0xFF6D4AFF),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ESKOOLIA — Year-End Report', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(reportName, style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                      pw.Text('Generated: $today', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            )
          : pw.SizedBox(),
      footer: (context) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        color: const PdfColor.fromInt(0xFFF8F8FB),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Eskoolia School ERP — Confidential', style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFFA0A3B8))),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFFA0A3B8))),
          ],
        ),
      ),
      build: (context) => [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: _buildBody(reportType, groups, allStudents, collected, outstanding, concessions),
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  await Printing.sharePdf(bytes: bytes, filename: '$reportType.pdf');
}

String _fmtToday() {
  final now = DateTime.now();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
}

pw.Widget _buildBody(
  String reportType,
  List<DuesClassGroup> groups,
  List<DueStudent> allStudents,
  double collected,
  double outstanding,
  double concessions,
) {
  if (reportType == 'outstanding_dues' && allStudents.isNotEmpty) {
    final totalAmt = allStudents.fold<double>(0, (s, st) => s + (double.tryParse(st.amountDue) ?? 0));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total outstanding students: ${allStudents.length}  |  Total amount: Rs.${groupIndian(totalAmt.round().toString())}',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A)),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          color: const PdfColor.fromInt(0xFF6D4AFF),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 160, child: pw.Text('STUDENT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.Expanded(flex: 80, child: pw.Text('CLASS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.Expanded(flex: 110, child: pw.Text('AMOUNT DUE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.Expanded(flex: 110, child: pw.Text('DAYS OVERDUE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.Expanded(flex: 110, child: pw.Text('STATUS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
            ],
          ),
        ),
        for (var i = 0; i < allStudents.length; i++) _outstandingRow(allStudents[i], i),
      ],
    );
  } else if (reportType == 'class_wise_report' && groups.isNotEmpty) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          color: const PdfColor.fromInt(0xFF6D4AFF),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 150, child: pw.Text('CLASS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.Expanded(flex: 160, child: pw.Text('STUDENTS WITH DUES', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
              pw.Expanded(flex: 160, child: pw.Text('TOTAL OUTSTANDING', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
            ],
          ),
        ),
        for (var i = 0; i < groups.length; i++) _classWiseRow(groups[i], i),
      ],
    );
  } else {
    final stats = [
      ('COLLECTED', 'Rs. ${groupIndian(collected.round().toString())}', const PdfColor.fromInt(0xFF10B981)),
      ('OUTSTANDING', 'Rs. ${groupIndian(outstanding.round().toString())}', const PdfColor.fromInt(0xFFDC2626)),
      ('CONCESSIONS', 'Rs. ${groupIndian((concessions < 0 ? 0 : concessions).round().toString())}', const PdfColor.fromInt(0xFF6D4AFF)),
      ('STUDENTS WITH DUES', '${allStudents.length}', const PdfColor.fromInt(0xFF181B2A)),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('2025-26 Academic Year Summary', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF181B2A))),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in stats)
              pw.Container(
                width: 160,
                height: 50,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: s.$3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(s.$1, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.SizedBox(height: 4),
                    pw.Text(s.$2, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

pw.Widget _outstandingRow(DueStudent st, int i) {
  final name = st.name.length > 22 ? '${st.name.substring(0, 21)}…' : st.name;
  return pw.Container(
    color: i % 2 == 0 ? const PdfColor.fromInt(0xFFF8F8FB) : PdfColors.white,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: pw.Row(
      children: [
        pw.Expanded(flex: 160, child: pw.Text(name, style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF181B2A)))),
        pw.Expanded(flex: 80, child: pw.Text(st.cls, style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF181B2A)))),
        pw.Expanded(flex: 110, child: pw.Text('Rs.${groupIndian((double.tryParse(st.amountDue) ?? 0).round().toString())}', style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF181B2A)))),
        pw.Expanded(flex: 110, child: pw.Text('${st.daysOverdue} days', style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF181B2A)))),
        pw.Expanded(flex: 110, child: pw.Text(st.status, style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF181B2A)))),
      ],
    ),
  );
}

pw.Widget _classWiseRow(DuesClassGroup g, int i) {
  final clsTotal = g.students.fold<double>(0, (s, st) => s + (double.tryParse(st.amountDue) ?? 0));
  return pw.Container(
    color: i % 2 == 0 ? const PdfColor.fromInt(0xFFF8F8FB) : PdfColors.white,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: pw.Row(
      children: [
        pw.Expanded(flex: 150, child: pw.Text(g.cls, style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF181B2A)))),
        pw.Expanded(flex: 160, child: pw.Text('${g.students.length}', style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF181B2A)))),
        pw.Expanded(flex: 160, child: pw.Text('Rs.${groupIndian(clsTotal.round().toString())}', style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF181B2A)))),
      ],
    ),
  );
}
