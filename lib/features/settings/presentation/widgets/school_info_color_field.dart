import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../core/theme/app_colors.dart';
import 'school_info_field.dart';

Color? _parseHex(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}

String _colorToHex(Color color) => '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

/// Brand color field — mirrors `SchoolInfoPanel.tsx`'s Branding-step color
/// input: a tappable swatch (the closest mobile equivalent of the web's
/// native `<input type="color">`, which Flutter has no built-in widget for)
/// plus a hex text field, kept in sync both directions.
class SchoolInfoColorField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const SchoolInfoColorField({super.key, required this.value, required this.onChanged});

  @override
  State<SchoolInfoColorField> createState() => _SchoolInfoColorFieldState();
}

class _SchoolInfoColorFieldState extends State<SchoolInfoColorField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(covariant SchoolInfoColorField oldWidget) {
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

  Color get _swatchColor => _parseHex(widget.value ?? '') ?? AppColors.purpleAccent;

  Future<void> _openPicker() async {
    Color picked = _swatchColor;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Brand color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            enableAlpha: false,
            onColorChanged: (color) => picked = color,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              widget.onChanged(_colorToHex(picked));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Brand Color', style: schoolInfoLabelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            GestureDetector(
              onTap: _openPicker,
              child: Container(
                height: 38,
                width: 46,
                decoration: BoxDecoration(
                  color: _swatchColor,
                  border: Border.all(color: AppColors.borderSecondary),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '#6d4aff',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  filled: true,
                  fillColor: AppColors.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSecondary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSecondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.purpleAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
