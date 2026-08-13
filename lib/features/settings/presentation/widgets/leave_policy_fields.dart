import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/leave_policy_choices.dart';

/// Shared label style — mirrors `LeavePolicyPanel.tsx`'s `labelStyle`
/// (12.5px, 600 weight, `--ink-2`), identical to School Info's.
const TextStyle leavePolicyLabelStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

InputBorder _leaveInputBorder(Color color) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color));

/// A labeled text/number input — mirrors `renderField`'s number/text
/// branches (`inputStyle`: 1px `--bd-2` border, 10px radius, 9x11 padding).
/// Number fields always coerce to an int (default `0`), never `null` — this
/// screen's `POLICY_FIELDS` are plain `PositiveSmallIntegerField`s with a
/// `0` default, unlike School Info's nullable lat/lng quirk.
class LeavePolicyField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool multiline;
  final bool isNumber;
  final bool autofocus;

  const LeavePolicyField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.multiline = false,
    this.isNumber = false,
    this.autofocus = false,
  });

  @override
  State<LeavePolicyField> createState() => _LeavePolicyFieldState();
}

class _LeavePolicyFieldState extends State<LeavePolicyField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant LeavePolicyField oldWidget) {
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
        Text(widget.label, style: leavePolicyLabelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          minLines: widget.multiline ? 3 : 1,
          maxLines: widget.multiline ? 3 : 1,
          keyboardType: widget.isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            filled: true,
            fillColor: AppColors.bgPrimary,
            border: _leaveInputBorder(AppColors.borderSecondary),
            enabledBorder: _leaveInputBorder(AppColors.borderSecondary),
            focusedBorder: _leaveInputBorder(AppColors.purpleAccent),
          ),
        ),
      ],
    );
  }
}

/// A labeled dropdown over a fixed, capitalized `List<String>` of raw
/// values (e.g. `["limited","unlimited"]`) — mirrors `renderField`'s select
/// branch, which hardcodes its own tiny option lists inline.
class LeavePolicySelectField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const LeavePolicySelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final matchedValue = options.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: leavePolicyLabelStyle),
        const SizedBox(height: 6),
        AppDropdown<String>(
          value: matchedValue,
          height: 38,
          fontSize: 14,
          textColor: AppColors.textPrimary,
          borderColor: AppColors.borderSecondary,
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          items: [
            for (final option in options)
              DropdownMenuItem<String?>(
                value: option,
                child: Text(capitalize(option), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => onChanged(v ?? options.first),
        ),
      ],
    );
  }
}

/// A checkbox rendered as a full-width filled pill row — mirrors
/// `renderField`'s checkbox branch (`background: var(--bg-2)`, 10px radius,
/// 10x12 padding).
class LeavePolicyCheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LeavePolicyCheckboxField({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

/// A toggle-chip for the Eligibility step's department/designation/
/// employment-type multi-selects — mirrors the web's checked/unchecked
/// pill styling exactly (filled purple + check icon when checked).
class LeavePolicyPill extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const LeavePolicyPill({super.key, required this.label, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: checked ? AppColors.purpleAccent : AppColors.bgSecondary,
          border: Border.all(color: checked ? AppColors.purpleAccent : AppColors.borderSecondary),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checked) ...[
              const Icon(Icons.check_circle, size: 13, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: checked ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
