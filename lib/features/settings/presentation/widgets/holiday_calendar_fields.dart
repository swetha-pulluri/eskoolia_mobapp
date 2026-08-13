import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

/// Shared label style — mirrors `HolidaysPanel.tsx`'s `labelStyle`
/// (12.5px, 600 weight, `--ink-2`).
const TextStyle holidayLabelStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

InputBorder _holidayInputBorder(Color color) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color));

/// A labeled text input — mirrors `HolidayWizard`'s Name field styling.
class HolidayField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const HolidayField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<HolidayField> createState() => _HolidayFieldState();
}

class _HolidayFieldState extends State<HolidayField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant HolidayField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: holidayLabelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            filled: true,
            fillColor: AppColors.bgPrimary,
            border: _holidayInputBorder(AppColors.borderSecondary),
            enabledBorder: _holidayInputBorder(AppColors.borderSecondary),
            focusedBorder: _holidayInputBorder(AppColors.purpleAccent),
          ),
        ),
      ],
    );
  }
}

/// A date-picker field — the mobile equivalent of the web's
/// `<input type="date">`. Stores/sends ISO `yyyy-MM-dd` strings (matching
/// the backend contract exactly) but displays a friendlier `d MMM y` label,
/// since there's no native "browser date input" look to replicate on mobile.
class HolidayDateField extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String value;
  final String? minDate;
  final ValueChanged<String> onChanged;

  const HolidayDateField({
    super.key,
    required this.label,
    this.sublabel,
    required this.value,
    this.minDate,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final parsedValue = DateTime.tryParse(value);
    final parsedMin = minDate != null && minDate!.isNotEmpty ? DateTime.tryParse(minDate!) : null;
    final firstDate = parsedMin ?? DateTime(2015);
    final initialDate = parsedValue != null && !parsedValue.isBefore(firstDate) ? parsedValue : firstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onChanged(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(value);
    final display = parsed != null ? DateFormat('d MMM y').format(parsed) : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: holidayLabelStyle,
            children: [
              TextSpan(text: label),
              if (sublabel != null) TextSpan(text: ' $sublabel', style: const TextStyle(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: _holidayInputBorder(AppColors.borderSecondary),
              enabledBorder: _holidayInputBorder(AppColors.borderSecondary),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textTertiary),
            ),
            child: Text(
              display.isEmpty ? 'Select date' : display,
              style: TextStyle(fontSize: 14, color: display.isEmpty ? AppColors.textTertiary : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

/// A checkbox rendered as a full-width filled pill row — mirrors
/// `HolidayWizard`'s "Restricted" checkbox styling.
class HolidayCheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const HolidayCheckboxField({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.purpleAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
