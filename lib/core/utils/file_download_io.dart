import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Desktop/mobile: write to a real, user-findable location and return its
/// path so the caller can report where the export landed (there is no OS
/// download tray to rely on for feedback, unlike a browser).
///
/// Previously wrote to `Directory.systemTemp`, an OS-managed scratch
/// directory the user has no way to browse to — a "direct download" that
/// silently vanished. On Android, `getExternalStorageDirectory()` is the
/// app's own external-storage folder — browsable with any file manager and,
/// unlike the shared public Downloads folder, needs no runtime storage
/// permission on any supported Android version. On iOS,
/// `getApplicationDocumentsDirectory()` is the folder the app exposes in
/// the Files app (`UIFileSharingEnabled`/`LSSupportsOpeningDocumentsInPlace`
/// in `Info.plist`).
Future<String> saveBytesForDownload({required List<int> bytes, required String filename}) async {
  Directory? dir;
  if (Platform.isAndroid) {
    dir = await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    dir = await getApplicationDocumentsDirectory();
  }
  dir ??= await getApplicationDocumentsDirectory();

  final downloadDir = Directory('${dir.path}/Download');
  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }
  final file = File('${downloadDir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
