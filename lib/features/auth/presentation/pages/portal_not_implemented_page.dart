import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

/// Shown after login for a portal role whose dashboard is real on web
/// (Teacher/Parent/Student portals are fully built there) but has not been
/// ported to this Flutter app yet. Per explicit product decision, these
/// roles must NOT silently fall back to the Admin Dashboard — they land
/// here instead, so the gap is visible rather than hidden.
class PortalNotImplementedPage extends ConsumerWidget {
  final String portalLabel;

  const PortalNotImplementedPage({super.key, required this.portalLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.hourglass_top_outlined, size: 30, color: AppColors.brandPurple),
                ),
                const SizedBox(height: 20),
                Text(
                  '$portalLabel — Coming Soon',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink1),
                ),
                const SizedBox(height: 8),
                Text(
                  'The $portalLabel isn\'t available in the mobile app yet. It already exists on the web app and is coming to mobile soon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink3, height: 1.4),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink1,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
