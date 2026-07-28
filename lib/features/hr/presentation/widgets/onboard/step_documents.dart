import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../administration/domain/entities/picked_attachment.dart';
import '../../../domain/repositories/hr_repository.dart';
import '../../providers/hr_provider.dart';
import '../hr_theme.dart';
import 'onboard_field_widgets.dart';

/// Matches the real web's `ALL_DOCS` checklist exactly (14 items, only
/// `signature`/`aadhaar` in `MANDATORY_DOC_KEYS`).
const _allDocs = [
  ('signature', 'Signature', true),
  ('aadhaar', 'Aadhaar Card', true),
  ('pan', 'PAN Card', false),
  ('passport_photo', 'Passport Photo', false),
  ('bank_proof', 'Bank Proof', false),
  ('address_proof', 'Address Proof', false),
  ('tenth_marksheet', '10th Marksheet', false),
  ('twelfth_marksheet', '12th Marksheet', false),
  ('degree_certificate', 'Degree Certificate', false),
  ('bed_certificate', 'B.Ed Certificate', false),
  ('experience_letter', 'Experience Letter', false),
  ('noc', 'NOC (No Objection Certificate)', false),
  ('medical_certificate', 'Medical Certificate', false),
  ('police_verification', 'Police Verification', false),
];

/// Step 9 — Documents. A real upload flow against
/// `POST/GET/DELETE /api/v1/hr/onboard/documents/...` — server enforces
/// 5MB size cap and PDF/JPG/PNG content-type whitelist. Only `signature`
/// and `aadhaar` block advancing to the next step.
class StepDocuments extends ConsumerStatefulWidget {
  const StepDocuments({super.key});

  @override
  ConsumerState<StepDocuments> createState() => _StepDocumentsState();
}

class _StepDocumentsState extends ConsumerState<StepDocuments> {
  final Set<String> _uploading = {};

  Future<void> _upload(String docKey, String docLabel) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    if (file!.size > 5 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File size must be 5 MB or less.')));
      return;
    }
    setState(() => _uploading.add(docKey));
    try {
      await ref.read(hrRepositoryProvider).uploadOnboardDocument(
            file: PickedAttachment(name: file.name, bytes: file.bytes!, size: file.size),
            docKey: docKey,
            docLabel: docLabel,
          );
      invalidateOnboardDocuments(ref);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is HrApiException ? e.message : 'Upload failed.')));
    } finally {
      if (mounted) setState(() => _uploading.remove(docKey));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await ref.read(hrRepositoryProvider).deleteOnboardDocument(id);
      invalidateOnboardDocuments(ref);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is HrApiException ? e.message : 'Delete failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(onboardDocumentsProvider);
    final docs = docsAsync.valueOrNull ?? const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardStepHeader('Documents', 'Tally-based checklist'),
          if (docsAsync.isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator())),
          for (final (key, label, required) in _allDocs) _docRow(key, label, required, docs),
        ],
      ),
    );
  }

  Widget _docRow(String docKey, String docLabel, bool required, List uploaded) {
    final match = uploaded.where((d) => d.docKey == docKey).cast<dynamic>().toList();
    final doc = match.isEmpty ? null : match.first;
    final isUploading = _uploading.contains(docKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8E8EE)), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(doc != null ? Icons.check_circle : Icons.insert_drive_file_outlined, size: 18, color: doc != null ? const Color(0xFF16A34A) : const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(docLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: HrColors.ink)),
              if (required) const Padding(padding: EdgeInsets.only(left: 4), child: Text('*', style: TextStyle(color: HrColors.red, fontWeight: FontWeight.w900))),
            ]),
            if (doc != null) Text(doc.fileName as String, style: const TextStyle(fontSize: 11.5, color: HrColors.muted), overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (isUploading)
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        else ...[
          TextButton(onPressed: () => _upload(docKey, docLabel), child: Text(doc == null ? 'Upload' : 'Replace')),
          if (doc != null) IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: HrColors.red), onPressed: () => _delete(doc.id as int)),
        ],
      ]),
    );
  }
}
