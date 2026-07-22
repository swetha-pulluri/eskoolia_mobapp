import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Attendance Page Header — converted from web
/// `attendance/student/components/AttendancePageHeader.tsx`.
class AttendancePageHeader extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onDownloadSample;

  const AttendancePageHeader({super.key, required this.onImport, required this.onExport, required this.onDownloadSample});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Student ',
                    style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.6, color: const Color(0xFF0F172A)),
                  ),
                  TextSpan(
                    text: 'Attendance',
                    style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, height: 1.15, color: const Color(0xFF6C3CE1)),
                  ),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Track and manage daily student attendance', style: TextStyle(fontSize: 14, color: Color(0xFF6B6B80))),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerButton(icon: Icons.file_download_outlined, label: 'Download Sample', onTap: onDownloadSample),
              _headerButton(icon: Icons.upload_outlined, label: 'Import', onTap: onImport),
              _headerButton(icon: Icons.ios_share_outlined, label: 'Export', onTap: onExport),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A1A2E),
        side: const BorderSide(color: Color(0xFFE6E6EC)),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
