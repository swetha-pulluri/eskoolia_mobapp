import 'package:flutter/material.dart';
import '../../data/enrollment_draft_store.dart';
import '../../domain/models/enrollment_draft.dart';

const int _draftsPerPage = 15;

/// "Saved drafts" modal — mirrors StudentAddPanel.tsx's `draftsOpen` overlay
/// (`.ai-modal-drafts`) exactly: search box, Recent/Oldest/Most-complete
/// sort pills, per-draft avatar/progress/smart-tip card, Resume/Delete
/// actions, and pagination past 15 drafts.
class StudentDraftsDialog extends StatefulWidget {
  final int totalSteps;
  final ValueChanged<EnrollmentDraft> onResume;

  const StudentDraftsDialog({super.key, required this.totalSteps, required this.onResume});

  @override
  State<StudentDraftsDialog> createState() => _StudentDraftsDialogState();
}

enum _DraftSort { recent, oldest, progress }

class _StudentDraftsDialogState extends State<StudentDraftsDialog> {
  final _store = EnrollmentDraftStore();
  late List<EnrollmentDraft> _drafts;
  final _searchController = TextEditingController();
  _DraftSort _sort = _DraftSort.recent;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _drafts = _store.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EnrollmentDraft> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    var list = q.isEmpty
        ? List<EnrollmentDraft>.from(_drafts)
        : _drafts
            .where((d) =>
                d.firstName.toLowerCase().contains(q) || d.lastName.toLowerCase().contains(q) || d.admissionNo.toLowerCase().contains(q))
            .toList();
    list.sort((a, b) {
      switch (_sort) {
        case _DraftSort.recent:
          return b.savedAt.compareTo(a.savedAt);
        case _DraftSort.oldest:
          return a.savedAt.compareTo(b.savedAt);
        case _DraftSort.progress:
          return computeDraftStats(b, widget.totalSteps).pct.compareTo(computeDraftStats(a, widget.totalSteps).pct);
      }
    });
    return list;
  }

  Future<void> _delete(EnrollmentDraft draft, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text('Delete draft "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.delete(draft.id);
    if (!mounted) return;
    setState(() => _drafts = _store.load());
  }

  String _timeAgo(int savedAt) {
    final diffMs = DateTime.now().millisecondsSinceEpoch - savedAt;
    final mins = (diffMs / 60000).floor().clamp(0, 1 << 31);
    if (mins < 1) return 'just now';
    if (mins == 1) return '1 min ago';
    if (mins < 60) return '$mins min ago';
    if (mins < 1440) return '${mins ~/ 60} hr ago';
    return '${mins ~/ 1440} day(s) ago';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final filtered = _filtered;
    final totalPages = filtered.isEmpty ? 1 : ((filtered.length - 1) ~/ _draftsPerPage) + 1;
    final safePage = _page.clamp(1, totalPages);
    final pageSlice = filtered.skip((safePage - 1) * _draftsPerPage).take(_draftsPerPage).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: screenHeight * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHead(),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            if (_drafts.isEmpty)
              _buildEmptyState()
            else ...[
              _buildToolbar(),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No drafts match "${_searchController.text}".',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                        children: pageSlice.map(_buildDraftCard).toList(),
                      ),
              ),
              if (totalPages > 1) _buildPagination(safePage, totalPages, filtered.length),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHead() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)]),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF6C3CE1)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved drafts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                SizedBox(height: 2),
                Text(
                  'Pick up where you left off — your work is safe on this device.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
            style: IconButton.styleFrom(backgroundColor: const Color(0x0A000000), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined, size: 40, color: Color(0xFFA78BFA)),
          ),
          const SizedBox(height: 14),
          const Text('No drafts yet', style: TextStyle(fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          const Text(
            'Start filling the form and tap Save draft in the footer — your drafts are stored on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3CE1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: const Text('Got it', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _page = 1),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search by name or admission no…',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sortPill('Recent', _DraftSort.recent),
              const SizedBox(width: 4),
              _sortPill('Oldest', _DraftSort.oldest),
              const SizedBox(width: 4),
              _sortPill('Most complete', _DraftSort.progress),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortPill(String label, _DraftSort value) {
    final active = _sort == value;
    return InkWell(
      onTap: () => setState(() {
        _sort = value;
        _page = 1;
      }),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFDDD6FE) : Colors.transparent),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? const Color(0xFF6C3CE1) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(EnrollmentDraft draft) {
    final stats = computeDraftStats(draft, widget.totalSteps);
    final name = [draft.firstName, draft.lastName].where((s) => s.trim().isNotEmpty).join(' ');
    final displayName = name.trim().isEmpty ? 'Unnamed draft' : name.trim();
    final initials = ((draft.firstName.isNotEmpty ? draft.firstName[0] : '?') + (draft.lastName.isNotEmpty ? draft.lastName[0] : '')).toUpperCase();
    final pct = stats.pct;
    final tone = pct >= 78 ? _Tone.high : (pct >= 44 ? _Tone.mid : _Tone.low);
    final smartTip = pct >= 89
        ? 'Almost there — just the final review left!'
        : pct >= 55
            ? 'Good progress. Still missing: ${stats.missing.take(2).join(', ')}.'
            : stats.missing.isNotEmpty
                ? 'Getting started — still need: ${stats.missing.take(2).join(', ')}.'
                : 'Just getting started — load to continue.';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(gradient: tone.avatarGradient, borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    if (draft.admissionNo.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
                        child: Text('#${draft.admissionNo}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Saved ${_timeAgo(draft.savedAt)}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('$pct% complete', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: tone.textColor)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation(tone.textColor),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.auto_awesome, size: 11, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 5),
                    Expanded(child: Text(smartTip, style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1)))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onResume(draft);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3CE1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Resume', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              IconButton(
                onPressed: () => _delete(draft, displayName),
                icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFDC2626)),
                tooltip: 'Delete draft $displayName',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int safePage, int totalPages, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: safePage <= 1 ? null : () => setState(() => _page = safePage - 1),
            child: const Text('← Prev', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text('Page $safePage of $totalPages · $totalCount draft${totalCount != 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(width: 8),
          TextButton(
            onPressed: safePage >= totalPages ? null : () => setState(() => _page = safePage + 1),
            child: const Text('Next →', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

enum _Tone { high, mid, low }

extension on _Tone {
  LinearGradient get avatarGradient {
    switch (this) {
      case _Tone.high:
        return const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]);
      case _Tone.mid:
        return const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]);
      case _Tone.low:
        return const LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)]);
    }
  }

  Color get textColor {
    switch (this) {
      case _Tone.high:
        return const Color(0xFF059669);
      case _Tone.mid:
        return const Color(0xFFD97706);
      case _Tone.low:
        return const Color(0xFF64748B);
    }
  }
}
