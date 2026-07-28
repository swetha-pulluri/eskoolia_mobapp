// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web: mirrors `StudentAddPanel.tsx`'s `compressImage()` exactly — draw the
/// picked file into a `<canvas>` at max width 1200px (never upscale), then
/// export at JPEG quality 0.8. This is real native browser image resizing,
/// not pixel-level Dart work, so — unlike the `image` package — it never
/// blocks the UI thread here.
///
/// Uses `canvas.toDataUrl()` (synchronous, returns a base64 string
/// immediately) rather than `canvas.toBlob()` + `FileReader` (both
/// event/Promise-based). The latter combo was found to hang indefinitely on
/// `FileReader.readAsArrayBuffer` in real testing even though `toBlob`
/// itself resolved — `toDataUrl` has no such failure mode since there is no
/// async callback to ever fail to fire.
Future<Uint8List> compressPhotoForUpload(Uint8List bytes) async {
  final blob = html.Blob([bytes]);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  try {
    // Listeners MUST be attached before `src` is assigned — a blob: URL can
    // decode fast enough that setting `src` in the same statement as
    // constructing the element (e.g. `ImageElement(src: objectUrl)`) lets
    // the load event fire before `.onLoad.first` subscribes to it, which
    // then never completes: the exact "stuck on the loading spinner
    // forever" bug this fixes.
    final image = html.ImageElement();
    final loaded = Completer<void>();
    image.onLoad.first.then((_) {
      if (!loaded.isCompleted) loaded.complete();
    });
    image.onError.first.then((event) {
      if (!loaded.isCompleted) loaded.completeError(Exception('Invalid image.'));
    });
    image.src = objectUrl;
    await loaded.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('[stage:image-load] the browser never fired the image load event for this file.'),
    );

    var width = image.naturalWidth;
    var height = image.naturalHeight;
    const maxWidth = 1200;
    if (width > maxWidth) {
      height = (height * maxWidth / width).round();
      width = maxWidth;
    }
    if (width == 0 || height == 0) {
      throw Exception('[stage:image-dimensions] the picked file has no readable image dimensions.');
    }

    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(image, 0, 0, width, height);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.8);
    final base64Marker = dataUrl.indexOf(',');
    if (base64Marker == -1) {
      throw Exception('[stage:canvas-encode] canvas.toDataUrl returned an unexpected value.');
    }
    return base64Decode(dataUrl.substring(base64Marker + 1));
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
}
