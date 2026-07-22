import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coming Soon — converted from web `components/shared/ComingSoon.tsx`.
/// Shown for modules whose web route resolves to this placeholder instead
/// of a real screen (e.g. Attendance's `/attendance/student` today).
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          border: Border.all(color: const Color(0xFFE8E8EE)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x140F1222), blurRadius: 24, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: const Icon(Icons.access_time_outlined, size: 28, color: Color(0xFF6D4AFF)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF181B2A), letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            const Text(
              'This module is under development',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFFA0A3B8), height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D4AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
