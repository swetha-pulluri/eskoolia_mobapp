import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../administration/domain/entities/picked_attachment.dart';
import '../../domain/entities/policy_document_entity.dart';
import 'document_card.dart' show formatFileSize;

/// Shared label style — mirrors `DocumentsPanel.tsx`'s `labelStyle`
/// (12.5px, 600 weight, `--ink-2`), same as every other Settings screen.
const TextStyle documentLabelStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

InputBorder _documentInputBorder(Color color) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color));

InputDecoration _documentDecoration() => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      filled: true,
      fillColor: AppColors.bgPrimary,
      border: _documentInputBorder(AppColors.borderSecondary),
      enabledBorder: _documentInputBorder(AppColors.borderSecondary),
      focusedBorder: _documentInputBorder(AppColors.purpleAccent),
    );

/// The Title text input — mirrors `DocumentWizard`'s plain `<input>`.
class DocumentField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const DocumentField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<DocumentField> createState() => _DocumentFieldState();
}

class _DocumentFieldState extends State<DocumentField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant DocumentField oldWidget) {
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
        Text(widget.label, style: documentLabelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: _documentDecoration(),
        ),
      ],
    );
  }
}

/// The Upload step's file picker — mirrors `DocumentWizard`'s plain
/// `<input type="file">` (no drag-and-drop zone, no extension filter on the
/// web input itself — the server validates MIME type instead, so this
/// doesn't restrict [FilePicker] to specific extensions either).
class DocumentFilePickerField extends StatelessWidget {
  final PickedAttachment? file;
  final ValueChanged<PickedAttachment?> onChanged;

  const DocumentFilePickerField({super.key, required this.file, required this.onChanged});

  Future<void> _pick() async {
    final result = await FilePicker.pickFiles(withData: true);
    final picked = result?.files.singleOrNull;
    if (picked == null || picked.bytes == null) return;
    onChanged(PickedAttachment(name: picked.name, bytes: picked.bytes!, size: picked.size));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PDF, JPEG or PNG, up to 25MB.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.upload_file_outlined, size: 15),
          label: const Text('Choose File'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purpleAccent,
            side: const BorderSide(color: AppColors.purpleSoft),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              children: [
                const TextSpan(text: 'Selected: '),
                TextSpan(text: file!.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                TextSpan(text: ' (${formatFileSize(file!.size)})'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The Category dropdown — mirrors `DocumentWizard`'s `<select>`, options
/// from the fixed `policyDocumentCategories` enum.
class DocumentCategoryField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const DocumentCategoryField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final matchedValue = policyDocumentCategories.any((o) => o.key == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: documentLabelStyle),
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
            for (final option in policyDocumentCategories) DropdownMenuItem<String?>(value: option.key, child: Text(option.value)),
          ],
          onChanged: (v) => onChanged(v ?? policyDocumentCategories.last.key),
        ),
      ],
    );
  }
}
