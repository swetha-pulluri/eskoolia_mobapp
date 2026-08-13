import 'package:flutter/material.dart';
import '../widgets/module_grid.dart';

/// Bottom-nav "Modules" tab — a dedicated full-page version of the "All
/// Modules" grid already embedded on Home ([ModuleGrid]), so every module
/// is reachable directly from the nav bar instead of only by scrolling
/// Home to the bottom. Same data source, tap behavior, and "Coming Soon"
/// handling as the Home section — this page just gives it its own screen.
class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ModuleGrid(),
        ),
      ),
    );
  }
}
