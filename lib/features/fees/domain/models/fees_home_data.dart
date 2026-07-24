/// GET /api/v1/fees/home/ response shape.
/// Reference: frontend lib/fees-api.ts::FeesHomeData / FeesPaymentsPanel.tsx.
///
/// NOTE: `backend/apps/fees/urls.py` has no `home/` route — this endpoint
/// does not exist yet, so the real web app's fetch always 404s and its
/// `.catch(console.error)` silently leaves `tasks`/`audit_trail` empty. This
/// screen reproduces that faithfully: [FeesRepository.fetchHomeDashboard]
/// swallows the failure and returns an empty [FeesHomeData], so Task Queue
/// and Audit Trail render with nothing in them, matching the real app.
class FeesTaskButton {
  final String label;
  final String variant; // 'primary' | 'outline'
  final String toast;
  final String? href;

  const FeesTaskButton({required this.label, required this.variant, required this.toast, this.href});

  factory FeesTaskButton.fromJson(Map<String, dynamic> json) {
    return FeesTaskButton(
      label: (json['label'] as String?) ?? '',
      variant: (json['variant'] as String?) ?? 'outline',
      toast: (json['toast'] as String?) ?? '',
      href: json['href'] as String?,
    );
  }
}

class FeesTask {
  final String id;
  final String color;
  final String title;
  final String desc;
  final List<FeesTaskButton> buttons;

  const FeesTask({required this.id, required this.color, required this.title, required this.desc, required this.buttons});

  factory FeesTask.fromJson(Map<String, dynamic> json) {
    return FeesTask(
      id: (json['id'] as String?) ?? '',
      color: (json['color'] as String?) ?? '#6D4AFF',
      title: (json['title'] as String?) ?? '',
      desc: (json['desc'] as String?) ?? '',
      buttons: ((json['buttons'] as List<dynamic>?) ?? const [])
          .map((e) => FeesTaskButton.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeesAuditItem {
  final String id;
  final String initials;
  final String event;
  final String desc;
  final String date;
  final String bg;

  const FeesAuditItem({
    required this.id,
    required this.initials,
    required this.event,
    required this.desc,
    required this.date,
    required this.bg,
  });

  factory FeesAuditItem.fromJson(Map<String, dynamic> json) {
    return FeesAuditItem(
      id: (json['id'] as String?) ?? '',
      initials: (json['initials'] as String?) ?? '',
      event: (json['event'] as String?) ?? '',
      desc: (json['desc'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      bg: (json['bg'] as String?) ?? '#6D4AFF',
    );
  }
}

class FeesHomeData {
  final List<FeesTask> tasks;
  final List<FeesAuditItem> auditTrail;

  const FeesHomeData({this.tasks = const [], this.auditTrail = const []});

  factory FeesHomeData.fromJson(Map<String, dynamic> json) {
    return FeesHomeData(
      tasks: ((json['tasks'] as List<dynamic>?) ?? const [])
          .map((e) => FeesTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      auditTrail: ((json['audit_trail'] as List<dynamic>?) ?? const [])
          .map((e) => FeesAuditItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
