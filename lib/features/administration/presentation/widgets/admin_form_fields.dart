import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roles/presentation/widgets/add_role_card.dart' show DashedBorderPainter;

/// Shared Administration form field styling — a labeled text input with
/// an optional `*` required marker and inline error text, matching the
/// web panels' label+input+`<small class="form-error">` pattern.
class AdminTextField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hint;
  final String? helper;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  /// Live "{n} / {maxLength} ..." counter shown below the field — only
  /// the specific long-text fields that render one on web (e.g. Phone
  /// Calls' Description, Postal's Note) should set this.
  final String Function(int length)? counterBuilder;
  /// `false` renders a read-only, grey-filled field — matches web's
  /// `<input readOnly style={{ background: "#f9fafb" }} />` fallback
  /// (e.g. "All classes"/"All sections" on the Generate & Print screens).
  final bool enabled;

  const AdminTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.validator,
    this.hint,
    this.helper,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.counterBuilder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, required: required),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            enabled: enabled,
            decoration: _fieldDecoration(hint: hint).copyWith(
              fillColor: enabled ? Colors.white : const Color(0xFFF9FAFB),
            ),
          ),
          if (helper != null) _FieldHelper(text: helper!),
          if (counterBuilder != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => _FieldHelper(text: counterBuilder!(value.text.length)),
            ),
        ],
      ),
    );
  }
}

/// Shared Administration date field — opens a date picker, displays
/// `YYYY-MM-DD`, matching the web's native `<input type="date">`.
class AdminDateField extends StatelessWidget {
  final String label;
  final bool required;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? helper;
  final String? errorText;

  const AdminDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.firstDate,
    this.lastDate,
    this.helper,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, required: required),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2000),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked != null) onChanged(picked);
            },
            child: InputDecorator(
              decoration: _fieldDecoration(errorText: errorText).copyWith(
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                value == null ? 'Select date' : _fmt(value!),
                style: TextStyle(
                  fontSize: 14,
                  color: value == null ? AppColors.textTertiary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (helper != null) _FieldHelper(text: helper!),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Shared Administration time field — opens a time picker, displays
/// `HH:MM`, matching the web's native `<input type="time">`.
class AdminTimeField extends StatelessWidget {
  final String label;
  final bool required;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String? errorText;

  const AdminTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, required: required),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: value ?? TimeOfDay.now(),
              );
              if (picked != null) onChanged(picked);
            },
            child: InputDecorator(
              decoration: _fieldDecoration(errorText: errorText).copyWith(
                suffixIcon: const Icon(Icons.access_time, size: 18),
              ),
              child: Text(
                value == null ? 'Select time' : value!.format(context),
                style: TextStyle(
                  fontSize: 14,
                  color: value == null ? AppColors.textTertiary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared Administration dropdown field.
class AdminDropdownField<T> extends StatelessWidget {
  final String label;
  final bool required;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? helper;
  final String? errorText;

  const AdminDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.required = false,
    this.helper,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, required: required),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.textTertiary)),
            items: items,
            onChanged: onChanged,
            decoration: _fieldDecoration(errorText: errorText),
          ),
          if (helper != null) _FieldHelper(text: helper!),
        ],
      ),
    );
  }
}

/// Shared Administration file-attachment field — a plain
/// `<input type="file">` equivalent (Visitor Book has no label above it
/// on web, just the raw file input). Shows the picked file name once
/// chosen, or a placeholder prompt.
class AdminFileField extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;
  final String? errorText;
  final String placeholder;
  final String? helper;
  /// Optional field label rendered above the picker (e.g. Complaints'
  /// `<label htmlFor="c-attachment">Attachment</label>`). Every web panel
  /// with a file field (Complaints, Postal Receive/Dispatch, Visitor Book)
  /// actually renders a real `<label>Attachment</label>` above its
  /// `<input type="file">` — always pass this, don't omit it.
  final String? label;
  /// When editing a record that already has a saved file and no new file
  /// has been picked yet, shows a "View existing file" link above the
  /// picker (matches web's `{editingId && fileUrl && <a>View existing
  /// file</a>}`). Ignored when [previewBytes] or an image-capable
  /// [existingFileUrl] is shown inline instead (ID Card / Certificate).
  final String? existingFileUrl;
  /// Newly-picked image bytes to preview inline — matches web's
  /// `URL.createObjectURL(file)` live thumbnail (`IdCardPanel.tsx`).
  final Uint8List? previewBytes;
  /// True when [existingFileUrl] should be rendered as an inline image
  /// thumbnail (with a "Current image · click to replace" caption)
  /// instead of a plain "View existing file" link.
  final bool previewExistingAsImage;
  /// Web's `.file-upload-area` style (`IdCardPanel.tsx` / `CertificatePanel
  /// .tsx` only — Complaints/Visitor Book/Postal Receive/Dispatch all use a
  /// plain native `<input type="file">` with no drag-and-drop styling, so
  /// this defaults to `false` and those screens are unaffected): a dashed,
  /// generously-padded drop zone with the generic "Click to upload or drag
  /// and drop" + file-type/size hint, instead of a single-line bordered
  /// field. When true, [placeholder] is that hint text (e.g. "PNG, JPG (max
  /// 2MB)") — the field's own name belongs in [label] above the box, not
  /// baked into this hint, matching how web separates the two.
  final bool dashedDropZone;

  const AdminFileField({
    super.key,
    required this.fileName,
    required this.onTap,
    this.errorText,
    this.placeholder = 'Choose file',
    this.helper,
    this.existingFileUrl,
    this.previewBytes,
    this.previewExistingAsImage = false,
    this.label,
    this.dashedDropZone = false,
  });

  @override
  Widget build(BuildContext context) {
    final showImagePreview = previewBytes != null || (previewExistingAsImage && existingFileUrl != null && existingFileUrl!.isNotEmpty);
    final dropZoneColor = errorText != null ? AppColors.dangerRed : AppColors.dashedBorder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) _FieldLabel(label: label!, required: false),
          if (label != null) const SizedBox(height: 6),
          if (!showImagePreview && fileName == null && existingFileUrl != null && existingFileUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () => launchUrl(Uri.parse(existingFileUrl!), mode: LaunchMode.externalApplication),
                child: const Text(
                  'View existing file',
                  style: TextStyle(fontSize: 12.5, color: AppColors.primaryPurple, decoration: TextDecoration.underline),
                ),
              ),
            ),
          InkWell(
            onTap: onTap,
            child: dashedDropZone
                ? CustomPaint(
                    painter: DashedBorderPainter(color: dropZoneColor, strokeWidth: 1.5, dashLength: 5, gapLength: 4, borderRadius: 8),
                    child: showImagePreview
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: previewBytes != null
                                      ? Image.memory(previewBytes!, height: 80, fit: BoxFit.contain)
                                      : Image.network(existingFileUrl!, height: 80, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, size: 32, color: AppColors.textTertiary)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fileName ?? 'Current image · click to replace',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: 'Click to upload', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
                                      TextSpan(text: fileName != null ? ' — $fileName' : ' or drag and drop'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(placeholder, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                  )
                : showImagePreview
                ? Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: errorText != null ? AppColors.dangerRed : AppColors.borderPrimary),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: previewBytes != null
                              ? Image.memory(previewBytes!, height: 70, fit: BoxFit.contain)
                              : Image.network(existingFileUrl!, height: 70, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, size: 32, color: AppColors.textTertiary)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fileName ?? 'Current image · click to replace',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : InputDecorator(
                    decoration: _fieldDecoration(errorText: errorText).copyWith(
                      prefixIcon: const Icon(Icons.attach_file, size: 18),
                    ),
                    child: Text(
                      fileName ?? placeholder,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: fileName == null ? AppColors.textTertiary : AppColors.textPrimary,
                      ),
                    ),
                  ),
          ),
          if (helper != null) _FieldHelper(text: helper!),
        ],
      ),
    );
  }
}

/// Plain label matching the web's `<label>Name *</label>` — the `*` is
/// literal text in the same label color, not a colored marker.
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Text(
      required ? '$label *' : label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }
}

class _FieldHelper extends StatelessWidget {
  final String text;
  const _FieldHelper({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
    );
  }
}

InputDecoration _fieldDecoration({String? hint, String? errorText}) {
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    // Web never shows a live character count on single-line fields (only
    // on the specific long-text fields that explicitly render one, which
    // AdminTextField's `showCounter` handles separately) — suppress
    // Flutter's automatic `maxLength` counter everywhere else.
    counterText: '',
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderPrimary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.borderPrimary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryPurple),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.dangerRed),
    ),
  );
}
