import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/id_card_entity.dart';
import '../../domain/entities/certificate_entity.dart';

/// Mobile equivalent of the web's `window.open()` + `popup.print()` in
/// `GenerateIdCardPanel.tsx`/`GenerateCertificatePanel.tsx` — there is no
/// browser print popup on mobile, so this builds the same real template +
/// recipient data into an actual PDF and hands it to the native
/// print/share sheet via `Printing.layoutPdf`.
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

double _mmVal(int? value, double fallback) => (value == null || value == 0) ? fallback : value.toDouble();

String _initialsOf(String displayName) {
  final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
  final initials = parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
  return initials.isEmpty ? 'S' : initials;
}

String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);

/// Placeholder substitution matching `GenerateCertificatePanel.tsx`'s
/// `replacePlaceholders()` — same alias groups, same `{{key}}`/`[key]`
/// (case-insensitive, whitespace-tolerant) matching.
String _replacePlaceholders(String body, RecipientEntity r, String today) {
  final values = <String, String>{
    'student_name': r.label,
    'name': r.label,
    'class': r.className ?? '',
    'admission_no': r.admissionNo ?? '',
    'roll_no': r.rollNo ?? '',
    'section_name': r.sectionName ?? '',
    'gender': r.gender ?? '',
    'date_of_birth': r.dateOfBirth ?? '',
    'date': today,
  };
  final aliasGroups = <String, List<String>>{
    'student_name': ['student_name', 'student name', 'student'],
    'name': ['name'],
    'class': ['class', 'class_name', 'class name'],
    'admission_no': ['admission_no', 'admission no', 'admission number'],
    'roll_no': ['roll_no', 'roll no', 'roll number'],
    'section_name': ['section_name', 'section name', 'section'],
    'gender': ['gender'],
    'date_of_birth': ['date_of_birth', 'date of birth', 'dob'],
    'date': ['date', 'today'],
  };
  var out = body.replaceAll('**', '');
  for (final entry in aliasGroups.entries) {
    final value = values[entry.key] ?? '';
    for (final pattern in entry.value) {
      final escaped = RegExp.escape(pattern).replaceAll(' ', r'\s+');
      final brace = RegExp('\\{\\{\\s*$escaped\\s*\\}\\}', caseSensitive: false);
      final bracket = RegExp('\\[\\s*$escaped\\s*\\]', caseSensitive: false);
      out = out.replaceAll(brace, value).replaceAll(bracket, value);
    }
  }
  return out;
}

pw.Widget _idCardWidget({
  required RecipientEntity r,
  required bool isStudentRole,
  required double widthPt,
  required double heightPt,
  pw.MemoryImage? background,
  pw.MemoryImage? logo,
  pw.MemoryImage? signature,
}) {
  return pw.Container(
    width: widthPt,
    height: heightPt,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400, width: 0.75),
      borderRadius: pw.BorderRadius.circular(6),
      image: background != null ? pw.DecorationImage(image: background, fit: pw.BoxFit.cover) : null,
    ),
    child: pw.Stack(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) pw.SizedBox(height: 22, child: pw.Image(logo, fit: pw.BoxFit.contain, alignment: pw.Alignment.topLeft)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: 40,
              height: 40,
              decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.grey300),
              alignment: pw.Alignment.center,
              child: pw.Text(_initialsOf(r.label), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            ),
            pw.SizedBox(height: 4),
            pw.Text(r.label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
            if (isStudentRole) ...[
              pw.Text('Admission: ${r.admissionNo ?? '-'}', style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text('Class: ${r.className ?? '-'} (${r.sectionName ?? '-'})', style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text('Roll: ${r.rollNo ?? '-'}', style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text('Gender: ${r.gender ?? '-'}', style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text('DOB: ${r.dateOfBirth ?? '-'}', style: const pw.TextStyle(fontSize: 7.5)),
            ],
          ],
        ),
        if (signature != null)
          pw.Positioned(
            right: 4,
            bottom: 4,
            child: pw.SizedBox(height: 18, width: 44, child: pw.Image(signature, fit: pw.BoxFit.contain)),
          ),
      ],
    ),
  );
}

/// Builds a real PDF from the selected ID card template + recipients and
/// opens the native print/share dialog. Mirrors
/// `GenerateIdCardPanel.tsx:268-375`: same card fields (Admission/Class/
/// Roll/Gender/DOB for the Student role only), same background/logo/
/// signature images, same grid layout (`gridGapPx`), same `pl_width`/
/// `pl_height`-driven card size with the same layout-style fallback.
Future<void> printIdCards({
  required List<RecipientEntity> recipients,
  required IdCardTemplateEntity template,
  required bool isStudentRole,
  double gridGapPx = 12,
}) async {
  final background = await _fetchImageBytes(template.backgroundUrl);
  final logo = await _fetchImageBytes(template.logoUrl);
  final signature = await _fetchImageBytes(template.signatureUrl);

  final isHorizontal = template.pageLayoutStyle != 'vertical';
  final widthPt = _mmVal(template.plWidth, isHorizontal ? 85 : 55) * PdfPageFormat.mm;
  final heightPt = _mmVal(template.plHeight, isHorizontal ? 54 : 85) * PdfPageFormat.mm;
  final gapPt = gridGapPx * 0.75;

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (context) => [
        pw.Wrap(
          spacing: gapPt,
          runSpacing: gapPt,
          children: recipients
              .map((r) => _idCardWidget(
                    r: r,
                    isStudentRole: isStudentRole,
                    widthPt: widthPt,
                    heightPt: heightPt,
                    background: background != null ? pw.MemoryImage(background) : null,
                    logo: logo != null ? pw.MemoryImage(logo) : null,
                    signature: signature != null ? pw.MemoryImage(signature) : null,
                  ))
              .toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'id-cards.pdf');
}

/// Builds a real PDF from the selected certificate template + recipients
/// (one certificate per page, page-sized to the template's own
/// `background_width`/`background_height`) and opens the native
/// print/share dialog. Mirrors `GenerateCertificatePanel.tsx:324-479`: same
/// placeholder-substituted body, same background image, same
/// Class/Section + Date + Authorized Signature footer.
Future<void> printCertificates({
  required List<RecipientEntity> recipients,
  required CertificateTemplateEntity template,
}) async {
  final background = await _fetchImageBytes(template.backgroundUrl);
  final backgroundImage = background != null ? pw.MemoryImage(background) : null;

  final widthPt = template.backgroundWidth * PdfPageFormat.mm;
  final heightPt = template.backgroundHeight * PdfPageFormat.mm;
  final pageFormat = PdfPageFormat(widthPt, heightPt, marginAll: 0);
  final today = _todayIso();

  final doc = pw.Document();
  for (final r in recipients) {
    final body = _replacePlaceholders(template.body, r, today);
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Stack(
          children: [
            if (backgroundImage != null) pw.Positioned.fill(child: pw.Image(backgroundImage, fit: pw.BoxFit.cover)),
            pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(
                template.paddingLeft * PdfPageFormat.mm,
                template.paddingTop * PdfPageFormat.mm,
                template.paddingRight * PdfPageFormat.mm,
                template.paddingBottom * PdfPageFormat.mm,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(body, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 13)),
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Class/Section: ${r.className ?? '-'}${(r.sectionName != null && r.sectionName != '-') ? ' (${r.sectionName})' : ''}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text('Date: $today', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Authorized Signature: __________', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'certificates.pdf');
}
