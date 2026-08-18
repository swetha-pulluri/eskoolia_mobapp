import 'package:flutter/material.dart';
import '../../../dashboard/domain/entities/module_entity.dart';

/// The Home screen's own decorative "All Modules" grid catalog — mirrors
/// web's `(parent-portal)/parent/home/page.tsx`'s own local `ALL_MODULES`
/// const exactly (same names, paths, icons, colors, order). This is a
/// SEPARATE list from [ParentNavModules] below: web itself keeps two
/// distinct Parent module catalogs — this decorative one (Home page's own
/// grid tiles) and the real nav registry (`lib/parent-routes.ts`'s
/// `PARENT_MODULES`, used by the top bar/sub-nav) — with different
/// entries/colors/order. Do not conflate them.
///
/// `Academics`/`Student Life`/`Documents` all resolve to `/parent/children`
/// on web too (there is no dedicated page behind any of them — see
/// `ChildrenPage`'s doc comment) — now that that page is built, those 3
/// tiles are real navigation, not `comingSoon`. `Attendance`, `Fees`, and
/// `Communication` now resolve to the real `AttendancePage`/`FeesPage`/
/// `NoticesPage`. `Transport`/`Cafeteria` point at `/parent/home` on web too
/// (no dedicated page behind them either) — since that page is real, those
/// are real navigation as well, even though the destination looks unrelated
/// to the tile's own name; that is web's own behavior, not a Flutter bug.
/// `Profile` is the one exception — see its own inline comment below,
/// disclosed as `comingSoon` instead of silently aliasing like the other
/// two. `My Profile` is a deliberate Flutter-only 11th tile (by request) —
/// web's own decorative `ALL_MODULES` hasn't been updated to include it even
/// though the real `/parent/profile` page and its `parent-routes.ts` nav
/// entry both now exist (see [ParentNavModules]) — added here so it's also
/// reachable from this grid, not just the top-nav pill.
class ParentModules {
  ParentModules._();

  static final List<ModuleEntity> all = [
    const ModuleEntity(
      id: 'parent-home',
      name: 'Dashboard',
      path: '/parent/home',
      icon: Icons.home_outlined,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF5836E0),
      iconAsset: 'assets/icons/dashboard_3d.png',
    ),
    const ModuleEntity(
      id: 'parent-academics',
      name: 'Academics',
      path: '/parent/children',
      icon: Icons.school_outlined,
      bgColor: Color(0xFFDDF6E4),
      iconColor: Color(0xFF0E9F6E),
      iconAsset: 'assets/icons/academics_3d.png',
    ),
    const ModuleEntity(
      id: 'parent-attendance-module',
      name: 'Attendance',
      path: '/parent/attendance',
      icon: Icons.calendar_month_outlined,
      bgColor: Color(0xFFDDF6E4),
      iconColor: Color(0xFF0E9F6E),
      iconAsset: 'assets/icons/attendance_3d.png',
    ),
    const ModuleEntity(
      id: 'parent-fees-module',
      name: 'Fees',
      path: '/parent/fees',
      icon: Icons.payment_outlined,
      bgColor: Color(0xFFFEF1CC),
      iconColor: Color(0xFFA65D08),
      iconAsset: 'assets/icons/fees_3d.png',
    ),
    const ModuleEntity(
      id: 'parent-communication',
      name: 'Communication',
      path: '/parent/notices',
      icon: Icons.chat_bubble_outline,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF5836E0),
      iconAsset: 'assets/icons/communication-parent.png',
    ),
    const ModuleEntity(
      id: 'parent-student-life',
      name: 'Student Life',
      path: '/parent/children',
      icon: Icons.emoji_events_outlined,
      bgColor: Color(0xFFE0EAFE),
      iconColor: Color(0xFF0369A1),
      iconAsset: 'assets/icons/students_3d.png',
    ),
    // Flutter-only addition to this decorative grid (see class doc comment)
    // — matches the real `/parent/profile` page, same position (right after
    // Student Life) as the real nav entry in [ParentNavModules].
    const ModuleEntity(
      id: 'parent-my-profile',
      name: 'My Profile',
      path: '/parent/profile',
      icon: Icons.person_outline,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF4F35CC),
      iconAsset: 'assets/icons/profile.png',
    ),
    const ModuleEntity(
      id: 'parent-transport',
      name: 'Transport',
      path: '/parent/home',
      icon: Icons.directions_bus_outlined,
      bgColor: Color(0xFFFCE6F0),
      iconColor: Color(0xFF992558),
      iconAsset: 'assets/icons/bus.png',
    ),
    const ModuleEntity(
      id: 'parent-documents',
      name: 'Documents',
      path: '/parent/children',
      icon: Icons.description_outlined,
      bgColor: Color(0xFFE0EAFE),
      iconColor: Color(0xFF1A4ACF),
      iconAsset: 'assets/icons/sticky-notes.png',
    ),
    const ModuleEntity(
      id: 'parent-cafeteria',
      name: 'Cafeteria',
      path: '/parent/home',
      icon: Icons.grid_view_outlined,
      bgColor: Color(0xFFF4F4F8),
      iconColor: Color(0xFF5A607A),
      iconAsset: 'assets/icons/cafeteria-parent.png',
    ),
    // Web's own tile just aliases to `/parent/home` (same trick as
    // Transport/Cafeteria above) — a leftover, unrelated to the real
    // `My Profile` tile above. NOT the same module: this one still has no
    // genuine destination of its own on web (unlike `My Profile`, which
    // resolves to the real `/parent/profile` page), so it stays disclosed
    // as `comingSoon` (same treatment as `Results` in `ParentNavModules`)
    // rather than silently redirecting to Home like Transport/Cafeteria do.
    const ModuleEntity(
      id: 'parent-profile',
      name: 'Profile',
      path: '/parent/home',
      icon: Icons.person_outline,
      bgColor: Color(0xFFF4F4F8),
      iconColor: Color(0xFF5A607A),
      comingSoon: true,
    ),
  ];

  static ModuleEntity? findById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  static ModuleEntity? findByPath(String path) {
    try {
      return all.firstWhere((m) => m.path == path);
    } catch (e) {
      return null;
    }
  }
}

/// The Home screen's own "Quick Access" tile set — mirrors web's `QUICK`
/// array exactly (same names, categories, icons, colors, order). Distinct
/// from [ParentModules.all]: these are Home-page launcher tiles, not top-nav
/// entries. "Timetable"/"Homework" resolve to `/parent/children` and "Bus
/// Tracking" to `/parent/home` on web too (see [ParentModules]' own doc
/// comment) — now real navigation. "Attendance"/"Apply Leave" both resolve
/// to `/parent/attendance`, "Pay Fees" to `/parent/fees`, and "Permission
/// Slips"/"Message Teacher" to `/parent/notices` — all now real. Every tile
/// in this list is now real navigation — none currently `comingSoon`.
class ParentQuickAccess {
  ParentQuickAccess._();

  static final List<ModuleEntity> all = [
    const ModuleEntity(
      id: 'quick-attendance',
      name: 'Attendance',
      path: '/parent/attendance',
      icon: Icons.calendar_month_outlined,
      bgColor: Color(0xFFDDF6E4),
      iconColor: Color(0xFF0E9F6E),
      iconAsset: 'assets/icons/attendance_3d.png',
    ),
    const ModuleEntity(
      id: 'quick-timetable',
      name: 'Timetable',
      path: '/parent/children',
      icon: Icons.calendar_month_outlined,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF5836E0),
    ),
    const ModuleEntity(
      id: 'quick-pay-fees',
      name: 'Pay Fees',
      path: '/parent/fees',
      icon: Icons.credit_card_outlined,
      bgColor: Color(0xFFFEF1CC),
      iconColor: Color(0xFFA65D08),
      iconAsset: 'assets/icons/paay-slips-parent.png',
    ),
    const ModuleEntity(
      id: 'quick-permission-slips',
      name: 'Permission Slips',
      path: '/parent/notices',
      icon: Icons.description_outlined,
      bgColor: Color(0xFFE0EAFE),
      iconColor: Color(0xFF1A4ACF),
      iconAsset: 'assets/icons/sticky-notes.png',
    ),
    const ModuleEntity(
      id: 'quick-apply-leave',
      name: 'Apply Leave',
      path: '/parent/attendance',
      icon: Icons.eco_outlined,
      bgColor: Color(0xFFDDF6E4),
      iconColor: Color(0xFF0E9F6E),
      iconAsset: 'assets/icons/apply- leave-parent.png',
    ),
    const ModuleEntity(
      id: 'quick-bus-tracking',
      name: 'Bus Tracking',
      path: '/parent/home',
      icon: Icons.directions_bus_outlined,
      bgColor: Color(0xFFFCE6F0),
      iconColor: Color(0xFF992558),
      iconAsset: 'assets/icons/bus-tracking-parent.png',
    ),
    const ModuleEntity(
      id: 'quick-homework',
      name: 'Homework',
      path: '/parent/children',
      icon: Icons.description_outlined,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF5836E0),
      iconAsset: 'assets/icons/openbook.png',
    ),
    const ModuleEntity(
      id: 'quick-message-teacher',
      name: 'Message Teacher',
      path: '/parent/notices',
      icon: Icons.chat_bubble_outline,
      bgColor: Color(0xFFFEE2E5),
      iconColor: Color(0xFFE0463A),
      iconAsset: 'assets/icons/message- teacher.png',
    ),
  ];
}

/// The Parent Portal's REAL nav registry — mirrors web's
/// `frontend/lib/parent-routes.ts`'s `PARENT_MODULES` exactly (same ids,
/// names, paths, icons, colors, and each module's own `sub` array). This is
/// what `ParentTopBar`'s pills and `GlobalAppShell`'s `ModuleSubNav` are
/// driven by — distinct from [ParentModules] above, which is only the Home
/// page's own decorative "All Modules" grid (see its doc comment for why
/// web itself keeps two separate lists).
///
/// "Timetable"/"Syllabus"/"Homework" (under Academics) and all of Student
/// Life's subs resolve to `/parent/children` on web too — there is no
/// dedicated timetable/syllabus/homework page there, just this one child
/// profile page (see `ChildrenPage`'s doc comment). Attendance, Fees, and
/// Communication now resolve to the real `AttendancePage`/`FeesPage`/
/// `NoticesPage` ("Fee Summary"/"Receipts" both resolve to the one
/// `FeesPage`, and Communication's "Messages"/"PTMs"/"Permissions" all
/// resolve to the one `NoticesPage`, on web too — no separate receipts/
/// messaging/PTM/permission-slip feature there). `My Profile` now resolves
/// to the real `ParentProfilePage` (admission-wizard-captured child data).
/// Results points at a Flutter page that doesn't exist yet, so that module
/// (and its subs) stays `comingSoon: true`.
class ParentNavModules {
  ParentNavModules._();

  static final List<ModuleEntity> all = [
    const ModuleEntity(
      id: 'parent-home',
      name: 'Home',
      path: '/parent/home',
      icon: Icons.grid_view_outlined,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF4F35CC),
    ),
    const ModuleEntity(
      id: 'parent-academics',
      name: 'Academics',
      path: '/parent/children',
      icon: Icons.school_outlined,
      bgColor: Color(0xFFDDF6E4),
      iconColor: Color(0xFF0D7A55),
      subModules: [
        SubModuleEntity(label: 'Timetable', path: '/parent/children', icon: Icons.calendar_month_outlined),
        SubModuleEntity(label: 'Syllabus', path: '/parent/children', icon: Icons.menu_book_outlined),
        SubModuleEntity(label: 'Homework', path: '/parent/children', icon: Icons.description_outlined),
        SubModuleEntity(label: 'Grades', path: '/parent/results', icon: Icons.star_outline, comingSoon: true),
        SubModuleEntity(label: 'Library', path: '/parent/home', icon: Icons.menu_book_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'parent-attendance',
      name: 'Attendance',
      path: '/parent/attendance',
      icon: Icons.calendar_month_outlined,
      bgColor: Color(0xFFDDF6E4),
      iconColor: Color(0xFF0D7A55),
      // "Daily Log"/"Apply Leave"/"Calendar"/"Holidays" all resolve to this
      // one real `AttendancePage` on web too — there's no separate leave-
      // application form or daily-log view there, just this calendar (see
      // `AttendancePage`'s doc comment). Matches web's own behavior exactly,
      // not a Flutter gap.
      subModules: [
        SubModuleEntity(label: 'Daily Log', path: '/parent/attendance', icon: Icons.calendar_month_outlined),
        SubModuleEntity(label: 'Apply Leave', path: '/parent/attendance', icon: Icons.eco_outlined),
        SubModuleEntity(label: 'Calendar', path: '/parent/attendance', icon: Icons.calendar_month_outlined),
        SubModuleEntity(label: 'Holidays', path: '/parent/attendance', icon: Icons.shield_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'parent-fees',
      name: 'Fees',
      path: '/parent/fees',
      icon: Icons.credit_card_outlined,
      bgColor: Color(0xFFFEF1CC),
      iconColor: Color(0xFFA65D08),
      subModules: [
        SubModuleEntity(label: 'Fee Summary', path: '/parent/fees', icon: Icons.credit_card_outlined),
        SubModuleEntity(label: 'Receipts', path: '/parent/fees', icon: Icons.description_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'parent-communication',
      name: 'Communication',
      path: '/parent/notices',
      icon: Icons.notifications_outlined,
      bgColor: Color(0xFFE0EAFE),
      iconColor: Color(0xFF1A4ACF),
      subModules: [
        SubModuleEntity(label: 'Notices', path: '/parent/notices', icon: Icons.notifications_outlined),
        SubModuleEntity(label: 'Messages', path: '/parent/notices', icon: Icons.chat_bubble_outline),
        SubModuleEntity(label: 'PTMs', path: '/parent/notices', icon: Icons.people_outline),
        SubModuleEntity(label: 'Permissions', path: '/parent/notices', icon: Icons.description_outlined),
      ],
    ),
    const ModuleEntity(
      id: 'parent-results',
      name: 'Results',
      path: '/parent/results',
      icon: Icons.emoji_events_outlined,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF4F35CC),
      comingSoon: true,
      subModules: [
        SubModuleEntity(label: 'Exam Results', path: '/parent/results', icon: Icons.emoji_events_outlined, comingSoon: true),
        SubModuleEntity(label: 'Report Cards', path: '/parent/results', icon: Icons.description_outlined, comingSoon: true),
      ],
    ),
    const ModuleEntity(
      id: 'parent-student-life',
      name: 'Student Life',
      path: '/parent/children',
      icon: Icons.monitor_heart_outlined,
      bgColor: Color(0xFFE0EAFE),
      iconColor: Color(0xFF0369A1),
      subModules: [
        SubModuleEntity(label: 'Behaviour', path: '/parent/children', icon: Icons.star_outline),
        SubModuleEntity(label: 'Health Log', path: '/parent/children', icon: Icons.monitor_heart_outlined),
        SubModuleEntity(label: 'Sports & Clubs', path: '/parent/children', icon: Icons.emoji_events_outlined),
      ],
    ),
    // Newly added on web (`parent-routes.ts`'s `PARENT_MODULES`), positioned
    // exactly here — after Student Life, before Transport. Real page now:
    // `/parent/profile` shows the admission-wizard-captured data for each
    // child (see `ParentProfilePage`'s doc comment). No sub-tabs on web
    // either (`sub: []`).
    const ModuleEntity(
      id: 'parent-my-profile',
      name: 'My Profile',
      path: '/parent/profile',
      icon: Icons.person_outline,
      bgColor: Color(0xFFEEEAFF),
      iconColor: Color(0xFF4F35CC),
    ),
    const ModuleEntity(
      id: 'parent-transport',
      name: 'Transport',
      path: '/parent/home',
      icon: Icons.directions_bus_outlined,
      bgColor: Color(0xFFFCE6F0),
      iconColor: Color(0xFF992558),
      subModules: [
        SubModuleEntity(label: 'Bus Tracking', path: '/parent/home', icon: Icons.directions_bus_outlined),
        SubModuleEntity(label: 'Pickup Auth', path: '/parent/children', icon: Icons.people_outline),
      ],
    ),
  ];

  static ModuleEntity? findById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  static ModuleEntity? findByPath(String path) {
    try {
      return all.firstWhere((m) => m.path == path);
    } catch (e) {
      return null;
    }
  }
}
