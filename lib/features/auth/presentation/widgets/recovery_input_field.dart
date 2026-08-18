import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Two input styles used across the Forgot/Reset Password screens — exact
/// replicas of frontend/app/globals.css:
/// - [underline]: `.editorial-form input` (Forgot Password's email field) —
///   bottom-border only, tinted fill, icon inset at the left.
/// - [boxed]: `.reset-form input` / `.activation-field input` (Reset
///   Password's code/password fields) — full rounded border, focus ring.
enum RecoveryInputStyle { underline, boxed }

class RecoveryInputField extends StatefulWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final RecoveryInputStyle style;
  final TextEditingController controller;
  final bool obscureText;
  final bool showPasswordToggle;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool autofocus;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  const RecoveryInputField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.controller,
    this.style = RecoveryInputStyle.boxed,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.keyboardType,
    this.validator,
    this.autofocus = false,
    this.textStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  State<RecoveryInputField> createState() => _RecoveryInputFieldState();
}

class _RecoveryInputFieldState extends State<RecoveryInputField> {
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isUnderline = widget.style == RecoveryInputStyle.underline;
    final labelColor = _isFocused ? AppColors.surfaceTint : AppColors.onSurfaceVariant;
    final iconColor = _isFocused ? AppColors.surfaceTint : AppColors.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ).copyWith(fontFamily: 'Plus Jakarta Sans'),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: isUnderline ? null : BorderRadius.circular(12),
              border: isUnderline
                  ? Border(
                      bottom: BorderSide(
                        color: _isFocused ? AppColors.surfaceTint : AppColors.outlineVariant,
                        width: 1,
                      ),
                    )
                  : Border.all(
                      color: _isFocused ? AppColors.surfaceTint : AppColors.outlineVariant,
                      width: 1,
                    ),
              boxShadow: !isUnderline && _isFocused
                  ? [BoxShadow(color: AppColors.surfaceTint.withValues(alpha: 0.1), blurRadius: 0, spreadRadius: 4)]
                  : null,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(widget.icon, size: 20, color: iconColor),
                ),
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    obscureText: _obscureText,
                    autofocus: widget.autofocus,
                    keyboardType: widget.keyboardType,
                    textAlign: widget.textAlign,
                    style: (widget.textStyle ??
                            const TextStyle(color: AppColors.onBackground, fontSize: 16, fontWeight: FontWeight.w400))
                        .copyWith(fontFamily: 'Plus Jakarta Sans'),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        color: AppColors.outline.withValues(alpha: 0.6),
                        fontSize: 16,
                      ).copyWith(fontFamily: 'Plus Jakarta Sans'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                    ),
                    validator: widget.validator,
                  ),
                ),
                if (widget.showPasswordToggle)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: IconButton(
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
