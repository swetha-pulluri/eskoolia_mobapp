import 'package:flutter/material.dart';
import '../../domain/inspire_hub_store.dart';
import '../../domain/models/competition.dart';

const _kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// History tab — every draft and finalised event stored on this device.
/// Mirrors web's HistoryPanel.jsx: search, status filter, a collapsible
/// "More filters" panel (Type / Level / Month / Sort by), duplicate/delete,
/// tap to reopen in Compose.
class InspireHubHistoryTab extends StatefulWidget {
  final InspireHubStore store;
  final int refreshKey;
  final ValueChanged<Competition> onEdit;
  final VoidCallback onNew;
  final VoidCallback onChanged;
  const InspireHubHistoryTab({
    super.key,
    required this.store,
    required this.refreshKey,
    required this.onEdit,
    required this.onNew,
    required this.onChanged,
  });

  @override
  State<InspireHubHistoryTab> createState() => _InspireHubHistoryTabState();
}

class _InspireHubHistoryTabState extends State<InspireHubHistoryTab> {
  String _query = '';
  String _status = 'all'; // all | draft | final
  String _sort = 'date_desc';
  String _type = ''; // '' = any
  String _level = ''; // '' = any
  int? _month; // null = any
  bool _filtersOpen = false;

  int get _extraFilterCount => [_type.isNotEmpty, _level.isNotEmpty, _month != null, _sort != 'date_desc'].where((v) => v).length;

  List<String> _uniqueValues(List<Competition> rows, String Function(Competition) pick) {
    final set = <String>{};
    for (final r in rows) {
      final v = pick(r);
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _delete(Competition c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this event?'),
        content: Text('"${c.name}" and every result inside it will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFEE2E2), foregroundColor: const Color(0xFFB91C1C)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.remove(c.id);
      widget.onChanged();
    }
  }

  Future<void> _duplicate(Competition c) async {
    final now = DateTime.now().toIso8601String();
    final copy = c.copyWith(status: 'draft', name: '${c.name} (copy)', finalisedAt: null, createdAt: now, updatedAt: now);
    await widget.store.saveDraft(
      Competition(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        backendId: null,
        isLocal: true,
        name: copy.name,
        date: copy.date,
        level: copy.level,
        compType: copy.compType,
        sportType: copy.sportType,
        location: copy.location,
        opponent: copy.opponent,
        notes: copy.notes,
        houseAId: copy.houseAId,
        houseBId: copy.houseBId,
        classes: copy.classes,
        className: copy.className,
        sections: copy.sections,
        status: 'draft',
        results: copy.results,
        createdAt: now,
        updatedAt: now,
      ),
    );
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    var rows = widget.store.list();
    if (_status != 'all') rows = rows.where((r) => r.status == _status).toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      rows = rows
          .where((r) => r.name.toLowerCase().contains(q) || r.location.toLowerCase().contains(q) || r.opponent.toLowerCase().contains(q) || r.notes.toLowerCase().contains(q))
          .toList();
    }
    if (_type.isNotEmpty) rows = rows.where((r) => r.compType.value == _type).toList();
    if (_level.isNotEmpty) rows = rows.where((r) => r.level.value == _level).toList();
    if (_month != null) rows = rows.where((r) => DateTime.tryParse(r.date)?.month == _month! + 1).toList();
    rows.sort((a, b) {
      switch (_sort) {
        case 'date_asc':
          return a.date.compareTo(b.date);
        case 'name_asc':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'name_desc':
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        default:
          return b.date.compareTo(a.date);
      }
    });

    final all = widget.store.list();
    final drafts = all.where((r) => r.status == 'draft').length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ARCHIVE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: Color(0xFF64748B))),
                        const Text('Past events & drafts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        Text('${all.length} events · $drafts draft${drafts == 1 ? '' : 's'}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                    onPressed: widget.onNew,
                    child: const Text('+ New event'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: 'Search by name, location, opponent…',
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  _StatusChip(label: 'All', count: all.length, on: _status == 'all', onTap: () => setState(() => _status = 'all')),
                  _StatusChip(label: 'Drafts', count: drafts, on: _status == 'draft', color: const Color(0xFFF59E0B), onTap: () => setState(() => _status = 'draft')),
                  _StatusChip(label: 'Finalised', count: all.length - drafts, on: _status == 'final', color: const Color(0xFF10B981), onTap: () => setState(() => _status = 'final')),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
                    icon: const Icon(Icons.filter_alt_outlined, size: 15, color: Color(0xFF64748B)),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('More filters', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        if (_extraFilterCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(20)),
                            child: Text('$_extraFilterCount', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                        const SizedBox(width: 3),
                        Icon(_filtersOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 15, color: const Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
              if (_filtersOpen) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown<String>(
                        label: 'Type',
                        value: _type.isEmpty ? null : _type,
                        anyLabel: 'Any type',
                        items: [for (final t in _uniqueValues(all, (r) => r.compType.value)) (t, t)],
                        onChanged: (v) => setState(() => _type = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown<String>(
                        label: 'Level',
                        value: _level.isEmpty ? null : _level,
                        anyLabel: 'Any level',
                        items: [for (final l in _uniqueValues(all, (r) => r.level.value)) (l, CompetitionLevel.fromValue(l).label)],
                        onChanged: (v) => setState(() => _level = v ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown<int>(
                        label: 'Month',
                        value: _month,
                        anyLabel: 'Any month',
                        items: [for (var i = 0; i < _kMonths.length; i++) (i, _kMonths[i])],
                        onChanged: (v) => setState(() => _month = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown<String>(
                        label: 'Sort by',
                        value: _sort,
                        anyLabel: null,
                        items: const [
                          ('date_desc', 'Date · newest'),
                          ('date_asc', 'Date · oldest'),
                          ('name_asc', 'Name · A→Z'),
                          ('name_desc', 'Name · Z→A'),
                        ],
                        onChanged: (v) => setState(() => _sort = v ?? 'date_desc'),
                      ),
                    ),
                  ],
                ),
                if (_extraFilterCount > 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() {
                        _type = '';
                        _level = '';
                        _month = null;
                        _sort = 'date_desc';
                      }),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('Clear all', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📭', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text('No events match these filters yet.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _EventRow(
                    competition: rows[i],
                    onTap: () => widget.onEdit(rows[i]),
                    onDelete: () => _delete(rows[i]),
                    onDuplicate: () => _duplicate(rows[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String? anyLabel;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  const _FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.anyLabel,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF64748B))),
        const SizedBox(height: 3),
        DropdownButtonFormField<T?>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600),
          items: [
            if (anyLabel != null) DropdownMenuItem<T?>(value: null, child: Text(anyLabel!, overflow: TextOverflow.ellipsis)),
            for (final item in items) DropdownMenuItem<T?>(value: item.$1, child: Text(item.$2, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool on;
  final Color color;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.count, required this.on, required this.onTap, this.color = const Color(0xFF0F172A)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? color : Colors.white,
          border: Border.all(color: on ? color : const Color(0xFFE2E8F0), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: on ? Colors.white : const Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Competition competition;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  const _EventRow({required this.competition, required this.onTap, required this.onDelete, required this.onDuplicate});

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final wins = c.results.where((r) => r.position == '1st').length;
    final reviewed = c.results.where((r) => r.aiResponse.isNotEmpty).length;
    final isDraft = c.status == 'draft';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: Text(c.compType.icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c.name.isEmpty ? 'Untitled event' : c.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDraft ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isDraft ? 'DRAFT' : 'FINAL',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDraft ? const Color(0xFF92400E) : const Color(0xFF047857)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📅 ${c.date} · ${c.level.label}${c.location.isNotEmpty ? ' · 📍 ${c.location}' : ''}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _tag('${c.results.length} participant${c.results.length == 1 ? '' : 's'}'),
                      if (wins > 0) _tag('🥇 $wins', tone: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
                      if (reviewed > 0) _tag('✨ $reviewed review${reviewed == 1 ? '' : 's'}', tone: const Color(0xFFF3E8FF), fg: const Color(0xFF7C3AED)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
              onSelected: (v) => v == 'delete' ? onDelete() : onDuplicate(),
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'duplicate', child: Text('⎘ Duplicate')),
                PopupMenuItem(value: 'delete', child: Text('🗑 Delete', style: TextStyle(color: Color(0xFFB91C1C)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, {Color tone = const Color(0xFFF1F5F9), Color fg = const Color(0xFF334155)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
