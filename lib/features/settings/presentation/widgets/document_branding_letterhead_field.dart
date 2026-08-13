import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../administration/domain/entities/picked_attachment.dart';

/// Reverse of `DocumentBrandingUploadLetterheadView.ALLOWED_CONTENT_TYPES` —
/// the web sets an explicit `accept="application/pdf,image/jpeg,image/png"`
/// on its file input, so this restricts to the same 3 extensions rather
/// than the broader set Documents' own upload allows.
const Map<String, String> _extensionToMime = {
  'pdf': 'application/pdf',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
};

/// The Upload-letterhead dropzone — mirrors `DocumentBrandingPanel.tsx`'s
/// upload control (there's no real drag-and-drop surface on mobile, so this
/// is the plain tap-to-pick equivalent, same adaptation already used for
/// Documents' own file field).
class DocumentBrandingLetterheadField extends StatelessWidget {
  final String? existingFileName;
  final bool uploading;
  final void Function(PickedAttachment file, String mimeType) onPicked;

  const DocumentBrandingLetterheadField({
    super.key,
    required this.existingFileName,
    required this.uploading,
    required this.onPicked,
  });

  Future<void> _pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensionToMime.keys.toList(),
      withData: true,
    );
    final picked = result?.files.singleOrNull;
    if (picked == null || picked.bytes == null) return;
    final ext = picked.extension?.toLowerCase() ?? '';
    final mime = _extensionToMime[ext];
    if (mime == null) return;
    onPicked(PickedAttachment(name: picked.name, bytes: picked.bytes!, size: picked.size), mime);
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = existingFileName != null && existingFileName!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PDF · JPEG · PNG · max 5 MB', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: uploading ? null : _pick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSecondary, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.bgSecondary,
            ),
            child: Column(
              children: [
                if (uploading)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleAccent))
                else
                  const Icon(Icons.cloud_upload_outlined, size: 20, color: AppColors.purpleAccent),
                const SizedBox(height: 8),
                Text(
                  uploading ? 'Uploading…' : (hasExisting ? 'Replace letterhead' : 'Upload letterhead'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.purpleAccent),
                ),
                if (hasExisting && !uploading) ...[
                  const SizedBox(height: 4),
                  Text('"$existingFileName"', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
