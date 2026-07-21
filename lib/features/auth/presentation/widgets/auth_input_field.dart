import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Auth Input Field Widget
/// Exact replica of .input-group from frontend/app/globals.css
/// 
/// React code:
/// ```tsx
/// <label className="input-group teal">
///   <span className="input-label">Institutional Email / Username</span>
///   <span className="input-wrap">
///     <span className="material-symbols-outlined input-icon">alternate_email</span>
///     <input ... />
///   </span>
/// </label>
/// ```
class AuthInputField extends StatefulWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final AuthInputTone tone;
  final TextEditingController controller;
  final bool obscureText;
  final bool showPasswordToggle;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool autofocus;

  const AuthInputField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.tone,
    required this.controller,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.keyboardType,
    this.validator,
    this.autofocus = false,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.tone == AuthInputTone.teal
        ? AppColors.airaTeal
        : AppColors.saffron;
    final focusRingColor = widget.tone == AuthInputTone.teal
        ? AppColors.tealFocus
        : AppColors.saffronFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Label
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.atriumIndigo,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8, // 0.15em * 12px = 1.8px
            height: 16 / 12,
          ).copyWith(
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 8),
        // Input Wrap
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused ? focusColor : AppColors.surfaceVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
                if (_isFocused)
                  BoxShadow(
                    color: focusRingColor,
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: Row(
              children: [
                // Input Icon
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: _isFocused ? focusColor : AppColors.outline,
                  ),
                ),
                // Input Field
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    obscureText: _obscureText,
                    autofocus: widget.autofocus,
                    keyboardType: widget.keyboardType,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ).copyWith(
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        color: AppColors.outline.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ).copyWith(
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    validator: widget.validator,
                  ),
                ),
                // Password Eye Toggle (if applicable)
                if (widget.showPasswordToggle)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: IconButton(
                      onPressed: () {
                        setState(() => _obscureText = !_obscureText);
                      },
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

enum AuthInputTone {
  teal,
  saffron,
}
