import 'dart:typed_data';

/// Fallback for platforms with neither `dart:io` nor `dart:html` available
/// (shouldn't be reachable on any Flutter target this app ships to).
Future<Uint8List> compressPhotoForUpload(Uint8List bytes) {
  throw UnsupportedError('Photo compression is not supported on this platform.');
}
