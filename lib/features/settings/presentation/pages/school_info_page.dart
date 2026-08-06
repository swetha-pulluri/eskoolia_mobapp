import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/school_info_entity.dart';
import '../providers/settings_provider.dart';

/// Settings → School Info. Read-only — the backend's
/// `my-school-info` endpoint has no write counterpart for a school-scoped
/// user, and the web app has no persisted edit form for this data either
/// (see [SchoolInfoEntity] doc comment), so there is nothing to save here.
class SchoolInfoPage extends ConsumerWidget {
  const SchoolInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolInfoAsync = ref.watch(schoolInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(schoolInfoProvider.future),
          child: schoolInfoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Failed to load school info.\n$error',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageSubtitle,
                    ),
                  ),
                ),
              ],
            ),
            data: (info) => SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTINGS · SCHOOL INFO',
                    style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text('School Info', style: AppTextStyles.pageTitle.copyWith(fontSize: 22)),
                  const SizedBox(height: 20),
                  _section('01', 'School details', [
                    _logoRow(info),
                    const SizedBox(height: 4),
                    _infoRow('School name', info.name),
                    _infoRow('Address', info.address),
                    _infoRow('Email', info.email),
                    _infoRow('Phone', info.phone, isLast: true),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String num, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(999)),
                child: Text(num, style: AppTextStyles.numberedBadge.copyWith(color: AppColors.purpleDeep, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _logoRow(SchoolInfoEntity info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          info.logoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    info.logoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    // Backend `logo_url` can be blank or point at a stale/404
                    // path — fall back to the placeholder rather than crash.
                    errorBuilder: (context, error, stackTrace) => _logoPlaceholder(),
                  ),
                )
              : _logoPlaceholder(),
          const SizedBox(width: 12),
          Text('School logo', style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.borderPrimary)),
      child: Icon(Icons.school_outlined, color: AppColors.textTertiary, size: 22),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.sectionSubtitle.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'Not set',
            style: TextStyle(fontSize: 13.5, color: value.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
