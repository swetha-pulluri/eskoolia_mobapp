import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/role_data.dart';

/// Role Card Widget
/// Pixel-perfect recreation of frontend role card
/// Source: frontend/components/access-control/RoleManagementPanel.tsx - role card div
///
/// Displays role information with:
/// - Deterministic color icon (first letter)
/// - Role name
/// - Portal badge (Admin/Teacher/Parent/Student/Custom) — hidden if unknown
/// - System/Custom label
/// - Inactive overlay badge (if not active)
/// - Hover-reveal action icons (Assign Permissions/Edit/Activate-Deactivate/
///   Delete), matching the frontend's `.role-hover-actions` exactly. Since
///   touch devices have no hover, tapping the card (which already selects it)
///   also reveals the icons — the frontend's mouse-only interaction adapted
///   to the platforms this app actually runs on.
class RoleCard extends StatefulWidget {
  final RoleData role;
  final bool isSelected;
  final bool isMutating;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;
  final VoidCallback? onAssignPermissions;

  const RoleCard({
    super.key,
    required this.role,
    this.isSelected = false,
    this.isMutating = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.onAssignPermissions,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _isHovered = false;

  RoleData get role => widget.role;

  /// Get deterministic background color for role based on name
  /// Matches frontend getRoleColor() function
  Color _getRoleColor() {
    int hash = 0;
    for (int i = 0; i < role.name.length; i++) {
      hash = role.name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return AppColors.roleCardBackgrounds[hash.abs() %
        AppColors.roleCardBackgrounds.length];
  }

  /// Get portal badge colors based on portal type
  (Color bg, Color text) _getPortalColors(PortalType type) {
    switch (type) {
      case PortalType.admin:
        return (AppColors.portalAdminBg, AppColors.portalAdminText);
      case PortalType.teacher:
        return (AppColors.portalTeacherBg, AppColors.portalTeacherText);
      case PortalType.parent:
        return (AppColors.portalParentBg, AppColors.portalParentText);
      case PortalType.student:
        return (AppColors.portalStudentBg, AppColors.portalStudentText);
      case PortalType.custom:
        return (AppColors.portalCustomBg, AppColors.portalCustomText);
    }
  }

  bool get _showActions => _isHovered || widget.isSelected;

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();
    final portalType = role.portalType;

    final borderColor = widget.isSelected
        ? AppColors.roleCardSelectedBorder
        : _isHovered
        ? AppColors.roleCardHoverBorder
        : AppColors.roleCardBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.roleCardSelected
                : AppColors.cardBackground,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content
              Row(
                children: [
                  // Icon with first letter
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: roleColor.withValues(
                        alpha: role.isActive ? 1 : 0.45,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        role.name.isNotEmpty
                            ? role.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A607A), // ink-2
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name and badges
                  Expanded(
                    child: Opacity(
                      opacity: role.isActive ? 1 : 0.55,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Room for the hover-action icons so long names
                          // don't run underneath them.
                          Padding(
                            padding: const EdgeInsets.only(right: 100),
                            child: Text(
                              role.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F1222), // ink-1
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Portal badge (only if known) + System/Custom label
                          Row(
                            children: [
                              if (portalType != null) ...[
                                Builder(
                                  builder: (context) {
                                    final (portalBg, portalText) =
                                        _getPortalColors(portalType);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: portalBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        portalType.label.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: portalText,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                              ],

                              // System/Custom label
                              Text(
                                role.isSystem ? 'System' : 'Custom',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.labelTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Inactive overlay badge (top left)
              if (!role.isActive)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inactiveBadgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.inactiveBadgeText,
                      ),
                    ),
                  ),
                ),

              // Hover-reveal action icons (top right)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _showActions ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_showActions,
                    child: _buildActionRow(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onAssignPermissions != null)
          _actionIcon(
            icon: Icons.key_rounded,
            tooltip: 'Assign permissions',
            background: AppColors.roleActionAssignBg,
            foreground: AppColors.dashboardPurple,
            onTap: widget.onAssignPermissions,
          ),
        if (widget.onEdit != null) ...[
          const SizedBox(width: 4),
          _actionIcon(
            icon: Icons.edit_rounded,
            tooltip: 'Edit role',
            background: AppColors.roleActionEditBg,
            foreground: AppColors.dashboardPurple,
            onTap: widget.onEdit,
          ),
        ],
        if (widget.onToggleActive != null) ...[
          const SizedBox(width: 4),
          _actionIcon(
            icon: role.isActive
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            tooltip: role.isActive ? 'Deactivate role' : 'Activate role',
            background: role.isActive
                ? AppColors.roleActionDeactivateBg
                : AppColors.roleActionActivateBg,
            foreground: role.isActive
                ? AppColors.roleActionDeactivateText
                : AppColors.roleActionActivateText,
            onTap: widget.isMutating ? null : widget.onToggleActive,
          ),
        ],
        if (widget.onDelete != null && !role.isSystem) ...[
          const SizedBox(width: 4),
          _actionIcon(
            icon: Icons.delete_rounded,
            tooltip: 'Delete role',
            background: AppColors.roleActionDeleteBg,
            foreground: AppColors.error,
            onTap: widget.isMutating ? null : widget.onDelete,
          ),
        ],
      ],
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required String tooltip,
    required Color background,
    required Color foreground,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 12, color: foreground),
        ),
      ),
    );
  }
}

/// Role Card Skeleton for Loading State
class RoleCardSkeleton extends StatelessWidget {
  const RoleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
