import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shared card shell for Settings screens — matches the app's established
/// card look (see e.g. `LeavePolicyCard`): white surface, subtle border,
/// barely-there shadow. Used to break a screen into clearly separated
/// cards instead of one long nested container. First introduced for
/// School Info, reused by Leave Policy and any other Settings page that
/// wants the same look.
class SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const SettingsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1222), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: child,
    );
  }
}
