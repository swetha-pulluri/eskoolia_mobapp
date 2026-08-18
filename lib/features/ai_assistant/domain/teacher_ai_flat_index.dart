import '../../teacher/domain/entities/teacher_module_entity.dart';
import 'models/flat_index_entry.dart';

/// Teacher-portal counterpart to [aiFlatIndex] (`ai_flat_index.dart`) — that
/// index is Admin-only (every entry points at an Admin `/xxx` route), so a
/// Teacher using Search was always being sent to Admin's own pages
/// regardless of which portal they're actually authenticated in. Concretely:
/// searching "fees" navigated to Admin's `/fees/payments` (`FeesHomePage`),
/// not `/teacher/fees/payments` (`TeacherFeesHomePage`) — and Admin's page
/// has no fix for the backend's CSS-colour-name fields
/// (`teacher_fees_home_page.dart`'s `_resolveHex`), so it crashed with
/// `FormatException: red` the moment its Task Queue/Audit Trail cards tried
/// to parse "red" as a hex string.
///
/// Built directly from [TeacherModules.all] (module + sub-module entries)
/// instead of a hand-duplicated parallel list, so it can never drift out of
/// sync with the real Teacher module catalog. `comingSoon` entries are
/// excluded — same "a search result never dead-ends" principle
/// `ai_flat_index.dart`'s own doc comment already states for Admin.
final List<FlatIndexEntry> teacherAiFlatIndex = [
  for (final m in TeacherModules.all) ...[
    if (!m.comingSoon)
      FlatIndexEntry(modId: m.id, label: m.name, path: m.path, icon: m.icon, bg: m.bgColor, ic: m.iconColor),
    for (final s in m.subModules)
      if (!s.comingSoon)
        FlatIndexEntry(
          modId: m.id,
          label: s.label,
          path: s.path,
          icon: s.icon ?? m.icon,
          bg: m.bgColor,
          ic: m.iconColor,
        ),
  ],
];
