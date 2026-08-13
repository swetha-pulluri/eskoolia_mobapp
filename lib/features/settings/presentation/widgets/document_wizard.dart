import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/policy_document_entity.dart';
import '../providers/documents_provider.dart';
import '../providers/documents_state.dart';
import 'document_card.dart' show formatFileSize;
import 'document_fields.dart';
import 'document_stat_tile.dart';
import 'document_step_indicator.dart';

/// The 3-step (create) / 2-step (edit) Details → [Upload →] Review wizard —
/// mirrors `DocumentWizard` in `DocumentsPanel.tsx`. Unlike every other
/// Settings wizard, the step set itself differs between create and edit
/// (editing skips Upload entirely — the file can't be replaced in-place).
class DocumentWizard extends ConsumerWidget {
  const DocumentWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentsNotifierProvider);
    final notifier = ref.read(documentsNotifierProvider.notifier);
    final draft = state.draft;
    final hasTitle = ((draft['title'] as String?) ?? '').trim().isNotEmpty;
    final steps = state.isEditing ? documentEditSteps : documentCreateSteps;
    final isLastStep = state.step == steps.length - 1;

    // Step order for create: 0=Details, 1=Upload, 2=Review.
    // Step order for edit: 0=Details, 1=Review.
    final isUploadStep = !state.isEditing && state.step == 1;
    final canGoNext = state.step == 0 ? hasTitle : (isUploadStep ? state.pickedFile != null : true);
    bool canJumpTo(int target) => state.isEditing || target == 0 || hasTitle;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentStepIndicator(
            steps: steps,
            currentStep: state.step,
            canJumpTo: canJumpTo,
            onStepTap: notifier.setStep,
          ),
          if (state.step == 0) _detailsStep(state, notifier),
          if (isUploadStep) _uploadStep(state, notifier),
          if (isLastStep) _reviewStep(state),
          const SizedBox(height: 22),
          _footer(state, notifier, canGoNext, isLastStep),
        ],
      ),
    );
  }

  Widget _detailsStep(DocumentsState state, DocumentsNotifier notifier) {
    final draft = state.draft;
    final existingFileName = draft['file_name'] as String?;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DocumentField(
                  label: 'Title',
                  value: (draft['title'] as String?) ?? '',
                  autofocus: true,
                  onChanged: (v) => notifier.setDraftField('title', v),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: DocumentCategoryField(
                  value: (draft['category'] as String?) ?? 'other',
                  onChanged: (v) => notifier.setDraftField('category', v),
                ),
              ),
            ],
          ),
          if (state.isEditing && existingFileName != null && existingFileName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(10)),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                  children: [
                    const TextSpan(text: 'File stays as-is when editing: '),
                    TextSpan(text: existingFileName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const TextSpan(text: '. Delete and re-upload to replace the file itself.'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _uploadStep(DocumentsState state, DocumentsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: DocumentFilePickerField(file: state.pickedFile, onChanged: notifier.setPickedFile),
    );
  }

  Widget _reviewStep(DocumentsState state) {
    final draft = state.draft;
    final title = (draft['title'] as String?) ?? '';
    final category = (draft['category'] as String?) ?? 'other';
    final fileLabel = state.isEditing
        ? ((draft['file_name'] as String?)?.isNotEmpty == true ? '${draft['file_name']} (unchanged)' : 'unchanged')
        : (state.pickedFile != null ? '${state.pickedFile!.name} (${formatFileSize(state.pickedFile!.size)})' : '—');

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 15, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Review before saving:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          DocumentStatTile(icon: Icons.badge_outlined, tone: DocumentStatTone.purple, label: 'Title', value: title.isEmpty ? '—' : title),
          const SizedBox(height: 10),
          DocumentStatTile(icon: Icons.category_outlined, tone: DocumentStatTone.blue, label: 'Category', value: policyDocumentCategoryLabel(category)),
          const SizedBox(height: 10),
          DocumentStatTile(icon: Icons.attach_file, tone: DocumentStatTone.amber, label: 'File', value: fileLabel),
        ],
      ),
    );
  }

  Widget _footer(DocumentsState state, DocumentsNotifier notifier, bool canGoNext, bool isLastStep) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderPrimary))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          state.step > 0
              ? TextButton.icon(
                  onPressed: () => notifier.setStep(state.step - 1),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  icon: const Icon(Icons.chevron_left, size: 15),
                  label: const Text('Back', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                )
              : const SizedBox.shrink(),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: notifier.closeWizard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSecondary),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (state.isEditing && !isLastStep)
                OutlinedButton(
                  onPressed: state.saving ? null : () => _submit(notifier),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purpleAccent,
                    side: const BorderSide(color: AppColors.purpleSoft),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: state.saving
                      ? _savingRow(AppColors.purpleAccent)
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 15, color: AppColors.purpleAccent),
                            SizedBox(width: 6),
                            Text('Save & Exit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.purpleAccent)),
                          ],
                        ),
                ),
              if (!isLastStep)
                ElevatedButton(
                  onPressed: canGoNext ? () => notifier.setStep(state.step + 1) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 15),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: state.saving ? null : () => _submit(notifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: state.saving
                      ? _savingRow(Colors.white)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(state.isEditing ? Icons.check_circle : Icons.add, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              state.isEditing ? 'Save Changes' : 'Upload',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit(DocumentsNotifier notifier) async {
    try {
      await notifier.submit();
    } catch (_) {
      // Error already surfaced via state.error.
    }
  }

  Widget _savingRow(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
        const SizedBox(width: 6),
        Text('Saving…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
