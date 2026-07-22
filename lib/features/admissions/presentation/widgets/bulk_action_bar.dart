import 'package:flutter/material.dart';

const List<Map<String, String>> kBulkStageOptions = [
  {'value': 'new', 'label': 'New'},
  {'value': 'contacted', 'label': 'In Conversation'},
  {'value': 'visited', 'label': 'Decision Pending'},
  {'value': 'enrolled', 'label': 'Enrolled'},
  {'value': 'declined', 'label': 'Cold / Dropped'},
];

/// Bulk Action Bar — floating pill shown at the bottom of the screen once
/// one or more rows are selected. Converted from web
/// `command-center/BulkActionBar.tsx`. (The "Send Message" button is
/// commented out / hidden in the web source itself, so it's omitted here.)
class BulkActionBar extends StatefulWidget {
  final int selectedCount;
  final bool isLoading;
  final ValueChanged<String> onMoveStage;
  final ValueChanged<String> onAssign;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onMoveStage,
    required this.onAssign,
    required this.onDelete,
    required this.onClear,
    this.isLoading = false,
  });

  @override
  State<BulkActionBar> createState() => _BulkActionBarState();
}

class _BulkActionBarState extends State<BulkActionBar> {
  final _assignController = TextEditingController();

  @override
  void dispose() {
    _assignController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCount == 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Opacity(
          opacity: widget.isLoading ? 0.7 : 1,
          child: Container(
            constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16), boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
            ]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.selectedCount} selected', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 12),
                Container(width: 1, height: 18, color: const Color(0x33FFFFFF)),
                const SizedBox(width: 12),
                _pillButton(
                  icon: Icons.arrow_forward,
                  label: 'Stage',
                  onSelected: widget.onMoveStage,
                  options: kBulkStageOptions,
                ),
                const SizedBox(width: 8),
                _assignButton(),
                const Spacer(),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFF87171)),
                  tooltip: 'Delete selected',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
                IconButton(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                  tooltip: 'Clear selection',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillButton({required IconData icon, required String label, required ValueChanged<String> onSelected, required List<Map<String, String>> options}) {
    return PopupMenuButton<String>(
      tooltip: '',
      color: Colors.white,
      offset: const Offset(0, -180),
      itemBuilder: (context) => options
          .map((o) => PopupMenuItem<String>(value: o['value'], child: Text(o['label']!, style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))))
          .toList(),
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
          const SizedBox(width: 3),
          const Icon(Icons.keyboard_arrow_down, size: 13, color: Colors.white),
        ]),
      ),
    );
  }

  Widget _assignButton() {
    return PopupMenuButton<String>(
      tooltip: '',
      color: Colors.white,
      offset: const Offset(0, -100),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setMenuState) => SizedBox(
              width: 200,
              child: TextField(
                controller: _assignController,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(hintText: 'Name, press Enter…', isDense: true, border: OutlineInputBorder()),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    widget.onAssign(v.trim());
                    _assignController.clear();
                  }
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(8)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Text('👤 Assign', style: TextStyle(fontSize: 13, color: Colors.white)),
          SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down, size: 13, color: Colors.white),
        ]),
      ),
    );
  }
}
