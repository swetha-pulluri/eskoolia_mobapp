import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/pin_item_entity.dart';
import '../providers/dashboard_provider.dart';

const int kMaxPins = 12;

/// One flat, pinnable "page" — a leaf entry built from [Modules.all], the
/// Flutter equivalent of web's `FLAT_INDEX` (`frontend/lib/routes.ts`).
/// Modules with sub-modules contribute one entry per sub-module; a module
/// with none (e.g. a single-page module) contributes itself.
class _PinnablePage {
  final String moduleId;
  final String moduleName;
  final Color moduleBg;
  final Color moduleIcon;
  final IconData icon;
  final String label;
  final String path;

  const _PinnablePage({
    required this.moduleId,
    required this.moduleName,
    required this.moduleBg,
    required this.moduleIcon,
    required this.icon,
    required this.label,
    required this.path,
  });
}

List<_PinnablePage> _buildFlatIndex() {
  final pages = <_PinnablePage>[];
  for (final module in Modules.all) {
    if (module.subModules.isEmpty) {
      pages.add(_PinnablePage(
        moduleId: module.id,
        moduleName: module.name,
        moduleBg: module.bgColor,
        moduleIcon: module.iconColor,
        icon: module.icon,
        label: module.name,
        path: module.path,
      ));
    } else {
      for (final sub in module.subModules) {
        pages.add(_PinnablePage(
          moduleId: module.id,
          moduleName: module.name,
          moduleBg: module.bgColor,
          moduleIcon: module.iconColor,
          icon: sub.icon ?? module.icon,
          label: sub.label,
          path: sub.path,
        ));
      }
    }
  }
  return pages;
}

/// Opens the "Manage Quick Access" modal — a 1:1 port of
/// `frontend/components/home/ManagePinsModal.tsx`: search + a module-grouped
/// list of every page, each with an immediate Pin/Unpin toggle (no Save/
/// Cancel — matches the web's own live-editing behavior, since pins persist
/// to local storage on every tap either way). Presented as a large
/// draggable bottom sheet rather than web's centered dialog — the standard
/// mobile adaptation of a heavy-content modal, same content and behavior.
void showManagePinsModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => _ManagePinsSheet(scrollController: scrollController),
    ),
  );
}

class _ManagePinsSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _ManagePinsSheet({required this.scrollController});

  @override
  ConsumerState<_ManagePinsSheet> createState() => _ManagePinsSheetState();
}

class _ManagePinsSheetState extends ConsumerState<_ManagePinsSheet> {
  final _searchController = TextEditingController();
  final _flatIndex = _buildFlatIndex();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(pinsProvider);
    final pins = pinsAsync.value ?? const <PinItemEntity>[];
    final atMax = pins.length >= kMaxPins;

    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _flatIndex
        : _flatIndex.where((p) => p.label.toLowerCase().contains(query) || p.moduleName.toLowerCase().contains(query)).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                const Icon(Icons.star, size: 17, color: AppColors.brandPurple),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Manage Quick Access', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink1)),
                ),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pin up to $kMaxPins pages for fast access · ${pins.length}/$kMaxPins pinned',
                style: const TextStyle(fontSize: 12, color: AppColors.ink3),
              ),
            ),
          ),
          if (pins.isNotEmpty) _currentPins(pins),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search pages to pin…',
                hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.ink3),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.ink3),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: AppColors.bg2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No pages match "$query"', style: const TextStyle(fontSize: 13, color: AppColors.ink3)),
                    ),
                  )
                : ListView(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: _buildGroupedRows(filtered, pins, atMax),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _currentPins(List<PinItemEntity> pins) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT PINS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pin in pins)
                Container(
                  padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
                  decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pin.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandPurple)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => ref.read(pinsProvider.notifier).removePin(pin.path),
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close, size: 13, color: AppColors.brandPurple),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedRows(List<_PinnablePage> pages, List<PinItemEntity> pins, bool atMax) {
    final widgets = <Widget>[];
    String? lastModule;
    for (final page in pages) {
      if (page.moduleName != lastModule) {
        lastModule = page.moduleName;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(
            page.moduleName.toUpperCase(),
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.5),
          ),
        ));
      }
      final isPinned = pins.any((p) => p.path == page.path);
      final disabled = atMax && !isPinned;
      widgets.add(_PageRow(
        page: page,
        isPinned: isPinned,
        disabled: disabled,
        onToggle: () {
          if (isPinned) {
            ref.read(pinsProvider.notifier).removePin(page.path);
          } else if (!atMax) {
            ref.read(pinsProvider.notifier).addPin(PinItemEntity(path: page.path, label: page.label, moduleId: page.moduleId));
          }
        },
      ));
    }
    return widgets;
  }
}

class _PageRow extends StatelessWidget {
  final _PinnablePage page;
  final bool isPinned;
  final bool disabled;
  final VoidCallback onToggle;

  const _PageRow({required this.page, required this.isPinned, required this.disabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        onTap: disabled ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: page.moduleBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(page.icon, size: 15, color: page.moduleIcon),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink1)),
                    Text(page.path, style: const TextStyle(fontSize: 10.5, color: AppColors.ink3), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 14, color: isPinned ? AppColors.brandPurple : AppColors.ink3),
                  const SizedBox(width: 4),
                  Text(
                    isPinned ? 'Unpin' : 'Pin',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPinned ? AppColors.brandPurple : AppColors.ink3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
