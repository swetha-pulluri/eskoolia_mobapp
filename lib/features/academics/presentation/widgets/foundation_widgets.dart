import 'package:flutter/material.dart';

/// Shared visual pieces for the Academics → Foundation & Core Settings
/// workspace — ports of components/academics/foundation/ConfirmDeleteDialog.tsx
/// and the FoundationWorkspace.tsx toast, reused by every step's pane
/// (Academic Year, Classes, Sections, Subjects, Rooms).

/// Port of ConfirmDeleteDialog.tsx.
class FoundationConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final Widget message;
  final String confirmLabel;
  final String cancelLabel;
  final bool loading;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const FoundationConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.loading = false,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFB91C1C)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F))),
                        const SizedBox(height: 2),
                        const Text('This action cannot be undone.', style: TextStyle(fontSize: 12.5, color: Color(0xFF6F767E))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DefaultTextStyle(
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D1F), height: 1.4),
                child: message,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: loading ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6F767E),
                      side: const BorderSide(color: Color(0xFFE8ECEF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    child: Text(cancelLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: loading ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (loading) ...[
                        const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        const SizedBox(width: 8),
                      ],
                      Text(loading ? 'Deleting…' : confirmLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
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

/// Port of FoundationWorkspace.tsx's fixed top-right toast (tone: success →
/// dark navy, error → red).
class FoundationToast extends StatelessWidget {
  final ({String tone, String message})? toast;
  const FoundationToast({super.key, required this.toast});

  @override
  Widget build(BuildContext context) {
    final visible = toast != null;
    final isError = toast?.tone == 'error';
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      top: visible ? 20 : -60,
      right: 24,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: visible ? 1 : 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFFEF4444) : const Color(0xFF1A1D1F),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isError ? '✕' : '✓', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Flexible(child: Text(toast?.message ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Port of AcademicYearPane.tsx's shared `Card` chrome — a white rounded
/// card with a light border and subtle shadow, reused by every pane.
class FoundationCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FoundationCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: child,
    );
  }
}

/// Shared text-field styling matching every input in the Foundation panes
/// (`bg-[#F0F2F5] border-[1.5px] border-[#E8ECEF] rounded-[10px]`).
InputDecoration foundationFieldDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF0F2F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8ECEF), width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8ECEF), width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF5B4FCF), width: 1.5)),
  );
}

Widget foundationFieldLabel(String text, {bool required = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6F767E)),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444))),
        ],
      ),
    ),
  );
}

/// Plain circle indicator standing in for a radio-button glyph — the
/// enclosing row is already the tap target, so this avoids Flutter's
/// deprecated `Radio.groupValue`/`onChanged` API for a purely decorative dot.
class FoundationRadioDot extends StatelessWidget {
  final bool selected;
  final Color color;
  const FoundationRadioDot({super.key, required this.selected, this.color = const Color(0xFF5B4FCF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? color : const Color(0xFF9FA6AD), width: 1.6)),
      child: selected ? Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)) : null,
    );
  }
}
