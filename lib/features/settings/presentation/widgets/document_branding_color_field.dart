import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../core/theme/app_colors.dart';

Color? _parseHex(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}

String _colorToHex(Color color) => '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

/// A tappable swatch (the closest mobile equivalent of the web's native
/// `<input type="color">`) + an uppercased hex text field kept in sync both
/// directions — mirrors `DocumentBrandingPanel.tsx`'s two color rows (Text
/// color / Accent). Same pattern as School Info's own brand-color field,
/// kept as a separate copy per the established per-feature self-contained
/// convention.
class DocumentBrandingColorField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const DocumentBrandingColorField({super.key, required this.label, required this.value, required this.onChanged});

  @override
  State<DocumentBrandingColorField> createState() => _DocumentBrandingColorFieldState();
}

class _DocumentBrandingColorFieldState extends State<DocumentBrandingColorField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant DocumentBrandingColorField oldWidget) {
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

  Color get _swatchColor => _parseHex(widget.value) ?? AppColors.purpleAccent;

  Future<void> _openPicker() async {
    Color picked = _swatchColor;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.label),
        content: SingleChildScrollView(
          child: ColorPicker(pickerColor: picked, enableAlpha: false, onColorChanged: (color) => picked = color),
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

  void _onHexTyped(String value) {
    widget.onChanged(value.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: [
            GestureDetector(
              onTap: _openPicker,
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: _swatchColor,
                  border: Border.all(color: AppColors.borderSecondary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onHexTyped,
                maxLength: 7,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  hintText: '#1A1A2E',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  filled: true,
                  fillColor: AppColors.bgPrimary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSecondary)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSecondary)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.purpleAccent)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
