import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared building blocks for the Multi Subject Assignment screen — ported
/// from frontend/components/students/StudentMultiClassPanel.tsx +
/// StudentMultiClassPanel.module.css (Ring, SubBadge, PreviewBadges, Chk,
/// the editable ModuleCard option-picker, and the compact ellipsis pager).

/// Mirrors `.checkBox` / `.checkBoxOn` — a 16×16 rounded-square checkbox.
class Chk extends StatelessWidget {
  final bool checked;
  final VoidCallback? onChanged;
  const Chk({super.key, required this.checked, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: checked ? const Color(0xFF6C4CF1) : Colors.white,
          border: Border.all(color: checked ? const Color(0xFF6C4CF1) : const Color(0xFFE8E3D8), width: 1.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: checked ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
      ),
    );
  }
}

/// Mirrors `.subBadge` — a two-part badge: a colored monospace tag chip
/// followed by a value label.
class SubBadge extends StatelessWidget {
  final String tag;
  final String value;
  final Color tagColor;
  final bool dim;
  final bool err;
  const SubBadge({super.key, required this.tag, required this.value, required this.tagColor, this.dim = false, this.err = false});

  @override
  Widget build(BuildContext context) {
    final bg = err ? const Color(0xFFFFF5F5) : (dim ? const Color(0xFFF5F2E8) : Colors.white);
    final borderColor = err ? const Color(0xFFFFD0CC) : (dim ? const Color(0xFFF0ECE3) : const Color(0xFFE8E3D8));
    final valColor = err ? const Color(0xFFE5534B) : (dim ? const Color(0xFF908AAC) : const Color(0xFF19162C));
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 2, 7, 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5), border: Border.all(color: borderColor)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(2)),
            child: Text(tag, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: valColor)),
        ],
      ),
    );
  }
}

/// Mirrors the `PreviewBadges` component — "WILL BE ASSIGNED" badge row.
class PreviewBadges extends StatelessWidget {
  final String lang2;
  final String lang3;
  final List<String> sports;
  final List<String> arts;
  const PreviewBadges({super.key, required this.lang2, required this.lang3, required this.sports, required this.arts});

  @override
  Widget build(BuildContext context) {
    final total = 7 + (lang2.isNotEmpty ? 1 : 0) + (lang3.isNotEmpty ? 1 : 0) + sports.length + arts.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'WILL BE ASSIGNED',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFC4BEDD)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const SubBadge(tag: 'MAN', value: '+7', tagColor: Color(0xFF1E9B6B), dim: true),
            lang2.isNotEmpty
                ? SubBadge(tag: 'L2', value: lang2, tagColor: const Color(0xFF2C56A1))
                : const SubBadge(tag: 'L2', value: 'missing', tagColor: Color(0xFFB3261E), err: true),
            lang3.isNotEmpty
                ? SubBadge(tag: 'L3', value: lang3, tagColor: const Color(0xFF915A1A))
                : const SubBadge(tag: 'L3', value: 'missing', tagColor: Color(0xFFB3261E), err: true),
            for (final sp in sports) SubBadge(tag: 'SP', value: sp, tagColor: const Color(0xFFA0264A)),
            for (final ar in arts) SubBadge(tag: 'AR', value: ar, tagColor: const Color(0xFF5231B5)),
            Text('$total total', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFC4BEDD))),
          ],
        ),
      ],
    );
  }
}

/// Mirrors the inline SVG `Ring` component — a circular progress ring with a
/// centered percentage label (or "—" at 0%).
class RingProgress extends StatelessWidget {
  final double pct;
  final double size;
  const RingProgress({super.key, required this.pct, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _RingPainter(pct)),
          Text(
            pct <= 0 ? '—' : '${pct.round()}%',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14)),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  static const _sw = 3.0;
  _RingPainter(this.pct);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - _sw;
    final bg = Paint()
      ..color = const Color(0xFFF0F0F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sw;
    canvas.drawCircle(center, radius, bg);
    if (pct <= 0) return;
    final color = pct >= 85 ? const Color(0xFF4729F4) : (pct >= 60 ? const Color(0xFFB4721B) : const Color(0xFFC2264E));
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sw
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * (pct / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct;
}

/// Compact page list with ellipsis — mirrors `buildPageList(current,total)`.
List<Object> buildPageList(int current, int total) {
  if (total <= 7) return List.generate(total, (i) => i + 1);
  final pages = <Object>[];
  pages.add(1);
  final left = math.max(2, current - 1);
  final right = math.min(total - 1, current + 1);
  if (left > 2) pages.add('…');
  for (var p = left; p <= right; p++) {
    pages.add(p);
  }
  if (right < total - 1) pages.add('…');
  pages.add(total);
  return pages;
}

/// A grid whose column count adapts at CSS-equivalent breakpoints — mirrors
/// the reference's `grid-template-columns: repeat(N, 1fr)` + `@media` rules.
/// [breakpoints] maps a max-width threshold to the column count that applies
/// at or below it; the smallest matching threshold wins.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int baseCols;
  final Map<double, int> breakpoints;
  final double gap;
  const ResponsiveGrid({super.key, required this.children, required this.baseCols, this.breakpoints = const {}, this.gap = 9});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      var cols = baseCols;
      final w = constraints.maxWidth;
      final sortedKeys = breakpoints.keys.toList()..sort();
      for (final bp in sortedKeys) {
        if (w <= bp) {
          cols = breakpoints[bp]!;
          break;
        }
      }
      cols = cols.clamp(1, children.length);
      final itemWidth = (w - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
      );
    });
  }
}

/// Mirrors `interface CardDef { title, options }` — an editable option-card
/// definition (2nd Language / 3rd Language / Sports / Arts).
class CardDef {
  final String title;
  final List<String> options;
  const CardDef({required this.title, required this.options});
}

/// Mirrors the `ModuleCard` component: a bordered card of checkable options
/// with an inline "edit card" mode (rename title, add/edit/delete options).
class ModuleOptionCard extends StatefulWidget {
  final CardDef cardDef;
  final IconData icon;
  final String chipLabel;
  final Color chipBg;
  final Color chipText;
  final Color chipBorder;
  final bool multi;
  final Object value; // String when !multi, List<String> when multi
  final ValueChanged<Object> onChange;
  final ValueChanged<CardDef> onCardChange;
  final List<String> disabledOptions;

  const ModuleOptionCard({
    super.key,
    required this.cardDef,
    required this.icon,
    required this.chipLabel,
    required this.chipBg,
    required this.chipText,
    required this.chipBorder,
    required this.multi,
    required this.value,
    required this.onChange,
    required this.onCardChange,
    this.disabledOptions = const [],
  });

  @override
  State<ModuleOptionCard> createState() => _ModuleOptionCardState();
}

class _ModuleOptionCardState extends State<ModuleOptionCard> {
  bool _editMode = false;
  late final TextEditingController _titleCtrl = TextEditingController(text: widget.cardDef.title);
  late List<String> _draftOpts = List.of(widget.cardDef.options);
  int? _editOptIdx;
  late final TextEditingController _editOptCtrl = TextEditingController();
  late final TextEditingController _newOptCtrl = TextEditingController();
  final _editOptFocus = FocusNode();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _editOptCtrl.dispose();
    _newOptCtrl.dispose();
    _editOptFocus.dispose();
    super.dispose();
  }

  bool _isSelected(String opt) => widget.multi ? (widget.value as List<String>).contains(opt) : widget.value == opt;
  bool _isDisabled(String opt) => widget.disabledOptions.contains(opt);

  void _toggle(String opt) {
    if (_isDisabled(opt)) return;
    if (widget.multi) {
      final list = List<String>.from(widget.value as List<String>);
      if (list.contains(opt)) {
        list.remove(opt);
      } else {
        list.add(opt);
      }
      widget.onChange(list);
    } else {
      widget.onChange(widget.value == opt ? '' : opt);
    }
  }

  void _enterEditMode() {
    setState(() {
      _titleCtrl.text = widget.cardDef.title;
      _draftOpts = List.of(widget.cardDef.options);
      _editMode = true;
    });
  }

  void _saveCard() {
    final t = _titleCtrl.text.trim().isEmpty ? widget.cardDef.title : _titleCtrl.text.trim();
    final opts = _draftOpts.where((o) => o.trim().isNotEmpty).toList();
    widget.onCardChange(CardDef(title: t, options: opts));
    if (widget.multi) {
      final list = (widget.value as List<String>).where((v) => opts.contains(v)).toList();
      widget.onChange(list);
    } else if (!opts.contains(widget.value as String)) {
      widget.onChange('');
    }
    setState(() {
      _editMode = false;
      _editOptIdx = null;
    });
  }

  void _discardCard() {
    setState(() {
      _titleCtrl.text = widget.cardDef.title;
      _draftOpts = List.of(widget.cardDef.options);
      _editMode = false;
      _editOptIdx = null;
      _newOptCtrl.clear();
    });
  }

  void _commitOpt(int idx) {
    final v = _editOptCtrl.text.trim();
    if (v.isNotEmpty) {
      setState(() => _draftOpts[idx] = v);
    }
    setState(() => _editOptIdx = null);
  }

  void _deleteOpt(int idx) {
    setState(() => _draftOpts.removeAt(idx));
  }

  void _addOpt() {
    final v = _newOptCtrl.text.trim();
    if (v.isEmpty || _draftOpts.contains(v)) return;
    setState(() {
      _draftOpts.add(v);
      _newOptCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_editMode) return _buildEditMode();
    return _buildViewMode();
  }

  Widget _buildViewMode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8E3D8)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 13, color: const Color(0xFF19162C)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  widget.cardDef.title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF19162C)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.chipBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: widget.chipBorder),
                ),
                child: Text(widget.chipLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: widget.chipText)),
              ),
              const SizedBox(width: 5),
              InkWell(
                onTap: _enterEditMode,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.edit_outlined, size: 12, color: Color(0xFFC4BEDD)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final opt in widget.cardDef.options)
            Opacity(
              opacity: _isDisabled(opt) ? 0.4 : 1,
              child: InkWell(
                onTap: _isDisabled(opt) ? null : () => _toggle(opt),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Chk(checked: _isSelected(opt), onChanged: _isDisabled(opt) ? null : () => _toggle(opt)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(opt, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF48436A))),
                      ),
                      if (_isDisabled(opt)) ...[
                        const SizedBox(width: 5),
                        const Flexible(child: Text('(already in L2)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Color(0xFF908AAC)))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF6C4CF1)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFEFEAFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF19162C)),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFF6C4CF1), width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFF6C4CF1), width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFF6C4CF1), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              InkWell(
                onTap: _saveCard,
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF6C4CF1), borderRadius: BorderRadius.circular(7)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Save', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(width: 5),
              InkWell(
                onTap: _discardCard,
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: const Color(0xFFE8E3D8), borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.close, size: 13, color: Color(0xFF48436A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _draftOpts.length; i++) _optRow(i),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newOptCtrl,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF19162C)),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '+ Add option…',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF908AAC)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFE8E3D8), width: 1.5)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFE8E3D8), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFF6C4CF1), width: 1.5)),
                    ),
                    onSubmitted: (_) => _addOpt(),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _addOpt,
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF6C4CF1), width: 1.5), borderRadius: BorderRadius.circular(7)),
                    child: const Text('Add', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF6C4CF1))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optRow(int idx) {
    final opt = _draftOpts[idx];
    final editing = _editOptIdx == idx;
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8E3D8)), borderRadius: BorderRadius.circular(7)),
      child: Row(
        children: [
          Expanded(
            child: editing
                ? Focus(
                    onFocusChange: (has) {
                      if (!has) _commitOpt(idx);
                    },
                    child: TextField(
                      controller: _editOptCtrl,
                      autofocus: true,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF19162C)),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xFF6C4CF1), width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xFF6C4CF1), width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xFF6C4CF1), width: 1.5)),
                      ),
                      onSubmitted: (_) => _commitOpt(idx),
                    ),
                  )
                : Text(opt, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF48436A))),
          ),
          InkWell(
            onTap: () => setState(() {
              _editOptIdx = idx;
              _editOptCtrl.text = opt;
            }),
            borderRadius: BorderRadius.circular(5),
            child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.edit_outlined, size: 11, color: Color(0xFFC4BEDD))),
          ),
          InkWell(
            onTap: () => _deleteOpt(idx),
            borderRadius: BorderRadius.circular(5),
            child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.close, size: 12, color: Color(0xFFC4BEDD))),
          ),
        ],
      ),
    );
  }
}
