/// A Home-screen widget definition, transcribed verbatim from web's
/// `frontend/lib/widgetStore.ts`'s `ALL_WIDGETS`. `icon` is the same emoji
/// web itself uses (its own choice, not a lucide icon this time).
///
/// NOTE: this only models the *management* list — actually rendering these
/// as Home-screen rail cards (web's `LeftRail`/`RightRail`) is an
/// explicitly deferred follow-up task (see `widget_manager_panel.dart`'s
/// header comment). This pass ports the toggle UI + persistence only.
class WidgetDefEntity {
  final String id;
  final String name;
  final String description;
  final String rail; // 'left' | 'right'
  final String icon; // emoji
  final bool defaultEnabled;
  final bool disabled;
  final bool comingSoon;
  final List<String>? roles; // null = all roles

  const WidgetDefEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.rail,
    required this.icon,
    this.defaultEnabled = false,
    this.disabled = false,
    this.comingSoon = false,
    this.roles,
  });
}

/// Verbatim transcription of web's 21-entry `ALL_WIDGETS` list.
final List<WidgetDefEntity> allWidgets = [
  const WidgetDefEntity(id: 'teacher-day-plan', name: "Today's Schedule", description: "Your classes and periods for today", rail: 'left', icon: '🗒', defaultEnabled: true, roles: ['teacher']),
  const WidgetDefEntity(id: 'attendance', name: 'Student Attendance', description: "Today's attendance snapshot", rail: 'left', icon: '📊', defaultEnabled: true, roles: ['admin']),
  const WidgetDefEntity(id: 'sickbay', name: 'Sick Bay', description: 'Students currently in sick bay', rail: 'left', icon: '🏥', disabled: true, comingSoon: true, roles: ['admin']),
  const WidgetDefEntity(id: 'busfleet', name: 'Bus Fleet', description: 'Live transport fleet status', rail: 'left', icon: '🚌', disabled: true, comingSoon: true, roles: ['admin']),
  const WidgetDefEntity(id: 'feestoday', name: "Today's Fees", description: 'Fee collections made today', rail: 'left', icon: '💰', defaultEnabled: true, roles: ['admin']),
  const WidgetDefEntity(id: 'staffleave', name: 'Staff Leave', description: 'Staff on leave today', rail: 'left', icon: '👤', disabled: true, comingSoon: true, roles: ['admin']),
  const WidgetDefEntity(id: 'morning-brief', name: 'Morning Brief', description: 'AI-generated summary of your day', rail: 'right', icon: '☀️', defaultEnabled: true, roles: ['admin']),
  const WidgetDefEntity(id: 'notifications', name: 'Notifications', description: 'Recent notifications', rail: 'right', icon: '🔔', defaultEnabled: true, roles: ['admin']),
  const WidgetDefEntity(id: 'calls-queue', name: 'Calls Queue', description: 'Pending calls to follow up', rail: 'right', icon: '📞', defaultEnabled: true, roles: ['admin']),
  const WidgetDefEntity(id: 'drafts', name: 'Drafts Pending', description: 'Unsent drafts waiting for review', rail: 'right', icon: '📝', disabled: true, roles: ['admin']),
  const WidgetDefEntity(id: 'academic-strip', name: 'Academic Calendar', description: 'Merged into Week Ahead widget', rail: 'right', icon: '📅', disabled: true, roles: ['admin']),
  const WidgetDefEntity(id: 'broadcast', name: 'Quick Broadcast', description: 'Send a quick announcement', rail: 'right', icon: '📢', defaultEnabled: true, roles: ['admin', 'teacher']),
  const WidgetDefEntity(id: 'parent-attendance', name: "Child's Attendance", description: "Your child's attendance summary", rail: 'left', icon: '📅', defaultEnabled: true, roles: ['parent']),
  const WidgetDefEntity(id: 'parent-results', name: 'Recent Results', description: "Your child's recent exam results", rail: 'left', icon: '📊', defaultEnabled: true, roles: ['parent']),
  const WidgetDefEntity(id: 'parent-notices', name: 'Notice Board', description: 'Latest notices from school', rail: 'right', icon: '🔔', defaultEnabled: true, roles: ['parent']),
  const WidgetDefEntity(id: 'parent-fees', name: 'Fee Status', description: 'Your outstanding/paid fees', rail: 'right', icon: '💳', defaultEnabled: true, roles: ['parent']),
  const WidgetDefEntity(id: 'smart-todo', name: 'Smart To-Do', description: 'Your task list for today', rail: 'right', icon: '✅', defaultEnabled: true),
  const WidgetDefEntity(id: 'week-ahead', name: 'Week Ahead', description: 'What is coming up this week', rail: 'right', icon: '🗓', defaultEnabled: true),
  const WidgetDefEntity(id: 'pinned-notes', name: 'Pinned Notes', description: 'Your pinned sticky notes', rail: 'right', icon: '📌'),
];

List<WidgetDefEntity> widgetsForRole(String role) => allWidgets.where((w) => w.roles == null || w.roles!.contains(role)).toList();
