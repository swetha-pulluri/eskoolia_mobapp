/// `captureStudentPhotoViaCamera(context) -> Future<Uint8List?>` —
/// platform-conditional "Take photo" entry point. Returns the captured JPEG
/// bytes, or `null` if the user cancelled/closed without capturing.
///
/// - Mobile/desktop (`photo_compress_io`-style): launches the native OS
///   camera directly via `image_picker` — the native camera *is* the
///   capture UI there, so no custom modal is needed.
/// - Web: mirrors `StudentAddPanel.tsx`'s own in-page camera modal exactly
///   (`getUserMedia` + `<video>` preview + Capture/Retake/Use photo/Cancel),
///   since a browser has no native camera app to hand off to.
library;

export 'camera_capture_stub.dart'
    if (dart.library.io) 'camera_capture_io.dart'
    if (dart.library.html) 'camera_capture_web.dart';
