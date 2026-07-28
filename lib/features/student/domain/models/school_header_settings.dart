import 'package:flutter/material.dart';

/// Mirrors `ConsentForm.tsx`'s `HeaderLayout` union exactly.
enum HeaderLayout { classic, centered, banner, minimal, letterhead }

HeaderLayout headerLayoutFromName(String? name) =>
    HeaderLayout.values.where((l) => l.name == name).firstOrNull ?? HeaderLayout.classic;

/// Mirrors `ConsentForm.tsx`'s `DEFAULT_DECLARATION` exactly.
const String kDefaultDeclaration =
    "I, the undersigned parent / legal guardian of {studentName}, hereby confirm that all information provided in "
    "this admission form is accurate and complete to the best of my knowledge. I consent to the school collecting, "
    "storing, and using the student's personal data exclusively for educational, administrative, and legally "
    "mandated purposes in accordance with the Digital Personal Data Protection Act, 2023. I understand that any "
    "withdrawal of consent must be submitted in writing to the school administration.";

/// Mirrors `ConsentForm.tsx`'s `SchoolHeaderData` interface — the school
/// branding shown on the Student Verification Form and persisted to the same
/// localStorage-equivalent key (`eskoolia:school:header:v2`) via
/// [SchoolHeaderStore]. `logoUrl` is dropped in favor of storing uploaded
/// image bytes directly (base64) since there is no browser `<input
/// type=url>` affordance on mobile — file upload is the only path here.
@immutable
class SchoolHeaderSettings {
  final String schoolName;
  final String schoolAddress;
  final String schoolPhone;
  final String schoolEmail;
  final String schoolWebsite;
  final String logoBase64;
  final String principalName;
  final String schoolMotto;
  final String affiliationNo;
  final String letterheadBase64;
  final HeaderLayout headerLayout;
  final int headerBgColor;
  final int headerTextColor;
  final String declarationText;

  const SchoolHeaderSettings({
    this.schoolName = 'Eskoolia School',
    this.schoolAddress = '123 School Lane, City — 000000',
    this.schoolPhone = '',
    this.schoolEmail = 'admissions@eskoolia.in',
    this.schoolWebsite = '',
    this.logoBase64 = '',
    this.principalName = 'Principal',
    this.schoolMotto = '',
    this.affiliationNo = '',
    this.letterheadBase64 = '',
    this.headerLayout = HeaderLayout.classic,
    this.headerBgColor = 0xFFFFFFFF,
    this.headerTextColor = 0xFF111827,
    this.declarationText = kDefaultDeclaration,
  });

  Color get bgColor => Color(headerBgColor);
  Color get textColor => Color(headerTextColor);

  SchoolHeaderSettings copyWith({
    String? schoolName,
    String? schoolAddress,
    String? schoolPhone,
    String? schoolEmail,
    String? schoolWebsite,
    String? logoBase64,
    String? principalName,
    String? schoolMotto,
    String? affiliationNo,
    String? letterheadBase64,
    HeaderLayout? headerLayout,
    int? headerBgColor,
    int? headerTextColor,
    String? declarationText,
  }) {
    return SchoolHeaderSettings(
      schoolName: schoolName ?? this.schoolName,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      schoolPhone: schoolPhone ?? this.schoolPhone,
      schoolEmail: schoolEmail ?? this.schoolEmail,
      schoolWebsite: schoolWebsite ?? this.schoolWebsite,
      logoBase64: logoBase64 ?? this.logoBase64,
      principalName: principalName ?? this.principalName,
      schoolMotto: schoolMotto ?? this.schoolMotto,
      affiliationNo: affiliationNo ?? this.affiliationNo,
      letterheadBase64: letterheadBase64 ?? this.letterheadBase64,
      headerLayout: headerLayout ?? this.headerLayout,
      headerBgColor: headerBgColor ?? this.headerBgColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      declarationText: declarationText ?? this.declarationText,
    );
  }

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'schoolAddress': schoolAddress,
        'schoolPhone': schoolPhone,
        'schoolEmail': schoolEmail,
        'schoolWebsite': schoolWebsite,
        'logoBase64': logoBase64,
        'principalName': principalName,
        'schoolMotto': schoolMotto,
        'affiliationNo': affiliationNo,
        'letterheadBase64': letterheadBase64,
        'headerLayout': headerLayout.name,
        'headerBgColor': headerBgColor,
        'headerTextColor': headerTextColor,
        'declarationText': declarationText,
      };

  factory SchoolHeaderSettings.fromJson(Map<String, dynamic> json) {
    const fallback = SchoolHeaderSettings();
    return SchoolHeaderSettings(
      schoolName: (json['schoolName'] as String?)?.trim().isNotEmpty == true ? json['schoolName'] as String : fallback.schoolName,
      schoolAddress: (json['schoolAddress'] as String?) ?? fallback.schoolAddress,
      schoolPhone: (json['schoolPhone'] as String?) ?? fallback.schoolPhone,
      schoolEmail: (json['schoolEmail'] as String?) ?? fallback.schoolEmail,
      schoolWebsite: (json['schoolWebsite'] as String?) ?? fallback.schoolWebsite,
      logoBase64: (json['logoBase64'] as String?) ?? '',
      principalName: (json['principalName'] as String?)?.trim().isNotEmpty == true ? json['principalName'] as String : fallback.principalName,
      schoolMotto: (json['schoolMotto'] as String?) ?? '',
      affiliationNo: (json['affiliationNo'] as String?) ?? '',
      letterheadBase64: (json['letterheadBase64'] as String?) ?? '',
      headerLayout: headerLayoutFromName(json['headerLayout'] as String?),
      headerBgColor: (json['headerBgColor'] as num?)?.toInt() ?? fallback.headerBgColor,
      headerTextColor: (json['headerTextColor'] as num?)?.toInt() ?? fallback.headerTextColor,
      declarationText: (json['declarationText'] as String?)?.trim().isNotEmpty == true ? json['declarationText'] as String : kDefaultDeclaration,
    );
  }
}
