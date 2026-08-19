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
        // The picker's natural height (square + slider row + RGB row) can
        // exceed a phone's available height once the dialog's own title,
        // padding and action buttons are added — bounding it to a fraction
        // of screen height and scrolling internally keeps Cancel/Select
        // reachable on screen instead of being pushed off the bottom.
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.5),
          child: SingleChildScrollView(
            child: _NativeStyleColorPicker(
              initialColor: picked,
              onChanged: (color) => picked = color,
            ),
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

/// Composed from the same package pieces `ColorPicker` uses internally
/// (`ColorPickerArea`, `ColorPickerSlider`, `ColorIndicator` — all publicly
/// exported by `flutter_colorpicker`), arranged to match the OS-native
/// `<input type="color">` picker the web's own Brand Color field opens:
/// a saturation/value square, a swatch + hue slider row, then editable R/G/B
/// fields. The package's stock `ColorPicker` widget instead defaults to
/// read-only RGB/HSV/HSL labels with a mode dropdown, which doesn't match.
/// There's no eyedropper here — the OS picker's eyedropper samples pixels
/// anywhere on the user's screen, a desktop-browser capability with no
/// mobile-app equivalent.
class _NativeStyleColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onChanged;

  const _NativeStyleColorPicker({required this.initialColor, required this.onChanged});

  @override
  State<_NativeStyleColorPicker> createState() => _NativeStyleColorPickerState();
}

class _NativeStyleColorPickerState extends State<_NativeStyleColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initialColor);
  late final _rController = TextEditingController(text: '${_hsv.toColor().toARGB32() >> 16 & 0xFF}');
  late final _gController = TextEditingController(text: '${_hsv.toColor().toARGB32() >> 8 & 0xFF}');
  late final _bController = TextEditingController(text: '${_hsv.toColor().toARGB32() & 0xFF}');

  @override
  void dispose() {
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    super.dispose();
  }

  void _update(HSVColor next) {
    setState(() => _hsv = next);
    final color = next.toColor();
    widget.onChanged(color);
    final argb = color.toARGB32();
    _rController.text = '${argb >> 16 & 0xFF}';
    _gController.text = '${argb >> 8 & 0xFF}';
    _bController.text = '${argb & 0xFF}';
  }

  void _onRgbTyped({int? r, int? g, int? b}) {
    final argb = _hsv.toColor().toARGB32();
    final newColor = Color.fromARGB(255, r ?? (argb >> 16 & 0xFF), g ?? (argb >> 8 & 0xFF), b ?? (argb & 0xFF));
    setState(() => _hsv = HSVColor.fromColor(newColor));
    widget.onChanged(newColor);
  }

  Widget _rgbField(String label, TextEditingController controller, ValueChanged<int> onTyped) {
    return Column(
      children: [
        SizedBox(
          width: 56,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) onTyped(parsed.clamp(0, 255));
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 180, width: 180, child: ColorPickerArea(_hsv, _update, PaletteType.hsvWithHue)),
          const SizedBox(height: 12),
          Row(
            children: [
              ColorIndicator(_hsv, width: 30, height: 30),
              const SizedBox(width: 10),
              Expanded(child: SizedBox(height: 30, child: ColorPickerSlider(TrackType.hue, _hsv, _update))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rgbField('R', _rController, (v) => _onRgbTyped(r: v)),
              _rgbField('G', _gController, (v) => _onRgbTyped(g: v)),
              _rgbField('B', _bController, (v) => _onRgbTyped(b: v)),
            ],
          ),
        ],
      ),
    );
  }
}
