import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

const _cardFill = Color(0x14FFFFFF); // white @ 8%
const _cardBorder = Color(0x26FFFFFF); // white @ 15%

/// Shared chrome for the Forgot Password / Reset Password screens — the
/// same deep purple gradient + centered translucent card as [LoginPage],
/// not the old light "Atrium" editorial theme (blurred teal/indigo blobs,
/// a compact header/footer, diagonal "bleed" watermark text) that
/// belonged to the previous login design and no longer matches once this
/// screen sits right next to the login screen in the same flow.
class RecoveryShell extends StatelessWidget {
  final String bleedText;
  final Widget child;
  final VoidCallback onBack;
  final String backLabel;

  const RecoveryShell({
    super.key,
    required this.bleedText,
    required this.child,
    required this.onBack,
    this.backLabel = 'Back to login',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1F87), AppColors.brandPurple, Color(0xFF5B4FE8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  decoration: BoxDecoration(
                    color: _cardFill,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              backLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
