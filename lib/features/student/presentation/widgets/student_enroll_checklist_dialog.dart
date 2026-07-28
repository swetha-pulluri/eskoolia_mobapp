import 'package:flutter/material.dart';
import '../utils/enrollment_pdf.dart';

/// "What I'll need" checklist modal — mirrors StudentAddPanel.tsx's
/// `infoChecklistOpen` dialog exactly: same 10 modules, same item text,
/// same required("*")/optional("·") markers, same "Print checklist" action
/// (built as a real PDF here — see `printEnrollmentChecklist`, the mobile
/// equivalent of the frontend's print-window + `window.print()`).
class StudentEnrollChecklistDialog extends StatefulWidget {
  final String schoolName;

  const StudentEnrollChecklistDialog({super.key, required this.schoolName});

  @override
  State<StudentEnrollChecklistDialog> createState() => _StudentEnrollChecklistDialogState();
}

class _StudentEnrollChecklistDialogState extends State<StudentEnrollChecklistDialog> {
  bool _printing = false;

  Future<void> _printChecklist() async {
    setState(() => _printing = true);
    try {
      await printEnrollmentChecklist(schoolName: widget.schoolName);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: screenHeight * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "📋 What you'll need to enroll a student",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                            children: [
                              TextSpan(text: 'Use this checklist with the parents before starting. '),
                              TextSpan(text: '*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                              TextSpan(text: ' = required to enroll.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 22, color: Color(0xFF6B7280)),
                    tooltip: 'Close checklist',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: kEnrollmentChecklistModules.map(_buildModuleCard).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _printing ? null : _printChecklist,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _printing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('🖨 Print checklist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3CE1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Got it, let's start", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(EnrollmentChecklistModule mod) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                child: Text('${mod.number}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6C3CE1))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(mod.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in mod.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$2 ? '*' : '·',
                    style: TextStyle(
                      color: item.$2 ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.$1, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
