import 'package:flutter/material.dart';
import '../widgets/administration_layout.dart';
import '../widgets/administration_sub_tab_bar.dart';
import 'id_cards_screen.dart';
import 'generate_id_card_screen.dart';
import 'certificates_screen.dart';
import 'generate_certificate_screen.dart';

/// Documents Studio — matches web `/administration/documents`
/// (`DocumentsStudioPage`): 2 main tabs (ID Cards / Certificates, underline
/// style) each with 2 sub-tabs (Design Template / Generate & Print, pill
/// style) — a distinct two-level tab structure not used elsewhere in
/// Administration.
class DocumentsStudioPage extends StatefulWidget {
  const DocumentsStudioPage({super.key});

  @override
  State<DocumentsStudioPage> createState() => _DocumentsStudioPageState();
}

class _DocumentsStudioPageState extends State<DocumentsStudioPage> {
  int _mainTab = 0; // 0 = ID Cards, 1 = Certificates
  int _subTab = 0; // 0 = Design Template, 1 = Generate & Print

  static const _mainTabs = [
    (icon: Icons.badge_outlined, label: 'ID Cards'),
    (icon: Icons.workspace_premium_outlined, label: 'Certificates'),
  ];

  static const _subTabs = [
    (icon: Icons.credit_card_outlined, label: 'Design Template'),
    (icon: Icons.verified_outlined, label: 'Generate & Print'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdministrationLayout(
      child: Column(
        children: [
          AdministrationSubTabBar(
            tabs: _mainTabs,
            activeIndex: _mainTab,
            onTap: (i) => setState(() {
              _mainTab = i;
              _subTab = 0;
            }),
          ),
          AdministrationPillTabBar(
            tabs: _subTabs,
            activeIndex: _subTab,
            onTap: (i) => setState(() => _subTab = i),
          ),
          Expanded(
            child: IndexedStack(
              index: _mainTab * 2 + _subTab,
              children: const [
                IdCardsScreen(),
                GenerateIdCardScreen(),
                CertificatesScreen(),
                GenerateCertificateScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
