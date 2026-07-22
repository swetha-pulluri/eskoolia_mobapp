import 'package:flutter/material.dart';

/// Bulk Action Bar — converted from web
/// `attendance/student/components/BulkActionBar.tsx`.
class AttendanceBulkActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final void Function(String status) onMarkAll;
  final VoidCallback onSignInAll;
  final VoidCallback? onSignOutAll;

  const AttendanceBulkActionBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onMarkAll,
    required this.onSignInAll,
    this.onSignOutAll,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFF0B0B14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFF4729F4), shape: BoxShape.circle),
              child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            const Text('selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _btn('Sign in & mark present', bg: const Color(0xFF0A8C5A), onTap: onSignInAll, tooltip: 'Sign in selected students and mark them present'),
            _btn('Mark absent', bg: const Color(0xFFC2264E), onTap: () => onMarkAll('absent')),
            _btn('Mark late', bg: const Color(0xFFB4721B), onTap: () => onMarkAll('late')),
            if (onSignOutAll != null) _outlineBtn('Sign out', onTap: onSignOutAll!, tooltip: 'Sign out selected students'),
          ]),
          InkWell(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, {required Color bg, required VoidCallback onTap, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _outlineBtn(String label, {required VoidCallback onTap, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}
