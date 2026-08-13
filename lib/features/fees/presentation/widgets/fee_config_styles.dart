import 'package:flutter/material.dart';

/// Shared style building-blocks for the Fee Configuration screen — mirrors
/// FeeConfigurationPanel.tsx's `card`/`primaryBtn`/`outlineBtn`/`dangerBtn`/
/// `ghostBtn`/`inputField`/`thStyle`/`tdStyle`/`statusPill` helpers, reused
/// identically across all 5 tabs.
const feeConfigBorder = Color(0xFFE8E8EE);
const feeConfigInk1 = Color(0xFF181B2A);
const feeConfigInk2 = Color(0xFF5B5E72);
const feeConfigInk3 = Color(0xFFA0A3B8);
const feeConfigPurple = Color(0xFF6D4AFF);

const feeConfigCardDecoration = BoxDecoration(
  color: Colors.white,
  border: Border.fromBorderSide(BorderSide(color: feeConfigBorder)),
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

class FeeConfigCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FeeConfigCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: feeConfigCardDecoration,
      child: child,
    );
  }
}

/// Small uppercase field label, e.g. "GROUP NAME" — 10.5px w700.
class FeeConfigLabel extends StatelessWidget {
  final String text;
  const FeeConfigLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: feeConfigInk3),
      ),
    );
  }
}

class FeeConfigFieldError extends StatelessWidget {
  final String? message;
  const FeeConfigFieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(message!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Section heading + description shown at the top of a Fee Configuration
/// tab (Fee Groups / Fee Types / Fee Schedules) — the description text is
/// copied verbatim from `FeeConfigurationPanel.tsx`'s
/// `HELP_CONTENT[tab].whatIsThis`, which on the real web page is only shown
/// via a per-tab Help-modal (i) icon rather than always inline.
class FeeConfigSectionHeading extends StatelessWidget {
  final String title;
  final String description;
  const FeeConfigSectionHeading({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: feeConfigInk1)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 13, color: feeConfigInk2, height: 1.5)),
        ],
      ),
    );
  }
}

InputDecoration feeConfigInputDecoration({String? hint, bool hasError = false}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9AA0B2), fontSize: 13),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: hasError ? const Color(0xFFEF4444) : feeConfigBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: hasError ? const Color(0xFFEF4444) : feeConfigBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: hasError ? const Color(0xFFEF4444) : feeConfigPurple),
    ),
  );
}

ButtonStyle _btnStyle({required bool small, required Color bg, required Color fg, Color? borderColor}) {
  return ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: fg,
    disabledBackgroundColor: bg.withValues(alpha: 0.6),
    disabledForegroundColor: fg.withValues(alpha: 0.8),
    elevation: 0,
    minimumSize: Size(0, small ? 32 : 40),
    padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(small ? 7 : 9),
      side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
    ),
    textStyle: TextStyle(fontSize: small ? 12.5 : 13.5, fontWeight: FontWeight.w600),
  );
}

class FeeConfigPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FeeConfigPrimaryButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _btnStyle(small: small, bg: feeConfigPurple, fg: Colors.white),
      child: Text(label),
    );
  }
}

class FeeConfigOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FeeConfigOutlineButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _btnStyle(small: small, bg: Colors.white, fg: feeConfigInk1, borderColor: feeConfigBorder),
      child: Text(label),
    );
  }
}

class FeeConfigDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FeeConfigDangerButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _btnStyle(small: small, bg: Colors.white, fg: const Color(0xFFDC2626), borderColor: const Color(0xFFFCA5A5)),
      child: Text(label),
    );
  }
}

class FeeConfigGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FeeConfigGhostButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF7F7FB),
        foregroundColor: const Color(0xFF4B5563),
        elevation: 0,
        minimumSize: Size(0, small ? 30 : 36),
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
        side: const BorderSide(color: Color(0xFFE4E7F1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(small ? 7 : 9)),
        textStyle: TextStyle(fontSize: small ? 12 : 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Mirrors `statusPill` — "Active" green, anything else neutral grey.
class FeeConfigStatusPill extends StatelessWidget {
  final String status;
  const FeeConfigStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF15803D) : const Color(0xFF6B7280),
          height: 16 / 11,
        ),
      ),
    );
  }
}

/// Mirrors the pill-shaped active/inactive toggle switch used in Fee Groups
/// (list row + edit panel) and Fee Types (edit modal).
class FeeConfigToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const FeeConfigToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: GestureDetector(
        onTap: disabled ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 18,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value ? const Color(0xFFE6F6EE) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: feeConfigBorder),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? const Color(0xFF1D9E63) : const Color(0xFF8A90A2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal white-popup select — same `dropdownColor`-forced-white fix as the
/// app-wide [AppDropdown], specialised here for this feature's inline
/// enum/id selects (string enums, or `int?` ids like fee group/fee type).
class FeeConfigSelect<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool hasError;

  const FeeConfigSelect({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.hint,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: hasError ? const Color(0xFFEF4444) : feeConfigBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          hint: hint != null ? Text(hint!, style: const TextStyle(color: Color(0xFF9AA0B2), fontSize: 13)) : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF8B8EA8)),
          style: const TextStyle(fontSize: 13.5, color: feeConfigInk1),
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(labelOf(i)))],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

const feeConfigThStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: feeConfigInk3);
const feeConfigTdStyle = TextStyle(fontSize: 13.5, color: feeConfigInk1);
const feeConfigTdMuted = TextStyle(fontSize: 13.5, color: feeConfigInk2);
