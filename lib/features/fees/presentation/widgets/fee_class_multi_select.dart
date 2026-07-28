import 'package:flutter/material.dart';
import '../../../student/domain/models/school_class.dart';
import 'fee_config_styles.dart';

/// Mirrors the "APPLICABLE CLASSES" control in Fee Groups' create form and
/// edit panel — a chip-filled button that opens a searchable multi-select
/// (search box, Select all / Clear all, checkbox list, Apply selection).
/// The web version renders this as an absolutely-positioned dropdown panel;
/// here it opens as a modal bottom sheet, the same mobile adaptation this
/// app already uses elsewhere for search-driven web dropdowns.
class FeeClassMultiSelect extends StatelessWidget {
  final List<int> selectedIds;
  final List<SchoolClass> availableClasses;
  final ValueChanged<List<int>> onChanged;
  final String? errorText;

  const FeeClassMultiSelect({
    super.key,
    required this.selectedIds,
    required this.availableClasses,
    required this.onChanged,
    this.errorText,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ClassMultiSelectSheet(selectedIds: selectedIds, availableClasses: availableClasses),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: errorText != null ? const Color(0xFFEF4444) : feeConfigBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: selectedIds.isEmpty
                ? const Text('Select classes', style: TextStyle(color: Color(0xFF9AA0B2), fontSize: 13))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final id in selectedIds)
                        Chip(
                          label: Text(
                            availableClasses.where((c) => c.id == id).map((c) => c.name).firstOrNull ?? 'Class',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                          ),
                          backgroundColor: const Color(0xFFF4F5FB),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF6B7280)),
                          onDeleted: () => onChanged(selectedIds.where((v) => v != id).toList()),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
          ),
        ),
        FeeConfigFieldError(errorText),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${selectedIds.length} Classes Selected', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ClassMultiSelectSheet extends StatefulWidget {
  final List<int> selectedIds;
  final List<SchoolClass> availableClasses;
  const _ClassMultiSelectSheet({required this.selectedIds, required this.availableClasses});

  @override
  State<_ClassMultiSelectSheet> createState() => _ClassMultiSelectSheetState();
}

class _ClassMultiSelectSheetState extends State<_ClassMultiSelectSheet> {
  late List<int> _selected = List.of(widget.selectedIds);
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.availableClasses.where((c) => c.name.toLowerCase().contains(_search.trim().toLowerCase())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: feeConfigInputDecoration(hint: 'Search classes'),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FeeConfigGhostButton(small: true, label: 'Select all', onPressed: () => setState(() => _selected = widget.availableClasses.map((c) => c.id).toList())),
                      FeeConfigGhostButton(small: true, label: 'Clear all', onPressed: () => setState(() => _selected = [])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final c in filtered)
                          _classRow(c),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply selection', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _classRow(SchoolClass c) {
    final checked = _selected.contains(c.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => setState(() => checked ? _selected.remove(c.id) : _selected.add(c.id)),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEF0F4)),
            borderRadius: BorderRadius.circular(10),
            color: checked ? const Color(0xFFF2F3FF) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked ? const Color(0xFF5B4FCF) : Colors.white,
                  border: Border.all(color: checked ? const Color(0xFF5B4FCF) : const Color(0xFFCBD5F0)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: checked ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
              const SizedBox(width: 10),
              Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            ],
          ),
        ),
      ),
    );
  }
}
