import 'package:flutter/material.dart';
import '../../domain/entities/inquiry_entity.dart';
import '../../domain/entities/school_class_entity.dart';
import '../../../administration/domain/entities/admin_setup_entity.dart';

class AiTip {
  final String headline;
  final String insight;
  final String suggestedMsg;
  const AiTip({required this.headline, required this.insight, required this.suggestedMsg});
}

AiTip generateAiTip(InquiryEntity draft, List<AdminSetupEntity> sources, List<SchoolClassEntity> classes) {
  final sourceName = sources.where((s) => s.id == draft.source).map((s) => s.name).firstOrNull ?? '';
  final gradeName = classes.where((c) => c.id == draft.schoolClass).map((c) => c.name).firstOrNull ?? '';
  final parentFirst = draft.fullName.trim().split(RegExp(r'\s+')).firstOrNull ?? 'there';
  final sourceLower = sourceName.toLowerCase();

  String headline = 'AI Insight';
  String insight = 'Follow up within 24 hours for best conversion rates.';
  if (sourceLower.contains('instagram') || sourceLower.contains('facebook')) {
    headline = 'Social Media Lead';
    insight = 'Social media leads like $parentFirst convert best when contacted within 2 hours.';
  } else if (sourceLower.contains('word') || sourceLower.contains('mouth')) {
    headline = 'Referral Lead - High Intent';
    insight = '$parentFirst was referred - referral leads convert at 2-3x the rate!';
  } else if (sourceLower.contains('google')) {
    headline = 'Google Search Lead';
    insight = '$parentFirst was actively searching - respond within 30 minutes.';
  }
  if (gradeName.isNotEmpty) insight += ' Grade $gradeName has been popular this season.';
  final suggestedMsg = 'Hi $parentFirst! Thank you for your interest. Can you visit this week? We have limited seats for ${gradeName.isNotEmpty ? gradeName : "the grade"}. - Admissions Team';
  return AiTip(headline: headline, insight: insight, suggestedMsg: suggestedMsg);
}

/// AI Tip — converted from `AdmissionsCommandCenter.tsx`'s "AI TIP" popup.
/// A small bottom-right card shown right after a new inquiry is created,
/// surfacing a lead-source-aware insight and a ready-to-send WhatsApp
/// message.
class AiTipPopup extends StatelessWidget {
  final AiTip tip;
  final String? phone;
  final VoidCallback onClose;
  final VoidCallback onSend;

  const AiTipPopup({super.key, required this.tip, required this.phone, required this.onClose, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 16,
      left: 16,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border(left: BorderSide(color: Color(0xFF4F46E5), width: 4)),
            boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 32, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(tip.headline, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                InkWell(onTap: onClose, child: const Padding(padding: EdgeInsets.all(2), child: Text('✕', style: TextStyle(fontSize: 14)))),
              ]),
              const SizedBox(height: 6),
              Text(tip.insight, style: const TextStyle(fontSize: 12, height: 1.4)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: Text(tip.suggestedMsg, style: const TextStyle(fontSize: 11, height: 1.4)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSend,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 6), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  child: const Text('Send WhatsApp'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
