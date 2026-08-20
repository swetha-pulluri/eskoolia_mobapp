import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const authFieldBorderColor = Color(0xFFE0DAFB); // light purple, visible on white

/// Shared input field for the purple-gradient auth screens (Login, Forgot
/// Password, Reset Password) — a white box with icon/typed-text in the
/// brand blue (`AppColors.purpleDeep`), not the dark-on-white style the
/// old "Atrium" recovery screens used before those screens shared this
/// same gradient background.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final bool autofocus;
  final Widget? trailing;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextStyle? textStyle;

  const AuthField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.autofocus = false,
    this.trailing,
    this.validator,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: authFieldBorderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.purpleDeep),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              autofocus: autofocus,
              validator: validator,
              keyboardType: keyboardType,
              textAlign: textAlign,
              style: textStyle ?? const TextStyle(color: AppColors.purpleDeep, fontSize: 15, fontWeight: FontWeight.w600),
              cursorColor: AppColors.purpleDeep,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.ink3, fontSize: 15),
                // The app's global `InputDecorationTheme` (app_theme.dart)
                // sets `filled: true` with its own light fillColor and
                // separate enabled/focused/error border states —
                // overriding only `border` leaves those other states (and
                // the fill) showing through as a nested white-ish box.
                // Every state needs to be overridden explicitly to fully
                // suppress it here.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: const TextStyle(color: Color(0xFFFFC9CF), fontSize: 11),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small caps field label above an [AuthField], matching the login
/// screen's own label style.
class AuthFieldLabel extends StatelessWidget {
  final String text;

  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xB3FFFFFF), letterSpacing: 1.0),
    );
  }
}
