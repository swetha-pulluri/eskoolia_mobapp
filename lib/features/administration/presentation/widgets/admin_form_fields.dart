import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

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

  const AdminFileField({
    super.key,
    required this.fileName,
    required this.onTap,
    this.errorText,
    this.placeholder = 'Choose file',
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: InputDecorator(
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

/// Shared Administration radio group (e.g. Incoming/Outgoing call type).
class AdminRadioGroup<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<(T value, String label)> options;
  final ValueChanged<T?> onChanged;

  const AdminRadioGroup({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, required: false),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            children: options.map((opt) {
              return InkWell(
                onTap: () => onChanged(opt.$1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<T>(value: opt.$1, groupValue: value, onChanged: onChanged),
                    Text(opt.$2, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  ],
                ),
              );
            }).toList(),
          ),
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
