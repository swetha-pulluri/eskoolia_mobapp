import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import 'school_info_field.dart';

String _mimeTypeOf(String filename) => filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

/// Logo upload field — mirrors `SchoolInfoPanel.tsx`'s Branding-step logo
/// picker: a 56x56 preview box, an "Upload Logo" button, and inline
/// size/type validation errors. `image_picker`'s gallery source is the
/// mobile equivalent of the web's hidden `<input type="file">`.
class SchoolInfoLogoField extends ConsumerWidget {
  const SchoolInfoLogoField({super.key});

  Future<void> _pick(WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final filename = picked.name.isNotEmpty ? picked.name : 'logo.jpg';
    await ref.read(schoolInfoNotifierProvider.notifier).uploadLogo(bytes, filename, _mimeTypeOf(filename));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolInfoNotifierProvider);
    final bytes = state.logoBytes;
    final logoUrl = state.info?.logoUrl;
    final hasRemote = logoUrl != null && logoUrl.isNotEmpty;
    final absoluteUrl = hasRemote ? (logoUrl.startsWith('http') ? logoUrl : '${ApiConstants.baseUrl}$logoUrl') : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logo', style: schoolInfoLabelStyle),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSecondary),
                color: AppColors.bgSecondary,
              ),
              child: bytes != null
                  ? Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain)
                  : (absoluteUrl != null
                      ? Image.network(
                          absoluteUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.business_outlined, size: 20, color: AppColors.textTertiary),
                        )
                      : const Icon(Icons.business_outlined, size: 20, color: AppColors.textTertiary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: state.logoUploading ? null : () => _pick(ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purpleAccent,
                      side: const BorderSide(color: AppColors.purpleSoft),
                      backgroundColor: AppColors.bgPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: state.logoUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleAccent),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 14),
                    label: Text(
                      state.logoUploading ? 'Uploading…' : 'Upload Logo',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('JPG or PNG, up to 2MB.', style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                  if (state.logoError != null) ...[
                    const SizedBox(height: 4),
                    Text(state.logoError!, style: const TextStyle(fontSize: 11.5, color: AppColors.dangerRed)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
