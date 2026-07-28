/// `saveBytesForDownload({required bytes, required filename}) -> Future<String>`
/// — platform-conditional file export. `dart:io`'s `File`/`Directory` don't
/// exist on Flutter web at all, so a CSV/xlsx export built only against
/// `dart:io` compiles fine but throws `UnsupportedError` at runtime the
/// moment it's actually invoked in a browser — this picks the right
/// implementation per platform at compile time instead.
library;

export 'file_download_stub.dart'
    if (dart.library.io) 'file_download_io.dart'
    if (dart.library.html) 'file_download_web.dart';
