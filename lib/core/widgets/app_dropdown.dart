import 'package:flutter/material.dart';

/// Reusable dropdown shell — the project-wide standard for every
/// select-style field. Every dropdown in the app (Student List/Enroll,
/// Role create/edit portal selects, Login Permission's role/status filters)
/// is built on this instead of a bare [DropdownButton]; any new screen
/// should follow the same pattern rather than reaching for [DropdownButton]
/// directly.
///
/// Why this exists: [DropdownButton]'s popup menu paints itself with
/// `dropdownColor ?? Theme.of(context).colorScheme.surface`. This app's
/// global [ThemeData] (`AppTheme.darkTheme`) is a dark theme, so an
/// unstyled DropdownButton's *closed* field can look right (callers draw
/// their own white box around it) while its *open* popup still renders in
/// the dark/near-black surface color — a real, user-visible bug distinct
/// from the field's own background. This widget hard-codes a white popup
/// (`dropdownColor: Colors.white`) so that can never happen again,
/// regardless of the surrounding theme.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?>? onChanged;

  /// Shown when [value] is null and no item in [items] has a matching null
  /// value — mirrors [DropdownButton.hint] (e.g. "Choose a relation…").
  final Widget? hint;
  final double height;
  final double fontSize;
  final Color textColor;
  final Color borderColor;
  final Color disabledBackground;
  final Color iconColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.height = 36,
    this.fontSize = 12,
    this.textColor = const Color(0xFF42455D),
    this.borderColor = const Color(0xFFDFE0EB),
    this.disabledBackground = const Color(0xFFF9FAFB),
    this.iconColor = const Color(0xFF8B8EA8),
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: disabled ? disabledBackground : Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: borderRadius,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T?>(
            isExpanded: true,
            value: value,
            items: items,
            onChanged: onChanged,
            hint: hint,
            dropdownColor: Colors.white,
            borderRadius: borderRadius,
            elevation: 3,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: iconColor),
            style: TextStyle(fontSize: fontSize, color: textColor),
          ),
        ),
      ),
    );
  }
}
