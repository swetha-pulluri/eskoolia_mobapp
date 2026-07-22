import 'package:flutter/material.dart';

/// Morning Brief — section "01" of the Command Center. Converted from web
/// `command-center/MorningBrief.tsx`. A collapsible KPI strip: 2x2 grid of
/// stat cards (New Applications / Follow-up Overdue / Visits Today /
/// Decisions Pending) plus a priority narrative bar.
class MorningBriefData {
  final int newToday;
  final int overdueFollowUp;
  final int visitsToday;
  final int decisionsPending;
  const MorningBriefData({
    required this.newToday,
    required this.overdueFollowUp,
    required this.visitsToday,
    required this.decisionsPending,
  });
}

class MorningBrief extends StatefulWidget {
  final MorningBriefData data;
  final ValueChanged<String> onCardClick;
  final bool isLoading;
  final String? priorityText;

  const MorningBrief({
    super.key,
    required this.data,
    required this.onCardClick,
    this.isLoading = false,
    this.priorityText,
  });

  @override
  State<MorningBrief> createState() => _MorningBriefState();
}

class _CardSpec {
  final String label;
  final String stage;
  final String emoji;
  final int Function(MorningBriefData) value;
  final Color accent;
  final Color bg;
  final Color border;
  const _CardSpec(this.label, this.stage, this.emoji, this.value, this.accent, this.bg, this.border);
}

class _MorningBriefState extends State<MorningBrief> {
  bool _collapsed = false;

  static final _cards = [
    _CardSpec('New Applications', 'new', '✨', (d) => d.newToday, const Color(0xFF4F46E5), const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)),
    _CardSpec('Follow-up Overdue', 'active', '⏰', (d) => d.overdueFollowUp, const Color(0xFFD97706), const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)),
    _CardSpec('Visits Today', 'pending', '🏫', (d) => d.visitsToday, const Color(0xFF16A34A), const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)),
    _CardSpec('Decisions Pending', 'pending', '⚖️', (d) => d.decisionsPending, const Color(0xFFDC2626), const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                  child: const Text('01', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.notifications_outlined, size: 14, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                const Text('Morning Brief', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Today's priorities at a glance", style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
                ),
                Icon(_collapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, size: 20, color: const Color(0xFF9CA3AF)),
              ],
            ),
          ),
          if (!_collapsed) ...[
            const SizedBox(height: 10),
            widget.isLoading
                ? Row(
                    children: List.generate(
                      4,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          child: Container(height: 96, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    children: _cards.map((c) => _buildCard(c)).toList(),
                  ),
            if (!widget.isLoading && widget.priorityText != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), border: Border.all(color: const Color(0xFFE0E7FF)), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚡ ', style: TextStyle(fontSize: 13)),
                    Expanded(child: Text(widget.priorityText!, style: const TextStyle(fontSize: 12, color: Color(0xFF3730A3)))),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCard(_CardSpec spec) {
    final value = spec.value(widget.data);
    return InkWell(
      onTap: () => widget.onCardClick(spec.stage),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: spec.bg, border: Border.all(color: spec.border), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(spec.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: spec.accent)),
            Text(spec.label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
