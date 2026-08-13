import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

const _navBorder = Color(0xFFECECF2);
const _navInk1 = Color(0xFF0F1222);
const _navInk2 = Color(0xFF5A607A);
const _navInk3 = Color(0xFF9197AE);
const _navPurple = Color(0xFF6D4AFF);
const _dangerRed = Color(0xFFE11D48);

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _navBorder),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _navPurple,
                    child: Text(_initials(user), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _navInk1)),
                  const SizedBox(height: 3),
                  Text(user.email, style: const TextStyle(fontSize: 12.5, color: _navInk3)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFEEEAFF), borderRadius: BorderRadius.circular(999)),
                    child: Text(_roleLabel(user), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navPurple)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.badge_outlined, 'Username', user.username),
            if (user.schoolName != null) _infoRow(Icons.school_outlined, 'School', user.schoolName!),
            _infoRow(Icons.verified_user_outlined, 'Portal', user.portalType),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dangerRed,
                  side: const BorderSide(color: _dangerRed),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      decoration: BoxDecoration(border: Border.all(color: _navBorder), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _navInk3),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12.5, color: _navInk2)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _navInk1),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
