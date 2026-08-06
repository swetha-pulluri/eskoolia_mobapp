import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the running platform is hover-capable (mouse/trackpad), matching
/// web's desktop-only `onMouseEnter`/`onMouseLeave` dropdown behavior.
/// Android/iOS get tap-to-open/close instead. Mirrors the binary
/// `kIsWeb`/`Platform.isAndroid||Platform.isIOS` branching style already
/// established in `env_config.dart`.
bool get isHoverCapablePlatform =>
    kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
