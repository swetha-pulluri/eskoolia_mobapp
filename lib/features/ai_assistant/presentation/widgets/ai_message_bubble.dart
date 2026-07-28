import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../providers/ai_assistant_controller.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/flat_index_entry.dart';
import 'ai_absence_flow.dart';
import 'ai_assistant_colors.dart';
import 'ai_enquiry_lookup_results.dart';
import 'ai_issue_flow.dart';
import 'ai_student_lookup_results.dart';

/// Mirrors frontend components/AIBot.tsx's per-message render block (the
/// `msgs.map(m => ...)` body) — one [AiMsg] in, one bubble/card out.
/// Assumes the caller has already filtered out collapsed messages and
/// handled the `collapsedCount` "show previous results" banner separately
/// (that one isn't a real message bubble in the source either).
class AiMessageBubble extends ConsumerWidget {
  final AiMsg msg;

  const AiMessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aiAssistantControllerProvider.notifier);
    final isUser = msg.role == AiMsgRole.user;

    if (msg.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: aiBg2, borderRadius: BorderRadius.circular(12)),
          child: const Text('…', style: TextStyle(fontSize: 13, color: aiInk3)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (msg.text != null && msg.text!.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUser ? aiPurple : aiBg2,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 12),
              ),
            ),
            child: Text(msg.text!, style: TextStyle(fontSize: 13, height: 1.4, color: isUser ? Colors.white : aiInk1)),
          ),
        if (msg.redirect != null) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [aiPurple.withValues(alpha: 0.08), aiPurple.withValues(alpha: 0.04)]),
              border: Border.all(color: aiPurple.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: msg.redirect!.bg, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Icon(msg.redirect!.icon, size: 14, color: msg.redirect!.ic),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msg.redirect!.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: aiInk1)),
                      Text(msg.redirect!.path, style: const TextStyle(fontSize: 11, color: aiInk3)),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, size: 13, color: aiPurple),
              ],
            ),
          ),
        ],
        if (msg.results != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                for (final r in msg.results!.take(5)) ...[
                  _resultRow(ref, r, controller),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ],
        if (msg.studentResults != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: AiStudentLookupResults(students: msg.studentResults!, query: msg.studentQuery ?? '', onNavigated: controller.closePanel),
          ),
        ],
        if (msg.enquiryResults != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: AiEnquiryLookupResults(enquiries: msg.enquiryResults!, query: msg.enquiryQuery ?? '', onNavigated: controller.closePanel),
          ),
        ],
        if (msg.phonePrompt != null) ...[
          const SizedBox(height: 4),
          _phonePromptCard(ref, msg.phonePrompt!, controller),
        ],
        if (msg.showAbsenceFlow) ...[
          const SizedBox(height: 4),
          AiAbsenceFlow(
            prefillName: msg.absenceFlowPrefillName,
            onComplete: (result) => controller.onAbsenceComplete(msg.id, result),
            onCancel: () => controller.dismissFlow(msg.id),
          ),
        ],
        if (msg.issueFlowType != null) ...[
          const SizedBox(height: 4),
          AiIssueFlow(
            type: msg.issueFlowType!,
            onComplete: (note) => controller.onIssueComplete(msg.id, msg.issueFlowType!, note),
            onCancel: () => controller.dismissFlow(msg.id),
          ),
        ],
      ],
    );
  }

  Widget _resultRow(WidgetRef ref, FlatIndexEntry r, AiAssistantController controller) {
    return InkWell(
      onTap: () {
        controller.closePanel();
        // `AiMessageBubble` lives inside the AI assistant overlay, which is
        // mounted as a sibling of the routed Navigator (via
        // `MaterialApp.router`'s `builder:`), so `context.go(...)` here has
        // no `GoRouter` ancestor to find — use the router instance directly.
        ref.read(appRouterProvider).go(r.path);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: aiBg1, border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: r.bg, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Icon(r.icon, size: 12, color: r.ic),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: aiInk1), overflow: TextOverflow.ellipsis),
                  Text(r.path, style: const TextStyle(fontSize: 10.5, color: aiInk3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phonePromptCard(WidgetRef ref, String phone, AiAssistantController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(10), color: aiBg0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📵 No enquiry found', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: aiInk1)),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 11.5, color: aiInk2),
              children: [
                const TextSpan(text: 'No existing enquiry for '),
                TextSpan(text: phone, style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: '. Would you like to create a new enquiry for this number?'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  controller.closePanel();
                  ref.read(appRouterProvider).go('/admissions/command-center');
                },
                style: ElevatedButton.styleFrom(backgroundColor: aiPurple, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                child: const Text('✚ Create New Enquiry', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  controller.closePanel();
                  ref.read(appRouterProvider).go('/admissions/command-center');
                },
                style: TextButton.styleFrom(backgroundColor: aiPurpleSoft, foregroundColor: aiPurple, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                child: const Text('Open Admissions', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
