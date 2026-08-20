import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/login_permission_user.dart';

/// Users data table — mirrors frontend components/login-permission/UsersTable.tsx.
///
/// Renders an actual table (header row + data rows), not a card list, so the
/// column layout matches the web source of truth exactly: User, Role /
/// Details, Email, Login Access, Last Login, Credentials. The table scrolls
/// horizontally on narrow phones so no column is clipped or hidden.
class LoginPermissionUsersTable extends StatelessWidget {
  final List<LoginPermissionUser> users;
  final Function(String, bool) onToggleAccess;
  final Function(LoginPermissionUser) onOpenCredentials;

  /// Selection is a controlled property (owned by the screen's notifier, not
  /// this widget) so the bulk action bar — which lives outside this table —
  /// can react to it too.
  final Set<String> selectedIds;
  final bool allOnPageSelected;
  final Function(String, bool) onSelectRow;
  final Function(bool) onSelectAllOnPage;

  const LoginPermissionUsersTable({
    super.key,
    required this.users,
    required this.onToggleAccess,
    required this.onOpenCredentials,
    required this.selectedIds,
    required this.allOnPageSelected,
    required this.onSelectRow,
    required this.onSelectAllOnPage,
  });

  static const double _checkboxColWidth = 44;
  static const double _userColWidth = 220;
  static const double _roleColWidth = 170;
  static const double _emailColWidth = 190;
  static const double _accessColWidth = 110;
  static const double _lastLoginColWidth = 130;
  static const double _credentialsColWidth = 96;
  static const double _cellPaddingH = 16;
  static const double _cellPaddingV = 12;

  static const Map<String, Color> _avatarColors = {
    'A': Color(0xFF3B5BDB), 'B': Color(0xFF7048E8), 'C': Color(0xFF0CA678),
    'D': Color(0xFFE8590C), 'E': Color(0xFFD6336C), 'F': Color(0xFF1971C2),
    'G': Color(0xFF2F9E44), 'H': Color(0xFFF76707), 'I': Color(0xFF862E9C),
    'J': Color(0xFF364FC7), 'K': Color(0xFF087F5B), 'L': Color(0xFFA61E4D),
    'M': Color(0xFFC92A2A), 'N': Color(0xFF5C7CFA), 'O': Color(0xFF74C0FC),
    'P': Color(0xFF38D9A9), 'Q': Color(0xFFE67700), 'R': Color(0xFF5F3DC4),
    'S': Color(0xFF1864AB), 'T': Color(0xFF099268), 'U': Color(0xFFD9480F),
    'V': Color(0xFF495057), 'W': Color(0xFF66A80F), 'X': Color(0xFF0B7285),
    'Y': Color(0xFF6741D9), 'Z': Color(0xFFE03131),
  };

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  Color _getAvatarColor(String name) {
    return _avatarColors[name.isNotEmpty ? name[0].toUpperCase() : 'A'] ??
        const Color(0xFF3B5BDB);
  }

  String _formatLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return 'Never';
    return DateFormat('d MMM yyyy').format(lastLogin);
  }

  double get _tableWidth =>
      _checkboxColWidth +
      _userColWidth +
      _roleColWidth +
      _emailColWidth +
      _accessColWidth +
      _lastLoginColWidth +
      _credentialsColWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: users.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderRow(),
                    for (final user in users) _buildDataRow(user),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No users match the current filters.',
              style: TextStyle(fontSize: 14, color: AppColors.inkTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          _headerCheckboxCell(),
          _headerCell('User', _userColWidth),
          _headerCell('Role / Details', _roleColWidth),
          _headerCell('Email', _emailColWidth),
          _headerCell(
            'Login Access',
            _accessColWidth,
            align: TextAlign.center,
          ),
          _headerCell('Last Login', _lastLoginColWidth),
          _headerCell(
            'Credentials',
            _credentialsColWidth,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _headerCheckboxCell() {
    return SizedBox(
      width: _checkboxColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: _buildCheckbox(
          value: allOnPageSelected,
          onChanged: (checked) => onSelectAllOnPage(checked ?? false),
        ),
      ),
    );
  }

  Widget _checkboxCell(LoginPermissionUser user) {
    return SizedBox(
      width: _checkboxColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: _buildCheckbox(
          value: selectedIds.contains(user.id),
          onChanged: (checked) => onSelectRow(user.id, checked ?? false),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.dashboardPurple,
      side: BorderSide(color: AppColors.cardBorder, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _headerCell(
    String label,
    double width, {
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(LoginPermissionUser user) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _checkboxCell(user),
          _userCell(user),
          _roleCell(user),
          _emailCell(user),
          _accessCell(user),
          _lastLoginCell(user),
          _credentialsCell(user),
        ],
      ),
    );
  }

  Widget _userCell(LoginPermissionUser user) {
    return SizedBox(
      width: _userColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getAvatarColor(user.name),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(user.name),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkPrimary,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.staffId,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkTertiary,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.mustChange) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Must change',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFA16207),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCell(LoginPermissionUser user) {
    return SizedBox(
      width: _roleColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: Text(
          user.role,
          style: TextStyle(fontSize: 13, color: AppColors.inkSecondary),
        ),
      ),
    );
  }

  Widget _emailCell(LoginPermissionUser user) {
    return SizedBox(
      width: _emailColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: Text(
          user.email,
          style: TextStyle(fontSize: 13, color: AppColors.inkSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _accessCell(LoginPermissionUser user) {
    return SizedBox(
      width: _accessColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _cellPaddingV),
        child: Center(
          child: Transform.scale(
            scale: 0.85,
            child: Switch(
              value: user.loginAccess,
              onChanged: (value) => onToggleAccess(user.id, value),
              activeThumbColor: const Color(0xFF10B981),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lastLoginCell(LoginPermissionUser user) {
    final isNever = user.lastLogin == null;
    return SizedBox(
      width: _lastLoginColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cellPaddingH,
          vertical: _cellPaddingV,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNever) ...[
              const Icon(
                Icons.access_time_rounded,
                size: 12,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                _formatLastLogin(user.lastLogin),
                style: TextStyle(
                  fontSize: isNever ? 12 : 13,
                  fontWeight: isNever ? FontWeight.w500 : FontWeight.normal,
                  color: isNever
                      ? const Color(0xFFD97706)
                      : AppColors.inkSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _credentialsCell(LoginPermissionUser user) {
    return SizedBox(
      width: _credentialsColWidth,
      child: Center(
        child: IconButton(
          onPressed: () => onOpenCredentials(user),
          tooltip: 'Manage credentials',
          icon: const Icon(Icons.key_rounded, size: 17),
          color: AppColors.dashboardPurple,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
