import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/login_permission_user.dart';
import '../providers/login_permission_providers.dart';

/// Set Initial Password modal — mirrors frontend
/// components/login-permission/SetInitialPasswordModal.tsx.
///
/// Offers two modes: use a default password (123456) or type a manual one.
/// On success, surfaces the password backup with show/hide + copy.
/// Shown as a mobile-friendly dialog.
class LoginPermissionSetInitialPasswordModal extends ConsumerStatefulWidget {
  final LoginPermissionUser user;

  /// Called after the password is set. Returns the backup password so the
  /// drawer can display it and emit a success toast.
  final void Function(String message, String passwordBackup) onSuccess;

  /// Called if the API call fails (e.g. validation error from the backend).
  final void Function(String message) onError;

  const LoginPermissionSetInitialPasswordModal({
    super.key,
    required this.user,
    required this.onSuccess,
    required this.onError,
  });

  @override
  ConsumerState<LoginPermissionSetInitialPasswordModal> createState() =>
      _LoginPermissionSetInitialPasswordModalState();
}

enum _Mode { none, defaultPwd, manual }

class _LoginPermissionSetInitialPasswordModalState
    extends ConsumerState<LoginPermissionSetInitialPasswordModal> {
  static const String _defaultPassword = '123456';

  _Mode _mode = _Mode.none;
  final TextEditingController _manualController = TextEditingController();
  bool _showPwd = false;
  bool _loading = false;
  String? _result;
  bool _copied = false;
  String _validationError = '';

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_mode == _Mode.none) return;

    final manual = _manualController.text.trim();
    if (_mode == _Mode.manual) {
      if (manual.isEmpty) {
        setState(() => _validationError = 'Please enter a password.');
        return;
      }
      if (manual.length < 6) {
        setState(
          () => _validationError = 'Password must be at least 6 characters.',
        );
        return;
      }
    }

    setState(() {
      _validationError = '';
      _loading = true;
    });

    try {
      final repository = ref.read(loginPermissionRepositoryProvider);
      final res = await repository.setInitialPassword(
        widget.user.id,
        mode: _mode == _Mode.manual ? 'manual' : 'default',
        password: _mode == _Mode.manual ? manual : null,
      );
      if (!mounted) return;

      if (!res.ok) {
        setState(() => _loading = false);
        widget.onError(res.message.isNotEmpty ? res.message : 'Failed to set password.');
        return;
      }

      setState(() {
        _result = res.passwordBackup.isNotEmpty
            ? res.passwordBackup
            : (_mode == _Mode.manual ? manual : _defaultPassword);
        _loading = false;
      });
      widget.onSuccess(res.message, _result!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _result != null ? _buildResult() : _buildOptions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Initial Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.user.name,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.textTertiary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            children: [
              const TextSpan(text: 'Choose how to set the password for '),
              TextSpan(
                text: widget.user.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: ':'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Default password option
        _buildOptionCard(
          selected: _mode == _Mode.defaultPwd,
          selectedBorder: AppColors.dashboardPurple,
          icon: Icons.verified_user_outlined,
          iconColor: AppColors.dashboardPurple,
          title: 'Use Default Password',
          badge: 'Quick',
          badgeBg: const Color(0xFFEEEAFF),
          badgeText: AppColors.dashboardPurple,
          description:
              'Sets the password to $_defaultPassword. User must change it on first login.',
          onTap: () => setState(() {
            _mode = _Mode.defaultPwd;
            _validationError = '';
          }),
        ),
        const SizedBox(height: 8),

        // Manual password option
        _buildOptionCard(
          selected: _mode == _Mode.manual,
          selectedBorder: const Color(0xFFFBBF24),
          icon: Icons.vpn_key_outlined,
          iconColor: const Color(0xFFF59E0B),
          title: 'Set Manual Password',
          badge: 'Custom',
          badgeBg: const Color(0xFFFEF3C7),
          badgeText: const Color(0xFFB45309),
          description:
              'You type the password — share it with the user directly. Must change on first login.',
          onTap: () => setState(() {
            _mode = _Mode.manual;
            _validationError = '';
          }),
        ),

        // Manual password input
        if (_mode == _Mode.manual) ...[
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              children: const [
                TextSpan(text: 'Password '),
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _manualController,
            obscureText: !_showPwd,
            onChanged: (_) {
              if (_validationError.isNotEmpty) {
                setState(() => _validationError = '');
              }
            },
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Min. 6 characters',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPwd = !_showPwd),
                icon: Icon(
                  _showPwd
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
                color: AppColors.textTertiary,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _validationError.isNotEmpty
                      ? const Color(0xFFF87171)
                      : AppColors.cardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _validationError.isNotEmpty
                      ? const Color(0xFFF87171)
                      : AppColors.dashboardPurple,
                ),
              ),
            ),
          ),
          if (_validationError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _validationError,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ],
        ],

        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: (_mode == _Mode.none || _loading)
                    ? null
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dashboardPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.dashboardPurple.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          Text('Setting…'),
                        ],
                      )
                    : const Text('Set Password'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required bool selected,
    required Color selectedBorder,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeText,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? selectedBorder.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: selected ? selectedBorder : AppColors.cardBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
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
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                'Password set successfully',
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
                        _showPwd
                            ? _result!
                            : '•' * _result!.length,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildResultIconButton(
                    icon: _showPwd
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onTap: () => setState(() => _showPwd = !_showPwd),
                  ),
                  const SizedBox(width: 8),
                  _buildResultIconButton(
                    icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                    onTap: () => _copy(_result!),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The user must change this password on first login.',
                style: TextStyle(fontSize: 12, color: Color(0xFF059669)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: BorderSide(color: AppColors.cardBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildResultIconButton({
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
}
