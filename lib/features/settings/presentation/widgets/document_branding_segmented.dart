import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A labeled N-way single-select segmented control — mirrors
/// `DocumentBrandingPanel.tsx`'s "Size" and "Logo" 3-way segmented rows
/// (the mobile equivalent of a `<select>`/radio-group rendered as
/// equal-width pill buttons).
class DocumentBrandingSegmented extends StatelessWidget {
  final String label;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String> onChanged;

  const DocumentBrandingSegmented({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              Expanded(child: _segment(options[i])),
              if (i != options.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  Widget _segment(MapEntry<String, String> option) {
    final selected = option.key == value;
    return InkWell(
      onTap: () => onChanged(option.key),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleAccent : AppColors.bgSecondary,
          border: Border.all(color: selected ? AppColors.purpleAccent : AppColors.borderSecondary),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          option.value,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}
