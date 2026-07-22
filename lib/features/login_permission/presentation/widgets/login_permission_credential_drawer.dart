import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/login_permission_user.dart';
import '../providers/login_permission_providers.dart';
import 'login_permission_set_initial_password_modal.dart';

/// Credential management drawer — mirrors frontend
/// components/login-permission/CredentialDrawer.tsx.
///
/// On the frontend this is a right-side slide-in drawer; on mobile it is
/// presented as a draggable bottom sheet. Surfaces dev login credentials
/// (mock mode), the user info card, and credential actions (reset password /
/// set initial password) with a one-time password backup display.
class LoginPermissionCredentialDrawer extends ConsumerStatefulWidget {
  final LoginPermissionUser user;

  /// Emits a success/error message so the host page can show a toast.
  final void Function(bool success, String message) onToast;

  const LoginPermissionCredentialDrawer({
    super.key,
    required this.user,
    required this.onToast,
  });

  /// Presents the drawer as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required LoginPermissionUser user,
    required void Function(bool success, String message) onToast,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) =>
          LoginPermissionCredentialDrawer(user: user, onToast: onToast),
    );
  }

  @override
  ConsumerState<LoginPermissionCredentialDrawer> createState() =>
      _LoginPermissionCredentialDrawerState();
}

class _LoginPermissionCredentialDrawerState
    extends ConsumerState<LoginPermissionCredentialDrawer> {
  bool _loading = false;
  String? _result;
  bool _showPassword = false;
  bool _copiedResult = false;
  bool _showDevPwd = false;
  String? _copiedField; // 'username' | 'password'

  bool get _isNew => widget.user.lastLogin == null;

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  Future<void> _copyText(String text, String field) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copiedField = field);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedField = null);
    });
  }

  Future<void> _handleResetPassword() async {
    setState(() => _loading = true);

    try {
      final repository = ref.read(loginPermissionRepositoryProvider);
      final res = await repository.resetPassword(widget.user.id);
      if (!mounted) return;

      if (!res.ok) {
        setState(() => _loading = false);
        widget.onToast(
          false,
          res.message.isNotEmpty ? res.message : 'Failed to reset password.',
        );
        return;
      }

      setState(() {
        _result = res.passwordBackup;
        _loading = false;
      });
      widget.onToast(true, res.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onToast(false, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleCopyResult() async {
    if (_result == null) return;
    await Clipboard.setData(ClipboardData(text: _result!));
    if (!mounted) return;
    setState(() => _copiedResult = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedResult = false);
    });
  }

  Future<void> _openSetInitialModal() async {
    await showDialog<void>(
      context: context,
      builder: (_) => LoginPermissionSetInitialPasswordModal(
        user: widget.user,
        onSuccess: (message, pwd) {
          if (pwd.isNotEmpty) setState(() => _result = pwd);
          widget.onToast(true, message);
        },
        onError: (message) => widget.onToast(false, message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildGrabHandle(),
              _buildHeader(user),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (user.devUsername != null &&
                        user.devPassword != null) ...[
                      _buildDevCredentialsCard(user),
                      const SizedBox(height: 16),
                    ],
                    _buildUserInfoCard(user),
                    const SizedBox(height: 16),
                    _buildActions(),
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      _buildResultCard(),
                    ],
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrabHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.cardBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(LoginPermissionUser user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.dashboardPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(user.name),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.staffId,
                  style: TextStyle(fontSize: 12, color: AppColors.inkTertiary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.inkTertiary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildDevCredentialsCard(LoginPermissionUser user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAFF),
        border: Border.all(color: AppColors.dashboardPurple),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEV LOGIN CREDENTIALS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.dashboardPurple,
            ),
          ),
          const SizedBox(height: 12),
          _buildDevField(
            label: 'USERNAME',
            value: user.devUsername!,
            obscured: false,
            fieldKey: 'username',
            showToggle: false,
          ),
          const SizedBox(height: 10),
          _buildDevField(
            label: 'PASSWORD',
            value: user.devPassword!,
            obscured: !_showDevPwd,
            fieldKey: 'password',
            showToggle: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDevField({
    required String label,
    required String value,
    required bool obscured,
    required String fieldKey,
    required bool showToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.inkTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  obscured ? '••••••••' : value,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: AppColors.inkPrimary,
                  ),
                ),
              ),
            ),
            if (showToggle) ...[
              const SizedBox(width: 8),
              _buildPurpleIconButton(
                icon: obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onTap: () => setState(() => _showDevPwd = !_showDevPwd),
              ),
            ],
            const SizedBox(width: 8),
            _buildPurpleIconButton(
              icon: _copiedField == fieldKey
                  ? Icons.check_rounded
                  : Icons.copy_rounded,
              onTap: () => _copyText(value, fieldKey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurpleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.dashboardPurple),
      ),
    );
  }

  Widget _buildUserInfoCard(LoginPermissionUser user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Role', user.role),
          const SizedBox(height: 8),
          _buildInfoRow('Email', user.email),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Login Access',
            user.loginAccess ? 'Enabled' : 'Disabled',
            valueColor: user.loginAccess
                ? const Color(0xFF059669)
                : const Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Last Login',
            user.lastLogin != null
                ? DateFormat('dd MMM yyyy').format(user.lastLogin!)
                : 'Never',
          ),
          if (user.mustChange) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Must change password on next login',
                style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.inkTertiary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.inkPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CREDENTIAL ACTIONS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.inkTertiary,
          ),
        ),
        const SizedBox(height: 8),

        // Reset password — always available
        _buildActionCard(
          onTap: _loading ? null : _handleResetPassword,
          title: 'Reset password',
          badge: 'Recommended',
          badgeBg: const Color(0xFFD1FAE5),
          badgeText: const Color(0xFF047857),
          description:
              'Generates a secure random 10-character password. The one-time '
              'backup is shown here — share it with the user and they will be '
              'required to change it on next login.',
          showSpinner: _loading,
        ),

        // Set initial password — only if never logged in
        if (_isNew) ...[
          const SizedBox(height: 8),
          _buildActionCard(
            onTap: _loading ? null : _openSetInitialModal,
            title: 'Set initial password',
            badge: 'No-email fallback',
            badgeBg: const Color(0xFFFEF3C7),
            badgeText: const Color(0xFFB45309),
            description:
                'You type the password yourself — for onboarding a user with '
                'no working email, so you can share it directly. Available only '
                'because this user has never logged in.',
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard({
    required VoidCallback? onTap,
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeText,
    required String description,
    bool showSpinner = false,
  }) {
    return Opacity(
      opacity: onTap == null && !showSpinner ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: badgeText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkTertiary,
                  height: 1.5,
                ),
              ),
              if (showSpinner) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.dashboardPurple,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temporary Password',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF047857),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _showPassword ? _result! : '•' * _result!.length,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildGreenIconButton(
                icon: _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onTap: () => setState(() => _showPassword = !_showPassword),
              ),
              const SizedBox(width: 8),
              _buildGreenIconButton(
                icon: _copiedResult ? Icons.check_rounded : Icons.copy_rounded,
                onTap: _handleCopyResult,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The user will be required to change this on next login.',
            style: TextStyle(fontSize: 12, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFA7F3D0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: const Color(0xFF047857)),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.inkSecondary,
            side: BorderSide(color: AppColors.cardBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Close'),
        ),
      ),
    );
  }
}
