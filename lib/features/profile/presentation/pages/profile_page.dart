import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);
const _dangerRed = Color(0xFFE11D48);
const _pageBg = Color(0xFFF6F6FB);
const _iconBadgeBg = Color(0xFFF1EDFE);

/// Bottom-nav "Profile" tab — the account-info + logout destination that
/// used to live behind the header's avatar dropdown (now removed from the
/// top bar in favor of this dedicated tab). Reuses [authNotifierProvider]
/// for both the user data and the actual `logout()` call — same auth state
/// the rest of the app already reads.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _initials(UserEntity user) {
    final f = user.firstName.trim();
    final l = user.lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    if (user.username.isNotEmpty) return user.username[0].toUpperCase();
    return '?';
  }

  String _roleLabel(UserEntity user) {
    if (user.roleNames.isNotEmpty) return user.roleNames.join(', ');
    switch (user.portalType) {
      case 'super_admin':
        return 'Super Admin';
      case 'teacher':
        return 'Teacher';
      case 'parent':
        return 'Parent';
      case 'student':
        return 'Student';
      default:
        return 'Admin';
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of Eskoolia?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out', style: TextStyle(color: _dangerRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.maybeWhen(authenticated: (u) => u, orElse: () => null);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF2EFFE), Color(0xFFDCD3FB)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // White "halo" ring behind the avatar, matching the
                  // reference — a plain CircleAvatar sat directly on the
                  // gradient before.
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: _navPurple,
                      child: Text(_initials(user), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(user.email, style: const TextStyle(fontSize: 15, color: _navInk1, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _navPurple.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(_roleLabel(user), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navPurple)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.person_outline, 'Username', user.username),
            if (user.schoolName != null) _infoRow(Icons.school_outlined, 'School', user.schoolName!),
            _infoRow(Icons.verified_user_outlined, 'Portal', user.portalType),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _dangerRed,
                  side: const BorderSide(color: Color(0xFFF4C7CE)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _navBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _iconBadgeBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: _navPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: _navInk3)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navInk1),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
