import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../auth/data/models/login_request_model.dart';

/// Unlock Edit Dialog — converted from web
/// `attendance/student/components/UnlockEditDialog.tsx`. Matches web's
/// real behavior exactly: it does NOT touch `is_locked` on any attendance
/// record and does NOT require superuser — it re-verifies the currently
/// logged-in user's own password via a real `POST /api/v1/auth/login/`
/// call (password re-entry, not privilege elevation), and if that
/// succeeds, just flips a client-side "unlocked for this session" flag.
/// Calls the auth datasource directly (not the repository/notifier) so
/// this verification call never overwrites the real session's stored
/// tokens — exactly mirroring how the real web page discards the
/// re-login response instead of applying it.
class UnlockEditDialog extends ConsumerStatefulWidget {
  final VoidCallback onUnlock;
  final VoidCallback onClose;

  const UnlockEditDialog({super.key, required this.onUnlock, required this.onClose});

  @override
  ConsumerState<UnlockEditDialog> createState() => _UnlockEditDialogState();
}

class _UnlockEditDialogState extends ConsumerState<UnlockEditDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    final username = ref.read(authNotifierProvider).whenOrNull(authenticated: (user) => user.username);
    if (username == null) {
      setState(() => _error = 'Your session has expired. Please log in again.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRemoteDataSourceProvider).login(LoginRequestModel(username: username, password: _controller.text));
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onUnlock();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Incorrect password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: const Color(0x66000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: BoxConstraints(maxWidth: 380, maxHeight: MediaQuery.of(context).size.height * 0.85),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFFDF1DC), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: const Icon(Icons.lock_outline, size: 14, color: Color(0xFFB4721B))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Unlock Past Date Editing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0B0B14))),
                    const SizedBox(height: 4),
                    const Text('Re-enter your password to enable editing for this past date.', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B7B), height: 1.4)),
                  ]),
                ),
                InkWell(onTap: widget.onClose, child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 16, color: Color(0xFF9CA0AE)))),
              ]),
              const SizedBox(height: 16),
              const Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B6B7B), letterSpacing: 0.4)),
              const SizedBox(height: 6),
              TextField(
                controller: _controller,
                obscureText: true,
                autofocus: true,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Enter your login password',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA0AE)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE6E6EC))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4729F4), width: 2)),
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF0B0B14)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.error_outline, size: 12, color: Color(0xFFC2264E)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFC2264E)))),
                  ]),
                ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: widget.onClose, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3A3A4A), side: const BorderSide(color: Color(0xFFE6E6EC))), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4729F4), foregroundColor: Colors.white),
                  child: _loading
                      ? const SizedBox(width: 60, child: Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 8), Text('...', style: TextStyle(fontSize: 12))]))
                      : const Text('Unlock Editing'),
                ),
              ]),
            ]),
            ),
          ),
        ),
      ),
    );
  }
}
