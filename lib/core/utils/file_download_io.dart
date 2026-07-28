import 'dart:io';

/// Desktop/mobile: write to a temp file and return its path so the caller
/// can report where the export landed (there is no OS download tray to
/// rely on for feedback, unlike a browser).
Future<String> saveBytesForDownload({required List<int> bytes, required String filename}) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
