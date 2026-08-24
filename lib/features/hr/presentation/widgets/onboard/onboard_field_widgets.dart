import 'package:flutter/material.dart';
import '../hr_theme.dart';

/// Shared field builders for the 10 onboarding-wizard steps — thin wrappers
/// around [HrField] so every step's fields look consistent without
/// repeating the same boilerplate 10 times.

/// Fixed Designation options for Step 2's dropdown, per direct request —
/// see `step_role.dart`'s doc comment. Shared here (rather than kept private
/// to that file) so Step 10's review and the PDF preview screen can resolve
/// the negative sentinel id `-(i+1)` back to its name via
/// [fixedDesignationNameFor].
const fixedDesignationNames = [
  'Senior Teacher', 'Teacher', 'Head of Department', 'English Coordinator', 'Subject Expert',
  'Administrative Officer', 'Office Superintendent', 'Clerk', 'Accountant', 'Accounts Clerk',
  'Cashier', 'Finance Manager', 'HR Executive', 'HR Manager', 'Recruitment Coordinator',
  'Examination Clerk', 'Examination Controller', 'Examination Coordinator', 'Bus Coordinator',
  'Driver', 'Electrician', 'Maintenance Supervisor', 'Plumber', 'Medical Officer',
  'Health Assistant', 'School Nurse', 'CCTV Operator', 'Security Guard', 'Security Supervisor',
  'Laboratory Assistant', 'Laboratory Technician',
];

/// Resolves a `fixedDesignationNames` sentinel id (`-(i+1)`) back to its
/// name, or `null` if [id] isn't one (e.g. a real designation id, or unset).
String? fixedDesignationNameFor(int? id) {
  if (id == null || id >= 0) return null;
  final index = -id - 1;
  return index >= 0 && index < fixedDesignationNames.length ? fixedDesignationNames[index] : null;
}

Widget onboardText({
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
  bool required = false,
  String? error,
  String? hint,
  TextInputType? keyboardType,
  int? maxLength,
  int maxLines = 1,
  TextCapitalization textCapitalization = TextCapitalization.none,
  /// Matches web's `readOnly` grey "Staff Code" `<HrInput>` exactly
  /// (`bg-[#F1F5F9] cursor-not-allowed !text-[#94A3B8]`,
  /// `hr/onboard/page.tsx:507-513`) — auto-generated fields the user can
  /// see and copy but not type into.
  bool readOnly = false,
}) {
  return HrField(
    label: label,
    required: required,
    error: error,
    child: TextFormField(
      // `TextFormField.initialValue` only applies on first build — for an
      // editable field that's fine (the user's own typing is the only thing
      // that should change it), but a `readOnly` field's value can change
      // purely from parent state (e.g. Staff Code arriving async from
      // `next-staff-no`), which needs a new key to actually repaint.
      key: readOnly ? ValueKey(value) : null,
      initialValue: value,
      onChanged: onChanged,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: readOnly ? const TextStyle(color: Color(0xFF94A3B8)) : null,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hint,
        isDense: true,
        counterText: maxLength != null ? '' : null,
        filled: readOnly,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : null,
      ),
    ),
  );
}

/// Above this many options, [onboardDropdown] switches from the plain
/// `DropdownButtonFormField` to [_SearchableOnboardDropdown] so the user can
/// type instead of scrolling. Chosen to comfortably cover every dropdown in
/// this wizard that's a real "long list" (Mother Tongue ~41, Nationality
/// ~94, Designation 30, Religion 13, Degree 15, and any backend-driven list
/// — Department/Role/Reporting Manager — that happens to grow past it)
/// while leaving genuinely short ones (Gender, Blood Group, Marital Status,
/// etc., all well under 10) untouched, exactly as they already render today.
const _searchableDropdownThreshold = 8;

Widget onboardDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  bool required = false,
  String? error,
  String placeholder = 'Select…',
}) {
  final hasValue = items.any((i) => i.value == value);
  if (items.length > _searchableDropdownThreshold) {
    return HrField(
      label: label,
      required: required,
      error: error,
      child: _SearchableOnboardDropdown<T>(
        value: hasValue ? value : null,
        items: items,
        onChanged: onChanged,
        placeholder: placeholder,
      ),
    );
  }
  return HrField(
    label: label,
    required: required,
    error: error,
    child: DropdownButtonFormField<T>(
      initialValue: hasValue ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
      items: [
        DropdownMenuItem<T>(value: null, child: Text(placeholder, style: const TextStyle(color: Color(0xFF94A3B8)))),
        ...items,
      ],
      onChanged: onChanged,
    ),
  );
}

/// A drop-in replacement for `DropdownButtonFormField` used only for long
/// option lists (see [_searchableDropdownThreshold]) — same closed-state
/// look (bordered box, placeholder in grey, chevron), but its open popup
/// leads with a search field that filters the list live, so the user can
/// type instead of scrolling through dozens of entries. Selecting an option
/// calls the same [onChanged] callback with the same value as before —
/// nothing about what happens on selection changes, only how the option is
/// found.
///
/// Built on `CompositedTransformTarget`/`CompositedTransformFollower` (the
/// same proven pattern already used for the searchable State picker in
/// `add_school_page.dart`) rather than `DropdownMenu`'s own built-in
/// `enableFilter`, which was tried for that same State picker first and
/// didn't reliably show a usable search box.
///
/// Extracts each option's searchable text from its `DropdownMenuItem.child`
/// when that child is a plain `Text` (true for every call site in this
/// wizard today) — falling back to `value.toString()` otherwise — so this
/// works with the exact same `items` every call site already builds, with
/// no call-site changes needed.
class _SearchableOnboardDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String placeholder;

  const _SearchableOnboardDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.placeholder,
  });

  @override
  State<_SearchableOnboardDropdown<T>> createState() => _SearchableOnboardDropdownState<T>();
}

class _SearchableOnboardDropdownState<T> extends State<_SearchableOnboardDropdown<T>> {
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _query = '';

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  String _labelFor(DropdownMenuItem<T> item) {
    final child = item.child;
    if (child is Text) return child.data ?? '';
    return item.value?.toString() ?? '';
  }

  List<DropdownMenuItem<T>> _filtered() {
    if (_query.trim().isEmpty) return widget.items;
    final q = _query.trim().toLowerCase();
    return widget.items.where((i) => _labelFor(i).toLowerCase().contains(q)).toList();
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    _query = '';
    _searchController.clear();
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _removeOverlay();
    if (mounted) setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _select(T? value) {
    widget.onChanged(value);
    _close();
  }

  OverlayEntry _buildOverlay() {
    final fieldWidth = context.size?.width ?? 260;
    return OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Tap-outside-to-close barrier, matching the State picker's own
            // approach — a full-screen transparent `GestureDetector` behind
            // the popup.
            Positioned.fill(
              child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _close),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 52),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: fieldWidth, maxWidth: fieldWidth, maxHeight: 260),
                    child: StatefulBuilder(
                      builder: (context, setOverlayState) {
                        final filtered = _filtered();
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Search…',
                                    prefixIcon: const Icon(Icons.search, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: (v) => setOverlayState(() => _query = v),
                                ),
                              ),
                              const Divider(height: 1),
                              Flexible(
                                child: filtered.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 22),
                                        child: Center(
                                          child: Text(
                                            'No results found',
                                            style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                          ),
                                        ),
                                      )
                                    : ListView(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        children: [
                                          _optionTile(
                                            selected: widget.value == null,
                                            child: Text(widget.placeholder, style: const TextStyle(color: Color(0xFF94A3B8))),
                                            onTap: () => _select(null),
                                          ),
                                          for (final item in filtered)
                                            _optionTile(
                                              selected: item.value == widget.value,
                                              child: item.child,
                                              onTap: () => _select(item.value),
                                            ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _optionTile({required bool selected, required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: selected ? const Color(0xFFEEF0FF) : null,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 13,
            color: selected ? const Color(0xFF6D4AFF) : const Color(0xFF0F1222),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? selectedLabel;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selectedLabel = _labelFor(item);
        break;
      }
    }
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: const Color(0xFF64748B)),
          ),
          child: Text(
            selectedLabel ?? widget.placeholder,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: selectedLabel == null ? const Color(0xFF94A3B8) : const Color(0xFF0F1222)),
          ),
        ),
      ),
    );
  }
}

Widget onboardDateField(
  BuildContext context, {
  required String label,
  required String? value,
  bool required = false,
  required ValueChanged<String> onPicked,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return HrField(
    label: label,
    required: required,
    child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(value ?? '') ?? DateTime(DateTime.now().year - 25),
          firstDate: firstDate ?? DateTime(1940),
          lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) onPicked(picked.toIso8601String().split('T').first);
      },
      child: InputDecorator(
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, suffixIcon: Icon(Icons.calendar_today_outlined, size: 16)),
        child: Text(
          value?.isNotEmpty == true ? value! : 'Select date',
          style: TextStyle(color: value?.isNotEmpty == true ? HrColors.ink : const Color(0xFF94A3B8)),
        ),
      ),
    ),
  );
}

Widget onboardSectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1, color: Color(0xFF94A3B8)),
    ),
  );
}

Widget onboardStepHeader(String title, String sub) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: HrColors.ink)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 13, color: HrColors.muted)),
      ],
    ),
  );
}

/// A grid of fields that wraps responsively — [columns] fields per row on
/// a wide-enough screen, falling back to fewer as space runs out.
Widget onboardFieldGrid(List<Widget> fields, {double minFieldWidth = 260}) {
  return LayoutBuilder(builder: (context, constraints) {
    final perRow = (constraints.maxWidth / minFieldWidth).floor().clamp(1, fields.isEmpty ? 1 : fields.length);
    final width = (constraints.maxWidth - (perRow - 1) * 12) / perRow;
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: [for (final f in fields) SizedBox(width: width, child: f)],
    );
  });
}
