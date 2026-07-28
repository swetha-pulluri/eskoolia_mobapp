/// `compressPhotoForUpload(bytes) -> Future<Uint8List>` — platform-conditional
/// photo resize/compression before upload, mirroring the reference
/// frontend's `compressImage()` (a `<canvas>` draw + `toBlob`) exactly: max
/// width 1200px (never upscale), JPEG re-encode at ~0.8 quality.
///
/// Why this needs to be platform-conditional rather than one pure-Dart
/// implementation: on Flutter web, `compute()` does not actually spawn a Web
/// Worker — it just runs the callback synchronously on the same thread as
/// the UI — so a pure-Dart pixel-level decode/resize/encode (the `image`
/// package) still freezes the page exactly like it would with no `compute()`
/// at all. The web implementation instead drives the browser's native
/// `<canvas>` resize (the same mechanism the frontend itself uses), which is
/// fast and never blocks. The non-web implementation uses the `image`
/// package inside a real `compute()` isolate, where that actually helps.
library;

export 'photo_compress_stub.dart'
    if (dart.library.io) 'photo_compress_io.dart'
    if (dart.library.html) 'photo_compress_web.dart';
