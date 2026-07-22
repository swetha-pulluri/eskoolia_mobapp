import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Floating bulk action bar — mirrors frontend
/// components/login-permission/BulkActionBar.tsx.
///
/// Shown only while one or more rows are selected. On the frontend it mounts
/// with a `fadeIn .15s ease` animation and unmounts instantly with none —
/// this widget plays the same one-shot fade-in on insertion; the caller is
/// responsible for removing it from the tree entirely once the selection is
/// cleared (matching the frontend's abrupt unmount), rather than animating it
/// away.
class LoginPermissionBulkActionBar extends StatefulWidget {
  final int selectedCount;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onReset;
  final VoidCallback onClose;

  const LoginPermissionBulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onEnable,
    required this.onDisable,
    required this.onReset,
    required this.onClose,
  });

  @override
  State<LoginPermissionBulkActionBar> createState() =>
      _LoginPermissionBulkActionBarState();
}

class _LoginPermissionBulkActionBarState
    extends State<LoginPermissionBulkActionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.ease);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // The full row (count + 3 actions + close) doesn't fit narrow
          // phone widths at natural size — scroll horizontally rather than
          // overflow, same pattern already used for the users table.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCountBadge(),
                _buildDivider(),
                _buildActionButton(
                  icon: Icons.done_all_rounded,
                  label: 'Enable All',
                  foreground: const Color(0xFF047857),
                  background: const Color(0xFFECFDF5),
                  onTap: widget.onEnable,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.remove_moderator_rounded,
                  label: 'Disable All',
                  foreground: const Color(0xFFDC2626),
                  background: const Color(0xFFFEF2F2),
                  onTap: widget.onDisable,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.key_rounded,
                  label: 'Reset Passwords',
                  foreground: const Color(0xFFB45309),
                  background: const Color(0xFFFFFBEB),
                  onTap: widget.onReset,
                ),
                _buildDivider(),
                _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.dashboardPurple,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${widget.selectedCount}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.cardBorder,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return InkWell(
      onTap: widget.onClose,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.close_rounded,
          size: 15,
          color: AppColors.inkTertiary,
        ),
      ),
    );
  }
}
