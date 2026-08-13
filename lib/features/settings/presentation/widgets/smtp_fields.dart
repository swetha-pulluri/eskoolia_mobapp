import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';

/// Shared label style — mirrors `SmtpSettingsPanel.tsx`'s `labelStyle`
/// (12.5px, 600 weight, `--ink-2`), same as every other Settings screen.
const TextStyle smtpLabelStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

InputBorder _smtpInputBorder(Color color) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color));

InputDecoration _smtpDecoration({String? hintText}) => InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      filled: true,
      fillColor: AppColors.bgPrimary,
      border: _smtpInputBorder(AppColors.borderSecondary),
      enabledBorder: _smtpInputBorder(AppColors.borderSecondary),
      focusedBorder: _smtpInputBorder(AppColors.purpleAccent),
    );

/// A labeled text/number input — mirrors `SmtpWizard`'s plain `<input>`
/// fields (Config Name, Host, Port, Username, From/BCC Email, Sender Name).
class SmtpField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool isNumber;
  final bool autofocus;

  const SmtpField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isNumber = false,
    this.autofocus = false,
  });

  @override
  State<SmtpField> createState() => _SmtpFieldState();
}

class _SmtpFieldState extends State<SmtpField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant SmtpField oldWidget) {
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
        Text(widget.label, style: smtpLabelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          keyboardType: widget.isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: _smtpDecoration(),
        ),
      ],
    );
  }
}

/// The Password field — mirrors `SmtpWizard`'s `<input type="password">`
/// exactly: a plain obscured text field, no show/hide toggle (the web has
/// none either). [hint] renders the "(leave blank to keep current)" suffix
/// only while editing.
class SmtpPasswordField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;

  const SmtpPasswordField({super.key, required this.value, required this.onChanged, this.hint});

  @override
  State<SmtpPasswordField> createState() => _SmtpPasswordFieldState();
}

class _SmtpPasswordFieldState extends State<SmtpPasswordField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant SmtpPasswordField oldWidget) {
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
        RichText(
          text: TextSpan(
            style: smtpLabelStyle,
            children: [
              const TextSpan(text: 'Password'),
              if (widget.hint != null) TextSpan(text: ' ${widget.hint}', style: const TextStyle(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          obscureText: true,
          onChanged: widget.onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: _smtpDecoration(),
        ),
      ],
    );
  }
}

/// A labeled dropdown over a fixed `(value,label)` option list — mirrors
/// `SmtpWizard`'s `<select>` fields (Type, Priority, Receiver Email Type).
class SmtpSelectField extends StatelessWidget {
  final String label;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String> onChanged;

  const SmtpSelectField({
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
        Text(label, style: smtpLabelStyle),
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
/// `SmtpWizard`'s "Use TLS" checkbox styling.
class SmtpCheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SmtpCheckboxField({super.key, required this.label, required this.value, required this.onChanged});

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
