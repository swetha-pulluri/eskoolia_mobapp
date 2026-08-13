import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/reset_password_result_entity.dart';
import '../../../../domain/entities/student_credentials_entity.dart';
import '../../../providers/my_classes_providers.dart';
import '../load_error_card.dart';

/// Mirrors `CredentialsTab` in `StudentProfileDrawer.tsx` — two account
/// cards (Student / Parent portal) with a Reset Password action whose
/// result reveal-box + copy-to-clipboard idiom is ported from
/// `login_permission_credential_drawer.dart`'s `_buildResultCard`. Reset
/// Password is shown unconditionally (no client-side `students.manage`
/// gate — see plan notes); if the teacher actually lacks it, the backend's
/// real 403 message surfaces via the normal error path below.
class CredentialsTab extends ConsumerWidget {
  final int studentId;
  const CredentialsTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credsAsync = ref.watch(studentCredentialsProvider(studentId));
    return credsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => LoadErrorCard(
        title: 'Could not load credentials',
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(studentCredentialsProvider(studentId)),
        iconSize: 24,
        padding: const EdgeInsets.symmetric(vertical: 32),
      ),
      data: (creds) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AccountCard(title: 'Student Portal', info: creds.student, studentId: studentId, target: 'student'),
          const SizedBox(height: 16),
          _AccountCard(
            title: [
              'Parent Portal',
              if ((creds.guardianName ?? '').isNotEmpty) '— ${creds.guardianName}${(creds.guardianRelation ?? '').isNotEmpty ? ' (${creds.guardianRelation})' : ''}',
            ].join(' '),
            info: creds.parent,
            studentId: studentId,
            target: 'parent',
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerStatefulWidget {
  final String title;
  final PortalAccountInfoEntity info;
  final int studentId;
  final String target;

  const _AccountCard({required this.title, required this.info, required this.studentId, required this.target});

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _loading = false;
  bool _showPassword = false;
  bool _copied = false;
  ResetPasswordResultEntity? _result;
  String? _error;

  Future<void> _resetPassword() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(myClassesRepositoryProvider).resetStudentPassword(widget.studentId, widget.target);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _copy() async {
    if (_result == null) return;
    await Clipboard.setData(ClipboardData(text: _result!.newPassword));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '—';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(color: AppColors.bg2, border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink2, letterSpacing: 0.5),
                  ),
                ),
                if (info.hasAccount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (info.isActive ?? false) ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (info.isActive ?? false) ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 10,
                          color: (info.isActive ?? false) ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          (info.isActive ?? false) ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: (info.isActive ?? false) ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: !info.hasAccount
                ? const Text('No portal account created yet.', style: TextStyle(fontSize: 12, color: AppColors.ink2))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Username', info.username ?? '—'),
                      _infoRow('Last Login', info.lastLogin != null ? _formatDate(info.lastLogin) : 'Never'),
                      _infoRow('Joined', _formatDate(info.dateJoined)),
                      const SizedBox(height: 10),
                      if (_result != null) _resultCard() else _resetButton(),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(fontSize: 11, color: AppColors.error)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink2))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink1))),
        ],
      ),
    );
  }

  Widget _resetButton() {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _resetPassword,
      icon: _loading
          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPurple))
          : const Icon(Icons.refresh, size: 13),
      label: Text(_loading ? 'Resetting…' : 'Reset Password'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandPurple,
        backgroundColor: _loading ? AppColors.bg2 : AppColors.purpleSoft,
        side: const BorderSide(color: Color(0xFFDDD6FE)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _resultCard() {
    final password = _result!.newPassword;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFECFDF5), border: Border.all(color: const Color(0xFFA7F3D0)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Password (share with user)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857), letterSpacing: 0.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFA7F3D0)), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _showPassword ? password : '•' * password.length,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _greenIconButton(icon: _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, onTap: () => setState(() => _showPassword = !_showPassword)),
              const SizedBox(width: 8),
              _greenIconButton(icon: _copied ? Icons.check_rounded : Icons.copy_rounded, onTap: _copy),
            ],
          ),
          const SizedBox(height: 8),
          const Text('User will be prompted to change this on next login.', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
        ],
      ),
    );
  }

  Widget _greenIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFA7F3D0)), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: const Color(0xFF047857)),
      ),
    );
  }
}
