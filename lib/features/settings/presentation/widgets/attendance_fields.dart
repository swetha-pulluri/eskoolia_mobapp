import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';

/// Shared label style — mirrors `AttendanceRulesPanel.tsx`'s `labelStyle`
/// (12.5px, 600 weight, `--ink-2`), same as every other Settings screen.
const TextStyle attendanceLabelStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

InputBorder _attendanceInputBorder(Color color) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color));

InputDecoration _attendanceDecoration() => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      filled: true,
      fillColor: AppColors.bgPrimary,
      border: _attendanceInputBorder(AppColors.borderSecondary),
      enabledBorder: _attendanceInputBorder(AppColors.borderSecondary),
      focusedBorder: _attendanceInputBorder(AppColors.purpleAccent),
    );

enum AttendanceFieldKind { text, integer, decimal }

/// A labeled text/number input — mirrors `AttendanceWizard`'s plain
/// `<input>` fields (Policy Name, and every `type="number"` field: grace
/// periods, hours/multipliers as decimal strings, late-marks count, etc).
class AttendanceField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final AttendanceFieldKind kind;
  final bool autofocus;

  const AttendanceField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.kind = AttendanceFieldKind.text,
    this.autofocus = false,
  });

  @override
  State<AttendanceField> createState() => _AttendanceFieldState();
}

class _AttendanceFieldState extends State<AttendanceField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant AttendanceField oldWidget) {
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
        Text(widget.label, style: attendanceLabelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          keyboardType: switch (widget.kind) {
            AttendanceFieldKind.text => TextInputType.text,
            AttendanceFieldKind.integer => TextInputType.number,
            AttendanceFieldKind.decimal => const TextInputType.numberWithOptions(decimal: true),
          },
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: _attendanceDecoration(),
        ),
      ],
    );
  }
}

/// The Shift Start/End time picker — mirrors `<input type="time">`. Value
/// and output are both plain `"HH:MM"` strings.
class AttendanceTimeField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const AttendanceTimeField({super.key, required this.label, required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final parts = value.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: attendanceLabelStyle),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              border: Border.all(color: AppColors.borderSecondary),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A labeled dropdown over a fixed `(value,label)` option list — mirrors
/// `AttendanceWizard`'s `<select>` fields (LOP deduction unit, absence
/// alert "Notify").
class AttendanceSelectField extends StatelessWidget {
  final String label;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String> onChanged;

  const AttendanceSelectField({
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
        Text(label, style: attendanceLabelStyle),
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
            for (final option in options) DropdownMenuItem<String?>(value: option.key, child: Text(option.value)),
          ],
          onChanged: (v) => onChanged(v ?? options.first.key),
        ),
      ],
    );
  }
}

/// A checkbox rendered as a full-width filled pill row — mirrors
/// `AttendanceWizard`'s "Enable absence alerts" checkbox styling.
class AttendanceCheckboxField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AttendanceCheckboxField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.notifications_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}

/// A toggle-chip for the Applies-To (roles) and Weekly-Offs steps — mirrors
/// the web's checked/unchecked pill styling exactly (filled purple + check
/// icon when checked, [uncheckedIcon] + grey when not).
class AttendanceChip extends StatelessWidget {
  final String label;
  final bool checked;
  final IconData uncheckedIcon;
  final VoidCallback onTap;

  const AttendanceChip({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
    this.uncheckedIcon = Icons.circle_outlined,
  });

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
            Icon(checked ? Icons.check_circle : uncheckedIcon, size: 13, color: checked ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
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
