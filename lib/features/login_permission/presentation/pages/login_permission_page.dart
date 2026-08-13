import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/login_permission_user.dart';
import '../providers/login_permission_notifier.dart';
import '../providers/login_permission_providers.dart';
import '../providers/login_permission_state.dart';
import '../widgets/login_permission_bulk_action_bar.dart';
import '../widgets/login_permission_bulk_confirm_dialog.dart';
import '../widgets/login_permission_credential_drawer.dart';
import '../widgets/login_permission_filter_bar.dart';
import '../widgets/login_permission_hero.dart';
import '../widgets/login_permission_stats.dart';
import '../widgets/login_permission_tabs.dart';
import '../widgets/login_permission_users_table.dart';

/// Login Permission page — backed by [loginPermissionNotifierProvider], which
/// talks to the real backend (backend/apps/access_control/views.py ::
/// LoginPermissionViewSet). All screen state (meta, active tab/filters, and
/// the current page of users) lives in the notifier; this widget only reads
/// it and dispatches user actions.
class LoginPermissionPage extends ConsumerWidget {
  const LoginPermissionPage({super.key});

  void _showToast(BuildContext context, String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF10B981)
            : const Color(0xFFE0463A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleOpenCredentials(
    BuildContext context,
    WidgetRef ref,
    LoginPermissionUser user,
  ) {
    LoginPermissionCredentialDrawer.show(
      context,
      user: user,
      onToast: (success, message) {
        _showToast(context, message, success: success);
        // Matches the frontend's fetchUsers()-after-success behavior, so
        // e.g. the "Must change" badge reflects a just-reset password.
        if (success) {
          ref.read(loginPermissionNotifierProvider.notifier).refreshCurrentPage();
        }
      },
    );
  }

  Future<void> _handleBulkAction(
    BuildContext context,
    WidgetRef ref, {
    required LoginPermissionBulkAction action,
    required int count,
  }) async {
    final confirmed = await showLoginPermissionBulkConfirmDialog(
      context: context,
      action: action,
      count: count,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    final notifier = ref.read(loginPermissionNotifierProvider.notifier);
    final userWord = count == 1 ? 'user' : 'users';
    String? error;
    String successMessage;
    switch (action) {
      case LoginPermissionBulkAction.enable:
        error = await notifier.bulkSetAccess(true);
        successMessage = 'Login access enabled for $count $userWord.';
        break;
      case LoginPermissionBulkAction.disable:
        error = await notifier.bulkSetAccess(false);
        successMessage = 'Login access disabled for $count $userWord.';
        break;
      case LoginPermissionBulkAction.reset:
        error = await notifier.bulkResetPasswords();
        successMessage = 'Passwords reset for $count $userWord.';
        break;
    }
    if (!context.mounted) return;
    _showToast(context, error ?? successMessage, success: error == null);
  }

  void _handleExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Export isn\'t available — the backend has no export endpoint for this list.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginPermissionNotifierProvider);
    final notifier = ref.read(loginPermissionNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Login Credentials',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: LoginPermissionHero(activeTab: state.activeTab),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Divider(height: 1, color: AppColors.cardBorder),
              ),

              // Portal Tabs — pinned so they stay visible while scrolling,
              // matching the frontend's `sticky top-0` tab bar.
              SliverPersistentHeader(
                pinned: true,
                delegate: _PortalTabsHeaderDelegate(
                  child: LoginPermissionTabs(
                    activeTab: state.activeTab,
                    onTabChanged: notifier.changeTab,
                    tabCounts: state.tabCounts,
                  ),
                ),
              ),

              ..._buildContentSlivers(context, ref, state, notifier),
            ],
          ),

          // Bulk action bar — floats above the content, shown only while a
          // row is selected, mirrors frontend BulkActionBar.tsx's
          // `fixed bottom-0 inset-x-0` overlay.
          if (state.selectedIds.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: Center(
                child: LoginPermissionBulkActionBar(
                  selectedCount: state.selectedIds.length,
                  onEnable: () => _handleBulkAction(
                    context,
                    ref,
                    action: LoginPermissionBulkAction.enable,
                    count: state.selectedIds.length,
                  ),
                  onDisable: () => _handleBulkAction(
                    context,
                    ref,
                    action: LoginPermissionBulkAction.disable,
                    count: state.selectedIds.length,
                  ),
                  onReset: () => _handleBulkAction(
                    context,
                    ref,
                    action: LoginPermissionBulkAction.reset,
                    count: state.selectedIds.length,
                  ),
                  onClose: () => notifier.clearSelection(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    WidgetRef ref,
    LoginPermissionScreenState state,
    LoginPermissionNotifier notifier,
  ) {
    if (state.metaLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    if (state.metaError != null) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildMessageBlock(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn\'t load roles',
              message: state.metaError!,
              actionLabel: 'Retry',
              onAction: () => notifier.retryMeta(),
            ),
          ),
        ),
      ];
    }

    if (!state.hasRolesForActiveTab) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildMessageBlock(
              icon: Icons.badge_outlined,
              title: 'No ${state.activeTab.label} roles found',
              message:
                  'Create a role with the correct portal type in Roles & Permissions first.',
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            LoginPermissionStats(counts: state.counts, activeTab: state.activeTab),
            const SizedBox(height: 20),

            LoginPermissionFilterBar(
              roleFilter: state.role ?? '',
              searchQuery: state.searchQuery,
              statusFilter: state.statusFilter,
              onRoleChanged: notifier.changeRole,
              onSearchChanged: notifier.updateSearchText,
              onStatusChanged: notifier.changeStatusFilter,
              onSearch: notifier.submitSearch,
              onExport: () => _handleExport(context),
              roleOptions: state.currentTabRoles.map((r) => r.name).toList(),
            ),
            const SizedBox(height: 20),

            _buildUsersArea(context, ref, state, notifier),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    ];
  }

  Widget _buildUsersArea(
    BuildContext context,
    WidgetRef ref,
    LoginPermissionScreenState state,
    LoginPermissionNotifier notifier,
  ) {
    // First load for this tab/filter combination — no stale data to show yet.
    if (state.usersLoading && state.pageResult == null) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.usersError != null && state.pageResult == null) {
      return _buildMessageBlock(
        icon: Icons.error_outline_rounded,
        title: 'Couldn\'t load users',
        message: state.usersError!,
        actionLabel: 'Retry',
        onAction: () => notifier.refreshCurrentPage(),
      );
    }

    return Stack(
      children: [
        LoginPermissionUsersTable(
          users: state.users,
          onToggleAccess: (id, value) async {
            final error = await notifier.toggleAccess(id, value);
            if (!context.mounted) return;
            _showToast(
              context,
              error ??
                  (value
                      ? 'Login access enabled successfully'
                      : 'Login access disabled successfully'),
              success: error == null,
            );
          },
          onOpenCredentials: (user) =>
              _handleOpenCredentials(context, ref, user),
          selectedIds: state.selectedIds,
          allOnPageSelected: state.allOnPageSelected,
          onSelectRow: notifier.toggleSelectRow,
          onSelectAllOnPage: notifier.toggleSelectAllOnPage,
        ),
        // Subtle overlay while refetching with existing data still visible
        // (tab already has results, e.g. a filter/search re-run).
        if (state.usersLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBlock({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEAFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: AppColors.dashboardPurple),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.inkPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: AppColors.inkTertiary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dashboardPurple,
                side: BorderSide(color: AppColors.dashboardPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pins the portal tab bar (with its bottom divider) to the top of the
/// scroll view once the hero has scrolled past — mirrors the frontend's
/// `sticky top-0 z-10` tab bar in login-permission/page.tsx.
class _PortalTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PortalTabsHeaderDelegate({required this.child});

  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // SliverPersistentHeader requires the built child to occupy exactly
    // minExtent/maxExtent — without a forced height here the tabs' intrinsic
    // content (~47px) mismatches the declared 48px, producing an invalid
    // SliverGeometry that crashes on paint every frame.
    return SizedBox(
      height: _height,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PortalTabsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
