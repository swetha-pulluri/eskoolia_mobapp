import 'dart:io';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Android: saves directly into the real, shared Downloads folder via
/// `MediaStore` — no permission prompt needed on any currently-supported
/// Android version (API 29 requires the legacy `WRITE_EXTERNAL_STORAGE`
/// permission declared in `AndroidManifest.xml`; nothing at all above
/// that). The file shows up immediately in the Files app / any file
/// manager, matching a browser download exactly.
///
/// Previously wrote to `getExternalStorageDirectory()` (a plain `path_provider`
/// call) — the app's own PRIVATE external-storage folder
/// (`Android/data/<package>/files/Download`), which no file manager surfaces
/// and which is deleted the moment the app is uninstalled. That produced a
/// "downloaded successfully" toast for a file the user could never actually
/// find — functionally indistinguishable from the download silently failing.
///
/// iOS: unchanged — `getApplicationDocumentsDirectory()` is already the
/// folder the app exposes in the Files app
/// (`UIFileSharingEnabled`/`LSSupportsOpeningDocumentsInPlace` in
/// `Info.plist`), genuinely visible there already; iOS has no MediaStore
/// equivalent and `media_store_plus` is Android-only.
Future<String> saveBytesForDownload({required List<int> bytes, required String filename}) async {
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = 'Eskoolia';
    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/$filename').writeAsBytes(bytes);
    try {
      final saved = await MediaStore().saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
        // Directly in Downloads, not a nested `Download/Eskoolia/...`
        // subfolder — the file should be immediately visible, not one
        // extra tap away in an app-specific folder.
        relativePath: FilePath.root,
      );
      if (saved == null) throw Exception('Failed to save file to Downloads.');
      return saved.name;
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  Directory? dir;
  if (Platform.isIOS) {
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
