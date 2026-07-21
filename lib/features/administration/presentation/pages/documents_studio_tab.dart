import 'package:flutter/material.dart';
import '../widgets/administration_layout.dart';
import '../widgets/administration_tab_placeholder.dart';

/// Documents Studio — matches web `/administration/documents`.
/// Sub-tabs (ID Cards / Certificates, each with Design Template and
/// Generate & Print) are not implemented yet.
class DocumentsStudioPage extends StatelessWidget {
  const DocumentsStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdministrationLayout(
      currentPath: '/administration/documents',
      child: AdministrationTabPlaceholder(
        icon: Icons.badge_outlined,
        title: 'Documents Studio',
        subTabLabels: [
          'ID Cards — Design Template',
          'ID Cards — Generate & Print',
          'Certificates — Design Template',
          'Certificates — Generate & Print',
        ],
      ),
    );
  }
}
