import 'package:flutter/material.dart';
import '../widgets/administration_layout.dart';
import '../widgets/administration_sub_tab_bar.dart';
import 'postal_receive_screen.dart';
import 'postal_dispatch_screen.dart';

/// Postal Management — matches web `/administration/postal`, which hosts
/// its own secondary tab bar (Postal Received / Postal Dispatched).
class PostalManagementPage extends StatefulWidget {
  const PostalManagementPage({super.key});

  @override
  State<PostalManagementPage> createState() => _PostalManagementPageState();
}

class _PostalManagementPageState extends State<PostalManagementPage> {
  int _activeTab = 0;

  static const _tabs = [
    (icon: Icons.move_to_inbox_outlined, label: 'Postal Received'),
    (icon: Icons.outbox_outlined, label: 'Postal Dispatched'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdministrationLayout(
      currentPath: '/administration/postal',
      child: Column(
        children: [
          AdministrationSubTabBar(tabs: _tabs, activeIndex: _activeTab, onTap: (i) => setState(() => _activeTab = i)),
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: const [
                PostalReceiveScreen(),
                PostalDispatchScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
