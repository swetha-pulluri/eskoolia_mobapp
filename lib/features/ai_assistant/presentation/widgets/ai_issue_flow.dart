import 'package:flutter/material.dart';
import '../../domain/models/ai_message.dart' show AiIssueType;
import 'ai_assistant_colors.dart';

class _IssueCfg {
  final String icon;
  final String label;
  final Color color;
  final Color bg;
  final String placeholder;
  const _IssueCfg({required this.icon, required this.label, required this.color, required this.bg, required this.placeholder});
}

const _issueConfig = {
  AiIssueType.bus: _IssueCfg(
    icon: '🚌',
    label: 'Bus Issue',
    color: Color(0xFFD97706),
    bg: Color(0x0FD97706),
    placeholder: 'e.g., Bus 12 delayed by 30 mins, breakdown near highway turnoff…',
  ),
  AiIssueType.lunch: _IssueCfg(
    icon: '🍱',
    label: 'Lunch Concern',
    color: Color(0xFF16A34A),
    bg: Color(0x0F16A34A),
    placeholder: 'e.g., Riya in 4-B forgot her lunch box, nut allergy — please remind teacher…',
  ),
  AiIssueType.emergency: _IssueCfg(
    icon: '🚨',
    label: 'Emergency Pickup',
    color: Color(0xFFDC2626),
    bg: Color(0x0FDC2626),
    placeholder: 'e.g., Father will pick up Rahul (5-A) at 1 pm — medical appointment…',
  ),
};

/// Mirrors frontend components/aibot/IssueFlow.tsx exactly: purely local
/// note-taking, no backend call (matches the source component's own
/// zero-API-call behavior).
class AiIssueFlow extends StatefulWidget {
  final AiIssueType type;
  final void Function(String note) onComplete;
  final VoidCallback onCancel;

  const AiIssueFlow({super.key, required this.type, required this.onComplete, required this.onCancel});

  @override
  State<AiIssueFlow> createState() => _AiIssueFlowState();
}

class _AiIssueFlowState extends State<AiIssueFlow> {
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _issueConfig[widget.type]!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all(color: aiBorder), borderRadius: BorderRadius.circular(12), color: aiBg0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: cfg.bg, border: const Border(bottom: BorderSide(color: aiBorder))),
            child: Row(
              children: [
                Expanded(
                  child: Text('${cfg.icon} ${cfg.label}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cfg.color)),
                ),
                InkWell(
                  onTap: widget.onCancel,
                  child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 18, color: aiInk3)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Describe the issue:', style: TextStyle(fontSize: 12, color: aiInk2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  autofocus: true,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: cfg.placeholder,
                    isDense: true,
                    filled: true,
                    fillColor: aiBg2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
                  ),
                  style: const TextStyle(fontSize: 12.5, color: aiInk1),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(foregroundColor: aiInk2, side: const BorderSide(color: aiBorder), padding: const EdgeInsets.symmetric(vertical: 7)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _noteCtrl.text.trim().isEmpty ? null : () => widget.onComplete(_noteCtrl.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cfg.color,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: cfg.color.withValues(alpha: 0.5),
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          elevation: 0,
                        ),
                        child: Text('✓ Log ${cfg.label}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
