// ignore_for_file: deprecated_member_use
import 'dart:html' as html;

/// Web: trigger a real browser download via a Blob + anchor-click, mirroring
/// the reference frontend's own `URL.createObjectURL(blob)` + synthesized
/// `<a download>` mechanism exactly (this is the one platform where that
/// trick is native rather than a workaround) — `dart:io`'s `File`/`Directory`
/// are not available on web at all.
Future<String> saveBytesForDownload({required List<int> bytes, required String filename}) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return filename;
}
