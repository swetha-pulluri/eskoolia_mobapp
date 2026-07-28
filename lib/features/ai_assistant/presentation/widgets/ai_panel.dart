import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_assistant_controller.dart';
import '../providers/ai_assistant_state.dart';
import 'ai_assistant_colors.dart';
import 'ai_message_bubble.dart';

const _quickCallActions = [
  (label: '🏥 Absence', q: 'report absence', color: Color(0xFFDC2626), bg: Color(0x12DC2626)),
  (label: '🚌 Bus Issue', q: 'bus late', color: Color(0xFFD97706), bg: Color(0x12D97706)),
  (label: '🍱 Lunch', q: 'forgot lunch', color: Color(0xFF16A34A), bg: Color(0x1216A34A)),
  (label: '🚨 Pickup', q: 'emergency pickup', color: Color(0xFF7C3AED), bg: Color(0x127C3AED)),
];

const _quickGoTo = [
  (label: '📋 Attendance', q: 'student attendance'),
  (label: '💰 Fee dues', q: 'fees due'),
  (label: '🚌 Live bus', q: 'live bus tracking'),
  (label: '📅 Exam schedule', q: 'exam schedule'),
  (label: '📝 Marks', q: 'marks register'),
  (label: '🏥 Sick bay', q: 'sick bay'),
  (label: '📢 Broadcast', q: 'send broadcast'),
];

/// Mirrors AIBot.tsx's panel JSX (header, To-Do widget, messages list,
/// input + collapsible quick actions) as one Riverpod-driven shell.
class AiPanel extends ConsumerStatefulWidget {
  final double width;

  const AiPanel({super.key, this.width = 380});

  @override
  ConsumerState<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends ConsumerState<AiPanel> {
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final TextEditingController _todoCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  int _lastMsgCount = 0;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocus.dispose();
    _todoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottomIfNeeded(int count) {
    if (count == _lastMsgCount) return;
    _lastMsgCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  void _send() {
    final q = _inputCtrl.text;
    if (q.trim().isEmpty) return;
    _inputCtrl.clear();
    ref.read(aiAssistantControllerProvider.notifier).ask(q);
  }

  void _quickAsk(String q) {
    ref.read(aiAssistantControllerProvider.notifier).ask(q);
    ref.read(aiAssistantControllerProvider.notifier).toggleChips();
  }

  void _prefillInput(String text) {
    ref.read(aiAssistantControllerProvider.notifier).toggleChips();
    _inputCtrl.text = text;
    _inputCtrl.selection = TextSelection.collapsed(offset: text.length);
    Future.delayed(const Duration(milliseconds: 50), () => _inputFocus.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantControllerProvider);
    final controller = ref.read(aiAssistantControllerProvider.notifier);
    _scrollToBottomIfNeeded(state.msgs.length);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: widget.width,
        constraints: const BoxConstraints(maxHeight: 540),
        decoration: BoxDecoration(
          color: aiBg1,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: aiBorder),
          boxShadow: [BoxShadow(color: const Color(0xFF0E1020).withValues(alpha: 0.25), blurRadius: 60, offset: const Offset(0, 20), spreadRadius: -10)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(controller),
            _todoWidget(state, controller),
            Flexible(child: _messagesList(state, controller)),
            _inputArea(state, controller),
          ],
        ),
      ),
    );
  }

  Widget _header(AiAssistantController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: aiBorder))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: Alignment(-0.4, -0.44), colors: [Color(0xFF3A2A82), Color(0xFF150D3A), Color(0xFF0A0820)], stops: [0.0, 0.6, 1.0]),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ask eskoolia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: aiInk1)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E))),
                    const SizedBox(width: 4),
                    const Text('Online · navigate by keyword', style: TextStyle(fontSize: 11, color: aiInk3)),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: controller.closePanel,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: aiBorder)),
              alignment: Alignment.center,
              child: const Icon(Icons.close, size: 14, color: aiInk3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todoWidget(AiAssistantState state, AiAssistantController controller) {
    final pending = state.todos.where((t) => !t.done).length;
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: aiBorder))),
      child: Column(
        children: [
          InkWell(
            onTap: controller.toggleTodos,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('✓ TO-DO ($pending pending)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: aiInk3, letterSpacing: 0.6)),
                  ),
                  Text(state.showTodos ? '▲' : '▼', style: const TextStyle(fontSize: 11, color: aiPurple)),
                ],
              ),
            ),
          ),
          if (state.showTodos)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: [
                  if (state.todos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No tasks yet', style: TextStyle(fontSize: 12, color: aiInk3)),
                    ),
                  for (final t in state.todos)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: aiBorder))),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: t.done,
                              onChanged: (_) => controller.toggleTodoDone(t.id),
                              activeColor: aiPurple,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: t.done ? aiInk3 : aiInk1,
                                decoration: t.done ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                          ),
                          InkWell(onTap: () => controller.removeTodo(t.id), child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 14, color: aiInk3))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _todoCtrl,
                          onSubmitted: (v) {
                            controller.addTodo(v);
                            _todoCtrl.clear();
                          },
                          decoration: InputDecoration(
                            hintText: 'Add task…',
                            isDense: true,
                            filled: true,
                            fillColor: aiBg2,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: aiBorder)),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          controller.addTodo(_todoCtrl.text);
                          _todoCtrl.clear();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: aiPurple, borderRadius: BorderRadius.circular(8)),
                          child: const Text('+', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
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

  Widget _messagesList(AiAssistantState state, AiAssistantController controller) {
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shrinkWrap: true,
      itemCount: state.msgs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = state.msgs[i];
        if (m.collapsedCount != null) {
          return Center(
            child: OutlinedButton(
              onPressed: controller.expandCollapsedResults,
              style: OutlinedButton.styleFrom(foregroundColor: aiPurple, side: const BorderSide(color: aiBorder), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text('${m.collapsedCount} previous result${m.collapsedCount! > 1 ? 's' : ''} — show', style: const TextStyle(fontSize: 11)),
            ),
          );
        }
        if (m.collapsed) return const SizedBox.shrink();
        return AiMessageBubble(msg: m);
      },
    );
  }

  Widget _inputArea(AiAssistantState state, AiAssistantController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: aiBorder))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _inputFocus,
                  enabled: !state.loading,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Type a page or student name…',
                    isDense: true,
                    filled: true,
                    fillColor: aiBg2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: aiBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: aiBorder)),
                  ),
                  style: const TextStyle(fontSize: 13, color: aiInk1),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _inputCtrl,
                builder: (context, value, _) {
                  final enabled = !state.loading && value.text.trim().isNotEmpty;
                  return InkWell(
                    onTap: enabled ? _send : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: aiPurple.withValues(alpha: enabled ? 1 : 0.5), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.send, size: 14, color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Type a student name, phone number, or page name', style: TextStyle(fontSize: 10, color: aiInk3), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          InkWell(
            onTap: controller.toggleChips,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: aiBg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: aiBorder)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('⚡ Quick actions', style: TextStyle(fontSize: 11, color: aiInk2, fontWeight: FontWeight.w500)),
                  Text(state.showChips ? '▲ hide' : '▼ show', style: const TextStyle(fontSize: 10, color: aiInk3)),
                ],
              ),
            ),
          ),
          if (state.showChips) ...[
            const SizedBox(height: 8),
            _chipGroup('📞 LOG A CALL', [
              for (final c in _quickCallActions) _chip(label: c.label, color: c.color, bg: c.bg, border: c.color.withValues(alpha: 0.3), onTap: () => _quickAsk(c.q)),
            ]),
            const SizedBox(height: 8),
            _chipGroup('🔗 GO TO', [
              for (final c in _quickGoTo) _chip(label: c.label, color: aiInk2, bg: aiBg2, border: aiBorder, onTap: () => _quickAsk(c.q)),
            ]),
            const SizedBox(height: 8),
            _chipGroup('🔍 SEARCH & TOOLS', [
              _chip(label: '🎓 Find student…', color: aiPurple, bg: aiPurpleSoft, border: aiPurple.withValues(alpha: 0.4), onTap: () => _prefillInput('find ')),
              _chip(label: '📋 Find enquiry…', color: const Color(0xFF92400E), bg: const Color(0xFFFEF3C7), border: const Color(0xFFEA580C).withValues(alpha: 0.4), onTap: () => _prefillInput('find enquiry ')),
              _chip(label: '📅 Add to planner…', color: const Color(0xFF1E40AF), bg: const Color(0xFFDBEAFE), border: const Color(0xFF3B82F6).withValues(alpha: 0.4), onTap: () => _prefillInput('add wednesday 10am ')),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _chipGroup(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: aiInk3, letterSpacing: 0.7)),
        const SizedBox(height: 4),
        Wrap(spacing: 5, runSpacing: 5, children: chips),
      ],
    );
  }

  Widget _chip({required String label, required Color color, required Color bg, required Color border, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}
