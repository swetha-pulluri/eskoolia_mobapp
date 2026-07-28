import '../../../admissions/domain/entities/inquiry_entity.dart';
import '../../../student/domain/models/student_data.dart';
import 'flat_index_entry.dart';

enum AiMsgRole { user, bot }

enum AiIssueType { bus, lunch, emergency }

/// Mirrors frontend components/AIBot.tsx's `Msg` interface — one chat
/// bubble/card, which may carry any combination of a plain text reply, a
/// navigate-redirect card, fuzzy page results, real student/enquiry lookup
/// results (reusing Flutter's own [StudentData]/[InquiryEntity] models
/// rather than a separate duplicate shape), a phone-not-found prompt, the
/// quick-actions chip row, or an inline Absence/Issue flow.
class AiMsg {
  final String id;
  final AiMsgRole role;
  final String? text;
  final List<FlatIndexEntry>? results;
  final List<StudentData>? studentResults;
  final String? studentQuery;
  final List<InquiryEntity>? enquiryResults;
  final String? enquiryQuery;
  final FlatIndexEntry? redirect;
  final bool collapsed;
  final int? collapsedCount;
  final bool isTyping;
  final String? phonePrompt;
  final bool quickActions;
  final bool showAbsenceFlow;
  final String? absenceFlowPrefillName;
  final AiIssueType? issueFlowType;

  const AiMsg({
    required this.id,
    required this.role,
    this.text,
    this.results,
    this.studentResults,
    this.studentQuery,
    this.enquiryResults,
    this.enquiryQuery,
    this.redirect,
    this.collapsed = false,
    this.collapsedCount,
    this.isTyping = false,
    this.phonePrompt,
    this.quickActions = false,
    this.showAbsenceFlow = false,
    this.absenceFlowPrefillName,
    this.issueFlowType,
  });

  AiMsg copyWith({bool? collapsed}) {
    return AiMsg(
      id: id,
      role: role,
      text: text,
      results: results,
      studentResults: studentResults,
      studentQuery: studentQuery,
      enquiryResults: enquiryResults,
      enquiryQuery: enquiryQuery,
      redirect: redirect,
      collapsed: collapsed ?? this.collapsed,
      collapsedCount: collapsedCount,
      isTyping: isTyping,
      phonePrompt: phonePrompt,
      quickActions: quickActions,
      showAbsenceFlow: showAbsenceFlow,
      absenceFlowPrefillName: absenceFlowPrefillName,
      issueFlowType: issueFlowType,
    );
  }
}
