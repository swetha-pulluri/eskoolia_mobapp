import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/notice_item_entity.dart';
import '../providers/parent_providers.dart';

const Color _brandPurple = Color(0xFF6D4AFF);
const Color _info = Color(0xFF0284C7);

/// School Notices — mobile port of web's
/// `(parent-portal)/parent/notices/page.tsx`: the guardian's school
/// announcements/circulars, tap-to-expand for the full message. Also what
/// Communication's "Messages"/"PTMs"/"Permissions" sub-nav tabs resolve to
/// on web — there's no separate messaging/PTM/permission-slip feature
/// there, just this one notices list (see `ParentNavModules`' doc comment).
class NoticesPage extends ConsumerWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(parentNoticesProvider);
    final notices = noticesAsync.valueOrNull ?? const <NoticeItemEntity>[];
    final loading = noticesAsync.isLoading;
    final hasError = noticesAsync.hasError;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(parentNoticesProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.ink1, fontWeight: FontWeight.w600),
                            children: const [
                              TextSpan(text: 'School '),
                              TextSpan(text: 'Notices', style: TextStyle(color: _brandPurple, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text("Announcements and circulars from your child's school.", style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.4)),
                      ],
                    ),
                  ),
                  if (notices.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), color: AppColors.bg2),
                      child: Text('${notices.length} notice${notices.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
              if (hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Could not load notices. Pull to refresh.', style: TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C))),
                ),
              ],
              const SizedBox(height: 18),
              if (loading)
                Column(children: [for (var i = 0; i < 4; i++) ...[_skeleton(), const SizedBox(height: 10)]])
              else if (notices.isNotEmpty)
                Column(children: [for (var i = 0; i < notices.length; i++) ...[_NoticeCard(notice: notices[i]), if (i < notices.length - 1) const SizedBox(height: 10)]])
              else if (!hasError)
                _EmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeleton() => Container(height: 76, decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)));
}

class _NoticeCard extends StatefulWidget {
  final NoticeItemEntity notice;
  const _NoticeCard({required this.notice});

  @override
  State<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<_NoticeCard> {
  bool _expanded = false;

  bool get _isNew {
    final d = DateTime.tryParse(widget.notice.publishOn);
    if (d == null) return false;
    return DateTime.now().difference(d).inDays <= 3;
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(widget.notice.publishOn);
    final publishLabel = d != null ? DateFormat('d MMM yyyy').format(d) : widget.notice.publishOn;

    return PremiumCard(
      radius: 14,
      color: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: const Color(0x1A0284C7), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.notifications_outlined, size: 17, color: _info),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(widget.notice.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink1), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            if (_isNew) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0x1F0284C7), borderRadius: BorderRadius.circular(20)),
                                child: const Text('NEW', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _info)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(publishLabel, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
                        if (!_expanded) ...[
                          const SizedBox(height: 6),
                          Text(widget.notice.message, style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: AppColors.ink3),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(widget.notice.message, style: const TextStyle(fontSize: 13, color: AppColors.ink1, height: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(color: AppColors.bg2, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: const Color(0x1A0284C7), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_outlined, size: 22, color: _info),
          ),
          const SizedBox(height: 12),
          const Text('No notices yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink2)),
          const SizedBox(height: 4),
          const Text('School notices and announcements will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
        ],
      ),
    );
  }
}
