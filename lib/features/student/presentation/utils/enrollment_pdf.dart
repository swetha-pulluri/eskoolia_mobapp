import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../fees/presentation/utils/pdf_unicode_theme.dart';

/// Mirrors `ConsentForm.tsx`'s `DEFAULT_DECLARATION` exactly — the frontend
/// only ever prints this default text (per-school declaration customization
/// lives in `ConsentForm.tsx`'s branding/settings panel, which is out of
/// scope for this pass — see [printEnrollmentForm]'s doc comment).
const String kDefaultEnrollmentDeclaration =
    "I, the undersigned parent / legal guardian of {studentName}, hereby confirm that all information provided in "
    "this admission form is accurate and complete to the best of my knowledge. I consent to the school collecting, "
    "storing, and using the student's personal data exclusively for educational, administrative, and legally "
    "mandated purposes in accordance with the Digital Personal Data Protection Act, 2023. I understand that any "
    "withdrawal of consent must be submitted in writing to the school administration.";

class EnrollmentPdfGuardian {
  final String fullName;
  final String relation;
  final String phone;
  final String email;
  final String occupation;
  final bool isPrimary;

  const EnrollmentPdfGuardian({
    required this.fullName,
    required this.relation,
    required this.phone,
    required this.email,
    required this.occupation,
    required this.isPrimary,
  });
}

/// Everything the filled-admission-form PDF needs — a plain snapshot the
/// caller (StudentEnrollPage) builds from its own controllers/state, kept
/// separate from the page's live [TextEditingController]s so this util has
/// no Flutter-widget-tree dependency.
class EnrollmentPdfData {
  final String schoolName;
  final String schoolAddress;
  final String schoolPhone;
  final String schoolEmail;
  final String firstName;
  final String middleName;
  final String lastName;
  final String admissionNo;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String motherTongue;
  final String religion;
  final String nationality;
  final bool isActive;
  final String academicYearName;
  final String className;
  final String sectionName;
  final String admissionType;
  final String categoryName;
  final String phone;
  final String email;
  final String addressLine;
  final String city;
  final String district;
  final String stateName;
  final String pincode;
  final List<EnrollmentPdfGuardian> guardians;
  final bool apaarProvided;
  /// Each entry is (label, uploaded).
  final List<(String, bool)> documents;
  final String allergies;
  final String medications;
  final String emergencyContact;
  final bool isPwD;
  final String pwdNotes;
  final String identityMark1;
  final String identityMark2;
  final String birthmark;
  final String? photoUrl;

  const EnrollmentPdfData({
    required this.schoolName,
    this.schoolAddress = '',
    this.schoolPhone = '',
    this.schoolEmail = '',
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    required this.admissionNo,
    required this.dob,
    required this.gender,
    this.bloodGroup = '',
    this.motherTongue = '',
    this.religion = '',
    this.nationality = '',
    this.isActive = true,
    this.academicYearName = '',
    this.className = '',
    this.sectionName = '',
    this.admissionType = '',
    this.categoryName = '',
    this.phone = '',
    this.email = '',
    this.addressLine = '',
    this.city = '',
    this.district = '',
    this.stateName = '',
    this.pincode = '',
    this.guardians = const [],
    this.apaarProvided = false,
    this.documents = const [],
    this.allergies = '',
    this.medications = '',
    this.emergencyContact = '',
    this.isPwD = false,
    this.pwdNotes = '',
    this.identityMark1 = '',
    this.identityMark2 = '',
    this.birthmark = '',
    this.photoUrl,
  });
}

String _val(String v) => v.trim().isEmpty ? '—' : v.trim();

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

pw.Widget _sectionHeading(String text, PdfColor accent) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, top: 14),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accent),
      ),
    );

pw.Widget _kvTable(List<(String, String)> rows) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: const {0: pw.FlexColumnWidth(1.3), 1: pw.FlexColumnWidth(2.4)},
    children: rows
        .map((r) => pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(r.$1, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(r.$2, style: const pw.TextStyle(fontSize: 10)),
              ),
            ]))
        .toList(),
  );
}

/// Builds a real PDF of the filled admission/enrollment form and opens the
/// native print/share/save-as-PDF sheet — the mobile equivalent of
/// `ConsentForm.tsx` opening a print-only browser window and calling
/// `window.print()` (there is no `window.print()` on mobile; `Printing.
/// layoutPdf` is the standard Flutter substitute, used the same way
/// elsewhere in this app — see `document_print_helper.dart`).
///
/// Scope (disclosed): this reproduces `ConsentForm.tsx`'s core "filled
/// form" document — same 10 numbered sections, same declaration text, same
/// signature lines — using only the fields the Flutter Enroll form itself
/// collects. The frontend's surrounding secondary flows (school letterhead/
/// branding settings, upload-signed-copy, blank-form email/WhatsApp/
/// digital-fill menus, OCR scan-fill) are separate, much larger features
/// not covered by this pass. Section 5 "Government Identity" mirrors the
/// frontend's own privacy behavior (Aadhaar/APAAR is never printed in the
/// clear) by showing only whether an APAAR ID is on file, not its digits —
/// the frontend shows PEN/UDISE+ and ABC Portal ID instead, fields this
/// form doesn't collect.
Future<void> printEnrollmentForm(EnrollmentPdfData data) async {
  final theme = await pdfUnicodeTheme();
  final photoBytes = await _fetchImageBytes(data.photoUrl);
  const accent = PdfColor.fromInt(0xFF6C3CE1);

  final fullName = [data.firstName, data.middleName, data.lastName].where((s) => s.trim().isNotEmpty).join(' ');
  final declaration = kDefaultEnrollmentDeclaration.replaceAll('{studentName}', fullName.isEmpty ? '_____' : fullName);

  final doc = pw.Document(theme: theme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      build: (context) => [
        pw.Text(data.schoolName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: accent)),
        if (data.schoolAddress.isNotEmpty || data.schoolPhone.isNotEmpty || data.schoolEmail.isNotEmpty)
          pw.Text(
            [data.schoolAddress, data.schoolPhone, data.schoolEmail].where((s) => s.isNotEmpty).join('  ·  '),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        pw.Divider(color: PdfColors.grey400, height: 12),
        pw.Text('Student Verification Form', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.Text(
          'Please verify all details. Contact the school if any information is incorrect.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),

        _sectionHeading('1. Student Identity', accent),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 64,
              height: 64,
              margin: const pw.EdgeInsets.only(right: 10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
              alignment: pw.Alignment.center,
              child: photoBytes != null
                  ? pw.ClipRRect(
                      horizontalRadius: 4,
                      verticalRadius: 4,
                      child: pw.Image(pw.MemoryImage(photoBytes), fit: pw.BoxFit.cover, width: 64, height: 64),
                    )
                  : pw.Text('Photo', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ),
            pw.Expanded(
              child: _kvTable([
                ('Full Name', fullName.isEmpty ? '—' : fullName),
                ('Admission No.', _val(data.admissionNo)),
                ('Date of Birth', _val(data.dob)),
                ('Gender', _val(data.gender)),
                ('Blood Group', _val(data.bloodGroup)),
                ('Mother Tongue', _val(data.motherTongue)),
                ('Religion', _val(data.religion)),
                ('Nationality', _val(data.nationality)),
                ('Status', data.isActive ? 'Active' : 'Inactive'),
              ]),
            ),
          ],
        ),

        _sectionHeading('2. Academic Placement', accent),
        _kvTable([
          ('Academic Year', _val(data.academicYearName)),
          ('Class & Section', data.className.isEmpty ? '—' : '${data.className}${data.sectionName.isNotEmpty ? ' – ${data.sectionName}' : ''}'),
          ('Admission Type', _val(data.admissionType)),
          ('Category', _val(data.categoryName)),
        ]),

        _sectionHeading('3. Contact & Address', accent),
        _kvTable([
          ('Phone', _val(data.phone)),
          ('Email', _val(data.email)),
          ('Address', _val(data.addressLine)),
          ('City', _val(data.city)),
          ('District', _val(data.district)),
          ('State', _val(data.stateName)),
          ('Pincode', _val(data.pincode)),
        ]),

        _sectionHeading('4. Guardians', accent),
        if (data.guardians.isEmpty)
          pw.Text('No guardian details provided.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500))
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: data.guardians
                .map((g) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (g.isPrimary)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text('PRIMARY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accent)),
                            ),
                          _kvTable([
                            ('Name', _val(g.fullName)),
                            ('Relation', _val(g.relation)),
                            ('Phone', _val(g.phone)),
                            if (g.email.trim().isNotEmpty) ('Email', g.email.trim()),
                            if (g.occupation.trim().isNotEmpty) ('Occupation', g.occupation.trim()),
                          ]),
                        ],
                      ),
                    ))
                .toList(),
          ),

        _sectionHeading('5. Government Identity', accent),
        _kvTable([
          ('APAAR ID', data.apaarProvided ? 'On file' : 'Not provided'),
        ]),
        pw.Text(
          'Aadhaar number and APAAR ID are encrypted and not displayed for security.',
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500),
        ),

        _sectionHeading('6. Documents Checklist', accent),
        if (data.documents.isEmpty)
          pw.Text('No documents uploaded yet.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500))
        else
          _kvTable(data.documents.map((d) => (d.$1, d.$2 ? 'Submitted' : 'Pending')).toList()),

        _sectionHeading('7. Medical & Emergency', accent),
        _kvTable([
          ('Allergies', _val(data.allergies)),
          ('Current Medications', _val(data.medications)),
          ('Emergency Contact', _val(data.emergencyContact)),
        ]),

        _sectionHeading('8. Specially Abled (PwD)', accent),
        _kvTable([
          ('PwD Disclosure', data.isPwD ? 'Yes — disclosed' : 'Not Disclosed'),
          if (data.isPwD) ('Accommodation Notes', _val(data.pwdNotes)),
        ]),

        _sectionHeading('9. Physical Identity Marks', accent),
        _kvTable([
          ('Identity Mark 1', _val(data.identityMark1)),
          ('Identity Mark 2', _val(data.identityMark2)),
          ('Birthmark', _val(data.birthmark)),
        ]),

        _sectionHeading('10. Declaration', accent),
        pw.Text(declaration, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800, lineSpacing: 2)),

        pw.SizedBox(height: 36),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureBlock('Guardian / Parent Signature'),
            _signatureBlock('Principal / Authorised Signatory'),
            _signatureBlock('Date'),
          ],
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'enrollment-form.pdf');
}

pw.Widget _signatureBlock(String label) => pw.Column(
      children: [
        pw.Container(width: 130, height: 1, color: PdfColors.grey500),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    );

class EnrollmentChecklistModule {
  final int number;
  final String title;
  final List<(String, bool)> items; // (text, required)
  const EnrollmentChecklistModule(this.number, this.title, this.items);
}

/// Same 10 modules as StudentAddPanel.tsx's "What I'll need" info modal —
/// see `student_enroll_checklist_dialog.dart` for the on-screen render of
/// the identical content.
const List<EnrollmentChecklistModule> kEnrollmentChecklistModules = [
  EnrollmentChecklistModule(1, 'Student identity', [
    ('Full legal name (first, last)', true),
    ('Date of birth (must match age band of class)', true),
    ('Gender', true),
    ('Recent photo (square JPG/PNG, ≥400×400)', false),
    ('Blood group', false),
    ('Mother tongue, religion, nationality', false),
  ]),
  EnrollmentChecklistModule(2, 'Academic placement', [
    ('Academic year', true),
    ('Class & section', true),
    ('House (auto-suggested by AI)', false),
    ('Roll number (auto if blank)', false),
    ('Admission type, previous school name', false),
  ]),
  EnrollmentChecklistModule(3, 'Contact & address', [
    ('Mobile number (10-digit)', true),
    ('Address line, pincode (auto-fills city/state)', true),
    ('Email address', false),
    ('Landmark, means of transport', false),
  ]),
  EnrollmentChecklistModule(4, 'Family & guardians', [
    ('Guardian 1: name, relationship, mobile', true),
    ('Guardian 1: occupation, email', false),
    ('Additional guardians (mother/father/other)', false),
    ('Sibling already in school (for linking)', false),
    ('Friends/family emergency contacts', false),
  ]),
  EnrollmentChecklistModule(5, 'Government identity', [
    ("Aadhaar number (12-digit) — student's", false),
    ('Aadhaar of guardian (if student doesn’t have)', false),
    ('Birth certificate number', false),
    ('Caste / category certificate (if applicable)', false),
    ('PAN of guardian (for fee receipts > ₹2L)', false),
  ]),
  EnrollmentChecklistModule(6, 'Documents to upload', [
    ('Signed parent/guardian consent form', true),
    ('Birth certificate scan', false),
    ('Aadhaar scan (student / guardian)', false),
    ('Previous school TC / report card / mark sheets', false),
    ('Caste / income certificate (if applicable)', false),
    ('Custom documents (give a name + short note)', false),
  ]),
  EnrollmentChecklistModule(7, 'Medical & emergency', [
    ('Emergency contact name & phone', true),
    ('Known medical conditions (asthma, diabetes…)', false),
    ('Allergies (food, medication, environment)', false),
    ('Vaccination history / records', false),
    ('Family doctor name & phone', false),
  ]),
  EnrollmentChecklistModule(8, 'Specially abled (if applicable)', [
    ('Type of need (visual, hearing, learning…)', false),
    ('Disability certificate', false),
    ('Required accommodations (ramp, scribe, etc.)', false),
  ]),
  EnrollmentChecklistModule(9, 'Identity marks', [
    ('Visible birth marks, scars, moles (sensitive — keep brief)', false),
    ('Height & weight', false),
  ]),
  EnrollmentChecklistModule(10, 'Review & enroll', [
    ('Verify every section', true),
    ('Print or save the consent PDF', false),
    ('Submit the form to enroll the student', true),
  ]),
];

/// Mirrors StudentAddPanel.tsx's "Print checklist" button: builds the same
/// 10-module checklist into a real PDF and opens the native print/share
/// sheet (the mobile equivalent of its print-window + `window.print()`).
Future<void> printEnrollmentChecklist({required String schoolName}) async {
  final theme = await pdfUnicodeTheme();
  const accent = PdfColor.fromInt(0xFF6C3CE1);
  final doc = pw.Document(theme: theme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Text("What you'll need to enroll a student", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(schoolName, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(color: PdfColors.amber50, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: '★ Required', style: pw.TextStyle(fontSize: 9, color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
              const pw.TextSpan(text: '   ·   ', style: pw.TextStyle(fontSize: 9)),
              pw.TextSpan(text: '○ Optional / bring if available', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ]),
          ),
        ),
        pw.SizedBox(height: 10),
        ...kEnrollmentChecklistModules.map((m) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      alignment: pw.Alignment.center,
                      decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.deepPurple50),
                      child: pw.Text('${m.number}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accent)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(m.title, style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
                  ]),
                  pw.SizedBox(height: 4),
                  ...m.items.map((it) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(it.$2 ? '★' : '○',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    color: it.$2 ? PdfColors.red700 : PdfColors.grey500,
                                    fontWeight: it.$2 ? pw.FontWeight.bold : pw.FontWeight.normal)),
                            pw.SizedBox(width: 6),
                            pw.Expanded(child: pw.Text(it.$1, style: const pw.TextStyle(fontSize: 9.5))),
                          ],
                        ),
                      )),
                ],
              ),
            )),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'enrollment-checklist.pdf');
}
