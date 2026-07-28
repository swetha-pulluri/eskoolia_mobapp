import 'package:flutter/material.dart';

/// "Draft saved!" confirmation — mirrors StudentAddPanel.tsx's
/// `draftSavedModalOpen` dialog exactly (shown after the footer's "Save
/// draft" button, not after the AI panel's quick "Save draft" action, which
/// only shows a toast — see StudentEnrollPage._saveDraftFromFooter).
class StudentDraftSavedDialog extends StatelessWidget {
  final String firstName;
  final String lastName;
  final VoidCallback onEnrollAnother;
  final VoidCallback onGoToList;

  const StudentDraftSavedDialog({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.onEnrollAnother,
    required this.onGoToList,
  });

  @override
  Widget build(BuildContext context) {
    final subject = firstName.trim().isNotEmpty ? '$firstName${lastName.trim().isNotEmpty ? ' $lastName' : ''}\'s' : "The";
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 28, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 18),
              const Text('Draft saved!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text(
                '$subject enrollment has been saved as a draft.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can come back anytime from the Drafts button to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEnrollAnother();
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Enroll another student (fresh form)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3CE1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onGoToList();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Go to students list'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
