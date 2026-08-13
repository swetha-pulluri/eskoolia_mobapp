import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../domain/entities/policy_document_entity.dart';
import '../providers/documents_provider.dart';
import '../providers/documents_state.dart';
import '../widgets/document_card.dart';
import '../widgets/document_wizard.dart';

/// Settings → Documents ("Policy Documents") — a 1:1 port of
/// `frontend/components/settings/DocumentsPanel.tsx`: a category-filterable
/// card list of uploaded policy documents + a 3-step (create) / 2-step
/// (edit) wizard.
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentsNotifierProvider);
    final notifier = ref.read(documentsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notifier.load(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                border: Border.all(color: AppColors.borderPrimary),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x0A0F1222), blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(state),
                  if (state.error != null) _banner(state.error!, AppColors.dangerRed, AppColors.redSoft, Icons.warning_amber_rounded),
                  if (state.success != null) _banner(state.success!, AppColors.successGreen, AppColors.greenSoft, Icons.check_circle),
                  if (!state.wizardOpen) ...[
                    const SizedBox(height: 18),
                    _categoryFilter(state, notifier),
                  ],
                  if (state.loading) _loading(),
                  if (!state.loading && !state.wizardOpen && state.documents.isEmpty) _emptyState(notifier),
                  if (!state.loading && !state.wizardOpen && state.documents.isNotEmpty) _list(state, notifier),
                  if (state.wizardOpen) const DocumentWizard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(DocumentsState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Policy ', style: AppTextStyles.pageTitle),
                  Text('Documents', style: AppTextStyles.pageTitleAccent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Code of conduct, rule books, and school norms for staff. Visible on every staff member's profile.",
                style: AppTextStyles.pageSubtitle,
              ),
            ],
          ),
        ),
        if (!state.loading && state.documents.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 12, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: AppColors.purpleAccent),
                const SizedBox(width: 6),
                Text(
                  '${state.documents.length} ${state.documents.length == 1 ? 'document' : 'documents'}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.purpleAccent),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _categoryFilter(DocumentsState state, DocumentsNotifier notifier) {
    return Row(
      children: [
        const Text('Filter by category', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(width: 10),
        SizedBox(
          width: 190,
          child: AppDropdown<String>(
            value: state.categoryFilter,
            height: 34,
            fontSize: 12.5,
            textColor: AppColors.textPrimary,
            borderColor: AppColors.borderSecondary,
            borderRadius: BorderRadius.circular(9),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            hint: const Text('All'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
              for (final option in policyDocumentCategories) DropdownMenuItem<String?>(value: option.key, child: Text(option.value)),
            ],
            onChanged: notifier.setCategoryFilter,
          ),
        ),
      ],
    );
  }

  Widget _banner(String message, Color fg, Color bg, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.only(top: 20),
      child: Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)),
          SizedBox(width: 10),
          Text('Loading documents…', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _emptyState(DocumentsNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSecondary),
        borderRadius: BorderRadius.circular(14),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.1,
          colors: [AppColors.purpleTint, AppColors.bgPrimary],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.purpleTint, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.description_outlined, size: 21, color: AppColors.purpleAccent),
          ),
          const SizedBox(height: 14),
          const Text('Upload your first policy document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Code of conduct, rule book, or school norms — a short guided upload, then visible on every staff '
            'profile.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: notifier.startCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_outlined, size: 14),
                SizedBox(width: 6),
                Text('Upload Document', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(DocumentsState state, DocumentsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        for (var i = 0; i < state.documents.length; i++) ...[
          DocumentCard(document: state.documents[i]),
          if (i != state.documents.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: notifier.startCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_outlined, size: 14),
              SizedBox(width: 6),
              Text('Upload Another Document', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
