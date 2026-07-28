import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../../../admissions/presentation/providers/admissions_provider.dart';
import '../../../student/domain/models/student_data.dart';
import '../../../student/presentation/providers/student_providers.dart';
import '../../data/ai_assistant_remote_datasource.dart';
import '../../data/ai_faq.dart';
import '../../data/ai_intent_parser.dart';
import '../../data/ai_search.dart';
import '../../domain/models/ai_intent.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/ai_todo_item.dart';
import 'ai_assistant_providers.dart';
import 'ai_assistant_state.dart';

final aiAssistantControllerProvider = StateNotifierProvider<AiAssistantController, AiAssistantState>((ref) {
  return AiAssistantController(ref);
});

const _dayMap = {
  'mon': 0, 'monday': 0, 'tue': 1, 'tuesday': 1, 'wed': 2, 'wednesday': 2,
  'thu': 3, 'thursday': 3, 'fri': 4, 'friday': 4, 'sat': 5, 'saturday': 5, 'sun': 6, 'sunday': 6,
};
const _dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _issueLogLabels = {
  AiIssueType.bus: '🚌 Bus issue',
  AiIssueType.lunch: '🍱 Lunch concern',
  AiIssueType.emergency: '🚨 Emergency pickup',
};

/// Mirrors frontend components/AIBot.tsx's component state + `ask()` intent
/// dispatcher exactly, driving all chat/panel/todo state as a Riverpod
/// [StateNotifier] instead of React `useState`. Navigation goes straight
/// through [appRouterProvider] (no BuildContext needed), which is what lets
/// this controller live above the routed screens.
class AiAssistantController extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  int _idCounter = 0;

  AiAssistantController(this._ref) : super(const AiAssistantState()) {
    _loadTodos();
  }

  String _uid() => (++_idCounter).toString();

  void _addMsg(AiMsg m) => state = state.copyWith(msgs: [...state.msgs, m]);

  void _removeMsg(String id) => state = state.copyWith(msgs: state.msgs.where((m) => m.id != id).toList());

  Future<void> _loadTodos() async {
    final todos = await _ref.read(aiTodoStoreProvider).load();
    state = state.copyWith(todos: todos);
  }

  Future<void> _persistTodos() => _ref.read(aiTodoStoreProvider).save(state.todos);

  void openPanel() {
    if (state.msgs.isEmpty) {
      state = state.copyWith(
        open: true,
        msgs: [
          AiMsg(
            id: _uid(),
            role: AiMsgRole.bot,
            text:
                "Hi — I'm your eskoolia assistant. I can log parent calls (absence, bus issues, etc.), find students, check enquiries by phone number, navigate pages, and add tasks to your planner. Try a quick action below, or type a student name, phone number, or page.",
          ),
        ],
      );
      return;
    }
    final resultCount = state.msgs.where((m) => m.results != null || m.redirect != null).length;
    if (resultCount == 0) {
      state = state.copyWith(open: true);
      return;
    }
    final collapsed = state.msgs.map((m) => (m.results != null || m.redirect != null) ? m.copyWith(collapsed: true) : m).toList();
    state = state.copyWith(
      open: true,
      msgs: [...collapsed, AiMsg(id: _uid(), role: AiMsgRole.bot, text: '', collapsedCount: resultCount, collapsed: false)],
    );
  }

  void closePanel() => state = state.copyWith(open: false);

  void togglePanel() {
    if (state.open) {
      closePanel();
    } else {
      openPanel();
    }
  }

  void expandCollapsedResults() {
    final updated = state.msgs.map((m) => m.copyWith(collapsed: false)).where((m) => m.collapsedCount == null).toList();
    state = state.copyWith(msgs: updated);
  }

  void toggleTodos() => state = state.copyWith(showTodos: !state.showTodos);

  void toggleChips() => state = state.copyWith(showChips: !state.showChips);

  void addTodo(String text) {
    if (text.trim().isEmpty) return;
    state = state.copyWith(todos: [...state.todos, AiTodoItem(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text.trim())]);
    _persistTodos();
  }

  void toggleTodoDone(String id) {
    state = state.copyWith(todos: state.todos.map((t) => t.id == id ? t.copyWith(done: !t.done) : t).toList());
    _persistTodos();
  }

  void removeTodo(String id) {
    state = state.copyWith(todos: state.todos.where((t) => t.id != id).toList());
    _persistTodos();
  }

  void dismissFlow(String msgId) => _removeMsg(msgId);

  String _fmtDateLabel(String yyyyMmDd) {
    final d = DateTime.tryParse(yyyyMmDd);
    if (d == null) return yyyyMmDd;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void onAbsenceComplete(String msgId, AiAbsenceMarkResult result) {
    _removeMsg(msgId);
    final dateLabel = _fmtDateLabel(result.date);
    final classLabel = [result.className, result.sectionName].where((e) => e.isNotEmpty).join('-');
    _addMsg(AiMsg(
      id: _uid(),
      role: AiMsgRole.bot,
      text: '✅ **${result.studentName}** ($classLabel) marked absent for $dateLabel.\n_Reason: ${result.notes}_\n\nAttendance has been updated in the system.',
    ));
  }

  void onIssueComplete(String msgId, AiIssueType type, String note) {
    _removeMsg(msgId);
    _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: '✅ ${_issueLogLabels[type]} logged:\n_"$note"_\n\nPlease follow up with the relevant staff.'));
  }

  void _navigateAfterDelay(String path) {
    Future.delayed(const Duration(milliseconds: 680), () {
      _ref.read(appRouterProvider).go(path);
      closePanel();
    });
  }

  Future<void> ask(String q) async {
    if (q.trim().isEmpty) return;
    _addMsg(AiMsg(id: _uid(), role: AiMsgRole.user, text: q));

    final intent = parseIntent(q);

    if (intent is NavigateIntent) {
      final exact = exactMatch(q);
      if (exact != null) {
        _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, redirect: exact, text: 'Navigating to ${exact.label}…'));
        _navigateAfterDelay(exact.path);
      } else {
        _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: 'Navigating to ${intent.label}…'));
        _navigateAfterDelay(intent.path);
      }
      return;
    }

    if (intent is PhoneLookupIntent) {
      state = state.copyWith(loading: true);
      final typingId = _uid();
      _addMsg(AiMsg(id: typingId, role: AiMsgRole.bot, isTyping: true, text: ''));
      try {
        final all = await _ref.read(admissionsRepositoryProvider).getInquiries();
        final matches = all.where((e) => e.phone.replaceAll(RegExp(r'\D'), '').contains(intent.phone)).toList();
        _removeMsg(typingId);
        if (matches.isNotEmpty) {
          _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: '', enquiryResults: matches, enquiryQuery: intent.phone));
        } else {
          _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: '', phonePrompt: intent.phone));
        }
      } catch (_) {
        _removeMsg(typingId);
        _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: 'Could not check enquiry data. Please try again.'));
      } finally {
        state = state.copyWith(loading: false);
      }
      return;
    }

    if (intent is ReportAbsenceIntent) {
      _addMsg(AiMsg(
        id: _uid(),
        role: AiMsgRole.bot,
        text: 'Let me help you log this absence.',
        showAbsenceFlow: true,
        absenceFlowPrefillName: intent.query.isEmpty ? null : intent.query,
      ));
      return;
    }

    if (intent is ReportBusIntent) {
      _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: "I'll log this bus issue.", issueFlowType: AiIssueType.bus));
      return;
    }

    if (intent is ReportLunchIntent) {
      _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: "I'll log this lunch concern.", issueFlowType: AiIssueType.lunch));
      return;
    }

    if (intent is ReportEmergencyIntent) {
      _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: "I'll log this emergency pickup request.", issueFlowType: AiIssueType.emergency));
      return;
    }

    if (intent is StudentLookupIntent) {
      state = state.copyWith(loading: true);
      final typingId = _uid();
      _addMsg(AiMsg(id: typingId, role: AiMsgRole.bot, isTyping: true, text: ''));
      var students = <StudentData>[];
      try {
        final page = await _ref.read(studentRepositoryProvider).fetchStudentsFiltered(search: intent.query, pageSize: 8);
        students = page.results;
      } catch (_) {}
      state = state.copyWith(loading: false);
      _removeMsg(typingId);
      _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: '', studentResults: students, studentQuery: intent.query));
      return;
    }

    if (intent is EnquiryLookupIntent) {
      state = state.copyWith(loading: true);
      try {
        final all = await _ref.read(admissionsRepositoryProvider).getInquiries();
        final q2 = intent.query.toLowerCase();
        final matches = all
            .where((e) =>
                e.fullName.toLowerCase().contains(q2) ||
                e.phone.contains(q2) ||
                (e.classNameResolved?.toLowerCase().contains(q2) ?? false) ||
                e.childName.toLowerCase().contains(q2))
            .take(5)
            .toList();
        _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: '', enquiryResults: matches, enquiryQuery: intent.query));
      } catch (_) {
        _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: 'Could not fetch enquiry data. Please try again.'));
      } finally {
        state = state.copyWith(loading: false);
      }
      return;
    }

    if (intent is ParentQaIntent) {
      final faqAnswer = findFaqAnswer(q);
      if (faqAnswer != null) {
        _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: faqAnswer));
        return;
      }
      // No FAQ hit — falls through to the fuzzy fallback below, matching
      // AIBot.tsx's own fallthrough behavior for unmatched parent-qa intents.
    }

    if (intent is PlannerTaskIntent) {
      final dayIndex = _dayMap[intent.day.toLowerCase()] ?? 0;
      final timeRaw = intent.time.toLowerCase().trim();
      var timeFormatted = '09:00';
      final tMatch = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?$').firstMatch(timeRaw);
      if (tMatch != null) {
        var h = int.parse(tMatch.group(1)!);
        final m2 = tMatch.group(2) != null ? int.parse(tMatch.group(2)!) : 0;
        final mer = tMatch.group(3);
        if (mer == 'pm' && h < 12) h += 12;
        if (mer == 'am' && h == 12) h = 0;
        timeFormatted = '${h.toString().padLeft(2, '0')}:${m2.toString().padLeft(2, '0')}';
      }
      await _ref.read(aiPlannerStoreProvider).addEvent(dayIndex: dayIndex, time: timeFormatted, title: intent.title);
      _addMsg(AiMsg(
        id: _uid(),
        role: AiMsgRole.bot,
        text: '✅ Added to your planner: **${intent.title}** on **${_dayLabels[dayIndex]}** at **$timeFormatted**. Check the Week Ahead widget on your home screen.',
      ));
      return;
    }

    if (intent is ComposeMessageIntent) {
      final topic = intent.topic.toLowerCase();
      String template;
      if (topic.contains('fee') || topic.contains('payment')) {
        template =
            "Dear Parent,\n\nThis is a gentle reminder that your child's school fees for the current term are due. Kindly clear the outstanding amount at your earliest convenience to avoid any inconvenience.\n\nFor any queries regarding the fee structure or payment, please contact our accounts office.\n\nThank you for your cooperation.\n\nWarm regards,\n[School Name] Administration";
      } else if (topic.contains('attendance') || topic.contains('absent')) {
        template =
            "Dear Parent,\n\nWe wish to inform you that your child's attendance has been below the required 75% threshold. Regular attendance is essential for academic progress.\n\nKindly ensure your child attends school regularly. If there are any concerns, please meet with the class teacher at your earliest convenience.\n\nRegards,\n[School Name] Administration";
      } else if (topic.contains('exam') || topic.contains('result') || topic.contains('mark')) {
        template =
            "Dear Parent,\n\nWe are pleased to inform you that the exam results have been published. You can view your child's results by visiting our school portal or contacting the class teacher.\n\nFor result-related queries, please visit the school office during working hours.\n\nBest regards,\n[School Name] Academic Team";
      } else if (topic.contains('meeting') || topic.contains('parent teacher')) {
        template =
            "Dear Parent,\n\nYou are cordially invited to attend the Parent-Teacher Meeting scheduled on [DATE] at [TIME] in [VENUE].\n\nYour presence is important as we will discuss your child's academic progress, attendance, and overall development.\n\nKindly confirm your attendance by [RSVP DATE].\n\nLooking forward to meeting you.\n\nRegards,\n[School Name] Administration";
      } else {
        template =
            'Dear Parent,\n\nWe would like to bring to your attention an important matter regarding ${intent.topic}.\n\n[Please add your specific message here]\n\nFor any queries, please contact the school office.\n\nThank you.\n\nRegards,\n[School Name] Administration';
      }
      _addMsg(AiMsg(
        id: _uid(),
        role: AiMsgRole.bot,
        text: "📝 Here's a draft message about **${intent.topic}**:\n\n---\n\n$template\n\n---\n\n_Copy and customize as needed._",
      ));
      return;
    }

    // Reachable only by a ParentQaIntent with no FAQ hit, or a FuzzyPagesIntent
    // — every other intent kind returns above, matching AIBot.tsx's structure.
    final faqAnswer2 = findFaqAnswer(q);
    if (faqAnswer2 != null) {
      _addMsg(AiMsg(id: _uid(), role: AiMsgRole.bot, text: faqAnswer2));
      return;
    }

    state = state.copyWith(loading: true);
    final typingId2 = _uid();
    _addMsg(AiMsg(id: typingId2, role: AiMsgRole.bot, isTyping: true, text: ''));
    final pages = localFuzzySearch(q);
    state = state.copyWith(loading: false);
    _removeMsg(typingId2);
    _addMsg(AiMsg(
      id: _uid(),
      role: AiMsgRole.bot,
      text: pages.isNotEmpty ? 'Found ${pages.length} result${pages.length > 1 ? 's' : ''} for "$q":' : 'No results found for "$q". Try a different keyword.',
      results: pages.isNotEmpty ? pages : null,
    ));
  }
}
