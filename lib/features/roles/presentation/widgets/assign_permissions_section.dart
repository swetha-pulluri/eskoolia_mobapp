import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/permission_tree.dart';
import '../../domain/models/role_data.dart';
import '../../domain/models/sub_feature_row.dart';
import '../providers/roles_providers.dart';
import 'assign_permission_dialogs.dart';
import 'role_create_dialog.dart';
import 'role_delete_confirm_dialog.dart';
import 'role_edit_dialog.dart';

/// Assign Permissions content — mirrors frontend
/// components/access-control/AssignPermissionPanel.tsx as closely as
/// reasonably possible on a phone screen. This is the tab content shown by
/// RolesPermissionsPage (not a separate route), matching that page's shared
/// breadcrumb/tab shell.
///
/// Scope note (the one deliberate deviation from a fully literal port):
/// the frontend gates an inline create-role form (inside the Active Role
/// card) and a separate "Create New Role" modal behind the exact same
/// `showNewRoleForm` flag, so both would render at once — an apparent
/// leftover from an in-progress refactor (a `// TODO(create-role): restore
/// these props` comment sits right next to it), not a deliberate two-form
/// design. Only the complete, validated modal (`RoleCreateDialog`) is
/// implemented here, both for the "＋ New" button and the role picker's
/// "＋ Create New Role" tile.
class AssignPermissionsSection extends ConsumerStatefulWidget {
  final int? roleId;
  final String? roleName;
  final VoidCallback onBackToRoles;
  final void Function(String message, bool success) onSaved;

  const AssignPermissionsSection({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.onBackToRoles,
    required this.onSaved,
  });

  @override
  ConsumerState<AssignPermissionsSection> createState() =>
      _AssignPermissionsSectionState();
}

class _AssignPermissionsSectionState
    extends ConsumerState<AssignPermissionsSection> {
  bool _loading = true;
  String? _error;
  bool _saving = false;
  bool _saveSuccess = false;
  // Kept separate from _error: _error also decides whether the module
  // list/config panel are replaced by the tree-load retry screen (see
  // _buildTreeErrorBlock), and doSave() must never hide that editor —
  // mirrors frontend doSave() reusing the same top-level `error` state as
  // permission-tree loading but where THAT screen never re-checks `error`
  // to decide whether to render the module layout, only `loading`.
  String? _saveError;

  int? _activeRoleId;
  String? _activeRoleName;

  PermissionTree? _tree;
  Set<int> _selectedIds = {};
  Set<String> _enabledModules = {};
  Map<String, OperationLevel> _operationLevels = {};
  String? _activeModule;

  List<RoleData> _allRoles = [];
  bool _showRoleSwitcher = false;
  Set<int> _togglingRoleIds = {};

  // Owns the Module Access list's internal scroll — kept separate from the
  // Scrollbar's own auto-attach so it can't accidentally latch onto the
  // outer page scroll view instead (the module list is nested inside it).
  final ScrollController _moduleListScrollController = ScrollController();

  @override
  void dispose() {
    _moduleListScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _activeRoleId = widget.roleId;
    _activeRoleName = widget.roleName;
    _loadAllRoles();
    if (_activeRoleId != null) _loadTree();
  }

  @override
  void didUpdateWidget(AssignPermissionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different role was selected from outside (e.g. tapping another
    // card's 🔑 icon while this section is already showing).
    if (widget.roleId != null && widget.roleId != oldWidget.roleId) {
      setState(() {
        _activeRoleId = widget.roleId;
        _activeRoleName = widget.roleName;
        _showRoleSwitcher = false;
      });
      _loadTree();
    }
  }

  Future<void> _loadAllRoles() async {
    try {
      final page = await ref
          .read(roleRepositoryProvider)
          .fetchRoles(showInactive: true, pageSize: 200);
      if (!mounted) return;
      setState(() => _allRoles = page.results);
    } catch (_) {
      // Non-critical — the switcher just stays empty; the main permission
      // load has its own error handling.
    }
  }

  Future<void> _loadTree() async {
    final roleId = _activeRoleId;
    if (roleId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _saveError = null;
      _tree = null;
    });
    try {
      final tree = await ref
          .read(roleRepositoryProvider)
          .fetchPermissionTree(roleId);
      if (!mounted) return;
      final selected = <int>{};
      final enabled = <String>{};
      for (final module in tree.modules) {
        final hasSelected = module.permissions.any((p) => p.selected);
        if (hasSelected) {
          enabled.add(module.module);
          for (final perm in module.permissions) {
            if (perm.selected) selected.add(perm.id);
          }
        }
      }
      final levels = <String, OperationLevel>{};
      for (final module in tree.modules) {
        if (enabled.contains(module.module)) {
          levels[module.module] = inferOperationLevel(
            module.permissions,
            selected,
          );
        }
      }
      final firstEnabled = tree.modules
          .where((m) => enabled.contains(m.module))
          .firstOrNull;
      setState(() {
        _tree = tree;
        _selectedIds = selected;
        _enabledModules = enabled;
        _operationLevels = levels;
        _activeModule = firstEnabled?.module ?? tree.modules.firstOrNull?.module;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _switchRole(RoleData role) {
    setState(() {
      _activeRoleId = role.id;
      _activeRoleName = role.name;
      _showRoleSwitcher = false;
    });
    _loadTree();
  }

  Future<void> _onCreateRole() async {
    final created = await RoleCreateDialog.show(context);
    if (created == null || !mounted) return;
    setState(() => _allRoles = [..._allRoles, created]);
    widget.onSaved('Role "${created.name}" created successfully.', true);
    _switchRole(created);
  }

  Future<void> _onEditRoleFromPicker(RoleData role) async {
    final updated = await RoleEditDialog.show(context, role: role);
    if (updated == null || !mounted) return;
    setState(() {
      _allRoles = _allRoles.map((r) => r.id == updated.id ? updated : r).toList();
      if (_activeRoleId == updated.id) _activeRoleName = updated.name;
    });
    widget.onSaved('Role "${updated.name}" updated successfully.', true);
  }

  Future<void> _onDeleteRoleFromPicker(RoleData role) async {
    final confirmed = await showRoleDeleteConfirmDialog(context, roleName: role.name);
    if (!confirmed || !mounted) return;
    try {
      await ref.read(roleRepositoryProvider).deleteRole(role.id);
      if (!mounted) return;
      setState(() {
        _allRoles = _allRoles.where((r) => r.id != role.id).toList();
        if (_activeRoleId == role.id) {
          _activeRoleId = null;
          _activeRoleName = null;
          _tree = null;
        }
      });
      widget.onSaved('Role "${role.name}" deleted.', true);
    } catch (e) {
      if (!mounted) return;
      widget.onSaved(e.toString().replaceFirst('Exception: ', ''), false);
    }
  }

  Future<void> _onToggleRoleActiveFromPicker(RoleData role) async {
    setState(() => _togglingRoleIds = {..._togglingRoleIds, role.id});
    try {
      final updated = await ref
          .read(roleRepositoryProvider)
          .setActive(role.id, !role.isActive);
      if (!mounted) return;
      setState(() {
        _allRoles = _allRoles.map((r) => r.id == updated.id ? updated : r).toList();
        _togglingRoleIds = {..._togglingRoleIds}..remove(role.id);
      });
      widget.onSaved(
        updated.isActive
            ? '"${updated.name}" activated successfully.'
            : '"${updated.name}" deactivated successfully.',
        true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _togglingRoleIds = {..._togglingRoleIds}..remove(role.id));
      widget.onSaved(e.toString().replaceFirst('Exception: ', ''), false);
    }
  }

  void _toggleModule(PermissionModule module) {
    setState(() {
      if (_enabledModules.contains(module.module)) {
        _enabledModules = {..._enabledModules}..remove(module.module);
        _selectedIds = {..._selectedIds}
          ..removeWhere((id) => module.permissions.any((p) => p.id == id));
        _operationLevels = {..._operationLevels, module.module: OperationLevel.none};
        if (_activeModule == module.module) {
          // Keep it selected so the config panel still shows its (now
          // disabled) empty state rather than jumping to another module.
        }
      } else {
        _enabledModules = {..._enabledModules, module.module};
        _selectedIds = applyOperationLevel(
          module,
          OperationLevel.view,
          _selectedIds,
        );
        _operationLevels = {..._operationLevels, module.module: OperationLevel.view};
        _activeModule = module.module;
      }
    });
  }

  void _selectModule(String moduleKey) {
    setState(() => _activeModule = moduleKey);
  }

  /// Applies an operation-level preset. Full Control is intercepted when the
  /// module has a delete permission, so the admin explicitly confirms
  /// whether to include it — mirrors frontend handleOperationChange().
  Future<void> _handleOperationChange(
    PermissionModule module,
    OperationLevel level,
  ) async {
    if (level == OperationLevel.full) {
      final hasDelete = groupPermsBySubFeature(module.permissions).any((r) => r.delete != null);
      if (hasDelete) {
        final includeDelete = await showFullControlDialog(
          context,
          moduleName: prettyModuleName(module.module),
        );
        if (includeDelete == null || !mounted) return; // cancelled
        _applyLevel(module, OperationLevel.full, includeDelete: includeDelete);
        return;
      }
    }
    _applyLevel(module, level);
  }

  void _applyLevel(PermissionModule module, OperationLevel level, {bool includeDelete = true}) {
    final finalLevel = (!includeDelete && level == OperationLevel.full)
        ? OperationLevel.createEdit
        : level;
    setState(() {
      _operationLevels = {..._operationLevels, module.module: finalLevel};
      _selectedIds = applyOperationLevel(
        module,
        level,
        _selectedIds,
        includeDelete: includeDelete,
      );
    });
  }

  /// Toggling ON a delete-type permission requires explicit confirmation —
  /// mirrors frontend handlePermissionToggle().
  Future<void> _handlePermissionToggle(PermissionModule module, int permId) async {
    final perm = module.permissions.where((p) => p.id == permId).firstOrNull;
    if (perm == null) return;
    final adding = !_selectedIds.contains(permId);
    final rows = groupPermsBySubFeature(module.permissions);
    final ownerRow = rows.where((r) => r.delete?.id == permId).firstOrNull;

    if (adding && ownerRow != null) {
      final confirmed = await showDeleteConfirmDialog(
        context,
        permCode: perm.code,
        featureLabel: ownerRow.label,
      );
      if (!confirmed || !mounted) return;
      setState(() {
        final next = {..._selectedIds, permId};
        _selectedIds = next;
        _operationLevels = {
          ..._operationLevels,
          module.module: inferOperationLevel(module.permissions, next),
        };
      });
      return;
    }

    setState(() {
      final next = {..._selectedIds};
      if (next.contains(permId)) {
        next.remove(permId);
      } else {
        next.add(permId);
      }
      _selectedIds = next;
      _operationLevels = {
        ..._operationLevels,
        module.module: inferOperationLevel(module.permissions, next),
      };
    });
  }

  /// Save button entry point — shows the Review Permissions summary, then a
  /// sensitive-module confirmation if applicable, before actually saving.
  /// Mirrors frontend handleSaveClick() → handleReviewConfirm() → doSave().
  Future<void> _handleSaveClick() async {
    final tree = _tree;
    if (tree == null) return;
    final confirmed = await showReviewPermissionsDialog(
      context,
      modules: tree.modules,
      enabledModules: _enabledModules,
      operationLevels: _operationLevels,
      selectedIds: _selectedIds,
    );
    if (!confirmed || !mounted) return;

    final risky = _enabledModules.where((m) => riskyModules.contains(m)).toList();
    if (risky.isNotEmpty) {
      final proceed = await showRiskyConfirmDialog(
        context,
        riskyModuleLabels: risky.map(prettyModuleName).toList(),
      );
      if (!proceed) return;
    }
    await _doSave();
  }

  /// Mirrors frontend doSave() exactly: on failure it sets an inline banner
  /// (not a toast), and on success it shows only the "✓ Saved" pill, with
  /// no toast either. Neither branch calls widget.onSaved(); that callback
  /// is reserved for role CRUD actions (create/edit/delete/activate),
  /// matching the frontend's separate `toast` state, which doSave() never
  /// touches.
  Future<void> _doSave() async {
    final roleId = _activeRoleId;
    if (roleId == null) return;
    setState(() {
      _saving = true;
      _saveSuccess = false;
      _saveError = null;
    });
    try {
      await ref
          .read(roleRepositoryProvider)
          .assignPermissions(roleId, _selectedIds.toList());
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveSuccess = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _saveSuccess = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRole = _activeRoleId != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHead(hasRole),
          if (_error != null && hasRole && !_loading) ...[
            const SizedBox(height: 12),
            _buildErrorFlash(_error!),
          ],
          if (_saveError != null && hasRole && !_loading) ...[
            const SizedBox(height: 12),
            _buildErrorFlash(_saveError!),
          ],
          const SizedBox(height: 12),
          if (!hasRole)
            _buildRolePickerGrid()
          else ...[
            _buildStatsGrid(),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildTreeErrorBlock(_error!)
            else
              _buildModuleLayout(),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE HEAD
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPageHead(bool hasRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          _buildTitle(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasRole && _saveSuccess) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✓ Saved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (hasRole)
                ElevatedButton(
                  onPressed: _saving ? null : _handleSaveClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4FCF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFF5B4FCF,
                    ).withValues(alpha: 0.55),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _saving
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Saving…'),
                          ],
                        )
                      : const Text('Save Permissions'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final roleName = _activeRoleName;
    return RichText(
      text: TextSpan(
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.4,
          color: const Color(0xFF0F172A),
        ),
        children: [
          const TextSpan(text: 'Roles & '),
          TextSpan(
            text: 'Assign Permissions',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6C3CE1),
            ),
          ),
          if (roleName != null)
            TextSpan(
              text: ' — $roleName',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF15172A),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorFlash(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// No role selected — mirrors frontend's inline role picker (the
  /// `!activeRoleId` branch of AssignPermissionPanel.tsx): a grid of role
  /// cards (tap to configure permissions, edit/delete actions, an
  /// active/inactive toggle) plus a "＋ Create New Role" tile.
  Widget _buildRolePickerGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a role to configure its permissions, or create a new one.',
          style: TextStyle(fontSize: 13, color: Color(0xFF9A9DB0)),
        ),
        const SizedBox(height: 16),
        if (_allRoles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Loading roles…',
                style: TextStyle(fontSize: 14, color: Color(0xFF9A9DB0)),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = (constraints.maxWidth / 220).floor().clamp(1, 4);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 158,
                ),
                itemCount: _allRoles.length + 1,
                itemBuilder: (context, index) {
                  if (index == _allRoles.length) {
                    return _buildCreateRoleTile();
                  }
                  final role = _allRoles[index];
                  return _RolePickerCard(
                    role: role,
                    isToggling: _togglingRoleIds.contains(role.id),
                    onConfigure: () => _switchRole(role),
                    onEdit: () => _onEditRoleFromPicker(role),
                    onDelete: () => _onDeleteRoleFromPicker(role),
                    onToggleActive: () => _onToggleRoleActiveFromPicker(role),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildCreateRoleTile() {
    return InkWell(
      onTap: _onCreateRole,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          border: Border.all(color: const Color(0xFFC4BBFF), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '＋ Create New Role',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF6D4AFF),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Set up a role then configure its permissions',
              style: TextStyle(fontSize: 12, color: Color(0xFF9A9DB0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeErrorBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
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
            onPressed: _loadTree,
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

  // ══════════════════════════════════════════════════════════════════════
  // STATS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildStatsGrid() {
    final tree = _tree;
    final totalModules = tree?.modules.length ?? 0;
    final totalPermissions =
        tree?.modules.fold<int>(0, (s, m) => s + m.permissions.length) ?? 0;
    final modulesEnabled = _enabledModules.length;
    final modulesConfigured = _enabledModules
        .where((m) => (_operationLevels[m] ?? OperationLevel.none) != OperationLevel.none)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Frontend's own breakpoints go to a single column below 480px, but
        // that's a desktop-viewport threshold most phones never clear —
        // per the Mobile UI Guidelines ("place related cards side by side
        // whenever screen width allows"), phones use the frontend's own
        // 2-column state (already how it renders at 480-768px) instead of
        // stacking all three cards full-width. True 1-column only applies
        // below the width a compact card can no longer fit two-up. A fixed
        // mainAxisExtent (not an aspect ratio) keeps card height constant
        // regardless of column width, and the card's own text is bounded to
        // a fixed number of lines — together these guarantee no overflow at
        // any of these widths, instead of depending on width-based math.
        final crossAxisCount = width < 280 ? 1 : (width < 640 ? 2 : 3);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 130,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildStatCard(
                  label: 'MODULES ENABLED',
                  value: '$modulesEnabled',
                  valueSuffix: ' / $totalModules',
                  hint: 'modules active for this role',
                );
              case 1:
                return _buildStatCard(
                  label: 'PERMISSIONS ASSIGNED',
                  value: '${_selectedIds.length}',
                  hint: 'out of $totalPermissions total',
                );
              default:
                return _buildStatCard(
                  label: 'FULLY CONFIGURED',
                  value: '$modulesConfigured',
                  hint: 'modules with operation level set',
                );
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    String? valueSuffix,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF72758B),
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 34,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
                color: const Color(0xFF10122B),
                height: 1,
              ),
              children: [
                TextSpan(text: value),
                if (valueSuffix != null)
                  TextSpan(
                    text: valueSuffix,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF72758B),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF72758B)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // MODULE LAYOUT (list + config panel — stacked on phone widths, matching
  // the frontend's own <768px breakpoint which switches to column layout)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildModuleLayout() {
    return Column(
      children: [
        _buildModuleListCard(),
        const SizedBox(height: 10),
        _buildModuleConfigCard(),
      ],
    );
  }

  Widget _buildModuleListCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8EE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleCardHeader(),
          if (_showRoleSwitcher) _buildRoleSwitcherList(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5FB),
              border: Border(bottom: BorderSide(color: Color(0xFFE8E8EE))),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module Access',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF15172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Toggle to enable modules for this role',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9A9DB0)),
                ),
              ],
            ),
          ),
          _buildModuleRowsList(),
        ],
      ),
    );
  }

  /// Bounded, internally-scrolling module list with a visible scrollbar —
  /// mirrors the frontend's module-rows `div` (`overflowY: "auto", maxHeight:
  /// "calc(100vh - 440px)"`), which caps the row list to a few visible rows
  /// rather than letting it grow with the page. The 100vh-relative formula
  /// is a desktop-only value (it assumes ModuleList and ModuleConfigPanel
  /// sit side-by-side, so nothing else pushes it down) — on the stacked
  /// mobile layout that same subtraction doesn't apply, so the height here
  /// is instead proportional to the phone's own screen height, clamped so
  /// small phones still get a couple of visible rows and large phones don't
  /// get a panel that dominates the screen.
  Widget _buildModuleRowsList() {
    final modules = _tree?.modules ?? const <PermissionModule>[];
    final screenHeight = MediaQuery.of(context).size.height;
    final listHeight = (screenHeight * 0.28).clamp(200.0, 300.0);

    return SizedBox(
      height: listHeight,
      child: Scrollbar(
        controller: _moduleListScrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _moduleListScrollController,
          padding: EdgeInsets.zero,
          itemCount: modules.length,
          itemBuilder: (context, index) => _buildModuleRow(modules[index]),
        ),
      ),
    );
  }

  Widget _buildRoleCardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE9FF), Color(0xFFF5F5FB)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8EE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE ROLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Color(0xFF6D4AFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _activeRoleName ?? '…',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF15172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRoleHeaderButton(
                label: 'Switch ⇅',
                active: _showRoleSwitcher,
                onTap: () => setState(() => _showRoleSwitcher = !_showRoleSwitcher),
              ),
              const SizedBox(width: 6),
              _buildRoleHeaderButton(
                label: '＋ New',
                active: false,
                onTap: _onCreateRole,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleHeaderButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6D4AFF) : Colors.white,
          border: Border.all(color: const Color(0xFFC4BBFF), width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF6D4AFF),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitcherList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD8D4FF))),
      ),
      child: _allRoles.isEmpty
          ? const Text(
              'No other roles found',
              style: TextStyle(fontSize: 12, color: Color(0xFF9A9DB0)),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _allRoles.length,
              itemBuilder: (context, index) {
                final role = _allRoles[index];
                final isActive = role.id == _activeRoleId;
                return InkWell(
                  onTap: () => _switchRole(role),
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFEEEAFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF6D4AFF)
                                : const Color(0xFFC4C4C4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            role.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: const Color(0xFF15172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildModuleRow(PermissionModule module) {
    final isEnabled = _enabledModules.contains(module.module);
    final isActive = _activeModule == module.module;
    final level = _operationLevels[module.module] ?? OperationLevel.none;
    final permCount = module.permissions.length;
    final selectedCount =
        module.permissions.where((p) => _selectedIds.contains(p.id)).length;
    final isRisky = riskyModules.contains(module.module);

    return InkWell(
      onTap: isEnabled ? () => _selectModule(module.module) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: Color(0xFFE8E8EE)),
            left: BorderSide(
              color: isActive ? const Color(0xFF6D4AFF) : Colors.transparent,
              width: 4,
            ),
          ),
          color: isActive
              ? const Color(0xFFEEEAFF)
              : isEnabled
              ? Colors.white
              : const Color(0xFFFAFAFB),
        ),
        child: Row(
          children: [
            _buildModuleSwitch(
              isEnabled,
              () => _toggleModule(module),
              key: ValueKey('module-switch-${module.module}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          prettyModuleName(module.module),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isEnabled
                                ? const Color(0xFF15172A)
                                : const Color(0xFF9A9DB0),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRisky) ...[
                        const SizedBox(width: 5),
                        const Text('⚠️', style: TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isEnabled && level != OperationLevel.none
                        ? '${level.label} · $selectedCount/$permCount'
                        : '$permCount available',
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled
                          ? const Color(0xFF6D4AFF)
                          : const Color(0xFFC4C4C4),
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isActive
                    ? const Color(0xFF6D4AFF)
                    : const Color(0xFFC4C4C4),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSwitch(bool value, VoidCallback onTap, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 20,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF6D4AFF) : const Color(0xFFE8E8EE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // MODULE CONFIG PANEL
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildModuleConfigCard() {
    final tree = _tree;
    final activeModule = tree?.modules
        .where((m) => m.module == _activeModule)
        .firstOrNull;

    if (activeModule == null || !_enabledModules.contains(activeModule.module)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8EE)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🔒', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enable a module to configure it',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF15172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toggle the switch next to any module above to activate it, then choose its access level here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9A9DB0)),
            ),
          ],
        ),
      );
    }

    final level = _operationLevels[activeModule.module] ?? OperationLevel.none;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8EE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5FB),
              border: Border(bottom: BorderSide(color: Color(0xFFE8E8EE))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prettyModuleName(activeModule.module),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF15172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activeModule.permissions.length} permissions · Configure access level below',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9A9DB0)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OPERATION LEVEL',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.7,
                    color: Color(0xFF5B5E72),
                  ),
                ),
                const SizedBox(height: 10),
                _buildOperationLevelOptions(activeModule, level),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE8E8EE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAGE-LEVEL ACCESS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.7,
                    color: Color(0xFF5B5E72),
                  ),
                ),
                const SizedBox(height: 10),
                _buildPermissionsTable(activeModule),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationLevelOptions(
    PermissionModule module,
    OperationLevel current,
  ) {
    const options = [
      (
        OperationLevel.view,
        'View Only',
        'Can read data but not make changes',
      ),
      (
        OperationLevel.createEdit,
        'Create & Edit',
        'Can add new records and edit existing ones',
      ),
      (
        OperationLevel.full,
        'Full Control',
        'Can view, create, edit and delete',
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final (optLevel, label, description) = opt;
        final isSelected = current == optLevel;
        return SizedBox(
          width: 160,
          child: InkWell(
            onTap: () => _handleOperationChange(module, optLevel),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEEAFF) : const Color(0xFFFAFAFB),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6D4AFF)
                      : const Color(0xFFE8E8EE),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isSelected ? '● ' : '○ '}$label',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF6D4AFF)
                          : const Color(0xFF15172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A9DB0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionsTable(PermissionModule module) {
    final rows = groupPermsBySubFeature(module.permissions);
    const featureColWidth = 160.0;
    const actionColWidth = 72.0;
    final tableWidth = featureColWidth + actionColWidth * 4;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5FB),
                border: Border(bottom: BorderSide(color: Color(0xFFE8E8EE), width: 2)),
              ),
              child: Row(
                children: [
                  _tableHeaderCell('FEATURE / PAGE', featureColWidth, alignLeft: true),
                  _tableHeaderCell('VIEW', actionColWidth),
                  _tableHeaderCell('ADD', actionColWidth),
                  _tableHeaderCell('EDIT', actionColWidth),
                  _tableHeaderCell(
                    'DELETE',
                    actionColWidth,
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: tableWidth,
                    child: const Text(
                      'No sub-features found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF9A9DB0)),
                    ),
                  ),
                ),
              )
            else
              for (final row in rows) _buildTableRow(module, row, featureColWidth, actionColWidth),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(
    String label,
    double width, {
    bool alignLeft = false,
    Color color = const Color(0xFF5B5E72),
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(
    PermissionModule module,
    SubFeatureRow row,
    double featureColWidth,
    double actionColWidth,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F6))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: featureColWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Text(
                row.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF15172A),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _buildPermCell(module, row.view, actionColWidth, isDelete: false),
          _buildPermCell(module, row.add, actionColWidth, isDelete: false),
          _buildPermCell(module, row.edit, actionColWidth, isDelete: false),
          _buildPermCell(module, row.delete, actionColWidth, isDelete: true),
        ],
      ),
    );
  }

  Widget _buildPermCell(
    PermissionModule module,
    PermissionNode? perm,
    double width, {
    required bool isDelete,
  }) {
    if (perm == null) {
      return SizedBox(
        width: width,
        child: const Center(
          child: Text('—', style: TextStyle(color: Color(0xFFE8E8EE))),
        ),
      );
    }
    final isChecked = _selectedIds.contains(perm.id);
    final activeColor = isDelete ? const Color(0xFFDC2626) : const Color(0xFF6D4AFF);
    return SizedBox(
      width: width,
      child: Center(
        child: InkWell(
          onTap: () => _handlePermissionToggle(module, perm.id),
          borderRadius: BorderRadius.circular(5),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isChecked ? activeColor : const Color(0xFFFAFAFB),
              border: Border.all(
                color: isChecked ? activeColor : const Color(0xFFE8E8EE),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: isChecked
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// One card in the role picker grid — mirrors frontend's inline role card
/// (the `!activeRoleId` branch of AssignPermissionPanel.tsx): status dot +
/// name, "Configure permissions →" link, edit/delete icons, and an
/// active/inactive toggle.
///
/// The frontend only reveals the edit/delete icons on hover. Touch devices
/// have no hover at all, and tapping this card's body already navigates
/// (configures permissions) rather than merely "selecting" it the way the
/// Roles-tab grid's own RoleCard does — so there's no spare gesture left to
/// borrow for a reveal step. They're shown permanently instead, which is the
/// direct mobile equivalent for a platform where hover doesn't exist,
/// consistent with RoleCard's own precedent of adapting hover-only frontend
/// affordances to touch.
class _RolePickerCard extends StatelessWidget {
  final RoleData role;
  final bool isToggling;
  final VoidCallback onConfigure;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _RolePickerCard({
    required this.role,
    required this.isToggling,
    required this.onConfigure,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = role.isActive;
    return Opacity(
      opacity: isActive ? 1 : 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFFF9F9FC),
          border: Border.all(
            color: isActive ? const Color(0xFFE8E8EE) : const Color(0xFFECEEF5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: onConfigure,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 58, top: 2, bottom: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF6D4AFF)
                                    : const Color(0xFF9CA3AF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                role.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF15172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            'Configure permissions →',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6D4AFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconButton(
                        icon: Icons.edit_rounded,
                        color: const Color(0xFF6D4AFF),
                        background: Colors.white,
                        borderColor: const Color(0xFFE8E8EE),
                        tooltip: 'Edit role',
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 4),
                      _iconButton(
                        icon: Icons.delete_rounded,
                        color: const Color(0xFFDC2626),
                        background: const Color(0xFFFFF5F5),
                        borderColor: const Color(0xFFFEE2E2),
                        tooltip: 'Delete role',
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0xFFF0F0F5)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    _buildActiveToggle(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required Color background,
    required Color borderColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
      ),
    );
  }

  Widget _buildActiveToggle() {
    final isActive = role.isActive;
    final disabled = role.isSystem || isToggling;
    return Tooltip(
      message: role.isSystem
          ? 'System roles cannot be deactivated'
          : (isActive ? 'Deactivate role' : 'Activate role'),
      child: GestureDetector(
        onTap: disabled ? null : onToggleActive,
        child: Opacity(
          opacity: isToggling ? 0.55 : (role.isSystem ? 0.35 : 1),
          child: Container(
            width: 36,
            height: 20,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
