import 'package:flutter/material.dart';
import '../../domain/entities/inquiry_entity.dart';

/// Fixed column widths for the Class Workspace table — shared by the header
/// row (built in `class_workspace.dart`) and every `ApplicationRow`.
/// Order matches web exactly: checkbox, Name, Grade, Source, Age, Stage,
/// Follow-up, Counsellor, Actions.
class ApplicationTableColumns {
  static const checkbox = 36.0;
  static const name = 190.0;
  static const grade = 64.0;
  static const source = 96.0;
  static const age = 44.0;
  static const stage = 150.0;
  static const followUp = 120.0;
  static const counsellor = 84.0;
  static const actions = 116.0;

  static double get total =>
      checkbox + name + grade + source + age + stage + followUp + counsellor + actions;
}

const List<Map<String, String>> kInlineStageOptions = [
  {'value': 'new', 'label': 'New'},
  {'value': 'contacted', 'label': 'In Conversation'},
  {'value': 'visited', 'label': 'Decision Pending'},
  {'value': 'enrolled', 'label': 'Enrolled'},
  {'value': 'waitlisted', 'label': 'Waitlist'},
  {'value': 'declined', 'label': 'Cold / Dropped'},
];

const Map<String, StageStyle> kStageMap = {
  'new': StageStyle('New', Color(0xFF1D4ED8), Color(0xFFDBEAFE)),
  'contacted': StageStyle('In Conversation', Color(0xFF4338CA), Color(0xFFE0E7FF)),
  'visited': StageStyle('Decision Pending', Color(0xFF92400E), Color(0xFFFEF3C7)),
  'enrolled': StageStyle('Enrolled', Color(0xFF15803D), Color(0xFFDCFCE7)),
  'waitlisted': StageStyle('Waitlist', Color(0xFF6D28D9), Color(0xFFF3E8FF)),
  'declined': StageStyle('Cold / Dropped', Color(0xFF6B7280), Color(0xFFF3F4F6)),
};

class StageStyle {
  final String label;
  final Color fg;
  final Color bg;
  const StageStyle(this.label, this.fg, this.bg);
}

Color nameColor(String name) {
  const colors = [
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF14B8A6),
    Color(0xFFF59E0B), Color(0xFF3B82F6), Color(0xFF10B981),
  ];
  int hash = 0;
  for (final code in name.codeUnits) {
    hash = (hash * 31 + code) & 0xff;
  }
  return colors[hash % colors.length];
}

_SourceStyle _sourceStyle(String sourceName) {
  final n = sourceName.toLowerCase();
  if (n.contains('walk')) return const _SourceStyle(Color(0xFF1D4ED8), Color(0xFFEFF6FF), Color(0xFFDBEAFE));
  if (n.contains('whatsapp') || n.contains('wa')) return const _SourceStyle(Color(0xFF15803D), Color(0xFFF0FDF4), Color(0xFFDCFCE7));
  if (n.contains('web') || n.contains('online')) return const _SourceStyle(Color(0xFF7E22CE), Color(0xFFFAF5FF), Color(0xFFF3E8FF));
  if (n.contains('phone') || n.contains('call')) return const _SourceStyle(Color(0xFF374151), Color(0xFFF9FAFB), Color(0xFFE5E7EB));
  if (n.contains('refer')) return const _SourceStyle(Color(0xFF92400E), Color(0xFFFFFBEB), Color(0xFFFEF3C7));
  return const _SourceStyle(Color(0xFF374151), Color(0xFFF9FAFB), Color(0xFFE5E7EB));
}

class _SourceStyle {
  final Color fg;
  final Color bg;
  final Color border;
  const _SourceStyle(this.fg, this.bg, this.border);
}

class _Sentiment {
  final String emoji;
  final String label;
  const _Sentiment(this.emoji, this.label);
}

_Sentiment? _detectSentiment(String note) {
  final n = note.toLowerCase();
  if (RegExp(r'rude|angry|upset|complain|threaten|difficult|aggressive').hasMatch(n)) {
    return const _Sentiment('🔴', 'Difficult');
  }
  if (RegExp(r'fee|expensive|costly|afford|budget|price|cheap|discount').hasMatch(n)) {
    return const _Sentiment('💰', 'Fee sensitive');
  }
  if (RegExp(r'busy|no time|call back|not now|tied up|later').hasMatch(n)) {
    return const _Sentiment('⏰', 'Busy');
  }
  final qCount = RegExp(r'\?').allMatches(n).length;
  if (qCount >= 2 || RegExp(r'curriculum|syllabus|ratio|extracurricular').hasMatch(n)) {
    return const _Sentiment('❓', 'FAQ heavy');
  }
  return null;
}

class _NextBestAction {
  final String label;
  final Color color;
  final Color bg;
  const _NextBestAction(this.label, this.color, this.bg);
}

_NextBestAction? _nextBestAction(InquiryEntity inq, String today) {
  final nfd = inq.nextFollowUpDate;
  final overdue = nfd != null && nfd.compareTo(today) < 0;
  final dueToday = nfd == today;
  if (inq.status == 'enrolled' || inq.status == 'declined') return null;
  if (overdue) return const _NextBestAction('📞 Call now', Color(0xFF991B1B), Color(0xFFFEE2E2));
  if (dueToday && inq.status == 'visited') return const _NextBestAction('⚖️ Ask for decision', Color(0xFF92400E), Color(0xFFFEF3C7));
  if (dueToday) return const _NextBestAction('💬 Follow up today', Color(0xFF1E40AF), Color(0xFFDBEAFE));
  if (inq.status == 'new') return const _NextBestAction('👋 First contact', Color(0xFF065F46), Color(0xFFD1FAE5));
  if (inq.status == 'visited') return const _NextBestAction('⚖️ Await decision', Color(0xFF5B21B6), Color(0xFFEDE9FE));
  return null;
}

int inquiryAge(InquiryEntity inq, String today) {
  final ref = inq.queryDate;
  if (ref == null) return 0;
  final t = DateTime.tryParse(today);
  final r = DateTime.tryParse(ref);
  if (t == null || r == null) return 0;
  final diff = t.difference(r).inDays;
  return diff < 0 ? 0 : diff;
}

String formatShortDate(String? v) {
  if (v == null) return '–';
  final d = DateTime.tryParse(v);
  if (d == null) return v;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

/// Application Row — section "03" table row. Converted from web
/// `command-center/ApplicationRow.tsx`. Whole row opens the detail panel;
/// checkbox / stage chip / action icons stop propagation like on web.
class ApplicationRow extends StatefulWidget {
  final InquiryEntity inquiry;
  final bool isSelected;
  final String today;
  final ValueChanged<int> onToggleSelect;
  final ValueChanged<InquiryEntity> onOpenDetail;
  final ValueChanged<InquiryEntity> onOpenLog;
  final ValueChanged<InquiryEntity> onOpenCall;
  final ValueChanged<InquiryEntity> onOpenWA;
  final Future<void> Function(int id, String stage) onInlineStageMove;

  const ApplicationRow({
    super.key,
    required this.inquiry,
    required this.isSelected,
    required this.today,
    required this.onToggleSelect,
    required this.onOpenDetail,
    required this.onOpenLog,
    required this.onOpenCall,
    required this.onOpenWA,
    required this.onInlineStageMove,
  });

  @override
  State<ApplicationRow> createState() => _ApplicationRowState();
}

class _ApplicationRowState extends State<ApplicationRow> {
  bool _movingStage = false;

  Future<void> _handleStageSelect(String value) async {
    setState(() => _movingStage = true);
    try {
      await widget.onInlineStageMove(widget.inquiry.id, value);
    } finally {
      if (mounted) setState(() => _movingStage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inq = widget.inquiry;
    final today = widget.today;
    final age = inquiryAge(inq, today);
    final ageColor = age <= 2
        ? const Color(0xFF6B7280)
        : age <= 7
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);
    final sentiment = _detectSentiment(inq.note);
    final nba = _nextBestAction(inq, today);

    final nfd = inq.nextFollowUpDate;
    final isOverdue = nfd != null && nfd.compareTo(today) < 0 && inq.status != 'enrolled' && inq.status != 'declined';
    int overdueDays = 0;
    if (isOverdue) {
      final t = DateTime.tryParse(today);
      final f = DateTime.tryParse(nfd);
      if (t != null && f != null) overdueDays = t.difference(f).inDays;
    }
    final leftBorderColor = overdueDays > 7
        ? const Color(0xFFF87171)
        : overdueDays > 2
            ? const Color(0xFFFBBF24)
            : Colors.transparent;

    final stage = kStageMap[inq.status] ?? StageStyle(inq.status, const Color(0xFF4B5563), const Color(0xFFF3F4F6));
    final nameParts = inq.fullName.trim().isEmpty ? ['?'] : inq.fullName.trim().split(RegExp(r'\s+'));
    final initials = nameParts.take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Opacity(
      opacity: _movingStage ? 0.5 : 1,
      child: GestureDetector(
        onTap: () => widget.onOpenDetail(inq),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.isSelected ? const Color(0x14EEF2FF) : Colors.white,
                border: const Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
              ),
              child: Row(
                children: [
                  _cell(
                    ApplicationTableColumns.checkbox,
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (_) => widget.onToggleSelect(inq.id),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  _cell(ApplicationTableColumns.name, _nameCell(inq, initials, sentiment)),
                  _cell(
                    ApplicationTableColumns.grade,
                    _badge(inq.classNameResolved ?? '–', const Color(0xFF1D4ED8), const Color(0xFFEFF6FF)),
                  ),
                  _cell(ApplicationTableColumns.source, _sourceCell(inq)),
                  _cell(
                    ApplicationTableColumns.age,
                    Text('${age}d', style: TextStyle(fontSize: 11.5, color: ageColor, fontWeight: age > 2 ? FontWeight.w600 : FontWeight.normal)),
                  ),
                  _cell(ApplicationTableColumns.stage, _stageCell(stage, inq)),
                  _cell(ApplicationTableColumns.followUp, _followUpCell(inq, today, overdueDays, nba)),
                  _cell(
                    ApplicationTableColumns.counsellor,
                    Text(inq.assigned.isEmpty ? '–' : inq.assigned, style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563)), overflow: TextOverflow.ellipsis),
                  ),
                  _cell(ApplicationTableColumns.actions, _actionsCell(inq)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: leftBorderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(double width, Widget child) {
    return SizedBox(
      width: width,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: child),
    );
  }

  Widget _badge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _nameCell(InquiryEntity inq, String initials, _Sentiment? sentiment) {
    final displayName = inq.childName.isNotEmpty ? inq.childName : inq.fullName;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: nameColor(inq.fullName), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                  ),
                  if (sentiment != null) Padding(padding: const EdgeInsets.only(left: 4), child: Text(sentiment.emoji, style: const TextStyle(fontSize: 11))),
                  if (inq.hasSiblingEnrolled == 'yes')
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(999)),
                        child: const Text('👨‍👩‍👦 Sibling', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6D28D9))),
                      ),
                    ),
                ],
              ),
              if (inq.childName.isNotEmpty)
                Text('Parent: ${inq.fullName}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
              Text(inq.phone, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sourceCell(InquiryEntity inq) {
    final name = inq.sourceName;
    if (name == null || name.isEmpty) {
      return const Text('–', style: TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)));
    }
    final s = _sourceStyle(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: s.bg, border: Border.all(color: s.border), borderRadius: BorderRadius.circular(999)),
      child: Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: s.fg), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _stageCell(StageStyle stage, InquiryEntity inq) {
    return PopupMenuButton<String>(
      tooltip: 'Click to change stage',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 28),
      itemBuilder: (context) => kInlineStageOptions.map((s) {
        final isCurrent = inq.status == s['value'];
        return PopupMenuItem<String>(
          value: s['value'],
          height: 36,
          child: Text(
            s['label']!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isCurrent ? const Color(0xFF4F46E5) : const Color(0xFF374151),
            ),
          ),
        );
      }).toList(),
      onSelected: (value) => _handleStageSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: stage.bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(stage.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: stage.fg), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 12, color: stage.fg.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _followUpCell(InquiryEntity inq, String today, int overdueDays, _NextBestAction? nba) {
    final nfd = inq.nextFollowUpDate;
    Widget dateWidget;
    if (nfd == null) {
      dateWidget = const Text('–', style: TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)));
    } else if (nfd.compareTo(today) < 0) {
      dateWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(999)),
        child: Text('Overdue ${overdueDays}d', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
      );
    } else if (nfd == today) {
      dateWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(999)),
        child: const Text('Today', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
      );
    } else {
      dateWidget = Text(formatShortDate(nfd), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        dateWidget,
        if (nba != null) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: nba.bg, borderRadius: BorderRadius.circular(999)),
            child: Text(nba.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: nba.color), overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }

  Widget _actionsCell(InquiryEntity inq) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (inq.phone.isNotEmpty)
          _actionIcon(Icons.call_outlined, const Color(0xFF15803D), 'Call', () => widget.onOpenCall(inq)),
        if (inq.phone.isNotEmpty)
          _actionIcon(Icons.chat_bubble_outline, const Color(0xFF15803D), 'WhatsApp', () => widget.onOpenWA(inq)),
        _actionIcon(Icons.access_time, const Color(0xFF2563EB), 'Log Update', () => widget.onOpenLog(inq)),
        _actionIcon(Icons.edit_outlined, const Color(0xFF4B5563), 'View Details', () => widget.onOpenDetail(inq)),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 15, color: color)),
      ),
    );
  }
}
