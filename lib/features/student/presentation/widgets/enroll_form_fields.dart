import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';

/// Shared field-building blocks for the Enroll form's 11 sections — mirrors
/// frontend StudentAddPanel.tsx's `.field-label` / `.field-input` /
/// `.field-select` / `.grid-3` / `.grid-2` / required-asterisk / badge chip
/// styling, factored out once instead of repeating it in every section.
///
/// Mobile adaptation (disclosed): `.grid-3`/`.grid-2` are desktop-width
/// field grids; on a phone they'd force unreadably narrow fields, so
/// [EnrollFieldGrid] stacks to a single column below 480px and 2 columns
/// above it, never 3 — the same class of width-based reflow already used
/// for the stats grids elsewhere in this app, not an invented layout.
class EnrollFieldGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;

  const EnrollFieldGrid({super.key, required this.children, this.maxColumns = 2});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 480 ? 1 : maxColumns;
        if (columns == 1) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last) const SizedBox(height: 16),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children.map((child) {
            final width = (constraints.maxWidth - (16 * (columns - 1))) / columns;
            return SizedBox(width: width, child: child);
          }).toList(),
        );
      },
    );
  }
}

enum EnrollBadge { required, recommended, optional, goi, sensitive }

class EnrollLabel extends StatelessWidget {
  final String label;
  final EnrollBadge? badge;

  const EnrollLabel(this.label, {super.key, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.studentFieldLabel,
              ),
            ),
          ),
          if (badge == EnrollBadge.required) ...[
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.studentRequiredMark,
              ),
            ),
          ],
          if (badge != null && badge != EnrollBadge.required) ...[
            const SizedBox(width: 6),
            _buildBadgeChip(badge!),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeChip(EnrollBadge badge) {
    final (bg, text, label) = switch (badge) {
      EnrollBadge.recommended => (AppColors.studentRecommendedBg, AppColors.studentRecommendedText, 'RECOMMENDED'),
      EnrollBadge.optional => (AppColors.studentOptionalBg, AppColors.studentOptionalText, 'OPTIONAL'),
      EnrollBadge.goi => (AppColors.studentEnrollBrand.withValues(alpha: 0.12), AppColors.studentEnrollBrand, 'GOI'),
      EnrollBadge.sensitive => (const Color(0xFFFEF2F2), const Color(0xFFDC2626), 'SENSITIVE'),
      EnrollBadge.required => (Colors.transparent, Colors.transparent, ''),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: text, letterSpacing: 0.3),
      ),
    );
  }
}

class EnrollTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final EnrollBadge? badge;
  final String? hint;
  final String? helpText;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const EnrollTextField({
    super.key,
    required this.label,
    required this.controller,
    this.badge,
    this.hint,
    this.helpText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EnrollLabel(label, badge: badge),
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.studentEnrollInk),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            filled: readOnly || !enabled,
            fillColor: const Color(0xFFF9FAFB),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.studentFieldErrorBorder : AppColors.studentFieldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.studentFieldErrorBorder : AppColors.studentEnrollBrand,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
        ] else if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(helpText!, style: const TextStyle(fontSize: 12, color: AppColors.studentHelpText)),
        ],
      ],
    );
  }
}

class EnrollDropdown<T> extends StatelessWidget {
  final String label;
  final EnrollBadge? badge;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? helpText;

  const EnrollDropdown({
    super.key,
    required this.label,
    this.badge,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EnrollLabel(label, badge: badge),
        AppDropdown<T>(
          value: value,
          items: items.map((item) => DropdownMenuItem<T?>(value: item.value, child: item.child)).toList(),
          onChanged: onChanged,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          height: 42,
          fontSize: 14,
          textColor: AppColors.studentEnrollInk,
          borderColor: AppColors.studentFieldBorder,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(helpText!, style: const TextStyle(fontSize: 12, color: AppColors.studentHelpText)),
        ],
      ],
    );
  }
}

class EnrollToggle extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const EnrollToggle({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.studentFieldLabel,
                    ),
                  ),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        description!,
                        style: const TextStyle(fontSize: 12, color: AppColors.studentHelpText),
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.studentEnrollBrand,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section card shell used by every step — mirrors `.section-card`.
class EnrollSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int stepNumber;
  final Widget child;
  final Widget navButtons;

  const EnrollSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stepNumber,
    required this.child,
    required this.navButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.studentEnrollLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.studentEnrollInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.studentEnrollMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '$stepNumber / 11',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 20),
          navButtons,
        ],
      ),
    );
  }
}
