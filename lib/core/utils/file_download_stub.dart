/// Fallback for platforms with neither `dart:io` nor `dart:html` available
/// (shouldn't be reachable on any Flutter target this app ships to).
Future<String> saveBytesForDownload({required List<int> bytes, required String filename}) {
  throw UnsupportedError('File download is not supported on this platform.');
}
