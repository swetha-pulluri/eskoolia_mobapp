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
