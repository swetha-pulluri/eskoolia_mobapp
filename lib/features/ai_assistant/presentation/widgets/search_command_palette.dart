import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../../core/utils/platform_capabilities.dart';
import '../../../widgets_panel/presentation/providers/widget_prefs_provider.dart';
import '../../data/ai_search.dart';
import '../../domain/models/flat_index_entry.dart';
import '../../domain/teacher_ai_flat_index.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk3 = Color(0xFF9197AE);

/// Opens the Search command palette from a root-navigator [BuildContext]
/// (needed because the header button that triggers this sits above
/// go_router's own `Navigator` — see `GlobalAppShell`'s class doc).
Future<void> showSearchCommandPalette(BuildContext navContext) {
  return showGeneralDialog(
    context: navContext,
    barrierDismissible: true,
    barrierLabel: 'Search',
    barrierColor: const Color(0x8F0F1222),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, _, _) => const _SearchCommandPaletteDialog(),
    transitionBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
}

/// Flutter port of `components/nav/CommandPalette.tsx` — a static fuzzy
/// search over `aiFlatIndex` (module + page names/paths), navigating on
/// select. No API calls, matching web's own purely-local matching.
class _SearchCommandPaletteDialog extends ConsumerStatefulWidget {
  const _SearchCommandPaletteDialog();

  @override
  ConsumerState<_SearchCommandPaletteDialog> createState() => _SearchCommandPaletteDialogState();
}

class _SearchCommandPaletteDialogState extends ConsumerState<_SearchCommandPaletteDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<FlatIndexEntry> _results = const [];

  @override
  void initState() {
    super.initState();
    _recompute('');
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _recompute(String query) {
    // Admin's `aiFlatIndex` only contains Admin routes — a Teacher searching
    // "fees" (or anything else) must resolve against their own
    // `teacherAiFlatIndex` instead, or every result sends them to an Admin
    // page they may not even have access to (and, for Fees specifically,
    // one that crashes — see `teacher_ai_flat_index.dart`'s doc comment).
    final role = ref.read(currentPortalRoleProvider);
    final index = role == 'teacher' ? teacherAiFlatIndex : null;
    final exact = query.trim().isEmpty ? null : exactMatch(query, index: index);
    setState(() {
      _results = query.trim().isEmpty ? const [] : (exact != null ? [exact] : localFuzzySearch(query, index: index));
      _selectedIndex = 0;
    });
  }

  void _select(FlatIndexEntry entry) {
    ref.read(appRouterProvider).go(entry.path);
    Navigator.of(context).pop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (_results.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedIndex = (_selectedIndex + 1).clamp(0, _results.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _selectedIndex = (_selectedIndex - 1).clamp(0, _results.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _select(_results[_selectedIndex]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = screenWidth - 32 < 560.0 ? screenWidth - 32 : 560.0;
    final showKeyboardHints = isHoverCapablePlatform;

    Widget content = Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x2E0E1020), offset: Offset(0, 14), blurRadius: 32, spreadRadius: -10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _navBorder))),
            child: Row(
              children: [
                const Icon(Icons.search, size: 17, color: _navInk3),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    onChanged: _recompute,
                    decoration: const InputDecoration(
                      hintText: 'Search modules, pages…',
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(fontSize: 16, color: _navInk1),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _controller.clear();
                      _recompute('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: _navInk3),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4FB), border: Border.all(color: _navBorder), borderRadius: BorderRadius.circular(5)),
                  child: const Text('Esc', style: TextStyle(fontSize: 11, color: _navInk3, fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
          Flexible(
            child: _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Text(
                      _controller.text.trim().isEmpty ? 'Start typing to search' : 'No results for "${_controller.text.trim()}"',
                      style: const TextStyle(fontSize: 13, color: _navInk3),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(6),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final entry = _results[index];
                      final isSelected = index == _selectedIndex;
                      return InkWell(
                        onTap: () => _select(entry),
                        onHover: (hovering) {
                          if (hovering) setState(() => _selectedIndex = index);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF3F4FB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(color: entry.bg, borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: Icon(entry.icon, size: 13, color: entry.ic),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(entry.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _navInk1), overflow: TextOverflow.ellipsis),
                              ),
                              Text(entry.path, style: const TextStyle(fontSize: 11, color: _navInk3, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (showKeyboardHints)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _navBorder))),
              child: const Row(
                children: [
                  Text('↑↓ navigate', style: TextStyle(fontSize: 11, color: _navInk3)),
                  SizedBox(width: 16),
                  Text('↵ open', style: TextStyle(fontSize: 11, color: _navInk3)),
                  SizedBox(width: 16),
                  Text('Esc close', style: TextStyle(fontSize: 11, color: _navInk3)),
                ],
              ),
            ),
        ],
      ),
    );

    if (showKeyboardHints) {
      content = Focus(onKeyEvent: _onKey, autofocus: true, child: content);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 96),
        child: Material(color: Colors.transparent, child: content),
      ),
    );
  }
}
