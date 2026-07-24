import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared header for the Students sub-module screens (Categories, Disabled,
/// Deleted/Restore, Unassigned, Multi Subject Assignment, Promotion) —
/// mirrors each of their near-identical breadcrumb + Playfair title (with a
/// colored italic accent word) + subtitle layout, so it's built once instead
/// of six times.
class StudentSubpageHeader extends StatelessWidget {
  final String titlePlain;
  final String titleAccent;
  final Color accentColor;
  final String subtitle;
  final List<Widget> actions;

  const StudentSubpageHeader({
    super.key,
    required this.titlePlain,
    required this.titleAccent,
    required this.accentColor,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.go('/students'),
                child: const Text(
                  'Students',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4F39F6), fontWeight: FontWeight.w600),
                ),
              ),
              const Text(' / ', style: TextStyle(fontSize: 12, color: Color(0xFF9CA0AE))),
              Expanded(
                child: Text(
                  titleAccent,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA0AE)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: const Color(0xFF0F172A),
                  ),
                  children: [
                    TextSpan(text: titlePlain),
                    TextSpan(
                      text: titleAccent,
                      style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: accentColor),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
