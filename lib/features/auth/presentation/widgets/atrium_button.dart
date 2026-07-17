import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Atrium Button Widget
/// Exact replica of .btn-atrium from frontend/app/globals.css
/// 
/// React code:
/// ```tsx
/// <button type="submit" className="btn-atrium" disabled={submitting || isLoading}>
///   {submitting ? "Signing in…" : "Enter the Digital Atrium"}
///   <span className="material-symbols-outlined">arrow_forward</span>
/// </button>
/// ```
/// 
/// CSS:
/// ```css
/// .btn-atrium {
///   height: 72px;
///   font-size: 20px;
///   font-weight: 800;
///   background: linear-gradient(135deg, var(--aira-teal), var(--atrium-indigo));
///   box-shadow: 0 24px 48px -18px rgba(13, 148, 136, 0.5);
///   border-radius: 20px;
/// }
/// ```
class AtriumButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AtriumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<AtriumButton> createState() => _AtriumButtonState();
}

class _AtriumButtonState extends State<AtriumButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 72,
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.airaTeal.withOpacity(_isHovered ? 0.4 : 0.5),
              blurRadius: _isHovered ? 32 : 48,
              offset: _isHovered ? const Offset(0, 16) : const Offset(0, 24),
              spreadRadius: -18,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ).copyWith(
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!widget.isLoading) ...[
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
