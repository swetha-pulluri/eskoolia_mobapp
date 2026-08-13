import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import 'school_info_field.dart';

/// A labeled dropdown — mirrors `SchoolInfoPanel.tsx`'s `SelectField`
/// component. Built on [AppDropdown], the project-wide standard for every
/// select-style field (see its own doc comment for why a bare
/// [DropdownButton] isn't used directly).
class SchoolInfoSelectField extends StatelessWidget {
  final String label;
  final String? value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String?> onChanged;

  const SchoolInfoSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final matchedValue = options.any((o) => o.key == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: schoolInfoLabelStyle),
        const SizedBox(height: 6),
        AppDropdown<String>(
          value: matchedValue,
          height: 38,
          fontSize: 14,
          textColor: AppColors.textPrimary,
          borderColor: AppColors.borderSecondary,
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          hint: const Text('— Select —', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
          items: [
            for (final option in options)
              DropdownMenuItem<String?>(
                value: option.key,
                // `maxLines`/`overflow` keep a long option label (e.g. a
                // full board or state name) from wrapping onto a second
                // line and overflowing the dropdown's fixed-height box.
                child: Text(option.value, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
