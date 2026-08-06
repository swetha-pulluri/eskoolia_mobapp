import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/role_data.dart';
import '../providers/roles_providers.dart';
import '../providers/roles_state.dart';
import '../widgets/role_card.dart';
import '../widgets/add_role_card.dart';
import '../widgets/role_create_dialog.dart';
import '../widgets/role_edit_dialog.dart';
import '../widgets/role_delete_confirm_dialog.dart';
import '../widgets/assign_permissions_section.dart';

/// Which content is shown below the tab bar. "Assign Permissions" is a tab
/// within this same page/shell (not a separate route) — matching the
/// frontend's shared layout, where different tabs are different Next.js
/// routes but all render inside the same persistent header/nav.
enum _MainTab { roles, assignPermissions }

/// Roles & Permissions Page
/// Pixel-perfect Flutter recreation of frontend/components/access-control/RoleManagementPanel.tsx
///
/// Backed by [rolesNotifierProvider], which talks to the real backend
/// (backend/apps/access_control/views.py::RoleViewSet). Displays:
/// - Search and filter controls (re-fetch from the API, not client filtering)
/// - Responsive grid of role cards with hover/tap-reveal action icons
/// - Add new role functionality (unchanged — out of today's scope)
/// - Role actions wired to the backend: assign (navigate), edit, activate/
///   deactivate, delete
class RolesPermissionsPage extends ConsumerStatefulWidget {
  const RolesPermissionsPage({super.key});

  @override
  ConsumerState<RolesPermissionsPage> createState() =>
      _RolesPermissionsPageState();
}

class _RolesPermissionsPageState extends ConsumerState<RolesPermissionsPage> {
  final TextEditingController _searchController = TextEditingController();
  _MainTab _mainTab = _MainTab.roles;
  int? _assignRoleId;
  String? _assignRoleName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showToast(String message, {required bool success}) {
    if (!mounted) return;
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

  void _onSearchChanged(String value) {
    ref.read(rolesNotifierProvider.notifier).updateSearch(value);
  }

  Future<void> _onAddRole() async {
    final created = await RoleCreateDialog.show(context);
    if (created == null || !mounted) return;
    // Matches RoleManagementPanel.tsx's submit(): after a successful create
    // it skips reloading the list and immediately sends the admin to
    // Assign Permissions for the new role (`router.push('/roles/assign-
    // permission?roleId=...')`). This page keeps that same tab, rather than
    // a separate route (see _MainTab doc comment), so the equivalent is
    // `_onAssignPermissions`. `refresh()` beforehand is the one addition:
    // on web, navigating back to `/roles` later remounts the component and
    // refetches for free; here the Roles tab is never unmounted, so an
    // explicit refresh is needed for the new role to show up when the admin
    // returns to it — same end result as the frontend, adapted for the
    // tab-based (not route-based) navigation this page already uses.
    await ref.read(rolesNotifierProvider.notifier).refresh();
    if (!mounted) return;
    _showToast('"${created.name}" created.', success: true);
    _onAssignPermissions(created);
  }

  Future<void> _onEditRole(RoleData role) async {
    final updated = await RoleEditDialog.show(context, role: role);
    if (updated == null) return;
    ref.read(rolesNotifierProvider.notifier).applyUpdatedRole(updated);
    _showToast('"${updated.name}" updated.', success: true);
  }

  Future<void> _onDeleteRole(RoleData role) async {
    final confirmed = await showRoleDeleteConfirmDialog(
      context,
      roleName: role.name,
    );
    if (!confirmed) return;
    final error = await ref
        .read(rolesNotifierProvider.notifier)
        .deleteRole(role.id);
    if (!mounted) return;
    _showToast(error ?? 'Role deleted.', success: error == null);
  }

  Future<void> _onToggleActive(RoleData role) async {
    final nextActive = !role.isActive;
    final error = await ref
        .read(rolesNotifierProvider.notifier)
        .setActive(role.id, nextActive);
    if (!mounted) return;
    _showToast(
      error ??
          (nextActive
              ? '"${role.name}" activated.'
              : '"${role.name}" deactivated.'),
      success: error == null,
    );
  }

  void _onAssignPermissions(RoleData role) {
    setState(() {
      _assignRoleId = role.id;
      _assignRoleName = role.name;
      _mainTab = _MainTab.assignPermissions;
    });
  }

  void _onGoToRolesTab() {
    setState(() => _mainTab = _MainTab.roles);
  }

  void _onPermissionsSaved(String message, bool success) {
    _showToast(message, success: success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolesNotifierProvider);
    final onRolesTab = _mainTab == _MainTab.roles;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              if (onRolesTab) ...[
                _buildControls(state),
                _buildRolesSection(state),
              ] else
                _buildAssignPermissionsSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ASSIGN PERMISSIONS (tab content — same page/shell, not a separate route)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAssignPermissionsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: AssignPermissionsSection(
          roleId: _assignRoleId,
          roleName: _assignRoleName,
          onBackToRoles: _onGoToRolesTab,
          onSaved: _onPermissionsSaved,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.cardBackground,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with accent
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F1222), // ink-1
                  height: 1.15,
                ),
                children: [
                  TextSpan(text: 'Role '),
                  TextSpan(
                    text: 'Permission',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF6D4AFF), // purple
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Description
            const Text(
              'Define roles and control which pages each role can access',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9197AE), // ink-3
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Module-level nav ("Roles" / "Login Permission") is now shown once,
  // globally, by `GlobalAppShell`'s shared `ModuleSubNav`. "Assign
  // Permissions" remains an in-page workflow state (see [_onAssignPermissions],
  // [_onGoToRolesTab]) reached from a role card's action, not from a tab —
  // matching web's own equivalent flow (`router.push('/roles/assign-
  // permission?roleId=...')`).

  // ══════════════════════════════════════════════════════════════════════════
  // CONTROLS (Search, Filter, Add Button)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildControls(RolesScreenState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          children: [
            // First row: Active filter + Search
            Row(
              children: [
                // Show inactive toggle
                _buildActiveFilterButton(state),
                const SizedBox(width: 8),

                // Search box
                Expanded(child: _buildSearchBox(state)),
              ],
            ),
            const SizedBox(height: 12),

            // Second row: Add button (full width)
            SizedBox(width: double.infinity, child: _buildAddRoleButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterButton(RolesScreenState state) {
    return GestureDetector(
      onTap: () => ref.read(rolesNotifierProvider.notifier).toggleShowInactive(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: state.showInactive
              ? AppColors.dashboardPurple.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          border: Border.all(
            color: state.showInactive
                ? AppColors.dashboardPurple
                : AppColors.cardBorder,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.showInactive ? Icons.circle : Icons.circle_outlined,
              size: 14,
              color: state.showInactive
                  ? AppColors.dashboardPurple
                  : AppColors.labelTextMuted,
            ),
            const SizedBox(width: 6),
            Text(
              state.showInactive ? 'Showing all' : 'Active only',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: state.showInactive
                    ? AppColors.dashboardPurple
                    : AppColors.labelTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(RolesScreenState state) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(
              Icons.search_rounded,
              size: 16,
              color: AppColors.labelTextMuted,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F1222)),
              decoration: const InputDecoration(
                hintText: 'Search roles…',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.labelTextMuted,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (state.searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.labelTextMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddRoleButton() {
    return GestureDetector(
      onTap: _onAddRole,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.dashboardPurple,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '+ New Role',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ROLES SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRolesSection(RolesScreenState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.onBackground.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Text(
                'ALL ROLES${!state.loading ? ' · ${state.totalCount} defined' : ''}'
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelTextMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 14),

              // Roles grid / loading / error
              if (state.loading)
                _buildLoadingGrid()
              else if (state.error != null)
                _buildErrorBlock(state.error!)
              else
                _buildRolesGrid(state),

              const SizedBox(height: 12),

              // Bottom info bar
              _buildInfoBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
          ),
          itemCount: 8,
          itemBuilder: (context, index) => const RoleCardSkeleton(),
        );
      },
    );
  }

  Widget _buildErrorBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: AppColors.labelTextMuted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.labelTextMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(rolesNotifierProvider.notifier).refresh(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dashboardPurple,
              side: BorderSide(color: AppColors.dashboardPurple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesGrid(RolesScreenState state) {
    if (state.roles.isEmpty && state.searchQuery.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.labelTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No roles found matching "${state.searchQuery}"',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.labelTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: const Center(
          child: Text(
            'No roles found. Create your first role.',
            style: TextStyle(fontSize: 13, color: AppColors.labelTextMuted),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final itemCount = state.roles.length + 1; // +1 for Add New Role card

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Last item is Add New Role card
            if (index == state.roles.length) {
              return AddRoleCard(onTap: _onAddRole);
            }

            final role = state.roles[index];
            return RoleCard(
              role: role,
              isSelected: state.selectedRoleId == role.id,
              isMutating: state.mutatingIds.contains(role.id),
              onTap: () =>
                  ref.read(rolesNotifierProvider.notifier).selectRole(role.id),
              onEdit: () => _onEditRole(role),
              onDelete: role.isSystem ? null : () => _onDeleteRole(role),
              onToggleActive: () => _onToggleActive(role),
              onAssignPermissions: () => _onAssignPermissions(role),
            );
          },
        );
      },
    );
  }

  /// Calculate responsive grid column count based on screen width
  int _calculateCrossAxisCount(double width) {
    if (width < 400) {
      return 1; // Very small phones
    } else if (width < 600) {
      return 2; // Small phones
    } else if (width < 900) {
      return 3; // Medium phones/tablets
    } else {
      return 4; // Large tablets
    }
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), // bg-2
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF5A607A), // ink-2
          ),
          children: [
            TextSpan(text: 'Tap any card → '),
            TextSpan(
              text: '🔑 assign permissions',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F1222), // ink-1
              ),
            ),
            TextSpan(text: ' · '),
            TextSpan(
              text: '✏ edit',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F1222),
              ),
            ),
            TextSpan(text: ' · '),
            TextSpan(
              text: '🗑 delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F1222),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
