/// Single source of truth for "which route does this user land on after
/// login" — ports web's `app/login/page.tsx` role-based redirect exactly
/// (checks only `portal_type`; Super Admin and School Admin both resolve to
/// `portal_type == 'admin'` server-side — see `User.resolve_portal_type()`
/// — so both land on `/home` just like web, with no separate branch
/// needed for `isSuperuser`). Shared by `app_router.dart`'s `redirect`
/// callback and `login_page.dart`'s explicit post-login navigation so the
/// role→route mapping is defined in exactly one place.
String resolveHomeRouteForPortal(String portalType) {
  switch (portalType) {
    case 'teacher':
      return '/teacher/home';
    case 'parent':
      return '/parent/home';
    case 'student':
      return '/student/home';
    default:
      // 'admin', 'custom', or anything unrecognized — matches web's own
      // `else` fallback to `/home`.
      return '/home';
  }
}
