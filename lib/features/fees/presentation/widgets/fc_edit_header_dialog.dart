import 'package:flutter/material.dart';
import '../../domain/models/school_header_info.dart';
import 'fees_collection_styles.dart';

/// "Edit Receipt Header" modal — mirrors FeesCollectionPanel.tsx's
/// `showHeaderModal` block (§15 of the port spec). Local-state only: the
/// source never persists this to the backend (a refresh reverts to
/// whatever `getMySchoolInfo()` returns) — this dialog mirrors that by
/// simply returning the edited [SchoolHeaderInfo] to the caller, which
/// keeps it in memory only.
class FcEditHeaderDialog extends StatefulWidget {
  final SchoolHeaderInfo initial;
  const FcEditHeaderDialog({super.key, required this.initial});

  static Future<SchoolHeaderInfo?> show(BuildContext context, {required SchoolHeaderInfo initial}) {
    return showDialog<SchoolHeaderInfo>(
      context: context,
      barrierColor: const Color(0x73000000),
      builder: (_) => FcEditHeaderDialog(initial: initial),
    );
  }

  @override
  State<FcEditHeaderDialog> createState() => _FcEditHeaderDialogState();
}

class _FcEditHeaderDialogState extends State<FcEditHeaderDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.name);
    _addressCtrl = TextEditingController(text: widget.initial.address);
    _emailCtrl = TextEditingController(text: widget.initial.email);
    for (final c in [_nameCtrl, _addressCtrl, _emailCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text;
    final address = _addressCtrl.text;
    final email = _emailCtrl.text;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 40, offset: Offset(0, 12))],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Receipt Header', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fcInk1)),
                const SizedBox(height: 4),
                const Text('This header appears at the top of every downloaded receipt.', style: TextStyle(fontSize: 13, color: fcInk3)),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF8F8FB), border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), border: Border.all(color: fcBorder), borderRadius: BorderRadius.circular(10)),
                        child: const Text('🏫', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name.isEmpty ? 'School Name' : name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fcInk1)),
                            const SizedBox(height: 3),
                            Text(
                              '${address.isEmpty ? 'School Address' : address}${email.isNotEmpty ? ' · $email' : ''}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _field('School Name', _nameCtrl, 'e.g. Eskoolia School'),
                const SizedBox(height: 14),
                _field('Address', _addressCtrl, 'e.g. 123 School Lane, City — 000000'),
                const SizedBox(height: 14),
                _field('Email / Contact', _emailCtrl, 'e.g. admissions@eskoolia.in'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FcOutlineButton(small: true, label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 10),
                    FcPrimaryButton(
                      small: true,
                      label: 'Save Header',
                      onPressed: () => Navigator.of(context).pop(
                        widget.initial.copyWith(name: name, address: address, email: email),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fcInk2)),
        const SizedBox(height: 6),
        TextField(controller: controller, decoration: fcModalFieldDecoration(hintText: placeholder)),
      ],
    );
  }
}
