import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Trust Strip Widget
/// Exact replica of .trust-strip from frontend/app/globals.css
/// Shows faculty avatars and trust text
///
/// React code:
/// ```tsx
/// <div className="trust-strip">
///   <div className="avatar-row">
///     {FACULTY_IMAGES.map((src, i) => <img key={i} alt="Faculty" src={src} />)}
///   </div>
///   <div>
///     <p>Built for India's Future Leaders</p>
///     <span>Trusted by India's top educational institutions.</span>
///   </div>
/// </div>
/// ```
class TrustStrip extends StatelessWidget {
  final List<String> facultyImages;

  const TrustStrip({super.key, required this.facultyImages});

  @override
  Widget build(BuildContext context) {
    // Calculate stack width: first avatar (56px) + overlapping avatars (40px each)
    final stackWidth = facultyImages.isEmpty
        ? 0.0
        : 56 + (facultyImages.length - 1) * 40.0;

    return Row(
      children: [
        // Avatar Row
        SizedBox(
          width: stackWidth,
          height: 56,
          child: Stack(
            children: [
              for (int i = 0; i < facultyImages.length; i++)
                Positioned(
                  left: i * 40.0, // overlap: margin-left: -16px (56 - 16 = 40)
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(facultyImages[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Trust Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Built for India\'s Future Leaders',
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.84, // 0.06em * 14px
                  height: 1.0,
                ).copyWith(fontFamily: 'Plus Jakarta Sans'),
              ),
              const SizedBox(height: 3),
              Text(
                'Trusted by India\'s top educational institutions.',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1.0,
                ).copyWith(fontFamily: 'Plus Jakarta Sans'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
