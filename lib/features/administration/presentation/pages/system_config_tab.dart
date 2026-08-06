import 'package:flutter/material.dart';
import '../widgets/administration_layout.dart';
import '../widgets/administration_sub_tab_bar.dart';
import 'admin_setup_screen.dart';
import 'student_categories_screen.dart';

/// System Config — matches web `/administration/system-config`, which
/// hosts its own secondary tab bar (Admin Setup / Student Categories).
class SystemConfigPage extends StatefulWidget {
  const SystemConfigPage({super.key});

  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  int _activeTab = 0;

  static const _tabs = [
    (icon: Icons.settings_outlined, label: 'Admin Setup'),
    (icon: Icons.category_outlined, label: 'Student Categories'),
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
                AdminSetupScreen(),
                StudentCategoriesScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
