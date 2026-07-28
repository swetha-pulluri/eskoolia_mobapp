import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// Fallback for platforms with neither `dart:io` nor `dart:html` available
/// (shouldn't be reachable on any Flutter target this app ships to).
Future<Uint8List?> captureStudentPhotoViaCamera(BuildContext context) {
  throw UnsupportedError('Camera capture is not supported on this platform.');
}
