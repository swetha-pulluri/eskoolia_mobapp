import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/document_branding_state.dart';

final _savedDateFormat = DateFormat('MMM d, y, h:mm a');

/// Grayscale + slight contrast boost — the closest Flutter equivalent of
/// the web's `filter: grayscale(1) contrast(1.05)` applied to the preview
/// image only when the "B&W" toggle is on.
const List<double> _grayscaleMatrix = [
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

/// The Header tab's live preview pane — mirrors `DocumentBrandingPanel.tsx`'s
/// right-hand preview card: a pulsing status dot, an A4-ratio canvas showing
/// the rendered header PNG (fetched from the debounced `preview/` endpoint
/// in generated mode, or the saved `header-image/` in uploaded mode), a B&W
/// toggle, and a "Saved by … · …" footer line.
class DocumentBrandingPreview extends StatelessWidget {
  final DocumentBrandingState state;
  final VoidCallback onToggleBw;

  const DocumentBrandingPreview({super.key, required this.state, required this.onToggleBw});

  @override
  Widget build(BuildContext context) {
    final settings = state.settings;
    final savedBy = settings?.updatedByName ?? '—';
    final savedAt = () {
      final raw = settings?.updatedAt;
      if (raw == null) return '—';
      final parsed = DateTime.tryParse(raw);
      return parsed == null ? raw : _savedDateFormat.format(parsed.toLocal());
    }();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.previewLoading ? AppColors.warningAmber : AppColors.successGreen,
                ),
              ),
              Text(
                state.previewLoading ? 'Rendering…' : 'Live preview',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '— A4 proportions, unsaved',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: onToggleBw,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(state.bwPreview ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 14),
                label: const Text('B&W', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 210 / 297,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderPrimary),
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: state.previewBytes == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, size: 28, color: AppColors.textTertiary),
                          SizedBox(height: 8),
                          Text('No preview yet — save to render', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _maybeGrayscale(
                          Image.memory(Uint8List.fromList(state.previewBytes!), fit: BoxFit.fitWidth),
                          state.bwPreview,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < 6; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(height: 4, width: double.infinity, color: const Color(0xFFE8E8E8)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Saved by $savedBy · $savedAt', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _maybeGrayscale(Widget child, bool grayscale) {
    if (!grayscale) return child;
    return ColorFiltered(colorFilter: const ColorFilter.matrix(_grayscaleMatrix), child: child);
  }
}
