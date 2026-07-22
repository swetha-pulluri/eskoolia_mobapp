import 'dart:async';
import 'package:flutter/material.dart';

const List<String> _kDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime _parseIso(String s) => DateTime.parse('${s}T00:00:00');
String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _monday(DateTime d) {
  final weekday = d.weekday; // 1=Mon..7=Sun
  return d.subtract(Duration(days: weekday - 1));
}

List<DateTime> _weekDates(DateTime center) {
  final mon = _monday(center);
  return List.generate(7, (i) => mon.add(Duration(days: i)));
}

List<Map<String, String>> _monthOptions(DateTime selected) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return List.generate(12, (i) {
    final m = i + 1;
    final value = '${selected.year}-${m.toString().padLeft(2, '0')}';
    return {'value': value, 'label': '${months[i]} ${selected.year}'};
  });
}

List<Map<String, String>> _weekOptionsForMonth(String monthValue) {
  final parts = monthValue.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0);
  final out = <Map<String, String>>[];
  var cursor = _monday(firstDay);
  var idx = 1;
  while (cursor.isBefore(lastDay) || _fmt(cursor) == _fmt(lastDay)) {
    if (idx > 7) break;
    final weekStart = cursor;
    final weekEnd = cursor.add(const Duration(days: 6));
    final inMonthStart = weekStart.month == month ? weekStart : firstDay;
    final inMonthEnd = weekEnd.month == month ? weekEnd : lastDay;
    out.add({'value': _fmt(weekStart), 'label': 'Week $idx (${inMonthStart.day}-${inMonthEnd.day})'});
    cursor = cursor.add(const Duration(days: 7));
    idx++;
  }
  return out;
}

/// Global Controls — converted from web
/// `attendance/student/components/GlobalControls.tsx`. The date strip
/// (month/week pickers, prev/next, day chips), search + status/section
/// filters, and the "mark all visible" P/A/L buttons.
class GlobalControls extends StatefulWidget {
  final String selectedDate;
  final ValueChanged<String> onDateChange;
  final String searchQuery;
  final ValueChanged<String> onSearchChange;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChange;
  final String sectionFilter;
  final ValueChanged<String> onSectionFilterChange;
  final void Function(String status) onMarkAllVisible;
  final bool allVisibleMarked;

  const GlobalControls({
    super.key,
    required this.selectedDate,
    required this.onDateChange,
    required this.searchQuery,
    required this.onSearchChange,
    required this.statusFilter,
    required this.onStatusFilterChange,
    required this.sectionFilter,
    required this.onSectionFilterChange,
    required this.onMarkAllVisible,
    this.allVisibleMarked = false,
  });

  @override
  State<GlobalControls> createState() => _GlobalControlsState();
}

class _GlobalControlsState extends State<GlobalControls> {
  bool _confirmAbsent = false;
  Timer? _confirmTimer;
  late final _searchController = TextEditingController(text: widget.searchQuery);

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _moveWeek(int direction) {
    final d = _parseIso(widget.selectedDate).add(Duration(days: 7 * direction));
    widget.onDateChange(_fmt(d));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _parseIso(widget.selectedDate);
    final dateStrip = _weekDates(selected);
    final today = DateTime.now();
    final todayStr = _fmt(today);
    final selectedMonth = widget.selectedDate.substring(0, 7);
    final months = _monthOptions(selected);
    final weeks = _weekOptionsForMonth(selectedMonth);
    final selectedWeekStart = _fmt(_monday(selected));
    final weekValue = weeks.any((w) => w['value'] == selectedWeekStart) ? selectedWeekStart : (weeks.isNotEmpty ? weeks.first['value']! : widget.selectedDate);

    final first = dateStrip.first;
    final last = dateStrip.last;
    const monthsAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final stripLabel = 'Week of ${first.day} ${monthsAbbr[first.month - 1]} – ${last.day} ${monthsAbbr[last.month - 1]}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Row 1 — date strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6)))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text('$stripLabel:', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  _smallSelect(value: selectedMonth, items: months, onChanged: (v) {
                    final d = DateTime.parse('$v-01');
                    widget.onDateChange(_fmt(d));
                  }),
                  const SizedBox(width: 4),
                  _smallIconButton('←', onTap: () => _moveWeek(-1), tooltip: 'Previous week'),
                  const SizedBox(width: 4),
                  _smallSelect(value: weekValue, items: weeks, onChanged: (v) {
                    if (v != null) widget.onDateChange(v);
                  }),
                  const SizedBox(width: 4),
                  _smallIconButton('→', onTap: () => _moveWeek(1), tooltip: 'Next week'),
                  const SizedBox(width: 4),
                  _todayButton(enabled: widget.selectedDate != todayStr, onTap: () => widget.onDateChange(todayStr)),
                  const SizedBox(width: 8),
                  ...dateStrip.map((d) => _dayChip(d, selected: widget.selectedDate == _fmt(d), todayStr: todayStr)),
                  const SizedBox(width: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0A8C5A), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Auto-saving', style: TextStyle(fontSize: 11, color: Color(0xFF8B8B9E))),
                  ]),
                ],
              ),
            ),
          ),
          // Row 2 — search + filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _searchController,
                      onChanged: widget.onSearchChange,
                      decoration: InputDecoration(
                        hintText: 'Search students…',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)),
                        prefixIcon: const Icon(Icons.search, size: 15, color: Color(0xFF9CA0AE)),
                        suffixIcon: widget.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 14, color: Color(0xFF9CA0AE)),
                                onPressed: () {
                                  _searchController.clear();
                                  widget.onSearchChange('');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFFAFAFD),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4729F4))),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _filterSelect(
                    value: widget.statusFilter,
                    minWidth: 120,
                    items: const {'all': 'All students', 'present': 'Present', 'absent': 'Absent', 'late': 'Late', 'unmarked': 'Unmarked'},
                    onChanged: widget.onStatusFilterChange,
                  ),
                  const SizedBox(width: 10),
                  _filterSelect(
                    value: widget.sectionFilter,
                    minWidth: 100,
                    items: const {'all': 'All sections', 'A': 'Section A', 'B': 'Section B', 'C': 'Section C'},
                    onChanged: widget.onSectionFilterChange,
                  ),
                  const SizedBox(width: 16),
                  const Text('Mark all visible:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  _markAllButton('P', bg: const Color(0xFFE4F6ED), fg: const Color(0xFF0A8C5A), enabled: !widget.allVisibleMarked, onTap: () => widget.onMarkAllVisible('present'), tooltip: widget.allVisibleMarked ? 'All visible students already marked' : 'Mark all visible present'),
                  const SizedBox(width: 4),
                  _markAllAbsentButton(),
                  const SizedBox(width: 4),
                  _markAllButton('L', bg: const Color(0xFFFDF1DC), fg: const Color(0xFFB4721B), enabled: true, onTap: () => widget.onMarkAllVisible('late')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallSelect({required String value, required List<Map<String, String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((i) => i['value'] == value) ? value : null,
          isDense: true,
          style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A2E)),
          items: items.map((i) => DropdownMenuItem(value: i['value'], child: Text(i['label']!))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _smallIconButton(String label, {required VoidCallback onTap, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3A3A4A))),
        ),
      ),
    );
  }

  Widget _todayButton({required bool enabled, required VoidCallback onTap}) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Tooltip(
        message: 'Return to current date',
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFE4F6ED), border: Border.all(color: const Color(0xFFBDE9D0)), borderRadius: BorderRadius.circular(8)),
            child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0A8C5A))),
          ),
        ),
      ),
    );
  }

  Widget _dayChip(DateTime d, {required bool selected, required String todayStr}) {
    final ds = _fmt(d);
    final isToday = ds == todayStr;
    final isWeekend = d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
    final isPast = ds.compareTo(todayStr) < 0;

    Color bg, fg, border;
    if (selected && isToday) {
      bg = const Color(0xFF4729F4);
      fg = Colors.white;
      border = const Color(0xFF4729F4);
    } else if (selected && !isToday) {
      bg = const Color(0xFFFFF4D6);
      fg = const Color(0xFF9A5C00);
      border = const Color(0xFFF4DCA7);
    } else if (isToday) {
      bg = Colors.white;
      fg = const Color(0xFF4729F4);
      border = const Color(0xFF4729F4);
    } else if (isPast) {
      bg = const Color(0xFFF6F4FF);
      fg = const Color(0xFF4729F4);
      border = const Color(0x334729F4);
    } else {
      bg = Colors.white;
      fg = const Color(0xFF9CA0AE);
      border = const Color(0xFFE6E6EC);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Opacity(
        opacity: isWeekend && !selected ? 0.5 : 1,
        child: Tooltip(
          message: isWeekend ? 'Weekend' : '',
          child: InkWell(
            onTap: () {
              if (!selected) widget.onDateChange(ds);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 46, minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: isToday && !selected ? 2 : 1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_kDayNames[d.weekday - 1], style: TextStyle(fontSize: 9, color: fg, fontWeight: isToday ? FontWeight.w600 : FontWeight.normal)),
                  Text('${d.day}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFDDF5EA), borderRadius: BorderRadius.circular(3)),
                      child: Text('TODAY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: selected ? Colors.white : const Color(0xFF0A8C5A))),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterSelect({required String value, required double minWidth, required Map<String, String> items, required ValueChanged<String> onChanged}) {
    return Container(
      height: 36,
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFD), border: Border.all(color: const Color(0xFFE6E6EC)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A2E)),
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _markAllButton(String label, {required Color bg, required Color fg, required bool enabled, required VoidCallback onTap, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ),
        ),
      ),
    );
  }

  Widget _markAllAbsentButton() {
    return Tooltip(
      message: 'Click twice to confirm marking ALL students absent',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: _confirmAbsent ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: InkWell(
          onTap: () {
            if (_confirmAbsent) {
              widget.onMarkAllVisible('absent');
              _confirmTimer?.cancel();
              setState(() => _confirmAbsent = false);
            } else {
              setState(() => _confirmAbsent = true);
              _confirmTimer?.cancel();
              _confirmTimer = Timer(const Duration(milliseconds: 2000), () {
                if (mounted) setState(() => _confirmAbsent = false);
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFFCE8EE), borderRadius: BorderRadius.circular(8)),
            child: const Text('A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFC2264E))),
          ),
        ),
      ),
    );
  }
}
