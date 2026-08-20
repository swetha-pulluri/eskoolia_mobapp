import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';
import '../providers/password_reset_state.dart';
import '../widgets/auth_field.dart';
import '../widgets/recovery_button.dart';
import '../widgets/recovery_shell.dart';

enum _ResetStep { code, password }

const _white70 = Color(0xB3FFFFFF);
const _strengthLabels = ['', 'Weak', 'Fair', 'Strong', 'Secure'];
const _strengthColors = [
  Colors.transparent,
  Color(0xFFDC2626),
  Color(0xFFF59E0B),
  Color(0xFF22C55E),
  Colors.white,
];

int _passwordStrength(String pw) {
  if (pw.isEmpty) return 0;
  var score = 0;
  if (pw.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
  if (RegExp(r'[0-9]').hasMatch(pw)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score++;
  return score;
}

/// Forgot Access Key — Steps 2 & 3: verify the code, then set a new
/// access key. Same real step progress bar, password-strength meter,
/// resend cooldown, and auto-redirect-to-login on success as before —
/// only the visual theme changed, to match [RecoveryShell]'s now-shared
/// purple-gradient look with the login screen. [email] comes from
/// [ForgotPasswordPage] via a `?email=` query param.
class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _ResetStep _step = _ResetStep.code;
  bool _success = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 60;
  String? _resendMessage;
  bool _resendSucceeded = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _startCooldown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0) return;
    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    await notifier.requestCode(widget.email);
    if (!mounted) return;
    final state = ref.read(passwordResetNotifierProvider);
    if (state is PasswordResetSuccess) {
      setState(() {
        _resendSucceeded = true;
        _resendMessage = 'A new code was sent to ${widget.email}.';
        _codeController.clear();
      });
      _startCooldown();
    } else if (state is PasswordResetError) {
      setState(() {
        _resendSucceeded = false;
        _resendMessage = state.message;
      });
    }
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      ref.read(passwordResetNotifierProvider.notifier).setError('Enter the 6-digit code sent to your email.');
      return;
    }
    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    await notifier.verifyCode(widget.email, code);
    if (!mounted) return;
    if (ref.read(passwordResetNotifierProvider) is PasswordResetSuccess) {
      notifier.reset();
      setState(() => _step = _ResetStep.password);
    }
  }

  Future<void> _handleReset() async {
    if (_passwordController.text.length < 8) {
      ref.read(passwordResetNotifierProvider.notifier).setError('New password must be at least 8 characters.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      ref.read(passwordResetNotifierProvider.notifier).setError('Passwords do not match.');
      return;
    }
    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    await notifier.resetPassword(widget.email, _codeController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (ref.read(passwordResetNotifierProvider) is PasswordResetSuccess) {
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(passwordResetNotifierProvider);
    final isLoading = resetState is PasswordResetLoading;

    return RecoveryShell(
      bleedText: _step == _ResetStep.code ? 'OTP' : 'KEY',
      onBack: () {
        if (_step == _ResetStep.password && !_success) {
          ref.read(passwordResetNotifierProvider.notifier).reset();
          setState(() => _step = _ResetStep.code);
          return;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login');
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeading(),
            if (widget.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: _white70, fontSize: 14, height: 1.5),
                  children: [
                    TextSpan(
                      text: _step == _ResetStep.code ? 'Recovery code sent to ' : 'Resetting access for ',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildProgressBar(),
            const SizedBox(height: 8),
            if (_success)
              _buildSuccessPanel()
            else if (_step == _ResetStep.code)
              ..._buildCodeStep(resetState, isLoading)
            else
              ..._buildPasswordStep(resetState, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading() {
    final text = _step == _ResetStep.code ? 'Verify Code' : 'New Password';
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
    );
  }

  Widget _buildProgressBar() {
    final secondActive = _step == _ResetStep.password || _success;
    Widget segment(bool active) => Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
    return Row(children: [segment(true), const SizedBox(width: 6), segment(secondActive)]);
  }

  Widget _buildSuccessPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 48),
          SizedBox(height: 14),
          Text(
            'Password reset!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            'Your access key has been updated. Redirecting to login…',
            textAlign: TextAlign.center,
            style: TextStyle(color: _white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCodeStep(PasswordResetState resetState, bool isLoading) {
    return [
      const AuthFieldLabel('6-DIGIT VERIFICATION CODE'),
      const SizedBox(height: 8),
      AuthField(
        controller: _codeController,
        icon: Icons.pin,
        hint: '_ _ _ _ _ _',
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 6, color: AppColors.purpleDeep),
      ),
      if (resetState is PasswordResetError) ...[
        const SizedBox(height: 8),
        Text(
          resetState.message,
          style: const TextStyle(color: Color(0xFFFFC9CF), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
      const SizedBox(height: 20),
      RecoveryButton(
        label: 'Verify Code',
        loadingLabel: 'Verifying…',
        icon: Icons.verified,
        isLoading: isLoading,
        onPressed: _handleVerify,
      ),
      const SizedBox(height: 12),
      Center(
        child: Column(
          children: [
            TextButton(
              onPressed: _cooldownSeconds > 0 ? null : _handleResend,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: Text(
                _cooldownSeconds > 0
                    ? 'Resend available in ${_cooldownSeconds}s'
                    : "Didn't receive a code? Resend",
                style: TextStyle(
                  color: _cooldownSeconds > 0 ? _white70 : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: _cooldownSeconds > 0 ? null : TextDecoration.underline,
                ),
              ),
            ),
            if (_resendMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _resendMessage!,
                style: TextStyle(
                  color: _resendSucceeded ? Colors.white : const Color(0xFFFFC9CF),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPasswordStep(PasswordResetState resetState, bool isLoading) {
    final strength = _passwordStrength(_passwordController.text);
    return [
      const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Identity verified — set your new password',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const AuthFieldLabel('NEW PASSWORD'),
      const SizedBox(height: 8),
      AuthField(
        controller: _passwordController,
        icon: Icons.lock,
        hint: 'Create a strong password',
        autofocus: true,
        obscureText: true,
      ),
      if (_passwordController.text.isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(
          children: List.generate(4, (i) {
            final level = i + 1;
            final active = strength >= level;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: active ? _strengthColors[strength] : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _strengthLabels[strength],
              style: TextStyle(color: _strengthColors[strength], fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const Flexible(
              child: Text(
                'Min 8 chars, mixed case, numbers & symbols',
                style: TextStyle(color: _white70, fontSize: 10, fontWeight: FontWeight.w700),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      const AuthFieldLabel('CONFIRM PASSWORD'),
      const SizedBox(height: 8),
      AuthField(
        controller: _confirmController,
        icon: Icons.lock_reset,
        hint: 'Re-enter your new password',
        obscureText: true,
      ),
      if (resetState is PasswordResetError) ...[
        const SizedBox(height: 8),
        Text(
          resetState.message,
          style: const TextStyle(color: Color(0xFFFFC9CF), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
      const SizedBox(height: 20),
      RecoveryButton(
        label: 'Set New Password',
        loadingLabel: 'Resetting…',
        icon: Icons.lock_open,
        isLoading: isLoading,
        onPressed: _handleReset,
      ),
    ];
  }
}
