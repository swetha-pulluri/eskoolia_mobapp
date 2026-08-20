import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../providers/password_reset_state.dart';
import '../widgets/auth_field.dart';
import '../widgets/recovery_button.dart';
import '../widgets/recovery_shell.dart';

/// Forgot Access Key — Step 1: request a reset code.
///
/// Same real copy/labels/behavior as before (including the "Check your
/// inbox" confirmation state — an explicit "Enter Reset Code" button, not
/// an auto-redirect) and the same `POST /api/v1/auth/forgot-password/`
/// endpoint — only the visual theme changed, to match [RecoveryShell]'s
/// now-shared purple-gradient look with the login screen.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    await notifier.requestCode(_controller.text.trim());
    if (!mounted) return;
    if (ref.read(passwordResetNotifierProvider) is PasswordResetSuccess) {
      setState(() => _sent = true);
    }
  }

  void _handleEnterCode() {
    final email = _controller.text.trim();
    ref.read(passwordResetNotifierProvider.notifier).reset();
    context.push('/reset-password?email=${Uri.encodeComponent(email)}');
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(passwordResetNotifierProvider);
    final isLoading = resetState is PasswordResetLoading;

    return RecoveryShell(
      bleedText: 'RESET',
      onBack: () {
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
            const Text(
              'Recover Access',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter your institutional email and we'll send a password reset link to your inbox.",
              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            if (_sent)
              _buildSentPanel()
            else ...[
              const AuthFieldLabel('INSTITUTIONAL EMAIL ADDRESS'),
              const SizedBox(height: 8),
              AuthField(
                controller: _controller,
                icon: Icons.alternate_email,
                hint: 'your.name@school.edu.in',
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return "Please enter your institutional email address.";
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              if (resetState is PasswordResetError) ...[
                const SizedBox(height: 8),
                Text(
                  resetState.message,
                  style: const TextStyle(color: Color(0xFFFFC9CF), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 22),
              RecoveryButton(
                label: 'Send Recovery Link',
                loadingLabel: 'Sending…',
                icon: Icons.send,
                isLoading: isLoading,
                onPressed: _handleSend,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read, color: Colors.white, size: 48),
          const SizedBox(height: 14),
          const Text(
            'Check your inbox',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.5),
              children: [
                const TextSpan(text: "We've sent a 6-digit reset code to "),
                TextSpan(
                  text: _controller.text.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const TextSpan(text: '. Enter the code on the next screen to set a new password.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RecoveryButton(
            label: 'Enter Reset Code',
            icon: Icons.arrow_forward,
            onPressed: _handleEnterCode,
          ),
        ],
      ),
    );
  }
}
