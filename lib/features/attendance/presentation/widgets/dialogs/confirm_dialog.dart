import 'package:flutter/material.dart';

/// Confirm Dialog — converted from web
/// `attendance/student/components/ConfirmDialog.tsx`'s imperative
/// `ConfirmDialogHost` + `confirmDialog()` pattern. Flutter's `showDialog`
/// already provides the same "await a Future" imperative shape natively,
/// so no separate host widget is needed — call `confirmDialog(context, ...)`
/// directly wherever web calls `await confirmDialog({...})`.
class ConfirmResult {
  final bool ok;
  final String? note;
  const ConfirmResult({required this.ok, this.note});
}

enum ConfirmTone { info, warn, danger, success }

class _ToneStyle {
  final Color iconBg;
  final Color iconColor;
  final Color confirmBg;
  const _ToneStyle(this.iconBg, this.iconColor, this.confirmBg);
}

const Map<ConfirmTone, _ToneStyle> _kToneStyles = {
  ConfirmTone.info: _ToneStyle(Color(0xFFEDE9FE), Color(0xFF5B21B6), Color(0xFF4729F4)),
  ConfirmTone.warn: _ToneStyle(Color(0xFFFDF1DC), Color(0xFFB4721B), Color(0xFFB4721B)),
  ConfirmTone.danger: _ToneStyle(Color(0xFFFCE8EE), Color(0xFFC2264E), Color(0xFFC2264E)),
  ConfirmTone.success: _ToneStyle(Color(0xFFE4F6ED), Color(0xFF0A8C5A), Color(0xFF0A8C5A)),
};

Future<ConfirmResult> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  ConfirmTone tone = ConfirmTone.info,
  String? noteLabel,
  String? notePlaceholder,
  bool noteRequired = false,
  String initialNote = '',
  bool hideCancel = false,
}) async {
  final result = await showDialog<ConfirmResult>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (context) => _ConfirmDialogView(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      tone: tone,
      noteLabel: noteLabel,
      notePlaceholder: notePlaceholder,
      noteRequired: noteRequired,
      initialNote: initialNote,
      hideCancel: hideCancel,
    ),
  );
  return result ?? const ConfirmResult(ok: false);
}

class _ConfirmDialogView extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmTone tone;
  final String? noteLabel;
  final String? notePlaceholder;
  final bool noteRequired;
  final String initialNote;
  final bool hideCancel;

  const _ConfirmDialogView({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.tone,
    this.noteLabel,
    this.notePlaceholder,
    this.noteRequired = false,
    this.initialNote = '',
    this.hideCancel = false,
  });

  @override
  State<_ConfirmDialogView> createState() => _ConfirmDialogViewState();
}

class _ConfirmDialogViewState extends State<_ConfirmDialogView> {
  late final _noteController = TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _kToneStyles[widget.tone]!;
    final canConfirm = !(widget.noteRequired && _noteController.text.trim().isEmpty);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: style.iconBg, shape: BoxShape.circle), alignment: Alignment.center, child: Icon(Icons.info_outline, size: 20, color: style.iconColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0B0B14))),
                  const SizedBox(height: 6),
                  Text(widget.message, style: const TextStyle(fontSize: 13, color: Color(0xFF4B4B5A), height: 1.4)),
                  if (widget.noteLabel != null) ...[
                    const SizedBox(height: 12),
                    Text('${widget.noteLabel}${widget.noteRequired ? " *" : " (optional)"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA0AE), letterSpacing: 0.4)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: widget.notePlaceholder,
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4729F4))),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFFAFAFD), border: Border(top: BorderSide(color: Color(0xFFF0F0F6)))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (!widget.hideCancel) ...[
                OutlinedButton(onPressed: () => Navigator.of(context).pop(const ConfirmResult(ok: false)), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: Text(widget.cancelLabel)),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: canConfirm
                    ? () => Navigator.of(context).pop(ConfirmResult(ok: true, note: widget.noteLabel != null ? _noteController.text.trim() : null))
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: style.confirmBg, foregroundColor: Colors.white),
                child: Text(widget.confirmLabel),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
