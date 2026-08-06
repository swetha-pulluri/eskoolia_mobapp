import 'package:flutter/material.dart';
import '../widgets/administration_layout.dart';
import '../widgets/administration_sub_tab_bar.dart';
import 'visitor_book_screen.dart';
import 'complaints_screen.dart';
import 'phone_calls_screen.dart';

/// Communication Hub — matches web `/administration/communication-hub`,
/// which hosts its own secondary tab bar (Visitor Book / Complaints /
/// Phone Calls) inline, separate from the 4 main Administration tabs.
class CommunicationHubPage extends StatefulWidget {
  const CommunicationHubPage({super.key});

  @override
  State<CommunicationHubPage> createState() => _CommunicationHubPageState();
}

class _CommunicationHubPageState extends State<CommunicationHubPage> {
  int _activeTab = 0;

  static const _tabs = [
    (icon: Icons.person_search_outlined, label: 'Visitor Book'),
    (icon: Icons.error_outline, label: 'Complaints'),
    (icon: Icons.phone_outlined, label: 'Phone Calls'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdministrationLayout(
      child: Column(
        children: [
          AdministrationSubTabBar(tabs: _tabs, activeIndex: _activeTab, onTap: (i) => setState(() => _activeTab = i)),
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: const [
                VisitorBookScreen(),
                ComplaintsScreen(),
                PhoneCallsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
