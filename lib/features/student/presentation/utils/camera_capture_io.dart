import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

/// Mobile/desktop: the native OS camera app is itself the capture UI (its
/// own preview, shutter, retake/confirm), so this just hands off to it
/// directly instead of building a custom in-app modal.
Future<Uint8List?> captureStudentPhotoViaCamera(BuildContext context) async {
  final shot = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
  if (shot == null) return null;
  return shot.readAsBytes();
}
