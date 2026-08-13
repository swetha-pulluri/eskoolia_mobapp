import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shared label style — mirrors `SchoolInfoPanel.tsx`'s `labelStyle`
/// (12.5px, 600 weight, `--ink-2`).
const TextStyle schoolInfoLabelStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

InputBorder _schoolInfoBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

/// A labeled text input — mirrors `SchoolInfoPanel.tsx`'s `Field` component
/// (`inputStyle`: 1px `--bd-2` border, 10px radius, 9x11 padding, 14px text).
///
/// Keeps its own [TextEditingController] rather than rebuilding from
/// [value] on every keystroke (the parent's Riverpod state updates on every
/// character) — only resyncs from an external value change (e.g. after a
/// server save/load) via [didUpdateWidget], so typing never fights the
/// cursor position.
class SchoolInfoField extends StatefulWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool multiline;
  final TextInputType? keyboardType;
  final String? placeholder;

  const SchoolInfoField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.multiline = false,
    this.keyboardType,
    this.placeholder,
  });

  @override
  State<SchoolInfoField> createState() => _SchoolInfoFieldState();
}

class _SchoolInfoFieldState extends State<SchoolInfoField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(covariant SchoolInfoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.value ?? '';
    if (incoming != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
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
        Text(widget.label, style: schoolInfoLabelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          minLines: widget.multiline ? 3 : 1,
          maxLines: widget.multiline ? 3 : 1,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.placeholder,
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            filled: true,
            fillColor: AppColors.bgPrimary,
            border: _schoolInfoBorder(AppColors.borderSecondary),
            enabledBorder: _schoolInfoBorder(AppColors.borderSecondary),
            focusedBorder: _schoolInfoBorder(AppColors.purpleAccent),
          ),
        ),
      ],
    );
  }
}
