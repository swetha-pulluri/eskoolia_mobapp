import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/models/school_header_settings.dart';
import '../utils/enrollment_pdf.dart';

/// The 10 numbered sections of the Student Verification Form — mirrors
/// `ConsentForm.tsx`'s `SECTION_LIST` exactly (id + display label), used for
/// both the AI panel's visibility toggles and the document's own section
/// gating.
const List<(String id, String label)> kVerificationSections = [
  ('identity', '1. Student Identity'),
  ('academic', '2. Academic Placement'),
  ('contact', '3. Contact & Address'),
  ('guardians', '4. Guardians'),
  ('govt', '5. Government Identity'),
  ('documents', '6. Documents Checklist'),
  ('medical', '7. Medical & Emergency'),
  ('pwd', '8. Specially Abled (PwD)'),
  ('marks', '9. Physical Identity Marks'),
  ('declaration', '10. Declaration'),
];

String _val(String v) => v.trim().isEmpty ? '—' : v.trim();

/// Renders the printable body of the Student Verification Form — school
/// header + 10 numbered sections + signature lines — mirrors
/// `ConsentForm.tsx`'s `.cf-body` block exactly (same section order, same
/// labels, same "—" placeholder for empty values). Reused for both the
/// on-screen preview and as the visual reference for the generated PDF (see
/// `printVerificationForm` in `enrollment_pdf.dart`).
class StudentVerificationDocument extends StatelessWidget {
  final EnrollmentPdfData data;
  final SchoolHeaderSettings header;
  final Color accentColor;
  final Set<String> hiddenSections;

  const StudentVerificationDocument({
    super.key,
    required this.data,
    required this.header,
    required this.accentColor,
    required this.hiddenSections,
  });

  bool _visible(String id) => !hiddenSections.contains(id);

  String get _fullName => [data.firstName, data.middleName, data.lastName].where((s) => s.trim().isNotEmpty).join(' ');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSchoolHeader(),
        const Divider(color: Color(0xFFE5E7EB), thickness: 2, height: 32),
        const Text(
          'STUDENT VERIFICATION FORM',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: 0.9),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please verify all details. Contact the school if any information is incorrect.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        if (_visible('identity')) _buildIdentitySection(),
        if (_visible('academic')) _buildAcademicSection(),
        if (_visible('contact')) _buildContactSection(),
        if (_visible('guardians')) _buildGuardiansSection(),
        if (_visible('govt')) _buildGovtSection(),
        if (_visible('documents')) _buildDocumentsSection(),
        if (_visible('medical')) _buildMedicalSection(),
        if (_visible('pwd')) _buildPwdSection(),
        if (_visible('marks')) _buildMarksSection(),
        if (_visible('declaration')) _buildDeclarationSection(),
        const SizedBox(height: 40),
        _buildSignatures(),
      ],
    );
  }

  Widget _sectionWrap(String id, String heading, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
            child: Text(
              heading,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: accentColor),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSchoolHeader() {
    if (header.headerLayout == HeaderLayout.letterhead && header.letterheadBase64.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(base64Decode(header.letterheadBase64), width: double.infinity, height: 120, fit: BoxFit.cover),
      );
    }

    final logo = header.headerLayout == HeaderLayout.minimal
        ? null
        : (header.logoBase64.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(base64Decode(header.logoBase64), width: 56, height: 56, fit: BoxFit.contain),
              )
            : Text('🏫', style: TextStyle(fontSize: 36, color: header.textColor)));

    final nameBlock = Column(
      crossAxisAlignment: header.headerLayout == HeaderLayout.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          header.schoolName,
          textAlign: header.headerLayout == HeaderLayout.centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: header.textColor),
        ),
        if (header.schoolMotto.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(header.schoolMotto, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: header.textColor.withValues(alpha: 0.75))),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              header.schoolAddress,
              if (header.schoolPhone.trim().isNotEmpty) header.schoolPhone,
              if (header.schoolEmail.trim().isNotEmpty) header.schoolEmail,
              if (header.affiliationNo.trim().isNotEmpty) 'Affil. No: ${header.affiliationNo}',
            ].where((s) => s.trim().isNotEmpty).join(' · '),
            textAlign: header.headerLayout == HeaderLayout.centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(fontSize: 12, color: header.textColor.withValues(alpha: 0.75)),
          ),
        ),
      ],
    );

    final content = header.headerLayout == HeaderLayout.centered
        ? Column(children: [if (logo != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: logo), nameBlock])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (logo != null) Padding(padding: const EdgeInsets.only(right: 14), child: logo),
              Expanded(child: nameBlock),
            ],
          );

    final isBanner = header.headerLayout == HeaderLayout.banner;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isBanner ? 20 : 14, vertical: isBanner ? 18 : 12),
      decoration: BoxDecoration(color: header.bgColor, borderRadius: BorderRadius.circular(isBanner ? 12 : 10)),
      child: content,
    );
  }

  Widget _buildIdentitySection() {
    return _sectionWrap(
      'identity',
      '1. Student Identity',
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          data.photoUrl != null && data.photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    data.photoUrl!,
                    width: 84,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _photoPlaceholder(),
                  ),
                )
              : _photoPlaceholder(),
          const SizedBox(width: 16),
          Expanded(
            child: _KvTable(rows: [
              ('Full Name', _fullName.isEmpty ? '—' : _fullName),
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
    );
  }

  Widget _photoPlaceholder() => Container(
        width: 84,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid), borderRadius: BorderRadius.circular(6)),
        child: const Text('Photo', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      );

  Widget _buildAcademicSection() {
    return _sectionWrap(
      'academic',
      '2. Academic Placement',
      _KvTable(rows: [
        ('Academic Year', _val(data.academicYearName)),
        ('Class & Section', data.className.isEmpty ? '—' : '${data.className}${data.sectionName.isNotEmpty ? ' – ${data.sectionName}' : ''}'),
        ('Admission Type', _val(data.admissionType)),
        ('Category', _val(data.categoryName)),
      ]),
    );
  }

  Widget _buildContactSection() {
    return _sectionWrap(
      'contact',
      '3. Contact & Address',
      _KvTable(rows: [
        ('Phone', _val(data.phone)),
        ('Email', _val(data.email)),
        ('Address', _val(data.addressLine)),
        ('City', _val(data.city)),
        ('District', _val(data.district)),
        ('State', _val(data.stateName)),
        ('Pincode', _val(data.pincode)),
      ]),
    );
  }

  Widget _buildGuardiansSection() {
    return _sectionWrap(
      'guardians',
      '4. Guardians',
      data.guardians.isEmpty
          ? const Text('No guardian details provided.', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.guardians
                  .map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (g.isPrimary)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(999)),
                                child: const Text('PRIMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                              ),
                            _KvTable(rows: [
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
    );
  }

  Widget _buildGovtSection() {
    return _sectionWrap(
      'govt',
      '5. Government Identity',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KvTable(rows: [('APAAR ID', data.apaarProvided ? 'On file' : 'Not provided')]),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), border: Border.all(color: const Color(0xFFF59E0B)), borderRadius: BorderRadius.circular(6)),
            child: const Text(
              '🔒 Aadhaar number and APAAR ID are encrypted and not displayed for security.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return _sectionWrap(
      'documents',
      '6. Documents Checklist',
      data.documents.isEmpty
          ? const Text('No documents uploaded yet.', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)))
          : _KvTable(rows: data.documents.map((d) => (d.$1, d.$2 ? '✓ Submitted' : '○ Pending')).toList()),
    );
  }

  Widget _buildMedicalSection() {
    return _sectionWrap(
      'medical',
      '7. Medical & Emergency',
      _KvTable(rows: [
        ('Allergies', _val(data.allergies)),
        ('Current Medications', _val(data.medications)),
        ('Emergency Contact', _val(data.emergencyContact)),
      ]),
    );
  }

  Widget _buildPwdSection() {
    return _sectionWrap(
      'pwd',
      '8. Specially Abled (PwD)',
      _KvTable(rows: [
        ('PwD Disclosure', data.isPwD ? 'Yes — disclosed' : 'Not Disclosed'),
        if (data.isPwD) ('Accommodation Notes', _val(data.pwdNotes)),
      ]),
    );
  }

  Widget _buildMarksSection() {
    return _sectionWrap(
      'marks',
      '9. Physical Identity Marks',
      _KvTable(rows: [
        ('Identity Mark 1', _val(data.identityMark1)),
        ('Identity Mark 2', _val(data.identityMark2)),
        ('Birthmark', _val(data.birthmark)),
      ]),
    );
  }

  Widget _buildDeclarationSection() {
    return _sectionWrap(
      'declaration',
      '10. Declaration',
      Text(
        header.declarationText.replaceAll('{studentName}', _fullName.isEmpty ? '_____________________________ (Student Name)' : _fullName),
        textAlign: TextAlign.justify,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151), height: 1.6),
      ),
    );
  }

  Widget _buildSignatures() {
    Widget sigBlock(String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: const Color(0xFF374151)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        );
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        SizedBox(width: 160, child: sigBlock('Guardian / Parent Signature')),
        SizedBox(width: 160, child: sigBlock('${header.principalName} / Authorised Signatory')),
        SizedBox(width: 160, child: sigBlock('Date')),
      ],
    );
  }
}

/// Two-column key/value table — mirrors `ConsentForm.tsx`'s `.cf-table`
/// (38% label column, hairline row dividers, `#6b7280` label / `#111827`
/// value colors) exactly.
class _KvTable extends StatelessWidget {
  final List<(String, String)> rows;
  const _KvTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: i < rows.length - 1 ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(rows[i].$1, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Text(rows[i].$2, style: const TextStyle(fontSize: 13.5, color: Color(0xFF111827))),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
