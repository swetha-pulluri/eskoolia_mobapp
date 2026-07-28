import 'package:flutter/material.dart';

/// The subset of the Enroll form's live state `StudentAddPanel.tsx`'s
/// `aiOpen` panel actually reads to compute its tips — built fresh by the
/// page each time the dialog opens, so the tips always reflect the current
/// (possibly just-edited) field values.
class EnrollAiSnapshot {
  final bool identityComplete;
  final bool academicComplete;
  final bool contactComplete;
  final bool guardiansComplete;
  final bool documentsComplete;
  final bool feesComplete;
  final String firstName;
  final String lastName;
  final String dob;
  final String phone;
  final String pincode;
  final String guardianFullName;

  const EnrollAiSnapshot({
    required this.identityComplete,
    required this.academicComplete,
    required this.contactComplete,
    required this.guardiansComplete,
    required this.documentsComplete,
    required this.feesComplete,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.phone,
    required this.pincode,
    required this.guardianFullName,
  });

  /// Mirrors `isStepComplete()`'s exact 6-of-10 coverage: `apaar`,
  /// `medical`, `speciallyAbled` and `identityMarks` have no case in the
  /// frontend's switch and always fall through to `default: return false`,
  /// so — faithfully reproduced here — `completedSteps` can never exceed 6
  /// out of `totalSteps` (10), capping `overallPct` at 60. This looks like a
  /// frontend bug, but per this project's "frontend is the only source of
  /// truth" rule it is reproduced exactly rather than "fixed".
  int get completedSteps => [identityComplete, academicComplete, contactComplete, guardiansComplete, documentsComplete, feesComplete]
      .where((v) => v)
      .length;

  static const int totalSteps = 10;

  int get overallPct => ((completedSteps / totalSteps) * 100).round();
}

enum AiTipTone { info, warn, success }

class AiTip {
  final String icon;
  final String title;
  final String body;
  final AiTipTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AiTip({required this.icon, required this.title, required this.body, required this.tone, this.actionLabel, this.onAction});
}

/// "Eskoolia AI Assist" modal — mirrors StudentAddPanel.tsx's `aiOpen`
/// overlay exactly: same completion ring/summary, same tip rules & order,
/// same quick-action bar, same "nothing is sent to a server" disclaimer.
/// Tips are generated locally from [snapshot] — there is no backend/LLM
/// call here, matching the frontend's own local-only rules engine (a
/// different, simpler thing than this app's separate app-wide AI chatbot).
class StudentAiAssistDialog extends StatelessWidget {
  final EnrollAiSnapshot snapshot;
  final void Function(String sectionId) onJumpToSection;
  final VoidCallback onSaveDraft;
  final VoidCallback onViewDrafts;
  final VoidCallback onPreviewPdf;

  const StudentAiAssistDialog({
    super.key,
    required this.snapshot,
    required this.onJumpToSection,
    required this.onSaveDraft,
    required this.onViewDrafts,
    required this.onPreviewPdf,
  });

  List<AiTip> _buildTips(BuildContext context) {
    final tips = <AiTip>[];
    final overallPct = snapshot.overallPct;

    if (snapshot.firstName.trim().isEmpty || snapshot.lastName.trim().isEmpty || snapshot.dob.trim().isEmpty) {
      tips.add(AiTip(
        icon: '👤',
        tone: AiTipTone.warn,
        title: 'Start with the basics',
        body: 'Identity is the first step — name and date of birth unlock the rest of the form.',
        actionLabel: 'Go to Identity',
        onAction: () {
          Navigator.of(context).pop();
          onJumpToSection('identity');
        },
      ));
    }
    final phoneDigits = snapshot.phone.replaceAll(RegExp(r'\D'), '');
    if (snapshot.phone.trim().isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phoneDigits)) {
      tips.add(AiTip(
        icon: '📱',
        tone: AiTipTone.warn,
        title: 'Phone number looks off',
        body: 'Indian phone numbers should be exactly 10 digits. Re-check the contact step.',
        actionLabel: 'Fix contact',
        onAction: () {
          Navigator.of(context).pop();
          onJumpToSection('contact');
        },
      ));
    }
    if (snapshot.pincode.trim().isNotEmpty && snapshot.pincode.trim().length != 6) {
      tips.add(AiTip(
        icon: '📍',
        tone: AiTipTone.warn,
        title: 'Pincode incomplete',
        body: "Indian pincodes are 6 digits. Enter it and we'll auto-fill city/district/state.",
        actionLabel: 'Fix pincode',
        onAction: () {
          Navigator.of(context).pop();
          onJumpToSection('contact');
        },
      ));
    }
    if (snapshot.guardianFullName.trim().isEmpty) {
      tips.add(AiTip(
        icon: '👨‍👩‍👧',
        tone: AiTipTone.warn,
        title: 'Add a guardian',
        body: 'At least one guardian (name + phone) is required before you can submit.',
        actionLabel: 'Add guardian',
        onAction: () {
          Navigator.of(context).pop();
          onJumpToSection('guardians');
        },
      ));
    }
    if (overallPct >= 30 && overallPct < 100) {
      tips.add(AiTip(
        icon: '💾',
        tone: AiTipTone.info,
        title: 'Save your progress',
        body: "You're $overallPct% done. Save a draft so nothing is lost — you can resume anytime from the Drafts panel.",
        actionLabel: 'Save draft now',
        onAction: () {
          Navigator.of(context).pop();
          onSaveDraft();
        },
      ));
    }
    if (overallPct < 50) {
      tips.add(const AiTip(
        icon: '⚡',
        tone: AiTipTone.info,
        title: 'Speed tip — Aadhaar QR scan',
        body: "Got the student's Aadhaar card? Scan the QR to auto-fill name, DOB, gender and address in one go.",
      ));
    }
    if (overallPct == 100) {
      tips.add(AiTip(
        icon: '🎉',
        tone: AiTipTone.success,
        title: "You're ready to submit!",
        body: 'Every required step is complete. Head to Review to do a final check, then submit.',
        actionLabel: 'Go to Review',
        onAction: () {
          Navigator.of(context).pop();
          onJumpToSection('review');
        },
      ));
    }
    if (tips.isEmpty) {
      tips.add(const AiTip(
        icon: '✨',
        tone: AiTipTone.success,
        title: 'Everything looks great',
        body: 'No issues spotted. Keep going!',
      ));
    }
    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final tips = _buildTips(context);
    final overallPct = snapshot.overallPct;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: screenHeight * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHead(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(overallPct),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SUGGESTIONS FOR YOU',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 10),
                          ...tips.map(_buildTipRow),
                          _buildQuickbar(context),
                          const SizedBox(height: 14),
                          const Text(
                            "Tips are generated locally from the data you've entered. Nothing is sent to a server.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHead(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Eskoolia AI Assist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                      child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('Smart tips based on your current form.', style: TextStyle(fontSize: 12.5, color: Color(0xDFFFFFFF))),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int overallPct) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFAF5FF), Color(0xFFFDF2F8)]),
          border: Border.all(color: const Color(0xFFEDE9FE)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OVERALL COMPLETION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: Color(0xFF8B5CF6)),
                  ),
                  Text('$overallPct%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.2)),
                  Text('${snapshot.completedSteps} of ${EnrollAiSnapshot.totalSteps} steps done', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 6,
                      valueColor: const AlwaysStoppedAnimation(Color(0x268B5CF6)),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]).createShader(rect),
                      child: CircularProgressIndicator(
                        value: (overallPct / 100).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(AiTip tip) {
    final Color bg;
    final Color border;
    switch (tip.tone) {
      case AiTipTone.info:
        bg = const Color(0xFFF0F9FF);
        border = const Color(0xFFE0F2FE);
        break;
      case AiTipTone.warn:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFEF3C7);
        break;
      case AiTipTone.success:
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFDCFCE7);
        break;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(11)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Text(tip.icon, style: const TextStyle(fontSize: 18))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(tip.body, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.45)),
              ],
            ),
          ),
          if (tip.actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: tip.onAction,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  foregroundColor: const Color(0xFF6C3CE1),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7), side: const BorderSide(color: Color(0x0F000000))),
                ),
                child: Text('${tip.actionLabel} →', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _quickButton('💾', 'Save draft', () {
            Navigator.of(context).pop();
            onSaveDraft();
          }),
          _quickButton('📋', 'View drafts', () {
            Navigator.of(context).pop();
            onViewDrafts();
          }),
          _quickButton('📄', 'Preview PDF', () {
            Navigator.of(context).pop();
            onPreviewPdf();
          }),
        ],
      ),
    );
  }

  Widget _quickButton(String icon, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFFAFAFA),
        foregroundColor: const Color(0xFF475569),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
