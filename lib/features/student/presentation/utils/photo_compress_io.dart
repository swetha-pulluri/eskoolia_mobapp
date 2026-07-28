import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// Mobile/desktop: decode → resize (max width 1200px, never upscale) →
/// re-encode as JPEG at quality 80, run inside a real isolate via [compute]
/// so the pixel-level work never blocks the UI thread.
Future<Uint8List> compressPhotoForUpload(Uint8List bytes) {
  return compute(_resizeAndEncode, bytes);
}

Uint8List _resizeAndEncode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  var working = decoded;
  const maxWidth = 1200;
  if (working.width > maxWidth) {
    working = img.copyResize(working, width: maxWidth);
  }
  return Uint8List.fromList(img.encodeJpg(working, quality: 80));
}
