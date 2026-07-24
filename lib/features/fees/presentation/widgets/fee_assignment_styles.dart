import 'package:flutter/material.dart';

/// Shared style building-blocks for the Fee Assignment screen — mirrors
/// FeesAssignmentPanel.tsx's `primaryBtn`/`outlineBtn`/`TH`/`InfoDot`
/// helpers. Dimensions differ slightly from Fee Configuration's own button
/// helpers (38/32px height + 13/12.5 font here vs. 40/32 + 13.5/12.5 there)
/// so this screen gets its own, rather than reusing fee_config_styles.dart
/// and drifting from the literal source spec.
const faBorder = Color(0xFFE8E8EE);
const faInk1 = Color(0xFF181B2A);
const faInk2 = Color(0xFF5B5E72);
const faInk3 = Color(0xFFA0A3B8);
const faPurple = Color(0xFF6D4AFF);

ButtonStyle _btnStyle({required bool small, required Color bg, required Color fg, Color? borderColor}) {
  return ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: fg,
    disabledBackgroundColor: bg.withValues(alpha: 0.6),
    disabledForegroundColor: fg.withValues(alpha: 0.8),
    elevation: 0,
    minimumSize: Size(0, small ? 32 : 38),
    padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(small ? 7 : 9),
      side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
    ),
    textStyle: TextStyle(fontSize: small ? 12.5 : 13, fontWeight: FontWeight.w600),
  );
}

class FaPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  const FaPrimaryButton({super.key, required this.label, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(small ? 7 : 9),
        boxShadow: onPressed == null ? null : const [BoxShadow(color: Color(0x336D4AFF), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: _btnStyle(small: small, bg: faPurple, fg: Colors.white),
        child: Text(label),
      ),
    );
  }
}

class FaOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  final Color? color;
  final Color? borderColor;
  const FaOutlineButton({super.key, required this.label, required this.onPressed, this.small = false, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _btnStyle(small: small, bg: Colors.white, fg: color ?? faInk1, borderColor: borderColor ?? faBorder).copyWith(
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: small ? 12.5 : 13, fontWeight: FontWeight.w500)),
      ),
      child: Text(label),
    );
  }
}

const faThStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: faInk3);

/// The small circular "i" glyph next to a few column headers — purely
/// decorative in the source (no tooltip/press handler wired to it).
class FaInfoDot extends StatelessWidget {
  const FaInfoDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      margin: const EdgeInsets.only(left: 5),
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8E8EE)),
      child: const Text('i', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: faInk3)),
    );
  }
}

/// Mirrors `ModalShell` — centered dialog, dark scrim, rounded 16, max width.
class FaModalShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const FaModalShell({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 64, offset: Offset(0, 24))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}

/// Mirrors `ModalHeader` — title/subtitle left, circular × close button right.
class FaModalHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  const FaModalHeader({super.key, required this.title, required this.subtitle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: faInk1)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: faInk3)),
                  ],
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: faBorder)),
                  child: const Text('×', style: TextStyle(fontSize: 15, color: faInk3, height: 1)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: faBorder, indent: 20, endIndent: 20),
      ],
    );
  }
}

/// Mirrors `ModalFooter` — right-aligned action row with a top border.
class FaModalFooter extends StatelessWidget {
  final List<Widget> children;
  const FaModalFooter({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: faBorder))),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 8,
        children: children,
      ),
    );
  }
}
