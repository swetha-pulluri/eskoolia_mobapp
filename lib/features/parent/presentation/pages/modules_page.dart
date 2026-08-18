import 'package:flutter/material.dart';
import '../widgets/parent_module_grid.dart';

/// Bottom-nav "All Modules" tab — a dedicated full-page version of the
/// "All Modules" grid already embedded on Parent Home ([ParentModuleGrid]),
/// so every module is reachable directly from the nav bar instead of only
/// by scrolling Home to the bottom. Mirrors Admin's own `ModulesPage`
/// exactly (same reuse pattern, same thin wrapper).
class ParentModulesPage extends StatelessWidget {
  const ParentModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ParentModuleGrid(),
        ),
      ),
    );
  }
}
