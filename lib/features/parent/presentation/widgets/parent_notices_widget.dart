import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/entities/notice_item_entity.dart';

const Color _iconBg = Color(0xFFF0F9FF);
const Color _iconColor = Color(0xFF0284C7);
const Color _brandPurple = Color(0xFF6D4AFF);

/// Home screen → "Notice Board" widget — mobile port of web's
/// `ParentNoticesWidget.tsx`: the 3 most recent published school notices.
class ParentNoticesWidget extends StatelessWidget {
  final List<NoticeItemEntity> notices;
  final bool loading;

  const ParentNoticesWidget({super.key, required this.notices, required this.loading});

  bool _isNew(String publishOn) {
    final d = DateTime.tryParse(publishOn);
    if (d == null) return false;
    return DateTime.now().difference(d).inDays <= 3;
  }

  String _relative(String publishOn) {
    final d = DateTime.tryParse(publishOn);
    if (d == null) return '';
    final diff = DateTime.now().difference(d).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 6) return '$diff days ago';
    return DateFormat('d MMM').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final shown = notices.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PremiumCard(
        radius: 14,
        color: Colors.white,
        borderColor: AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.notifications_outlined, size: 13, color: _iconColor),
                  ),
                  const SizedBox(width: 7),
                  const Text('Notice Board', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/parent/notices'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('All', style: TextStyle(fontSize: 11.5, color: _brandPurple, fontWeight: FontWeight.w500)),
                        Icon(Icons.chevron_right, size: 13, color: _brandPurple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            if (loading)
              const SizedBox(
                height: 60,
                child: Center(child: Text('Loading…', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
              )
            else if (shown.isEmpty)
              const SizedBox(
                height: 60,
                child: Center(child: Text('No notices yet.', style: TextStyle(fontSize: 12, color: AppColors.ink3))),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      InkWell(
                        onTap: () => context.go('/parent/notices'),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                          decoration: BoxDecoration(
                            border: i < shown.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(7)),
                                alignment: Alignment.center,
                                child: const Icon(Icons.campaign_outlined, size: 14, color: _iconColor),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shown[i].title,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink1),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_isNew(shown[i].publishOn)) ...[
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(color: _iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                            child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _iconColor)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(shown[i].message, style: const TextStyle(fontSize: 11, color: AppColors.ink3), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(_relative(shown[i].publishOn), style: const TextStyle(fontSize: 10.5, color: AppColors.ink3)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
