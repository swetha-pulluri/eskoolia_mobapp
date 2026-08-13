/// Settings → Document Branding: the single per-school
/// `DocumentBrandingSettings` row. Reference: backend/apps/settings/
/// models.py::DocumentBrandingSettings,
/// serializers.py::DocumentBrandingSettingsSerializer,
/// frontend/components/settings/DocumentBrandingPanel.tsx.
///
/// Unlike School Info's logo, the letterhead/rendered image has NO url
/// field on this serializer at all — it's only ever fetched via the
/// separate binary `header-image/` and `preview/` endpoints (confirmed in
/// the serializer's own docstring). `letterheadFileName` is just the
/// basename, for display only.
class DocumentBrandingEntity {
  final int id;
  final String headerMode; // 'generated' | 'uploaded'
  final String headerStyle; // classic | modern | minimal | executive | letterpress | banner
  final String headerTextColor;
  final String accentColor;
  final String headerSize; // compact | standard | tall
  final String logoPosition; // left | center | right
  final bool showDivider;
  final String dividerStyle; // none | solid | double | dashed | thick_rule
  final bool showWatermark;
  final String watermarkText;
  final bool showLogo;
  final String? letterheadSourceFileType; // pdf | image
  final String? letterheadFileName;

  final String declarationStudentVerification;
  final String declarationStaffOnboarding;
  final String declarationPayslip;
  final String declarationFeeReceipt;
  final String declarationTransferCertificate;
  final String declarationAdmission;

  final String? updatedByName;
  final String? updatedAt;
  final String? createdAt;

  const DocumentBrandingEntity({
    required this.id,
    required this.headerMode,
    required this.headerStyle,
    required this.headerTextColor,
    required this.accentColor,
    required this.headerSize,
    required this.logoPosition,
    required this.showDivider,
    required this.dividerStyle,
    required this.showWatermark,
    required this.watermarkText,
    required this.showLogo,
    required this.letterheadSourceFileType,
    required this.letterheadFileName,
    required this.declarationStudentVerification,
    required this.declarationStaffOnboarding,
    required this.declarationPayslip,
    required this.declarationFeeReceipt,
    required this.declarationTransferCertificate,
    required this.declarationAdmission,
    required this.updatedByName,
    required this.updatedAt,
    required this.createdAt,
  });

  static bool _bool(Map<String, dynamic> json, String key, {bool fallback = false}) =>
      json[key] as bool? ?? fallback;
  static String _str(Map<String, dynamic> json, String key, {String fallback = ''}) =>
      json[key] as String? ?? fallback;

  factory DocumentBrandingEntity.fromJson(Map<String, dynamic> json) {
    return DocumentBrandingEntity(
      id: json['id'] as int,
      headerMode: _str(json, 'header_mode', fallback: 'generated'),
      headerStyle: _str(json, 'header_style', fallback: 'classic'),
      headerTextColor: _str(json, 'header_text_color', fallback: '#1A1A2E'),
      accentColor: _str(json, 'accent_color', fallback: '#1A1A2E'),
      headerSize: _str(json, 'header_size', fallback: 'standard'),
      logoPosition: _str(json, 'logo_position', fallback: 'center'),
      showDivider: _bool(json, 'show_divider', fallback: true),
      dividerStyle: _str(json, 'divider_style', fallback: 'solid'),
      showWatermark: _bool(json, 'show_watermark'),
      watermarkText: _str(json, 'watermark_text'),
      showLogo: _bool(json, 'show_logo', fallback: true),
      letterheadSourceFileType: json['letterhead_source_file_type'] as String?,
      letterheadFileName: json['letterhead_file_name'] as String?,
      declarationStudentVerification: _str(json, 'declaration_student_verification'),
      declarationStaffOnboarding: _str(json, 'declaration_staff_onboarding'),
      declarationPayslip: _str(json, 'declaration_payslip'),
      declarationFeeReceipt: _str(json, 'declaration_fee_receipt'),
      declarationTransferCertificate: _str(json, 'declaration_transfer_certificate'),
      declarationAdmission: _str(json, 'declaration_admission'),
      updatedByName: json['updated_by_name'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  /// Seeds the editable `draft` — mirrors the web's `setForm(settings)` on
  /// load. Every key here is a client-writable field on the serializer.
  Map<String, dynamic> toFormMap() {
    return {
      'header_mode': headerMode,
      'header_style': headerStyle,
      'header_text_color': headerTextColor,
      'accent_color': accentColor,
      'header_size': headerSize,
      'logo_position': logoPosition,
      'show_divider': showDivider,
      'divider_style': dividerStyle,
      'show_watermark': showWatermark,
      'watermark_text': watermarkText,
      'show_logo': showLogo,
      'declaration_student_verification': declarationStudentVerification,
      'declaration_staff_onboarding': declarationStaffOnboarding,
      'declaration_payslip': declarationPayslip,
      'declaration_fee_receipt': declarationFeeReceipt,
      'declaration_transfer_certificate': declarationTransferCertificate,
      'declaration_admission': declarationAdmission,
    };
  }
}

/// The 6 style-relevant fields sent to the transient `preview/` endpoint —
/// mirrors the web's debounced-preview field list exactly (everything
/// EXCEPT `header_mode` and the 6 `declaration_*` fields, which never
/// affect the rendered header image).
const List<String> documentBrandingPreviewFields = [
  'header_style',
  'header_text_color',
  'accent_color',
  'header_size',
  'logo_position',
  'show_divider',
  'divider_style',
  'show_watermark',
  'watermark_text',
  'show_logo',
];

/// Mirrors `STYLE_OPTIONS` in `DocumentBrandingPanel.tsx` exactly.
const List<({String value, String label, String hint})> documentBrandingHeaderStyles = [
  (value: 'classic', label: 'Classic', hint: 'Centered logo, name, address stack'),
  (value: 'modern', label: 'Modern', hint: 'Left logo, left-aligned detail column'),
  (value: 'minimal', label: 'Minimal', hint: 'Inline logo + single compact line'),
  (value: 'executive', label: 'Executive', hint: 'Logo | vertical rule | bold name + details'),
  (value: 'letterpress', label: 'Letterpress', hint: 'Double border rules top & bottom, centered'),
  (value: 'banner', label: 'Banner', hint: 'Solid dark band with white text, detail strip'),
];

const List<MapEntry<String, String>> documentBrandingHeaderSizes = [
  MapEntry('compact', 'Compact'),
  MapEntry('standard', 'Standard'),
  MapEntry('tall', 'Tall'),
];

const List<MapEntry<String, String>> documentBrandingLogoPositions = [
  MapEntry('left', 'Left'),
  MapEntry('center', 'Center'),
  MapEntry('right', 'Right'),
];

const List<MapEntry<String, String>> documentBrandingDividerStyles = [
  MapEntry('none', 'None'),
  MapEntry('solid', 'Solid'),
  MapEntry('double', 'Double'),
  MapEntry('dashed', 'Dashed'),
  MapEntry('thick_rule', 'Thick rule'),
];

/// Mirrors `DECLARATION_FIELDS` in `DocumentBrandingPanel.tsx` exactly.
const List<({String key, String label, String placeholder})> documentBrandingDeclarationFields = [
  (
    key: 'declaration_student_verification',
    label: 'Student Verification',
    placeholder: 'I/We, parent/guardian of {studentName}, declare the above information is true and correct.',
  ),
  (
    key: 'declaration_staff_onboarding',
    label: 'Staff Onboarding',
    placeholder: "Use {staffName} to insert the staff member's name automatically.",
  ),
  (key: 'declaration_payslip', label: 'Payslip', placeholder: 'Shown at the bottom of every payslip.'),
  (
    key: 'declaration_fee_receipt',
    label: 'Fee Receipt',
    placeholder: 'This receipt is computer generated. No signature required.',
  ),
  (
    key: 'declaration_transfer_certificate',
    label: 'Transfer Certificate',
    placeholder: 'Certified that the above information is correct as per school records.',
  ),
  (
    key: 'declaration_admission',
    label: 'Admission Form',
    placeholder: 'I hereby declare that the information furnished above is true, complete and correct.',
  ),
];
